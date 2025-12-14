-- Check brand logos in database
SELECT 
    id,
    name,
    logo_url,
    CASE 
        WHEN logo_url IS NULL THEN 'NULL'
        WHEN logo_url = '' THEN 'EMPTY'
        WHEN logo_url LIKE '%brand logos%' THEN 'HAS SPACE (needs fix)'
        WHEN logo_url LIKE '%brand_logos%' THEN 'HAS UNDERSCORE (correct)'
        ELSE 'OTHER FORMAT'
    END as url_status,
    LENGTH(logo_url) as url_length
FROM brands
WHERE logo_url IS NOT NULL AND logo_url != ''
ORDER BY created_at DESC;

-- Count brands with/without logos
SELECT 
    COUNT(*) FILTER (WHERE logo_url IS NOT NULL AND logo_url != '') as with_logos,
    COUNT(*) FILTER (WHERE logo_url IS NULL OR logo_url = '') as without_logos,
    COUNT(*) as total_brands
FROM brands;


