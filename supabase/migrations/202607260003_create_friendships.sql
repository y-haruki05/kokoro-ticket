-- Review and dry-run before applying to the target Supabase project.

create table public.friend_requests (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references auth.users(id) on delete cascade,
  receiver_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'rejected', 'cancelled')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  constraint friend_requests_no_self_request check (sender_id <> receiver_id)
);

create unique index friend_requests_unique_pending_direction
on public.friend_requests (sender_id, receiver_id)
where status = 'pending';

create index friend_requests_sender_status_created_idx
on public.friend_requests (sender_id, status, created_at desc);

create index friend_requests_receiver_status_created_idx
on public.friend_requests (receiver_id, status, created_at desc);

create table public.friendships (
  id uuid primary key default gen_random_uuid(),
  user_id_low uuid not null references auth.users(id) on delete cascade,
  user_id_high uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint friendships_ordered_users check (user_id_low::text < user_id_high::text),
  constraint friendships_unique_pair unique (user_id_low, user_id_high)
);

create index friendships_high_user_idx
on public.friendships (user_id_high);

alter table public.friend_requests enable row level security;
alter table public.friendships enable row level security;

create policy "Participants can read friend requests"
on public.friend_requests
for select
to authenticated
using ((select auth.uid()) = sender_id or (select auth.uid()) = receiver_id);

create policy "Friends can read their friendships"
on public.friendships
for select
to authenticated
using ((select auth.uid()) = user_id_low or (select auth.uid()) = user_id_high);

-- No INSERT / UPDATE / DELETE policies are intentionally defined.
-- Mutations are only available through the security-definer RPCs below.

create or replace function public.search_profile_by_friend_code(input_friend_code text)
returns table (
  profile_id uuid,
  display_name text,
  friend_code text,
  avatar_key text,
  relationship text
)
language sql
security definer
set search_path = ''
stable
as $$
  select
    p.id,
    p.display_name,
    p.friend_code,
    p.avatar_key,
    case
      when f.id is not null then 'friend'
      when outgoing.id is not null then 'outgoing_pending'
      when incoming.id is not null then 'incoming_pending'
      else 'none'
    end
  from public.profiles p
  left join public.friendships f
    on f.user_id_low = least((select auth.uid()), p.id)
   and f.user_id_high = greatest((select auth.uid()), p.id)
  left join public.friend_requests outgoing
    on outgoing.sender_id = (select auth.uid())
   and outgoing.receiver_id = p.id
   and outgoing.status = 'pending'
  left join public.friend_requests incoming
    on incoming.sender_id = p.id
   and incoming.receiver_id = (select auth.uid())
   and incoming.status = 'pending'
  where (select auth.uid()) is not null
    and p.id <> (select auth.uid())
    and p.friend_code = upper(btrim(input_friend_code))
  limit 1;
$$;

