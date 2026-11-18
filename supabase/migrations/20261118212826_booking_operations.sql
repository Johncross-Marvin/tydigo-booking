-- Booking operations: additive expansion, no operational seed data.
create table public.organizations(id uuid primary key default gen_random_uuid(),owner_id uuid not null references public.customer_accounts(auth_user_id),name text not null check(length(trim(name)) between 2 and 200),created_at timestamptz not null default now());
create table public.organization_members(organization_id uuid not null references public.organizations,auth_user_id uuid not null references public.customer_accounts,can_book boolean not null default false,active boolean not null default true,primary key(organization_id,auth_user_id));
create index on public.organization_members(auth_user_id);
create index on public.organizations(owner_id);
alter table public.customer_addresses add column organization_id uuid references public.organizations, add column coverage_id uuid references public.service_availability,
 add column coverage_verified boolean not null default false;
create index on public.customer_addresses(organization_id);
create index on public.customer_addresses(coverage_id);
create table public.service_destinations(id uuid primary key default gen_random_uuid(),name text not null,category_id uuid not null references public.waste_categories,coverage_id uuid not null references public.service_availability,authorization_reference text not null,active boolean not null default false);
create table public.collection_slots(id uuid primary key default gen_random_uuid(),coverage_id uuid not null references public.service_availability,starts_at timestamptz not null,ends_at timestamptz not null,capacity integer not null check(capacity>0),active boolean not null default false,check(ends_at>starts_at),unique(coverage_id,starts_at));
create table public.pricing_rules(id uuid primary key default gen_random_uuid(),coverage_id uuid not null references public.service_availability,category_id uuid not null references public.waste_categories,unit text not null check(unit in ('kg','container')),base_kobo bigint not null check(base_kobo>=0),unit_kobo bigint not null check(unit_kobo>0),minimum_quantity numeric(12,3) not null check(minimum_quantity>0),maximum_quantity numeric(12,3) not null,active boolean not null default false,version text not null,check(maximum_quantity>=minimum_quantity));
create unique index one_current_price on public.pricing_rules(coverage_id,category_id,unit) where active;
alter table public.quotes add column address_id uuid references public.customer_addresses,add column category_id uuid references public.waste_categories,add column slot_id uuid references public.collection_slots,add column rule_id uuid references public.pricing_rules,add column quantity numeric(12,3),add column destination_id uuid references public.service_destinations,add column address_snapshot jsonb,add column preparation_confirmed boolean not null default false,add column organization_id uuid references public.organizations;
alter table public.bookings add column slot_id uuid references public.collection_slots,add column organization_id uuid references public.organizations;
create index on public.bookings(slot_id) where status<>'cancelled';
create index on public.bookings(organization_id);
create table public.booking_status_history(id bigint generated always as identity primary key,booking_id uuid not null references public.bookings,auth_user_id uuid not null references public.customer_accounts,status text not null,created_at timestamptz not null default now());
create index on public.booking_status_history(auth_user_id,booking_id);
create table private.audit_events(id bigint generated always as identity primary key,actor uuid,event_type text not null,subject_id uuid,details jsonb not null default '{}',created_at timestamptz not null default now());
alter table private.audit_events enable row level security;
create table public.verification_applications(id uuid primary key default gen_random_uuid(),auth_user_id uuid not null references public.customer_accounts,state public.verification_state not null default 'not_started',submitted_at timestamptz,reviewed_at timestamptz,review_reason text,created_at timestamptz not null default now());
create unique index one_open_application on public.verification_applications(auth_user_id) where state in ('not_started','submitted','under_review');
alter table public.verification_documents add column application_id uuid references public.verification_applications;
-- The foundation allows submissions before application records exist. Stop if
-- there is data requiring an explicit backfill so existing reviews stay usable.
do $$ begin
 if exists(select 1 from public.verification_documents where application_id is null)
 or exists(select 1 from public.customer_accounts where verification_status in ('submitted','under_review')) then
  raise exception 'Existing verification submissions require a reviewed backfill';
 end if;
