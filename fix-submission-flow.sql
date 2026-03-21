-- ============================================================
-- ShelfAssured: Fix Job Submission Flow
-- Run in Supabase SQL Editor
-- ============================================================
-- Generated: 2026-03-21
-- Fixes:
--   1. jobs.status constraint missing 'pending_review'
--   2. submission_type constraint (verify it allows 'photo')
--   3. Duplicate OCA products cleanup
-- ============================================================

-- ── 1. FIX jobs.status CONSTRAINT ───────────────────────────
-- The current constraint does not include 'pending_review',
-- which causes the shelfer submission flow to fail when the
-- app tries to set status = 'pending_review'.

-- Step 1a: Find and drop the existing constraint
DO $$
DECLARE
  v_constraint_name text;
BEGIN
  SELECT constraint_name
    INTO v_constraint_name
    FROM information_schema.table_constraints
   WHERE table_schema = 'public'
     AND table_name   = 'jobs'
     AND constraint_type = 'CHECK'
     AND constraint_name ILIKE '%status%'
   LIMIT 1;

  IF v_constraint_name IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.jobs DROP CONSTRAINT %I', v_constraint_name);
    RAISE NOTICE 'Dropped constraint: %', v_constraint_name;
  ELSE
    RAISE NOTICE 'No status CHECK constraint found on jobs — may already be clean';
  END IF;
END $$;

-- Step 1b: Add the corrected constraint that includes 'pending_review'
ALTER TABLE public.jobs
  ADD CONSTRAINT jobs_status_check
  CHECK (status IN (
    'pending',
    'assigned',
    'in_progress',
    'pending_review',
    'completed',
    'cancelled',
    'rejected'
  ));

-- Verify
SELECT constraint_name, check_clause
  FROM information_schema.check_constraints
 WHERE constraint_schema = 'public'
   AND constraint_name = 'jobs_status_check';

-- ── 2. VERIFY submission_type CONSTRAINT ────────────────────
-- The app sends 'photo' which is valid per the schema.
-- This block verifies the constraint is correct and adds it
-- if it was somehow dropped.

DO $$
DECLARE
  v_constraint_name text;
BEGIN
  SELECT constraint_name
    INTO v_constraint_name
    FROM information_schema.table_constraints
   WHERE table_schema = 'public'
     AND table_name   = 'job_submissions'
     AND constraint_type = 'CHECK'
     AND constraint_name ILIKE '%submission_type%'
   LIMIT 1;

  IF v_constraint_name IS NULL THEN
    -- Constraint is missing — add it
    ALTER TABLE public.job_submissions
      ADD CONSTRAINT job_submissions_submission_type_check
      CHECK (submission_type IN ('photo', 'inventory_data', 'price_data', 'shelf_data', 'not_found'));
    RAISE NOTICE 'Added submission_type constraint (was missing)';
  ELSE
    RAISE NOTICE 'submission_type constraint exists: %', v_constraint_name;
    -- Drop and recreate to ensure 'not_found' is included for the Not Found flow
    EXECUTE format('ALTER TABLE public.job_submissions DROP CONSTRAINT %I', v_constraint_name);
    ALTER TABLE public.job_submissions
      ADD CONSTRAINT job_submissions_submission_type_check
      CHECK (submission_type IN ('photo', 'inventory_data', 'price_data', 'shelf_data', 'not_found'));
    RAISE NOTICE 'Recreated submission_type constraint with not_found value';
  END IF;
END $$;

-- ── 3. DUPLICATE OCA PRODUCTS CLEANUP ───────────────────────
-- Remove duplicate products from field testing.
-- Strategy: keep the OLDEST record per (brand_id, name) pair,
-- delete the newer duplicates.

-- Step 3a: Preview what will be deleted (run this first to verify)
SELECT
  p.id,
  p.name,
  p.brand_id,
  b.name AS brand_name,
  p.created_at,
  'WILL DELETE' AS action
FROM products p
JOIN brands b ON b.id = p.brand_id
WHERE p.id NOT IN (
  -- Keep the oldest record per brand_id + name
  SELECT DISTINCT ON (brand_id, name) id
    FROM products
   ORDER BY brand_id, name, created_at ASC
)
ORDER BY b.name, p.name, p.created_at;

-- Step 3b: Also check skus table for duplicates
SELECT
  s.id,
  s.name,
  s.upc,
  s.brand_id,
  b.name AS brand_name,
  s.created_at,
  'DUPLICATE SKU' AS note
FROM skus s
JOIN brands b ON b.id = s.brand_id
WHERE s.id NOT IN (
  SELECT DISTINCT ON (upc) id
    FROM skus
   WHERE upc IS NOT NULL
   ORDER BY upc, created_at ASC
)
AND s.upc IS NOT NULL
ORDER BY b.name, s.name;

-- Step 3c: Delete duplicate products (uncomment after reviewing Step 3a)
-- DELETE FROM products
-- WHERE id NOT IN (
--   SELECT DISTINCT ON (brand_id, name) id
--     FROM products
--    ORDER BY brand_id, name, created_at ASC
-- );

-- Step 3d: Delete duplicate skus (uncomment after reviewing Step 3b)
-- DELETE FROM skus
-- WHERE id NOT IN (
--   SELECT DISTINCT ON (upc) id
--     FROM skus
--    WHERE upc IS NOT NULL
--    ORDER BY upc, created_at ASC
-- )
-- AND upc IS NOT NULL;

-- ── 4. HEALTH CHECK ─────────────────────────────────────────
-- Run after applying fixes to confirm everything is clean.

SELECT 'jobs.status constraint' AS check_name,
       check_clause
  FROM information_schema.check_constraints
 WHERE constraint_schema = 'public'
   AND constraint_name = 'jobs_status_check'

UNION ALL

SELECT 'submission_type constraint' AS check_name,
       check_clause
  FROM information_schema.check_constraints
 WHERE constraint_schema = 'public'
   AND constraint_name = 'job_submissions_submission_type_check';
