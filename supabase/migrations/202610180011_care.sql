begin;

-- Care team: clinic connections, consented shares, one-way messages,
-- caregivers and supporters.
--
-- * public.care_orgs and public.care_invites are clinic reference data, with
--   no patient data and no client write path. An invite stores only the
--   SHA-256 of its code (code_hash, 32 bytes), never the code.
-- * A member connects to a clinic only through public.redeem_care_invite(code).
--   It refuses, in this order: no caller (42501); a sync service session
--   (TH010); account deletion started (TH006); a code that is malformed,
--   unknown, expired or used up, or whose clinic is not verified or is
--   disabled (TH025, one message for every case). A member who is already
--   connected to the code's clinic gets that live connection back, and no use
--   is consumed, even if the code has since expired or been used up.
-- * Every member table holds user_id and cascades from auth.users; programme
--   rows also cascade from their enrolment. Row-level security is enabled and
--   forced on all nine tables, every write policy refuses a sync service
--   session, and every insert policy requires the deletion barrier to be open.
--   Members may delete supporters only. Connections, shares and caregivers
--   are only ever revoked; access rows, messages and caregiver events are
--   append-only (TH023). Truncate is refused on the six member tables that
--   keep that history, whatever the role (TH024).
-- * A share needs a live share_care_team consent that names its connection,
--   on the share's own enrolment. A caregiver event needs a live
--   share_caregiver consent that names its caregiver. The insert triggers
--   lock and re-check that consent and its connection or caregiver (TH022).
-- * A new share_care_team or share_caregiver consent must name, by its
--   lowercase id, a live connection, or a live caregiver of the same
--   enrolment, owned by the enrolment's member (TH021). A consent without a
--   recipient is still refused by the existing check constraint.
-- * Revoking a share consent revokes its shares; revoking a connection revokes
--   the consents that name it and its shares; revoking a caregiver revokes
--   the consents that name it. Revoking core, leaving and supersession reach
--   shares through the consents they revoke.
-- * Supporters list only the caller's bf and sf programmes that are not left.
--   Leaving or deleting a programme removes its code from the member's
--   supporters.
-- * Every live share consent stored before this migration is revoked (none
--   can name a recipient that exists). Rows are kept as history.
-- * delete_my_app_data also deletes and counts the seven member care tables.
--   Its owner, privileges and comment are unchanged.
-- * Shares expire at most 30 days after they are created (the default).
-- * No table here references the consent, consent document or sync tables, so
--   a plain truncate of those tables still reaches its guard. No foreign key
--   sets null or a default, because that would update revoke-only and
--   append-only rows; an invite a connection used cannot be deleted.

-- Tables -----------------------------------------------------------------------

create table public.care_orgs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  contact_email text null,
  verified_at timestamptz null,
  disabled_at timestamptz null,
  created_at timestamptz not null default now(),
  constraint care_orgs_name_check check (
    name = btrim(name) and char_length(name) between 1 and 120
  ),
  constraint care_orgs_contact_email_check check (
    contact_email is null or (
      char_length(contact_email) <= 254 and contact_email ~ '^[^@]+@[^@]+$'
    )
  )
);

comment on table public.care_orgs is
  'Clinics (reference data, no patient data). No client write path.';

create table public.care_invites (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.care_orgs(id) on delete cascade,
  code_hash bytea not null,
  expires_at timestamptz not null,
  max_uses integer not null default 1,
  uses integer not null default 0,
  created_by text not null,
  created_at timestamptz not null default now(),
  constraint care_invites_code_hash_key unique (code_hash),
  constraint care_invites_code_hash_check check (octet_length(code_hash) = 32),
  constraint care_invites_expires_check check (expires_at > created_at),
  constraint care_invites_max_uses_check check (max_uses between 1 and 10000),
  constraint care_invites_uses_check check (uses between 0 and max_uses),
  constraint care_invites_created_by_check check (
    char_length(created_by) between 1 and 120
  )
);

comment on table public.care_invites is
  'Clinic invite codes, stored only as the SHA-256 of the normalised code. created_by is an operator reference, never a patient value.';

create table public.care_connections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  org_id uuid not null references public.care_orgs(id),
  invite_id uuid null references public.care_invites(id),
  connected_at timestamptz not null default now(),
  revoked_at timestamptz null,
  created_at timestamptz not null default now(),
  constraint care_connections_revoked_check check (
    revoked_at is null or revoked_at >= connected_at
  )
);

