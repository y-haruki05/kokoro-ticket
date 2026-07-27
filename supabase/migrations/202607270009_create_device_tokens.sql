-- Review and dry-run before applying.
create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  apns_token text not null check (apns_token ~ '^[0-9a-f]{64,200}$'),
  environment text not null check (environment in ('sandbox', 'production')),
  device_id text,
  bundle_id text not null check (char_length(bundle_id) between 3 and 255),
  is_active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (apns_token, environment)
);
create index device_tokens_user_active_idx on public.device_tokens(user_id, is_active);
create table public.push_deliveries (
  notification_id uuid not null references public.notifications(id) on delete cascade,
  device_token_id uuid not null references public.device_tokens(id) on delete cascade,
  delivered_at timestamptz,
  last_error text,
  primary key (notification_id, device_token_id)
);
alter table public.device_tokens enable row level security;
alter table public.push_deliveries enable row level security;
create policy "Users read own device tokens" on public.device_tokens for select
to authenticated using (user_id = (select auth.uid()));

create function public.set_device_tokens_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end; $$;
create trigger device_tokens_updated_at before update on public.device_tokens
for each row execute function public.set_device_tokens_updated_at();

create function public.register_device_token(
  target_token text, target_environment text, target_bundle_id text
) returns uuid language plpgsql security definer set search_path = '' as $$
declare result uuid; actor uuid := (select auth.uid());
begin
  if actor is null then raise exception 'authentication_required' using errcode='42501'; end if;
  insert into public.device_tokens(user_id, apns_token, environment, bundle_id)
  values(actor, lower(target_token), target_environment, target_bundle_id)
  on conflict (apns_token, environment) do update set
    user_id=actor, bundle_id=excluded.bundle_id, is_active=true,
    last_seen_at=now(), updated_at=now()
  returning id into result;
  return result;
end; $$;

create function public.deactivate_device_token(
  target_token text, target_environment text
) returns boolean language plpgsql security definer set search_path = '' as $$
begin
  update public.device_tokens set is_active=false, updated_at=now()
  where user_id=(select auth.uid()) and apns_token=lower(target_token)
    and environment=target_environment;
  return found;
end; $$;

revoke all on table public.device_tokens from public, anon, authenticated;
revoke all on table public.push_deliveries from public, anon, authenticated;
grant select on table public.device_tokens to authenticated;
revoke all on function public.register_device_token(text,text,text) from public, anon;
revoke all on function public.deactivate_device_token(text,text) from public, anon;
grant execute on function public.register_device_token(text,text,text) to authenticated;
grant execute on function public.deactivate_device_token(text,text) to authenticated;
