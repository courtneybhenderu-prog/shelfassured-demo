-- ========================================
-- Update Brand Logo - Quick SQL Script
-- ========================================
-- Use this to quickly update a brand's logo URL directly in the database
-- 
-- Option 1: Update by brand name
-- ========================================

-- Example: Update Evive logo with a URL
-- Replace 'https://example.com/logo.png' with the actual logo URL
/*
UPDATE brands
SET logo_url = 'https://example.com/logo.png'
WHERE name = 'Evive';
*/

-- ========================================
-- Option 2: Update by brand ID
-- ========================================

-- First, find the brand ID:
SELECT id, name, logo_url 
FROM brands 
WHERE name = 'Evive';

-- Then update using the ID:
/*
UPDATE brands
SET logo_url = 'https://example.com/logo.png'
WHERE id = 'paste-brand-id-here';
*/

-- ========================================
-- Option 3: Update multiple brands at once
-- ========================================

-- Example: Update multiple brands with their logo URLs
/*
UPDATE brands
SET logo_url = CASE
    WHEN name = 'Evive' THEN 'https://evivenutrition.com/logo.png'
    WHEN name = 'Brand2' THEN 'https://brand2.com/logo.png'
    WHEN name = 'Brand3' THEN 'https://brand3.com/logo.png'
    ELSE logo_url  -- Keep existing logo for other brands
END
WHERE name IN ('Evive', 'Brand2', 'Brand3');
*/

-- ========================================
-- Option 4: Check current logo status
-- ========================================

-- See which brands have logos and which don't:
SELECT 
    name,
    CASE 
        WHEN logo_url IS NULL OR logo_url = '' THEN '❌ No Logo'
        ELSE '✅ Has Logo'
    END as logo_status,
    logo_url
FROM brands
ORDER BY 
    CASE WHEN logo_url IS NULL OR logo_url = '' THEN 0 ELSE 1 END,
    name;

-- ========================================
-- Option 5: Clear/Remove a logo
-- ========================================

-- To remove a logo (set it to NULL):
/*
UPDATE brands
SET logo_url = NULL
WHERE name = 'Evive';
*/

-- ========================================
-- NOTES:
-- ========================================
-- 1. Logo URLs should be:
--    - Publicly accessible (no authentication required)
--    - Use HTTPS (secure)
--    - Direct links to image files (.png, .jpg, .svg)
--
-- 2. Good sources for logo URLs:
--    - Brand's official website
--    - CDN (Content Delivery Network)
--    - Supabase Storage (if uploaded via admin panel)
--
-- 3. Example URLs:
--    - https://evivenutrition.com/wp-content/uploads/logo.png
--    - https://cdn.example.com/brands/evive-logo.svg
--    - https://[your-project].supabase.co/storage/v1/object/public/brand_logos/abc123_logo.png
--
-- 4. After updating, refresh the admin dashboard to see the logo
