#!/usr/bin/env bash
# Checks the care-team schema: nine tables with forced row-level security,
# consent-bound shares and caregiver events, the recipient check on sharing
# consents, revoke-only and append-only rows, truncate guards, invite
# redemption, supporters, the revocation of stored sharing consents, and
# delete_my_app_data counting the member care tables.
#
#   bash supabase/tests/verify_care_migration.sh   static checks
#   VERIFY_DB_URL=postgresql://...@127.0.0.1:54322/... bash <this script>
#       static checks, then the SQL test and the control against an
#       already-migrated LOCAL database (psql). Any host other than 127.0.0.1
#       or localhost is refused. The SQL test switches the session user to
#       thsync and authenticator and creates test roles, so the URL's user
#       must be a superuser.
#   bash <this script> --print-sql            print the SQL test
#   bash <this script> --print-control-sql    print the control: as
#       authenticated, a synthetic member with a live core consent grants a
#       share_care_team consent whose recipient names nothing, and it reports:
#         TH955_CONTROL_UNBOUND_RECIPIENT_REFUSED   (expected with the
#             migration: TH021)
#         TH955_CONTROL_UNBOUND_RECIPIENT_ACCEPTED  (a tree without the
#             migration: the consent is stored; no care table is touched)
#         TH955_CONTROL_UNEXPECTED                  (anything else)
#
# Both use synthetic identities only, run in one transaction and always roll
# back.
set -euo pipefail

migration="supabase/migrations/202610180011_care.sql"
previous="supabase/migrations/202610180002_service_session_guard.sql"
migrations_dir="supabase/migrations"
contract="docs/contracts/database.md"

# The block between the legacy share consent markers in the migration.
legacy_block() {
  if [[ -f "$migration" ]]; then
    sed -n '/^-- TH-955 legacy share consents: begin$/,/^-- TH-955 legacy share consents: end$/p' "$migration" |
      sed '1d;$d'
  else
    echo "do \$\$ begin raise exception 'FAIL setup: $migration is missing'; end \$\$;"
  fi
}

