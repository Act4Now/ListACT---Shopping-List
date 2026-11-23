-- Each member owns their own price override for a shared item.
-- Existing rows retain their author as owner.
alter table public.list_item_price_overrides
  drop constraint list_item_price_overrides_pkey;
alter table public.list_item_price_overrides
  add constraint list_item_price_overrides_pkey primary key (shopping_item_id, updated_by);
drop policy if exists price_overrides_read_member on public.list_item_price_overrides;
drop policy if exists price_overrides_delete_member on public.list_item_price_overrides;
drop policy if exists price_overrides_update_member on public.list_item_price_overrides;
create policy price_overrides_read_own on public.list_item_price_overrides
  for select to authenticated using (
    updated_by = (select auth.uid())
    and exists (
      select 1 from public.shopping_items si
      join public.shopping_lists sl on sl.id = si.list_id
      where si.id = shopping_item_id and private.is_household_member(sl.household_id)
    )
  );
create policy price_overrides_delete_own on public.list_item_price_overrides
  for delete to authenticated using (
    updated_by = (select auth.uid())
    and exists (
      select 1 from public.shopping_items si
      join public.shopping_lists sl on sl.id = si.list_id
      where si.id = shopping_item_id and private.is_household_member(sl.household_id)
    )
  );
create policy price_overrides_update_own on public.list_item_price_overrides
  for update to authenticated using (
    updated_by = (select auth.uid())
    and exists (
      select 1 from public.shopping_items si
      join public.shopping_lists sl on sl.id = si.list_id
      where si.id = shopping_item_id and private.is_household_member(sl.household_id)
    )
  ) with check (
    updated_by = (select auth.uid())
    and exists (
      select 1 from public.shopping_items si
      join public.shopping_lists sl on sl.id = si.list_id
      where si.id = shopping_item_id and private.is_household_member(sl.household_id)
    )
  );
