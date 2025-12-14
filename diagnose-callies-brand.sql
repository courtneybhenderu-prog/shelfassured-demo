-- Diagnose the exact characters in "Callie's Hot Little Biscuit" entries
-- This will reveal any hidden Unicode characters causing the duplication

SELECT 
    id,
    brand,
    LENGTH(brand) as char_count,
    -- Show each character's Unicode code point
    array_agg(ASCII(SUBSTRING(brand FROM i FOR 1)) ORDER BY i) as char_codes,
    -- Show positions where characters differ
    SUBSTRING(brand FROM 1 FOR 50) as first_50_chars,
    created_at
FROM products,
LATERAL generate_series(1, LENGTH(brand)) AS i
WHERE brand LIKE '%Callie%'
GROUP BY id, brand, created_at
ORDER BY created_at;

-- Simpler version: show hex representation to see exact bytes
SELECT 
    id,
    brand,
    ENCODE(brand::bytea, 'hex') as hex_representation,
    created_at
FROM products
WHERE brand LIKE '%Callie%'
ORDER BY created_at;


