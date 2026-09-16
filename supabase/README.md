# Local Supabase

With the Supabase CLI and Docker installed, run `supabase start` followed by
`supabase db reset` to execute all migrations locally. Repository-safe static
checks are:

```bash
bash supabase/tests/verify_profiles_migration.sh
bash supabase/tests/verify_quit_plans_migration.sh
```

Local keys printed by the CLI belong in process/build configuration, never
source. Flutter receives only the publishable key; the profile and quit-plan APIs
forward the authenticated caller token so PostgreSQL RLS remains the final
authorization boundary. Use synthetic quit-plan and support-person data only in
development environments.