end $$;
create unique index one_requirement_per_application on public.verification_documents(application_id,requirement_id);
alter table private.admin_members add column can_support boolean not null default false,add column can_payments boolean not null default false,add column can_operations boolean not null default false;
alter table public.payment_orders add column provider_transaction_id text unique,add column currency text not null default 'NGN' check(currency='NGN'),add column authorization_url text,add column updated_at timestamptz not null default now();
create unique index one_payment_per_booking on public.payment_orders(booking_id);
create table private.payment_events(provider_transaction_id text primary key,reference text not null,amount_kobo bigint not null,received_at timestamptz not null default now());
alter table private.payment_events enable row level security;
create table public.receipts(id uuid primary key default gen_random_uuid(),auth_user_id uuid not null references public.customer_accounts,payment_order_id uuid not null unique references public.payment_orders,amount_kobo bigint not null check(amount_kobo>0),currency text not null check(currency='NGN'),issued_at timestamptz not null default now());
create table public.refund_requests(id uuid primary key default gen_random_uuid(),auth_user_id uuid not null references public.customer_accounts,payment_order_id uuid not null references public.payment_orders,amount_kobo bigint not null check(amount_kobo>0),reason text not null,state text not null default 'requested' check(state in ('requested','approved','rejected','processing','refunded','failed')),provider_refund_id text unique,created_at timestamptz not null default now());
create unique index one_open_refund on public.refund_requests(payment_order_id) where state in ('requested','approved','processing');
alter table private.integration_events add column published_at timestamptz,add column attempt_count integer not null default 0,add column next_attempt_at timestamptz not null default now();
create table private.integration_inbox(event_id uuid primary key,booking_id uuid not null references public.bookings,event_type text not null,sequence bigint not null,payload jsonb not null,state text not null default 'received' check(state in ('received','applied','reconcile')),received_at timestamptz not null default now(),unique(booking_id,sequence));
alter table private.integration_inbox enable row level security;
create table private.reward_rules(id uuid primary key default gen_random_uuid(),category_id uuid not null references public.waste_categories,points integer not null check(points>0),version text not null,active boolean not null default false);
alter table private.reward_rules enable row level security;

create function private.require_customer(approved boolean default false) returns uuid language plpgsql security definer set search_path='' as $$
declare actor uuid:=auth.uid();
begin
 if actor is null or not exists(select 1 from public.customer_accounts a join auth.users u on u.id=a.auth_user_id where a.auth_user_id=actor and a.status='active' and u.email_confirmed_at is not null and (not approved or a.verification_status='approved')) then raise exception 'Customer authorization required' using errcode='42501';end if;
 return actor;
end $$;

create function private.org_access(org uuid,booking boolean default false) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.organization_members m where m.organization_id=org and m.auth_user_id=auth.uid() and m.active and (not booking or m.can_book));
$$;
create function private.staff(capability text) returns boolean language sql stable security definer set search_path='' as $$
 select coalesce(auth.jwt()->>'aal','')='aal2' and exists(select 1 from private.admin_members m where m.auth_user_id=auth.uid() and case capability when 'review' then m.can_review when 'support' then m.can_support when 'payments' then m.can_payments when 'operations' then m.can_operations else false end);
$$;
-- Helpers expose only decisions about the caller and have no caller-controlled actor ID.
grant usage on schema private to authenticated;
revoke all on function private.require_customer(boolean),private.org_access(uuid,boolean),private.staff(text) from public,anon;
grant execute on function private.org_access(uuid,boolean),private.staff(text) to authenticated;
revoke all on function private.require_customer(boolean) from authenticated;

do $$ declare t text;begin
 foreach t in array array['organizations','organization_members','service_destinations','collection_slots','pricing_rules','booking_status_history','verification_applications','receipts','refund_requests'] loop
 execute format('alter table public.%I enable row level security',t);
 execute format('revoke all on public.%I from anon,authenticated',t);
 execute format('grant select on public.%I to authenticated',t);
 end loop;
 foreach t in array array['booking_status_history','verification_applications','receipts','refund_requests'] loop
 execute format('create policy owner_read on public.%I for select to authenticated using(auth_user_id=(select auth.uid()))',t);
 end loop;
 foreach t in array array['service_destinations','collection_slots','pricing_rules'] loop
 execute format('create policy active_read on public.%I for select to authenticated using(active)',t);
 end loop;