print_sql() {
  cat <<'SQL'
begin;

do $setup$
begin
  if not coalesce((select rolsuper from pg_catalog.pg_roles where rolname = current_user), false) then
    raise exception 'FAIL setup: this SQL test needs a superuser connection (it switches the session user to thsync and authenticator)';
  end if;
  if exists (
    select 1 from pg_catalog.unnest(array['anon', 'authenticated', 'authenticator', 'service_role', 'thsync']) as r(n)
    where not exists (select 1 from pg_catalog.pg_roles where rolname = r.n)) then
    raise exception 'FAIL setup: one of the roles anon, authenticated, authenticator, service_role, thsync is missing';
  end if;
  if pg_catalog.to_regclass('public.care_connections') is null
     or pg_catalog.to_regprocedure('public.redeem_care_invite(text)') is null
     or pg_catalog.to_regprocedure('public.delete_my_account(text)') is null then
    raise exception 'FAIL setup: the care tables, public.redeem_care_invite(text) and public.delete_my_account(text) are needed';
  end if;
end;
$setup$;

select set_config('th955.superuser', session_user, true);

create schema th955_test;

create function th955_test.ok(p_cond boolean, p_label text)
returns void language plpgsql set search_path = '' as $f$
begin
  if p_cond is distinct from true then
    raise exception 'FAIL %', p_label;
  end if;
  raise notice 'PASS %', p_label;
end;
$f$;

-- Expects p_sql to fail with one of the SQLSTATEs in p_states ("a|b") and a
-- message like p_message_like; when p_hint is given, the hint must equal it.
create function th955_test.refused(
  p_sql text, p_states text, p_message_like text, p_label text, p_hint text default null)
returns void language plpgsql set search_path = '' as $f$
declare
  got_hint text;
begin
  begin
    execute p_sql;
  exception when others then
    get stacked diagnostics got_hint = pg_exception_hint;
    if sqlstate = any (pg_catalog.string_to_array(p_states, '|')) and sqlerrm like p_message_like
       and (p_hint is null or got_hint is not distinct from p_hint) then
      raise notice 'PASS % (% %)', p_label, sqlstate, sqlerrm;
      return;
    end if;
    raise exception 'FAIL % (got % % hint %)', p_label, sqlstate, sqlerrm, got_hint;
  end;
  raise exception 'FAIL % (statement succeeded)', p_label;
end;
$f$;

create function th955_test.affects(p_sql text, p_rows integer, p_label text)
returns void language plpgsql set search_path = '' as $f$
declare
  n integer;
begin
  execute p_sql;
  get diagnostics n = row_count;
  if n is distinct from p_rows then
    raise exception 'FAIL % (% rows, expected %)', p_label, n, p_rows;
  end if;
  raise notice 'PASS % (% rows)', p_label, n;
end;
$f$;

-- A value stored with set_config('th955.<name>', ...).
create function th955_test.v(p_name text)
returns text language sql stable set search_path = '' as $f$
  select pg_catalog.current_setting('th955.' || p_name)
$f$;

-- Token claims for p_sub with one password sign-in 30 seconds ago.
create function th955_test.claims(p_sub text)
returns text language sql stable set search_path = '' as $f$
  select pg_catalog.jsonb_build_object('role', 'authenticated', 'aud', 'authenticated', 'sub', p_sub,
    'amr', pg_catalog.jsonb_build_array(pg_catalog.jsonb_build_object(
      'method', 'password', 'timestamp', extract(epoch from pg_catalog.now()) - 30)))::text
$f$;

-- Switches the session to p_login acting as p_role with p_claims, the way
-- PostgREST (authenticator) and the sync service (thsync) do; or back to the
-- superuser that started the test. No SET clause on purpose: SET LOCAL
-- inside a function with one would be undone when it returns.
create function th955_test.act_as(p_login text, p_claims text, p_role text default 'authenticated')
returns void language plpgsql as $f$
begin
  reset role;
  execute pg_catalog.format('set session authorization %I', p_login);
  perform pg_catalog.set_config('request.jwt.claim.sub', '', true);
  perform pg_catalog.set_config('request.jwt.claims', coalesce(p_claims, ''), true);
  if p_login <> pg_catalog.current_setting('th955.superuser') then
    execute pg_catalog.format('set local role %I', p_role);
  end if;
end;
$f$;

-- Enrols p_user in p_code (as the caller) with a live core consent, and
-- stores the enrolment id as th955.<p_key>.
create function th955_test.enrol(p_key text, p_user uuid, p_code text, p_status text)
returns void language plpgsql set search_path = '' as $f$
declare
  new_id uuid;
begin
  insert into public.enrolments (user_id, programme_code, status)
  values (p_user, p_code, p_status) returning id into new_id;
  insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
  values (new_id, 'core', 'v1-draft', 'en');
  perform pg_catalog.set_config('th955.' || p_key, new_id::text, true);
end;
$f$;

-- Grants a sharing consent as the caller and stores its id as th955.<p_key>.
create function th955_test.grant_share(
  p_key text, p_enrolment text, p_purpose text, p_recipient text, p_label text)
returns void language plpgsql set search_path = '' as $f$
declare
  new_id uuid;
begin
  insert into public.programme_consents (enrolment_id, purpose, recipient_ref, consent_version, locale)
  values (p_enrolment::uuid, p_purpose, p_recipient, 'v1-draft', 'en') returning id into new_id;
  perform pg_catalog.set_config('th955.' || p_key, new_id::text, true);
  raise notice 'PASS %', p_label;
end;
$f$;

-- Inserts a share as the caller and stores its id as th955.<p_key>.
create function th955_test.add_share(
  p_key text, p_enrolment text, p_connection text, p_consent text, p_kind text, p_label text)
returns void language plpgsql set search_path = '' as $f$
declare
  new_id uuid;
begin
  insert into public.care_shares (user_id, enrolment_id, connection_id, consent_id, kind, snapshot)
  values (auth.uid(), p_enrolment::uuid, p_connection::uuid, p_consent::uuid, p_kind,
          '{"summary": "synthetic"}') returning id into new_id;
  perform pg_catalog.set_config('th955.' || p_key, new_id::text, true);
  raise notice 'PASS %', p_label;
end;
$f$;

-- Inserts a caregiver as the caller and stores its id as th955.<p_key>.
create function th955_test.add_caregiver(p_key text, p_enrolment text, p_scope text[], p_label text)
returns void language plpgsql set search_path = '' as $f$
declare
  new_id uuid;
begin
  insert into public.caregivers (user_id, enrolment_id, name, phone, scope)
  values (auth.uid(), p_enrolment::uuid, 'Synthetic Caregiver', '+15550100001', p_scope)
  returning id into new_id;
  perform pg_catalog.set_config('th955.' || p_key, new_id::text, true);
  raise notice 'PASS %', p_label;
end;
$f$;

-- The rows a user holds in every member table, keyed like the
-- delete_my_app_data receipt.
create function th955_test.counts(p_user uuid)
returns jsonb language sql stable set search_path = '' as $f$
  select pg_catalog.jsonb_build_object(
    'profiles', (select count(*) from public.profiles where id = p_user),
    'quit_plans', (select count(*) from public.quit_plans where user_id = p_user),
    'program_data', (select count(*) from public.program_data where user_id = p_user),
    'enrolments', (select count(*) from public.enrolments where user_id = p_user),
    'programme_consents', (select count(*) from public.programme_consents as c
                           join public.enrolments as e on e.id = c.enrolment_id
                           where e.user_id = p_user),
    'account_consents', (select count(*) from public.account_consents where user_id = p_user),
    'sync_answers', (select count(*) from public.sync_answer where user_id = p_user),
    'sync_lapses', (select count(*) from public.sync_lapse where user_id = p_user),
    'sync_areas', (select count(*) from public.sync_area where user_id = p_user),
    'sync_accounts', (select count(*) from public.sync_account where user_id = p_user),
    'care_share_access', (select count(*) from public.care_share_access where user_id = p_user),
    'care_messages', (select count(*) from public.care_messages where user_id = p_user),
    'care_shares', (select count(*) from public.care_shares where user_id = p_user),
    'caregiver_events', (select count(*) from public.caregiver_events where user_id = p_user),
    'caregivers', (select count(*) from public.caregivers where user_id = p_user),
    'care_connections', (select count(*) from public.care_connections where user_id = p_user),
    'supporters', (select count(*) from public.supporters where user_id = p_user))
$f$;

-- Member rows plus the identity and whether account deletion was started.
create function th955_test.state(p_user uuid)
returns jsonb language sql stable set search_path = '' as $f$
  select th955_test.counts(p_user) || pg_catalog.jsonb_build_object(
    'users', (select count(*) from auth.users where id = p_user),
    'deletion_started', (select account_deletion_started_at is not null
                         from public.profiles where id = p_user))
$f$;

-- Every share's consent row still exists (consent_id is not a foreign key).
create function th955_test.no_orphans(p_label text)
returns void language sql set search_path = '' as $f$
  select th955_test.ok(
    not exists (
      select 1 from public.care_shares as s
      where not exists (select 1 from public.programme_consents as c where c.id = s.consent_id)),
    'no share without its consent row: ' || p_label)
$f$;

-- Rows of any table in public, auth or storage whose text matches p_pattern.
create function th955_test.text_hits(p_pattern text)
returns bigint language plpgsql set search_path = '' as $f$
declare
  rel record;
  n bigint;
  total bigint := 0;
begin
  for rel in
    select ns.nspname, c.relname
    from pg_catalog.pg_class as c
    join pg_catalog.pg_namespace as ns on ns.oid = c.relnamespace
    where c.relkind in ('r', 'p') and ns.nspname in ('public', 'auth', 'storage')
  loop
    execute pg_catalog.format(
      'select count(*) from %I.%I as t where pg_catalog.row_to_json(t)::text ilike %L',
      rel.nspname, rel.relname, p_pattern) into n;
    total := total + n;
  end loop;
  return total;
end;
$f$;

grant usage on schema th955_test to public;
grant execute on all functions in schema th955_test to public;
revoke all on function th955_test.text_hits(text) from public;

-- Catalogue -------------------------------------------------------------------
-- The reviewed check constraints of the care tables, as pg_get_constraintdef
-- prints them (schema prefixes removed), ordered by constraint name.
select set_config('th955.check_constraints', btrim($checks$
care_connections.care_connections_revoked_check: CHECK (((revoked_at IS NULL) OR (revoked_at >= connected_at)))
care_invites.care_invites_code_hash_check: CHECK ((octet_length(code_hash) = 32))
care_invites.care_invites_created_by_check: CHECK (((char_length(created_by) >= 1) AND (char_length(created_by) <= 120)))
care_invites.care_invites_expires_check: CHECK ((expires_at > created_at))
care_invites.care_invites_max_uses_check: CHECK (((max_uses >= 1) AND (max_uses <= 10000)))
care_invites.care_invites_uses_check: CHECK (((uses >= 0) AND (uses <= max_uses)))
care_messages.care_messages_body_check: CHECK (((char_length(body) >= 1) AND (char_length(body) <= 2000)))
care_messages.care_messages_share_enrolment_check: CHECK (((share_id IS NULL) OR (enrolment_id IS NOT NULL)))
care_messages.care_messages_topic_check: CHECK (((char_length(topic) >= 1) AND (char_length(topic) <= 80)))
care_orgs.care_orgs_contact_email_check: CHECK (((contact_email IS NULL) OR ((char_length(contact_email) <= 254) AND (contact_email ~ '^[^@]+@[^@]+$'::text))))
care_orgs.care_orgs_name_check: CHECK (((name = btrim(name)) AND ((char_length(name) >= 1) AND (char_length(name) <= 120))))
care_share_access.care_share_access_channel_check: CHECK ((channel = 'secure_link'::text))
care_shares.care_shares_expires_check: CHECK (((expires_at > created_at) AND (expires_at <= (created_at + '30 days'::interval))))
care_shares.care_shares_kind_check: CHECK ((kind = ANY (ARRAY['visit_summary'::text, 'message_attachment'::text])))
care_shares.care_shares_revoked_check: CHECK (((revoked_at IS NULL) OR (revoked_at >= created_at)))
care_shares.care_shares_snapshot_check: CHECK (((jsonb_typeof(snapshot) = 'object'::text) AND (octet_length((snapshot)::text) <= 65536)))
caregiver_events.caregiver_events_kind_check: CHECK ((kind = ANY (ARRAY['sd.session_finished'::text, 'sd.fall_logged'::text])))
caregivers.caregivers_invite_status_check: CHECK ((invite_status = ANY (ARRAY['pending'::text, 'sent'::text])))
caregivers.caregivers_name_check: CHECK (((name = btrim(name)) AND ((char_length(name) >= 1) AND (char_length(name) <= 80))))
caregivers.caregivers_phone_check: CHECK ((phone ~ '^\+[1-9][0-9]{6,14}$'::text))
caregivers.caregivers_revoked_check: CHECK (((revoked_at IS NULL) OR (revoked_at >= created_at)))
caregivers.caregivers_scope_check: CHECK (((cardinality(scope) >= 1) AND (array_position(scope, NULL::text) IS NULL) AND is_unique_text_array(scope) AND (scope <@ ARRAY['sd.session_finished'::text, 'sd.fall_logged'::text])))
supporters.supporters_help_phrase_check: CHECK (((help_phrase IS NULL) OR ((char_length(help_phrase) >= 1) AND (char_length(help_phrase) <= 200))))
supporters.supporters_name_check: CHECK (((name = btrim(name)) AND ((char_length(name) >= 1) AND (char_length(name) <= 80))))
supporters.supporters_phone_check: CHECK ((phone ~ '^\+[1-9][0-9]{6,14}$'::text))
supporters.supporters_programme_codes_check: CHECK (((array_position(programme_codes, NULL::text) IS NULL) AND is_unique_text_array(programme_codes) AND (programme_codes <@ ARRAY['bf'::text, 'sf'::text])))
$checks$, E'\n'), true);
select th955_test.ok(
  (select string_agg(relname || ':' || relrowsecurity || ':' || relforcerowsecurity, ','
                     order by relname)
   from pg_catalog.pg_class
   where relnamespace = 'public'::regnamespace and relkind = 'r'
     and relname in ('care_orgs', 'care_invites', 'care_connections', 'care_shares',
                     'care_share_access', 'care_messages', 'caregivers', 'caregiver_events',
                     'supporters')) =
  'care_connections:true:true,care_invites:true:true,care_messages:true:true,'
  'care_orgs:true:true,care_share_access:true:true,care_shares:true:true,'
  'caregiver_events:true:true,caregivers:true:true,supporters:true:true',
  'catalogue: the nine care tables exist with row-level security enabled and forced');
select th955_test.ok(
  (select string_agg(t.relname || '(' || t.cols || ')', ' ' order by t.relname)
   from (select c.relname, string_agg(a.attname, ',' order by a.attnum) as cols
         from pg_catalog.pg_class as c
         join pg_catalog.pg_attribute as a on a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped
         where c.relnamespace = 'public'::regnamespace
           and c.relname in ('care_orgs', 'care_invites', 'care_connections', 'care_shares',
                             'care_share_access', 'care_messages', 'caregivers',
                             'caregiver_events', 'supporters')
         group by c.relname) as t) =
  'care_connections(id,user_id,org_id,invite_id,connected_at,revoked_at,created_at) '
  'care_invites(id,org_id,code_hash,expires_at,max_uses,uses,created_by,created_at) '
  'care_messages(id,user_id,connection_id,enrolment_id,topic,body,share_id,created_at) '
  'care_orgs(id,name,contact_email,verified_at,disabled_at,created_at) '
  'care_share_access(id,user_id,share_id,accessed_at,channel,created_at) '
  'care_shares(id,user_id,enrolment_id,connection_id,consent_id,kind,snapshot,created_at,expires_at,revoked_at) '
  'caregiver_events(id,user_id,caregiver_id,kind,occurred_at,created_at) '
  'caregivers(id,user_id,enrolment_id,name,phone,scope,invite_status,created_at,revoked_at) '
  'supporters(id,user_id,name,phone,programme_codes,help_phrase,created_at,updated_at)',
  'catalogue: exactly the reviewed columns; care_invites holds code_hash and no code column');
select th955_test.ok(
  (select count(*) = 9
     and bool_and(format_type(a.atttypid, a.atttypmod) = 'uuid' and a.attnotnull
                  and pg_catalog.pg_get_expr(d.adbin, d.adrelid) = 'gen_random_uuid()')
   from pg_catalog.pg_class as c
   join pg_catalog.pg_attribute as a on a.attrelid = c.oid and a.attname = 'id'
   join pg_catalog.pg_attrdef as d on d.adrelid = c.oid and d.adnum = a.attnum
   where c.relnamespace = 'public'::regnamespace
     and c.relname in ('care_orgs', 'care_invites', 'care_connections', 'care_shares',
                       'care_share_access', 'care_messages', 'caregivers', 'caregiver_events',
                       'supporters'))
  and not exists (
    select 1 from pg_catalog.pg_attribute as a
    join pg_catalog.pg_class as c on c.oid = a.attrelid
    left join pg_catalog.pg_attrdef as d on d.adrelid = a.attrelid and d.adnum = a.attnum
    where c.relnamespace = 'public'::regnamespace
      and c.relname in ('care_orgs', 'care_invites', 'care_connections', 'care_shares',
                        'care_share_access', 'care_messages', 'caregivers', 'caregiver_events',
                        'supporters')
      and (a.attidentity <> '' or coalesce(pg_catalog.pg_get_expr(d.adbin, d.adrelid), '') like '%nextval%'))
  and (select format_type(atttypid, atttypmod) = 'bytea' and attnotnull
       from pg_catalog.pg_attribute
       where attrelid = 'public.care_invites'::regclass and attname = 'code_hash'),
  'catalogue: every id is a uuid with gen_random_uuid(), no identity or sequence; code_hash is bytea not null');
select th955_test.ok(
  (select string_agg(c.relname || '.' || a.attname || '>' || fn.nspname || '.' || fc.relname
                     || ':' || k.confdeltype::text, ',' order by c.relname, a.attname)
   from pg_catalog.pg_constraint as k
   join pg_catalog.pg_class as c on c.oid = k.conrelid
   join pg_catalog.pg_attribute as a on a.attrelid = k.conrelid and a.attnum = k.conkey[1]
   join pg_catalog.pg_class as fc on fc.oid = k.confrelid
   join pg_catalog.pg_namespace as fn on fn.oid = fc.relnamespace
   where k.contype = 'f' and c.relnamespace = 'public'::regnamespace
     and c.relname in ('care_orgs', 'care_invites', 'care_connections', 'care_shares',
                       'care_share_access', 'care_messages', 'caregivers', 'caregiver_events',
                       'supporters')) =
  'care_connections.invite_id>public.care_invites:a,care_connections.org_id>public.care_orgs:a,'
  'care_connections.user_id>auth.users:c,care_invites.org_id>public.care_orgs:c,'
  'care_messages.connection_id>public.care_connections:c,care_messages.enrolment_id>public.enrolments:c,'
  'care_messages.share_id>public.care_shares:c,care_messages.user_id>auth.users:c,'
  'care_share_access.share_id>public.care_shares:c,care_share_access.user_id>auth.users:c,'
  'care_shares.connection_id>public.care_connections:c,care_shares.enrolment_id>public.enrolments:c,'
  'care_shares.user_id>auth.users:c,caregiver_events.caregiver_id>public.caregivers:c,'
  'caregiver_events.user_id>auth.users:c,caregivers.enrolment_id>public.enrolments:c,'
  'caregivers.user_id>auth.users:c,supporters.user_id>auth.users:c',
  'catalogue: foreign keys exactly as reviewed; care_shares.consent_id has none; nothing sets null or a default');
select th955_test.ok(
  (select string_agg(c.relname || '.' || k.conname || ': '
                     || replace(pg_catalog.pg_get_constraintdef(k.oid), 'public.', ''), E'\n'
                     order by k.conname)
   from pg_catalog.pg_constraint as k
   join pg_catalog.pg_class as c on c.oid = k.conrelid
   where k.contype = 'c' and c.relnamespace = 'public'::regnamespace
     and c.relname in ('care_orgs', 'care_invites', 'care_connections', 'care_shares',
                       'care_share_access', 'care_messages', 'caregivers', 'caregiver_events',
                       'supporters')) =
  current_setting('th955.check_constraints'),
  'catalogue: every check constraint on the care tables is exactly as reviewed');
select th955_test.ok(
  not exists (
    select 1 from pg_catalog.pg_constraint as k
    join pg_catalog.pg_class as fc on fc.oid = k.confrelid
    where k.contype = 'f'
      and k.conrelid in (select oid from pg_catalog.pg_class
                         where relnamespace = 'public'::regnamespace
                           and relname in ('care_orgs', 'care_invites', 'care_connections',
                                           'care_shares', 'care_share_access', 'care_messages',
                                           'caregivers', 'caregiver_events', 'supporters'))
      and (k.confrelid in ('public.programme_consents'::regclass, 'public.account_consents'::regclass,
                           'public.consent_documents'::regclass)
           or (fc.relnamespace = 'public'::regnamespace and fc.relname like 'sync\_%')
           or k.confupdtype <> 'a' or k.confdeltype in ('n', 'd')))
  and exists (select 1 from pg_catalog.pg_index
              where indrelid = 'public.care_shares'::regclass
                and indkey[0] = (select attnum from pg_catalog.pg_attribute
                                 where attrelid = 'public.care_shares'::regclass
                                   and attname = 'consent_id')),
  'catalogue: no care table references the consent, consent document or sync tables; consent_id is indexed');
select th955_test.ok(
  (with t as (
     select oid, relname from pg_catalog.pg_class
     where relnamespace = 'public'::regnamespace
       and relname in ('care_orgs', 'care_invites', 'care_connections', 'care_shares',
                       'care_share_access', 'care_messages', 'caregivers', 'caregiver_events',
                       'supporters'))
   select string_agg(e, ',' order by e collate "C")
   from (select t.relname || ':' || a.privilege_type as e
         from t join pg_catalog.pg_class as c on c.oid = t.oid
         cross join lateral pg_catalog.aclexplode(c.relacl) as a
         where a.grantee = 'authenticated'::regrole
         union all
         select t.relname || '.' || att.attname || ':' || a.privilege_type
         from t join pg_catalog.pg_attribute as att on att.attrelid = t.oid and att.attacl is not null
         cross join lateral pg_catalog.aclexplode(att.attacl) as a
         where a.grantee = 'authenticated'::regrole) as x) =
  'care_connections.revoked_at:UPDATE,care_connections:SELECT,care_messages.body:INSERT,'
  'care_messages.connection_id:INSERT,care_messages.enrolment_id:INSERT,'
  'care_messages.share_id:INSERT,care_messages.topic:INSERT,care_messages.user_id:INSERT,'
  'care_messages:SELECT,care_orgs.id:SELECT,care_orgs.name:SELECT,care_share_access:SELECT,'
  'care_shares.connection_id:INSERT,care_shares.consent_id:INSERT,'
  'care_shares.enrolment_id:INSERT,care_shares.expires_at:INSERT,care_shares.kind:INSERT,'
  'care_shares.revoked_at:UPDATE,care_shares.snapshot:INSERT,care_shares.user_id:INSERT,'
  'care_shares:SELECT,caregiver_events.caregiver_id:INSERT,caregiver_events.kind:INSERT,'
  'caregiver_events.occurred_at:INSERT,caregiver_events.user_id:INSERT,'
  'caregiver_events:SELECT,caregivers.enrolment_id:INSERT,caregivers.invite_status:UPDATE,'
  'caregivers.name:INSERT,caregivers.phone:INSERT,caregivers.revoked_at:UPDATE,'
  'caregivers.scope:INSERT,caregivers.user_id:INSERT,caregivers:SELECT,'
  'supporters.help_phrase:INSERT,supporters.help_phrase:UPDATE,supporters.name:INSERT,'
  'supporters.name:UPDATE,supporters.phone:INSERT,supporters.phone:UPDATE,'
  'supporters.programme_codes:INSERT,supporters.programme_codes:UPDATE,'
  'supporters.user_id:INSERT,supporters:DELETE,supporters:SELECT',
  'catalogue: authenticated holds exactly the reviewed table and column privileges');
select th955_test.ok(
  not exists (
    select 1 from pg_catalog.pg_class as c
    cross join lateral pg_catalog.aclexplode(c.relacl) as a
    where c.relnamespace = 'public'::regnamespace
      and c.relname in ('care_orgs', 'care_invites', 'care_connections', 'care_shares',
                        'care_share_access', 'care_messages', 'caregivers', 'caregiver_events',
                        'supporters')
      and a.grantee not in (c.relowner, 'authenticated'::regrole))
  and not exists (
    select 1 from pg_catalog.pg_attribute as att
    join pg_catalog.pg_class as c on c.oid = att.attrelid
    cross join lateral pg_catalog.aclexplode(att.attacl) as a
    where c.relnamespace = 'public'::regnamespace and att.attacl is not null
      and c.relname in ('care_orgs', 'care_invites', 'care_connections', 'care_shares',
                        'care_share_access', 'care_messages', 'caregivers', 'caregiver_events',
                        'supporters')
      and a.grantee not in (c.relowner, 'authenticated'::regrole)),
  'catalogue: every privilege on the care tables is held by their owner or authenticated, and no one else');
select th955_test.ok(
  (select string_agg(tablename || ':' || policyname || ':' || cmd || ':' || permissive || ':'
                     || array_to_string(roles, '+'), ',' order by tablename, policyname)
   from pg_catalog.pg_policies
   where schemaname = 'public'
     and tablename in ('care_orgs', 'care_invites', 'care_connections', 'care_shares',
                       'care_share_access', 'care_messages', 'caregivers', 'caregiver_events',
                       'supporters')) =
  'care_connections:care_connections_select_own:SELECT:PERMISSIVE:authenticated,'
  'care_connections:care_connections_update_own:UPDATE:PERMISSIVE:authenticated,'
  'care_messages:care_messages_insert_own:INSERT:PERMISSIVE:authenticated,'
  'care_messages:care_messages_select_own:SELECT:PERMISSIVE:authenticated,'
  'care_orgs:care_orgs_select_connected:SELECT:PERMISSIVE:authenticated,'
  'care_share_access:care_share_access_select_own:SELECT:PERMISSIVE:authenticated,'
  'care_shares:care_shares_insert_own:INSERT:PERMISSIVE:authenticated,'
  'care_shares:care_shares_select_own:SELECT:PERMISSIVE:authenticated,'
  'care_shares:care_shares_update_own:UPDATE:PERMISSIVE:authenticated,'
  'caregiver_events:caregiver_events_insert_own:INSERT:PERMISSIVE:authenticated,'
  'caregiver_events:caregiver_events_select_own:SELECT:PERMISSIVE:authenticated,'
  'caregivers:caregivers_insert_own:INSERT:PERMISSIVE:authenticated,'
  'caregivers:caregivers_select_own:SELECT:PERMISSIVE:authenticated,'
  'caregivers:caregivers_update_own:UPDATE:PERMISSIVE:authenticated,'
  'supporters:supporters_delete_own:DELETE:PERMISSIVE:authenticated,'
  'supporters:supporters_insert_own:INSERT:PERMISSIVE:authenticated,'
  'supporters:supporters_select_own:SELECT:PERMISSIVE:authenticated,'
  'supporters:supporters_update_own:UPDATE:PERMISSIVE:authenticated',
  'catalogue: the care policies are exactly the reviewed per-command policies for authenticated');
-- care_connections' own select policy already limits the subquery to the
-- caller's rows, so no member-level test can tell the ownership clause apart;
-- the clause is pinned here.
select th955_test.ok(
  (select regexp_replace(replace(qual, 'public.', ''), '\s+', ' ', 'g')
   from pg_catalog.pg_policies
   where schemaname = 'public' and policyname = 'care_orgs_select_connected') =
  '(EXISTS ( SELECT 1 FROM care_connections c WHERE ((c.org_id = care_orgs.id) AND (c.user_id = ( SELECT auth.uid() AS uid)))))',
  'catalogue: a clinic is visible only through one of the caller''s own connections');
select th955_test.ok(
  not exists (
    select 1 from pg_catalog.pg_policies
    where schemaname = 'public'
      and tablename in ('care_orgs', 'care_invites', 'care_connections', 'care_shares',
                        'care_share_access', 'care_messages', 'caregivers', 'caregiver_events',
                        'supporters')
      and ((cmd in ('INSERT', 'UPDATE')
            and coalesce(with_check, '') !~ ' AND \(NOT (public\.)?sync_writer_session\(\)\)\)$')
        or (cmd in ('UPDATE', 'DELETE')
            and coalesce(qual, '') !~ ' AND \(NOT (public\.)?sync_writer_session\(\)\)\)$')
        or (cmd = 'INSERT' and coalesce(with_check, '') !~ 'deletion_barrier_open\(\)')
        or (cmd in ('UPDATE', 'DELETE')
            and coalesce(qual, '') || coalesce(with_check, '') ~ 'deletion_barrier_open')
        or (cmd = 'SELECT' and coalesce(qual, '') ~ 'sync_writer_session'))),
  'catalogue: every write clause ends with the sync guard; inserts check the deletion barrier; reads are unguarded');
select th955_test.ok(
  (select string_agg(p.proname || ':' || p.prosecdef || ':' || coalesce(array_to_string(p.proconfig, ';'), '')
                     || ':' || replace(coalesce(p.proacl::text, 'default'), pg_catalog.pg_get_userbyid(p.proowner), 'OWNER'),
                     ',' order by p.proname)
   from pg_catalog.pg_proc as p
   where p.pronamespace = 'public'::regnamespace
     and p.proname in ('care_check_consent_recipient', 'care_lock_live_consent', 'care_revoke_only',
                       'care_append_only', 'care_truncate_guard', 'programme_consents_revoke_care_shares',
                       'care_connections_revoke_cascade', 'caregivers_revoke_cascade',
                       'supporters_drop_programme', 'redeem_care_invite')) =
  'care_append_only:false:search_path="":{OWNER=X/OWNER},'
  'care_check_consent_recipient:false:search_path="":{OWNER=X/OWNER},'
  'care_connections_revoke_cascade:false:search_path="":{OWNER=X/OWNER},'
  'care_lock_live_consent:false:search_path="":{OWNER=X/OWNER},'
  'care_revoke_only:false:search_path="":{OWNER=X/OWNER},'
  'care_truncate_guard:false:search_path="":{OWNER=X/OWNER},'
  'caregivers_revoke_cascade:false:search_path="":{OWNER=X/OWNER},'
  'programme_consents_revoke_care_shares:false:search_path="":{OWNER=X/OWNER},'
  'redeem_care_invite:true:search_path="":{OWNER=X/OWNER,authenticated=X/OWNER},'
  'supporters_drop_programme:true:search_path="":{OWNER=X/OWNER}',
  'catalogue: the ten functions; two security definer; empty search_path; only authenticated may execute redeem_care_invite');
select th955_test.ok(
  (select prorettype = 'public.care_connections'::regtype
   from pg_catalog.pg_proc where oid = 'public.redeem_care_invite(text)'::regprocedure)
  and not pg_catalog.has_function_privilege('anon', 'public.redeem_care_invite(text)', 'EXECUTE')
  and not pg_catalog.has_function_privilege('service_role', 'public.redeem_care_invite(text)', 'EXECUTE'),
  'catalogue: redeem_care_invite(text) returns a care_connections row; anon and service_role may not execute it');
select th955_test.ok(
  (select string_agg(c.relname || ':' || t.tgname || ':' || t.tgtype || ':' || p.proname || ':'
                     || t.tgenabled::text, ',' order by c.relname, t.tgname)
   from pg_catalog.pg_trigger as t
   join pg_catalog.pg_class as c on c.oid = t.tgrelid
   join pg_catalog.pg_proc as p on p.oid = t.tgfoid
   where not t.tgisinternal and c.relnamespace = 'public'::regnamespace
     and c.relname in ('care_orgs', 'care_invites', 'care_connections', 'care_shares',
                       'care_share_access', 'care_messages', 'caregivers', 'caregiver_events',
                       'supporters')) =
  'care_connections:care_connections_revoke_cascade:17:care_connections_revoke_cascade:O,'
  'care_connections:care_connections_revoke_only:19:care_revoke_only:O,'
  'care_connections:care_connections_truncate_guard:34:care_truncate_guard:A,'
  'care_messages:care_messages_append_only:19:care_append_only:O,'
  'care_messages:care_messages_truncate_guard:34:care_truncate_guard:A,'
  'care_share_access:care_share_access_append_only:19:care_append_only:O,'
  'care_share_access:care_share_access_truncate_guard:34:care_truncate_guard:A,'
  'care_shares:care_shares_lock_consent:7:care_lock_live_consent:O,'
  'care_shares:care_shares_revoke_only:19:care_revoke_only:O,'
  'care_shares:care_shares_truncate_guard:34:care_truncate_guard:A,'
  'caregiver_events:caregiver_events_append_only:19:care_append_only:O,'
  'caregiver_events:caregiver_events_lock_consent:7:care_lock_live_consent:O,'
  'caregiver_events:caregiver_events_truncate_guard:34:care_truncate_guard:A,'
  'caregivers:caregivers_revoke_cascade:17:caregivers_revoke_cascade:O,'
  'caregivers:caregivers_revoke_only:19:care_revoke_only:O,'
  'caregivers:caregivers_truncate_guard:34:care_truncate_guard:A,'
  'supporters:supporters_set_updated_at:19:set_updated_at:O',
  'catalogue: care triggers exactly as reviewed; the six truncate guards fire in every session mode');
select th955_test.ok(
  (select string_agg(c.relname || ':' || t.tgname || ':' || t.tgtype || ':' || p.proname || ':'
                     || t.tgenabled::text, ',' order by c.relname, t.tgname)
   from pg_catalog.pg_trigger as t
   join pg_catalog.pg_class as c on c.oid = t.tgrelid
   join pg_catalog.pg_proc as p on p.oid = t.tgfoid
   where not t.tgisinternal
     and t.tgrelid in ('public.programme_consents'::regclass, 'public.enrolments'::regclass)
     and p.proname in ('care_check_consent_recipient', 'programme_consents_revoke_care_shares',
                       'supporters_drop_programme')) =
  'enrolments:enrolments_drop_supporter_programme:17:supporters_drop_programme:O,'
  'enrolments:enrolments_drop_supporter_programme_on_delete:9:supporters_drop_programme:O,'
  'programme_consents:programme_consents_check_recipient:7:care_check_consent_recipient:O,'
  'programme_consents:programme_consents_revoke_care_shares:17:programme_consents_revoke_care_shares:O'
  and (select pg_catalog.pg_get_triggerdef(oid) like '%WHEN%share_care_team%share_caregiver%recipient_ref IS NOT NULL%'
       from pg_catalog.pg_trigger where tgname = 'programme_consents_check_recipient')
  and (select pg_catalog.pg_get_triggerdef(oid) like '%AFTER UPDATE OF revoked_at%share_care_team%'
       from pg_catalog.pg_trigger where tgname = 'programme_consents_revoke_care_shares')
  and (select pg_catalog.pg_get_triggerdef(oid) like '%AFTER UPDATE OF status%''left''%'
       from pg_catalog.pg_trigger where tgname = 'enrolments_drop_supporter_programme'),
  'catalogue: the four new triggers on programme_consents and enrolments, with their conditions');
select th955_test.ok(
  not pg_catalog.has_function_privilege('authenticated', 'public.delete_my_app_data(text)', 'EXECUTE')
  and pg_catalog.obj_description('public.delete_my_app_data(text)'::regprocedure, 'pg_proc')
      = 'Deletes the calling member app-owned rows in public and returns counts only. Only its owner may execute it: members reach it through delete_my_account, which also deletes the Auth identity.',
  'catalogue: delete_my_app_data keeps its owner-only execute and its comment');

-- Synthetic accounts, clinics and invites (as the superuser) --------------------
-- A: the main member. B: another member. C: identity deleted by an Auth stand-in.
-- D: a member who tries A's code.
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-4000-8000-0000009550a1', 'synthetic-user-955a@example.test', 'authenticated', 'authenticated'),
  ('00000000-0000-4000-8000-0000009550b1', 'synthetic-user-955b@example.test', 'authenticated', 'authenticated'),
  ('00000000-0000-4000-8000-0000009550c1', 'synthetic-user-955c@example.test', 'authenticated', 'authenticated'),
  ('00000000-0000-4000-8000-0000009550d1', 'synthetic-user-955d@example.test', 'authenticated', 'authenticated');
insert into public.care_orgs (name, contact_email, verified_at, disabled_at) values
  ('Synthetic Clinic 955 A', 'clinic-955a@example.test', now(), null),
  ('Synthetic Clinic 955 B', null, now(), null),
  ('Synthetic Clinic 955 M', null, now(), null),
  ('Synthetic Clinic 955 C', null, now(), null),
  ('Synthetic Clinic 955 E', null, now(), null),
  ('Synthetic Clinic 955 U', null, null, null),
  ('Synthetic Clinic 955 X', null, now(), now());
select set_config('th955.org_' || lower(right(name, 1)), id::text, true)
from public.care_orgs where name like 'Synthetic Clinic 955 _';
-- Codes are sent only to the hash; no table receives them.
insert into public.care_invites (org_id, code_hash, expires_at, max_uses, uses, created_by, created_at)
select o.id, pg_catalog.sha256(convert_to(v.code, 'UTF8')), v.expires_at, v.max_uses, v.uses,
       'synthetic-operator-01', v.created_at
from (values
  ('Synthetic Clinic 955 A', 'SYNTH955A0001', now() + interval '1 day', 1, 0, now()),
  ('Synthetic Clinic 955 B', 'SYNTH955B0001', now() + interval '1 day', 1, 0, now()),
  ('Synthetic Clinic 955 B', 'SYNTH955B0002', now() + interval '1 day', 1, 0, now()),
  ('Synthetic Clinic 955 M', 'SYNTH955M0001', now() + interval '1 day', 10, 0, now()),
  ('Synthetic Clinic 955 C', 'SYNTH955C0001', now() + interval '1 day', 1, 0, now()),
  ('Synthetic Clinic 955 E', 'SYNTH955E0001', now() - interval '1 day', 5, 0, now() - interval '2 days'),
  ('Synthetic Clinic 955 E', 'SYNTH955F0001', now() + interval '1 day', 1, 1, now()),
  ('Synthetic Clinic 955 U', 'SYNTH955N0001', now() + interval '1 day', 5, 0, now()),
  ('Synthetic Clinic 955 X', 'SYNTH955X0001', now() + interval '1 day', 5, 0, now()),
  ('Synthetic Clinic 955 E', 'SYNTH955L11', now() + interval '1 day', 5, 0, now()),
  ('Synthetic Clinic 955 E', 'SYNTH955' || repeat('L', 57), now() + interval '1 day', 5, 0, now())
) as v(org, code, expires_at, max_uses, uses, created_at)
join public.care_orgs as o on o.name = v.org;

select th955_test.enrol('a_hw', '00000000-0000-4000-8000-0000009550a1', 'hw', 'focus');
select th955_test.enrol('a_sd', '00000000-0000-4000-8000-0000009550a1', 'sd', 'learn_only');
select th955_test.enrol('a_bf', '00000000-0000-4000-8000-0000009550a1', 'bf', 'learn_only');
select th955_test.enrol('a_st', '00000000-0000-4000-8000-0000009550a1', 'st', 'learn_only');
select th955_test.enrol('a_nu', '00000000-0000-4000-8000-0000009550a1', 'nu', 'learn_only');
select th955_test.enrol('a_ca', '00000000-0000-4000-8000-0000009550a1', 'ca', 'learn_only');
select th955_test.enrol('a_ck', '00000000-0000-4000-8000-0000009550a1', 'ck', 'learn_only');
select th955_test.enrol('b_hw', '00000000-0000-4000-8000-0000009550b1', 'hw', 'focus');
select th955_test.enrol('b_bf', '00000000-0000-4000-8000-0000009550b1', 'bf', 'learn_only');
select th955_test.enrol('c_bf', '00000000-0000-4000-8000-0000009550c1', 'bf', 'focus');
insert into public.supporters (user_id, name, phone, programme_codes) values
  ('00000000-0000-4000-8000-0000009550c1', 'Synthetic Supporter C', '+15550100003', '{bf}');
-- A row of A in every older member table, for the deletion receipt.
insert into public.quit_plans (user_id, quit_date) values ('00000000-0000-4000-8000-0000009550a1', current_date);
insert into public.program_data (user_id, program_id, payload)
values ('00000000-0000-4000-8000-0000009550a1', 'heartwise', '{}');
insert into public.account_consents (user_id, purpose, consent_version, locale)
values ('00000000-0000-4000-8000-0000009550a1', 'essential', 'v1-draft', 'en');
insert into public.sync_account (user_id) values ('00000000-0000-4000-8000-0000009550a1');
insert into public.sync_area (user_id, enrolment_id, programme_code, revision, change_seq)
values ('00000000-0000-4000-8000-0000009550a1', th955_test.v('a_hw')::uuid, 'hw', 1, 1);
insert into public.sync_answer (user_id, programme_code, screen_id, payload)
values ('00000000-0000-4000-8000-0000009550a1', 'hw', 'hw_targets', '{"slider":{"0":120}}');
insert into public.sync_lapse (user_id, programme_code, ordinal, at)
values ('00000000-0000-4000-8000-0000009550a1', 'hw', 0, now());
set constraints public.enrolments_focus_cap immediate;
set constraints public.enrolments_focus_cap deferred;
select th955_test.ok(
  (select count(*) from public.care_orgs where name like 'Synthetic Clinic 955 _') = 7
  and (select count(*) from public.care_invites
       where org_id in (select id from public.care_orgs where name like 'Synthetic Clinic 955 _')) = 11
  and (select count(*) from public.enrolments where user_id::text like '00000000-0000-4000-8000-0000009550%') = 10,
  'setup: seven synthetic clinics, eleven invites and ten enrolments with core consents');

-- Redemption ------------------------------------------------------------------
select th955_test.act_as('authenticator', th955_test.claims('00000000-0000-4000-8000-0000009550a1'));
select set_config('th955.a1', (public.redeem_care_invite('synth-955a 0001')).id::text, true);
select set_config('th955.a1_again', (public.redeem_care_invite('SYNTH955A0001')).id::text, true);
select th955_test.act_as(current_setting('th955.superuser'), null);
select th955_test.ok(
  (select c.user_id = '00000000-0000-4000-8000-0000009550a1' and c.org_id::text = th955_test.v('org_a')
          and c.revoked_at is null and i.uses = 1
          and i.code_hash = pg_catalog.sha256(convert_to('SYNTH955A0001', 'UTF8'))
   from public.care_connections as c join public.care_invites as i on i.id = c.invite_id
   where c.id = th955_test.v('a1')::uuid),
  'redeem: a valid code (lower case, spaces, hyphens) connects A to its clinic and uses it once');
select th955_test.ok(
  th955_test.v('a1_again') = th955_test.v('a1')
  and (select uses from public.care_invites where org_id = th955_test.v('org_a')::uuid) = 1
  and (select count(*) from public.care_connections
       where user_id = '00000000-0000-4000-8000-0000009550a1') = 1,
  'redeem: repeating the used single-use code returns the same connection and uses nothing');
select set_config('th955.uses_before', (select sum(uses)::text from public.care_invites), true);
select th955_test.act_as('authenticator', th955_test.claims('00000000-0000-4000-8000-0000009550d1'));
select th955_test.refused('select public.redeem_care_invite(''SYNTH955A0001'')',
  'TH025', 'Invite code is not valid', 'redeem: another member with the used single-use code is refused',
  'care_invite_invalid');
select th955_test.act_as('authenticator', th955_test.claims('00000000-0000-4000-8000-0000009550a1'));
select th955_test.refused('select public.redeem_care_invite(''SYNTH955E0001'')',
  'TH025', 'Invite code is not valid', 'redeem: an expired code is refused', 'care_invite_invalid');
select th955_test.refused('select public.redeem_care_invite(''SYNTH955F0001'')',
  'TH025', 'Invite code is not valid', 'redeem: a used-up code is refused', 'care_invite_invalid');
select th955_test.refused('select public.redeem_care_invite(''SYNTH955Z0001'')',
  'TH025', 'Invite code is not valid', 'redeem: an unknown code is refused', 'care_invite_invalid');
select th955_test.refused('select public.redeem_care_invite(''SYNTH955L11'')',
  'TH025', 'Invite code is not valid', 'redeem: an 11-character code is refused by length, though an invite has its hash',
  'care_invite_invalid');
select th955_test.refused('select public.redeem_care_invite(''SYNTH955'' || repeat(''L'', 57))',
  'TH025', 'Invite code is not valid', 'redeem: a 65-character code is refused by length, though an invite has its hash',
  'care_invite_invalid');
select th955_test.refused('select public.redeem_care_invite(null)',
  'TH025', 'Invite code is not valid', 'redeem: a null code is refused', 'care_invite_invalid');
select th955_test.refused('select public.redeem_care_invite(''SYNTH955N0001'')',
  'TH025', 'Invite code is not valid', 'redeem: a code of an unverified clinic is refused', 'care_invite_invalid');
select th955_test.refused('select public.redeem_care_invite(''SYNTH955X0001'')',
  'TH025', 'Invite code is not valid', 'redeem: a code of a disabled clinic is refused', 'care_invite_invalid');
select th955_test.act_as(current_setting('th955.superuser'), null);
select th955_test.ok(
  (select count(*) from public.care_connections
   where user_id in ('00000000-0000-4000-8000-0000009550a1', '00000000-0000-4000-8000-0000009550d1')) = 1
  and (select sum(uses)::text from public.care_invites) = th955_test.v('uses_before'),
  'redeem: the refused codes created no connection and used nothing');

-- B redeems a single-use code, revokes the connection, and tries again.
select th955_test.act_as('authenticator', th955_test.claims('00000000-0000-4000-8000-0000009550b1'));
select set_config('th955.b1', (public.redeem_care_invite('SYNTH955B0001')).id::text, true);
select th955_test.affects(format(
  'update public.care_connections set revoked_at = now() where id = %L', th955_test.v('b1')),
  1, 'B: revokes its connection');
select th955_test.refused('select public.redeem_care_invite(''SYNTH955B0001'')',
  'TH025', 'Invite code is not valid',
  'redeem: after revoking, the same member''s used single-use code is refused', 'care_invite_invalid');
select set_config('th955.bm', (public.redeem_care_invite('SYNTH955M0001')).id::text, true);
select set_config('th955.bc', (public.redeem_care_invite('SYNTH955C0001')).id::text, true);
select th955_test.ok(
  (select string_agg(name, ',' order by name collate "C") from public.care_orgs) =
  'Synthetic Clinic 955 B,Synthetic Clinic 955 C,Synthetic Clinic 955 M',
  'B: sees the clinics it is or was connected to, including one A never joins');
select th955_test.act_as('authenticator', th955_test.claims('00000000-0000-4000-8000-0000009550a1'));
select set_config('th955.am', (public.redeem_care_invite('SYNTH955M0001')).id::text, true);
select set_config('th955.ab', (public.redeem_care_invite('SYNTH955B0002')).id::text, true);
select th955_test.affects(format(
  'update public.care_connections set revoked_at = now() where id = %L', th955_test.v('ab')),
  1, 'A: revokes its connection to clinic B');
select th955_test.act_as(current_setting('th955.superuser'), null);
select th955_test.ok(
  (select count(*) from public.care_connections where user_id = '00000000-0000-4000-8000-0000009550b1') = 3
  and (select count(*) from public.care_connections
       where user_id = '00000000-0000-4000-8000-0000009550b1' and revoked_at is null) = 2
  and (select uses from public.care_invites where org_id = th955_test.v('org_m')::uuid) = 2
  and (select revoked_at >= connected_at from public.care_connections where id = th955_test.v('ab')::uuid),
  'redeem: B holds one revoked and two live connections; a multi-use code was used twice');

select th955_test.act_as('thsync', th955_test.claims('00000000-0000-4000-8000-0000009550a1'));
select th955_test.refused('select public.redeem_care_invite(''SYNTH955M0001'')',
  'TH010', 'The sync service writes only sync tables', 'redeem: a sync service session is refused',
  'sync_session_refused');
select th955_test.act_as('authenticator', null);
select th955_test.refused('select public.redeem_care_invite(''SYNTH955M0001'')',
  '42501', 'Authentication required', 'redeem: a call without a caller is refused');
select th955_test.act_as('authenticator', null, 'anon');
select th955_test.refused('select public.redeem_care_invite(''SYNTH955M0001'')',
  '42501', 'permission denied for function redeem_care_invite', 'redeem: anon may not execute it');
select th955_test.act_as(current_setting('th955.superuser'), null);
select th955_test.ok(th955_test.text_hits('%synth955%') = 0,
  'redeem: no invite code appears in any column of any table in public, auth or storage');

-- Direct access as A ---------------------------------------------------------------
select th955_test.act_as('authenticator', th955_test.claims('00000000-0000-4000-8000-0000009550a1'));
select th955_test.ok(
  (select string_agg(name, ',' order by name collate "C") from public.care_orgs) =
  'Synthetic Clinic 955 A,Synthetic Clinic 955 B,Synthetic Clinic 955 M',
  'A: sees the clinics it is or was connected to, and not the clinic only B joined');
select th955_test.refused('select contact_email from public.care_orgs',
  '42501', 'permission denied%', 'A: cannot read a clinic''s contact email');
select th955_test.refused('select count(*) from public.care_invites',
  '42501', 'permission denied%', 'A: cannot read invites');
select th955_test.refused(format(
  'insert into public.care_connections (user_id, org_id) values (%L, %L)',
  '00000000-0000-4000-8000-0000009550a1', th955_test.v('org_e')),
  '42501', 'permission denied%', 'A: cannot create a connection except by redeeming a code');
select th955_test.refused('delete from public.care_connections',
  '42501', 'permission denied%', 'A: cannot delete connections');
select th955_test.refused('delete from public.care_shares',
  '42501', 'permission denied%', 'A: cannot delete shares');
select th955_test.refused('delete from public.care_share_access',
  '42501', 'permission denied%', 'A: cannot delete share access rows');
select th955_test.refused('delete from public.care_messages',
  '42501', 'permission denied%', 'A: cannot delete messages');
select th955_test.refused('delete from public.caregivers',
  '42501', 'permission denied%', 'A: cannot delete caregivers');
select th955_test.refused('delete from public.caregiver_events',
  '42501', 'permission denied%', 'A: cannot delete caregiver events');
select th955_test.refused(format(
  'insert into public.care_share_access (user_id, share_id, channel) values (%L, gen_random_uuid(), ''secure_link'')',
  '00000000-0000-4000-8000-0000009550a1'),
  '42501', 'permission denied%', 'A: cannot write share access rows');

-- Recipients of sharing consents (as A) -------------------------------------------------
select th955_test.grant_share('c_hw_a1', th955_test.v('a_hw'), 'share_care_team', th955_test.v('a1'),
  'recipient: A grants Heartwise sharing to its own live connection');
select th955_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, recipient_ref, consent_version, locale)
   values (%L, ''share_care_team'', %L, ''v1-draft'', ''en'')', th955_test.v('a_hw'), th955_test.v('bm')),
  'TH021', 'A sharing consent must name a live connection or caregiver of the same member',
  'recipient: another member''s connection is refused', 'consent_recipient_invalid');
