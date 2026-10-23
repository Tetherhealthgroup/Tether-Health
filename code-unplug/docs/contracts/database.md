# Database contract v1

Migration source of truth: `supabase/migrations/202609110001_profiles.sql`.

`public.profiles` is a one-to-one extension of `auth.users`; `id` is both its
primary key and cascading foreign key. A signup trigger creates the row. Clients
cannot choose another user's identity: RLS predicates use `auth.uid()`.

| Column | Contract |
|---|---|
| `id` | UUID, immutable identity, references `auth.users(id)` |
| `display_name` | nullable trimmed text, 1–80 characters when present |
| `locale` | `en` or `es` |
| `time_zone` | non-empty time-zone identifier, max 64 characters |
| `onboarding_completed` | boolean, defaults false |
| `avatar_path` | nullable private path under `<user-id>/`, max 512 characters |
| `created_at` / `updated_at` | UTC timestamps; database managed |

Authenticated users may select and update only their row. Insert is performed by
the trusted signup trigger; delete is intentionally not granted because verified
account deletion needs a separate audited workflow. Avatar objects use a private
bucket and must live under a folder matching `auth.uid()`.