end $$;
create policy org_read on public.organizations for select to authenticated using(private.org_access(id));
create policy membership_read on public.organization_members for select to authenticated using(auth_user_id=(select auth.uid()) or exists(select 1 from public.organizations o where o.id=organization_id and o.owner_id=(select auth.uid())));
alter policy owner_read on public.customer_addresses using (organization_id is null and auth_user_id=(select auth.uid()));
create policy org_address_read on public.customer_addresses for select to authenticated using(private.org_access(organization_id));
alter policy owner_read on public.bookings using (organization_id is null and auth_user_id=(select auth.uid()));
create policy org_booking_read on public.bookings for select to authenticated using(private.org_access(organization_id));
create policy review_queue on public.verification_applications for select to authenticated using(private.staff('review'));
create policy reviewer_documents on public.verification_documents for select to authenticated using(private.staff('review'));
create policy support_queue on public.support_tickets for select to authenticated using(private.staff('support'));
create policy payment_exceptions on public.payment_orders for select to authenticated using(private.staff('payments'));
create policy booking_exceptions on public.bookings for select to authenticated using(private.staff('operations'));
-- Column grants prevent forging an organization or coverage reference via direct inserts.
revoke insert on public.customer_addresses from authenticated;
revoke insert(auth_user_id,label,address_text) on public.customer_addresses from authenticated;

create function public.create_organization(org_name text) returns uuid language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_customer(); result uuid;
begin
 if not exists(select 1 from public.customer_accounts where auth_user_id=actor and account_type in ('estate','business')) then raise exception 'Organization account required';end if;
 insert into public.organizations(owner_id,name) values(actor,org_name) returning id into result;
 insert into public.organization_members values(result,actor,true,true);
 insert into private.audit_events(actor,event_type,subject_id) values(actor,'organization.created',result);
 return result;
end $$;
create function public.set_organization_member(org uuid,member uuid,may_book boolean,enabled boolean) returns void language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_customer();
begin
 if not exists(select 1 from public.organizations where id=org and owner_id=actor) or member=actor then raise exception 'Organization owner required';end if;
 insert into public.organization_members values(org,member,may_book,enabled) on conflict(organization_id,auth_user_id) do update set can_book=excluded.can_book,active=excluded.active;
 insert into private.audit_events(actor,event_type,subject_id,details) values(actor,'organization.membership_changed',org,jsonb_build_object('member',member,'active',enabled,'can_book',may_book));
end $$;
create function public.save_address(label text,address_text text,coverage uuid,organization uuid default null) returns uuid language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_customer(); result uuid;
begin
 if length(trim(label)) not between 1 and 100 or length(trim(address_text)) not between 10 and 1000 then raise exception 'Invalid address';end if;
 if organization is not null and not private.org_access(organization,true) then raise exception 'Organization access denied';end if;
 if not exists(select 1 from public.service_availability where id=coverage and active) then raise exception 'Coverage unavailable';end if;
 insert into public.customer_addresses(auth_user_id,label,address_text,coverage_id,organization_id) values(actor,label,address_text,coverage,organization) returning id into result;
 return result;
end $$;

create function public.request_quote(address uuid,category uuid,slot uuid,quantity numeric,unit text,prepared boolean default false,destination uuid default null) returns public.quotes language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_customer(true); a public.customer_addresses;c public.waste_categories;s public.collection_slots;r public.pricing_rules;q public.quotes;amount bigint;
begin
 select * into a from public.customer_addresses where id=address;
 if a.id is null or not a.coverage_verified or not (a.auth_user_id=actor or private.org_access(a.organization_id,true)) then raise exception 'Address unavailable';end if;
 if a.organization_id is not null and not private.org_access(a.organization_id,true) then raise exception 'Organization access denied';end if;
 select * into c from public.waste_categories where id=category and active and not hazardous;
 select * into s from public.collection_slots where id=slot and active and starts_at>now();
 if c.id is null or s.id is null or s.coverage_id<>a.coverage_id or not exists(select 1 from public.service_availability v where v.id=a.coverage_id and v.active and v.service=c.service) then raise exception 'Unsupported service, category or schedule';end if;
 if c.service='send' and (prepared is distinct from true or destination is null or not exists(select 1 from public.service_destinations where id=destination and active and category_id=c.id and coverage_id=a.coverage_id)) then raise exception 'Preparation and authorized destination required';end if;
 select * into r from public.pricing_rules p where p.coverage_id=a.coverage_id and p.category_id=c.id and p.unit=request_quote.unit and p.active;
 if r.id is null or quantity is null or scale(quantity)>3 or (unit='container' and quantity<>trunc(quantity)) or quantity::text in ('NaN','Infinity','-Infinity') or quantity<r.minimum_quantity or quantity>r.maximum_quantity then raise exception 'Configured price and valid quantity required';end if;
 amount=r.base_kobo+ceil(r.unit_kobo*quantity)::bigint;
 if amount<=0 or amount>9007199254740991 then raise exception 'Invalid quote amount';end if;
 insert into public.quotes(auth_user_id,amount_kobo,items,expires_at,address_id,category_id,slot_id,rule_id,quantity,destination_id,address_snapshot,preparation_confirmed,organization_id)
 values(actor,amount,jsonb_build_object('base_kobo',r.base_kobo,'unit_kobo',r.unit_kobo,'quantity',quantity,'unit',unit,'rule_version',r.version),least(now()+interval '15 minutes',s.starts_at),a.id,c.id,s.id,r.id,quantity,destination,to_jsonb(a),prepared,a.organization_id) returning * into q;
 return q;
