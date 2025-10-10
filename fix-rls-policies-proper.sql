-- PROPER FIX: JWT-only RLS policies (no recursion)
-- Run this in your Supabase SQL editor

-- 1) Create a JWT-only admin helper (no table reads)
-- Helper that checks the JWT for admin.
-- NOTE: reads ONLY auth.jwt(), never the users table → no recursion.
create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select coalesce(
    (auth.jwt() -> 'app_metadata'  ->> 'role') = 'admin' OR
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin',
    false
  );
$$;

-- 2) Drop existing users policies and re-enable RLS
-- Drop all existing policies by name (ignore "doesn't exist" warnings)
drop policy if exists "Users can view own profile"        on public.users;
drop policy if exists "Users can update own profile"      on public.users;
drop policy if exists "Users can insert own profile"      on public.users;
drop policy if exists "Admins can view all users"         on public.users;
drop policy if exists "Admins can update any profile"     on public.users;
drop policy if exists "Enable read access for all users"  on public.users;
drop policy if exists "Enable insert for authenticated users only" on public.users;
drop policy if exists "Enable update for users based on email"     on public.users;

-- Make sure RLS is ON (we want it enabled, just with correct rules)
alter table public.users enable row level security;

-- 3) Minimal, non-recursive RLS policies
-- SELECT: user can see own row, or any row if admin
create policy "users_select_self_or_admin"
on public.users
for select
using (
  id = auth.uid() OR public.is_admin()
);

-- INSERT: user can insert only their own row (admin can insert any)
create policy "users_insert_self_or_admin"
on public.users
for insert
with check (
  id = auth.uid() OR public.is_admin()
);

-- UPDATE: user can update only their own row (admin can update any)
create policy "users_update_self_or_admin"
on public.users
for update
using (
  id = auth.uid() OR public.is_admin()
)
with check (
  id = auth.uid() OR public.is_admin()
);

-- 4) Ensure privileges (policies guard the rows; grants allow the statements)
grant usage on schema public to authenticated;
grant select, insert, update on public.users to authenticated;

-- 5) Verify the setup
-- Check that RLS is enabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'users';

-- Check policies exist
SELECT policyname, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'users';
