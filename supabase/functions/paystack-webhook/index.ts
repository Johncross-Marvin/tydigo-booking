import { referenceValid, reply, serviceClient } from '../_shared/booking.ts';
import { paystackSecret, provider, verifiedPayment, verifySignature, type PaymentVerification } from '../_shared/paystack.ts';

Deno.serve(async request => {
 if (request.method !== 'POST') return reply(405,{error:'Method not allowed'});
 const secret = paystackSecret();
 if (!secret) return reply(503,{error:'Payment sandbox is not configured'});
 try {
  const raw = new Uint8Array(await request.arrayBuffer());
  if (raw.length>262144) return reply(413,{error:'Payload too large'});
  if (!await verifySignature(raw,request.headers.get('x-paystack-signature'),secret)) return reply(401,{error:'Invalid signature'});
  let event;
  try { event=JSON.parse(new TextDecoder().decode(raw)); }
  catch { return reply(400,{error:'Invalid event'}); }
  const reference = event?.data?.reference;
  if (event?.event!=='charge.success' || !referenceValid(reference)) return reply(200,{received:true});
  const admin = serviceClient();
  const {data:order,error} = await admin.from('payment_orders').select('amount_kobo').eq('provider_reference',reference).maybeSingle();
  if (error) return reply(503,{error:'Payment lookup unavailable'});
  if (!order) return reply(200,{received:true});
  const transaction=await provider<PaymentVerification>('/transaction/verify/'+encodeURIComponent(reference),secret);
  if (!verifiedPayment(transaction,reference,order.amount_kobo)) return reply(409,{error:'Payment requires reconciliation'});
  const settlement=await admin.rpc('record_verified_payment',{reference,provider_id:String(transaction.id),amount:transaction.amount,currency_code:transaction.currency});
  if (settlement.error) return reply(503,{error:'Payment reconciliation unavailable'});
  return reply(200,{received:true});
 } catch {
  return reply(503,{error:'Webhook processing unavailable'});
 }
});
