-- Dedicated Booking database only. No legacy accounts or operational seeds.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
create type public.customer_category as enum ('household','estate','business');
create type public.verification_state as enum ('not_started','submitted','under_review','corrections_required','approved','rejected');
create table public.customer_accounts (
 auth_user_id uuid primary key references auth.users(id),
 account_type public.customer_category not null,
 display_name text not null check(length(display_name) between 1 and 200),
 status text not null default 'active' check(status in ('active','suspended','closed')),
 verification_status public.verification_state not null default 'not_started',
 created_at timestamptz not null default now()
);
create function private.create_customer() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.raw_user_meta_data->>'account_type' not in ('household','estate','business') or new.raw_user_meta_data->>'account_type' is null then
 raise exception 'Choose a supported customer category'; end if;
 insert into public.customer_accounts(auth_user_id,account_type,display_name)
 values(new.id,(new.raw_user_meta_data->>'account_type')::public.customer_category,trim(new.raw_user_meta_data->>'display_name'));
 return new;
end; $$;
-- Metadata is validated once as registration input, never consulted for authorization.
create trigger booking_customer_created after insert on auth.users for each row execute function private.create_customer();
create table private.admin_members(auth_user_id uuid primary key references auth.users(id), can_review boolean not null default false);
create table private.review_audit(id bigint generated always as identity primary key, actor uuid not null, subject uuid not null, decision text not null, reason text not null, created_at timestamptz not null default now());
create table public.verification_requirements(id uuid primary key default gen_random_uuid(), account_type public.customer_category not null,label text not null,active boolean not null default false);
create table public.verification_documents(id uuid primary key default gen_random_uuid(),auth_user_id uuid not null references public.customer_accounts,requirement_id uuid not null references public.verification_requirements,storage_path text not null unique,created_at timestamptz not null default now());
create index on public.verification_documents(auth_user_id);
create table public.customer_addresses(id uuid primary key default gen_random_uuid(),auth_user_id uuid not null references public.customer_accounts,label text not null,address_text text not null,created_at timestamptz not null default now());
create index on public.customer_addresses(auth_user_id);
create table public.service_availability(id uuid primary key default gen_random_uuid(),service text not null check(service in ('drive','send')),area_name text not null,active boolean not null default false);
create table public.waste_categories(id uuid primary key default gen_random_uuid(),label text not null,service text not null check(service in ('drive','send')),preparation text not null,active boolean not null default false,hazardous boolean not null default false,check(not(active and hazardous)));
create table public.quotes(id uuid primary key default gen_random_uuid(),auth_user_id uuid not null references public.customer_accounts,amount_kobo bigint not null check(amount_kobo>0),currency text not null default 'NGN' check(currency='NGN'),items jsonb not null,expires_at timestamptz not null,created_at timestamptz not null default now());
create index on public.quotes(auth_user_id);
create table public.bookings(id uuid primary key default gen_random_uuid(),auth_user_id uuid not null references public.customer_accounts,service text not null check(service in ('drive','send')),address_snapshot jsonb not null,requested_at timestamptz not null,quote_id uuid not null unique references public.quotes,status text not null default 'awaiting_assignment' check(status in ('awaiting_assignment','scheduled','assignment_unavailable','collection_pending','in_progress','completed','delivery_confirmed','cancelled')),payment_status text not null default 'pending' check(payment_status in ('pending','paid','failed','partially_refunded','refunded')),idempotency_key uuid not null,created_at timestamptz not null default now(),unique(auth_user_id,idempotency_key));
create index on public.bookings(auth_user_id,created_at desc);
create table public.payment_orders(id uuid primary key default gen_random_uuid(),auth_user_id uuid not null references public.customer_accounts,booking_id uuid not null references public.bookings,provider_reference text not null unique,amount_kobo bigint not null check(amount_kobo>0),status text not null default 'pending',created_at timestamptz not null default now());
create index on public.payment_orders(auth_user_id);
create table public.rewards_ledger(id uuid primary key default gen_random_uuid(),auth_user_id uuid not null references public.customer_accounts,booking_id uuid not null references public.bookings,points integer not null,reason text not null,idempotency_key text not null unique,created_at timestamptz not null default now());
create index on public.rewards_ledger(auth_user_id);
create table public.customer_notifications(id uuid primary key default gen_random_uuid(),auth_user_id uuid not null references public.customer_accounts,body text not null,created_at timestamptz not null default now());
create index on public.customer_notifications(auth_user_id);
create table public.support_tickets(id uuid primary key default gen_random_uuid(),auth_user_id uuid not null references public.customer_accounts,body text not null check(length(trim(body)) between 10 and 5000),status text not null default 'open',created_at timestamptz not null default now());
create index on public.support_tickets(auth_user_id);
create table private.integration_events(id uuid primary key default gen_random_uuid(),booking_id uuid not null references public.bookings,event_type text not null,sequence bigint not null,payload jsonb not null,occurred_at timestamptz not null default now(),unique(booking_id,sequence));
-- Default-deny public mutations. Owners may read only their own rows.
do $$ declare t text; begin
 foreach t in array array['customer_accounts','verification_documents','customer_addresses','quotes','bookings','payment_orders','rewards_ledger','customer_notifications','support_tickets'] loop
 execute format('alter table public.%I enable row level security',t);
 execute format('revoke all on public.%I from anon,authenticated',t);
 execute format('grant select on public.%I to authenticated',t);
 execute format('create policy owner_read on public.%I for select to authenticated using (auth_user_id=(select auth.uid()))',t);
 end loop;
 foreach t in array array['verification_requirements','service_availability','waste_categories'] loop
 execute format('alter table public.%I enable row level security',t);
 execute format('revoke all on public.%I from anon,authenticated',t);
 execute format('grant select on public.%I to authenticated',t);
 execute format('create policy configured_read on public.%I for select to authenticated using (active)',t);
 end loop;
