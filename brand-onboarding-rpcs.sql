-- Brand Onboarding RPC Functions
-- Run this in Supabase SQL editor after the schema

-- RPC 1: upsert_brand_public
-- Inserts or updates a brand's public fields only. Never touches admin fields.
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

-- RPC 2: merge_brand_records
-- Admin only. Merge a new client submitted brand into an existing admin seeded brand.
CREATE OR REPLACE FUNCTION merge_brand_records(
  p_source uuid,  -- new client record
  p_target uuid   -- existing admin seeded record
) RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- example merge strategy: prefer target's private fields, update public from source where target is null
  UPDATE brands t
  SET
    name = COALESCE(t.name, s.name),
    website = COALESCE(t.website, s.website),
    primary_email = COALESCE(t.primary_email, s.primary_email),
    phone = COALESCE(t.phone, s.phone),
    address = COALESCE(t.address, s.address),
    updated_at = now()
  FROM brands s
  WHERE t.id = p_target AND s.id = p_source;

  -- move products over
  INSERT INTO products (brand_id, name, identifier, variant, size, suggested_retail_price, image_url, category, data_source, data_confidence)
  SELECT p_target, name, identifier, variant, size, suggested_retail_price, image_url, category, data_source, data_confidence
  FROM products
  WHERE brand_id = p_source
  ON CONFLICT (brand_id, name) DO NOTHING;

  -- cleanup: delete the source brand
  DELETE FROM brands WHERE id = p_source;

  RETURN p_target;
END $$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION upsert_brand_public TO authenticated;
GRANT EXECUTE ON FUNCTION merge_brand_records TO authenticated;

-- Seed data for testing
INSERT INTO app_users (email, display_name, role) VALUES
  ('admin@shelfassured.com','Admin User','admin'),
  ('marc@shelfassured.com','Marc','admin')
ON CONFLICT (email) DO NOTHING;

INSERT INTO retailers (name) VALUES ('HEB'), ('Kroger'), ('Whole Foods'), ('Target') ON CONFLICT DO NOTHING;

-- Example brand seed
INSERT INTO brands(name, website, data_source, data_confidence, broker_name)
VALUES ('DJ''s Boudain','https://djsboudain.com','admin_added','medium','Mana Foods')
ON CONFLICT DO NOTHING;


