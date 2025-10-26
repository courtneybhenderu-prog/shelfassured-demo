-- Brand Onboarding Database Schema (Updated for existing brands table)
-- Run this in Supabase SQL editor

-- Add missing columns to existing brands table
ALTER TABLE brands ADD COLUMN IF NOT EXISTS website text;
ALTER TABLE brands ADD COLUMN IF NOT EXISTS primary_email text;
ALTER TABLE brands ADD COLUMN IF NOT EXISTS phone text;
ALTER TABLE brands ADD COLUMN IF NOT EXISTS address text;
ALTER TABLE brands ADD COLUMN IF NOT EXISTS broker_name text;
ALTER TABLE brands ADD COLUMN IF NOT EXISTS broker_agreement text;
ALTER TABLE brands ADD COLUMN IF NOT EXISTS nda_status text;
ALTER TABLE brands ADD COLUMN IF NOT EXISTS data_source text;
ALTER TABLE brands ADD COLUMN IF NOT EXISTS data_confidence text;
ALTER TABLE brands ADD COLUMN IF NOT EXISTS visibility jsonb DEFAULT '{}'::jsonb;

-- 1. Users and roles (create if not exists)
CREATE TABLE IF NOT EXISTS app_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  display_name text,
  role text NOT NULL CHECK (role IN ('admin','brand','shelfer')),
  created_at timestamptz DEFAULT now()
);

-- 3. Products (create if not exists)
CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  brand_id uuid NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
  name text NOT NULL,
  identifier text NOT NULL,       -- UPC or temp code
  variant text,
  size text,
  suggested_retail_price numeric,
  image_url text,
  category text,
  data_source text,
  data_confidence text,
  created_at timestamptz DEFAULT now(),
  UNIQUE (brand_id, name),
  UNIQUE (brand_id, identifier)
);

-- 4. Retailers and stores (create if not exists)
CREATE TABLE IF NOT EXISTS retailers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS stores (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  retailer_id uuid REFERENCES retailers(id),
  name text,                      -- optional, e.g., "HEB Bridgeland"
  address text,
  city text,
  state text,
  zip text,
  latitude double precision,
  longitude double precision,
  status text NOT NULL DEFAULT 'unverified' CHECK (status IN ('verified','unverified')),
  created_at timestamptz DEFAULT now()
);

-- 5. Jobs (create if not exists)
CREATE TABLE IF NOT EXISTS jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  brand_id uuid NOT NULL REFERENCES brands(id),
  product_id uuid NOT NULL REFERENCES products(id),
  store_id uuid NOT NULL REFERENCES stores(id),
  tier text NOT NULL CHECK (tier IN ('standard','launch','rush')),
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open','in_progress','submitted','approved','rejected','paid')),
  instructions text,
  created_at timestamptz DEFAULT now()
);

-- 6. Photos from jobs (create if not exists)
CREATE TABLE IF NOT EXISTS job_photos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id uuid NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  url text NOT NULL,
  type text,                      -- before, after, tag, etc.
  ai_checks jsonb,                -- lighting, focus, product visible
  created_at timestamptz DEFAULT now()
);

-- Enable RLS (if not already enabled)
ALTER TABLE brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_photos ENABLE ROW LEVEL SECURITY;

-- Simple RLS policies (tighten later)
-- Admins can do everything
DROP POLICY IF EXISTS admin_all_brands ON brands;
CREATE POLICY admin_all_brands ON brands FOR ALL
  USING (EXISTS (SELECT 1 FROM app_users u WHERE u.id = auth.uid() AND u.role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM app_users u WHERE u.id = auth.uid() AND u.role = 'admin'));

-- Brands can read only their public fields (served via a filtered view, below)
-- Easiest: serve brand dashboards through a SQL view that strips private fields.
CREATE OR REPLACE VIEW brands_public AS
SELECT
  id, name, website, primary_email, phone, address, created_at, updated_at
FROM brands;

ALTER VIEW brands_public SET (security_invoker = true);

-- Grant access to authenticated users
GRANT SELECT ON brands_public TO authenticated;
GRANT ALL ON brands TO authenticated;
GRANT ALL ON products TO authenticated;
GRANT ALL ON stores TO authenticated;
GRANT ALL ON jobs TO authenticated;
GRANT ALL ON job_photos TO authenticated;
GRANT ALL ON retailers TO authenticated;
GRANT ALL ON app_users TO authenticated;