create unique index care_connections_live_key
on public.care_connections (user_id, org_id)
where revoked_at is null;

comment on table public.care_connections is
  'A member''s connection to a clinic, created only by redeem_care_invite. Revoke-only.';

create table public.care_shares (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  enrolment_id uuid not null references public.enrolments(id) on delete cascade,
  connection_id uuid not null references public.care_connections(id) on delete cascade,
  consent_id uuid not null,
  kind text not null,
  snapshot jsonb not null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '30 days',
  revoked_at timestamptz null,
  constraint care_shares_kind_check check (
    kind in ('visit_summary', 'message_attachment')
  ),
  constraint care_shares_snapshot_check check (
    jsonb_typeof(snapshot) = 'object' and octet_length(snapshot::text) <= 65536
  ),
  constraint care_shares_expires_check check (
    expires_at > created_at and expires_at <= created_at + interval '30 days'
  ),
  constraint care_shares_revoked_check check (
    revoked_at is null or revoked_at >= created_at
  )
);

create index care_shares_user_idx on public.care_shares (user_id);
create index care_shares_enrolment_idx on public.care_shares (enrolment_id);
create index care_shares_connection_idx on public.care_shares (connection_id);
create index care_shares_consent_idx on public.care_shares (consent_id);

comment on table public.care_shares is
  'The exact content a member approved to share with a connected clinic, under a live share_care_team consent on the same enrolment. Expires at most 30 days after creation. Revoke-only.';
comment on column public.care_shares.consent_id is
  'The share_care_team consent the share was created under, checked and locked on insert. Not a foreign key, so the consent tables stay unreferenced. Shares are deleted with their enrolment, and before consents in delete_my_app_data.';

create table public.care_share_access (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  share_id uuid not null references public.care_shares(id) on delete cascade,
  accessed_at timestamptz not null default now(),
  channel text not null,
  created_at timestamptz not null default now(),
  constraint care_share_access_channel_check check (channel in ('secure_link'))
);

comment on table public.care_share_access is
  'When a share was opened, and through which channel. No content and no viewer identity. Append-only.';

create table public.care_messages (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  connection_id uuid not null references public.care_connections(id) on delete cascade,
  enrolment_id uuid null references public.enrolments(id) on delete cascade,
  topic text not null,
  body text not null,
  share_id uuid null references public.care_shares(id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint care_messages_topic_check check (char_length(topic) between 1 and 80),
  constraint care_messages_body_check check (char_length(body) between 1 and 2000),
  constraint care_messages_share_enrolment_check check (
    share_id is null or enrolment_id is not null
  )
);

comment on table public.care_messages is
  'One-way messages from a member to a connected clinic. A message with an attached share belongs to the share''s programme and is deleted with it. Append-only.';

create table public.caregivers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  enrolment_id uuid not null references public.enrolments(id) on delete cascade,
  name text not null,
  phone text not null,
  scope text[] not null default '{sd.session_finished,sd.fall_logged}',
  invite_status text not null default 'pending',
  created_at timestamptz not null default now(),
  revoked_at timestamptz null,
  constraint caregivers_name_check check (
    name = btrim(name) and char_length(name) between 1 and 80
  ),
  constraint caregivers_phone_check check (phone ~ '^\+[1-9][0-9]{6,14}$'),
  constraint caregivers_scope_check check (
    cardinality(scope) >= 1 and
    array_position(scope, null) is null and
    public.is_unique_text_array(scope) and
    scope <@ array['sd.session_finished', 'sd.fall_logged']::text[]
  ),
  constraint caregivers_invite_status_check check (
    invite_status in ('pending', 'sent')
  ),
  constraint caregivers_revoked_check check (
    revoked_at is null or revoked_at >= created_at
  )
);

comment on table public.caregivers is
  'A caregiver of a Stride enrolment, who may see only the event kinds in scope. Revoke-only; invite_status may move from pending to sent while live.';

create table public.caregiver_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  caregiver_id uuid not null references public.caregivers(id) on delete cascade,
  kind text not null,
  occurred_at timestamptz not null,
  created_at timestamptz not null default now(),
  constraint caregiver_events_kind_check check (
    kind in ('sd.session_finished', 'sd.fall_logged')
  )
);

comment on table public.caregiver_events is
  'The only records a caregiver can ever see. Append-only.';

