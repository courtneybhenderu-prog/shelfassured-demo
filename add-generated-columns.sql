-- Add generated columns for zip5 and state_zip if they don't exist
-- These are computed columns to simplify queries

-- Check if columns exist
DO $$
BEGIN
  -- Add zip5 as generated column (first 5 digits of zip_code)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name='stores' AND column_name='zip5'
  ) THEN
    ALTER TABLE stores 
    ADD COLUMN zip5 TEXT GENERATED ALWAYS AS (
      SUBSTRING(REGEXP_REPLACE(zip_code, '\D', '', 'g') FROM 1 FOR 5)
    ) STORED;
  END IF;

  -- Add state_zip as generated column (state + zip in format "TX 77057")
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name='stores' AND column_name='state_zip'
  ) THEN
    ALTER TABLE stores 
    ADD COLUMN state_zip TEXT GENERATED ALWAYS AS (
      state || ' ' || zip_code
    ) STORED;
  END IF;
END $$;

-- Verify columns exist
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name='stores' 
  AND column_name IN ('banner_id', 'status', 'zip5', 'state_zip')
ORDER BY column_name;

