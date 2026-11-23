-- Consolidate profile SELECT rules and cover remaining foreign-key lookup paths.
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_self_or_household" on public.profiles for select to authenticated
using (
  id = (select auth.uid())
  or exists (
    select 1
    from public.household_members self_member
    join public.household_members other_member
      on other_member.household_id = self_member.household_id
    where self_member.user_id = (select auth.uid())
      and other_member.user_id = profiles.id
  )
);

create index if not exists list_item_price_overrides_updated_by_idx on public.list_item_price_overrides(updated_by);
create index if not exists price_observations_source_id_idx on public.price_observations(source_id);
create index if not exists store_locations_source_id_idx on public.store_locations(source_id);