create table public.supporters (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  phone text not null,
  programme_codes text[] not null default '{}',
  help_phrase text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint supporters_name_check check (
    name = btrim(name) and char_length(name) between 1 and 80
  ),
  constraint supporters_phone_check check (phone ~ '^\+[1-9][0-9]{6,14}$'),
  constraint supporters_programme_codes_check check (
    array_position(programme_codes, null) is null and
    public.is_unique_text_array(programme_codes) and
    programme_codes <@ array['bf', 'sf']::text[]
  ),
  constraint supporters_help_phrase_check check (
    help_phrase is null or char_length(help_phrase) between 1 and 200
  )
);

comment on table public.supporters is
  'People a member may contact themselves. Tether never contacts them. programme_codes lists only the member''s bf and sf programmes that are not left.';

create trigger supporters_set_updated_at
before update on public.supporters
for each row execute function public.set_updated_at();

-- Consent recipients -------------------------------------------------------------

-- A share consent names, by its lowercase id, a live connection (share_care_team)
-- or a live caregiver of the same enrolment (share_caregiver), owned by the
-- enrolment's member. The row is locked, so a concurrent revoke either waits
-- for this insert or is seen by it.
create function public.care_check_consent_recipient()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  member_id uuid;
  recipient_id uuid;
begin
  if new.recipient_ref ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    select e.user_id
    into member_id
    from public.enrolments as e
    where e.id = new.enrolment_id;

    if new.purpose = 'share_care_team' then
      select c.id
      into recipient_id
      from public.care_connections as c
      where c.id = new.recipient_ref::uuid
        and c.user_id = member_id
        and c.revoked_at is null
      for share;
    elsif new.purpose = 'share_caregiver' then
      select g.id
      into recipient_id
      from public.caregivers as g
      where g.id = new.recipient_ref::uuid
        and g.enrolment_id = new.enrolment_id
        and g.user_id = member_id
        and g.revoked_at is null
      for share;
    end if;
  end if;

  if recipient_id is null then
    raise exception using errcode = 'TH021',
      message = 'A sharing consent must name a live connection or caregiver of the same member',
      hint = 'consent_recipient_invalid';
  end if;
  return new;
end;
$$;

revoke all on function public.care_check_consent_recipient()
from public, anon, authenticated, service_role;

create trigger programme_consents_check_recipient
before insert on public.programme_consents
for each row
when (
  new.purpose in ('share_care_team', 'share_caregiver')
  and new.recipient_ref is not null
)
execute function public.care_check_consent_recipient();

-- A share locks and re-checks its consent and connection; a caregiver event
-- locks and re-checks its caregiver and the consent that names it.
create function public.care_lock_live_consent()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
declare
  live_consent_id uuid;
  live_parent_id uuid;
  caregiver_enrolment_id uuid;
begin
  if tg_table_name = 'care_shares' then
    select c.id
    into live_consent_id
    from public.programme_consents as c
    where c.id = new.consent_id
      and c.purpose = 'share_care_team'
      and c.enrolment_id = new.enrolment_id
      and c.recipient_ref = new.connection_id::text
      and c.revoked_at is null
    for share;

    select k.id
    into live_parent_id
    from public.care_connections as k
    where k.id = new.connection_id
      and k.revoked_at is null
    for share;
  elsif tg_table_name = 'caregiver_events' then
    select g.id, g.enrolment_id
    into live_parent_id, caregiver_enrolment_id
    from public.caregivers as g
    where g.id = new.caregiver_id
      and g.revoked_at is null
    for share;

    select c.id
    into live_consent_id
    from public.programme_consents as c
    where c.enrolment_id = caregiver_enrolment_id
      and c.purpose = 'share_caregiver'
      and c.recipient_ref = new.caregiver_id::text
      and c.revoked_at is null
    for share;
  end if;

  if live_consent_id is null or live_parent_id is null then
    raise exception using errcode = 'TH022',
      message = 'A live sharing consent for this recipient is required',
      hint = 'care_consent_required';
  end if;
  return new;
end;
$$;

revoke all on function public.care_lock_live_consent()
from public, anon, authenticated, service_role;

create trigger care_shares_lock_consent
before insert on public.care_shares
for each row execute function public.care_lock_live_consent();

create trigger caregiver_events_lock_consent
before insert on public.caregiver_events
for each row execute function public.care_lock_live_consent();

-- Revoke-only and append-only ------------------------------------------------------

