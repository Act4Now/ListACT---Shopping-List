create unique index if not exists household_members_one_owner_per_household_idx
on public.household_members (household_id)
where role = 'owner';

create or replace function public.transfer_household_ownership(p_household_id uuid, p_new_owner_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  perform 1 from public.households h where h.id = p_household_id for update;
  if not found then raise exception 'Household not found'; end if;
  if p_new_owner_id = auth.uid() then raise exception 'You are already the owner'; end if;
  if not exists (
    select 1 from public.household_members hm
    where hm.household_id = p_household_id and hm.user_id = auth.uid() and hm.role = 'owner'
  ) then raise exception 'Only the current owner can transfer ownership'; end if;
  if not exists (
    select 1 from public.household_members hm
    where hm.household_id = p_household_id and hm.user_id = p_new_owner_id and hm.role = 'member'
  ) then raise exception 'New owner must already be a household member'; end if;
  update public.household_members set role = 'member'
  where household_id = p_household_id and user_id = auth.uid() and role = 'owner';
  update public.household_members set role = 'owner'
  where household_id = p_household_id and user_id = p_new_owner_id and role = 'member';
end;
$$;
