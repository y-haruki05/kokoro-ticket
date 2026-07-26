-- Review and dry-run before applying to the target Supabase project.

create index tickets_completed_at_idx
on public.tickets (completed_at desc)
where status = 'completed';

alter table public.tickets
add constraint tickets_completed_state_consistency check (
  (status = 'completed' and completed_at is not null)
  or (status <> 'completed' and completed_at is null)
) not valid;

alter table public.tickets
validate constraint tickets_completed_state_consistency;

create or replace function public.complete_ticket(target_ticket_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor_id uuid := (select auth.uid());
  ticket_row public.tickets%rowtype;
  transfer_row public.ticket_transfers%rowtype;
  usage_row public.ticket_usage_requests%rowtype;
  completion_time timestamptz := now();
begin
  if actor_id is null then
    raise exception 'authentication_required' using errcode = 'PT401';
  end if;

  select *
  into ticket_row
  from public.tickets
  where id = target_ticket_id
  for update;

  if not found then
    raise exception 'ticket_not_found' using errcode = 'PT404';
  end if;

  select *
  into transfer_row
  from public.ticket_transfers
  where ticket_id = target_ticket_id
  for update;

  if not found then
    raise exception 'ticket_not_found' using errcode = 'PT404';
  end if;

  if transfer_row.sender_id <> actor_id then
    raise exception 'sender_only' using errcode = 'PT403';
  end if;

  if ticket_row.status = 'completed' then
    raise exception 'already_completed' using errcode = 'PT409';
  end if;

  if ticket_row.status <> 'requested' then
    raise exception 'ticket_not_requested' using errcode = 'PT400';
  end if;

  select *
  into usage_row
  from public.ticket_usage_requests
  where ticket_id = target_ticket_id
  for update;

  if not found then
    raise exception 'usage_request_not_found' using errcode = 'PT404';
  end if;

  if usage_row.completed_at is not null or usage_row.completed_by is not null then
    raise exception 'already_completed' using errcode = 'PT409';
  end if;

  update public.ticket_usage_requests
  set completed_by = actor_id,
      completed_at = completion_time
  where ticket_id = target_ticket_id;

  update public.tickets
  set status = 'completed',
      completed_at = completion_time,
      updated_at = completion_time
  where id = target_ticket_id;

  return 'completed';
end;
$$;

create or replace function public.get_completed_tickets()
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
  completed_at timestamptz,
  status text,
  sender_name text,
  receiver_name text
)
language plpgsql
security definer
set search_path = ''
stable
as $$
declare
  actor_id uuid := (select auth.uid());
begin
  if actor_id is null then
    raise exception 'authentication_required' using errcode = 'PT401';
  end if;

  return query
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
    ticket.completed_at,
    ticket.status,
    transfer.sender_name_snapshot,
    transfer.receiver_name_snapshot
  from public.ticket_usage_requests request
  join public.tickets ticket on ticket.id = request.ticket_id
  join public.ticket_transfers transfer on transfer.ticket_id = ticket.id
  where ticket.status = 'completed'
    and (
      transfer.sender_id = actor_id
      or transfer.receiver_id = actor_id
    )
  order by ticket.completed_at desc;
end;
$$;

revoke all on function public.complete_ticket(uuid) from public, anon;
revoke all on function public.get_completed_tickets() from public, anon;

grant execute on function public.complete_ticket(uuid) to authenticated;
grant execute on function public.get_completed_tickets() to authenticated;