-- Only revoked_at may change, once, from null to the server time (for
-- caregivers also invite_status, from pending to sent while live).
create function public.care_revoke_only()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  ignored text[] := array['revoked_at'];
begin
  if old.revoked_at is not null then
    raise exception using errcode = 'TH023',
      message = 'Care records can only be revoked',
      hint = 'care_record_immutable';
  end if;
  if tg_nargs > 0 and tg_argv[0] = 'invite_status' then
    if (to_jsonb(new) ->> 'invite_status') is distinct from (to_jsonb(old) ->> 'invite_status')
       and not ((to_jsonb(old) ->> 'invite_status') = 'pending'
                and (to_jsonb(new) ->> 'invite_status') = 'sent') then
      raise exception using errcode = 'TH023',
        message = 'Care records can only be revoked',
        hint = 'care_record_immutable';
    end if;
    ignored := ignored || array['invite_status'];
  end if;
  if (to_jsonb(new) - ignored) is distinct from (to_jsonb(old) - ignored) then
    raise exception using errcode = 'TH023',
      message = 'Care records can only be revoked',
      hint = 'care_record_immutable';
  end if;
  if new.revoked_at is not null then
    new.revoked_at = greatest(
      clock_timestamp(),
      (to_jsonb(old) ->> 'created_at')::timestamptz,
      (to_jsonb(old) ->> 'connected_at')::timestamptz
    );
  end if;
  return new;
end;
$$;

revoke all on function public.care_revoke_only()
from public, anon, authenticated, service_role;

create trigger care_connections_revoke_only
before update on public.care_connections
for each row execute function public.care_revoke_only();

create trigger care_shares_revoke_only
before update on public.care_shares
for each row execute function public.care_revoke_only();

create trigger caregivers_revoke_only
before update on public.caregivers
for each row execute function public.care_revoke_only('invite_status');

create function public.care_append_only()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception using errcode = 'TH023',
    message = 'Care records can only be revoked',
    hint = 'care_record_immutable';
end;
$$;

revoke all on function public.care_append_only()
from public, anon, authenticated, service_role;

create trigger care_share_access_append_only
before update on public.care_share_access
for each row execute function public.care_append_only();

create trigger care_messages_append_only
before update on public.care_messages
for each row execute function public.care_append_only();

create trigger caregiver_events_append_only
before update on public.caregiver_events
for each row execute function public.care_append_only();

-- Revocation cascades ----------------------------------------------------------------

create function public.programme_consents_revoke_care_shares()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  update public.care_shares
  set revoked_at = now()
  where consent_id = new.id
    and revoked_at is null;
  return null;
end;
$$;

revoke all on function public.programme_consents_revoke_care_shares()
from public, anon, authenticated, service_role;

create trigger programme_consents_revoke_care_shares
after update of revoked_at on public.programme_consents
for each row
when (
  old.purpose = 'share_care_team' and old.revoked_at is null
  and new.revoked_at is not null
)
execute function public.programme_consents_revoke_care_shares();

create function public.care_connections_revoke_cascade()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  update public.programme_consents
  set revoked_at = now()
  where purpose = 'share_care_team'
    and recipient_ref = old.id::text
    and revoked_at is null;
  update public.care_shares
  set revoked_at = now()
  where connection_id = old.id
    and revoked_at is null;
  return null;
end;
$$;

revoke all on function public.care_connections_revoke_cascade()
from public, anon, authenticated, service_role;

create trigger care_connections_revoke_cascade
after update of revoked_at on public.care_connections
for each row
when (old.revoked_at is null and new.revoked_at is not null)
execute function public.care_connections_revoke_cascade();

create function public.caregivers_revoke_cascade()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  update public.programme_consents
  set revoked_at = now()
  where purpose = 'share_caregiver'
    and enrolment_id = old.enrolment_id
    and recipient_ref = old.id::text
    and revoked_at is null;
  return null;
end;
$$;

revoke all on function public.caregivers_revoke_cascade()
from public, anon, authenticated, service_role;

create trigger caregivers_revoke_cascade
after update of revoked_at on public.caregivers
for each row
when (old.revoked_at is null and new.revoked_at is not null)
execute function public.caregivers_revoke_cascade();

-- Supporter programme codes ----------------------------------------------------------

-- Leaving or deleting a programme removes its code from the member's
-- supporters. Runs as the owner, so a cascaded enrolment delete by any role
-- (for example an identity delete) is not refused here; it touches only the
-- supporters of the trigger row's member.
create function public.supporters_drop_programme()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'DELETE' then
    update public.supporters
    set programme_codes = array_remove(programme_codes, old.programme_code)
    where user_id = old.user_id
      and old.programme_code = any (programme_codes);
  else
    update public.supporters
    set programme_codes = array_remove(programme_codes, new.programme_code)
    where user_id = new.user_id
      and new.programme_code = any (programme_codes);
  end if;
  return null;
