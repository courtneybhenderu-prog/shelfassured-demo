-- ============================================================
-- ShelfAssured: OCA Duplicate Product Cleanup
-- Run in Supabase SQL Editor
-- ============================================================
-- Generated: 2026-03-21
-- Purpose: Remove duplicate products/skus created during field testing
-- Strategy: Keep the OLDEST record per unique key, delete newer duplicates
-- ============================================================

-- ── STEP 1: PREVIEW — Run this first to see what will be deleted ──

-- 1a. Duplicate products in the `products` table (by brand_id + name)
SELECT
  p.id,
  p.name,
  p.brand_id,
  b.name AS brand_name,
  p.identifier,
  p.created_at,
  ROW_NUMBER() OVER (PARTITION BY p.brand_id, p.name ORDER BY p.created_at ASC) AS row_num,
  CASE
    WHEN ROW_NUMBER() OVER (PARTITION BY p.brand_id, p.name ORDER BY p.created_at ASC) = 1
    THEN 'KEEP (oldest)'
    ELSE 'DELETE (duplicate)'
  END AS action
FROM products p
LEFT JOIN brands b ON b.id = p.brand_id
ORDER BY b.name, p.name, p.created_at;

-- 1b. Duplicate skus in the `skus` table (by upc)
SELECT
  s.id,
  s.name,
  s.upc,
  s.brand_id,
  b.name AS brand_name,
  s.created_at,
  ROW_NUMBER() OVER (PARTITION BY s.upc ORDER BY s.created_at ASC) AS row_num,
  CASE
    WHEN ROW_NUMBER() OVER (PARTITION BY s.upc ORDER BY s.created_at ASC) = 1
    THEN 'KEEP (oldest)'
    ELSE 'DELETE (duplicate)'
  END AS action
FROM skus s
LEFT JOIN brands b ON b.id = s.brand_id
WHERE s.upc IS NOT NULL
ORDER BY b.name, s.name, s.created_at;

-- 1c. Duplicate skus by brand_id + name (catches duplicates without UPC)
SELECT
  s.id,
  s.name,
  s.upc,
  s.brand_id,
  b.name AS brand_name,
  s.created_at,
  ROW_NUMBER() OVER (PARTITION BY s.brand_id, s.name ORDER BY s.created_at ASC) AS row_num,
  CASE
    WHEN ROW_NUMBER() OVER (PARTITION BY s.brand_id, s.name ORDER BY s.created_at ASC) = 1
    THEN 'KEEP (oldest)'
    ELSE 'DELETE (duplicate)'
  END AS action
FROM skus s
LEFT JOIN brands b ON b.id = s.brand_id
ORDER BY b.name, s.name, s.created_at;

-- ── STEP 2: EXECUTE CLEANUP ──────────────────────────────────
-- Review Step 1 output first, then uncomment and run these.

-- 2a. Delete duplicate products (keep oldest per brand_id + name)
-- DELETE FROM products
-- WHERE id IN (
--   SELECT id FROM (
--     SELECT id,
--            ROW_NUMBER() OVER (PARTITION BY brand_id, name ORDER BY created_at ASC) AS rn
--     FROM products
--   ) ranked
--   WHERE rn > 1
-- );

-- 2b. Delete duplicate skus by UPC (keep oldest per UPC)
-- DELETE FROM skus
-- WHERE id IN (
--   SELECT id FROM (
--     SELECT id,
--            ROW_NUMBER() OVER (PARTITION BY upc ORDER BY created_at ASC) AS rn
--     FROM skus
--     WHERE upc IS NOT NULL
--   ) ranked
--   WHERE rn > 1
-- );

-- 2c. Delete duplicate skus by brand_id + name (for skus without UPC)
-- DELETE FROM skus
-- WHERE id IN (
--   SELECT id FROM (
--     SELECT id,
--            ROW_NUMBER() OVER (PARTITION BY brand_id, name ORDER BY created_at ASC) AS rn
--     FROM skus
--   ) ranked
--   WHERE rn > 1
-- );

-- ── STEP 3: VERIFY ───────────────────────────────────────────
-- Run after cleanup to confirm no duplicates remain.

-- 3a. Check for remaining duplicate products
SELECT brand_id, name, COUNT(*) AS cnt
FROM products
GROUP BY brand_id, name
HAVING COUNT(*) > 1
ORDER BY cnt DESC;

-- 3b. Check for remaining duplicate skus by UPC
SELECT upc, COUNT(*) AS cnt
FROM skus
WHERE upc IS NOT NULL
GROUP BY upc
HAVING COUNT(*) > 1
ORDER BY cnt DESC;

-- 3c. Check for remaining duplicate skus by brand + name
SELECT brand_id, name, COUNT(*) AS cnt
FROM skus
GROUP BY brand_id, name
HAVING COUNT(*) > 1
ORDER BY cnt DESC;

-- ── STEP 4: ORPHAN CLEANUP ───────────────────────────────────
-- Remove brand_products junction rows pointing to deleted products.

-- Preview orphaned brand_products rows
SELECT bp.id, bp.brand_id, bp.product_id
FROM brand_products bp
LEFT JOIN products p ON p.id = bp.product_id
WHERE p.id IS NULL;

-- Delete orphaned brand_products rows (uncomment after reviewing)
-- DELETE FROM brand_products
-- WHERE product_id NOT IN (SELECT id FROM products);
