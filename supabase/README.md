# Local Supabase

With the Supabase CLI and Docker installed, run `supabase start` followed by
`supabase db reset` to execute all migrations locally. Repository-safe static
checks are:

```bash
bash supabase/tests/verify_profiles_migration.sh
bash supabase/tests/verify_quit_plans_migration.sh
bash supabase/tests/verify_account_deletion_migration.sh
```

Local keys printed by the CLI belong in process/build configuration, never
source. Flutter receives only the publishable key; the profile and quit-plan APIs
forward the authenticated caller token so PostgreSQL RLS remains the final
authorization boundary. Use synthetic quit-plan and support-person data only in
development environments.

For native email confirmation, add
`io.breathefree.patient://login-callback` to **Authentication → URL
Configuration → Redirect URLs** in every Supabase project. Flutter supplies that
exact callback when creating an account or resending confirmation, and the iOS
and Android runners register the matching deep link. Password recovery uses the
same callback and must also be allowlisted. Do not leave a production
project relying on the local `http://localhost:3000` Site URL.
