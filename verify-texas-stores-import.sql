-- Verification Script for Texas Stores Import
-- Run this after importing texas-stores-complete-import.sql

-- Check total stores imported
SELECT 
    'Total Texas Stores' as metric,
    COUNT(*) as count
FROM stores 
WHERE state = 'TX' AND is_active = true;

-- Check stores by chain/banner
SELECT 
    CASE 
        WHEN name ILIKE '%heb%' THEN 'H-E-B'
        WHEN name ILIKE '%whole foods%' THEN 'Whole Foods'
        WHEN name ILIKE '%tom thumb%' THEN 'Tom Thumb'
        WHEN name ILIKE '%sprouts%' THEN 'Sprouts'
        WHEN name ILIKE '%natural grocers%' THEN 'Natural Grocers'
        WHEN name ILIKE '%food lion%' THEN 'Food Lion'
        ELSE 'Other'
    END as chain_type,
    COUNT(*) as store_count
FROM stores 
WHERE state = 'TX' AND is_active = true
GROUP BY 
    CASE 
        WHEN name ILIKE '%heb%' THEN 'H-E-B'
        WHEN name ILIKE '%whole foods%' THEN 'Whole Foods'
        WHEN name ILIKE '%tom thumb%' THEN 'Tom Thumb'
        WHEN name ILIKE '%sprouts%' THEN 'Sprouts'
        WHEN name ILIKE '%natural grocers%' THEN 'Natural Grocers'
        WHEN name ILIKE '%food lion%' THEN 'Food Lion'
        ELSE 'Other'
    END
ORDER BY store_count DESC;

-- Check cities covered
SELECT 
    'Cities Covered' as metric,
    COUNT(DISTINCT city) as count
FROM stores 
WHERE state = 'TX' AND is_active = true;

-- Sample stores by city
SELECT 
    city,
    COUNT(*) as store_count,
    STRING_AGG(name, ', ' ORDER BY name LIMIT 3) as sample_stores
FROM stores 
WHERE state = 'TX' AND is_active = true
GROUP BY city
ORDER BY store_count DESC
LIMIT 10;

-- Check for stores with phone numbers
SELECT 
    'Stores with Phone Numbers' as metric,
    COUNT(*) as count
FROM stores 
WHERE state = 'TX' AND is_active = true AND phone IS NOT NULL AND phone != '';

-- Check for stores with ZIP codes
SELECT 
    'Stores with ZIP Codes' as metric,
    COUNT(*) as count
FROM stores 
WHERE state = 'TX' AND is_active = true AND zip_code IS NOT NULL AND zip_code != '';

-- Test search functionality
SELECT 
    'Search Test Results' as test,
    COUNT(*) as matches
FROM stores 
WHERE state = 'TX' AND is_active = true 
AND (
    name ILIKE '%houston%' OR 
    city ILIKE '%houston%' OR 
    address ILIKE '%houston%'
);

-- Show sample of imported data
SELECT 
    name,
    city,
    state,
    zip_code,
    phone,
    CASE 
        WHEN phone IS NOT NULL AND phone != '' THEN 'Yes'
        ELSE 'No'
    END as has_phone
FROM stores 
WHERE state = 'TX' AND is_active = true
ORDER BY name
LIMIT 20;
