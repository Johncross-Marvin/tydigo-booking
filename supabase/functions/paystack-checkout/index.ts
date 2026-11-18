import { customer, reply, serviceClient, uuid } from '../_shared/booking.ts';
import { checkoutUrl, paystackSecret, provider, verifiedPayment, type PaymentVerification } from '../_shared/paystack.ts';

Deno.serve(async request => {
 if (request.method !== 'POST') return reply(405,{error:'Method not allowed'});
 try {
  const auth = await customer(request);
  if (!auth) return reply(401,{error:'Confirmed sign-in required'});
  const secret = paystackSecret();
  if (!secret) return reply(503,{error:'Payment sandbox is not configured'});
  const body = await request.json().catch(()=>null);
  if (!uuid(body?.booking_id) || !['initialize','verify'].includes(body?.action)) return reply(400,{error:'Invalid payment request'});
  const admin = serviceClient();

  if (body.action === 'verify') {
   const {data:order,error} = await auth.client.from('payment_orders').select('provider_reference,amount_kobo,status')
    .eq('booking_id',body.booking_id).eq('auth_user_id',auth.user.id).maybeSingle();
   if (error || !order) return reply(404,{error:'Payment not found'});
   if (['paid','refunded'].includes(order.status)) return reply(200,{status:order.status});
   const transaction = await provider<PaymentVerification>('/transaction/verify/'+encodeURIComponent(order.provider_reference),secret);
   if (transaction.reference !== order.provider_reference || transaction.domain !== 'test' || transaction.amount !== order.amount_kobo || transaction.currency !== 'NGN') return reply(409,{error:'Payment requires reconciliation'});
   if (!verifiedPayment(transaction,order.provider_reference,order.amount_kobo)) {
    const status = transaction.status==='failed' ? 'failed' : transaction.status==='abandoned' ? 'cancelled' : 'pending';
    if (status !== 'pending') {
     const saved = await admin.rpc('record_payment_outcome',{reference:order.provider_reference,outcome:status});
     if (saved.error) return reply(502,{error:'Payment status could not be recorded'});
     return reply(200,{status:saved.data});
    }
    return reply(200,{status});
   }
   const receipt = await admin.rpc('record_verified_payment',{reference:transaction.reference,provider_id:String(transaction.id),amount:transaction.amount,currency_code:transaction.currency});
   if (receipt.error) return reply(502,{error:'Payment could not be reconciled'});
   return reply(200,{status:'paid',receipt_id:receipt.data});
  }

  const callback = Deno.env.get('PAYSTACK_TEST_CALLBACK_URL');
  if (!callback || new URL(callback).protocol !== 'https:') return reply(503,{error:'Payment sandbox callback is not configured'});
  const {data:order,error} = await auth.client.rpc('prepare_payment',{booking:body.booking_id});
  if (error || !order) return reply(409,{error:'Booking is not payable'});
  if (order.authorization_url) return reply(200,{reference:order.provider_reference,checkout_url:checkoutUrl(order.authorization_url)});
  const initialized = await provider<{reference:string;authorization_url:string}>('/transaction/initialize',secret,{
   email:auth.email,amount:order.amount_kobo,currency:'NGN',reference:order.provider_reference,
   callback_url:callback,
  });
  if (initialized.reference !== order.provider_reference) return reply(502,{error:'Provider reference mismatch'});
  const checkout = checkoutUrl(initialized.authorization_url);
  const saved = await admin.from('payment_orders').update({authorization_url:checkout}).eq('id',order.id);
  if (saved.error) return reply(502,{error:'Checkout could not be confirmed'});
  return reply(200,{reference:order.provider_reference,checkout_url:checkout});
 } catch {
  return reply(502,{error:'Checkout service temporarily unavailable'});
 }
});
