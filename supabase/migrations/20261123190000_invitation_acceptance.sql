-- Secure invitation acceptance: the raw token is never stored in the database.
create or replace function public.accept_household_invitation(p_token text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_invitation public.household_invitations;
  v_email text;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_token is null or length(p_token) < 32 then raise exception 'Invalid invitation token'; end if;
  v_email := lower(coalesce(auth.jwt() ->> 'email', ''));
  select * into v_invitation
    from public.household_invitations i
    where i.token_hash = encode(sha256(convert_to(p_token, 'UTF8')), 'hex')
      and i.accepted_at is null
      and i.expires_at > now()
      and lower(i.email) = v_email
    limit 1
    for update;
  if not found then raise exception 'Invitation is invalid, expired, already used, or for another email'; end if;
  insert into public.household_members(household_id, user_id, role)
    values (v_invitation.household_id, auth.uid(), 'member')
    on conflict (household_id, user_id) do nothing;
  update public.household_invitations set accepted_at = now() where id = v_invitation.id;
  return v_invitation.household_id;
end;
$$;
revoke all on function public.accept_household_invitation(text) from public, anon;
grant execute on function public.accept_household_invitation(text) to authenticated;
