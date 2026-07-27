-- Prevent an authenticated user from claiming a token already owned by another user.
create or replace function public.register_device_token(
  target_token text, target_environment text, target_bundle_id text
) returns uuid language plpgsql security definer set search_path = '' as $$
declare
  result uuid;
  actor uuid := (select auth.uid());
begin
  if actor is null then
    raise exception 'authentication_required' using errcode='42501';
  end if;

  insert into public.device_tokens(user_id, apns_token, environment, bundle_id)
  values(actor, lower(target_token), target_environment, target_bundle_id)
  on conflict (apns_token, environment) do update set
    bundle_id=excluded.bundle_id,
    is_active=true,
    last_seen_at=now(),
    updated_at=now()
  where public.device_tokens.user_id=actor
  returning id into result;

  if result is null then
    raise exception 'device_token_owned_by_another_user' using errcode='42501';
  end if;
  return result;
end; $$;

revoke all on function public.register_device_token(text,text,text) from public, anon;
grant execute on function public.register_device_token(text,text,text) to authenticated;
