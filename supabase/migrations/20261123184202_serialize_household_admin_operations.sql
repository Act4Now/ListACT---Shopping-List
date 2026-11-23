create or replace function private.create_household_join_link(p_household_id uuid, p_token text)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  perform 1 from public.households h where h.id = p_household_id for update;
  if not found then raise exception 'Household not found'; end if;
  if p_token is null or length(p_token) <> 64 or p_token !~ '^[0-9a-f]{64}$' then raise exception 'Invalid join token'; end if;
  if not exists (select 1 from public.household_members m where m.household_id = p_household_id and m.user_id = auth.uid() and m.role = 'owner') then
    raise exception 'Only a household owner can create a join link';
  end if;
  insert into public.household_join_links(household_id, token_hash, created_by, created_at, revoked_at)
  values (p_household_id, encode(sha256(convert_to(p_token, 'UTF8')), 'hex'), auth.uid(), now(), null)
  on conflict (household_id) do update set token_hash = excluded.token_hash, created_by = excluded.created_by, created_at = now(), revoked_at = null;
end;
$$;

create or replace function private.revoke_household_join_link(p_household_id uuid)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  perform 1 from public.households h where h.id = p_household_id for update;
  if not found then raise exception 'Household not found'; end if;
  if not exists (select 1 from public.household_members hm where hm.household_id = p_household_id and hm.user_id = auth.uid() and hm.role = 'owner') then
    raise exception 'Only a household owner can revoke its join link';
  end if;
  update public.household_join_links set revoked_at = now() where household_id = p_household_id;
end;
$$;

create or replace function private.remove_household_member(p_household_id uuid, p_user_id uuid)
returns void language plpgsql security definer set search_path = ''
as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  perform 1 from public.households h where h.id = p_household_id for update;
  if not found then raise exception 'Household not found'; end if;
  if p_user_id = auth.uid() then raise exception 'Use leave-household flow to remove yourself'; end if;
  if not exists (select 1 from public.household_members hm where hm.household_id = p_household_id and hm.user_id = auth.uid() and hm.role = 'owner') then
    raise exception 'Only a household owner can remove members';
  end if;
  if not exists (select 1 from public.household_members hm where hm.household_id = p_household_id and hm.user_id = p_user_id and hm.role = 'member') then
    raise exception 'Target user is not a removable member';
  end if;
  delete from public.household_members where household_id = p_household_id and user_id = p_user_id and role = 'member';
end;
$$;