end;
$$;

revoke all on function public.supporters_drop_programme()
from public, anon, authenticated, service_role;

create trigger enrolments_drop_supporter_programme
after update of status on public.enrolments
for each row
when (new.status = 'left' and old.status is distinct from 'left')
execute function public.supporters_drop_programme();

create trigger enrolments_drop_supporter_programme_on_delete
after delete on public.enrolments
for each row execute function public.supporters_drop_programme();

-- Row-level security, policies and grants ------------------------------------------

alter table public.care_orgs enable row level security;
alter table public.care_orgs force row level security;
alter table public.care_invites enable row level security;
alter table public.care_invites force row level security;
alter table public.care_connections enable row level security;
alter table public.care_connections force row level security;
alter table public.care_shares enable row level security;
alter table public.care_shares force row level security;
alter table public.care_share_access enable row level security;
alter table public.care_share_access force row level security;
alter table public.care_messages enable row level security;
alter table public.care_messages force row level security;
alter table public.caregivers enable row level security;
alter table public.caregivers force row level security;
alter table public.caregiver_events enable row level security;
alter table public.caregiver_events force row level security;
alter table public.supporters enable row level security;
alter table public.supporters force row level security;

revoke all on table public.care_orgs from public, anon, authenticated, service_role;
revoke all on table public.care_invites from public, anon, authenticated, service_role;
revoke all on table public.care_connections from public, anon, authenticated, service_role;
revoke all on table public.care_shares from public, anon, authenticated, service_role;
revoke all on table public.care_share_access from public, anon, authenticated, service_role;
revoke all on table public.care_messages from public, anon, authenticated, service_role;
revoke all on table public.caregivers from public, anon, authenticated, service_role;
revoke all on table public.caregiver_events from public, anon, authenticated, service_role;
revoke all on table public.supporters from public, anon, authenticated, service_role;

-- Clinics: a member sees the id and name of clinics they are or were
-- connected to. Invites have no client path at all.
create policy "care_orgs_select_connected"
on public.care_orgs for select
to authenticated
using (
  exists (
    select 1
    from public.care_connections as c
    where c.org_id = care_orgs.id
      and c.user_id = (select auth.uid())
  )
);

grant select (id, name) on table public.care_orgs to authenticated;

-- Connections: created only by redeem_care_invite; members read and revoke.
create policy "care_connections_select_own"
on public.care_connections for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "care_connections_update_own"
on public.care_connections for update
to authenticated
using ((select auth.uid()) = user_id and not public.sync_writer_session())
with check ((select auth.uid()) = user_id and not public.sync_writer_session());

grant select on table public.care_connections to authenticated;
grant update (revoked_at) on table public.care_connections to authenticated;

-- Shares.
create policy "care_shares_select_own"
on public.care_shares for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "care_shares_insert_own"
on public.care_shares for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  exists (
    select 1
    from public.enrolments as e
    where e.id = care_shares.enrolment_id
      and e.user_id = (select auth.uid())
      and e.status <> 'left'
  ) and
  exists (
    select 1
    from public.care_connections as c
    where c.id = care_shares.connection_id
      and c.user_id = (select auth.uid())
      and c.revoked_at is null
  ) and
  public.has_consent(care_shares.enrolment_id, 'share_care_team', care_shares.connection_id::text) and
  public.deletion_barrier_open() and
  not public.sync_writer_session()
);

create policy "care_shares_update_own"
on public.care_shares for update
to authenticated
using ((select auth.uid()) = user_id and not public.sync_writer_session())
with check ((select auth.uid()) = user_id and not public.sync_writer_session());

grant select on table public.care_shares to authenticated;
grant insert (user_id, enrolment_id, connection_id, consent_id, kind, snapshot, expires_at)
on table public.care_shares to authenticated;
grant update (revoked_at) on table public.care_shares to authenticated;

-- Share access log: read only (no client writer).
create policy "care_share_access_select_own"
on public.care_share_access for select
to authenticated
using ((select auth.uid()) = user_id);

grant select on table public.care_share_access to authenticated;

