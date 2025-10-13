-- Texas Stores Complete Import - All 2,339 Stores
-- This script will import all Texas stores from the Google Sheet
-- Note: This is a template - the actual data needs to be extracted from the full Google Sheet

-- First, let's check current store count
SELECT COUNT(*) as current_store_count FROM stores;

-- Clear any existing Texas import data to avoid duplicates
DELETE FROM stores WHERE source = 'texas_import';

-- Import all Texas stores (this is a template - needs actual data from Google Sheet)
-- The Google Sheet contains 2,339 stores total
-- We need to extract the complete data and convert to INSERT statements

-- Template structure for importing:
INSERT INTO stores (name, address, city, state, zip_code, phone, chain, metro_area, source)
VALUES 
-- This section needs to be populated with all 2,339 stores from the Google Sheet
-- Each row should follow this format:
-- ('STORE_NAME', 'ADDRESS', 'CITY', 'TX', 'ZIP_CODE', 'PHONE', 'CHAIN', 'METRO_AREA', 'texas_import'),

-- Placeholder - this needs to be replaced with actual data
('PLACEHOLDER_STORE', 'PLACEHOLDER_ADDRESS', 'PLACEHOLDER_CITY', 'TX', '00000', '0000000000', 'PLACEHOLDER_CHAIN', 'PLACEHOLDER_METRO', 'texas_import');

-- Check final store count
SELECT COUNT(*) as final_store_count FROM stores;

-- Show stores by chain
SELECT chain, COUNT(*) as store_count 
FROM stores 
WHERE source = 'texas_import'
GROUP BY chain 
ORDER BY store_count DESC;

-- Show stores by metro area
SELECT metro_area, COUNT(*) as store_count 
FROM stores 
WHERE source = 'texas_import'
GROUP BY metro_area 
ORDER BY store_count DESC;

-- Show total stores by source
SELECT source, COUNT(*) as store_count 
FROM stores 
GROUP BY source 
ORDER BY store_count DESC;