end $$;

create function private.booking_event() returns trigger language plpgsql security definer set search_path='' as $$
declare seq bigint;
begin
 if tg_op='INSERT' or new.status is distinct from old.status then
 insert into public.booking_status_history(booking_id,auth_user_id,status) values(new.id,new.auth_user_id,new.status);
 insert into public.customer_notifications(auth_user_id,body) values(new.auth_user_id,'Booking status: '||new.status);
 select coalesce(max(sequence),0)+1 into seq from private.integration_events where booking_id=new.id;
 insert into private.integration_events(booking_id,event_type,sequence,payload) values(new.id,case when tg_op='INSERT' then 'booking.created' else 'booking.status_changed' end,seq,jsonb_build_object('status',new.status));
 end if;return new;
end $$;
create trigger booking_history after insert or update of status on public.bookings for each row execute function private.booking_event();
create function public.create_booking(quote uuid,idempotency uuid) returns public.bookings language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_customer(true);q public.quotes;s public.collection_slots;b public.bookings;
begin
 if idempotency is null then raise exception 'Idempotency key required';end if;
 perform pg_advisory_xact_lock(hashtextextended(actor::text||idempotency::text,0));
 select * into b from public.bookings where auth_user_id=actor and idempotency_key=idempotency;
 if b.id is not null then if b.quote_id<>quote then raise exception 'Idempotency key reused with different quote';end if;return b;end if;
 select * into q from public.quotes where id=quote and auth_user_id=actor for update;
 if q.id is null or q.expires_at<=now() then raise exception 'Quote unavailable or expired';end if;
 if q.organization_id is not null and not private.org_access(q.organization_id,true) then raise exception 'Organization access denied';end if;
 if not exists(select 1 from public.customer_addresses a join public.collection_slots cs on cs.coverage_id=a.coverage_id where a.id=q.address_id and a.coverage_verified and cs.id=q.slot_id) then raise exception 'Collection address eligibility changed';end if;
 if q.destination_id is not null and not exists(select 1 from public.service_destinations where id=q.destination_id and active) then raise exception 'Destination unavailable';end if;
 select * into s from public.collection_slots where id=q.slot_id and active and starts_at>now() for update;
 if s.id is null or (select count(*) from public.bookings where slot_id=s.id and status<>'cancelled')>=s.capacity then raise exception 'Collection slot unavailable';end if;
 if not exists(select 1 from public.waste_categories where id=q.category_id and active and not hazardous) or not exists(select 1 from public.service_availability where id=s.coverage_id and active) then raise exception 'Service unavailable';end if;
 insert into public.bookings(auth_user_id,service,address_snapshot,requested_at,quote_id,idempotency_key,slot_id,organization_id)
 select actor,c.service,q.address_snapshot,s.starts_at,q.id,idempotency,s.id,q.organization_id from public.waste_categories c where c.id=q.category_id returning * into b;
 return b;
end $$;
create function public.cancel_booking(booking uuid) returns void language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_customer();b public.bookings;
begin
 select * into b from public.bookings where id=booking and auth_user_id=actor for update;
 if b.id is null or (b.organization_id is not null and not private.org_access(b.organization_id,true)) then raise exception 'Booking unavailable';end if;
 if b.status='cancelled' then return;end if;
 if b.status not in ('awaiting_assignment','scheduled','assignment_unavailable','collection_pending') or b.requested_at<=now() or b.payment_status<>'pending' or exists(select 1 from public.payment_orders where booking_id=b.id) then raise exception 'Cancellation requires support review';end if;
 update public.bookings set status='cancelled' where id=b.id;