select th955_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, recipient_ref, consent_version, locale)
   values (%L, ''share_care_team'', gen_random_uuid()::text, ''v1-draft'', ''en'')', th955_test.v('a_hw')),
  'TH021', 'A sharing consent must name%', 'recipient: a random uuid is refused', 'consent_recipient_invalid');
select th955_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, recipient_ref, consent_version, locale)
   values (%L, ''share_care_team'', ''synthetic-recipient'', ''v1-draft'', ''en'')', th955_test.v('a_hw')),
  'TH021', 'A sharing consent must name%', 'recipient: text that is not a uuid is refused', 'consent_recipient_invalid');
select th955_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, recipient_ref, consent_version, locale)
   values (%L, ''share_care_team'', %L, ''v1-draft'', ''en'')', th955_test.v('a_st'), upper(th955_test.v('a1'))),
  'TH021', 'A sharing consent must name%', 'recipient: an upper-case uuid of A''s own connection is refused',
  'consent_recipient_invalid');
select th955_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, recipient_ref, consent_version, locale)
   values (%L, ''share_care_team'', %L, ''v1-draft'', ''en'')', th955_test.v('a_hw'), th955_test.v('ab')),
  'TH021', 'A sharing consent must name%', 'recipient: A''s revoked connection is refused', 'consent_recipient_invalid');
