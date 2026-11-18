const endpoint = 'https://api.paystack.co';
const encoder = new TextEncoder();

export function paystackSecret(): string | undefined {
 // A sandbox charge must never settle a production Booking order.
 if (Deno.env.get('SUPABASE_URL')?.includes('auplmtypaptzxjqeqhhf')) return undefined;
 const secret = Deno.env.get('PAYSTACK_TEST_SECRET_KEY');
 return secret?.startsWith('sk_test_') ? secret : undefined;
}

export async function verifySignature(raw: Uint8Array<ArrayBuffer>, signature: string | null, secret: string) {
 if (!signature || !/^[0-9a-f]{128}$/i.test(signature)) return false;
 const bytes = Uint8Array.from(signature.match(/../g)!, byte => parseInt(byte,16));
 const key = await crypto.subtle.importKey('raw',encoder.encode(secret),{name:'HMAC',hash:'SHA-512'},false,['verify']);
 return crypto.subtle.verify('HMAC',key,bytes,raw);
}

export async function provider<T>(path: string, secret: string, body?: unknown): Promise<T> {
 const result = await fetch(endpoint+path,{
  method: body ? 'POST' : 'GET',
  headers: { Authorization: 'Bearer '+secret, 'Content-Type': 'application/json' },
  body: body ? JSON.stringify(body) : undefined,
  signal: AbortSignal.timeout(12000),
 });
 const payload = await result.json();
 if (!result.ok || payload.status !== true || !payload.data) throw new Error('Provider request unsuccessful');
 return payload.data as T;
}

export type PaymentVerification = { id: number; reference: string; amount: number; currency: string; status: string; domain: string };

export function verifiedPayment(value: PaymentVerification, reference: string, amount: number) {
 return value.reference === reference && value.amount === amount && value.currency === 'NGN' &&
  value.status === 'success' && value.domain === 'test' && Number.isSafeInteger(value.id) && value.id > 0;
}

export function checkoutUrl(value: string): string {
 const url = new URL(value);
 if (url.protocol !== 'https:' || url.hostname !== 'checkout.paystack.com' || url.port || url.username || url.password) throw new Error('Unexpected checkout host');
 return url.href;
}
