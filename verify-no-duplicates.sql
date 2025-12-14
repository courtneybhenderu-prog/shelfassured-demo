-- Verify: Check if duplicates still exist
-- Run this to confirm everything is clean

-- Find duplicate products by SKU
SELECT 
    COALESCE(sku, barcode) as unique_sku,
    COUNT(*) as duplicate_count,
    array_agg(id ORDER BY created_at) as product_ids,
    array_agg(name ORDER BY created_at) as product_names
FROM products
WHERE COALESCE(sku, barcode) IS NOT NULL
GROUP BY COALESCE(sku, barcode)
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


