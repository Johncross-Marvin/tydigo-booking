import { useState } from 'react';
import { Stack } from 'expo-router';
import { requireBackend } from '../../lib/backend';
import { useAuth } from '../../auth/provider';
import { Button, Card, Copy, Field, Page } from '../../components/ui';
export default function Support(){const {state}=useAuth();const [body,setBody]=useState(''),[message,setMessage]=useState(''),[busy,setBusy]=useState(false);async function send(){setBusy(true);try{const {error}=await requireBackend().from('support_tickets').insert({auth_user_id:state.account!.auth_user_id,body});if(error)throw error;setBody('');setMessage('Your support request has been recorded.');}catch{setMessage('Could not submit your request. Please retry.');}finally{setBusy(false);}}return <Page><Stack.Screen options={{title:'Help & support'}}/><Card><Copy title>How can we help?</Copy><Copy>Describe the problem. Never include passwords or payment card details.</Copy><Field label="Your message" multiline value={body} onChangeText={setBody}/><Button label="Submit support request" disabled={busy||body.trim().length<10} onPress={()=>void send()}/>{!!message&&<Copy>{message}</Copy>}</Card></Page>;}

