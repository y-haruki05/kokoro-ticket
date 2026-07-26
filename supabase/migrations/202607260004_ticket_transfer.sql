-- Review and dry-run before applying to the target Supabase project.

create table public.tickets (
  id uuid primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  ticket_title text not null check (char_length(btrim(ticket_title)) between 1 and 100),
  message text not null default '' check (char_length(message) <= 1000),
  illustration text,
  background_color text not null,
  border_style text not null,
  status text not null default 'draft'
    check (status in ('draft', 'sent', 'received', 'requested', 'completed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  sent_at timestamptz,
  requested_at timestamptz,
  completed_at timestamptz
);

create index tickets_owner_status_updated_idx
on public.tickets (owner_id, status, updated_at desc);

create table public.ticket_transfers (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null unique references public.tickets(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  receiver_id uuid not null references auth.users(id) on delete cascade,
  sender_name_snapshot text not null,
  receiver_name_snapshot text not null,
  sent_at timestamptz not null default now(),
  received_at timestamptz,
  constraint ticket_transfers_no_self_transfer check (sender_id <> receiver_id)
);

create index ticket_transfers_sender_sent_idx
on public.ticket_transfers (sender_id, sent_at desc);

create index ticket_transfers_receiver_received_idx
on public.ticket_transfers (receiver_id, received_at desc);

alter table public.tickets enable row level security;
alter table public.ticket_transfers enable row level security;

create policy "Owners can insert draft tickets"
on public.tickets
for insert
to authenticated
with check (
  owner_id = (select auth.uid())
  and status = 'draft'
  and sent_at is null
  and requested_at is null
  and completed_at is null
);

create policy "Owners can update their draft tickets"
on public.tickets
for update
to authenticated
using (
  owner_id = (select auth.uid())
  and status = 'draft'
)
with check (
  owner_id = (select auth.uid())
  and status = 'draft'
  and sent_at is null
  and requested_at is null
  and completed_at is null
);

create policy "Participants can read tickets"
on public.tickets
for select
to authenticated
using (
  (
    status = 'draft'
    and owner_id = (select auth.uid())
  )
  or (
    status <> 'draft'
    and exists (
      select 1
      from public.ticket_transfers transfer
      where transfer.ticket_id = tickets.id
        and (
          transfer.sender_id = (select auth.uid())
          or transfer.receiver_id = (select auth.uid())
        )
    )
  )
);

create policy "Participants can read ticket transfers"
on public.ticket_transfers
for select
to authenticated
using (
  sender_id = (select auth.uid())
  or receiver_id = (select auth.uid())
);

-- No INSERT / UPDATE / DELETE policies are defined for ticket_transfers.
-- Transfer creation is only available through send_ticket.

create or replace function public.send_ticket(
  target_ticket_id uuid,
  target_receiver_id uuid
)
returns table (
  id uuid,
  ticket_id uuid,
  sender_id uuid,
  receiver_id uuid,
  sender_name_snapshot text,
  receiver_name_snapshot text,
  sent_at timestamptz,
  received_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor_id uuid := (select auth.uid());
  ticket_row public.tickets%rowtype;
  sender_name text;
  receiver_name text;
  transfer_row public.ticket_transfers%rowtype;
  low_id uuid;
  high_id uuid;
begin
  if actor_id is null then
    raise exception 'authentication_required' using errcode = '42501';
  end if;
  if actor_id = target_receiver_id then
    raise exception 'self_transfer' using errcode = '22023';
  end if;

  select *
  into ticket_row
  from public.tickets
  where public.tickets.id = target_ticket_id
  for update;

  if not found then
    raise exception 'ticket_not_found' using errcode = 'P0002';
  end if;
  if ticket_row.owner_id <> actor_id then
    raise exception 'ticket_not_owned' using errcode = '42501';
  end if;
  if ticket_row.status <> 'draft' then
    raise exception 'ticket_not_draft' using errcode = 'P0001';
  end if;
  if exists (
    select 1 from public.ticket_transfers
    where public.ticket_transfers.ticket_id = target_ticket_id
  ) then
    raise exception 'already_transferred' using errcode = '23505';
  end if;

  low_id := least(actor_id, target_receiver_id);
  high_id := greatest(actor_id, target_receiver_id);
  if not exists (
    select 1
    from public.friendships
    where user_id_low = low_id and user_id_high = high_id
  ) then
    raise exception 'receiver_not_friend' using errcode = '42501';
  end if;

  select display_name into sender_name
  from public.profiles where public.profiles.id = actor_id;
  select display_name into receiver_name
  from public.profiles where public.profiles.id = target_receiver_id;
  if sender_name is null or receiver_name is null then
    raise exception 'profile_not_found' using errcode = 'P0002';
  end if;

  insert into public.ticket_transfers (
    ticket_id,
    sender_id,
    receiver_id,
    sender_name_snapshot,
    receiver_name_snapshot,
    sent_at,
    received_at
  )
  values (
    target_ticket_id,
    actor_id,
    target_receiver_id,
    sender_name,
    receiver_name,
    now(),
    now()
  )
  returning * into transfer_row;

  update public.tickets
  set status = 'sent',
      sent_at = transfer_row.sent_at,
      updated_at = transfer_row.sent_at
  where public.tickets.id = target_ticket_id;

  return query
  select
    transfer_row.id,
    transfer_row.ticket_id,
    transfer_row.sender_id,
    transfer_row.receiver_id,
    transfer_row.sender_name_snapshot,
    transfer_row.receiver_name_snapshot,
    transfer_row.sent_at,
    transfer_row.received_at;
end;
$$;

create or replace function public.get_sent_tickets()
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
    transfer.sender_name_snapshot,
    transfer.receiver_name_snapshot
  from public.ticket_transfers transfer
  join public.tickets ticket on ticket.id = transfer.ticket_id
  where transfer.sender_id = (select auth.uid())
  order by transfer.sent_at desc;
$$;

create or replace function public.get_received_tickets()
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
    transfer.sender_name_snapshot,
    transfer.receiver_name_snapshot
  from public.ticket_transfers transfer
  join public.tickets ticket on ticket.id = transfer.ticket_id
  where transfer.receiver_id = (select auth.uid())
  order by transfer.received_at desc nulls last, transfer.sent_at desc;
$$;

revoke all on table public.tickets from anon, authenticated;
revoke all on table public.ticket_transfers from anon, authenticated;
grant select, insert, update on table public.tickets to authenticated;
grant select on table public.ticket_transfers to authenticated;

revoke all on function public.send_ticket(uuid, uuid) from public, anon;
revoke all on function public.get_sent_tickets() from public, anon;
revoke all on function public.get_received_tickets() from public, anon;

grant execute on function public.send_ticket(uuid, uuid) to authenticated;
grant execute on function public.get_sent_tickets() to authenticated;
grant execute on function public.get_received_tickets() to authenticated;
