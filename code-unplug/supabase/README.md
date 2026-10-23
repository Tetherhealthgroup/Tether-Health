# Local Supabase

With the Supabase CLI and Docker installed, run `supabase start` followed by
`supabase db reset` to execute all migrations locally. The repository-safe static
check is `bash supabase/tests/verify_profiles_migration.sh`.

Local keys printed by the CLI belong in process/build configuration, never source.
Flutter receives only the publishable/anonymous key; the current profile API does
not use a service-role key.
