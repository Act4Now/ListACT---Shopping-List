create table if not exists public.household_join_links (
  household_id uuid primary key references public.households(id) on delete cascade,
  token_hash text not null unique,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  revoked_at timestamptz
);
alter table public.household_join_links enable row level security;

create or replace function public.create_household_join_link(p_household_id uuid, p_token text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_token is null or length(p_token) <> 64 or p_token !~ '^[0-9a-f]{64}$' then
    raise exception 'Invalid join token';
  end if;
  if not exists (
    select 1 from public.household_members m
    where m.household_id = p_household_id and m.user_id = auth.uid() and m.role = 'owner'
  ) then raise exception 'Only a household owner can create a join link'; end if;
  insert into public.household_join_links(household_id, token_hash, created_by, created_at, revoked_at)
  values (p_household_id, encode(sha256(convert_to(p_token, 'UTF8')), 'hex'), auth.uid(), now(), null)
  on conflict (household_id) do update
    set token_hash = excluded.token_hash, created_by = excluded.created_by, created_at = now(), revoked_at = null;
end;
$$;

create or replace function public.accept_household_join_link(p_household_id uuid, p_token text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_token is null or length(p_token) <> 64 or p_token !~ '^[0-9a-f]{64}$' then
    raise exception 'Invalid join token';
  end if;
  perform 1 from public.household_join_links l
  where l.household_id = p_household_id
    and l.token_hash = encode(sha256(convert_to(p_token, 'UTF8')), 'hex')
    and l.revoked_at is null
  for update;
  if not found then raise exception 'Invalid or revoked household link'; end if;
  insert into public.household_members(household_id, user_id, role)
  values (p_household_id, auth.uid(), 'member')
  on conflict (household_id, user_id) do nothing;
  return p_household_id;
end;
$$;

revoke all on function public.create_household_join_link(uuid, text) from public, anon;
revoke all on function public.accept_household_join_link(uuid, text) from public, anon;
grant execute on function public.create_household_join_link(uuid, text) to authenticated;
grant execute on function public.accept_household_join_link(uuid, text) to authenticated;
