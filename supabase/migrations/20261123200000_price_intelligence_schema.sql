-- Price Intelligence data model. No source is enabled until reuse rights are verified.
create table public.price_sources (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  source_url text,
  terms_url text,
  license_name text,
  reuse_permitted boolean not null default false,
  terms_verified_at timestamptz,
  is_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  check (not is_enabled or (reuse_permitted and terms_verified_at is not null))
);

create table public.store_locations (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  city text not null,
  address text,
  postal_code text,
  latitude numeric(9,6),
  longitude numeric(9,6),
  source_id uuid references public.price_sources(id) on delete set null,
  created_at timestamptz not null default now(),
  check (latitude is null or latitude between -90 and 90),
  check (longitude is null or longitude between -180 and 180)
);

create table public.price_products (
  id uuid primary key default gen_random_uuid(),
  ean text unique,
  name text not null,
  brand text,
  package_quantity numeric(12,3),
  package_unit text check (package_unit is null or package_unit in ('buc','kg','g','l','ml')),
  normalized_name text not null,
  category text,
  created_at timestamptz not null default now()
);

create table public.price_observations (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.price_products(id) on delete cascade,
  store_location_id uuid not null references public.store_locations(id) on delete cascade,
  source_id uuid not null references public.price_sources(id),
  price numeric(12,2) not null check (price >= 0),
  currency text not null default 'RON' check (currency = 'RON'),
  observed_at timestamptz not null,
  match_type text not null check (match_type in ('exact','similar')),
  source_url text,
  created_at timestamptz not null default now()
);

create table public.product_similarity_groups (
  id uuid primary key default gen_random_uuid(),
  label text not null,
  category text,
  unit text not null check (unit in ('buc','kg','g','l','ml')),
  created_at timestamptz not null default now()
);
create table public.product_similarity_members (
  group_id uuid not null references public.product_similarity_groups(id) on delete cascade,
  product_id uuid not null references public.price_products(id) on delete cascade,
  primary key (group_id, product_id),
  unique (product_id, group_id)
);

create table public.price_estimates (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  shopping_item_id uuid not null references public.shopping_items(id) on delete cascade,
  estimated_unit_price numeric(12,2) not null check (estimated_unit_price >= 0),
  currency text not null default 'RON' check (currency = 'RON'),
  city text not null,
  match_type text not null check (match_type in ('exact','similar')),
  sample_count integer not null default 1 check (sample_count > 0),
  source_count integer not null default 1 check (source_count > 0),
  observed_at timestamptz not null,
  created_at timestamptz not null default now(),
  unique (shopping_item_id)
);

create table public.list_item_price_overrides (
  shopping_item_id uuid primary key references public.shopping_items(id) on delete cascade,
  personal_unit_price numeric(12,2) not null check (personal_unit_price >= 0),
  currency text not null default 'RON' check (currency = 'RON'),
  updated_by uuid not null references auth.users(id),
  updated_at timestamptz not null default now()
);

create index store_locations_store_city_idx on public.store_locations(store_id, city);
create index price_products_normalized_name_idx on public.price_products(normalized_name);
create index price_observations_product_date_idx on public.price_observations(product_id, observed_at desc);
create index price_observations_location_date_idx on public.price_observations(store_location_id, observed_at desc);
create index price_estimates_household_idx on public.price_estimates(household_id);
create index price_estimates_item_idx on public.price_estimates(shopping_item_id);

alter table public.price_sources enable row level security;
alter table public.store_locations enable row level security;
alter table public.price_products enable row level security;
alter table public.price_observations enable row level security;
alter table public.product_similarity_groups enable row level security;
alter table public.product_similarity_members enable row level security;
alter table public.price_estimates enable row level security;
alter table public.list_item_price_overrides enable row level security;

create policy "price_sources_read_enabled" on public.price_sources for select to authenticated using (is_enabled and reuse_permitted);
create policy "store_locations_read_visible_store" on public.store_locations for select to authenticated
using (exists (select 1 from public.stores s where s.id = store_id and (s.is_system or private.is_household_member(s.household_id))));
create policy "price_products_read_authenticated" on public.price_products for select to authenticated using (true);
create policy "price_observations_read_enabled_source" on public.price_observations for select to authenticated
using (exists (select 1 from public.price_sources ps where ps.id = source_id and ps.is_enabled and ps.reuse_permitted));
create policy "similarity_groups_read_authenticated" on public.product_similarity_groups for select to authenticated using (true);
create policy "similarity_members_read_authenticated" on public.product_similarity_members for select to authenticated using (true);
create policy "price_estimates_read_household" on public.price_estimates for select to authenticated
using (private.is_household_member(household_id));
create policy "price_estimates_insert_household" on public.price_estimates for insert to authenticated
with check (
  private.is_household_member(household_id)
  and exists (select 1 from public.shopping_items si join public.shopping_lists sl on sl.id = si.list_id
    where si.id = shopping_item_id and sl.household_id = price_estimates.household_id)
);
create policy "price_overrides_read_member" on public.list_item_price_overrides for select to authenticated
using (exists (select 1 from public.shopping_items si join public.shopping_lists sl on sl.id = si.list_id
  where si.id = shopping_item_id and private.is_household_member(sl.household_id)));
create policy "price_overrides_insert_member" on public.list_item_price_overrides for insert to authenticated
with check (updated_by = (select auth.uid()) and exists (select 1 from public.shopping_items si join public.shopping_lists sl on sl.id = si.list_id
  where si.id = shopping_item_id and private.is_household_member(sl.household_id)));
create policy "price_overrides_update_member" on public.list_item_price_overrides for update to authenticated
using (exists (select 1 from public.shopping_items si join public.shopping_lists sl on sl.id = si.list_id
  where si.id = shopping_item_id and private.is_household_member(sl.household_id)))
with check (updated_by = (select auth.uid()) and exists (select 1 from public.shopping_items si join public.shopping_lists sl on sl.id = si.list_id
  where si.id = shopping_item_id and private.is_household_member(sl.household_id)));
create policy "price_overrides_delete_member" on public.list_item_price_overrides for delete to authenticated
using (exists (select 1 from public.shopping_items si join public.shopping_lists sl on sl.id = si.list_id
  where si.id = shopping_item_id and private.is_household_member(sl.household_id)));

grant select on public.price_sources, public.store_locations, public.price_products,
  public.price_observations, public.product_similarity_groups, public.product_similarity_members,
  public.price_estimates, public.list_item_price_overrides to authenticated;
grant insert, update, delete on public.list_item_price_overrides to authenticated;
grant insert, update on public.price_estimates to authenticated;
