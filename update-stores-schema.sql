-- Update stores schema for brand onboarding
-- Run this in Supabase SQL editor

-- Add generated columns for backwards compatibility
ALTER TABLE stores ADD COLUMN IF NOT EXISTS state_zip text;
ALTER TABLE stores ADD COLUMN IF NOT EXISTS status text DEFAULT 'unverified';

-- Create generated column for zip5 (if it doesn't exist already)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'stores' AND column_name = 'zip5'
  ) THEN
    ALTER TABLE stores ADD COLUMN zip5 text GENERATED ALWAYS AS (
      substring(regexp_replace(zip_code, '\D', '', 'g'), 1, 5)
    ) STORED;
  END IF;
END $$;

-- Update state_zip generated column
ALTER TABLE stores 
  DROP COLUMN IF EXISTS state_zip CASCADE;

ALTER TABLE stores 
  ADD COLUMN state_zip text GENERATED ALWAYS AS (
    state || ' ' || zip_code
  ) STORED;

-- Create unique index for brands (normalized name + website)
CREATE UNIQUE INDEX IF NOT EXISTS brands_unique_name_site
ON brands (lower(name), coalesce(website, ''));

-- Reload schema
NOTIFY pgrst, 'reload schema';