-- Messages.
create policy "care_messages_select_own"
on public.care_messages for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "care_messages_insert_own"
on public.care_messages for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  exists (
    select 1
    from public.care_connections as c
    where c.id = care_messages.connection_id
      and c.user_id = (select auth.uid())
      and c.revoked_at is null
  ) and (
    care_messages.enrolment_id is null or (
      exists (
        select 1
        from public.enrolments as e
        where e.id = care_messages.enrolment_id
          and e.user_id = (select auth.uid())
          and e.status <> 'left'
      ) and
      public.has_consent(care_messages.enrolment_id, 'share_care_team', care_messages.connection_id::text)
    )
  ) and (
    care_messages.share_id is null or exists (
      select 1
      from public.care_shares as s
      where s.id = care_messages.share_id
        and s.user_id = (select auth.uid())
        and s.connection_id = care_messages.connection_id
        and s.enrolment_id = care_messages.enrolment_id
        and s.kind = 'message_attachment'
        and s.revoked_at is null
        and s.expires_at > now()
    )
  ) and
  public.deletion_barrier_open() and
  not public.sync_writer_session()
);

grant select on table public.care_messages to authenticated;
grant insert (user_id, connection_id, enrolment_id, topic, body, share_id)
on table public.care_messages to authenticated;

-- Caregivers: on the member's own Stride enrolment.
create policy "caregivers_select_own"
on public.caregivers for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "caregivers_insert_own"
on public.caregivers for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  exists (
    select 1
    from public.enrolments as e
    where e.id = caregivers.enrolment_id
      and e.user_id = (select auth.uid())
      and e.programme_code = 'sd'
      and e.status <> 'left'
  ) and
  public.deletion_barrier_open() and
  not public.sync_writer_session()
);

create policy "caregivers_update_own"
on public.caregivers for update
to authenticated
using ((select auth.uid()) = user_id and not public.sync_writer_session())
with check ((select auth.uid()) = user_id and not public.sync_writer_session());

grant select on table public.caregivers to authenticated;
grant insert (user_id, enrolment_id, name, phone, scope)
on table public.caregivers to authenticated;
grant update (invite_status, revoked_at) on table public.caregivers to authenticated;

-- Caregiver events: for a live caregiver, in scope, with its live consent.
create policy "caregiver_events_select_own"
on public.caregiver_events for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "caregiver_events_insert_own"
on public.caregiver_events for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  exists (
    select 1
    from public.caregivers as g
    where g.id = caregiver_events.caregiver_id
      and g.user_id = (select auth.uid())
      and g.revoked_at is null
      and caregiver_events.kind = any (g.scope)
      and public.has_consent(g.enrolment_id, 'share_caregiver', g.id::text)
  ) and
  public.deletion_barrier_open() and
  not public.sync_writer_session()
);

grant select on table public.caregiver_events to authenticated;
grant insert (user_id, caregiver_id, kind, occurred_at)
on table public.caregiver_events to authenticated;

-- Supporters: programme codes only of the caller's bf and sf programmes that
-- are not left.
create policy "supporters_select_own"
on public.supporters for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "supporters_insert_own"
on public.supporters for insert
to authenticated
with check (
  (select auth.uid()) = user_id and
  supporters.programme_codes <@ array(
    select e.programme_code
    from public.enrolments as e
    where e.user_id = (select auth.uid())
      and e.programme_code in ('bf', 'sf')
      and e.status <> 'left'
  ) and
  public.deletion_barrier_open() and
  not public.sync_writer_session()
);

create policy "supporters_update_own"
on public.supporters for update
to authenticated
using ((select auth.uid()) = user_id and not public.sync_writer_session())
with check (
  (select auth.uid()) = user_id and
  supporters.programme_codes <@ array(
    select e.programme_code
    from public.enrolments as e
    where e.user_id = (select auth.uid())
      and e.programme_code in ('bf', 'sf')
      and e.status <> 'left'
  ) and
  not public.sync_writer_session()
);

create policy "supporters_delete_own"
on public.supporters for delete
to authenticated
using ((select auth.uid()) = user_id and not public.sync_writer_session());

grant select, delete on table public.supporters to authenticated;
grant insert (user_id, name, phone, programme_codes, help_phrase)
on table public.supporters to authenticated;
grant update (name, phone, programme_codes, help_phrase)
on table public.supporters to authenticated;

-- Truncate guards ------------------------------------------------------------------

create function public.care_truncate_guard()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  raise exception using errcode = 'TH024',
    message = 'Care rows are removed only with their programme or account',
    hint = 'care_rows_delete_only';
end;
$$;

revoke all on function public.care_truncate_guard()
from public, anon, authenticated, service_role;

create trigger care_connections_truncate_guard
before truncate on public.care_connections
for each statement execute function public.care_truncate_guard();

