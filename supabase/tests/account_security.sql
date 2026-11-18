begin;
-- Ephemeral database-only fixtures. No emails, sessions or records survive rollback.
insert into auth.users(id,email,raw_user_meta_data,email_confirmed_at)
values
('10000000-0000-4000-8000-000000000001','household@isolated.invalid','{"account_type":"household","display_name":"Isolated household"}',now()),
('10000000-0000-4000-8000-000000000002','estate@isolated.invalid','{"account_type":"estate","display_name":"Isolated estate"}',now()),
('10000000-0000-4000-8000-000000000003','business@isolated.invalid','{"account_type":"business","display_name":"Isolated business"}',now());
do $$ begin
 if (select count(*) from public.customer_accounts where auth_user_id in ('10000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000003'))<>3 then raise exception 'Canonical trigger failed';end if;
 begin
 insert into auth.users(id,email,raw_user_meta_data) values('10000000-0000-4000-8000-000000000004','invalid@isolated.invalid','{"account_type":"admin","display_name":"Invalid"}');
 raise exception 'Invalid category accepted';
 exception when raise_exception then
 if sqlerrm='Invalid category accepted' then raise;end if;
 end;
end $$;
select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-8000-000000000001","role":"authenticated","aal":"aal1"}',true);
set local role authenticated;
do $$ begin
 if (select count(*) from public.customer_accounts)<>1 then raise exception 'Owner isolation failed'; end if;
 if (select account_type from public.customer_accounts)<>'household' then raise exception 'Wrong canonical role';end if;
 begin
 update public.customer_accounts set account_type='business';
 raise exception 'Role mutation allowed';
 exception when insufficient_privilege then null;end;
 begin
 insert into public.bookings(auth_user_id,service,address_snapshot,requested_at,quote_id,idempotency_key)
 values(auth.uid(),'drive','{}',now(),gen_random_uuid(),gen_random_uuid());
 raise exception 'Unapproved direct booking allowed';
 exception when insufficient_privilege then null;end;
 begin
 perform public.review_verification(auth.uid(),'approved','Unauthorized test approval');
 raise exception 'Nonstaff review allowed';
 exception when insufficient_privilege then null;
 when raise_exception then
 if sqlerrm<>'Authorized MFA review required' then raise;end if;
 end;
end $$;
reset role;
update auth.users set raw_user_meta_data='{"account_type":"business","display_name":"Changed metadata"}' where id='10000000-0000-4000-8000-000000000001';
do $$ begin
 if (select account_type from public.customer_accounts where auth_user_id='10000000-0000-4000-8000-000000000001')<>'household' then raise exception 'Metadata changed canonical role';end if;
 if exists(select 1 from pg_tables where schemaname='public' and not rowsecurity) then raise exception 'Unprotected public table';end if;
end $$;
select 'PASS: canonical signup for three categories; invalid category rejection; owner isolation; immutable role; unapproved booking denial; nonstaff review denial; metadata spoof resistance; public RLS' as result;
rollback;

