-- ========================================
-- Store Reconciliation - Matching Diagnostics
-- Run this AFTER uploading Excel CSV to stores_import table
-- ========================================
-- This script shows why stores aren't matching by comparing match keys

-- Step 0: Check if stores_import table exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'stores_import'
    ) THEN
        RAISE EXCEPTION 'Table "stores_import" does not exist. Please upload your Excel file first:
        
1. Go to Supabase Dashboard → Table Editor
2. Click "New Table" 
3. Name it: stores_import
4. Click "Import data" and upload your Excel/CSV file
5. Make sure column names match: CHAIN, DIVISION, BANNER, STORE LOCATION NAME, STORE, Store #, ADDRESS, CITY, STATE, ZIP, METRO, PHONE

Or if your table has a different name, update the script to use that table name.';
    END IF;
END $$;

-- Step 1: Ensure stores_import table has normalized columns
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS banner_norm TEXT;
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS address_norm TEXT;
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS city_norm TEXT;
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS state_norm TEXT;
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS zip5 TEXT;
ALTER TABLE stores_import ADD COLUMN IF NOT EXISTS match_key TEXT;

-- Step 2: Normalize stores_import data
UPDATE stores_import SET
    banner_norm = LOWER(TRIM(COALESCE("BANNER", ''))),
    address_norm = LOWER(REGEXP_REPLACE(
        REGEXP_REPLACE(
            REGEXP_REPLACE(
                REGEXP_REPLACE(TRIM(COALESCE("ADDRESS", '')), '\b(st|street|rd|road|ave|avenue|blvd|boulevard|dr|drive|ln|lane|ct|court|pl|place)\b', '', 'gi'),
                '\b(ste|suite|unit|#)\s*\d*\b', '', 'gi'
            ),
            '[^\w\s]', '', 'g'
        ),
        '\s+', ' ', 'g'
    )),
    city_norm = LOWER(TRIM(COALESCE("CITY", ''))),
    state_norm = UPPER(LEFT(TRIM(COALESCE("STATE", '')), 2)),
    zip5 = LPAD(SUBSTRING(COALESCE("ZIP", '') FROM '\d{5}'), 5, '0')
WHERE banner_norm IS NULL;

-- Step 3: Create match keys
UPDATE stores_import SET
    match_key = banner_norm || '|' || address_norm || '|' || city_norm || '|' || state_norm || '|' || zip5
WHERE match_key IS NULL;

-- Step 4: Ensure stores table has normalized columns (if not already)
-- Note: zip5 might be a generated column, so we'll use a different name for our normalized version
ALTER TABLE stores ADD COLUMN IF NOT EXISTS banner_norm TEXT;
ALTER TABLE stores ADD COLUMN IF NOT EXISTS address_norm TEXT;
ALTER TABLE stores ADD COLUMN IF NOT EXISTS city_norm TEXT;
ALTER TABLE stores ADD COLUMN IF NOT EXISTS state_norm TEXT;
ALTER TABLE stores ADD COLUMN IF NOT EXISTS zip5_norm TEXT;  -- Use zip5_norm to avoid conflict with generated column
ALTER TABLE stores ADD COLUMN IF NOT EXISTS match_key TEXT;

-- Step 5: Normalize existing stores data (if not already normalized)
-- Note: zip5 is a generated column, so we'll compute zip5_norm from zip_code
UPDATE stores SET
    banner_norm = LOWER(TRIM(COALESCE(banner, "STORE", name, ''))),
    address_norm = LOWER(REGEXP_REPLACE(
        REGEXP_REPLACE(
            REGEXP_REPLACE(
                REGEXP_REPLACE(TRIM(COALESCE(address, '')), '\b(st|street|rd|road|ave|avenue|blvd|boulevard|dr|drive|ln|lane|ct|court|pl|place)\b', '', 'gi'),
                '\b(ste|suite|unit|#)\s*\d*\b', '', 'gi'
            ),
            '[^\w\s]', '', 'g'
        ),
        '\s+', ' ', 'g'
    )),
    city_norm = LOWER(TRIM(COALESCE(city, ''))),
    state_norm = UPPER(LEFT(TRIM(COALESCE(state, '')), 2)),
    zip5_norm = LPAD(SUBSTRING(COALESCE(zip_code, '') FROM '\d{5}'), 5, '0')
