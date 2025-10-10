-- SIMPLE FIX: Re-enable RLS with table-based admin check
-- Run this in Supabase SQL editor

-- 1) Create a simple admin function that checks the users table
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users 
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

-- 2) Test the function
SELECT public.is_admin() as is_admin_result;

-- 3) Re-enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 4) Drop existing policies
DROP POLICY IF EXISTS "users_select_self_or_admin" ON public.users;
DROP POLICY IF EXISTS "users_insert_self_or_admin" ON public.users;
DROP POLICY IF EXISTS "users_update_self_or_admin" ON public.users;

-- 5) Create new policies with the table-based admin function
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

-- 6) Grant necessary permissions
GRANT ALL ON public.users TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO public;

-- 7) Test the policies
SELECT COUNT(*) as total_users FROM public.users;
SELECT email, role FROM public.users ORDER BY created_at DESC;
