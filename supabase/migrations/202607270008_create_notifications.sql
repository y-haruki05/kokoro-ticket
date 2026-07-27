-- Review and dry-run before applying to the target Supabase project.

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references auth.users(id) on delete cascade,
  actor_id uuid references auth.users(id) on delete set null,
  type text not null check (type in (
    'friend_request_received',
    'friend_request_accepted',
    'ticket_received',
    'ticket_acknowledged',
    'ticket_usage_requested',
    'ticket_completed'
  )),
  resource_type text not null check (
    resource_type in ('friend_request', 'friendship', 'ticket')
  ),
  resource_id uuid not null,
  title text not null check (char_length(title) between 1 and 100),
  message text not null check (char_length(message) between 1 and 300),
  payload jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  constraint notifications_event_unique unique (recipient_id, resource_id, type)
);

create index notifications_recipient_created_idx
on public.notifications (recipient_id, created_at desc);

create index notifications_recipient_unread_idx
on public.notifications (recipient_id, created_at desc)
where read_at is null;

alter table public.notifications enable row level security;

create policy "Recipients can read notifications"
on public.notifications
for select
to authenticated
using (recipient_id = (select auth.uid()));

create or replace function public.create_notification_from_friend_request()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  friendship_id uuid;
begin
  if tg_op = 'INSERT' then
    insert into public.notifications (
      recipient_id, actor_id, type, resource_type, resource_id, title, message, payload
    ) values (
      new.receiver_id,
      new.sender_id,
      'friend_request_received',
      'friend_request',
      new.id,
      'フレンド申請が届きました',
      'フレンド申請を確認してください',
      jsonb_build_object('friend_request_id', new.id::text)
    ) on conflict (recipient_id, resource_id, type) do nothing;
  elsif old.status = 'pending' and new.status = 'accepted' then
    select id into friendship_id
    from public.friendships
    where user_id_low = least(new.sender_id, new.receiver_id)
      and user_id_high = greatest(new.sender_id, new.receiver_id);
    insert into public.notifications (
      recipient_id, actor_id, type, resource_type, resource_id, title, message, payload
    ) values (
      new.sender_id,
      new.receiver_id,
      'friend_request_accepted',
      'friendship',
      friendship_id,
      'フレンド申請が承認されました',
      '新しいフレンドが増えました',
      jsonb_build_object('friend_request_id', new.id::text)
    ) on conflict (recipient_id, resource_id, type) do nothing;
  end if;
  return new;
end;
$$;

create trigger friend_requests_create_notification
after insert or update of status on public.friend_requests
for each row execute function public.create_notification_from_friend_request();

create or replace function public.create_notification_from_ticket_status()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  transfer_row public.ticket_transfers%rowtype;
begin
  if old.status is not distinct from new.status then
    return new;
  end if;

  select * into transfer_row
  from public.ticket_transfers
  where ticket_id = new.id;

  if not found then
    return new;
  end if;

  if old.status = 'draft' and new.status = 'sent' then
    insert into public.notifications (
      recipient_id, actor_id, type, resource_type, resource_id, title, message, payload
    ) values (
      transfer_row.receiver_id, transfer_row.sender_id, 'ticket_received',
      'ticket', new.id, 'チケットが届きました',
      transfer_row.sender_name_snapshot || 'さんからチケットが届きました',
      jsonb_build_object('ticket_id', new.id::text, 'status', new.status)
    ) on conflict (recipient_id, resource_id, type) do nothing;
  elsif old.status = 'sent' and new.status = 'received' then
    insert into public.notifications (
      recipient_id, actor_id, type, resource_type, resource_id, title, message, payload
    ) values (
      transfer_row.sender_id, transfer_row.receiver_id, 'ticket_acknowledged',
      'ticket', new.id, 'チケットが受け取られました',
      transfer_row.receiver_name_snapshot || 'さんがチケットを受け取りました',
      jsonb_build_object('ticket_id', new.id::text, 'status', new.status)
    ) on conflict (recipient_id, resource_id, type) do nothing;
  elsif old.status = 'received' and new.status = 'requested' then
    insert into public.notifications (
      recipient_id, actor_id, type, resource_type, resource_id, title, message, payload
    ) values (
      transfer_row.sender_id, transfer_row.receiver_id, 'ticket_usage_requested',
      'ticket', new.id, '使用リクエストが届きました',
      transfer_row.receiver_name_snapshot || 'さんがチケットを使いたいと伝えています',
      jsonb_build_object('ticket_id', new.id::text, 'status', new.status)
    ) on conflict (recipient_id, resource_id, type) do nothing;
  elsif old.status = 'requested' and new.status = 'completed' then
    insert into public.notifications (
      recipient_id, actor_id, type, resource_type, resource_id, title, message, payload
    ) values (
      transfer_row.receiver_id, transfer_row.sender_id, 'ticket_completed',
      'ticket', new.id, 'チケットが完了しました',
      '完了したチケットが思い出に追加されました',
      jsonb_build_object('ticket_id', new.id::text, 'status', new.status)
    ) on conflict (recipient_id, resource_id, type) do nothing;
  end if;
  return new;
