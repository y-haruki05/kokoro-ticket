-- Profile avatar storage foundation.
-- This migration creates a private bucket. Only authenticated users may read
-- avatars, and only the owner of the first path segment may write or delete.

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'profile-avatars',
  'profile-avatars',
  false,
  5242880,
  array['image/jpeg']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

alter table public.profiles
  add constraint profiles_avatar_key_owned_path
  check (
    avatar_key is null
    or (
      split_part(avatar_key, '/', 1) = id::text
      and avatar_key ~ '^[0-9a-f-]{36}/avatar-[0-9a-f-]{36}\.jpg$'
    )
  ) not valid;

alter table public.profiles
  validate constraint profiles_avatar_key_owned_path;

drop policy if exists "Authenticated users can read profile avatars"
on storage.objects;

create policy "Authenticated users can read profile avatars"
on storage.objects
for select
to authenticated
using (bucket_id = 'profile-avatars');

drop policy if exists "Users can upload their own profile avatar"
on storage.objects;

create policy "Users can upload their own profile avatar"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'profile-avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and lower(storage.extension(name)) = 'jpg'
);

drop policy if exists "Users can update their own profile avatar"
on storage.objects;

create policy "Users can update their own profile avatar"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'profile-avatars'
  and owner_id = (select auth.uid())::text
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'profile-avatars'
  and owner_id = (select auth.uid())::text
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and lower(storage.extension(name)) = 'jpg'
);

drop policy if exists "Users can delete their own profile avatar"
on storage.objects;

create policy "Users can delete their own profile avatar"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'profile-avatars'
  and owner_id = (select auth.uid())::text
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
