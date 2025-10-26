-- Add missing columns to stores table
-- Run this in Supabase SQL editor

ALTER TABLE stores ADD COLUMN IF NOT EXISTS state_zip text;
ALTER TABLE stores ADD COLUMN IF NOT EXISTS status text DEFAULT 'unverified';

-- Then reload schema
NOTIFY pgrst, 'reload schema';

