-- Recovered from the active Supabase migration history.
create or replace function public.create_household(p_name text, p_city text default null)
returns uuid language plpgsql security definer set search_path = '' as $function$
declare v_household_id uuid; v_user_id uuid := auth.uid();
begin
  if v_user_id is null then raise exception 'Authentication required'; end if;
  if p_name is null or length(trim(p_name)) = 0 or length(trim(p_name)) > 100 then raise exception 'Invalid household name'; end if;
  insert into public.households(name, city, created_by) values (trim(p_name), nullif(trim(p_city), ''), v_user_id) returning id into v_household_id;
  insert into public.household_members(household_id, user_id, role) values (v_household_id, v_user_id, 'owner');
  return v_household_id;
end;
$function$;
revoke all on function public.create_household(text, text) from public, anon;
grant execute on function public.create_household(text, text) to authenticated;
