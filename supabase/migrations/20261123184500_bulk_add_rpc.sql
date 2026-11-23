-- Atomic bulk add. UI previews duplicates before this RPC is called.
create or replace function public.add_shopping_items_bulk(p_list_id uuid, p_items jsonb)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_row jsonb;
  v_name text;
  v_qty numeric;
  v_unit text;
  v_added integer := 0;
  v_processed integer := 0;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) > 200 then
    raise exception 'Expected an array of at most 200 items';
  end if;
  if not exists (
    select 1 from public.shopping_lists sl
    join public.household_members hm on hm.household_id = sl.household_id
    where sl.id = p_list_id and hm.user_id = auth.uid()
  ) then raise exception 'List not found or access denied'; end if;

  for v_row in select value from jsonb_array_elements(p_items)
  loop
    v_name := trim(v_row ->> 'name');
    v_qty := coalesce((v_row ->> 'quantity')::numeric, 1);
    v_unit := coalesce(v_row ->> 'unit', 'buc');
    if v_name is null or length(v_name) = 0 or length(v_name) > 160 then
      raise exception 'Invalid product name in bulk data';
    end if;
    if v_qty <= 0 or v_unit not in ('buc','kg','g','l','ml') then
      raise exception 'Invalid quantity or unit in bulk data';
    end if;
    perform public.add_shopping_item(p_list_id, v_name, v_qty, v_unit);
    v_processed := v_processed + 1;
  end loop;
  return jsonb_build_object('processed', v_processed, 'ok', true);
end;
$$;
revoke all on function public.add_shopping_items_bulk(uuid,jsonb) from public, anon;
grant execute on function public.add_shopping_items_bulk(uuid,jsonb) to authenticated;
