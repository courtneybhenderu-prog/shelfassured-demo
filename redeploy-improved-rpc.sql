-- Check if the improved upsert_brand_public function is deployed
-- This should prevent future duplicates

-- Check current function definition
SELECT prosrc FROM pg_proc WHERE proname = 'upsert_brand_public';

-- If the function doesn't have name-based duplicate checking, redeploy it
CREATE OR REPLACE FUNCTION upsert_brand_public(
  p_id uuid,
  p_name text,
  p_website text,
  p_primary_email text,
  p_phone text,
  p_address text
) RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE v_id uuid;
BEGIN
  -- First, try to find existing brand by name (case-insensitive)
  SELECT id INTO v_id 
  FROM brands 
  WHERE LOWER(TRIM(name)) = LOWER(TRIM(p_name))
  LIMIT 1;
  
  -- If found existing brand, update it
  IF v_id IS NOT NULL THEN
    UPDATE brands
      SET name = p_name,
          website = p_website,
          primary_email = p_primary_email,
          phone = p_phone,
          address = p_address,
          updated_at = now()
    WHERE id = v_id
    RETURNING id INTO v_id;
  -- If p_id provided and no name match, update by ID
  ELSIF p_id IS NOT NULL THEN
    UPDATE brands
      SET name = p_name,
          website = p_website,
          primary_email = p_primary_email,
          phone = p_phone,
          address = p_address,
          updated_at = now()
    WHERE id = p_id
    RETURNING id INTO v_id;
  -- Otherwise, create new brand
  ELSE
    INSERT INTO brands(name, website, primary_email, phone, address, data_source, data_confidence)
    VALUES (p_name, p_website, p_primary_email, p_phone, p_address, 'client_supplied','medium')
    RETURNING id INTO v_id;
  END IF;
  
  RETURN v_id;
END $$;

-- Refresh PostgREST schema
NOTIFY pgrst, 'reload schema';


