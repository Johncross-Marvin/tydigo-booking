import { useState } from 'react';
import { Stack, useLocalSearchParams, router } from 'expo-router';
import { canTransact } from '../../domain/accounts';
import { useAuth } from '../../auth/provider';
import { requireBackend } from '../../lib/backend';
import { Button, Card, Copy, Page } from '../../components/ui';
export default function Booking(){const {service}=useLocalSearchParams<{service:string}>();const {state}=useAuth();const [message,setMessage]=useState(''),[busy,setBusy]=useState(false);
if(service!=='drive'&&service!=='send')return <Page><Copy>Choose TYDIGO Drive or TYDIGO Send from your dashboard.</Copy></Page>;
async function availability(){setBusy(true);try{const {data,error}=await requireBackend().from('service_availability').select('area_name').eq('service',service).eq('active',true);if(error)throw error;setMessage(data?.length?'Service areas: '+data.map(r=>r.area_name).join(', ')+'. Address selection and quote checkout are not released yet.':'No collection areas are currently available for this service.');}catch{setMessage('Service availability could not be loaded. Please retry.');}finally{setBusy(false);}}
return <Page><Stack.Screen options={{title:'TYDIGO '+(service==='drive'?'Drive':'Send')}}/><Copy title>{service==='drive'?'Make room for a cleaner day.':'Give separated materials a next destination.'}</Copy><Card><Copy>{service==='drive'?'Collection requires your registered address, supported waste category, quantity and an available time window.':'Only eligible separated materials can be sent. Preparation and recycler eligibility must be confirmed before a quote.'}</Copy><Copy>Hazardous or unsupported materials cannot be booked. Prices are issued by the service after availability checks.</Copy>{!canTransact(state.account!)?<><Copy>Verification approval is required before checkout.</Copy><Button label="Complete verification" onPress={()=>router.push('/verification')}/></>:<Button label="Check service availability" disabled={busy} onPress={()=>void availability()}/>} {!!message&&<Copy>{message}</Copy>}</Card></Page>;}

