import { useEffect, useState } from 'react';
import { Stack } from 'expo-router';
import { useAuth } from '../../auth/provider';
import { requireBackend } from '../../lib/backend';
import type { Tables } from '../../lib/database.types';
import { Button, Card, Copy, Page } from '../../components/ui';

type Booking = Pick<Tables<'bookings'>,'id'|'service'|'status'|'requested_at'|'payment_status'>;

export default function History() {
 const {notificationVersion}=useAuth();
 const [retry,setRetry]=useState(0);
 const [result,setResult]=useState<{rows:Booking[];error:boolean}|null>(null);
 useEffect(() => {
  const abort=new AbortController();
  void requireBackend().from('bookings')
   .select('id,service,status,requested_at,payment_status')
   .order('created_at',{ascending:false}).limit(50).abortSignal(abort.signal)
   .then(({data,error})=>{if(!abort.signal.aborted) setResult({rows:data??[],error:Boolean(error)});});
  return ()=>abort.abort();
 },[retry,notificationVersion]);

 return <Page>
  <Stack.Screen options={{title:'Your bookings'}}/>
  {!result ? <Copy>Loading bookings…</Copy> :
   result.error ? <Card><Copy>Bookings are unavailable. Please retry.</Copy>
    <Button label="Retry" onPress={()=>{setResult(null);setRetry(value=>value+1);}}/>
   </Card> :
   result.rows.length ? result.rows.map(booking=><Card key={booking.id}>
    <Copy title>TYDIGO {booking.service}</Copy>
    <Copy>Reference: {booking.id}</Copy>
    <Copy>{booking.status.replaceAll('_',' ')}</Copy>
    <Copy>{new Date(booking.requested_at).toLocaleString()}</Copy>
    <Copy>Payment: {booking.payment_status}</Copy>
   </Card>) : <Card><Copy title>No pickup requests yet</Copy><Copy>Your requests and their progress will appear here.</Copy></Card>}
 </Page>;
}

