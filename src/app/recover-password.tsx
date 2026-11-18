import { useState } from 'react';
import { Redirect, Stack, router } from 'expo-router';
import { useAuth } from '../auth/provider';
import { recoveryClient, recoveryConfigured } from '../lib/backend';
import { Button, Card, Copy, Field, Page } from '../components/ui';

export default function RecoverPassword() {
 const {state}=useAuth();
 const [email,setEmail]=useState('');
 const [code,setCode]=useState('');
 const [password,setPassword]=useState('');
 const [sent,setSent]=useState(false);
 const [busy,setBusy]=useState(false);
 const [message,setMessage]=useState('');
 if(state.status==='ready'||state.status==='error') return <Redirect href="/" />;
 if(!recoveryConfigured) return <Redirect href="/sign-in" />;

 async function recover() {
  setBusy(true);
  setMessage('');
  try {
   const client=recoveryClient();
   if(!sent) {
    const {error}=await client.auth.resetPasswordForEmail(email.trim());
    if(error) throw error;
    setSent(true);
    setMessage('If this address is registered, check your email for a recovery code.');
    return;
   }
   const {error: verificationError}=await client.auth.verifyOtp({email:email.trim(),token:code.trim(),type:'recovery'});
   if(verificationError) throw verificationError;
   try {
    const {error}=await client.auth.updateUser({password});
    if(error) throw error;
   } finally {
    await client.auth.signOut({scope:'local'});
   }
   router.replace('/sign-in');
  } catch {
   setMessage('Recovery could not be completed. Check your code or request another one.');
  } finally { setBusy(false); }
 }

 return <Page>
  <Stack.Screen options={{title:'Reset password'}} />
  <Card>
   <Copy title>Reset your password</Copy>
   <Field label="Email" value={email} editable={!sent&&!busy} onChangeText={setEmail} autoCapitalize="none" keyboardType="email-address" />
   {sent && <>
    <Field label="Recovery code" value={code} onChangeText={setCode} keyboardType="number-pad" autoComplete="one-time-code" />
    <Field label="New password" value={password} onChangeText={setPassword} secureTextEntry autoComplete="new-password" />
   </>}
   {message && <Copy>{message}</Copy>}
   <Button label={sent?'Set new password':'Send recovery code'} disabled={busy||state.status!=='signed_out'||!email.trim()||(sent&&(!code.trim()||password.length<12))} onPress={()=>void recover()} />
   {sent && <Button label="Request another code" disabled={busy} onPress={()=>{setSent(false);setCode('');setMessage('');}} />}
  </Card>
 </Page>;
}