select th955_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
   values (%L, ''share_care_team'', ''v1-draft'', ''en'')', th955_test.v('a_hw')),
  '23514', '%programme_consents_recipient_check%', 'recipient: a sharing consent without a recipient fails its check constraint');
select th955_test.add_caregiver('g1', th955_test.v('a_sd'), '{sd.session_finished}',
  'caregiver: A adds a caregiver to its Stride enrolment');
select th955_test.refused(format(
  'insert into public.caregivers (user_id, enrolment_id, name, phone) values (%L, %L, ''Synthetic Caregiver'', ''+15550100001'')',
  '00000000-0000-4000-8000-0000009550a1', th955_test.v('a_hw')),
  '42501', '%row-level security%', 'caregiver: refused on a programme other than Stride');
select th955_test.grant_share('c_sd_g1', th955_test.v('a_sd'), 'share_caregiver', th955_test.v('g1'),
  'recipient: A grants caregiver sharing on Stride to its live caregiver');
select th955_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, recipient_ref, consent_version, locale)
   values (%L, ''share_caregiver'', %L, ''v1-draft'', ''en'')', th955_test.v('a_hw'), th955_test.v('g1')),
  'TH021', 'A sharing consent must name%', 'recipient: a caregiver of another enrolment is refused',
  'consent_recipient_invalid');
select th955_test.add_caregiver('g2', th955_test.v('a_sd'), '{sd.session_finished,sd.fall_logged}',
  'caregiver: A adds a second caregiver');
select th955_test.affects(format(
  'update public.caregivers set revoked_at = now() where id = %L', th955_test.v('g2')),
  1, 'caregiver: A revokes the second caregiver');
