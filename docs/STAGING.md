# Staging backend (owner runbook)

A separate staging backend for testing internal builds: a Supabase project,
the API and the sync service (thsync) on Render. **Synthetic accounts only.**
No real member, patient or health data ever goes into staging.

Every step below is an owner step. Agents prepare files; they never create
projects, hold credentials or run these commands against a live service.
Nothing here changes production (`render.yaml`, the production Supabase
project, the store builds).

**What has been tested.** No command in this runbook has been run against a
live Supabase project, a Render service or a staging host. Each step says what
was checked locally (on an in-memory PostgreSQL 17.5, with fake command-line
tools, or by the repository's tests) and labels the rest **UNTESTED**. Expect
to stop and report if an UNTESTED step does not behave as written.

Secrets (database passwords, keys) are typed only into the Supabase or Render
dashboard, or into a hidden prompt in your own terminal. Never paste them into
this repository, a chat, an issue or a commit. This document holds variable
**names** only.

## 0. Before anything: counsel

Record counsel's confirmation that the HIPAA arrangement does not need to
cover a staging project that holds synthetic data only. **Do not start step 1
until that confirmation is recorded.**

## 1. Create the Supabase project

In the Supabase dashboard, create a new project (for example
`tether-staging`), separate from production. Note:

- the project ref (`<ref>`); the project URL is `https://<ref>.supabase.co`;
- the publishable key (`sb_publishable_...`), from Project Settings > API
  Keys. Never use a secret key (`sb_secret_...`) or the service role key
  anywhere in staging;
- the database password you chose (keep it in your password manager).

## 2. Mark the database as staging

In the staging project's SQL editor, run:

```sql
alter database postgres set app.environment = 'staging';
```

Open a new SQL editor tab (the setting applies to new sessions) and check:

```sql
select current_setting('app.environment', true) as environment;
```

It must show `staging`. The staging seed (step 7) refuses to run anywhere this
is not set, so never run step 2 on production.

Tested locally: both statements on an in-memory PostgreSQL 17.5 (superuser).
**UNTESTED** on hosted Supabase, including whether its `postgres` role may set
this value and whether a new SQL editor tab picks it up.

## 3. Apply the migrations

The migrations are every file in `supabase/migrations`, applied in filename
order: today 26 files, from `202609110001_profiles.sql` to
`202610180015_records.sql`. Later migrations are applied the same way.

The commands below use `tool/staging_db.sh`, which refuses unless the target is
a staging host, so first add the Supabase host to `STAGING_HOSTS` (step 6;
the API and sync hosts can be added later). Then, from the repository root, in
your own terminal:

```sh
read -rs STAGING_DATABASE_URL && export STAGING_DATABASE_URL
```

Paste the staging connection string (Project Settings > Database, URI form,
user `postgres`, percent-encoded); nothing is echoed. Then:

```sh
sh tool/staging_db.sh check
sh tool/staging_db.sh migrate --dry-run
sh tool/staging_db.sh migrate
sh tool/staging_db.sh list
```

`migrate --dry-run` lists the migrations it would apply; check the list is the
files in `supabase/migrations`, in order, before running `migrate`.

Tested locally: `read -rs` in bash 3.2 and zsh; every `tool/staging_db.sh`
command refuses while `STAGING_HOSTS` is empty, and, with fake hosts and a
fake Supabase CLI, calls the CLI once with the expected arguments; the
Supabase CLI 2.108 accepts these flags; all migrations apply in filename order
on an in-memory PostgreSQL 17.5. **UNTESTED** against a live Supabase project:
`check`, `migrate --dry-run`, `migrate` and `list`.

## 4. Give the sync role a login

The migrations create the role `thsync` without a login. In the SQL editor,
give it a login with a new, strong password used nowhere else, and bound how
long it can hold locks (proposed values; change them if you prefer):

```sql
alter role thsync with login password 'TYPE-A-NEW-STRONG-PASSWORD-HERE';
alter role thsync set statement_timeout = '15s';
alter role thsync set idle_in_transaction_session_timeout = '15s';
alter role thsync set idle_session_timeout = '10min';
```

Type the password only there, then delete that query from the SQL editor's
history. Check the role:

```sql
select rolname, rolcanlogin, rolsuper, rolbypassrls, rolcreaterole,
  rolreplication, rolconfig
from pg_roles where rolname = 'thsync';
```

Expected: `rolcanlogin` true; `rolsuper`, `rolbypassrls`, `rolcreaterole` and
`rolreplication` false; `rolconfig` lists the three timeouts.

Tested locally: these statements and the check on an in-memory PostgreSQL 17.5
(superuser), with a made-up password. **UNTESTED** on hosted Supabase.

## 5. Create the two Render services

In Render: New > Blueprint, pick this repository and the branch to deploy,
and set the Blueprint path to `render.staging.yaml`. It defines
`tether-api-staging` (the API, health check `/health`) and
`tether-thsync-staging` (thsync, health check `/v1/health`). Deploys are
manual (auto-deploy is off).

Render asks for each variable marked `sync: false`. Enter the values in Render
only:

| Service | Variable | Value |
| --- | --- | --- |
| tether-api-staging | `SUPABASE_URL` | `https://<ref>.supabase.co` |
| tether-api-staging | `SUPABASE_ANON_KEY` | the staging publishable key |
| tether-thsync-staging | `THSYNC_SUPABASE_URL` | `https://<ref>.supabase.co` |
| tether-thsync-staging | `THSYNC_DATABASE_URL` | `postgresql+psycopg://thsync:<thsync password>@<database host>:5432/postgres` |

`<database host>` is the direct host `db.<ref>.supabase.co`. If thsync cannot
reach it from Render, use the session pooler host from Project Settings >
Database instead, with the user `thsync.<ref>` in place of `thsync` (whether
thsync's start-up role check passes through the pooler is not yet verified).

Never add `SUPABASE_SERVICE_ROLE_KEY` (the API refuses to start while it is
set) or `THSYNC_JWT_SECRET` (thsync refuses it in production mode). Then
deploy both services manually and note their hosts (for example
`tether-api-staging.onrender.com`).

Tested locally: `render.staging.yaml` parses with two YAML parsers and the
repository's tests check its services and variables. **UNTESTED** on Render:
creating the Blueprint from a non-default path, the build and start commands,
`PYTHON_VERSION`, the health checks, and thsync through the pooler.

## 6. Set STAGING_HOSTS

Internal builds in http mode, and `tool/staging_db.sh`, accept only hosts in
`STAGING_HOSTS` in `tool/release_define_check.sh`. It is empty until now, so
every http internal build has been refused. Add the three staging hosts,
lower case, without scheme or path:

```python
STAGING_HOSTS = frozenset((
    "<ref>.supabase.co",
    "tether-api-staging.onrender.com",
    "tether-thsync-staging.onrender.com",
))
```

Never add a production host. Commit this change through the normal review;
then run the tool tests:

```sh
flutter test --no-pub test/tool
```

Tested locally: the repository's tests swap in a host list in this exact form.

## 7. Seed the staging consent documents

The seed adds DRAFT consent documents marked `[DRAFT · staging]` (synthetic,
not approved). It refuses unless step 2 was done on this database, and
`tool/staging_db.sh` refuses unless the target is a staging host:

```sh
sh tool/staging_db.sh seed --dry-run
sh tool/staging_db.sh seed
```

Tested locally: on an in-memory PostgreSQL 17.5 the seed refuses (and writes
nothing) without `app.environment` and with `production`, adds 20 draft
documents with `staging`, and adds nothing when run again; `seed --dry-run`
and the host refusal are covered by the repository's tests. **UNTESTED**
against a live Supabase project, including `supabase db query` running the
file.

When the database steps are done, close the terminal (or run
`unset STAGING_DATABASE_URL`).

## 8. Read-only checks

```sh
sh tool/staging_db.sh list
curl -fsS https://tether-api-staging.onrender.com/health
curl -fsS https://tether-thsync-staging.onrender.com/v1/health
```

- `list`: every migration in `supabase/migrations` is applied, none extra.
- The API health check returns `{"status":"ok",...}`; the thsync one returns
  its health JSON with HTTP 200.
- Rerun the `pg_roles` query from step 4.
- In the dashboard (Project Settings > Data API), the exposed schemas are only
  the defaults (`public`, `graphql_public`); no other schema is exposed.

**UNTESTED**: every check in this step (no staging service exists yet).

## 9. Build an internal test app against staging

Copy `tool/defines/internal-staging.example.json` to a file outside the
repository, replace every placeholder with the staging values (the three
staging URLs and the staging publishable key), then:

```sh
sh tool/build_ios_release.sh --dart-define-from-file=<your file> --internal-tether-ui --check-only
bash tool/build_play_release.sh --dart-define-from-file=<your file> --internal-tether-ui
```

A sandbox build (no backend) uses `tool/defines/internal-sandbox.example.json`
as it is.

Tested locally: the iOS `--check-only` command with the sandbox template
passes, and with the unedited staging template is refused; the Play command
with the sandbox template stops at the missing signing configuration on an
agent machine. **UNTESTED**: a signed build, and both commands with a filled-in
staging file.

## Always

- Keep every staging account synthetic: made-up names, `example.com`-style
  email addresses you control, no real health data.
- **Never promote an internal build to production.** An Android build made with
  `--internal-tether-ui` has a versionName ending in `-internal-ui`; never
  promote or roll it out beyond the internal testing track. An iOS one printed
  the internal banner and left `build/ios/INTERNAL_TETHER_UI`; never submit it
  for App Store review or external testing.
- Always make a store iOS build with `tool/build_ios_release.sh` (without the
  flag). Never use Xcode Product > Archive after an internal build: Xcode
  archives with the defines of the last Flutter build. (The script removes the
  internal define from `ios/Flutter/Generated.xcconfig` after every internal
  build, but the script is the only supported path.)