create trigger care_shares_truncate_guard
before truncate on public.care_shares
for each statement execute function public.care_truncate_guard();

create trigger care_share_access_truncate_guard
before truncate on public.care_share_access
for each statement execute function public.care_truncate_guard();

create trigger care_messages_truncate_guard
before truncate on public.care_messages
for each statement execute function public.care_truncate_guard();

create trigger caregivers_truncate_guard
before truncate on public.caregivers
for each statement execute function public.care_truncate_guard();

create trigger caregiver_events_truncate_guard
before truncate on public.caregiver_events
for each statement execute function public.care_truncate_guard();

alter table public.care_connections
enable always trigger care_connections_truncate_guard;
alter table public.care_shares
enable always trigger care_shares_truncate_guard;
alter table public.care_share_access
enable always trigger care_share_access_truncate_guard;
alter table public.care_messages
enable always trigger care_messages_truncate_guard;
alter table public.caregivers
enable always trigger caregivers_truncate_guard;
alter table public.caregiver_events
enable always trigger caregiver_events_truncate_guard;

revoke truncate on public.care_connections, public.care_shares, public.care_share_access,
  public.care_messages, public.caregivers, public.caregiver_events
from public, anon, authenticated, thsync;

-- Invite redemption -------------------------------------------------------------------

create function public.redeem_care_invite(p_code text)
returns public.care_connections
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  normalised text;
  invite public.care_invites;
  clinic public.care_orgs;
  connection public.care_connections;
begin
  if caller_id is null then
    raise insufficient_privilege using message = 'Authentication required';
  end if;
  if public.sync_writer_session() then
    raise exception using errcode = 'TH010',
      message = 'The sync service writes only sync tables',
      hint = 'sync_session_refused';
  end if;
  if not public.deletion_barrier_open() then
    raise exception using errcode = 'TH006',
      message = 'Account deletion has started',
      hint = 'deletion_in_progress';
  end if;

  normalised := upper(regexp_replace(coalesce(p_code, ''), '[[:space:]-]', '', 'g'));
  if char_length(normalised) < 12 or char_length(normalised) > 64 then
    raise exception using errcode = 'TH025',
      message = 'Invite code is not valid',
      hint = 'care_invite_invalid';
  end if;

  select i.*
  into invite
  from public.care_invites as i
  where i.code_hash = pg_catalog.sha256(convert_to(normalised, 'UTF8'))
  for update;

  if invite.id is not null then
    select o.*
    into clinic
    from public.care_orgs as o
    where o.id = invite.org_id;
  end if;

  if invite.id is null
     or clinic.id is null
     or clinic.verified_at is null
     or clinic.disabled_at is not null then
    raise exception using errcode = 'TH025',
      message = 'Invite code is not valid',
      hint = 'care_invite_invalid';
  end if;

  -- Already connected to this clinic: return that connection and use nothing.
  select c.*
  into connection
  from public.care_connections as c
  where c.user_id = caller_id
    and c.org_id = invite.org_id
    and c.revoked_at is null;
  if connection.id is not null then
    return connection;
  end if;

  if invite.expires_at <= now() or invite.uses >= invite.max_uses then
    raise exception using errcode = 'TH025',
      message = 'Invite code is not valid',
      hint = 'care_invite_invalid';
  end if;

  update public.care_invites
  set uses = uses + 1
  where id = invite.id;

  insert into public.care_connections (user_id, org_id, invite_id)
  values (caller_id, invite.org_id, invite.id)
  returning * into connection;
  return connection;
end;
$$;

revoke all on function public.redeem_care_invite(text)
from public, anon, authenticated, service_role;
grant execute on function public.redeem_care_invite(text) to authenticated;

