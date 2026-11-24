-- Preserve the quantity and unit entered when a purchased product is re-added.
create or replace function public.add_shopping_item(
  p_list_id uuid, p_name text, p_quantity numeric default 1, p_unit text default 'buc'
)
returns public.shopping_items language plpgsql security invoker set search_path = '' as $function$
declare v_item public.shopping_items; v_name text := trim(p_name);
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if v_name is null or length(v_name) = 0 or length(v_name) > 160 then raise exception 'Invalid product name'; end if;
  if p_quantity is null or p_quantity <= 0 then raise exception 'Quantity must be positive'; end if;
  if p_unit not in ('buc','kg','g','l','ml') then raise exception 'Unsupported unit'; end if;
  if not exists (select 1 from public.shopping_lists sl join public.household_members hm on hm.household_id = sl.household_id where sl.id = p_list_id and hm.user_id = auth.uid()) then raise exception 'List not found or access denied'; end if;
  perform pg_advisory_xact_lock(hashtextextended(p_list_id::text || ':' || lower(v_name), 0));
  select * into v_item from public.shopping_items si where si.list_id = p_list_id and lower(trim(si.name)) = lower(v_name) and si.is_purchased = true order by si.created_at desc limit 1 for update;
  if found then
    update public.shopping_items set is_purchased = false, purchased_at = null, quantity = p_quantity, unit = p_unit, updated_at = now() where id = v_item.id returning * into v_item;
    return v_item;
  end if;
  select * into v_item from public.shopping_items si where si.list_id = p_list_id and lower(trim(si.name)) = lower(v_name) and si.unit = p_unit and si.is_purchased = false order by si.created_at desc limit 1 for update;
  if found then
    update public.shopping_items set quantity = quantity + p_quantity, updated_at = now() where id = v_item.id returning * into v_item;
    return v_item;
  end if;
  insert into public.shopping_items(list_id, name, quantity, unit, created_by) values (p_list_id, v_name, p_quantity, p_unit, auth.uid()) returning * into v_item;
  return v_item;
end;
$function$;
revoke all on function public.add_shopping_item(uuid,text,numeric,text) from public, anon;
grant execute on function public.add_shopping_item(uuid,text,numeric,text) to authenticated;
