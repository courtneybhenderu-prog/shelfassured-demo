-- TEMPORARY FIX: Disable RLS on users table to test
-- This will allow all authenticated users to see all users
-- Run this in Supabase SQL editor

-- Disable RLS temporarily
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- Grant permissions to authenticated users
GRANT ALL ON public.users TO authenticated;

-- Test query to verify it works
SELECT COUNT(*) as total_users FROM public.users;
SELECT email, role, is_active FROM public.users ORDER BY created_at DESC;