end;
$$;

create trigger tickets_create_notification
after update of status on public.tickets
for each row execute function public.create_notification_from_ticket_status();

create function public.get_notifications(
  page_offset integer default 0,
  page_limit integer default 20
)
returns table (
  id uuid,
  recipient_id uuid,
  actor_id uuid,
  actor_display_name text,
  actor_avatar_key text,
  type text,
  resource_type text,
  resource_id uuid,
  title text,
  message text,
  payload jsonb,
  read_at timestamptz,
  created_at timestamptz
)
language sql
security definer
set search_path = ''
as $$
  select
    n.id, n.recipient_id, n.actor_id, p.display_name, p.avatar_key,
    n.type, n.resource_type, n.resource_id, n.title, n.message,
    n.payload, n.read_at, n.created_at
  from public.notifications n
  left join public.profiles p on p.id = n.actor_id
  where n.recipient_id = (select auth.uid())
  order by n.created_at desc, n.id desc
  offset greatest(page_offset, 0)
  limit least(greatest(page_limit, 1), 100);
$$;

create function public.get_unread_notification_count()
returns integer
language sql
security definer
set search_path = ''
as $$
  select count(*)::integer
  from public.notifications
  where recipient_id = (select auth.uid()) and read_at is null;
$$;

create function public.mark_notification_as_read(target_notification_id uuid)
returns timestamptz
language plpgsql
security definer
set search_path = ''
as $$
declare
  result timestamptz;
begin
  update public.notifications
  set read_at = coalesce(read_at, now())
  where id = target_notification_id
    and recipient_id = (select auth.uid())
  returning read_at into result;
  if result is null then
    raise exception 'notification_not_found' using errcode = 'P0002';
  end if;
  return result;
end;
$$;

create function public.mark_all_notifications_as_read()
returns timestamptz
language plpgsql
security definer
set search_path = ''
as $$
declare
  marked_at timestamptz := now();
begin
  update public.notifications
  set read_at = marked_at
  where recipient_id = (select auth.uid()) and read_at is null;
  return marked_at;
end;
$$;

revoke all on table public.notifications from public, anon, authenticated;
grant select on table public.notifications to authenticated;

revoke all on function public.create_notification_from_friend_request() from public, anon, authenticated;
revoke all on function public.create_notification_from_ticket_status() from public, anon, authenticated;
revoke all on function public.get_notifications(integer, integer) from public, anon;
revoke all on function public.get_unread_notification_count() from public, anon;
revoke all on function public.mark_notification_as_read(uuid) from public, anon;
revoke all on function public.mark_all_notifications_as_read() from public, anon;
grant execute on function public.get_notifications(integer, integer) to authenticated;
grant execute on function public.get_unread_notification_count() to authenticated;
grant execute on function public.mark_notification_as_read(uuid) to authenticated;
grant execute on function public.mark_all_notifications_as_read() to authenticated;

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end;
$$;
