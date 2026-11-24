-- Community price references. One household contributes at most one value per product/day.
create table if not exists public.household_price_contributions (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  product_id uuid not null references public.price_products(id) on delete cascade,
  city text not null,
  unit_price numeric(12,2) not null check (unit_price >= 0),
  contribution_date date not null default (timezone('utc', now()))::date,
  created_at timestamptz not null default now(),
  unique (household_id, product_id, contribution_date)
);
create index if not exists household_price_contributions_window_idx
  on public.household_price_contributions(product_id, city, created_at desc);
alter table public.household_price_contributions enable row level security;
revoke all on public.household_price_contributions from anon, authenticated;
-- No direct SELECT/INSERT/UPDATE/DELETE policies: client identities cannot inspect or forge contributions.

create table if not exists public.price_reference_aggregates (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.price_products(id) on delete cascade,
  city text not null,
  median_unit_price numeric(12,2) not null check (median_unit_price >= 0),
  currency text not null default 'RON' check (currency = 'RON'),
  sample_count integer not null check (sample_count > 0),
  household_count integer not null check (household_count > 0),
  window_end date not null,
  updated_at timestamptz not null default now(),
  unique (product_id, city, window_end)
);
create index if not exists price_reference_aggregates_lookup_idx
  on public.price_reference_aggregates(product_id, city, window_end desc);
alter table public.price_reference_aggregates enable row level security;
drop policy if exists price_reference_aggregates_read_authenticated on public.price_reference_aggregates;
create policy price_reference_aggregates_read_authenticated
  on public.price_reference_aggregates for select to authenticated using (true);
revoke insert, update, delete on public.price_reference_aggregates from anon, authenticated;
grant select on public.price_reference_aggregates to authenticated;

create or replace function private.capture_household_price_contribution()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_household_id uuid;
  v_city text;
  v_normalized text;
  v_product_id uuid;
begin
  if new.unit_price is null or (tg_op = 'UPDATE' and new.unit_price is not distinct from old.unit_price) then
    return new;
  end if;
  select sl.household_id, h.city
    into v_household_id, v_city
  from public.shopping_lists sl
  join public.households h on h.id = sl.household_id
  where sl.id = new.list_id;
  if v_household_id is null or nullif(trim(v_city), '') is null then return new; end if;

  v_normalized := lower(trim(translate(new.name,
    'ĂÂÎȘȚăâîșț', 'AAISTaaist')));
  v_normalized := regexp_replace(v_normalized, '\s+', ' ', 'g');
  select pp.id into v_product_id
  from public.price_products pp
  where pp.normalized_name = v_normalized
  limit 1;
  if v_product_id is null then return new; end if;

  insert into public.household_price_contributions
    (household_id, product_id, city, unit_price, contribution_date)
  values (
    v_household_id, v_product_id,
    lower(trim(translate(v_city, 'ĂÂÎȘȚăâîșț', 'AAISTaaist'))),
    new.unit_price, (timezone('utc', now()))::date
  )
  on conflict (household_id, product_id, contribution_date)
  do update set city = excluded.city, unit_price = excluded.unit_price, created_at = now();
  return new;
end;
$$;

drop trigger if exists capture_household_price_contribution on public.shopping_items;
create trigger capture_household_price_contribution
after insert or update of unit_price on public.shopping_items
for each row execute function private.capture_household_price_contribution();

create or replace function public.refresh_price_reference_aggregates()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  with recent as (
    select c.product_id, c.city, c.unit_price, c.household_id
    from public.household_price_contributions c
    where c.created_at >= now() - interval '60 days'
  ), medians as (
    select product_id, city, percentile_cont(0.5) within group (order by unit_price) as median_price
    from recent group by product_id, city
  ), filtered as (
    select r.product_id, r.city, r.unit_price, r.household_id
    from recent r join medians m using (product_id, city)
    where r.unit_price between m.median_price / 2 and m.median_price * 2
  ), grouped as (
    select product_id, city,
      percentile_cont(0.5) within group (order by unit_price)::numeric(12,2) as median_price,
      count(*)::integer as sample_count,
      count(distinct household_id)::integer as household_count
    from filtered group by product_id, city
  )
  insert into public.price_reference_aggregates
    (product_id, city, median_unit_price, sample_count, household_count, window_end, updated_at)
  select product_id, city, median_price, sample_count, household_count, current_date, now()
  from grouped
  where sample_count >= 1 and household_count >= 1
  on conflict (product_id, city, window_end)
  do update set median_unit_price = excluded.median_unit_price,
    sample_count = excluded.sample_count, household_count = excluded.household_count,
    updated_at = now();
end;
$$;
revoke all on function public.refresh_price_reference_aggregates() from public, anon, authenticated;
grant execute on function public.refresh_price_reference_aggregates() to service_role;

create or replace function private.refresh_price_reference_after_contribution()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.refresh_price_reference_aggregates();
  return new;
end;
$$;
drop trigger if exists refresh_price_reference_after_contribution on public.household_price_contributions;
create trigger refresh_price_reference_after_contribution
after insert or update on public.household_price_contributions
for each row execute function private.refresh_price_reference_after_contribution();