end $$;
grant insert(auth_user_id,body) on public.support_tickets to authenticated;
create policy owner_support on public.support_tickets for insert to authenticated with check(auth_user_id=(select auth.uid()));
grant insert(auth_user_id,label,address_text) on public.customer_addresses to authenticated;
create policy owner_address on public.customer_addresses for insert to authenticated with check(auth_user_id=(select auth.uid()));
alter table private.admin_members enable row level security;
alter table private.review_audit enable row level security;
alter table private.integration_events enable row level security;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('verification','verification',false,10485760,array['application/pdf','image/jpeg','image/png']);
create policy verification_upload on storage.objects for insert to authenticated with check(bucket_id='verification' and (storage.foldername(name))[1]=(select auth.uid())::text and exists(select 1 from public.customer_accounts a where a.auth_user_id=(select auth.uid()) and a.status='active' and a.verification_status in ('not_started','corrections_required','rejected')));
create policy verification_read on storage.objects for select to authenticated using(bucket_id='verification' and (storage.foldername(name))[1]=(select auth.uid())::text);
create function public.submit_verification_document(requirement uuid, object_path text) returns void language plpgsql security definer set search_path='' as $$
declare a public.customer_accounts;
begin
 select * into a from public.customer_accounts where auth_user_id=auth.uid() for update;
 if a.auth_user_id is null or a.status<>'active' or a.verification_status not in ('not_started','corrections_required','rejected') then raise exception 'Submission unavailable'; end if;
 if not exists(select 1 from auth.users where id=auth.uid() and email_confirmed_at is not null) then raise exception 'Email confirmation required'; end if;
 if not exists(select 1 from public.verification_requirements where id=requirement and account_type=a.account_type and active) then raise exception 'Invalid requirement'; end if;
 if split_part(object_path,'/',1)<>auth.uid()::text or not exists(select 1 from storage.objects where bucket_id='verification' and name=object_path) then raise exception 'Missing uploaded document'; end if;
 insert into public.verification_documents(auth_user_id,requirement_id,storage_path) values(auth.uid(),requirement,object_path);
 if not exists(select 1 from public.verification_requirements r where r.account_type=a.account_type and r.active and not exists(select 1 from public.verification_documents d where d.auth_user_id=auth.uid() and d.requirement_id=r.id)) then
 update public.customer_accounts set verification_status='submitted' where auth_user_id=auth.uid();
 end if;
end; $$;
revoke all on function public.submit_verification_document(uuid,text) from public,anon;
grant execute on function public.submit_verification_document(uuid,text) to authenticated;
create function public.review_verification(subject uuid, decision public.verification_state, reason text) returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or not exists(select 1 from private.admin_members where auth_user_id=auth.uid() and can_review) or coalesce(auth.jwt()->>'aal','')<>'aal2' then raise exception 'Authorized MFA review required'; end if;
 if decision not in ('approved','rejected','corrections_required','under_review') or length(trim(reason))<10 then raise exception 'Invalid review'; end if;
 perform 1 from public.customer_accounts where auth_user_id=subject and verification_status in ('submitted','under_review') for update;
 if not found then raise exception 'No submitted review'; end if;
 update public.customer_accounts set verification_status=decision where auth_user_id=subject;
 insert into private.review_audit(actor,subject,decision,reason) values(auth.uid(),subject,decision::text,reason);
end; $$;
revoke all on function public.review_verification(uuid,public.verification_state,text) from public,anon;
grant execute on function public.review_verification(uuid,public.verification_state,text) to authenticated;
revoke all on function private.create_customer() from public,anon,authenticated;
-- No client can create quotes/bookings, mark payments, issue rewards or approve verification.
-- Commercial RPCs will be added after approved pricing and availability rules are supplied.

