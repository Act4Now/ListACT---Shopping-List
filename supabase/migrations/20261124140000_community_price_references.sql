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

-- Canonical exact-name catalog; seed contains no prices because no licensed public source was verified.
create unique index if not exists price_products_normalized_name_uidx
  on public.price_products(normalized_name);
insert into public.price_products (name, normalized_name, category, package_unit)
values
('Lapte', 'lapte', 'lactate', 'buc'),
('Lapte fără lactoză', 'lapte fara lactoza', 'lactate', 'buc'),
('Iaurt natural', 'iaurt natural', 'lactate', 'buc'),
('Iaurt grecesc', 'iaurt grecesc', 'lactate', 'buc'),
('Iaurt de băut', 'iaurt de baut', 'lactate', 'buc'),
('Chefir', 'chefir', 'lactate', 'buc'),
('Sana', 'sana', 'lactate', 'buc'),
('Smântână', 'smantana', 'lactate', 'buc'),
('Unt', 'unt', 'lactate', 'buc'),
('Margarină', 'margarina', 'lactate', 'buc'),
('Cașcaval', 'cascaval', 'lactate', 'buc'),
('Telemea', 'telemea', 'lactate', 'buc'),
('Brânză de vaci', 'branza de vaci', 'lactate', 'buc'),
('Brânză feta', 'branza feta', 'lactate', 'buc'),
('Mozzarella', 'mozzarella', 'lactate', 'buc'),
('Parmezan', 'parmezan', 'lactate', 'buc'),
('Cremă de brânză', 'crema de branza', 'lactate', 'buc'),
('Brânză topită', 'branza topita', 'lactate', 'buc'),
('Frișcă lichidă', 'frisca lichida', 'lactate', 'buc'),
('Lapte condensat', 'lapte condensat', 'lactate', 'buc'),
('Pâine albă', 'paine alba', 'panificatie', 'buc'),
('Pâine integrală', 'paine integrala', 'panificatie', 'buc'),
('Pâine toast', 'paine toast', 'panificatie', 'buc'),
('Chifle', 'chifle', 'panificatie', 'buc'),
('Baghetă', 'bagheta', 'panificatie', 'buc'),
('Lipie', 'lipie', 'panificatie', 'buc'),
('Pită', 'pita', 'panificatie', 'buc'),
('Covrigi', 'covrigi', 'panificatie', 'buc'),
('Cornuri', 'cornuri', 'panificatie', 'buc'),
('Pesmet', 'pesmet', 'panificatie', 'buc'),
('Făină albă', 'faina alba', 'panificatie', 'buc'),
('Făină integrală', 'faina integrala', 'panificatie', 'buc'),
('Mălai', 'malai', 'panificatie', 'buc'),
('Griș', 'gris', 'panificatie', 'buc'),
('Fulgi de ovăz', 'fulgi de ovaz', 'panificatie', 'buc'),
('Cereale pentru mic dejun', 'cereale pentru mic dejun', 'panificatie', 'buc'),
('Musli', 'musli', 'panificatie', 'buc'),
('Pesmeți', 'pesmeti', 'panificatie', 'buc'),
('Biscuiți simpli', 'biscuiti simpli', 'panificatie', 'buc'),
('Crackers', 'crackers', 'panificatie', 'buc'),
('Mere', 'mere', 'fructe', 'kg'),
('Pere', 'pere', 'fructe', 'kg'),
('Banane', 'banane', 'fructe', 'kg'),
('Portocale', 'portocale', 'fructe', 'kg'),
('Mandarine', 'mandarine', 'fructe', 'kg'),
('Lămâi', 'lamai', 'fructe', 'kg'),
('Lime', 'lime', 'fructe', 'kg'),
('Grapefruit', 'grapefruit', 'fructe', 'kg'),
('Struguri', 'struguri', 'fructe', 'kg'),
('Căpșuni', 'capsuni', 'fructe', 'kg'),
('Afine', 'afine', 'fructe', 'kg'),
('Zmeură', 'zmeura', 'fructe', 'kg'),
('Mure', 'mure', 'fructe', 'kg'),
('Piersici', 'piersici', 'fructe', 'kg'),
('Nectarine', 'nectarine', 'fructe', 'kg'),
('Prune', 'prune', 'fructe', 'kg'),
('Caise', 'caise', 'fructe', 'kg'),
('Cireșe', 'cirese', 'fructe', 'kg'),
('Vișine', 'visine', 'fructe', 'kg'),
('Pepene verde', 'pepene verde', 'fructe', 'kg'),
('Pepene galben', 'pepene galben', 'fructe', 'kg'),
('Kiwi', 'kiwi', 'fructe', 'kg'),
('Ananas', 'ananas', 'fructe', 'kg'),
('Mango', 'mango', 'fructe', 'kg'),
('Avocado', 'avocado', 'fructe', 'kg'),
('Cartofi', 'cartofi', 'legume', 'kg'),
('Morcovi', 'morcovi', 'legume', 'kg'),
('Ceapă', 'ceapa', 'legume', 'kg'),
('Usturoi', 'usturoi', 'legume', 'kg'),
('Roșii', 'rosii', 'legume', 'kg'),
('Castraveți', 'castraveti', 'legume', 'kg'),
('Ardei gras', 'ardei gras', 'legume', 'kg'),
('Ardei kapia', 'ardei kapia', 'legume', 'kg'),
('Salată verde', 'salata verde', 'legume', 'kg'),
('Varză albă', 'varza alba', 'legume', 'kg'),
('Varză roșie', 'varza rosie', 'legume', 'kg'),
('Conopidă', 'conopida', 'legume', 'kg'),
('Broccoli', 'broccoli', 'legume', 'kg'),
('Dovlecei', 'dovlecei', 'legume', 'kg'),
('Vinete', 'vinete', 'legume', 'kg'),
('Ciuperci', 'ciuperci', 'legume', 'kg'),
('Fasole verde', 'fasole verde', 'legume', 'kg'),
('Mazăre', 'mazare', 'legume', 'kg'),
('Porumb', 'porumb', 'legume', 'kg'),
('Sfeclă roșie', 'sfecla rosie', 'legume', 'kg'),
('Ridichi', 'ridichi', 'legume', 'kg'),
('Țelină', 'telina', 'legume', 'kg'),
('Păstârnac', 'pastarnac', 'legume', 'kg'),
('Pătrunjel rădăcină', 'patrunjel radacina', 'legume', 'kg'),
('Spanac', 'spanac', 'legume', 'kg'),
('Piept de pui', 'piept de pui', 'carne_peste', 'kg'),
('Pulpe de pui', 'pulpe de pui', 'carne_peste', 'kg'),
('Aripi de pui', 'aripi de pui', 'carne_peste', 'kg'),
('Carne tocată de porc', 'carne tocata de porc', 'carne_peste', 'kg'),
('Carne tocată de vită', 'carne tocata de vita', 'carne_peste', 'kg'),
('Pulpă de porc', 'pulpa de porc', 'carne_peste', 'kg'),
('Cotlet de porc', 'cotlet de porc', 'carne_peste', 'kg'),
('Mușchiuleț de porc', 'muschiulet de porc', 'carne_peste', 'kg'),
('Carne de vită', 'carne de vita', 'carne_peste', 'kg'),
('Carne de curcan', 'carne de curcan', 'carne_peste', 'kg'),
('Piept de curcan', 'piept de curcan', 'carne_peste', 'kg'),
('Cârnați', 'carnati', 'carne_peste', 'kg'),
('Crenvurști', 'crenvursti', 'carne_peste', 'kg'),
('Șuncă', 'sunca', 'carne_peste', 'kg'),
('Salam', 'salam', 'carne_peste', 'kg'),
('Bacon', 'bacon', 'carne_peste', 'kg'),
('Pește proaspăt', 'peste proaspat', 'carne_peste', 'kg'),
('Somon', 'somon', 'carne_peste', 'kg'),
('Păstrăv', 'pastrav', 'carne_peste', 'kg'),
('Ton conservă', 'ton conserva', 'carne_peste', 'kg'),
('Orez', 'orez', 'bacanie', 'buc'),
('Paste', 'paste', 'bacanie', 'buc'),
('Spaghete', 'spaghete', 'bacanie', 'buc'),
('Macaroane', 'macaroane', 'bacanie', 'buc'),
('Fidea', 'fidea', 'bacanie', 'buc'),
('Linte', 'linte', 'bacanie', 'buc'),
('Năut', 'naut', 'bacanie', 'buc'),
('Fasole uscată', 'fasole uscata', 'bacanie', 'buc'),
('Fasole conservă', 'fasole conserva', 'bacanie', 'buc'),
('Roșii pasate', 'rosii pasate', 'bacanie', 'buc'),
('Bulion', 'bulion', 'bacanie', 'buc'),
('Ulei de floarea-soarelui', 'ulei de floarea-soarelui', 'bacanie', 'buc'),
('Ulei de măsline', 'ulei de masline', 'bacanie', 'buc'),
('Oțet', 'otet', 'bacanie', 'buc'),
('Sare', 'sare', 'bacanie', 'buc'),
('Piper', 'piper', 'bacanie', 'buc'),
('Zahăr', 'zahar', 'bacanie', 'buc'),
('Miere', 'miere', 'bacanie', 'buc'),
('Gem', 'gem', 'bacanie', 'buc'),
('Magiun', 'magiun', 'bacanie', 'buc'),
('Unt de arahide', 'unt de arahide', 'bacanie', 'buc'),
('Maioneză', 'maioneza', 'bacanie', 'buc'),
('Muștar', 'mustar', 'bacanie', 'buc'),
('Ketchup', 'ketchup', 'bacanie', 'buc'),
('Sos de soia', 'sos de soia', 'bacanie', 'buc'),
('Legume congelate', 'legume congelate', 'congelate', 'buc'),
('Amestec mexican congelat', 'amestec mexican congelat', 'congelate', 'buc'),
('Cartofi prăjiți congelați', 'cartofi prajiti congelati', 'congelate', 'buc'),
('Pizza congelată', 'pizza congelata', 'congelate', 'buc'),
('Aluat foietaj', 'aluat foietaj', 'congelate', 'buc'),
('Fructe de pădure congelate', 'fructe de padure congelate', 'congelate', 'buc'),
('Pește congelat', 'peste congelat', 'congelate', 'buc'),
('File de pește pane', 'file de peste pane', 'congelate', 'buc'),
('Înghețată', 'inghetata', 'congelate', 'buc'),
('Pâine congelată', 'paine congelata', 'congelate', 'buc'),
('Apă plată', 'apa plata', 'bauturi', 'l'),
('Apă minerală', 'apa minerala', 'bauturi', 'l'),
('Suc de portocale', 'suc de portocale', 'bauturi', 'l'),
('Suc de mere', 'suc de mere', 'bauturi', 'l'),
('Limonadă', 'limonada', 'bauturi', 'l'),
('Ceai', 'ceai', 'bauturi', 'l'),
('Cafea boabe', 'cafea boabe', 'bauturi', 'l'),
('Cafea măcinată', 'cafea macinata', 'bauturi', 'l'),
('Cafea instant', 'cafea instant', 'bauturi', 'l'),
('Cacao', 'cacao', 'bauturi', 'l'),
('Băutură vegetală de ovăz', 'bautura vegetala de ovaz', 'bauturi', 'l'),
('Băutură vegetală de soia', 'bautura vegetala de soia', 'bauturi', 'l'),
('Sirop', 'sirop', 'bauturi', 'l'),
('Compot', 'compot', 'bauturi', 'l'),
('Energizant', 'energizant', 'bauturi', 'l'),
('Detergent rufe', 'detergent rufe', 'menaj', 'buc'),
('Balsam de rufe', 'balsam de rufe', 'menaj', 'buc'),
('Detergent vase', 'detergent vase', 'menaj', 'buc'),
('Soluție geamuri', 'solutie geamuri', 'menaj', 'buc'),
('Soluție baie', 'solutie baie', 'menaj', 'buc'),
('Soluție pardoseli', 'solutie pardoseli', 'menaj', 'buc'),
('Dezinfectant suprafețe', 'dezinfectant suprafete', 'menaj', 'buc'),
('Bureți vase', 'bureti vase', 'menaj', 'buc'),
('Lavete', 'lavete', 'menaj', 'buc'),
('Prosoape hârtie', 'prosoape hartie', 'menaj', 'buc'),
('Hârtie igienică', 'hartie igienica', 'menaj', 'buc'),
('Șervețele', 'servetele', 'menaj', 'buc'),
('Saci menajeri', 'saci menajeri', 'menaj', 'buc'),
('Folie alimentară', 'folie alimentara', 'menaj', 'buc'),
('Folie aluminiu', 'folie aluminiu', 'menaj', 'buc'),
('Hârtie de copt', 'hartie de copt', 'menaj', 'buc'),
('Baterii', 'baterii', 'menaj', 'buc'),
('Becuri', 'becuri', 'menaj', 'buc'),
('Șampon', 'sampon', 'ingrijire', 'buc'),
('Balsam păr', 'balsam par', 'ingrijire', 'buc'),
('Gel de duș', 'gel de dus', 'ingrijire', 'buc'),
('Săpun lichid', 'sapun lichid', 'ingrijire', 'buc'),
('Săpun solid', 'sapun solid', 'ingrijire', 'buc'),
('Pastă de dinți', 'pasta de dinti', 'ingrijire', 'buc'),
('Periuță de dinți', 'periuta de dinti', 'ingrijire', 'buc'),
('Apă de gură', 'apa de gura', 'ingrijire', 'buc'),
('Deodorant', 'deodorant', 'ingrijire', 'buc'),
('Cremă de mâini', 'crema de maini', 'ingrijire', 'buc'),
('Cremă hidratantă', 'crema hidratanta', 'ingrijire', 'buc'),
('Lame de ras', 'lame de ras', 'ingrijire', 'buc'),
('Spumă de ras', 'spuma de ras', 'ingrijire', 'buc'),
('Dischete demachiante', 'dischete demachiante', 'ingrijire', 'buc'),
('Bețișoare igienice', 'betisoare igienice', 'ingrijire', 'buc'),
('Absorbante', 'absorbante', 'ingrijire', 'buc'),
('Scutece', 'scutece', 'ingrijire', 'buc'),
('Șervețele umede', 'servetele umede', 'ingrijire', 'buc'),
('Detergent intim', 'detergent intim', 'ingrijire', 'buc'),
('Hrană uscată pentru pisici', 'hrana uscata pentru pisici', 'ingrijire', 'buc'),
('Hrană umedă pentru pisici', 'hrana umeda pentru pisici', 'ingrijire', 'buc'),
('Hrană pentru câini', 'hrana pentru caini', 'ingrijire', 'buc')
on conflict (normalized_name) do update set
  name = excluded.name,
  category = excluded.category,
  package_unit = excluded.package_unit;
