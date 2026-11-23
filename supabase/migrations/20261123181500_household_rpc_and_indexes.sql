-- Follow-up: support atomic household creation and index FK lookup paths.
create index if not exists household_invitations_invited_by_idx on public.household_invitations(invited_by);
create index if not exists households_created_by_idx on public.households(created_by);
create index if not exists shopping_items_created_by_idx on public.shopping_items(created_by);
create index if not exists shopping_items_store_id_idx on public.shopping_items(store_id);
create index if not exists shopping_lists_created_by_idx on public.shopping_lists(created_by);
create index if not exists stores_created_by_idx on public.stores(created_by);
create index if not exists stores_household_id_idx on public.stores(household_id);

create or replace function public.create_household(p_name text, p_city text default null)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare v_household_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_name is null or length(trim(p_name)) = 0 or length(trim(p_name)) > 100 then
    raise exception 'Invalid household name';
  end if;
  insert into public.households(name, city, created_by)
    values (trim(p_name), nullif(trim(p_city), ''), auth.uid())
    returning id into v_household_id;
  insert into public.household_members(household_id, user_id, role)
    values (v_household_id, auth.uid(), 'owner');
  return v_household_id;
end;
$$;
revoke all on function public.create_household(text,text) from public, anon;
grant execute on function public.create_household(text,text) to authenticated;
