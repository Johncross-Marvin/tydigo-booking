import { useState } from 'react';
import { Image } from 'react-native';
import { Redirect, router } from 'expo-router';
import { useAuth } from '../auth/provider';
import { requireBackend, configured, recoveryConfigured } from '../lib/backend';
import { Button, Card, Copy, Field, Page } from '../components/ui';
export default function SignIn(){const {state}=useAuth();const [email,setEmail]=useState(''),[password,setPassword]=useState(''),[message,setMessage]=useState(''),[busy,setBusy]=useState(false);
if(state.status==='ready'||state.status==='error')return <Redirect href="/"/>;
async function submit(){setBusy(true);setMessage('');try{const {error}=await requireBackend().auth.signInWithPassword({email:email.trim(),password});if(error)throw error;}catch(e){setMessage(e instanceof Error?e.message:'Unable to sign in.');}finally{setBusy(false);}}
return <Page><Image source={require('../../assets/brand/Tydigo_Logo_Primary.png')} resizeMode="contain" accessibilityLabel="TYDIGO" style={{height:100,width:'100%'}}/><Copy title>Cleaner spaces. A simpler day.</Copy><Copy>Tap. Sort. Picked.</Copy><Card><Copy title>Welcome back</Copy><Copy>Book waste collection for your home, estate or business.</Copy>{!configured&&<Copy>The Booking service is not connected yet. Sign-in will be available once setup is complete.</Copy>}<Field label="Email" value={email} onChangeText={setEmail} autoCapitalize="none" keyboardType="email-address"/><Field label="Password" value={password} onChangeText={setPassword} secureTextEntry/>{!!message&&<Copy>{message}</Copy>}<Button label={busy?'Signing in…':'Sign in'} disabled={busy||!configured||!email||!password} onPress={()=>void submit()}/>{recoveryConfigured&&<Button label="Forgot password?" onPress={()=>router.push('/recover-password')}/>}<Button label="Create an account" onPress={()=>router.push('/register')}/></Card></Page>;}

