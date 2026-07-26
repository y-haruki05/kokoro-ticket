revoke all
on function public.is_friend_code_available(text)
from anon;

revoke all
on function public.is_friend_code_available(text)
from public;

grant execute
on function public.is_friend_code_available(text)
to authenticated;
