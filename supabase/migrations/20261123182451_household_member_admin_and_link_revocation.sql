create or replace function public.revoke_household_join_link(p_household_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if not exists (
    select 1 from public.household_members hm
    where hm.household_id = p_household_id and hm.user_id = auth.uid() and hm.role = 'owner'
  ) then raise exception 'Only a household owner can revoke its join link'; end if;
  update public.household_join_links set revoked_at = now() where household_id = p_household_id;
end;
$$;

create or replace function public.remove_household_member(p_household_id uuid, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_user_id = auth.uid() then raise exception 'Use leave-household flow to remove yourself'; end if;
  if not exists (
    select 1 from public.household_members hm
    where hm.household_id = p_household_id and hm.user_id = auth.uid() and hm.role = 'owner'
  ) then raise exception 'Only a household owner can remove members'; end if;
  if not exists (
    select 1 from public.household_members hm
    where hm.household_id = p_household_id and hm.user_id = p_user_id and hm.role = 'member'
  ) then raise exception 'Target user is not a removable member'; end if;
  delete from public.household_members
  where household_id = p_household_id and user_id = p_user_id and role = 'member';
end;
$$;

revoke all on function public.revoke_household_join_link(uuid) from public, anon;
revoke all on function public.remove_household_member(uuid, uuid) from public, anon;
grant execute on function public.revoke_household_join_link(uuid) to authenticated;
grant execute on function public.remove_household_member(uuid, uuid) to authenticated;
