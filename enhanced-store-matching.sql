-- Enhanced Store Matching Schema
-- Run this in Supabase SQL editor

-- Add normalized columns for better matching
ALTER TABLE stores ADD COLUMN IF NOT EXISTS street_norm text;
ALTER TABLE stores ADD COLUMN IF NOT EXISTS city_norm text;
ALTER TABLE stores ADD COLUMN IF NOT EXISTS zip5 text;
ALTER TABLE stores ADD COLUMN IF NOT EXISTS retailer_norm text;

-- Create function to normalize store data
CREATE OR REPLACE FUNCTION normalize_store_data()
RETURNS TRIGGER AS $$
BEGIN
  -- Normalize street address
  NEW.street_norm := lower(regexp_replace(
    regexp_replace(
      regexp_replace(
        regexp_replace(
          regexp_replace(NEW.address, '\b(rd|road)\b', 'road', 'gi'),
          '\b(st|street)\b', 'street', 'gi'
        ),
        '\b(ave|avenue)\b', 'avenue', 'gi'
      ),
      '\b(blvd|boulevard)\b', 'boulevard', 'gi'
    ),
    '\b(ste|suite)\s*#?\d*', '', 'gi'
  ));
  
  -- Normalize city
  NEW.city_norm := lower(trim(NEW.city));
  
  -- Extract ZIP5
  NEW.zip5 := substring(NEW.zip_code from '\d{5}');
  
  -- Normalize retailer
  NEW.retailer_norm := lower(regexp_replace(
    regexp_replace(NEW.store_chain, '\bheb\b', 'h-e-b', 'gi'),
    '[^a-z0-9-]', '', 'g'
  ));
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-normalize on insert/update
DROP TRIGGER IF EXISTS normalize_store_trigger ON stores;
CREATE TRIGGER normalize_store_trigger
  BEFORE INSERT OR UPDATE ON stores
  FOR EACH ROW EXECUTE FUNCTION normalize_store_data();

-- Create unique index to prevent duplicates
CREATE UNIQUE INDEX IF NOT EXISTS stores_unique_norm
ON stores (retailer_norm, street_norm, city_norm, state, zip5)
WHERE street_norm IS NOT NULL AND city_norm IS NOT NULL AND zip5 IS NOT NULL;

-- Backfill existing data
UPDATE stores SET 
  street_norm = lower(regexp_replace(
    regexp_replace(
      regexp_replace(
        regexp_replace(
          regexp_replace(address, '\b(rd|road)\b', 'road', 'gi'),
          '\b(st|street)\b', 'street', 'gi'
        ),
        '\b(ave|avenue)\b', 'avenue', 'gi'
      ),
      '\b(blvd|boulevard)\b', 'boulevard', 'gi'
    ),
    '\b(ste|suite)\s*#?\d*', '', 'gi'
  )),
  city_norm = lower(trim(city)),
  zip5 = substring(zip_code from '\d{5}'),
  retailer_norm = lower(regexp_replace(
    regexp_replace(store_chain, '\bheb\b', 'h-e-b', 'gi'),
    '[^a-z0-9-]', '', 'g'
  ))
WHERE street_norm IS NULL;

