-- ListACT initial schema. PostgreSQL 17 / Supabase.
create extension if not exists pgcrypto;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  city text,
  font_size integer not null default 16 check (font_size in (16,18,20,22)),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) between 1 and 100),
  city text,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.household_members (
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner','member')),
  joined_at timestamptz not null default now(),
  primary key (household_id, user_id)
);

create table public.household_invitations (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  email text not null,
  token_hash text not null unique,
  invited_by uuid not null references auth.users(id),
  expires_at timestamptz not null,
  accepted_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.shopping_lists (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  name text not null check (length(trim(name)) between 1 and 120),
  archived_at timestamptz,
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, household_id)
);

create table public.stores (
  id uuid primary key default gen_random_uuid(),
  household_id uuid references public.households(id) on delete cascade,
  name text not null check (length(trim(name)) between 1 and 100),
  is_system boolean not null default false,
  is_active boolean not null default true,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  check ((is_system and household_id is null) or (not is_system and household_id is not null))
);

create table public.shopping_items (
  id uuid primary key default gen_random_uuid(),
  list_id uuid not null references public.shopping_lists(id) on delete cascade,
  name text not null check (length(trim(name)) between 1 and 160),
  quantity numeric(12,3) not null default 1 check (quantity > 0),
  unit text not null default 'buc' check (unit in ('buc','kg','g','l','ml')),
  unit_price numeric(12,2) check (unit_price is null or unit_price >= 0),
  price_currency text not null default 'RON' check (price_currency = 'RON'),
  store_id uuid references public.stores(id) on delete set null,
  is_purchased boolean not null default false,
  purchased_at timestamptz,
  created_by uuid not null default auth.uid() references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index household_members_user_idx on public.household_members(user_id);
create index shopping_lists_household_idx on public.shopping_lists(household_id);
create index shopping_items_list_idx on public.shopping_items(list_id);
create index household_invitations_household_idx on public.household_invitations(household_id);

-- Non-exposed helper schema avoids recursive membership RLS policies.
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

create or replace function private.is_household_member(p_household_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.household_members hm
    where hm.household_id = p_household_id and hm.user_id = (select auth.uid())
  );
$$;
create or replace function private.is_household_owner(p_household_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.household_members hm
    where hm.household_id = p_household_id and hm.user_id = (select auth.uid()) and hm.role = 'owner'
  );
$$;
revoke all on function private.is_household_member(uuid) from public, anon;
revoke all on function private.is_household_owner(uuid) from public, anon;
grant execute on function private.is_household_member(uuid) to authenticated;
grant execute on function private.is_household_owner(uuid) to authenticated;

-- Every exposed table is protected by RLS.
alter table public.profiles enable row level security;
alter table public.households enable row level security;
alter table public.household_members enable row level security;
alter table public.household_invitations enable row level security;
alter table public.shopping_lists enable row level security;
alter table public.stores enable row level security;
alter table public.shopping_items enable row level security;

create policy "profiles_select_own" on public.profiles for select to authenticated using (id = (select auth.uid()));
create policy "profiles_insert_own" on public.profiles for insert to authenticated with check (id = (select auth.uid()));
create policy "profiles_update_own" on public.profiles for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));

create policy "households_select_member" on public.households for select to authenticated
using (private.is_household_member(id));
create policy "households_insert_creator" on public.households for insert to authenticated with check (created_by = (select auth.uid()));
create policy "households_update_owner" on public.households for update to authenticated
using (private.is_household_owner(id)) with check (private.is_household_owner(id));

create policy "members_select_same_household" on public.household_members for select to authenticated
using (private.is_household_member(household_id));
create policy "members_insert_owner_or_creator" on public.household_members for insert to authenticated
with check (
  (user_id = (select auth.uid()) and role = 'owner' and exists (select 1 from public.households h where h.id = household_id and h.created_by = (select auth.uid())))
  or private.is_household_owner(household_id)
);
create policy "members_delete_owner_or_self" on public.household_members for delete to authenticated
using (user_id = (select auth.uid()) or private.is_household_owner(household_id));

create policy "invitations_select_owner" on public.household_invitations for select to authenticated using (private.is_household_owner(household_id));
create policy "invitations_insert_owner" on public.household_invitations for insert to authenticated
with check (invited_by = (select auth.uid()) and private.is_household_owner(household_id));
create policy "invitations_delete_owner" on public.household_invitations for delete to authenticated using (private.is_household_owner(household_id));

create policy "lists_member_access" on public.shopping_lists for select to authenticated using (private.is_household_member(household_id));
create policy "lists_member_insert" on public.shopping_lists for insert to authenticated
with check (created_by = (select auth.uid()) and private.is_household_member(household_id));
create policy "lists_member_update" on public.shopping_lists for update to authenticated
using (private.is_household_member(household_id)) with check (private.is_household_member(household_id));
create policy "lists_owner_delete" on public.shopping_lists for delete to authenticated using (private.is_household_owner(household_id));

