-- Cleanup Duplicate Products
-- Fixes cases where same SKU appears multiple times (e.g., from scanner + brand form)
-- Keeps one canonical product and links all brand references to it

BEGIN;

-- Step 1: Find duplicate products by SKU
-- (products that have the same sku or barcode value)
WITH duplicates AS (
    SELECT 
        COALESCE(sku, barcode) as unique_sku,
        COUNT(*) as dup_count,
        array_agg(id ORDER BY created_at) as product_ids,
        array_agg(name ORDER BY created_at) as product_names
    FROM products
    WHERE COALESCE(sku, barcode) IS NOT NULL
    GROUP BY COALESCE(sku, barcode)
    HAVING COUNT(*) > 1
)
SELECT 
    unique_sku,
    dup_count,
    product_ids[1] as keep_product_id,  -- Keep oldest product
    product_ids[2:] as duplicate_ids
FROM duplicates;

-- Step 2: For duplicate products, consolidate brand_products links
-- Move all brand_products references to the canonical (oldest) product
WITH duplicates AS (
    SELECT 
        COALESCE(sku, barcode) as unique_sku,
        array_agg(id ORDER BY created_at) as product_ids
    FROM products
    WHERE COALESCE(sku, barcode) IS NOT NULL
    GROUP BY COALESCE(sku, barcode)
    HAVING COUNT(*) > 1
),
product_mappings AS (
    SELECT 
        d.unique_sku,
        d.product_ids[1] as canonical_id,
        unnest(d.product_ids[2:]) as duplicate_id
    FROM duplicates d
)
-- Update brand_products to point to canonical product
UPDATE brand_products bp
SET product_id = pm.canonical_id
FROM product_mappings pm
WHERE bp.product_id = pm.duplicate_id
AND NOT EXISTS (
    -- Don't create duplicate links if canonical product already linked to same brand
    SELECT 1 FROM brand_products existing
    WHERE existing.brand_id = bp.brand_id
    AND existing.product_id = pm.canonical_id
);

-- Step 3: Delete duplicate products (keep only canonical ones)
WITH duplicates AS (
    SELECT 
        COALESCE(sku, barcode) as unique_sku,
        array_agg(id ORDER BY created_at) as product_ids
    FROM products
    WHERE COALESCE(sku, barcode) IS NOT NULL
    GROUP BY COALESCE(sku, barcode)
    HAVING COUNT(*) > 1
)
DELETE FROM products p
USING duplicates d
WHERE p.id = ANY(d.product_ids[2:])  -- Delete all except first (oldest)
AND COALESCE(p.sku, p.barcode) = d.unique_sku;

-- Step 4: Report results
DO $$
DECLARE
    remaining_dupes INTEGER;
BEGIN
    SELECT COUNT(*) INTO remaining_dupes
    FROM (
        SELECT COALESCE(sku, barcode) as unique_sku
        FROM products
        WHERE COALESCE(sku, barcode) IS NOT NULL
        GROUP BY COALESCE(sku, barcode)
        HAVING COUNT(*) > 1
    ) dupes;
    
    IF remaining_dupes = 0 THEN
        RAISE NOTICE '✅ All duplicate products cleaned up';
    ELSE
        RAISE NOTICE '⚠️ % duplicate SKUs still remain (may need manual review)', remaining_dupes;
    END IF;
END $$;

COMMIT;

-- Verification query (run separately):
-- Find remaining duplicates
-- SELECT 
--     COALESCE(sku, barcode) as unique_sku,
--     COUNT(*) as count,
--     array_agg(name ORDER BY created_at) as product_names,
--     array_agg(id ORDER BY created_at) as product_ids
-- FROM products
-- WHERE COALESCE(sku, barcode) IS NOT NULL
-- GROUP BY COALESCE(sku, barcode)
-- HAVING COUNT(*) > 1;


