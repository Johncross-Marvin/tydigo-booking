begin;
do $$ begin
 if exists (
  select 1 from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.prosecdef
  and (has_function_privilege('authenticated',p.oid,'execute') or has_function_privilege('anon',p.oid,'execute'))
 ) then raise exception 'Elevated public implementation is executable by a client';end if;
end $$;
insert into auth.users(id,email,raw_user_meta_data,email_confirmed_at) values
('10000000-0000-4000-8000-000000000011','customer@isolated.invalid','{"account_type":"estate","display_name":"Estate fixture"}',now()),
('10000000-0000-4000-8000-000000000012','other@isolated.invalid','{"account_type":"business","display_name":"Business fixture"}',now()),
('10000000-0000-4000-8000-000000000013','reviewer@isolated.invalid','{"account_type":"household","display_name":"Staff fixture"}',now()),
('10000000-0000-4000-8000-000000000014','unconfirmed@isolated.invalid','{"account_type":"household","display_name":"Unconfirmed fixture"}',null);
insert into private.admin_members(auth_user_id,can_review,can_operations,can_payments) values('10000000-0000-4000-8000-000000000013',true,true,true);
insert into public.verification_requirements(id,account_type,label,active) values('20000000-0000-4000-8000-000000000001','estate','Fixture requirement',true);
insert into public.service_availability(id,service,area_name,active) values
('30000000-0000-4000-8000-000000000001','drive','Fixture Drive zone',true),
('30000000-0000-4000-8000-000000000002','send','Fixture Send zone',true);
insert into public.waste_categories(id,label,service,preparation,active) values
('40000000-0000-4000-8000-000000000001','Fixture general','drive','Fixture',true),
('40000000-0000-4000-8000-000000000002','Fixture recyclables','send','Separate material',true);
insert into public.collection_slots(id,coverage_id,starts_at,ends_at,capacity,active) values
('50000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000001',now()+interval '1 day',now()+interval '25 hours',1,true),
('50000000-0000-4000-8000-000000000002','30000000-0000-4000-8000-000000000002',now()+interval '1 day',now()+interval '25 hours',1,true);
insert into public.service_destinations(id,name,category_id,coverage_id,authorization_reference,active) values
('60000000-0000-4000-8000-000000000002','Fixture disposal facility','40000000-0000-4000-8000-000000000001','30000000-0000-4000-8000-000000000001','Fixture authorization',true),
('60000000-0000-4000-8000-000000000001','Fixture recycler','40000000-0000-4000-8000-000000000002','30000000-0000-4000-8000-000000000002','Fixture authorization',true);
insert into public.pricing_rules(coverage_id,category_id,unit,base_kobo,unit_kobo,minimum_quantity,maximum_quantity,version,active) values
('30000000-0000-4000-8000-000000000001','40000000-0000-4000-8000-000000000001','kg',100,250,1,100,'test',true),
('30000000-0000-4000-8000-000000000002','40000000-0000-4000-8000-000000000002','kg',150,300,1,100,'test',true);

set local role anon;
do $$ begin
 begin perform public.create_booking(gen_random_uuid(),gen_random_uuid());raise exception 'Anonymous booking allowed';
 exception when insufficient_privilege then null;end;
end $$;
reset role;

set local role authenticated;
select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-8000-000000000014","aal":"aal1"}',true);
do $$ begin
 begin perform public.save_address('Fixture','Fixture example road','30000000-0000-4000-8000-000000000001');raise exception 'Unconfirmed account accepted';
 exception when insufficient_privilege then null;end;
end $$;

select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-8000-000000000011","aal":"aal1"}',true);
do $$
declare org uuid;adr uuid;path text:=auth.uid()::text||'/20000000-0000-4000-8000-000000000001/first.pdf';
begin
 org:=public.create_organization('Fixture estate');
 adr:=public.save_address('Drive premise','Fixture example road','30000000-0000-4000-8000-000000000001',org);
 perform set_config('test.organization',org::text,true);
 perform set_config('test.address',adr::text,true);
 perform set_config('test.send_address',public.save_address('Send premise','Fixture example road','30000000-0000-4000-8000-000000000002',org)::text,true);
 begin perform public.create_booking(gen_random_uuid(),gen_random_uuid());raise exception 'Pending KYC booking allowed';
 exception when insufficient_privilege then null;end;
 insert into storage.objects(bucket_id,name) values('verification',path);
 perform public.submit_verification_document('20000000-0000-4000-8000-000000000001',path);
 if (select verification_status from public.customer_accounts)<>'submitted' then raise exception 'Submission did not update KYC state';end if;