create policy "stores_select_global_or_member" on public.stores for select to authenticated
using (is_system or private.is_household_member(household_id));
create policy "stores_insert_member" on public.stores for insert to authenticated
with check (not is_system and created_by = (select auth.uid()) and private.is_household_member(household_id));
create policy "stores_update_member" on public.stores for update to authenticated
using (not is_system and private.is_household_member(household_id))
with check (not is_system and private.is_household_member(household_id));
create policy "stores_delete_member" on public.stores for delete to authenticated
using (not is_system and private.is_household_member(household_id));

create policy "items_member_select" on public.shopping_items for select to authenticated
using (exists (select 1 from public.shopping_lists sl where sl.id = shopping_items.list_id and private.is_household_member(sl.household_id)));
create policy "items_member_insert" on public.shopping_items for insert to authenticated
with check (created_by = (select auth.uid()) and exists (select 1 from public.shopping_lists sl where sl.id = shopping_items.list_id and private.is_household_member(sl.household_id)));
create policy "items_member_update" on public.shopping_items for update to authenticated
using (exists (select 1 from public.shopping_lists sl where sl.id = shopping_items.list_id and private.is_household_member(sl.household_id)))
with check (exists (select 1 from public.shopping_lists sl where sl.id = shopping_items.list_id and private.is_household_member(sl.household_id)));
create policy "items_member_delete" on public.shopping_items for delete to authenticated
using (exists (select 1 from public.shopping_lists sl where sl.id = shopping_items.list_id and private.is_household_member(sl.household_id)));

-- Prevent assigning a custom store owned by a different household.
create or replace function public.validate_item_store()
returns trigger language plpgsql security invoker set search_path = ''
as $$
declare v_household_id uuid; v_store_household_id uuid; v_is_system boolean;
begin
  select sl.household_id into v_household_id from public.shopping_lists sl where sl.id = new.list_id;
  if new.store_id is not null then
    select s.household_id, s.is_system into v_store_household_id, v_is_system
      from public.stores s where s.id = new.store_id;
    if not found or (not v_is_system and v_store_household_id is distinct from v_household_id) then
      raise exception 'Store does not belong to this household';
    end if;
  end if;
  return new;
end;
$$;
create trigger shopping_item_store_guard before insert or update of list_id, store_id
on public.shopping_items for each row execute function public.validate_item_store();

-- Keep a profile row for every newly registered auth user.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'));
  return new;
end;
$$;
revoke all on function public.handle_new_user() from public, anon, authenticated;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Atomic duplicate handling. Same name + same unit merges; a purchased match is reactivated as 1 buc.
create or replace function public.add_shopping_item(
  p_list_id uuid, p_name text, p_quantity numeric default 1, p_unit text default 'buc'
)
returns public.shopping_items
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_item public.shopping_items;
  v_name text := trim(p_name);
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if v_name is null or length(v_name) = 0 or length(v_name) > 160 then raise exception 'Invalid product name'; end if;
  if p_quantity is null or p_quantity <= 0 then raise exception 'Quantity must be positive'; end if;
  if p_unit not in ('buc','kg','g','l','ml') then raise exception 'Unsupported unit'; end if;
  if not exists (
    select 1 from public.shopping_lists sl
    join public.household_members hm on hm.household_id = sl.household_id
    where sl.id = p_list_id and hm.user_id = auth.uid()
  ) then raise exception 'List not found or access denied'; end if;

  perform pg_advisory_xact_lock(hashtextextended(p_list_id::text || ':' || lower(v_name), 0));

  select * into v_item from public.shopping_items si
  where si.list_id = p_list_id and lower(trim(si.name)) = lower(v_name) and si.is_purchased = true
  order by si.created_at desc limit 1 for update;

  if found then
    update public.shopping_items
      set is_purchased = false, purchased_at = null, quantity = 1, unit = 'buc', updated_at = now()
      where id = v_item.id returning * into v_item;
    return v_item;
  end if;

  select * into v_item from public.shopping_items si
  where si.list_id = p_list_id and lower(trim(si.name)) = lower(v_name) and si.unit = p_unit and si.is_purchased = false
  order by si.created_at desc limit 1 for update;

  if found then
    update public.shopping_items
      set quantity = quantity + p_quantity, updated_at = now()
      where id = v_item.id returning * into v_item;
    return v_item;
  end if;

  insert into public.shopping_items(list_id, name, quantity, unit, created_by)
  values (p_list_id, v_name, p_quantity, p_unit, auth.uid())
  returning * into v_item;
  return v_item;
end;
$$;
revoke all on function public.add_shopping_item(uuid,text,numeric,text) from public, anon;
grant execute on function public.add_shopping_item(uuid,text,numeric,text) to authenticated;

-- Explicit table grants are required for the Data API; RLS remains the row-level boundary.
grant usage on schema public to authenticated;
grant select, insert, update, delete on public.profiles, public.households, public.household_members,
  public.household_invitations, public.shopping_lists, public.stores, public.shopping_items to authenticated;