WHERE banner_norm IS NULL OR address_norm IS NULL;

-- Step 6: Create match keys for existing stores
-- Use zip5_norm (computed from zip_code, or use generated zip5 if it exists and matches)
UPDATE stores SET
    match_key = banner_norm || '|' || address_norm || '|' || city_norm || '|' || state_norm || '|' || COALESCE(zip5_norm, COALESCE(zip5::text, LPAD(SUBSTRING(COALESCE(zip_code, '') FROM '\d{5}'), 5, '0')))
WHERE match_key IS NULL;

-- ========================================
-- DIAGNOSTICS: First 20 Excel rows (excluding empty rows)
-- ========================================
SELECT 
    'EXCEL ROW' as source,
    ROW_NUMBER() OVER () as row_num,
    "BANNER" as banner_raw,
    banner_norm,
    "ADDRESS" as address_raw,
    address_norm,
    "CITY" as city_raw,
    city_norm,
    "STATE" as state_raw,
    state_norm,
    "ZIP" as zip_raw,
    zip5,
    match_key,
    CASE 
        WHEN EXISTS (SELECT 1 FROM stores s WHERE s.match_key = stores_import.match_key) 
        THEN '✅ MATCH FOUND' 
        ELSE '❌ NO MATCH' 
    END as match_status
FROM stores_import
WHERE ("BANNER" IS NOT NULL AND "BANNER" != '') 
   OR ("ADDRESS" IS NOT NULL AND "ADDRESS" != '')
ORDER BY id
LIMIT 20;

-- ========================================
-- DIAGNOSTICS: 20 Existing Supabase stores
-- ========================================
SELECT 
    'SUPABASE STORE' as source,
    ROW_NUMBER() OVER () as row_num,
    COALESCE(banner, "STORE", name) as banner_raw,
    banner_norm,
    address as address_raw,
    address_norm,
    city as city_raw,
    city_norm,
    state as state_raw,
    state_norm,
    zip_code as zip_raw,
    COALESCE(zip5_norm, COALESCE(zip5::text, LPAD(SUBSTRING(COALESCE(zip_code, '') FROM '\d{5}'), 5, '0'))) as zip5,
    match_key,
    "STORE" as store_field,
    name as name_field
FROM stores
WHERE match_key IS NOT NULL
ORDER BY created_at DESC
LIMIT 20;

-- ========================================
-- DIAGNOSTICS: Match Statistics
-- ========================================
SELECT 
    'MATCH STATISTICS' as info,
    (SELECT COUNT(*) FROM stores_import) as total_excel_rows,
    (SELECT COUNT(*) FROM stores_import 
     WHERE ("BANNER" IS NOT NULL AND "BANNER" != '') 
        OR ("ADDRESS" IS NOT NULL AND "ADDRESS" != '')) as excel_rows_with_data,
    (SELECT COUNT(*) FROM stores) as total_stores,
    (SELECT COUNT(DISTINCT match_key) FROM stores_import WHERE match_key IS NOT NULL) as unique_excel_keys,
    (SELECT COUNT(DISTINCT match_key) FROM stores WHERE match_key IS NOT NULL) as unique_store_keys,
    (SELECT COUNT(*) 
     FROM stores_import si 
     WHERE (si."BANNER" IS NOT NULL AND si."BANNER" != '') 
        OR (si."ADDRESS" IS NOT NULL AND si."ADDRESS" != '')
       AND EXISTS (SELECT 1 FROM stores s WHERE s.match_key = si.match_key)) as matched_count,
    (SELECT COUNT(*) 
     FROM stores_import si 
     WHERE (si."BANNER" IS NOT NULL AND si."BANNER" != '') 
        OR (si."ADDRESS" IS NOT NULL AND si."ADDRESS" != '')
       AND NOT EXISTS (SELECT 1 FROM stores s WHERE s.match_key = si.match_key)) as new_count;