select th955_test.refused(format(
  'insert into public.programme_consents (enrolment_id, purpose, recipient_ref, consent_version, locale)
   values (%L, ''share_caregiver'', %L, ''v1-draft'', ''en'')', th955_test.v('a_sd'), th955_test.v('g2')),
  'TH021', 'A sharing consent must name%', 'recipient: a revoked caregiver is refused', 'consent_recipient_invalid');

-- Shares (as A) ---------------------------------------------------------------------------
select th955_test.add_share('s1', th955_test.v('a_hw'), th955_test.v('a1'), th955_test.v('c_hw_a1'),
  'visit_summary', 'share: A shares a Heartwise summary under the live consent');
select th955_test.ok(
  (select expires_at = created_at + interval '30 days' and revoked_at is null
   from public.care_shares where id = th955_test.v('s1')::uuid),
  'share: expires 30 days after it was created by default');
select th955_test.grant_share('c_st', th955_test.v('a_st'), 'share_care_team', th955_test.v('a1'),
  'recipient: A grants Steady sharing to its connection');
select th955_test.affects(format(
  'update public.programme_consents set revoked_at = now() where id = %L', th955_test.v('c_st')),
  1, 'A: revokes the Steady sharing consent');
select th955_test.refused(format(
  'insert into public.care_shares (user_id, enrolment_id, connection_id, consent_id, kind, snapshot)
   values (auth.uid(), %L, %L, %L, ''visit_summary'', ''{}'')', th955_test.v('a_st'), th955_test.v('a1'), th955_test.v('c_st')),
  'TH022', 'A live sharing consent for this recipient is required', 'share: a revoked consent is refused',
  'care_consent_required');
select th955_test.grant_share('c_st2', th955_test.v('a_st'), 'share_care_team', th955_test.v('a1'),
  'recipient: A grants Steady sharing again');
select th955_test.refused(format(
  'insert into public.care_shares (user_id, enrolment_id, connection_id, consent_id, kind, snapshot)
   values (auth.uid(), %L, %L, %L, ''visit_summary'', ''{}'')', th955_test.v('a_hw'), th955_test.v('a1'), th955_test.v('c_st2')),
  'TH022', 'A live sharing consent%', 'share: a consent of a sibling enrolment is refused', 'care_consent_required');
select th955_test.grant_share('c_hw_am', th955_test.v('a_hw'), 'share_care_team', th955_test.v('am'),
  'recipient: A grants Heartwise sharing to its second connection');
select th955_test.refused(format(
  'insert into public.care_shares (user_id, enrolment_id, connection_id, consent_id, kind, snapshot)
   values (auth.uid(), %L, %L, %L, ''visit_summary'', ''{}'')', th955_test.v('a_hw'), th955_test.v('a1'), th955_test.v('c_hw_am')),
  'TH022', 'A live sharing consent%', 'share: a consent for another connection is refused', 'care_consent_required');
select th955_test.refused(format(
  'insert into public.care_shares (user_id, enrolment_id, connection_id, consent_id, kind, snapshot)
   values (auth.uid(), %L, %L, %L, ''visit_summary'', ''{}'')', th955_test.v('a_hw'), th955_test.v('ab'), th955_test.v('c_hw_a1')),
  'TH022', 'A live sharing consent%', 'share: a revoked connection is refused', 'care_consent_required');
select th955_test.refused(format(
  'insert into public.care_shares (user_id, enrolment_id, connection_id, consent_id, kind, snapshot)
   values (auth.uid(), %L, %L, %L, ''visit_summary'', jsonb_build_object(''x'', repeat(''a'', 70000)))',
  th955_test.v('a_hw'), th955_test.v('a1'), th955_test.v('c_hw_a1')),
  '23514', '%care_shares_snapshot_check%', 'share: a snapshot over 64 KiB is refused');
select th955_test.refused(format(
  'insert into public.care_shares (user_id, enrolment_id, connection_id, consent_id, kind, snapshot, expires_at)
   values (auth.uid(), %L, %L, %L, ''visit_summary'', ''{}'', now() + interval ''31 days'')',
  th955_test.v('a_hw'), th955_test.v('a1'), th955_test.v('c_hw_a1')),
  '23514', '%care_shares_expires_check%', 'share: an expiry 31 days away is refused');
select th955_test.refused(format(
  'insert into public.care_shares (user_id, enrolment_id, connection_id, consent_id, kind, snapshot, expires_at)
   values (auth.uid(), %L, %L, %L, ''visit_summary'', ''{}'', now() + interval ''30 days 1 hour'')',
  th955_test.v('a_hw'), th955_test.v('a1'), th955_test.v('c_hw_a1')),
  '23514', '%care_shares_expires_check%', 'share: an expiry 30 days and 1 hour away is refused');
select th955_test.act_as('thsync', th955_test.claims('00000000-0000-4000-8000-0000009550a1'));
select th955_test.refused(format(
  'insert into public.care_shares (user_id, enrolment_id, connection_id, consent_id, kind, snapshot)
   values (auth.uid(), %L, %L, %L, ''visit_summary'', ''{}'')', th955_test.v('a_hw'), th955_test.v('a1'), th955_test.v('c_hw_a1')),
  'TH022', 'A live sharing consent%', 'share: a sync service session cannot share (it cannot lock the consent)',
  'care_consent_required');
select th955_test.act_as(current_setting('th955.superuser'), null);
select th955_test.ok(
  (select count(*) from public.care_shares where user_id = '00000000-0000-4000-8000-0000009550a1') = 1,
  'share: the refused shares wrote nothing');
insert into public.care_share_access (user_id, share_id, channel)
values ('00000000-0000-4000-8000-0000009550a1', th955_test.v('s1')::uuid, 'secure_link');
select th955_test.act_as('authenticator', th955_test.claims('00000000-0000-4000-8000-0000009550b1'));
select th955_test.ok(
  (select count(*) from public.care_shares) = 0
  and (select count(*) from public.care_share_access) = 0
  and (select count(*) from public.care_connections) = 3
  and (select count(*) from public.programme_consents
       where purpose in ('share_care_team', 'share_caregiver')) = 0,
  'B: sees none of A''s shares, access rows, connections or sharing consents');
select th955_test.affects(format(
  'update public.care_shares set revoked_at = now() where id = %L', th955_test.v('s1')),
  0, 'B: cannot revoke A''s share (no row qualifies)');
select th955_test.act_as('authenticator', th955_test.claims('00000000-0000-4000-8000-0000009550a1'));
select th955_test.ok((select count(*) from public.care_share_access) = 1,
  'A: reads the access row of its own share');

-- Messages (as A) ----------------------------------------------------------------------------
select th955_test.affects(format(
  'insert into public.care_messages (user_id, connection_id, topic, body)
   values (%L, %L, ''Synthetic topic'', ''Synthetic message'')',
  '00000000-0000-4000-8000-0000009550a1', th955_test.v('a1')),
  1, 'message: A writes to its live connection');
select th955_test.affects(format(
  'insert into public.care_messages (user_id, connection_id, enrolment_id, topic, body)
   values (%L, %L, %L, ''Synthetic topic'', ''Synthetic Heartwise message'')',
  '00000000-0000-4000-8000-0000009550a1', th955_test.v('a1'), th955_test.v('a_hw')),
  1, 'message: about Heartwise, with its sharing consent for the connection');
select th955_test.refused(format(
  'insert into public.care_messages (user_id, connection_id, topic, body)
   values (%L, %L, ''Synthetic topic'', ''Synthetic message'')',
  '00000000-0000-4000-8000-0000009550a1', th955_test.v('ab')),
  '42501', '%row-level security%', 'message: a revoked connection is refused');
select th955_test.refused(format(
  'insert into public.care_messages (user_id, connection_id, enrolment_id, topic, body)
   values (%L, %L, %L, ''Synthetic topic'', ''Synthetic message'')',
  '00000000-0000-4000-8000-0000009550a1', th955_test.v('a1'), th955_test.v('a_sd')),
  '42501', '%row-level security%', 'message: an enrolment without a sharing consent for the connection is refused');
select th955_test.add_share('s3', th955_test.v('a_hw'), th955_test.v('am'), th955_test.v('c_hw_am'),
  'message_attachment', 'share: A prepares an attachment for its second connection');
select th955_test.add_share('s4', th955_test.v('a_hw'), th955_test.v('a1'), th955_test.v('c_hw_a1'),
  'message_attachment', 'share: A prepares a Heartwise attachment for its first connection');
select th955_test.refused(format(
  'insert into public.care_messages (user_id, connection_id, enrolment_id, topic, body, share_id)
   values (%L, %L, %L, ''Synthetic topic'', ''Synthetic message'', %L)',
  '00000000-0000-4000-8000-0000009550a1', th955_test.v('a1'), th955_test.v('a_hw'), th955_test.v('s3')),
  '42501', '%row-level security%', 'message: another connection''s share is refused');
select th955_test.refused(format(
  'insert into public.care_messages (user_id, connection_id, enrolment_id, topic, body, share_id)
   values (%L, %L, %L, ''Synthetic topic'', ''Synthetic message'', %L)',
  '00000000-0000-4000-8000-0000009550a1', th955_test.v('a1'), th955_test.v('a_st'), th955_test.v('s4')),
  '42501', '%row-level security%', 'message: an enrolment other than the attached share''s is refused');
select th955_test.refused(format(
  'insert into public.care_messages (user_id, connection_id, topic, body, share_id)
   values (%L, %L, ''Synthetic topic'', ''Synthetic message'', %L)',
  '00000000-0000-4000-8000-0000009550a1', th955_test.v('a1'), th955_test.v('s4')),
  '42501', '%row-level security%', 'message: an attachment without an enrolment is refused');
select th955_test.act_as(current_setting('th955.superuser'), null);
with i as (
  insert into public.care_shares (user_id, enrolment_id, connection_id, consent_id, kind, snapshot,
                                  created_at, expires_at)
  values ('00000000-0000-4000-8000-0000009550a1', th955_test.v('a_hw')::uuid, th955_test.v('a1')::uuid,
          th955_test.v('c_hw_a1')::uuid, 'message_attachment', '{"summary": "synthetic"}',
          now() - interval '31 days', now() - interval '1 day')
  returning id
) select set_config('th955.s_expired', id::text, true) from i;
select th955_test.act_as('authenticator', th955_test.claims('00000000-0000-4000-8000-0000009550a1'));
select th955_test.refused(format(
  'insert into public.care_messages (user_id, connection_id, enrolment_id, topic, body, share_id)
   values (%L, %L, %L, ''Synthetic topic'', ''Synthetic message'', %L)',
  '00000000-0000-4000-8000-0000009550a1', th955_test.v('a1'), th955_test.v('a_hw'), th955_test.v('s_expired')),
  '42501', '%row-level security%', 'message: an expired attachment is refused');
select th955_test.affects(format(
  'insert into public.care_messages (user_id, connection_id, enrolment_id, topic, body, share_id)
   values (%L, %L, %L, ''Synthetic topic'', ''Synthetic message with attachment'', %L)',
  '00000000-0000-4000-8000-0000009550a1', th955_test.v('a1'), th955_test.v('a_hw'), th955_test.v('s4')),
  1, 'message: A attaches its own live Heartwise share on the same connection');
select th955_test.act_as(current_setting('th955.superuser'), null);
select th955_test.refused(format(
  'insert into public.care_messages (user_id, connection_id, topic, body, share_id)
   values (%L, %L, ''Synthetic topic'', ''Synthetic message'', %L)',
  '00000000-0000-4000-8000-0000009550a1', th955_test.v('a1'), th955_test.v('s4')),
  '23514', '%care_messages_share_enrolment_check%',
  'message: as the owner, an attachment without an enrolment fails its check constraint');

-- Caregiver events (as A) ------------------------------------------------------------------
select th955_test.act_as('authenticator', th955_test.claims('00000000-0000-4000-8000-0000009550a1'));
select th955_test.affects(format(
  'insert into public.caregiver_events (user_id, caregiver_id, kind, occurred_at)
   values (%L, %L, ''sd.session_finished'', now())', '00000000-0000-4000-8000-0000009550a1', th955_test.v('g1')),
  1, 'caregiver event: in scope with a live consent');
select th955_test.refused(format(
  'insert into public.caregiver_events (user_id, caregiver_id, kind, occurred_at)
   values (%L, %L, ''sd.fall_logged'', now())', '00000000-0000-4000-8000-0000009550a1', th955_test.v('g1')),
  '42501', '%row-level security%', 'caregiver event: a kind outside the caregiver''s scope is refused');
select th955_test.add_caregiver('g3', th955_test.v('a_sd'), '{sd.session_finished}',
  'caregiver: A adds a third caregiver without a consent');
select th955_test.refused(format(
  'insert into public.caregiver_events (user_id, caregiver_id, kind, occurred_at)
   values (%L, %L, ''sd.session_finished'', now())', '00000000-0000-4000-8000-0000009550a1', th955_test.v('g3')),
  'TH022', 'A live sharing consent%', 'caregiver event: refused without a live consent naming the caregiver',
  'care_consent_required');
select th955_test.affects(format(
  'update public.caregivers set invite_status = ''sent'' where id = %L', th955_test.v('g1')),
  1, 'caregiver: the invite moves from pending to sent');
select th955_test.refused(format(
  'update public.caregivers set invite_status = ''pending'' where id = %L', th955_test.v('g1')),
  'TH023', 'Care records can only be revoked', 'caregiver: the invite cannot move back to pending',
  'care_record_immutable');

-- Immutability (as the owner) ----------------------------------------------------------------
select th955_test.act_as(current_setting('th955.superuser'), null);
select th955_test.refused(format(
  'update public.care_shares set snapshot = ''{"summary": "changed"}'' where id = %L', th955_test.v('s4')),
  'TH023', 'Care records can only be revoked', 'immutability: a share''s snapshot cannot change', 'care_record_immutable');
select th955_test.refused(format(
  'update public.care_connections set org_id = %L where id = %L', th955_test.v('org_b'), th955_test.v('a1')),
  'TH023', 'Care records can only be revoked', 'immutability: a connection''s clinic cannot change', 'care_record_immutable');
select th955_test.refused(format(
  'update public.caregivers set name = ''Changed Name'' where id = %L', th955_test.v('g1')),
  'TH023', 'Care records can only be revoked', 'immutability: a caregiver''s name cannot change', 'care_record_immutable');
select th955_test.refused('update public.care_messages set topic = ''Changed''',
  'TH023', 'Care records can only be revoked', 'immutability: messages are append-only', 'care_record_immutable');
select th955_test.refused('update public.care_share_access set channel = ''secure_link''',
  'TH023', 'Care records can only be revoked', 'immutability: share access rows are append-only', 'care_record_immutable');
select th955_test.refused('update public.caregiver_events set occurred_at = now()',
  'TH023', 'Care records can only be revoked', 'immutability: caregiver events are append-only', 'care_record_immutable');

-- Revocation cascades (as A) ---------------------------------------------------------------
select th955_test.act_as('authenticator', th955_test.claims('00000000-0000-4000-8000-0000009550a1'));
select th955_test.affects(format(
  'update public.programme_consents set revoked_at = now() where id = %L', th955_test.v('c_hw_a1')),
  1, 'A: revokes the Heartwise sharing consent for its first connection');
select th955_test.act_as(current_setting('th955.superuser'), null);
select th955_test.ok(
  (select count(*) from public.care_shares
   where id in (th955_test.v('s1')::uuid, th955_test.v('s4')::uuid) and revoked_at is not null) = 2
  and (select revoked_at is null from public.care_shares where id = th955_test.v('s3')::uuid),
  'cascade: revoking a sharing consent revokes its shares, and only those');
select th955_test.refused(format(
  'update public.care_shares set revoked_at = null where id = %L', th955_test.v('s1')),
  'TH023', 'Care records can only be revoked', 'immutability: a revoked share cannot be un-revoked', 'care_record_immutable');
select th955_test.act_as('authenticator', th955_test.claims('00000000-0000-4000-8000-0000009550a1'));
select th955_test.affects(format(
  'update public.care_connections set revoked_at = now() where id = %L', th955_test.v('am')),
  1, 'A: revokes its second connection');
select th955_test.affects(format(
  'update public.caregivers set revoked_at = now() where id = %L', th955_test.v('g1')),
  1, 'A: revokes its caregiver');
select th955_test.act_as(current_setting('th955.superuser'), null);
select th955_test.ok(
  (select revoked_at is not null from public.programme_consents where id = th955_test.v('c_hw_am')::uuid)
  and (select revoked_at is not null from public.care_shares where id = th955_test.v('s3')::uuid),
  'cascade: revoking a connection revokes the consents that name it and its shares');
select th955_test.ok(
  (select revoked_at is not null from public.programme_consents where id = th955_test.v('c_sd_g1')::uuid),
  'cascade: revoking a caregiver revokes the consent that names it');
select th955_test.act_as('authenticator', th955_test.claims('00000000-0000-4000-8000-0000009550a1'));
select th955_test.grant_share('c_nu', th955_test.v('a_nu'), 'share_care_team', th955_test.v('a1'),
  'recipient: A grants Nourish sharing');
select th955_test.add_share('s5', th955_test.v('a_nu'), th955_test.v('a1'), th955_test.v('c_nu'),
  'visit_summary', 'share: A shares a Nourish summary');
select th955_test.affects(format(
  'update public.programme_consents set revoked_at = now() where enrolment_id = %L and purpose = ''core''',
  th955_test.v('a_nu')), 1, 'A: revokes the Nourish core consent');
select th955_test.grant_share('c_ca', th955_test.v('a_ca'), 'share_care_team', th955_test.v('a1'),
  'recipient: A grants ClearAir sharing');
select th955_test.add_share('s6', th955_test.v('a_ca'), th955_test.v('a1'), th955_test.v('c_ca'),
  'visit_summary', 'share: A shares a ClearAir summary');
select th955_test.affects(format(
  'update public.enrolments set status = ''left'' where id = %L', th955_test.v('a_ca')),
  1, 'A: leaves ClearAir');
select th955_test.act_as(current_setting('th955.superuser'), null);
select th955_test.ok(
  (select revoked_at is not null from public.programme_consents where id = th955_test.v('c_nu')::uuid)
  and (select revoked_at is not null from public.care_shares where id = th955_test.v('s5')::uuid),
  'cascade: revoking core revokes the sharing consent and its shares');
select th955_test.ok(
  (select revoked_at is not null from public.programme_consents where id = th955_test.v('c_ca')::uuid)
  and (select revoked_at is not null from public.care_shares where id = th955_test.v('s6')::uuid),
  'cascade: leaving revokes the sharing consent and its shares');
select th955_test.no_orphans('after the revocation, core-revoke and leave cascades');

-- Supporters ------------------------------------------------------------------------------
select th955_test.act_as('authenticator', th955_test.claims('00000000-0000-4000-8000-0000009550a1'));
select th955_test.affects(
  'insert into public.supporters (user_id, name, phone, programme_codes, help_phrase)
   values (''00000000-0000-4000-8000-0000009550a1'', ''Synthetic Supporter'', ''+15550100002'', ''{bf}'', ''Synthetic phrase'')',
  1, 'supporter: A lists BreatheFree, which it is enrolled in');
select th955_test.refused(
  'insert into public.supporters (user_id, name, phone, programme_codes)
   values (''00000000-0000-4000-8000-0000009550a1'', ''Synthetic Supporter'', ''+15550100002'', ''{sf}'')',
  '42501', '%row-level security%', 'supporter: a programme A is not enrolled in is refused');
select th955_test.refused(
  'insert into public.supporters (user_id, name, phone, programme_codes)
   values (''00000000-0000-4000-8000-0000009550a1'', ''Synthetic Supporter'', ''+15550100002'', ''{hw}'')',
  '42501', '%row-level security%', 'supporter: a programme other than bf or sf is refused by the policy');
select th955_test.act_as(current_setting('th955.superuser'), null);
select th955_test.refused(
  'insert into public.supporters (user_id, name, phone, programme_codes)
   values (''00000000-0000-4000-8000-0000009550a1'', ''Synthetic Supporter'', ''+15550100002'', ''{hw}'')',
  '23514', '%supporters_programme_codes_check%', 'supporter: as the owner, {hw} fails its check constraint');
select th955_test.act_as('thsync', th955_test.claims('00000000-0000-4000-8000-0000009550a1'));
select th955_test.refused(
  'insert into public.supporters (user_id, name, phone, programme_codes)
   values (''00000000-0000-4000-8000-0000009550a1'', ''Synthetic Supporter'', ''+15550100002'', ''{bf}'')',
  '42501', '%row-level security%', 'supporter: a sync service session cannot add one');
select th955_test.act_as('authenticator', th955_test.claims('00000000-0000-4000-8000-0000009550a1'));
select th955_test.affects(
  'insert into public.enrolments (user_id, programme_code, status)
   values (''00000000-0000-4000-8000-0000009550a1'', ''sf'', ''learn_only'')',
  1, 'A: enrols in ScrollFree');
select th955_test.affects(
  'update public.supporters set programme_codes = ''{bf,sf}''', 1, 'supporter: A adds ScrollFree');
select th955_test.act_as('authenticator', th955_test.claims('00000000-0000-4000-8000-0000009550b1'));
select th955_test.affects(
  'insert into public.supporters (user_id, name, phone, programme_codes)
   values (''00000000-0000-4000-8000-0000009550b1'', ''Synthetic Supporter B'', ''+15550100004'', ''{bf}'')',
  1, 'supporter: B lists BreatheFree');
select th955_test.act_as('authenticator', th955_test.claims('00000000-0000-4000-8000-0000009550a1'));
select th955_test.affects(format(
  'update public.enrolments set status = ''left'' where id = %L', th955_test.v('a_bf')),
  1, 'A: leaves BreatheFree');
select th955_test.ok(
  (select programme_codes = '{sf}'::text[] from public.supporters), 'supporter: leaving removed bf');
select th955_test.affects(format(
  'select public.delete_enrolment_now(%L, ''DELETE'')',
  (select id from public.enrolments
   where user_id = '00000000-0000-4000-8000-0000009550a1' and programme_code = 'sf')),
  1, 'A: deletes ScrollFree now');
select th955_test.act_as(current_setting('th955.superuser'), null);
select th955_test.ok(
  (select programme_codes = '{}'::text[] from public.supporters
   where user_id = '00000000-0000-4000-8000-0000009550a1')
  and (select programme_codes = '{bf}'::text[] from public.supporters
       where user_id = '00000000-0000-4000-8000-0000009550b1'),
  'supporter: delete-now removed sf; B''s supporter is untouched');
select th955_test.act_as('authenticator', th955_test.claims('00000000-0000-4000-8000-0000009550b1'));
select th955_test.affects(
  'delete from public.supporters where user_id = ''00000000-0000-4000-8000-0000009550a1''',
  0, 'B: cannot delete A''s supporter (no row qualifies)');
select th955_test.act_as('authenticator', th955_test.claims('00000000-0000-4000-8000-0000009550a1'));
select th955_test.affects('delete from public.supporters', 1, 'supporter: A deletes its own supporter');
select th955_test.affects(
  'insert into public.supporters (user_id, name, phone)
   values (''00000000-0000-4000-8000-0000009550a1'', ''Synthetic Supporter'', ''+15550100002'')',
  1, 'supporter: A lists a supporter for no programme');

-- Delete-now with an attached share (as A) ---------------------------------------------------
select th955_test.grant_share('c_ck', th955_test.v('a_ck'), 'share_care_team', th955_test.v('a1'),
  'recipient: A grants Checkup sharing');
select th955_test.add_share('s7', th955_test.v('a_ck'), th955_test.v('a1'), th955_test.v('c_ck'),
  'message_attachment', 'share: A prepares a Checkup attachment');
select th955_test.affects(format(
  'insert into public.care_messages (user_id, connection_id, enrolment_id, topic, body, share_id)
   values (%L, %L, %L, ''Synthetic topic'', ''Synthetic Checkup message'', %L)',
  '00000000-0000-4000-8000-0000009550a1', th955_test.v('a1'), th955_test.v('a_ck'), th955_test.v('s7')),
  1, 'message: A attaches the Checkup share');
select th955_test.act_as(current_setting('th955.superuser'), null);
insert into public.care_share_access (user_id, share_id, channel)
values ('00000000-0000-4000-8000-0000009550a1', th955_test.v('s7')::uuid, 'secure_link');
select th955_test.act_as('authenticator', th955_test.claims('00000000-0000-4000-8000-0000009550a1'));
select th955_test.affects(format(
  'select public.delete_enrolment_now(%L, ''DELETE'')', th955_test.v('a_ck')),
  1, 'delete-now: A deletes Checkup, whose share is attached to a message');
select th955_test.act_as(current_setting('th955.superuser'), null);
select th955_test.ok(
  (select count(*) from public.care_shares where id = th955_test.v('s7')::uuid) = 0
  and (select count(*) from public.care_messages where share_id = th955_test.v('s7')::uuid
       or enrolment_id = th955_test.v('a_ck')::uuid) = 0
  and (select count(*) from public.care_share_access where share_id = th955_test.v('s7')::uuid) = 0
  and (select count(*) from public.programme_consents where id = th955_test.v('c_ck')::uuid) = 0,
  'delete-now: the share, its message, its access row and the consent are gone');
select th955_test.no_orphans('after delete-now');
select th955_test.refused(format(
  'delete from public.care_invites where org_id = %L', th955_test.v('org_a')),
  '23503', '%care_connections%', 'invites: an invite a connection used cannot be deleted');
select th955_test.ok(
  (select count(*) from public.care_invites where org_id = th955_test.v('org_a')::uuid) = 1,
  'invites: the refused delete changed nothing');

-- The deletion barrier (B) -------------------------------------------------------------------
select th955_test.act_as('authenticator', th955_test.claims('00000000-0000-4000-8000-0000009550b1'));
select th955_test.grant_share('c_b_hw', th955_test.v('b_hw'), 'share_care_team', th955_test.v('bm'),
  'recipient: B grants Heartwise sharing to its connection');
select th955_test.ok(public.begin_account_deletion('DELETE'), 'B: begin_account_deletion sets the barrier');
select th955_test.refused(format(
  'insert into public.care_shares (user_id, enrolment_id, connection_id, consent_id, kind, snapshot)
   values (auth.uid(), %L, %L, %L, ''visit_summary'', ''{}'')', th955_test.v('b_hw'), th955_test.v('bm'), th955_test.v('c_b_hw')),
  '42501', '%row-level security%', 'barrier: B cannot share once deletion has started');
select th955_test.refused(format(
  'insert into public.care_messages (user_id, connection_id, topic, body)
   values (%L, %L, ''Synthetic topic'', ''Synthetic message'')', '00000000-0000-4000-8000-0000009550b1', th955_test.v('bm')),
  '42501', '%row-level security%', 'barrier: B cannot message once deletion has started');
select th955_test.refused(
  'insert into public.supporters (user_id, name, phone)
   values (''00000000-0000-4000-8000-0000009550b1'', ''Synthetic Supporter B'', ''+15550100004'')',
  '42501', '%row-level security%', 'barrier: B cannot add a supporter once deletion has started');
select th955_test.refused('select public.redeem_care_invite(''SYNTH955M0001'')',
  'TH006', 'Account deletion has started', 'redeem: refused once deletion has started', 'deletion_in_progress');

-- Truncate guards (as the owner) ---------------------------------------------------------
select th955_test.act_as(current_setting('th955.superuser'), null);
select set_config('th955.fingerprint', (
  select string_agg(n::text, ',') from (
    select count(*) as n from public.care_connections union all
    select count(*) from public.care_shares union all
    select count(*) from public.care_share_access union all
    select count(*) from public.care_messages union all
    select count(*) from public.caregivers union all
    select count(*) from public.caregiver_events) as x), true);
select th955_test.refused('truncate public.care_share_access',
  'TH024', 'Care rows are removed only with their programme or account',
  'truncate: care_share_access is refused', 'care_rows_delete_only');
select th955_test.refused('truncate public.care_messages',
  'TH024', 'Care rows are removed only%', 'truncate: care_messages is refused', 'care_rows_delete_only');
select th955_test.refused('truncate public.caregiver_events',
  'TH024', 'Care rows are removed only%', 'truncate: caregiver_events is refused', 'care_rows_delete_only');
select th955_test.refused('truncate public.care_connections',
  '0A000', 'cannot truncate a table referenced in a foreign key constraint',
  'truncate: care_connections without cascade is refused by its foreign keys');
select th955_test.refused('truncate public.care_shares',
  '0A000', 'cannot truncate a table referenced in a foreign key constraint',
  'truncate: care_shares without cascade is refused by its foreign keys');
select th955_test.refused('truncate public.caregivers',
  '0A000', 'cannot truncate a table referenced in a foreign key constraint',
  'truncate: caregivers without cascade is refused by its foreign keys');
select th955_test.refused('truncate public.care_connections cascade',
  'TH024', 'Care rows are removed only%', 'truncate: care_connections cascade is refused', 'care_rows_delete_only');
select th955_test.refused('truncate public.care_connections, public.care_shares, public.care_share_access,
   public.care_messages, public.caregivers, public.caregiver_events',
  'TH024', 'Care rows are removed only%', 'truncate: all six guarded tables together are refused', 'care_rows_delete_only');
set local session_replication_role = replica;
select th955_test.refused('truncate public.care_messages',
  'TH024', 'Care rows are removed only%', 'truncate: refused in a replica session too', 'care_rows_delete_only');
set local session_replication_role = origin;
select th955_test.refused('truncate auth.users cascade',
  'TH003', 'Consent records are immutable', 'truncate: auth.users cascade is still refused');
select th955_test.ok(
  (select string_agg(n::text, ',') from (
    select count(*) as n from public.care_connections union all
    select count(*) from public.care_shares union all
    select count(*) from public.care_share_access union all
    select count(*) from public.care_messages union all
    select count(*) from public.caregivers union all
    select count(*) from public.caregiver_events) as x) = th955_test.v('fingerprint'),
  'truncate: the refused truncates left every care row in place');

-- Stored sharing consents (the migration's revocation block, re-run) -------------------------
alter table public.programme_consents disable trigger programme_consents_check_recipient;
with i as (
  insert into public.programme_consents (enrolment_id, purpose, recipient_ref, consent_version, locale)
  values (th955_test.v('a_hw')::uuid, 'share_care_team', 'synthetic-legacy-recipient', 'v1-draft', 'en')
  returning id
) select set_config('th955.legacy', id::text, true) from i;
alter table public.programme_consents enable trigger programme_consents_check_recipient;
select set_config('th955.share_consents', (
  select count(*)::text from public.programme_consents
  where purpose in ('share_care_team', 'share_caregiver')), true);
select th955_test.ok(
  (select count(*) from public.programme_consents
   where purpose in ('share_care_team', 'share_caregiver') and revoked_at is null) = 3,
  'legacy: one unbound live sharing consent is seeded next to two live bound ones');
SQL
  legacy_block
  cat <<'SQL'
select th955_test.ok(
  not exists (select 1 from public.programme_consents
              where purpose in ('share_care_team', 'share_caregiver') and revoked_at is null)
  and (select revoked_at is not null from public.programme_consents where id = th955_test.v('legacy')::uuid)
  and (select count(*)::text from public.programme_consents
       where purpose in ('share_care_team', 'share_caregiver')) = th955_test.v('share_consents'),
  'legacy: the block revokes every live sharing consent and deletes none');
select th955_test.no_orphans('after the legacy revocation');
create role th955_nobypass nologin;
grant usage on schema th955_test to th955_nobypass;
set local role th955_nobypass;
select th955_test.refused($legacy$
SQL
  legacy_block
  cat <<'SQL'
$legacy$, 'P0001', 'Revoking stored share consents needs a migration role that bypasses row-level security',
  'legacy: the block refuses to run under a role without row-level security bypass');
reset role;

-- Account deletion end to end (A) ---------------------------------------------------------
select set_config('th955.a_before', th955_test.counts('00000000-0000-4000-8000-0000009550a1')::text, true);
select set_config('th955.b_before', th955_test.state('00000000-0000-4000-8000-0000009550b1')::text, true);
select set_config('th955.clinics', (
  select count(*) || ':' || sum(uses) from public.care_invites) || ':' || (select count(*) from public.care_orgs), true);
select th955_test.ok(
  (select count(*) = 17 and bool_and(value::text::integer >= 1)
   from jsonb_each(th955_test.v('a_before')::jsonb)),
  'deletion setup: A holds rows in every member table, the seven care tables included');
select th955_test.act_as('authenticator', th955_test.claims('00000000-0000-4000-8000-0000009550a1'));
select th955_test.ok(public.begin_account_deletion('DELETE'), 'A: begin_account_deletion sets the barrier');
select set_config('th955.a_receipt', public.delete_my_account('DELETE')::text, true);
select th955_test.act_as(current_setting('th955.superuser'), null);
select th955_test.ok(
  th955_test.v('a_receipt')::jsonb = th955_test.v('a_before')::jsonb
  and (select count(*) from jsonb_object_keys(th955_test.v('a_receipt')::jsonb)) = 17,
  'deletion: delete_my_account returns the 17 counts of the rows A held');
select th955_test.ok(
  (select bool_and(value in ('0'::jsonb, 'null'::jsonb))
   from jsonb_each(th955_test.state('00000000-0000-4000-8000-0000009550a1'))),
  'deletion: no row of A is left in any member table, and no identity');
select th955_test.ok(
  th955_test.state('00000000-0000-4000-8000-0000009550b1') = th955_test.v('b_before')::jsonb
  and (select count(*) || ':' || sum(uses) from public.care_invites) || ':'
      || (select count(*) from public.care_orgs) = th955_test.v('clinics'),
  'deletion: B, the clinics and the invites are untouched');
select th955_test.act_as('authenticator', th955_test.claims('00000000-0000-4000-8000-0000009550a1'));
select set_config('th955.a_repeat', public.delete_my_account('DELETE')::text, true);
select th955_test.act_as(current_setting('th955.superuser'), null);
select th955_test.ok(
  (select count(*) = 17 and bool_and(value = '0'::jsonb)
   from jsonb_each(th955_test.v('a_repeat')::jsonb)),
  'deletion: a repeat returns 17 zero counts');
select th955_test.ok(
  not pg_catalog.has_function_privilege('authenticated', 'public.delete_my_app_data(text)', 'EXECUTE')
  and pg_catalog.obj_description('public.delete_my_app_data(text)'::regprocedure, 'pg_proc')
      = 'Deletes the calling member app-owned rows in public and returns counts only. Only its owner may execute it: members reach it through delete_my_account, which also deletes the Auth identity.',
  'deletion: delete_my_app_data is still executable by its owner only, with the same comment');
select th955_test.no_orphans('after account deletion');

-- Identity deleted by a role with no privilege in public (C) -----------------------------
create role th955_auth_admin nologin;
grant usage on schema auth to th955_auth_admin;
grant select, delete on auth.users to th955_auth_admin;
select th955_test.ok(
  not pg_catalog.has_table_privilege('th955_auth_admin', 'public.supporters', 'UPDATE')
  and not pg_catalog.has_table_privilege('th955_auth_admin', 'public.enrolments', 'DELETE')
  and not pg_catalog.has_function_privilege('th955_auth_admin', 'public.supporters_drop_programme()', 'EXECUTE')
  and (select programme_codes = '{bf}'::text[] from public.supporters
       where user_id = '00000000-0000-4000-8000-0000009550c1'),
  'identity delete: the stand-in holds no privilege on supporters or enrolments; C''s supporter lists bf');
set local role th955_auth_admin;
delete from auth.users where id = '00000000-0000-4000-8000-0000009550c1';
reset role;
select th955_test.ok(
  (select bool_and(value in ('0'::jsonb, 'null'::jsonb))
   from jsonb_each(th955_test.state('00000000-0000-4000-8000-0000009550c1'))),
  'identity delete: cascades through the enrolment trigger and leaves no row of C');

select 'TH955_SQL_TESTS_COMPLETE' as result;
rollback;
SQL
}

print_control_sql() {
  cat <<'SQL'
begin;

do $setup$
begin
  if not coalesce((select rolsuper from pg_catalog.pg_roles where rolname = current_user), false) then
    raise exception 'CONTROL setup: this control needs a superuser connection';
  end if;
end;
$setup$;

create schema th955_control;

-- Synthetic E with a live core consent on Heartwise. No care table is
-- touched, so the control runs on trees with or without the care migration.
insert into auth.users (id, email, aud, role) values
  ('00000000-0000-4000-8000-0000009550e1', 'synthetic-control-955e@example.test', 'authenticated', 'authenticated');
with i as (
  insert into public.enrolments (user_id, programme_code, status)
  values ('00000000-0000-4000-8000-0000009550e1', 'hw', 'focus') returning id
) select set_config('th955c.hw', id::text, true) from i;
insert into public.programme_consents (enrolment_id, purpose, consent_version, locale)
values (current_setting('th955c.hw')::uuid, 'core', 'v1-draft', 'en');

-- As E, a share_care_team consent whose recipient names nothing. The outcome
-- is "completed" or the SQLSTATE that refused it.
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claims', jsonb_build_object(
  'sub', '00000000-0000-4000-8000-0000009550e1', 'role', 'authenticated')::text, true);
set local role authenticated;
do $c$
declare
  outcome text;
begin
  begin
    insert into public.programme_consents (enrolment_id, purpose, recipient_ref, consent_version, locale)
    values (current_setting('th955c.hw')::uuid, 'share_care_team',
            '00000000-0000-4000-8000-0000009550ff', 'v1-draft', 'en');
    outcome := 'completed';
  exception when others then
    outcome := sqlstate;
  end;
  perform pg_catalog.set_config('th955c.outcome', outcome, true);
  raise notice 'CONTROL share_care_team consent naming no recipient: %', outcome;
end;
$c$;
reset role;
select set_config('request.jwt.claims', '', true);

select case
  when current_setting('th955c.outcome') = 'TH021'
   and to_regclass('public.care_connections') is not null
    then 'TH955_CONTROL_UNBOUND_RECIPIENT_REFUSED'
  when current_setting('th955c.outcome') = 'completed'
   and to_regclass('public.care_connections') is null
    then 'TH955_CONTROL_UNBOUND_RECIPIENT_ACCEPTED'
  else 'TH955_CONTROL_UNEXPECTED'
end as result;
rollback;
SQL
}

case "${1:-}" in
  --print-sql)
    print_sql
    exit 0
    ;;
  --print-control-sql)
    print_control_sql
    exit 0
    ;;
esac

fail() {
  echo "Care migration check failed: $1" >&2
  exit 1
}

# Accepts only postgres:// or postgresql:// URLs whose whole authority is
# [userinfo@]127.0.0.1|localhost[:port] (same rule as the other verify scripts).
url_shape='^postgres(ql)?://([^/]*)(/[^?#[:space:]]*)?$'
local_authority='^([^@/?#,[:space:]]*@)?(127\.0\.0\.1|localhost)(:[0-9]{1,5})?$'
db_url_is_local() {
  [[ "$1" =~ $url_shape ]] || return 1
  [[ "${BASH_REMATCH[2]}" =~ $local_authority ]]
}
db_url_is_local 'postgresql://postgres:postgres@127.0.0.1:54322/postgres' ||
  fail 'local URL guard rejects a local URL'
for u in 'postgresql://postgres@db.example.test:5432/postgres' \
  'postgresql://postgres@localhost:54322/postgres?host=db.example.test' \
  'postgresql://u@db.example.test:5432@127.0.0.1/postgres'; do
  if db_url_is_local "$u"; then fail "local URL guard accepts a non-local URL ($u)"; fi
done
if [[ -n "${VERIFY_DB_URL:-}" ]] && ! db_url_is_local "$VERIFY_DB_URL"; then
  fail 'VERIFY_DB_URL must point at a local database (127.0.0.1 or localhost)'
fi

for f in "$migration" "$previous" "$contract"; do
  [[ -f "$f" ]] || fail "missing $f"
done
[[ -d "$migrations_dir" ]] || fail "missing $migrations_dir"

# Name and version: 12-digit version, lowercase name, after 202610180010 and
# used by no other file.
[[ "${migration##*/}" =~ ^[0-9]{12}_[a-z0-9_]+\.sql$ ]] ||
  fail "${migration##*/} is not YYYYMMDDNNNN_name.sql"
[[ "$(find "$migrations_dir" -maxdepth 1 -name '202610180011_*.sql' | wc -l | tr -d ' ')" -eq 1 ]] ||
  fail 'exactly one migration may use version 202610180011'
[[ -f "$migrations_dir/202610180010_app_data_deletion_owner_only.sql" ]] ||
  fail 'the care migration follows 202610180010'

migration_files=()
while IFS= read -r -d '' path; do
  migration_files+=("$path")
done < <(find "$migrations_dir" -mindepth 1 -maxdepth 1 -name '*.sql' -print0 | LC_ALL=C sort -z)

# The SQL on stdin as one statement per line: comments removed, lower case,
# double quotes dropped, whitespace collapsed to single spaces, split at ";".
statements() {
  sed 's/--.*$//' | tr '\n\t\r' '   ' | tr '[:upper:]' '[:lower:]' | tr -d '"' |
    sed -E 's/ +/ /g' | tr ';' '\n' | sed -E 's/^ //; s/ $//' | grep -v '^$' || true
}
stmts=$(statements <"$migration")
code_text=$(sed 's/--.*$//' "$migration")

[[ "$(head -n 1 <<<"$stmts")" == 'begin' ]] || fail "$migration must start with begin;"
[[ "$(tail -n 1 <<<"$stmts")" == 'commit' ]] || fail "$migration must end with commit;"

# The nine tables, each with row-level security enabled and forced and every
# privilege revoked before the reviewed grants.
tables='care_orgs care_invites care_connections care_shares care_share_access care_messages caregivers caregiver_events supporters'
created=$(grep -Eo '^create table public\.[a-z_]+' <<<"$stmts" | sed 's/^create table public\.//' | LC_ALL=C sort | tr '\n' ' ')
[[ "$created" == "$(tr ' ' '\n' <<<"$tables" | LC_ALL=C sort | tr '\n' ' ')" ]] ||
  fail "$migration must create exactly the nine care tables (got: $created)"
for t in $tables; do
  grep -Fxq "alter table public.$t enable row level security" <<<"$stmts" || fail "$t: enable row level security"
  grep -Fxq "alter table public.$t force row level security" <<<"$stmts" || fail "$t: force row level security"
  grep -Fxq "revoke all on table public.$t from public, anon, authenticated, service_role" <<<"$stmts" ||
    fail "$t: revoke all from public, anon, authenticated and service_role"
done
for c in care_clinicians care_referrals; do
  if grep -Fq "$c" <<<"$stmts"; then fail "$migration must not create $c"; fi
done

# Never loosen.
if grep -Eq 'grant all|disable row level security|no force row level security|disable trigger|session_replication_role|owner to|(create|alter|drop) role|security_barrier|create (or replace )?(materialized )?view' <<<"$stmts"; then
  fail 'migration must not grant all, weaken row-level security, disable triggers, change roles or owners, or create views'
fi
if grep -E '^grant ' <<<"$stmts" | grep -Eq '(^|[^a-z_])(anon|service_role|public|thsync)([^a-z_.]|$)'; then
  fail 'nothing is granted to anon, service_role, PUBLIC or thsync'
fi
# No foreign key to the guarded consent, consent document or sync tables, and
# no action that rewrites a referencing row.
if grep -Eq 'references public\.(programme_consents|account_consents|consent_documents|sync_[a-z_]+)' <<<"$stmts"; then
  fail 'no care table may reference programme_consents, account_consents, consent_documents or a sync table'
fi
if grep -Eq 'set null|set default' <<<"$stmts"; then
  fail 'no foreign key may set null or a default (that would update revoke-only and append-only rows)'
fi
grep -Eq 'consent_id uuid not null,' <<<"$stmts" || fail 'care_shares.consent_id must be uuid not null'
grep -Fxq 'create index care_shares_consent_idx on public.care_shares (consent_id)' <<<"$stmts" ||
  fail 'care_shares.consent_id must be indexed'
# care_invites keeps only the hash of the code.
invites=$(sed -n '/^create table public\.care_invites (/,/^);/p' "$migration")
grep -Fq '  code_hash bytea not null,' <<<"$invites" || fail 'care_invites must hold code_hash bytea not null'
grep -Fq 'octet_length(code_hash) = 32' <<<"$invites" || fail 'care_invites.code_hash must be 32 bytes'
if grep -Eq '^  code ' <<<"$invites"; then fail 'care_invites must not hold the code'; fi
# Shares expire 30 days after creation by default, and at most 30 days after it.
shares=$(sed -n '/^create table public\.care_shares (/,/^);/p' "$migration")
grep -Fq "  expires_at timestamptz not null default now() + interval '30 days'," <<<"$shares" ||
  fail 'care_shares.expires_at must default to 30 days after creation'
grep -Fq "    expires_at > created_at and expires_at <= created_at + interval '30 days'" <<<"$shares" ||
  fail 'care_shares.expires_at must be capped at 30 days after creation'

# The recipient check and the insert re-checks lock what they read (FOR SHARE),
# and redemption locks the invite (FOR UPDATE).
for pair in care_check_consent_recipient:2:0 care_lock_live_consent:4:0 redeem_care_invite:0:1; do
  IFS=: read -r fn shares_n updates_n <<<"$pair"
  body=$(sed -n "/^create function public\\.$fn(/,/^\\\$\\\$;\$/p" "$migration")
  [[ "$(grep -cE '^ +for share;$' <<<"$body")" -eq "$shares_n" &&
    "$(grep -cE '^ +for update;$' <<<"$body")" -eq "$updates_n" ]] ||
    fail "$fn must lock with $shares_n for share and $updates_n for update"
done

# Truncate appears only in the guards' trigger events and in the revoke.
while IFS= read -r stmt; do
  [[ "$stmt" =~ ^create\ trigger\ [a-z_]+_truncate_guard\ before\ truncate\ on\ public\.[a-z_]+\ for\ each\ statement\ execute\ function\ public\.care_truncate_guard\(\)$ ]] && continue
  [[ "$stmt" =~ ^revoke\ truncate\ on\  ]] && continue
  fail "truncate appears outside a guard trigger or the revoke: $stmt"
done < <(grep -E '(^|[^a-z_])truncate([^a-z_]|$)' <<<"$stmts" || true)
for t in care_connections care_shares care_share_access care_messages caregivers caregiver_events; do
  grep -Fxq "create trigger ${t}_truncate_guard before truncate on public.$t for each statement execute function public.care_truncate_guard()" <<<"$stmts" ||
    fail "$t needs its truncate guard"
  grep -Fxq "alter table public.$t enable always trigger ${t}_truncate_guard" <<<"$stmts" ||
    fail "${t}_truncate_guard must fire in every session mode"
done
grep -Fxq 'revoke truncate on public.care_connections, public.care_shares, public.care_share_access, public.care_messages, public.caregivers, public.caregiver_events from public, anon, authenticated, thsync' <<<"$stmts" ||
  fail 'truncate must be revoked on the six guarded tables from public, anon, authenticated and thsync'

# Functions: exactly the ten new ones plus delete_my_app_data, each revoked from
# public, anon, authenticated and service_role later in the file; only
# redeem_care_invite and supporters_drop_programme are new security definers.
new_functions=$(grep -Eo '^create function public\.[a-z_]+\([a-z_ ]*\)' "$migration" |
  sed 's/^create function public\.//' | LC_ALL=C sort | tr '\n' ' ')
[[ "$new_functions" == 'care_append_only() care_check_consent_recipient() care_connections_revoke_cascade() care_lock_live_consent() care_revoke_only() care_truncate_guard() caregivers_revoke_cascade() programme_consents_revoke_care_shares() redeem_care_invite(p_code text) supporters_drop_programme() ' ]] ||
  fail "$migration must create exactly the ten reviewed functions (got: $new_functions)"
if [[ "$(grep -Ec '^create or replace function ' "$migration")" -ne 1 ]] ||
  ! grep -Fxq 'create or replace function public.delete_my_app_data(p_confirmation text)' "$migration"; then
  fail 'the only function replaced is delete_my_app_data'
fi
for sig in 'care_append_only()' 'care_check_consent_recipient()' 'care_connections_revoke_cascade()' \
  'care_lock_live_consent()' 'care_revoke_only()' 'care_truncate_guard()' 'caregivers_revoke_cascade()' \
  'programme_consents_revoke_care_shares()' 'redeem_care_invite(text)' 'supporters_drop_programme()'; do
  name="${sig%%(*}"
  create_at=$(grep -n "^create function public\\.$name(" <<<"$stmts" | head -n 1 | cut -d: -f1)
  revoke_at=$(grep -nFx "revoke all on function public.$sig from public, anon, authenticated, service_role" <<<"$stmts" |
    head -n 1 | cut -d: -f1)
  [[ -n "$create_at" && -n "$revoke_at" && "$revoke_at" -gt "$create_at" ]] ||
    fail "$sig must be followed by revoke all from public, anon, authenticated and service_role"
  body=$(sed -n "/^create function public\\.$name(/,/^\\\$\\\$;\$/p" "$migration")
  grep -Fxq "set search_path = ''" <<<"$body" || fail "$name must set search_path = ''"
  if [[ "$name" == redeem_care_invite || "$name" == supporters_drop_programme ]]; then
    grep -Fxq 'security definer' <<<"$body" || fail "$name must be security definer"
  elif grep -Fxq 'security definer' <<<"$body"; then
    fail "$name must not be security definer"
  fi
done
[[ "$(grep -Ec '^security definer$' "$migration")" -eq 3 ]] ||
  fail 'only redeem_care_invite, supporters_drop_programme and delete_my_app_data are security definer'

# Grants: exactly the reviewed ones.
grants=$(grep -E '^grant ' <<<"$stmts" | LC_ALL=C sort)
expected_grants=$(LC_ALL=C sort <<'GRANTS'
grant select (id, name) on table public.care_orgs to authenticated
grant select on table public.care_connections to authenticated
grant update (revoked_at) on table public.care_connections to authenticated
grant select on table public.care_shares to authenticated
grant insert (user_id, enrolment_id, connection_id, consent_id, kind, snapshot, expires_at) on table public.care_shares to authenticated
grant update (revoked_at) on table public.care_shares to authenticated
grant select on table public.care_share_access to authenticated
grant select on table public.care_messages to authenticated
grant insert (user_id, connection_id, enrolment_id, topic, body, share_id) on table public.care_messages to authenticated
grant select on table public.caregivers to authenticated
grant insert (user_id, enrolment_id, name, phone, scope) on table public.caregivers to authenticated
grant update (invite_status, revoked_at) on table public.caregivers to authenticated
grant select on table public.caregiver_events to authenticated
grant insert (user_id, caregiver_id, kind, occurred_at) on table public.caregiver_events to authenticated
grant select, delete on table public.supporters to authenticated
grant insert (user_id, name, phone, programme_codes, help_phrase) on table public.supporters to authenticated
grant update (name, phone, programme_codes, help_phrase) on table public.supporters to authenticated
grant execute on function public.redeem_care_invite(text) to authenticated
GRANTS
)
[[ "$grants" == "$expected_grants" ]] || fail "$migration must contain exactly the reviewed grants. Got:
$grants"

# The recipient trigger fires only for sharing consents that name a recipient.
recipient_trigger=$(grep -E '^create trigger programme_consents_check_recipient ' <<<"$stmts" || true)
[[ "$recipient_trigger" == "create trigger programme_consents_check_recipient before insert on public.programme_consents for each row when ( new.purpose in ('share_care_team', 'share_caregiver') and new.recipient_ref is not null ) execute function public.care_check_consent_recipient()" ]] ||
  fail "programme_consents_check_recipient must run before insert for sharing consents with a recipient (got: $recipient_trigger)"

# delete_my_app_data: the earlier body plus only the care declares, deletes
# and receipt keys, and the trailing comma on the sync_accounts receipt line.
body_previous=$(sed -n '/^create or replace function public\.delete_my_app_data(p_confirmation text)$/,/^\$\$;$/p' "$previous")
body_new=$(sed -n '/^create or replace function public\.delete_my_app_data(p_confirmation text)$/,/^\$\$;$/p' "$migration")
[[ -n "$body_previous" && -n "$body_new" ]] || fail 'delete_my_app_data bodies not found'
for anchor in '  deleted_sync_accounts integer := 0;' '  get diagnostics deleted_sync_accounts = row_count;' \
  "    'sync_accounts', deleted_sync_accounts"; do
  [[ "$(grep -Fxc "$anchor" <<<"$body_previous")" -eq 1 ]] || fail "the earlier delete_my_app_data body must contain once: $anchor"
done
expected_body=$(awk -v q="'" '
  BEGIN { n = split("care_share_access care_messages care_shares caregiver_events caregivers care_connections supporters", k, " ") }
  $0 == "    " q "sync_accounts" q ", deleted_sync_accounts" {
    print $0 ","
    for (i = 1; i <= n; i++) printf "    %s%s%s, deleted_%s%s\n", q, k[i], q, k[i], (i < n ? "," : "")
    next
  }
  { print }
  $0 == "  deleted_sync_accounts integer := 0;" {
    for (i = 1; i <= n; i++) printf "  deleted_%s integer := 0;\n", k[i]
  }
  $0 == "  get diagnostics deleted_sync_accounts = row_count;" {
    for (i = 1; i <= n; i++) printf "  delete from public.%s where user_id = caller_id;\n  get diagnostics deleted_%s = row_count;\n", k[i], k[i]
  }
' <<<"$body_previous")
[[ "$body_new" == "$expected_body" ]] ||
  fail "delete_my_app_data must be the $previous body plus only the seven care declares, deletes and receipt keys:
$(diff <(echo "$expected_body") <(echo "$body_new") || true)"
latest_delete=$(grep -El '^create (or replace )?function public\.delete_my_app_data\(' "${migration_files[@]}" | tail -n 1)
latest_body=$(sed -n '/^create \(or replace \)\{0,1\}function public\.delete_my_app_data(/,/^\$\$;$/p' "$latest_delete")
for t in care_share_access care_messages care_shares caregiver_events caregivers care_connections supporters; do
  grep -Fxq "  delete from public.$t where user_id = caller_id;" <<<"$latest_body" ||
    fail "the latest delete_my_app_data ($latest_delete) must delete $t"
  grep -Fq "'$t', deleted_$t" <<<"$latest_body" || fail "the latest delete_my_app_data must count $t"
done
if grep -E '^(grant|alter function|comment on function)' <<<"$stmts" | grep -q 'delete_my_app_data'; then
  fail 'no grant, alter function or comment on function for delete_my_app_data'
fi
if grep -Eq 'delete_my_account|begin_account_deletion' <<<"$stmts"; then
  fail 'delete_my_account and begin_account_deletion are not named in any statement'
fi

# The legacy sharing-consent block: once, between its markers, after every
# object is created.
[[ "$(grep -Fxc -- '-- TH-955 legacy share consents: begin' "$migration")" -eq 1 &&
  "$(grep -Fxc -- '-- TH-955 legacy share consents: end' "$migration")" -eq 1 ]] ||
  fail 'the legacy share consent markers must each appear once'
block=$(legacy_block)
block_start=$(grep -nFx -- '-- TH-955 legacy share consents: begin' "$migration" | cut -d: -f1)
last_object=$(grep -nE '^(create|alter table|grant|revoke|comment on)' "$migration" | tail -n 1 | cut -d: -f1)
[[ "$block_start" -gt "$last_object" ]] || fail 'the legacy block must come after every object is created'
block_stmts=$(statements <<<"$block")
[[ "$(head -n 1 <<<"$block_stmts")" == 'do $$ begin if not exists ( select 1 from pg_catalog.pg_roles as r where r.rolname = current_user and (r.rolsuper or r.rolbypassrls) ) then raise exception '"'"'revoking stored share consents needs a migration role that bypasses row-level security'"'"'' ]] ||
  fail 'the legacy block must first refuse a migration role that does not bypass row-level security'
grep -Fq "update public.programme_consents set revoked_at = now() where purpose in ('share_care_team', 'share_caregiver') and revoked_at is null" <<<"$block_stmts" ||
  fail 'the legacy block must revoke every live sharing consent'
grep -Fq "raise exception 'live share consents remain after the revocation'" <<<"$block_stmts" ||
  fail 'the legacy block must fail if a live sharing consent remains'
if grep -Eq '(^|[^a-z_])delete([^a-z_]|$)|check \(|recipient_ref ~' <<<"$block_stmts"; then
  fail 'the legacy block must not delete consents or add a check on recipient_ref'
fi
[[ "$(grep -c '^do \$\$' <<<"$stmts")" -eq 1 ]] || fail 'the migration has exactly one do block'

# Registry: every TH raise in this migration uses a registered code, hint and
# message, and its row names the raising function.
# The backticks are literal Markdown, not command substitution.
# shellcheck disable=SC2016
registry_row() { grep -E "^\| \`$1\` \|" "$contract" || true; }
fn_re='^create (or replace )?function public\.([a-z_]+)\('
raise_re="errcode = '(TH[0-9]{3})', message = '([^']+)', hint = '([a-z_]+)';"
checked=0
codes=''
current_fn=''
while IFS= read -r line; do
  if [[ "$line" =~ $fn_re ]]; then
    current_fn="${BASH_REMATCH[2]}"
    continue
  fi
  [[ "$line" =~ $raise_re ]] || fail "unexpected raise form in $current_fn: $line"
  code="${BASH_REMATCH[1]}" msg="${BASH_REMATCH[2]}" hint="${BASH_REMATCH[3]}"
  row=$(registry_row "$code")
  [[ -n "$row" ]] || fail "$code ($current_fn) is not in the registry"
  grep -Fq "| \`$code\` | \`$hint\` |" <<<"$row" || fail "$code is raised with hint $hint, not the registered name"
  grep -Fq "$msg" <<<"$row" || fail "$code message '$msg' is not in its registry row"
  grep -Fq "\`$current_fn\`" <<<"$row" || fail "$code registry row does not name $current_fn"
  codes+="$code "
  checked=$((checked + 1))
done < <(awk '
  /^create (or replace )?function public\./ { print; next }
  /raise exception using errcode/ { stmt = $0; grab = 1 }
  grab {
    if (stmt != $0) { line = $0; sub(/^ +/, "", line); stmt = stmt " " line }
    if ($0 ~ /;$/) { sub(/^ +/, "", stmt); print stmt; grab = 0 }
  }
' <<<"$code_text")
[[ "$checked" -eq 13 ]] || fail "expected 13 TH raises in $migration, checked $checked"
[[ "$(tr ' ' '\n' <<<"$codes" | grep -v '^$' | LC_ALL=C sort -u | tr '\n' ' ')" == 'TH006 TH009 TH010 TH021 TH022 TH023 TH024 TH025 ' ]] ||
  fail "the migration raises only TH006, TH010, TH021 to TH025 and delete_my_app_data's TH009 (got: $codes)"
for row in 'TH021|consent_recipient_invalid' 'TH022|care_consent_required' 'TH023|care_record_immutable' \
  'TH024|care_rows_delete_only' 'TH025|care_invite_invalid'; do
  IFS='|' read -r c name <<<"$row"
  grep -Eq "^\\| \`$c\` \\| \`$name\` \\|" "$contract" || fail "$c $name is not in the registry in $contract"
done
# shellcheck disable=SC2016
registry_row TH006 | grep -Fq '`redeem_care_invite`' || fail 'the TH006 registry row must name redeem_care_invite'
# shellcheck disable=SC2016
registry_row TH010 | grep -Fq '`redeem_care_invite`' || fail 'the TH010 registry row must name redeem_care_invite'

# Contract.
grep -Fq "\`$migration\`" "$contract" || fail "$contract must name $migration"
# shellcheck disable=SC2016
grep -Fq '`supabase/tests/verify_care_migration.sh`' "$contract" || fail "$contract must name this check"
grep -Fxq '## Care team' "$contract" || fail "$contract must have a Care team section"

echo 'Care migration static checks passed.'

if [[ -n "${VERIFY_DB_URL:-}" ]]; then
  command -v psql >/dev/null || fail 'VERIFY_DB_URL is set but psql is not installed'
  run_psql() {
    env -u PGHOSTADDR -u PGHOST -u PGPORT -u PGSERVICE -u PGSERVICEFILE \
      psql "$VERIFY_DB_URL" -X -q -v ON_ERROR_STOP=1 2>&1
  }
  echo 'SQL test and control against VERIFY_DB_URL (local database):'
  out=$(print_sql | run_psql) || {
    echo "$out" >&2
    fail 'SQL test failed'
  }
  echo "$out" | grep -E 'PASS|FAIL' || true
  echo "$out" | grep -q 'TH955_SQL_TESTS_COMPLETE' || fail 'SQL test did not complete'
  out=$(print_control_sql | run_psql) || {
    echo "$out" >&2
    fail 'control failed'
  }
  echo "$out" | grep -E 'CONTROL' || true
  echo "$out" | grep -q 'TH955_CONTROL_UNBOUND_RECIPIENT_REFUSED' ||
    fail 'control: a sharing consent naming no recipient was not refused'
  echo 'Care migration SQL test and control passed.'
fi
