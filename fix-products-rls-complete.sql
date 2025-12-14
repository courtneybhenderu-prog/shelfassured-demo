-- Fix RLS policies for products table - ensure anon can insert/update
-- This addresses the "new row violates row-level security policy" error

-- Drop existing policies if they exist
DROP POLICY IF EXISTS anon_insert_products ON products;
DROP POLICY IF EXISTS anon_update_products ON products;
DROP POLICY IF EXISTS anon_select_products ON products;

-- Create new permissive policies for anon role
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

-- Also ensure authenticated users can insert/update
DROP POLICY IF EXISTS authenticated_insert_products ON products;
DROP POLICY IF EXISTS authenticated_update_products ON products;
DROP POLICY IF EXISTS authenticated_select_products ON products;

CREATE POLICY authenticated_insert_products ON products 
FOR INSERT TO authenticated 
WITH CHECK (true);

CREATE POLICY authenticated_update_products ON products 
FOR UPDATE TO authenticated 
USING (true) 
WITH CHECK (true);

CREATE POLICY authenticated_select_products ON products 
FOR SELECT TO authenticated 
USING (true);

-- Refresh PostgREST schema
NOTIFY pgrst, 'reload schema';


