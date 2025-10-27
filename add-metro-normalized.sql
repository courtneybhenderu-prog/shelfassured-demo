-- Add metro_norm field for normalized metro matching
-- Only run if metro_norm doesn't exist

-- Add metro_norm column
ALTER TABLE stores ADD COLUMN IF NOT EXISTS metro_norm TEXT;

-- Backfill metro_norm from metro
UPDATE stores
SET metro_norm = LOWER(REGEXP_REPLACE(metro, '\s+', ' ', 'g'))
WHERE metro IS NOT NULL AND (metro_norm IS NULL OR metro_norm='');

-- Create index for metro searches
CREATE INDEX IF NOT EXISTS stores_metro_norm_idx ON stores(metro_norm);

-- Verify
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name='stores' AND column_name IN ('metro', 'metro_norm');

