import { createClient } from 'npm:@supabase/supabase-js@2.119.1';

const url = () => Deno.env.get('SUPABASE_URL')!;
export const reply = (status: number, body: object) => Response.json(body, {status, headers:{'Cache-Control':'no-store'}});
export const uuid = (value: unknown): value is string => typeof value==='string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
export const referenceValid = (value: unknown): value is string => typeof value==='string' && /^tydigo-[0-9a-f]{8}-[0-9a-f-]{27}$/.test(value);

export function serviceClient() {
 return createClient(url(),Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,{auth:{persistSession:false,autoRefreshToken:false}});
}

export async function customer(request: Request) {
 const token = request.headers.get('Authorization')?.match(/^Bearer ([A-Za-z0-9._-]+)$/i)?.[1];
 if (!token) return null;
 const client = createClient(url(),Deno.env.get('SUPABASE_ANON_KEY')!,{
  auth:{persistSession:false,autoRefreshToken:false},
  global:{headers:{Authorization:'Bearer '+token}},
 });
 const {data,error} = await client.auth.getUser(token);
 if (error || !data.user?.email_confirmed_at || !data.user.email) return null;
 return {client, user:data.user, email:data.user.email};
}