end $$;
create function public.reschedule_booking(booking uuid,new_slot uuid) returns void language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_customer(true);b public.bookings;s public.collection_slots;
begin
 select * into b from public.bookings where id=booking and auth_user_id=actor for update;
 if b.id is null or (b.organization_id is not null and not private.org_access(b.organization_id,true)) or b.status<>'awaiting_assignment' or b.payment_status<>'pending' or exists(select 1 from public.payment_orders where booking_id=b.id) then raise exception 'Reschedule requires support review';end if;
 select * into s from public.collection_slots where id=new_slot and active and starts_at>now() for update;
 if s.id is null or not exists(select 1 from public.collection_slots old where old.id=b.slot_id and old.coverage_id=s.coverage_id) or (select count(*) from public.bookings where slot_id=s.id and status<>'cancelled' and id<>b.id)>=s.capacity then raise exception 'Slot unavailable';end if;
 update public.bookings set slot_id=s.id,requested_at=s.starts_at where id=b.id;
 insert into private.audit_events(actor,event_type,subject_id,details) values(actor,'booking.rescheduled',b.id,jsonb_build_object('slot',s.id));
end $$;

create or replace function public.submit_verification_document(requirement uuid,object_path text) returns void language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_customer();a public.customer_accounts;app public.verification_applications;
begin
 select * into a from public.customer_accounts where auth_user_id=actor for update;
 if a.verification_status not in ('not_started','corrections_required','rejected') then raise exception 'Submission unavailable';end if;
 if not exists(select 1 from public.verification_requirements where id=requirement and account_type=a.account_type and active) then raise exception 'Invalid requirement';end if;
 if split_part(object_path,'/',1)<>actor::text or not exists(select 1 from storage.objects where bucket_id='verification' and name=object_path) then raise exception 'Missing uploaded document';end if;
 select * into app from public.verification_applications where auth_user_id=actor and state='not_started';
 if app.id is null then insert into public.verification_applications(auth_user_id) values(actor) returning * into app;end if;
 insert into public.verification_documents(auth_user_id,requirement_id,storage_path,application_id) values(actor,requirement,object_path,app.id);
 if not exists(select 1 from public.verification_requirements r where r.account_type=a.account_type and r.active and not exists(select 1 from public.verification_documents d where d.application_id=app.id and d.requirement_id=r.id)) then
 update public.verification_applications set state='submitted',submitted_at=now() where id=app.id;
 update public.customer_accounts set verification_status='submitted' where auth_user_id=actor;
 insert into public.customer_notifications(auth_user_id,body) values(actor,'Your verification was submitted for review.');
 end if;
end $$;
create or replace function public.review_verification(subject uuid,decision public.verification_state,reason text) returns void language plpgsql security definer set search_path='' as $$
declare app public.verification_applications;
begin
 if not private.staff('review') then raise exception 'Authorized MFA review required' using errcode='42501';end if;
 if decision not in ('approved','rejected','corrections_required','under_review') or reason is null or length(trim(reason))<10 then raise exception 'Invalid review';end if;
 perform 1 from public.customer_accounts where auth_user_id=subject for update;
 select * into app from public.verification_applications where auth_user_id=subject and state in ('submitted','under_review') for update;
 if app.id is null then raise exception 'No submitted review';end if;
 update public.verification_applications set state=decision,reviewed_at=now(),review_reason=reason where id=app.id;
 update public.customer_accounts set verification_status=decision where auth_user_id=subject;
 insert into private.review_audit(actor,subject,decision,reason) values(auth.uid(),subject,decision::text,reason);
 insert into public.customer_notifications(auth_user_id,body) values(subject,'Verification status: '||decision::text);
