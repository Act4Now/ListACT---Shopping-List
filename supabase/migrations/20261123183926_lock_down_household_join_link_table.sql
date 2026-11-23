create policy household_join_links_no_direct_access
on public.household_join_links
for all to authenticated
using (false)
with check (false);
