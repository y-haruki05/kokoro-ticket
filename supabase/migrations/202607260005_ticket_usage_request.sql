-- Review and dry-run before applying to the target Supabase project.

alter table public.tickets
add column received_at timestamptz;

create table public.ticket_usage_requests (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null unique references public.tickets(id) on delete cascade,
  requester_id uuid not null references auth.users(id) on delete cascade,
  requested_at timestamptz not null default now(),
  completed_by uuid references auth.users(id) on delete set null,
  completed_at timestamptz,
  constraint ticket_usage_completion_consistency check (
    (completed_by is null and completed_at is null)
    or (completed_by is not null and completed_at is not null)
  )
);

create index ticket_usage_requests_requester_requested_idx
on public.ticket_usage_requests (requester_id, requested_at desc);

alter table public.ticket_usage_requests enable row level security;

create policy "Ticket participants can read usage requests"
on public.ticket_usage_requests
for select
to authenticated
using (
  exists (
    select 1
    from public.ticket_transfers transfer
    where transfer.ticket_id = ticket_usage_requests.ticket_id
      and (
        transfer.sender_id = (select auth.uid())
        or transfer.receiver_id = (select auth.uid())
      )
  )
);

-- Existing Issue #39 rows were marked received at send time.
-- Reset them because receipt is now explicitly acknowledged by the receiver.
update public.ticket_transfers transfer
set received_at = null
from public.tickets ticket
where ticket.id = transfer.ticket_id
  and ticket.status = 'sent';

create or replace function public.clear_received_at_on_transfer_insert()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.received_at = null;
  return new;
end;
$$;

create trigger ticket_transfers_clear_received_at
before insert on public.ticket_transfers
for each row
execute function public.clear_received_at_on_transfer_insert();

