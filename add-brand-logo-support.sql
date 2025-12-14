-- Add logo_url column to brands table if it doesn't exist
-- This is safe to run multiple times

ALTER TABLE brands ADD COLUMN IF NOT EXISTS logo_url TEXT;

-- Add comment for documentation
COMMENT ON COLUMN brands.logo_url IS 'URL to brand logo image (Supabase Storage or external URL)';


