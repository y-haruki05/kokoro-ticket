-- Review and dry-run before applying to the target Supabase project.
-- RLS remains enabled on every table. Only authenticated rows visible through
-- the existing policies are delivered by Supabase Realtime.

do $$
declare
  target_table text;
  target_tables constant text[] := array[
    'friend_requests',
    'friendships',
    'tickets',
    'ticket_transfers',
    'ticket_usage_requests'
  ];
begin
  foreach target_table in array target_tables
  loop
    if not exists (
      select 1
      from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = target_table
    ) then
      execute format(
        'alter publication supabase_realtime add table public.%I',
        target_table
      );
    end if;
  end loop;
end;
$$;