create or replace function public.acknowledge_ticket(target_ticket_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor_id uuid := (select auth.uid());
  ticket_row public.tickets%rowtype;
  transfer_row public.ticket_transfers%rowtype;
  acknowledged_at timestamptz := now();
begin
  if actor_id is null then
    raise exception 'authentication_required' using errcode = '42501';
  end if;

  select *
  into transfer_row
  from public.ticket_transfers
  where ticket_id = target_ticket_id
  for update;

  if not found or transfer_row.receiver_id <> actor_id then
    raise exception 'receiver_only' using errcode = '42501';
  end if;

  select *
  into ticket_row
  from public.tickets
  where id = target_ticket_id
  for update;

  if not found or ticket_row.status <> 'sent' then
    raise exception 'ticket_not_sent' using errcode = 'P0001';
  end if;

  update public.ticket_transfers
  set received_at = acknowledged_at
  where ticket_id = target_ticket_id;

  update public.tickets
  set status = 'received',
      received_at = acknowledged_at,
      updated_at = acknowledged_at
  where id = target_ticket_id;

  return 'received';
end;
$$;

create or replace function public.request_ticket_usage(target_ticket_id uuid)
returns table (
  id uuid,
  ticket_id uuid,
  requester_id uuid,
  requested_at timestamptz,
  completed_by uuid,
  completed_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor_id uuid := (select auth.uid());
  ticket_row public.tickets%rowtype;
  transfer_row public.ticket_transfers%rowtype;
  request_row public.ticket_usage_requests%rowtype;
begin
  if actor_id is null then
    raise exception 'authentication_required' using errcode = '42501';
  end if;

  select *
  into transfer_row
  from public.ticket_transfers
  where public.ticket_transfers.ticket_id = target_ticket_id
  for update;

  if not found or transfer_row.receiver_id <> actor_id then
    raise exception 'receiver_only' using errcode = '42501';
  end if;

  if exists (
    select 1 from public.ticket_usage_requests
    where public.ticket_usage_requests.ticket_id = target_ticket_id
  ) then
    raise exception 'already_requested' using errcode = '23505';
  end if;

  select *
  into ticket_row
  from public.tickets
  where public.tickets.id = target_ticket_id
  for update;

  if not found or ticket_row.status <> 'received' then
    raise exception 'ticket_not_received' using errcode = 'P0001';
  end if;

  insert into public.ticket_usage_requests (
    ticket_id,
    requester_id,
    requested_at
  )
  values (
    target_ticket_id,
    actor_id,
    now()
  )
  returning * into request_row;

  update public.tickets
  set status = 'requested',
      requested_at = request_row.requested_at,
      updated_at = request_row.requested_at
  where public.tickets.id = target_ticket_id;

  return query
  select
    request_row.id,
    request_row.ticket_id,
    request_row.requester_id,
    request_row.requested_at,
    request_row.completed_by,
    request_row.completed_at;
end;
$$;

drop function public.get_sent_tickets();
drop function public.get_received_tickets();

create function public.get_sent_tickets()
returns table (
  id uuid,
  ticket_title text,
  message text,
  illustration text,
  background_color text,
  border_style text,
  created_at timestamptz,
  updated_at timestamptz,
  sent_at timestamptz,
  received_at timestamptz,
  requested_at timestamptz,
  status text,
  sender_name text,
  receiver_name text
)
language sql
security definer
set search_path = ''
stable
as $$
  select
    ticket.id,
    ticket.ticket_title,
    ticket.message,
    ticket.illustration,
    ticket.background_color,
    ticket.border_style,
    ticket.created_at,
    ticket.updated_at,
    transfer.sent_at,
    ticket.received_at,
    ticket.requested_at,
    ticket.status,
    transfer.sender_name_snapshot,
    transfer.receiver_name_snapshot
  from public.ticket_transfers transfer
  join public.tickets ticket on ticket.id = transfer.ticket_id
  where transfer.sender_id = (select auth.uid())
  order by transfer.sent_at desc;
$$;

create function public.get_received_tickets()
returns table (
  id uuid,
  ticket_title text,
  message text,
  illustration text,
  background_color text,
  border_style text,
  created_at timestamptz,
  updated_at timestamptz,
  sent_at timestamptz,
  received_at timestamptz,
  requested_at timestamptz,
  status text,
  sender_name text,
  receiver_name text
)
language sql
security definer
set search_path = ''
stable
as $$
  select
    ticket.id,
    ticket.ticket_title,
    ticket.message,
    ticket.illustration,
    ticket.background_color,
    ticket.border_style,
    ticket.created_at,
    ticket.updated_at,
    transfer.sent_at,
    ticket.received_at,
    ticket.requested_at,
    ticket.status,
    transfer.sender_name_snapshot,
    transfer.receiver_name_snapshot
  from public.ticket_transfers transfer
  join public.tickets ticket on ticket.id = transfer.ticket_id
  where transfer.receiver_id = (select auth.uid())
  order by transfer.sent_at desc;
$$;

create function public.get_requested_tickets()
returns table (
  id uuid,
  ticket_title text,
  message text,
  illustration text,
  background_color text,
  border_style text,
  created_at timestamptz,
  updated_at timestamptz,
  sent_at timestamptz,
  received_at timestamptz,
  requested_at timestamptz,
  status text,
  sender_name text,
  receiver_name text
)
language sql
security definer
set search_path = ''
stable
as $$
  select
    ticket.id,
    ticket.ticket_title,
    ticket.message,
    ticket.illustration,
    ticket.background_color,
    ticket.border_style,
    ticket.created_at,
    ticket.updated_at,
    transfer.sent_at,
    ticket.received_at,
    ticket.requested_at,
    ticket.status,
    transfer.sender_name_snapshot,
    transfer.receiver_name_snapshot
  from public.ticket_usage_requests request
  join public.tickets ticket on ticket.id = request.ticket_id
  join public.ticket_transfers transfer on transfer.ticket_id = ticket.id
  where request.requester_id = (select auth.uid())
    and ticket.status = 'requested'
  order by request.requested_at desc;
$$;

create function public.get_waiting_tickets()
returns table (
  id uuid,
  ticket_title text,
  message text,
  illustration text,
  background_color text,
  border_style text,
  created_at timestamptz,
  updated_at timestamptz,
  sent_at timestamptz,
  received_at timestamptz,
  requested_at timestamptz,
  status text,
  sender_name text,
  receiver_name text
)
language sql
security definer
set search_path = ''
stable
as $$
  select
    ticket.id,
    ticket.ticket_title,
    ticket.message,
    ticket.illustration,
    ticket.background_color,
    ticket.border_style,
    ticket.created_at,
    ticket.updated_at,
    transfer.sent_at,
    ticket.received_at,
    ticket.requested_at,
    ticket.status,
    transfer.sender_name_snapshot,
    transfer.receiver_name_snapshot
  from public.ticket_usage_requests request
  join public.tickets ticket on ticket.id = request.ticket_id
  join public.ticket_transfers transfer on transfer.ticket_id = ticket.id
  where transfer.sender_id = (select auth.uid())
    and ticket.status = 'requested'
  order by request.requested_at desc;
$$;

revoke all on table public.ticket_usage_requests from anon, authenticated;
grant select on table public.ticket_usage_requests to authenticated;

revoke all on function public.clear_received_at_on_transfer_insert() from public, anon, authenticated;
revoke all on function public.acknowledge_ticket(uuid) from public, anon;
revoke all on function public.request_ticket_usage(uuid) from public, anon;
revoke all on function public.get_sent_tickets() from public, anon;
revoke all on function public.get_received_tickets() from public, anon;
revoke all on function public.get_requested_tickets() from public, anon;
revoke all on function public.get_waiting_tickets() from public, anon;

grant execute on function public.acknowledge_ticket(uuid) to authenticated;
grant execute on function public.request_ticket_usage(uuid) to authenticated;
grant execute on function public.get_sent_tickets() to authenticated;
grant execute on function public.get_received_tickets() to authenticated;
grant execute on function public.get_requested_tickets() to authenticated;
grant execute on function public.get_waiting_tickets() to authenticated;
