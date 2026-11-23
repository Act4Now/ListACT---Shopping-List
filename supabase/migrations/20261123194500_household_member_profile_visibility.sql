-- Permit household members to see only the basic profile of people sharing a household.
create policy "profiles_select_household_members" on public.profiles for select to authenticated
using (
  exists (
    select 1
    from public.household_members self_member
    join public.household_members other_member
      on other_member.household_id = self_member.household_id
    where self_member.user_id = (select auth.uid())
      and other_member.user_id = profiles.id
  )
);
