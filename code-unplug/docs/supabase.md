# Supabase

Project ref **`gcsazvotzqvjayqnqyra`** —
<https://supabase.com/dashboard/project/gcsazvotzqvjayqnqyra>

Everything below that can be a file in this repository is one. What is left is
dashboard state, and it is listed at the end with exactly what to click.

## This project signs tokens with ES256, not a shared secret

Verified, not assumed:

```console
$ curl https://gcsazvotzqvjayqnqyra.supabase.co/auth/v1/.well-known/jwks.json
{"keys":[{"alg":"ES256","crv":"P-256","kid":"4d6f2069-6aba-421c-90e3-cd62073b3501","kty":"EC",…}]}
```

One ES256 key on P-256, published unauthenticated. Supabase issues asymmetric
keys for new projects; the legacy symmetric `JWT_SECRET` belongs to older ones.

That matters because the sync service originally only did HS256, so **no token
from this project would ever have verified**. It now supports both families and
chooses between them from configuration — never from the token's own header,
which is the algorithm confusion bug. `sync/tests/test_auth_jwks.py` forges
exactly that attack, by hand, and asserts it is refused.

Verifying against the JWKS is also strictly better than a shared secret: the
service holds nothing that could mint a token, so compromising it cannot forge
a session for somebody else.

## Configuring the sync service

One variable, because the issuer and the key set are both fixed functions of
the project URL and asking for them separately invites a deployment where they
name different projects:

```bash
export THSYNC_SUPABASE_URL='https://gcsazvotzqvjayqnqyra.supabase.co'
export THSYNC_DATABASE_URL='postgresql+psycopg://…'
```

That derives:

| Derived | Value |
| --- | --- |
| `jwt_issuer` | `https://gcsazvotzqvjayqnqyra.supabase.co/auth/v1` |
| `jwt_jwks_url` | `…/auth/v1/.well-known/jwks.json` |

`THSYNC_JWT_SECRET` is for legacy symmetric projects only. Setting **both** it
and `THSYNC_SUPABASE_URL` is refused at start-up rather than resolved by
precedence — a precedence rule is something somebody has to remember at three
in the morning.

## Migrations live in `supabase/migrations/`

Not in `sync/`. Branching applies whatever is in that directory when it builds
a preview branch and when it deploys production; DDL kept anywhere else would
mean every branch came up with an empty database while the tests stayed green.

`.github/workflows/supabase.yml` applies them to a real PostgreSQL 17 on every
pull request, twice, to prove they are re-runnable. It deliberately does **not**
deploy on merge — Branching already does that, and two things applying the same
migrations would race.

## Branches

Supabase Branching maps git branches to databases:

- **Production branch** — `main`. The default branch of this repository and the
  one whose merges deploy to the live project.
- **Preview branches** — one per pull request, created and destroyed
  automatically, seeded by replaying `supabase/migrations`.

Preview branches are a **paid** feature and are billed per branch per hour, so
enabling this has a cost. That is the main reason the steps below are yours
rather than something done here.

### What you need to do in the dashboard

1. **Database → Branching → Enable branching.** Connect the GitHub app to
   `Tetherhealthgroup/Tether-Health` if it is not already.
2. Set the **production branch** to `main`.
3. Set the **supabase directory** to `supabase` (the default; confirm it).
4. Open a pull request touching `supabase/migrations/` and check a preview
   branch appears and the migration applies.

### The MCP server

Already in `.mcp.json`, scoped to this project:

```json
{"mcpServers":{"supabase":{"type":"http","url":"https://mcp.supabase.com/mcp?project_ref=gcsazvotzqvjayqnqyra&features=docs,account,database,debugging,development,functions,branching"}}}
```

Authentication is an OAuth flow and has to be done by a person, in a real
terminal rather than an IDE extension:

```bash
claude /mcp     # select "supabase", then Authenticate
```

## What has been verified here, and what has not

Verified:

- The project is live and its JWKS is reachable and ES256 (curl output above).
- The sync service, configured with `THSYNC_SUPABASE_URL` pointed at this
  project, fetches that key set and reports `kid
  4d6f2069-6aba-421c-90e3-cd62073b3501`.
- Running against it over HTTP, a token forged with that **real** `kid` and an
  attacker's own P-256 key is refused with `401` and an RFC 7807 body.
- `supabase init` config, migration layout and both workflow files parse.

Not verified:

- **No real Supabase access token has been through the service.** That needs a
  signed-in user, and no anon key or user credentials are present here. The
  first real sign-in is the remaining check.
- Nothing has been created, changed or deleted in the Supabase project. No
  branch exists yet; the dashboard steps above are untouched.
- The migration has still never run on a Postgres server locally — see
  `sync/README.md` for why (the sandbox denies `shmget`, so `initdb` cannot
  bootstrap a cluster). The CI job above is where that first happens.
