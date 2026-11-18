import { verifySignature, verifiedPayment } from './paystack.ts';

Deno.test('webhook signatures bind exact request bytes',async()=>{
 const encoder=new TextEncoder(),secret='isolated-fixture';
 const raw=encoder.encode('{"event":"charge.success"}');
 const key=await crypto.subtle.importKey('raw',encoder.encode(secret),{name:'HMAC',hash:'SHA-512'},false,['sign']);
 const signature=Array.from(new Uint8Array(await crypto.subtle.sign('HMAC',key,raw)),value=>value.toString(16).padStart(2,'0')).join('');
 if (!await verifySignature(raw,signature,secret)) throw new Error('Valid signature rejected');
 for(const input of [null,'00',signature.replace(/^./,signature[0]==='0'?'1':'0')]) {
  if(await verifySignature(raw,input,secret)) throw new Error('Invalid signature accepted');
 }
 if(await verifySignature(encoder.encode('{"event":"changed"}'),signature,secret)) throw new Error('Altered body accepted');
});

Deno.test('payment verification requires matching reference, amount, currency and test domain',()=>{
 const transaction={id:1,reference:'ref',amount:600,currency:'NGN',status:'success',domain:'test'};
 if(!verifiedPayment(transaction,'ref',600)) throw new Error('Valid transaction rejected');
 for(const change of [{id:0},{amount:599},{reference:'another'},{currency:'USD'},{status:'failed'},{domain:'live'}]) {
  if(verifiedPayment({...transaction,...change},'ref',600)) throw new Error('Mismatched transaction accepted');
 }
});