create or replace function public.send_friend_request(target_receiver_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor_id uuid := (select auth.uid());
  low_id uuid;
  high_id uuid;
begin
  if actor_id is null then
    raise exception 'authentication_required' using errcode = '42501';
  end if;
  if actor_id = target_receiver_id then
    return 'self_request';
  end if;
  if not exists (select 1 from public.profiles where id = target_receiver_id) then
    raise exception 'profile_not_found' using errcode = 'P0002';
  end if;

  low_id := least(actor_id, target_receiver_id);
  high_id := greatest(actor_id, target_receiver_id);
  perform pg_advisory_xact_lock(hashtextextended(low_id::text || high_id::text, 0));

  if exists (
    select 1 from public.friendships
    where user_id_low = low_id and user_id_high = high_id
  ) then
    return 'already_friends';
  end if;
  if exists (
    select 1 from public.friend_requests
    where sender_id = actor_id
      and receiver_id = target_receiver_id
      and status = 'pending'
  ) then
    return 'already_sent';
  end if;
  if exists (
    select 1 from public.friend_requests
    where sender_id = target_receiver_id
      and receiver_id = actor_id
      and status = 'pending'
  ) then
    return 'incoming_pending';
  end if;

  insert into public.friend_requests (sender_id, receiver_id)
  values (actor_id, target_receiver_id);
  return 'sent';
end;
$$;

create or replace function public.respond_friend_request(
  target_request_id uuid,
  response_action text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor_id uuid := (select auth.uid());
  request_row public.friend_requests%rowtype;
  low_id uuid;
  high_id uuid;
begin
  if actor_id is null then
    raise exception 'authentication_required' using errcode = '42501';
  end if;
  if response_action not in ('accept', 'reject') then
    raise exception 'invalid_response_action' using errcode = '22023';
  end if;

  select *
  into request_row
  from public.friend_requests
  where id = target_request_id
  for update;

  if not found or request_row.receiver_id <> actor_id then
    raise exception 'request_not_found_or_forbidden' using errcode = '42501';
  end if;
  if request_row.status <> 'pending' then
    raise exception 'already_processed' using errcode = 'P0001';
  end if;

  if response_action = 'reject' then
    update public.friend_requests
    set status = 'rejected', responded_at = now()
    where id = target_request_id;
    return 'rejected';
  end if;

  low_id := least(request_row.sender_id, request_row.receiver_id);
  high_id := greatest(request_row.sender_id, request_row.receiver_id);
  perform pg_advisory_xact_lock(hashtextextended(low_id::text || high_id::text, 0));

  insert into public.friendships (user_id_low, user_id_high)
  values (low_id, high_id)
  on conflict (user_id_low, user_id_high) do nothing;

  update public.friend_requests
  set status = 'accepted', responded_at = now()
  where id = target_request_id;

  return 'accepted';
end;
$$;

create or replace function public.get_incoming_friend_requests()
returns table (
  request_id uuid,
  sender_id uuid,
  receiver_id uuid,
  sender_display_name text,
  sender_friend_code text,
  sender_avatar_key text,
  receiver_display_name text,
  receiver_friend_code text,
  receiver_avatar_key text,
  status text,
  created_at timestamptz,
  responded_at timestamptz
)
language sql
security definer
set search_path = ''
stable
as $$
  select
    r.id, r.sender_id, r.receiver_id,
    sender.display_name, sender.friend_code, sender.avatar_key,
    receiver.display_name, receiver.friend_code, receiver.avatar_key,
    r.status, r.created_at, r.responded_at
  from public.friend_requests r
  join public.profiles sender on sender.id = r.sender_id
  join public.profiles receiver on receiver.id = r.receiver_id
  where r.receiver_id = (select auth.uid())
    and r.status = 'pending'
  order by r.created_at desc;
$$;

create or replace function public.get_outgoing_friend_requests()
returns table (
  request_id uuid,
  sender_id uuid,
  receiver_id uuid,
  sender_display_name text,
  sender_friend_code text,
  sender_avatar_key text,
  receiver_display_name text,
  receiver_friend_code text,
  receiver_avatar_key text,
  status text,
  created_at timestamptz,
  responded_at timestamptz
)
language sql
security definer
set search_path = ''
stable
as $$
  select
    r.id, r.sender_id, r.receiver_id,
    sender.display_name, sender.friend_code, sender.avatar_key,
    receiver.display_name, receiver.friend_code, receiver.avatar_key,
    r.status, r.created_at, r.responded_at
  from public.friend_requests r
  join public.profiles sender on sender.id = r.sender_id
  join public.profiles receiver on receiver.id = r.receiver_id
  where r.sender_id = (select auth.uid())
    and r.status = 'pending'
  order by r.created_at desc;
$$;

create or replace function public.get_friends()
returns table (
  profile_id uuid,
  display_name text,
  friend_code text,
  avatar_key text,
  friendship_created_at timestamptz
)
language sql
security definer
set search_path = ''
stable
as $$
  select
    p.id, p.display_name, p.friend_code, p.avatar_key, f.created_at
  from public.friendships f
  join public.profiles p
    on p.id = case
      when f.user_id_low = (select auth.uid()) then f.user_id_high
      else f.user_id_low
    end
  where f.user_id_low = (select auth.uid())
     or f.user_id_high = (select auth.uid())
  order by p.display_name;
$$;

revoke all on table public.friend_requests from anon, authenticated;
revoke all on table public.friendships from anon, authenticated;
grant select on table public.friend_requests to authenticated;
grant select on table public.friendships to authenticated;

revoke all on function public.search_profile_by_friend_code(text) from public, anon;
revoke all on function public.send_friend_request(uuid) from public, anon;
revoke all on function public.respond_friend_request(uuid, text) from public, anon;
revoke all on function public.get_incoming_friend_requests() from public, anon;
revoke all on function public.get_outgoing_friend_requests() from public, anon;
revoke all on function public.get_friends() from public, anon;

grant execute on function public.search_profile_by_friend_code(text) to authenticated;
grant execute on function public.send_friend_request(uuid) to authenticated;
grant execute on function public.respond_friend_request(uuid, text) to authenticated;
grant execute on function public.get_incoming_friend_requests() to authenticated;
grant execute on function public.get_outgoing_friend_requests() to authenticated;
grant execute on function public.get_friends() to authenticated;