-- Account deletion ----------------------------------------------------------------
-- delete_my_app_data also deletes and counts the member care tables, children
-- first, before the consents they reference. Everything else is unchanged; its
-- owner, privileges and comment are kept.
create or replace function public.delete_my_app_data(p_confirmation text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  deleted_profiles integer := 0;
  deleted_quit_plans integer := 0;
  deleted_program_data integer := 0;
  deleted_enrolments integer := 0;
  deleted_programme_consents integer := 0;
  deleted_account_consents integer := 0;
  deleted_sync_answers integer := 0;
  deleted_sync_lapses integer := 0;
  deleted_sync_areas integer := 0;
  deleted_sync_accounts integer := 0;
  deleted_care_share_access integer := 0;
  deleted_care_messages integer := 0;
  deleted_care_shares integer := 0;
  deleted_caregiver_events integer := 0;
  deleted_caregivers integer := 0;
  deleted_care_connections integer := 0;
  deleted_supporters integer := 0;
begin
  if caller_id is null then
    raise insufficient_privilege using message = 'Authentication required';
  end if;
  if public.sync_writer_session() then
    raise exception using errcode = 'TH009',
      message = 'Account deletion goes through the API',
      hint = 'deletion_via_api_only';
  end if;
  if p_confirmation is distinct from 'DELETE' then
    raise check_violation using message = 'Explicit confirmation required';
  end if;
  if exists (
    select 1
    from public.profiles
    where id = caller_id and account_deletion_started_at is null
  ) then
    raise check_violation using message = 'Account deletion was not started';
  end if;

  delete from public.sync_lapse where user_id = caller_id;
  get diagnostics deleted_sync_lapses = row_count;
  delete from public.sync_answer where user_id = caller_id;
  get diagnostics deleted_sync_answers = row_count;
  delete from public.sync_area where user_id = caller_id;
  get diagnostics deleted_sync_areas = row_count;
  delete from public.sync_account where user_id = caller_id;
  get diagnostics deleted_sync_accounts = row_count;
  delete from public.care_share_access where user_id = caller_id;
  get diagnostics deleted_care_share_access = row_count;
  delete from public.care_messages where user_id = caller_id;
  get diagnostics deleted_care_messages = row_count;
  delete from public.care_shares where user_id = caller_id;
  get diagnostics deleted_care_shares = row_count;
  delete from public.caregiver_events where user_id = caller_id;
  get diagnostics deleted_caregiver_events = row_count;
  delete from public.caregivers where user_id = caller_id;
  get diagnostics deleted_caregivers = row_count;
  delete from public.care_connections where user_id = caller_id;
  get diagnostics deleted_care_connections = row_count;
  delete from public.supporters where user_id = caller_id;
  get diagnostics deleted_supporters = row_count;
  delete from public.programme_consents
  where enrolment_id in (
    select id from public.enrolments where user_id = caller_id
  );
  get diagnostics deleted_programme_consents = row_count;
  delete from public.enrolments where user_id = caller_id;
  get diagnostics deleted_enrolments = row_count;
  delete from public.account_consents where user_id = caller_id;
  get diagnostics deleted_account_consents = row_count;
  delete from public.program_data where user_id = caller_id;
  get diagnostics deleted_program_data = row_count;
  delete from public.quit_plans where user_id = caller_id;
  get diagnostics deleted_quit_plans = row_count;
  delete from public.profiles where id = caller_id;
  get diagnostics deleted_profiles = row_count;

  return jsonb_build_object(
    'profiles', deleted_profiles,
    'quit_plans', deleted_quit_plans,
    'program_data', deleted_program_data,
    'enrolments', deleted_enrolments,
    'programme_consents', deleted_programme_consents,
    'account_consents', deleted_account_consents,
    'sync_answers', deleted_sync_answers,
    'sync_lapses', deleted_sync_lapses,
    'sync_areas', deleted_sync_areas,
    'sync_accounts', deleted_sync_accounts,
    'care_share_access', deleted_care_share_access,
    'care_messages', deleted_care_messages,
    'care_shares', deleted_care_shares,
    'caregiver_events', deleted_caregiver_events,
    'caregivers', deleted_caregivers,
    'care_connections', deleted_care_connections,
    'supporters', deleted_supporters
  );
end;
$$;

-- Share consents stored before this migration ------------------------------------
-- None can name a connection or caregiver, so every live one is revoked (kept
-- as history). The update must see every row, so the migration role has to
-- bypass row-level security; otherwise it would revoke nothing and pass.
-- TH-955 legacy share consents: begin
do $$
begin
  if not exists (
    select 1 from pg_catalog.pg_roles as r
    where r.rolname = current_user and (r.rolsuper or r.rolbypassrls)
  ) then
    raise exception 'Revoking stored share consents needs a migration role that bypasses row-level security';
  end if;

  update public.programme_consents
  set revoked_at = now()
  where purpose in ('share_care_team', 'share_caregiver')
    and revoked_at is null;

  if exists (
    select 1 from public.programme_consents
    where purpose in ('share_care_team', 'share_caregiver')
      and revoked_at is null
  ) then
    raise exception 'Live share consents remain after the revocation';
  end if;
end;
$$;
-- TH-955 legacy share consents: end

commit;
