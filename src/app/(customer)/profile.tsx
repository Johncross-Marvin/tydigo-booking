import { useState } from 'react';
import { router, Stack } from 'expo-router';
import { useAuth } from '../../auth/provider';
import { Button, Card, Copy, Page } from '../../components/ui';
export default function Profile(){const {state,signOut}=useAuth();const [confirm,setConfirm]=useState(false);return <Page><Stack.Screen options={{title:'Your account'}}/><Card><Copy title>{state.account!.display_name}</Copy><Copy>Account category: {state.account!.account_type}</Copy><Copy>Verification: {state.account!.verification_status.replaceAll('_',' ')}</Copy></Card><Button label="Verification centre" onPress={()=>router.push('/verification')}/><Button label="Help & support" onPress={()=>router.push('/support')}/>{confirm?<Card><Copy>Sign out of this installation?</Copy><Button label="Confirm sign out" onPress={()=>void signOut()}/><Button label="Stay signed in" onPress={()=>setConfirm(false)}/></Card>:<Button label="Sign out" onPress={()=>setConfirm(true)}/>}</Page>;}