end $$;
select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-8000-000000000012","aal":"aal1"}',true);
do $$ begin
 if exists(select 1 from storage.objects) or exists(select 1 from public.customer_addresses) or exists(select 1 from public.verification_applications) then raise exception 'Cross-account access';end if;
 begin insert into storage.objects(bucket_id,name) values('verification','10000000-0000-4000-8000-000000000011/forged');
 raise exception 'Cross-owner upload allowed';exception when insufficient_privilege then null;end;
end $$;
select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-8000-000000000013","aal":"aal1"}',true);
do $$ begin
 begin perform public.review_verification('10000000-0000-4000-8000-000000000011','approved','Fixture verification review');raise exception 'Non-MFA approval';
 exception when insufficient_privilege then null;end;
end $$;
select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-8000-000000000013","aal":"aal2"}',true);
do $$ begin
 if not exists(select 1 from storage.objects where bucket_id='verification') then raise exception 'Reviewer access missing';end if;
 perform public.review_verification('10000000-0000-4000-8000-000000000011','corrections_required','Fixture correction requested');
 perform public.verify_address_coverage(current_setting('test.address')::uuid,true);
 perform public.verify_address_coverage(current_setting('test.send_address')::uuid,true);
end $$;
select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-8000-000000000011","aal":"aal1"}',true);
do $$ declare path text:=auth.uid()::text||'/20000000-0000-4000-8000-000000000001/corrected.pdf';begin
 insert into storage.objects(bucket_id,name) values('verification',path);
 perform public.submit_verification_document('20000000-0000-4000-8000-000000000001',path);
end $$;
select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-8000-000000000013","aal":"aal2"}',true);
select public.review_verification('10000000-0000-4000-8000-000000000011','approved','Fixture corrected document verified');
select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-8000-000000000011","aal":"aal1"}',true);
do $$
declare q public.quotes;b public.bookings;p public.payment_orders;k uuid:=gen_random_uuid();
begin
 q:=public.request_quote(current_setting('test.address')::uuid,'40000000-0000-4000-8000-000000000001','50000000-0000-4000-8000-000000000001',2,'kg');
 if q.amount_kobo<>600 or q.destination_id is distinct from '60000000-0000-4000-8000-000000000002'::uuid then raise exception 'Drive price or destination incorrect';end if;
 if (select count(*) from public.list_collection_slots(current_setting('test.address')::uuid))<>1 then raise exception 'Available slot missing';end if;
 b:=public.create_booking(q.id,k);
 if (public.create_booking(q.id,k)).id<>b.id or (select count(*) from public.bookings)<>1 then raise exception 'Duplicate booking';end if;
 if exists(select 1 from public.list_collection_slots(current_setting('test.address')::uuid)) then raise exception 'Full slot exposed as available';end if;
 p:=public.prepare_payment(b.id);
 if (public.prepare_payment(b.id)).id<>p.id or p.amount_kobo<>600 then raise exception 'Payment intent mismatch';end if;
 perform set_config('test.reference',p.provider_reference,true);
 perform set_config('test.booking',b.id::text,true);
 begin perform public.record_booking_outcome(b.id,'scheduled','customer-issued-reference');raise exception 'Customer can record outcomes';
 exception when insufficient_privilege then null;end;
 begin
  perform public.request_quote(current_setting('test.send_address')::uuid,'40000000-0000-4000-8000-000000000002','50000000-0000-4000-8000-000000000002',2,'kg',false,'60000000-0000-4000-8000-000000000001');
  raise exception 'Unprepared Send accepted';
 exception when raise_exception then if sqlerrm not like 'Preparation%' then raise;end if;end;
 q:=public.request_quote(current_setting('test.send_address')::uuid,'40000000-0000-4000-8000-000000000002','50000000-0000-4000-8000-000000000002',2,'kg',true,'60000000-0000-4000-8000-000000000001');
 if q.amount_kobo<>750 or (public.create_booking(q.id,gen_random_uuid())).service<>'send' then raise exception 'Send contract failed';end if;
 begin perform public.record_verified_payment(p.provider_reference,'1001',600,'NGN');raise exception 'Customer can settle payment';
 exception when insufficient_privilege then null;end;
 begin perform public.receive_integration_event(gen_random_uuid(),b.id,'booking.completed',1,'{}');raise exception 'Customer can ingest events';
 exception when insufficient_privilege then null;end;
 begin insert into public.rewards_ledger(auth_user_id,booking_id,points,reason,idempotency_key) values(auth.uid(),b.id,100,'invalid','fixture');raise exception 'Customer can award points';
 exception when insufficient_privilege then null;end;
 perform public.set_organization_member(current_setting('test.organization')::uuid,'10000000-0000-4000-8000-000000000012',false,true);
