-- PROPER FIX: Re-enable RLS with working admin function
-- Run this in Supabase SQL editor

-- 1) First, let's check what's in the JWT for your admin user
-- This will help us understand why is_admin() is returning false
SELECT 
    auth.jwt() -> 'app_metadata' ->> 'role' as app_role,
    auth.jwt() -> 'user_metadata' ->> 'role' as user_role,
    auth.jwt() -> 'raw_app_meta_data' ->> 'role' as raw_app_role,
    auth.jwt() -> 'raw_user_meta_data' ->> 'role' as raw_user_role;

-- 2) Fix the is_admin() function to check all possible JWT locations
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT COALESCE(
    -- Check all possible JWT locations for admin role
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'admin' OR
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin' OR
    (auth.jwt() -> 'raw_app_meta_data' ->> 'role') = 'admin' OR
    (auth.jwt() -> 'raw_user_meta_data' ->> 'role') = 'admin' OR
    -- Fallback: check if user exists in users table with admin role
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() AND role = 'admin'
    ),
    false
  );
$$;

-- 3) Test the function
SELECT public.is_admin() as is_admin_result;

-- 4) Re-enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 5) Drop existing policies
DROP POLICY IF EXISTS "users_select_self_or_admin" ON public.users;
DROP POLICY IF EXISTS "users_insert_self_or_admin" ON public.users;
DROP POLICY IF EXISTS "users_update_self_or_admin" ON public.users;

-- 6) Create new policies with the fixed admin function
CREATE POLICY "users_select_self_or_admin"
ON public.users
FOR SELECT
USING (
  id = auth.uid() OR public.is_admin()
);

CREATE POLICY "users_insert_self_or_admin"
ON public.users
FOR INSERT
WITH CHECK (
  id = auth.uid() OR public.is_admin()
);

CREATE POLICY "users_update_self_or_admin"
ON public.users
FOR UPDATE
USING (
  id = auth.uid() OR public.is_admin()
)
WITH CHECK (
  id = auth.uid() OR public.is_admin()
);

-- 7) Grant necessary permissions
GRANT ALL ON public.users TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO public;

-- 8) Test the policies
SELECT COUNT(*) as total_users FROM public.users;
SELECT email, role FROM public.users ORDER BY created_at DESC;
