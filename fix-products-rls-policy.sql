-- Fix RLS policy for products table to allow anon role to insert/update
-- This allows the brand onboarding form to work properly

-- Check current policies on products table
SELECT policyname, permissive, roles, cmd, qual, with_check 
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'products';

-- Add permissive policies for anon role on products table
CREATE POLICY anon_insert_products ON products 
FOR INSERT TO anon 
WITH CHECK (true);

CREATE POLICY anon_update_products ON products 
FOR UPDATE TO anon 
USING (true) 
WITH CHECK (true);

CREATE POLICY anon_select_products ON products 
FOR SELECT TO anon 
USING (true);

-- Refresh PostgREST schema so policies take effect
NOTIFY pgrst, 'reload schema';

