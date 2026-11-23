-- Seed commonly used Romanian retail chains as global store choices.
insert into public.stores(name, is_system, is_active)
select v.name, true, true
from (values
  ('Kaufland'), ('Lidl'), ('Carrefour'), ('Auchan'), ('Mega Image'),
  ('Profi'), ('Penny'), ('Selgros'), ('METRO')
) as v(name)
where not exists (
  select 1 from public.stores s where s.is_system = true and lower(s.name) = lower(v.name)
);
