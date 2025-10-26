-- Fix brands to use unique constraint
-- Run this in Supabase SQL editor

CREATE UNIQUE INDEX IF NOT EXISTS brands_unique_name_site
ON brands (lower(name), coalesce(website, ''));

-- Update upsert_brand_public to handle conflicts
CREATE OR REPLACE FUNCTION upsert_brand_public(
  p_id uuid,
  p_name text,
  p_website text,
  p_primary_email text,
  p_phone text,
  p_address text
) RETURNS uuid 
SECURITY DEFINER
LANGUAGE plpgsql AS $$
DECLARE v_id uuid;
BEGIN
  IF p_id IS NULL THEN
    INSERT INTO brands(name, website, primary_email, phone, address, data_source, data_confidence)
    VALUES (p_name, p_website, p_primary_email, p_phone, p_address, 'client_supplied','medium')
    ON CONFLICT (lower(name), coalesce(website, ''))
    DO UPDATE SET 
      website = EXCLUDED.website,
      primary_email = EXCLUDED.primary_email,
      phone = EXCLUDED.phone,
      address = EXCLUDED.address,
      updated_at = now()
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

GRANT EXECUTE ON FUNCTION upsert_brand_public TO authenticated;
GRANT EXECUTE ON FUNCTION upsert_brand_public TO anon;

