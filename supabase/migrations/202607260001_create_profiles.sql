-- Proposal only: apply this migration after reviewing it in the target Supabase project.

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null
    check (char_length(btrim(display_name)) between 1 and 30),
  friend_code text not null unique
    check (friend_code ~ '^[A-HJ-NP-Z2-9]{8}$'),
  avatar_key text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_profiles_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_profiles_updated_at();

alter table public.profiles enable row level security;

create policy "Users can read their own profile"
on public.profiles
for select
to authenticated
using ((select auth.uid()) = id);

create policy "Users can create their own profile"
on public.profiles
for insert
to authenticated
with check ((select auth.uid()) = id);

create policy "Users can update their own profile"
on public.profiles
for update
to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

create or replace function public.is_friend_code_available(candidate text)
returns boolean
language sql
security definer
set search_path = ''
stable
as $$
  select
    candidate ~ '^[A-HJ-NP-Z2-9]{8}$'
    and not exists (
      select 1
      from public.profiles
      where friend_code = candidate
    );
$$;

revoke all on function public.is_friend_code_available(text) from public;
grant execute on function public.is_friend_code_available(text) to authenticated;