end $$;
select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-8000-000000000012","aal":"aal1"}',true);
do $$ begin
 if (select count(*) from public.bookings)<>2 or (select count(*) from public.customer_addresses)<>2 then raise exception 'Authorized organization reads failed';end if;
 if exists(select 1 from public.payment_orders) then raise exception 'Organization leaked customer payments';end if;
end $$;
reset role;
set local role service_role;
do $$ declare ref text:=current_setting('test.reference');r uuid;event_id uuid:=gen_random_uuid();booking uuid:=current_setting('test.booking')::uuid;begin
 begin perform public.record_verified_payment(ref,'1001',601,'NGN');raise exception 'Wrong amount accepted';
 exception when raise_exception then if sqlerrm<>'Payment verification mismatch' then raise;end if;end;
 r:=public.record_verified_payment(ref,'1001',600,'NGN');
 if r is null or r<>public.record_verified_payment(ref,'1001',600,'NGN') then raise exception 'Payment replay duplicated receipt';end if;
 if public.record_payment_outcome(ref,'failed')<>'paid' then raise exception 'Stale failure overwrote settlement';end if;
 if public.receive_integration_event(event_id,booking,'booking.completed',1,'{}')<>'reconcile' or public.receive_integration_event(event_id,booking,'booking.completed',1,'{}')<>'reconcile' then raise exception 'Event reconciliation contract';end if;
 if (select status from public.bookings where id=booking)<>'awaiting_assignment' then raise exception 'Integration bypassed lifecycle';end if;
end $$;
reset role;
set local role authenticated;
select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-8000-000000000011","aal":"aal1"}',true);
do $$ declare payment uuid;refund uuid;begin
 select id into payment from public.payment_orders where provider_reference=current_setting('test.reference');
 refund:=public.request_refund(payment,'Fixture refund request');
 perform set_config('test.refund',refund::text,true);
 if refund is null or (select count(*) from public.receipts)<>1 then raise exception 'Receipt/refund request failed';end if;
 begin perform public.review_refund(refund,true,'Fixture decision');raise exception 'Customer approved refund';
 exception when insufficient_privilege then null;end;
end $$;
select set_config('request.jwt.claims','{"sub":"10000000-0000-4000-8000-000000000013","aal":"aal2"}',true);
do $$ declare booking uuid:=current_setting('test.booking')::uuid;begin
 begin perform public.record_booking_outcome(booking,'delivery_confirmed','fixture-proof');raise exception 'Out-of-order outcome accepted';
 exception when raise_exception then if sqlerrm<>'Outcome is unavailable for the current booking state' then raise;end if;end;
 if public.record_booking_outcome(booking,'scheduled','fixture-scheduled')<>'scheduled' then raise exception 'Scheduling transition failed';end if;
 if public.record_booking_outcome(booking,'collection_confirmed','fixture-collection')<>'completed' then raise exception 'Collection transition failed';end if;
 if public.record_booking_outcome(booking,'delivery_confirmed','fixture-delivery')<>'delivery_confirmed' then raise exception 'Delivery transition failed';end if;
 if public.record_booking_outcome(booking,'delivery_confirmed','fixture-delivery')<>'delivery_confirmed' then raise exception 'Duplicate delivery failed';end if;
end $$;
select public.review_refund(current_setting('test.refund')::uuid,true,'Fixture decision');
reset role;
set local role service_role;
select public.record_verified_refund(current_setting('test.reference'),'fixture-refund',600);
select public.record_verified_refund(current_setting('test.reference'),'fixture-refund',600);
do $$ begin
 if (select payment_status from public.bookings where id=current_setting('test.booking')::uuid)<>'refunded' then raise exception 'Refund reconciliation failed';end if;
end $$;
rollback;