end $$;
create policy staff_document_read on storage.objects for select to authenticated using(bucket_id='verification' and private.staff('review') and exists(select 1 from public.verification_documents d where d.storage_path=name));
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values
('support-evidence','support-evidence',false,10485760,array['application/pdf','image/jpeg','image/png']),
('receipt-attachments','receipt-attachments',false,5242880,array['application/pdf']);
create policy support_evidence_upload on storage.objects for insert to authenticated with check(bucket_id='support-evidence' and (storage.foldername(name))[1]=(select auth.uid())::text);
create policy private_attachment_read on storage.objects for select to authenticated using(bucket_id in ('support-evidence','receipt-attachments') and ((storage.foldername(name))[1]=(select auth.uid())::text or (bucket_id='support-evidence' and private.staff('support'))));
create function public.update_support_ticket(ticket uuid,new_status text) returns void language plpgsql security definer set search_path='' as $$
begin
 if not private.staff('support') then raise exception 'Support permission required' using errcode='42501';end if;
 if new_status not in ('open','under_review','resolved','closed') then raise exception 'Invalid status';end if;
 update public.support_tickets set status=new_status where id=ticket;
 if not found then raise exception 'Ticket unavailable';end if;
 insert into private.audit_events(actor,event_type,subject_id,details) values(auth.uid(),'support.status_changed',ticket,jsonb_build_object('status',new_status));
end $$;

create function public.prepare_payment(booking uuid) returns public.payment_orders language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_customer(true);b public.bookings;q public.quotes;p public.payment_orders;
begin
 select * into b from public.bookings where id=booking and auth_user_id=actor for update;
 if b.id is null or (b.organization_id is not null and not private.org_access(b.organization_id,true)) or b.status='cancelled' or b.payment_status<>'pending' or b.requested_at<=now() then raise exception 'Booking not payable';end if;
 select * into p from public.payment_orders where booking_id=b.id;
 if p.id is not null then return p;end if;
 select * into q from public.quotes where id=b.quote_id;
 insert into public.payment_orders(auth_user_id,booking_id,provider_reference,amount_kobo) values(actor,b.id,'tydigo-'||gen_random_uuid()::text,q.amount_kobo) returning * into p;
 return p;
end $$;
-- Service-role-only settlement, invoked only after Paystack server verification.
create function public.record_verified_payment(reference text,provider_id text,amount bigint,currency_code text) returns uuid language plpgsql security definer set search_path='' as $$
declare p public.payment_orders;receipt uuid;seq bigint;
begin
 select * into p from public.payment_orders where provider_reference=reference for update;
 if p.id is null or provider_id is null or length(provider_id)=0 or p.amount_kobo is distinct from amount or currency_code is distinct from 'NGN' then raise exception 'Payment verification mismatch';end if;
 if p.status in ('paid','refunded') then
 if p.provider_transaction_id<>provider_id then raise exception 'Provider ID conflict';end if;
 select id into receipt from public.receipts where payment_order_id=p.id;return receipt;end if;
 insert into private.payment_events(provider_transaction_id,reference,amount_kobo) values(provider_id,reference,amount);
 update public.payment_orders set status='paid',provider_transaction_id=provider_id,updated_at=now() where id=p.id;
 update public.bookings set payment_status='paid' where id=p.booking_id;
 insert into public.receipts(auth_user_id,payment_order_id,amount_kobo,currency) values(p.auth_user_id,p.id,amount,'NGN') returning id into receipt;
 insert into public.customer_notifications(auth_user_id,body) values(p.auth_user_id,'Payment confirmed. Your receipt is available.');
 insert into private.audit_events(event_type,subject_id,details) values('payment.verified',p.id,jsonb_build_object('provider_transaction_id',provider_id));
 select coalesce(max(sequence),0)+1 into seq from private.integration_events where booking_id=p.booking_id;
 insert into private.integration_events(booking_id,event_type,sequence,payload)
 values(p.booking_id,'booking.ready_for_assignment',seq,'{}');
 return receipt;
end $$;
create function public.request_refund(payment uuid,reason text) returns uuid language plpgsql security definer set search_path='' as $$
declare actor uuid:=private.require_customer();p public.payment_orders;result uuid;
begin
 select * into p from public.payment_orders where id=payment and auth_user_id=actor for update;
 if p.id is null or p.status<>'paid' or reason is null or length(trim(reason)) not between 10 and 2000 then raise exception 'Refund request unavailable';end if;
 select id into result from public.refund_requests where payment_order_id=p.id and state in ('requested','approved','processing');
 if result is not null then return result;end if;
 if exists(select 1 from public.refund_requests where payment_order_id=p.id and state='refunded') then raise exception 'Already refunded';end if;
 insert into public.refund_requests(auth_user_id,payment_order_id,amount_kobo,reason) values(actor,p.id,p.amount_kobo,reason) returning id into result;
 return result;
