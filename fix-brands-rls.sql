-- Fix RLS policy for brands table
-- Run this in Supabase SQL editor

-- Drop existing policies if they exist
DROP POLICY IF EXISTS anon_insert_brands ON brands;
DROP POLICY IF EXISTS anon_update_brands ON brands;
DROP POLICY IF EXISTS anon_select_brands ON brands;
DROP POLICY IF EXISTS admin_all_brands ON brands;
DROP POLICY IF EXISTS brands_insert ON brands;
DROP POLICY IF EXISTS brands_select ON brands;

-- Allow authenticated users to insert brands
CREATE POLICY brands_insert ON brands
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Allow authenticated users to update brands
CREATE POLICY brands_update ON brands
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- Allow authenticated users to select brands
CREATE POLICY brands_select ON brands
FOR SELECT
TO authenticated
USING (true);

-- Allow anon/guest users to select brands (public brands)
CREATE POLICY anon_select_brands ON brands
FOR SELECT
TO anon
USING (true);

-- Make sure upsert_brand_public is SECURITY DEFINER (bypasses RLS)
CREATE OR REPLACE FUNCTION upsert_brand_public(
  p_id uuid,
  p_name text,
  p_website text,
  p_primary_email text,
  p_phone text,
  p_address text
) RETURNS uuid 
SECURITY DEFINER -- This bypasses RLS
LANGUAGE plpgsql AS $$
DECLARE v_id uuid;
BEGIN
  IF p_id IS NULL THEN
    INSERT INTO brands(name, website, primary_email, phone, address, data_source, data_confidence)
    VALUES (p_name, p_website, p_primary_email, p_phone, p_address, 'client_supplied','medium')
    RETURNING id INTO v_id;
  ELSE
    UPDATE brands
      SET name = p_name,
          website = p_website,
          primary_email = p_primary_email,
          phone = p_phone,
          address = p_address,
          updated_at = now()
    WHERE id = p_id
    RETURNING id INTO v_id;
  END IF;
  RETURN v_id;
END $$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION upsert_brand_public TO authenticated;
GRANT EXECUTE ON FUNCTION upsert_brand_public TO anon;

