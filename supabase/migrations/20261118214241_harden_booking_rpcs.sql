-- Keep elevated implementations out of exposed schemas. Public RPCs retain
-- the same inputs and delegate as the invoking role to guarded private functions.
alter function public.cancel_booking(uuid) set schema private;
create function public.cancel_booking(booking uuid)
returns void language sql security invoker set search_path='' as $$
 select private.cancel_booking($1);
$$;
revoke all on function public.cancel_booking(uuid) from public,anon;
grant execute on function public.cancel_booking(uuid) to authenticated;

alter function public.create_booking(uuid,uuid) set schema private;
create function public.create_booking(quote uuid, idempotency uuid)
returns public.bookings language sql security invoker set search_path='' as $$
 select private.create_booking($1, $2);
$$;
revoke all on function public.create_booking(uuid,uuid) from public,anon;
grant execute on function public.create_booking(uuid,uuid) to authenticated;

alter function public.create_organization(text) set schema private;
create function public.create_organization(org_name text)
returns uuid language sql security invoker set search_path='' as $$
 select private.create_organization($1);
$$;
revoke all on function public.create_organization(text) from public,anon;
grant execute on function public.create_organization(text) to authenticated;

alter function public.get_operational_audit(bigint) set schema private;
create function public.get_operational_audit(before_id bigint default null)
returns setof private.audit_events language sql stable security invoker set search_path='' as $$
 select * from private.get_operational_audit($1);
$$;
revoke all on function public.get_operational_audit(bigint) from public,anon;
grant execute on function public.get_operational_audit(bigint) to authenticated;

alter function public.list_collection_slots(uuid) set schema private;
create function public.list_collection_slots(address uuid)
returns table(id uuid, starts_at timestamptz, ends_at timestamptz) language sql stable security invoker set search_path='' as $$
 select * from private.list_collection_slots($1);
$$;
revoke all on function public.list_collection_slots(uuid) from public,anon;
grant execute on function public.list_collection_slots(uuid) to authenticated;

alter function public.prepare_payment(uuid) set schema private;
create function public.prepare_payment(booking uuid)
returns public.payment_orders language sql security invoker set search_path='' as $$
 select private.prepare_payment($1);
$$;
revoke all on function public.prepare_payment(uuid) from public,anon;
grant execute on function public.prepare_payment(uuid) to authenticated;

alter function public.request_quote(uuid,uuid,uuid,numeric,text,boolean,uuid) set schema private;
create function public.request_quote(address uuid, category uuid, slot uuid, quantity numeric, unit text, prepared boolean default false, destination uuid default null)
returns public.quotes language sql security invoker set search_path='' as $$
 select private.request_quote($1, $2, $3, $4, $5, $6, $7);
$$;
revoke all on function public.request_quote(uuid,uuid,uuid,numeric,text,boolean,uuid) from public,anon;
grant execute on function public.request_quote(uuid,uuid,uuid,numeric,text,boolean,uuid) to authenticated;

alter function public.request_refund(uuid,text) set schema private;
create function public.request_refund(payment uuid, reason text)
returns uuid language sql security invoker set search_path='' as $$
 select private.request_refund($1, $2);
$$;
revoke all on function public.request_refund(uuid,text) from public,anon;
grant execute on function public.request_refund(uuid,text) to authenticated;

alter function public.reschedule_booking(uuid,uuid) set schema private;
create function public.reschedule_booking(booking uuid, new_slot uuid)
returns void language sql security invoker set search_path='' as $$
 select private.reschedule_booking($1, $2);
$$;
revoke all on function public.reschedule_booking(uuid,uuid) from public,anon;
grant execute on function public.reschedule_booking(uuid,uuid) to authenticated;

alter function public.review_refund(uuid,boolean,text) set schema private;
create function public.review_refund(refund uuid, approval boolean, note text)
returns void language sql security invoker set search_path='' as $$
 select private.review_refund($1, $2, $3);
$$;
revoke all on function public.review_refund(uuid,boolean,text) from public,anon;
grant execute on function public.review_refund(uuid,boolean,text) to authenticated;

alter function public.review_verification(uuid,public.verification_state,text) set schema private;
create function public.review_verification(subject uuid, decision public.verification_state, reason text)
returns void language sql security invoker set search_path='' as $$
 select private.review_verification($1, $2, $3);
$$;
revoke all on function public.review_verification(uuid,public.verification_state,text) from public,anon;
grant execute on function public.review_verification(uuid,public.verification_state,text) to authenticated;

alter function public.save_address(text,text,uuid,uuid) set schema private;
create function public.save_address(label text, address_text text, coverage uuid, organization uuid default null)
returns uuid language sql security invoker set search_path='' as $$
 select private.save_address($1, $2, $3, $4);
$$;
revoke all on function public.save_address(text,text,uuid,uuid) from public,anon;
grant execute on function public.save_address(text,text,uuid,uuid) to authenticated;

alter function public.set_organization_member(uuid,uuid,boolean,boolean) set schema private;
create function public.set_organization_member(org uuid, member uuid, may_book boolean, enabled boolean)
returns void language sql security invoker set search_path='' as $$
 select private.set_organization_member($1, $2, $3, $4);
$$;
revoke all on function public.set_organization_member(uuid,uuid,boolean,boolean) from public,anon;
grant execute on function public.set_organization_member(uuid,uuid,boolean,boolean) to authenticated;

alter function public.submit_verification_document(uuid,text) set schema private;
create function public.submit_verification_document(requirement uuid, object_path text)
returns void language sql security invoker set search_path='' as $$
 select private.submit_verification_document($1, $2);
$$;
revoke all on function public.submit_verification_document(uuid,text) from public,anon;
grant execute on function public.submit_verification_document(uuid,text) to authenticated;

alter function public.update_support_ticket(uuid,text) set schema private;
create function public.update_support_ticket(ticket uuid, new_status text)
returns void language sql security invoker set search_path='' as $$
 select private.update_support_ticket($1, $2);
$$;
revoke all on function public.update_support_ticket(uuid,text) from public,anon;
grant execute on function public.update_support_ticket(uuid,text) to authenticated;

alter function public.verify_address_coverage(uuid,boolean) set schema private;
create function public.verify_address_coverage(address uuid, approved boolean)
returns void language sql security invoker set search_path='' as $$
 select private.verify_address_coverage($1, $2);
$$;
revoke all on function public.verify_address_coverage(uuid,boolean) from public,anon;
grant execute on function public.verify_address_coverage(uuid,boolean) to authenticated;

-- Revoke explicit client execution of Supabase's event trigger helper.
-- The installed trigger continues to run with its existing event binding.
do $$ begin
 if exists (
  select 1 from pg_proc p join pg_event_trigger e on e.evtfoid=p.oid
  where p.oid=to_regprocedure('public.rls_auto_enable()')
 ) then
  revoke execute on function public.rls_auto_enable() from public,anon,authenticated;
 end if;
end $$;
notify pgrst, 'reload schema';