end $$;
create function public.record_verified_refund(reference text,provider_refund text,amount bigint) returns void language plpgsql security definer set search_path='' as $$
declare p public.payment_orders;r public.refund_requests;
begin
 select * into p from public.payment_orders where provider_reference=reference for update;
 select * into r from public.refund_requests where payment_order_id=p.id and state in ('approved','processing','refunded') for update;
 if p.id is null or r.id is null or r.amount_kobo is distinct from amount or provider_refund is null then raise exception 'Refund reconciliation mismatch';end if;
 if r.state='refunded' then if r.provider_refund_id<>provider_refund then raise exception 'Refund ID conflict';end if;return;end if;
 update public.refund_requests set state='refunded',provider_refund_id=provider_refund where id=r.id;
 update public.payment_orders set status='refunded',updated_at=now() where id=p.id;
 update public.bookings set payment_status='refunded' where id=p.booking_id;
 insert into private.audit_events(event_type,subject_id) values('refund.reconciled',r.id);
end $$;

create function public.receive_integration_event(event_id uuid,booking uuid,kind text,event_sequence bigint,event_payload jsonb) returns text language plpgsql security definer set search_path='' as $$
declare b public.bookings;existing private.integration_inbox;
begin
 if kind is null or event_id is null or event_sequence is null or kind not in ('booking.ready_for_assignment','booking.assigned','booking.pickup_started','booking.collection_verified','booking.completed','booking.cancelled') or event_sequence<1 or event_payload is null or jsonb_typeof(event_payload)<>'object' or octet_length(event_payload::text)>10000 then raise exception 'Invalid event envelope';end if;
 select * into b from public.bookings where id=booking for update;
 if b.id is null then raise exception 'Unknown booking';end if;
 select * into existing from private.integration_inbox i where i.event_id=receive_integration_event.event_id;
 if existing.event_id is not null then
 if existing.booking_id<>booking or existing.event_type<>kind or existing.sequence<>event_sequence or existing.payload<>event_payload then raise exception 'Event ID conflict';end if;
 return existing.state;end if;
 insert into private.integration_inbox(event_id,booking_id,event_type,sequence,payload,state) values(event_id,booking,kind,event_sequence,event_payload,'reconcile');
 -- No operational system is authorized yet: queue evidence for controlled reconciliation.
 -- An event cannot directly alter money, rewards, assignment or customer-facing completion.
 return 'reconcile';
end $$;

-- Explicit grants for every new callable endpoint.
do $$ declare f record;begin
 for f in select p.oid::regprocedure as signature from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in ('create_organization','set_organization_member','save_address','request_quote','create_booking','cancel_booking','reschedule_booking','submit_verification_document','review_verification','update_support_ticket','prepare_payment','request_refund') loop
 execute format('revoke all on function %s from public,anon',f.signature);
 execute format('grant execute on function %s to authenticated',f.signature);
 end loop;
end $$;
revoke all on function public.record_verified_payment(text,text,bigint,text),public.record_verified_refund(text,text,bigint),public.receive_integration_event(uuid,uuid,text,bigint,jsonb) from public,anon,authenticated;
grant execute on function public.record_verified_payment(text,text,bigint,text),public.record_verified_refund(text,text,bigint),public.receive_integration_event(uuid,uuid,text,bigint,jsonb) to service_role;
revoke all on function private.booking_event() from public,anon,authenticated;
grant select,insert,update on public.payment_orders to service_role;
grant select on public.refund_requests,public.customer_accounts,public.bookings to service_role;
-- PostgreSQL Changes delivery still applies SELECT RLS for each subscriber.
do $$ declare t text;begin
 if exists(select 1 from pg_publication where pubname='supabase_realtime') then
 foreach t in array array['customer_notifications'] loop
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename=t) then execute format('alter publication supabase_realtime add table public.%I',t);end if;
 end loop;end if;
end $$;

