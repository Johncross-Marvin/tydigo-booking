import React, { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react';
import { AppState } from 'react-native';
import { backend, requireBackend } from '../lib/backend';
import { Account, resolveAccount } from '../domain/accounts';
type State = { status: 'loading' | 'signed_out' | 'ready' | 'error'; account: Account | null; message: string };
const initial: State = { status: 'loading', account: null, message: '' };
const Context = createContext<{ state: State; refresh: () => Promise<void>; signOut: () => Promise<void>; notificationVersion: number } | null>(null);
export function AuthProvider({ children }: React.PropsWithChildren) {
  const [state, setState] = useState(initial);
  const [notificationVersion,setNotificationVersion] = useState(0);
  const generation = useRef(0);
  const endingSession = useRef(false);
  const refresh = useCallback(async (background=false) => {
    if (endingSession.current) return;
    const epoch = ++generation.current;
    if (!backend) { setState({status:'signed_out',account:null,message:''}); return; }
    if (!background) setState(initial);
    try {
      const { data: session, error: sessionError } = await backend.auth.getSession();
      if (sessionError) throw sessionError;
      if (!session.session) { if(epoch === generation.current) setState({status:'signed_out',account:null,message:''}); return; }
      const { data, error } = await backend.auth.getUser();
      if (error) throw error;
      if (!data.user?.email_confirmed_at) throw new Error('Verify your email before signing in.');
      const result = await backend.from('customer_accounts').select('*').eq('auth_user_id',data.user.id).maybeSingle();
      if(result.error) throw new Error('Account lookup is unavailable. Please retry.');
      const account = resolveAccount(result.data, data.user.id);
      if(epoch === generation.current) setState({status:'ready',account,message:''});
    } catch(error) { if(epoch === generation.current) setState({status:'error',account:null,message:error instanceof Error ? error.message : 'Unable to resolve account.'}); }
  },[]);
  const signOut = async () => {
    if(endingSession.current) return;
    endingSession.current=true;
    ++generation.current;
    const client = requireBackend();
    setState(initial);
    try {
      await client.removeAllChannels();
      const { error } = await client.auth.signOut({scope:'local'});
      if(error) throw error;
      const {data} = await client.auth.getSession();
      if(data.session) throw new Error('Sign-out could not be confirmed.');
      setState({status:'signed_out',account:null,message:''});
    } catch { setState({status:'error',account:null,message:'Sign-out could not be confirmed. Retry to securely end this session.'}); }
    finally {endingSession.current=false;}
  };
  useEffect(() => {
    let timer: ReturnType<typeof setTimeout>;
    const scheduleRefresh=()=>{
      clearTimeout(timer);
      timer=setTimeout(()=>void refresh(),0);
    };
    scheduleRefresh();
    if(!backend) return ()=>clearTimeout(timer);
    const {data} = backend.auth.onAuthStateChange(event => {
      if(event === 'SIGNED_OUT') { ++generation.current; setState({status:'signed_out',account:null,message:''}); }
      else if(event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED' || event === 'USER_UPDATED') scheduleRefresh();
    });
    const foreground = AppState.addEventListener('change', status => { if(status === 'active') { backend!.auth.startAutoRefresh(); void refresh(); } else backend!.auth.stopAutoRefresh(); });
    return () => { clearTimeout(timer); data.subscription.unsubscribe(); foreground.remove(); };
  }, [refresh]);
  const authUserId = state.account?.auth_user_id;
  useEffect(() => {
    if (!backend || !authUserId) return;
    const client=backend;
    const invalidate=()=>{
      if(endingSession.current) return;
      setNotificationVersion(version=>version+1);
      void refresh(true);
    };
    const channel=client.channel('booking-notifications:'+authUserId)
      .on('postgres_changes',{event:'INSERT',schema:'public',table:'customer_notifications',filter:'auth_user_id=eq.'+authUserId},invalidate)
      .subscribe(status=>{if(status==='SUBSCRIBED') invalidate();});
    return ()=>{void client.removeChannel(channel);};
  }, [authUserId,refresh]);
  return <Context.Provider value={{state,refresh,signOut,notificationVersion}}>{children}</Context.Provider>;
}
export function useAuth() { const value=useContext(Context); if(!value) throw new Error('AuthProvider missing'); return value; }

