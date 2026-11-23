alter function public.accept_household_join_link(uuid, text) set schema private;
alter function public.create_household_join_link(uuid, text) set schema private;
alter function public.remove_household_member(uuid, uuid) set schema private;
alter function public.revoke_household_join_link(uuid) set schema private;
alter function public.transfer_household_ownership(uuid, uuid) set schema private;

grant usage on schema private to authenticated;
grant execute on function private.accept_household_join_link(uuid, text) to authenticated;
grant execute on function private.create_household_join_link(uuid, text) to authenticated;
grant execute on function private.remove_household_member(uuid, uuid) to authenticated;
grant execute on function private.revoke_household_join_link(uuid) to authenticated;
grant execute on function private.transfer_household_ownership(uuid, uuid) to authenticated;
revoke all on function private.accept_household_join_link(uuid, text) from public, anon;
revoke all on function private.create_household_join_link(uuid, text) from public, anon;
revoke all on function private.remove_household_member(uuid, uuid) from public, anon;
revoke all on function private.revoke_household_join_link(uuid) from public, anon;
revoke all on function private.transfer_household_ownership(uuid, uuid) from public, anon;

create or replace function public.accept_household_join_link(p_household_id uuid, p_token text)
returns uuid language sql security invoker set search_path = ''
as $$ select private.accept_household_join_link(p_household_id, p_token); $$;
create or replace function public.create_household_join_link(p_household_id uuid, p_token text)
returns void language sql security invoker set search_path = ''
as $$ select private.create_household_join_link(p_household_id, p_token); $$;
create or replace function public.remove_household_member(p_household_id uuid, p_user_id uuid)
returns void language sql security invoker set search_path = ''
as $$ select private.remove_household_member(p_household_id, p_user_id); $$;
create or replace function public.revoke_household_join_link(p_household_id uuid)
returns void language sql security invoker set search_path = ''
as $$ select private.revoke_household_join_link(p_household_id); $$;
create or replace function public.transfer_household_ownership(p_household_id uuid, p_new_owner_id uuid)
returns void language sql security invoker set search_path = ''
as $$ select private.transfer_household_ownership(p_household_id, p_new_owner_id); $$;

revoke all on function public.accept_household_join_link(uuid, text) from public, anon;
revoke all on function public.create_household_join_link(uuid, text) from public, anon;
revoke all on function public.remove_household_member(uuid, uuid) from public, anon;
revoke all on function public.revoke_household_join_link(uuid) from public, anon;
revoke all on function public.transfer_household_ownership(uuid, uuid) from public, anon;
grant execute on function public.accept_household_join_link(uuid, text) to authenticated;
grant execute on function public.create_household_join_link(uuid, text) to authenticated;
grant execute on function public.remove_household_member(uuid, uuid) to authenticated;
grant execute on function public.revoke_household_join_link(uuid) to authenticated;
grant execute on function public.transfer_household_ownership(uuid, uuid) to authenticated;
