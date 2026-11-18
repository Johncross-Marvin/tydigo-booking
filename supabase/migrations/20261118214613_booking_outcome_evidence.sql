-- Approved destinations for both services and staff-attested outcome evidence.
create function private.require_quote_destination() returns trigger
language plpgsql security definer set search_path='' as $$
declare coverage uuid; option_count bigint;
begin
 select coverage_id into coverage from public.collection_slots where id=new.slot_id;
 if new.destination_id is null then
  select count(*) into option_count from public.service_destinations d
  where d.active and d.coverage_id=coverage and d.category_id=new.category_id;
  if option_count=1 then
   select id into new.destination_id from public.service_destinations d
   where d.active and d.coverage_id=coverage and d.category_id=new.category_id;
  end if;
 end if;
 if not exists(
  select 1 from public.service_destinations d
  where d.id=new.destination_id and d.active and d.coverage_id=coverage and d.category_id=new.category_id
 ) then raise exception 'Select an approved destination for this service and category';end if;
 return new;
end $$;
create trigger require_quote_destination before insert on public.quotes
for each row execute function private.require_quote_destination();
revoke all on function private.require_quote_destination() from public,anon,authenticated;

create table private.booking_outcome_evidence (
 booking_id uuid not null references public.bookings,
 outcome text not null check(outcome in ('scheduled','collection_confirmed','delivery_confirmed')),
 recorded_by uuid not null references auth.users(id),
 evidence_reference text not null check(length(trim(evidence_reference)) between 6 and 200),
 recorded_at timestamptz not null default now(),
 primary key(booking_id,outcome)
);
alter table private.booking_outcome_evidence enable row level security;
revoke all on private.booking_outcome_evidence from public,anon,authenticated;

create function private.record_booking_outcome(booking uuid,outcome text,evidence_reference text)
returns text language plpgsql security definer set search_path='' as $$
declare order_row public.bookings; existing_reference text; expected_status text; resulting_status text;
begin
 if not private.staff('operations') then raise exception 'Operations permission required' using errcode='42501';end if;
 if evidence_reference is null or length(trim(evidence_reference)) not between 6 and 200 then
  raise exception 'Evidence reference required';
 end if;
 case outcome
 when 'scheduled' then expected_status:='awaiting_assignment'; resulting_status:='scheduled';
 when 'collection_confirmed' then expected_status:='scheduled'; resulting_status:='completed';
 when 'delivery_confirmed' then expected_status:='completed'; resulting_status:='delivery_confirmed';
 else raise exception 'Unsupported booking outcome';
 end case;

 select * into order_row from public.bookings where id=booking for update;
 if order_row.id is null then raise exception 'Booking unavailable';end if;
 select e.evidence_reference into existing_reference from private.booking_outcome_evidence e
 where e.booking_id=booking and e.outcome=record_booking_outcome.outcome;
 if found then
  if existing_reference<>trim(evidence_reference) then raise exception 'Outcome evidence conflict';end if;
  return order_row.status;
 end if;
 if order_row.payment_status<>'paid' or order_row.status<>expected_status then
  raise exception 'Outcome is unavailable for the current booking state';
 end if;
 if not exists(
  select 1 from public.quotes q join public.service_destinations d on d.id=q.destination_id
  where q.id=order_row.quote_id and d.active
 ) then raise exception 'Approved destination unavailable';end if;

 insert into private.booking_outcome_evidence(booking_id,outcome,recorded_by,evidence_reference)
 values(booking,outcome,auth.uid(),trim(evidence_reference));
 update public.bookings set status=resulting_status where id=booking;
 insert into private.audit_events(actor,event_type,subject_id,details)
 values(auth.uid(),'booking.outcome_recorded',booking,jsonb_build_object('outcome',outcome));
 return resulting_status;
end $$;
revoke all on function private.record_booking_outcome(uuid,text,text) from public,anon;
grant execute on function private.record_booking_outcome(uuid,text,text) to authenticated;
create function public.record_booking_outcome(booking uuid,outcome text,evidence_reference text)
returns text language sql security invoker set search_path='' as $$
 select private.record_booking_outcome($1,$2,$3);
$$;
revoke all on function public.record_booking_outcome(uuid,text,text) from public,anon;
grant execute on function public.record_booking_outcome(uuid,text,text) to authenticated;

notify pgrst, 'reload schema';
