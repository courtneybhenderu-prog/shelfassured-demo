-- Fix RLS policies for stores table
-- Run this in Supabase SQL editor

-- Drop all existing stores policies
DROP POLICY IF EXISTS stores_insert ON stores;
DROP POLICY IF EXISTS stores_update ON stores;
DROP POLICY IF EXISTS stores_select ON stores;
DROP POLICY IF EXISTS stores_all ON stores;
DROP POLICY IF EXISTS "Stores insert" ON stores;
DROP POLICY IF EXISTS "Stores update" ON stores;
DROP POLICY IF EXISTS "Stores select" ON stores;

-- Allow authenticated users to insert stores
CREATE POLICY stores_insert ON stores
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Allow authenticated users to update stores
CREATE POLICY stores_update ON stores
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Allow authenticated users to select stores
CREATE POLICY stores_select ON stores
FOR SELECT
TO authenticated
USING (true);

-- Allow anon to select stores (for public consumption)
CREATE POLICY stores_select_anon ON stores
FOR SELECT
TO anon
USING (true);

-- Verify RLS is enabled on stores
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;

-- Reload schema
NOTIFY pgrst, 'reload schema';