create function public.verify_address_coverage(address uuid, approved boolean) returns void
language plpgsql security definer set search_path='' as $$
begin
 if not private.staff('operations') then raise exception 'Operations permission required' using errcode='42501';end if;
 update public.customer_addresses a set coverage_verified=approved
 where a.id=address and (not approved or exists(select 1 from public.service_availability v where v.id=a.coverage_id and v.active));
 if not found then raise exception 'Address or coverage unavailable';end if;
 insert into private.audit_events(actor,event_type,subject_id,details)
 values(auth.uid(),'address.coverage_reviewed',address,jsonb_build_object('approved',approved));
end $$;
revoke all on function public.verify_address_coverage(uuid,boolean) from public,anon;
grant execute on function public.verify_address_coverage(uuid,boolean) to authenticated;

create function public.get_operational_audit(before_id bigint default null)
returns setof private.audit_events language plpgsql stable security definer set search_path='' as $$
begin
 if not private.staff('operations') then raise exception 'Operations permission required' using errcode='42501';end if;
 return query select * from private.audit_events where before_id is null or id<before_id order by id desc limit 100;
end $$;
revoke all on function public.get_operational_audit(bigint) from public,anon;
grant execute on function public.get_operational_audit(bigint) to authenticated;

create function private.notify_support_status() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 if new.status is distinct from old.status then
  insert into public.customer_notifications(auth_user_id,body)
  values(new.auth_user_id,'A support ticket status was updated.');
 end if;
 return new;
end $$;
create trigger support_status_changed after update of status on public.support_tickets
for each row execute function private.notify_support_status();
revoke all on function private.notify_support_status() from public,anon,authenticated;

create function public.record_payment_outcome(reference text, outcome text) returns text
language plpgsql security definer set search_path='' as $$
declare payment public.payment_orders;
begin
 if outcome is null or outcome not in ('failed','cancelled') then raise exception 'Unsupported payment outcome';end if;
 select * into payment from public.payment_orders where provider_reference=reference for update;
 if payment.id is null then raise exception 'Payment unavailable';end if;
 if payment.status in ('paid','refunded') then return payment.status;end if;
 if payment.status is distinct from outcome then
  update public.payment_orders set status=outcome,updated_at=now() where id=payment.id;
  insert into public.customer_notifications(auth_user_id,body)
  values(payment.auth_user_id,'Payment status: '||outcome);
 end if;
 return outcome;
end $$;
revoke all on function public.record_payment_outcome(text,text) from public,anon,authenticated;
grant execute on function public.record_payment_outcome(text,text) to service_role;

create function public.review_refund(refund uuid, approval boolean, note text) returns void
language plpgsql security definer set search_path='' as $$
begin
 if not private.staff('payments') then raise exception 'Payments permission required' using errcode='42501';end if;
 if approval is null or note is null or length(trim(note)) not between 10 and 2000 then raise exception 'A review decision and reason are required';end if;
 update public.refund_requests set state=case when approval then 'approved' else 'rejected' end
 where id=refund and state='requested';
 if not found then raise exception 'Refund unavailable for review';end if;
 insert into private.audit_events(actor,event_type,subject_id,details)
 values(auth.uid(),'refund.reviewed',refund,jsonb_build_object('approved',approval,'reason',note));
end $$;
revoke all on function public.review_refund(uuid,boolean,text) from public,anon;
grant execute on function public.review_refund(uuid,boolean,text) to authenticated;
create policy refund_review_queue on public.refund_requests for select to authenticated using(private.staff('payments'));

create function public.list_collection_slots(address uuid)
returns table(id uuid, starts_at timestamptz, ends_at timestamptz)
language plpgsql stable security definer set search_path='' as $$
declare actor uuid:=private.require_customer(true); location public.customer_addresses;
begin
 select a.* into location from public.customer_addresses a
 where a.id=address and a.coverage_verified
 and ((a.organization_id is null and a.auth_user_id=actor) or private.org_access(a.organization_id,true));
 if location.id is null then raise exception 'Verified collection address required';end if;
 return query select s.id,s.starts_at,s.ends_at from public.collection_slots s
 join public.service_availability v on v.id=s.coverage_id and v.active
 where s.coverage_id=location.coverage_id and s.active and s.starts_at>now()
 and (select count(*) from public.bookings b where b.slot_id=s.id and b.status<>'cancelled')<s.capacity
 order by s.starts_at limit 100;
end $$;
revoke all on function public.list_collection_slots(uuid) from public,anon;
grant execute on function public.list_collection_slots(uuid) to authenticated;

