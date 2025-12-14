-- Comprehensive Job Creation Form Verification
-- Run all queries to ensure database matches code expectations

-- ==========================================
-- QUERY 1: jobs table structure (already verified ✅)
-- ==========================================
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'jobs' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- ==========================================
-- QUERY 2: job_store_skus table structure
-- ==========================================
-- Expected columns: job_id, store_id, sku_id
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'job_store_skus' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- ==========================================
-- QUERY 3: Check unique constraint on job_store_skus
-- ==========================================
-- Code expects: onConflict: 'job_id,store_id,sku_id'
-- This means there should be a UNIQUE constraint on these 3 columns
SELECT
    tc.constraint_name,
    tc.constraint_type,
    string_agg(kcu.column_name, ', ' ORDER BY kcu.ordinal_position) AS columns
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
WHERE tc.table_name = 'job_store_skus'
  AND tc.table_schema = 'public'
  AND tc.constraint_type IN ('UNIQUE', 'PRIMARY KEY')
GROUP BY tc.constraint_name, tc.constraint_type;

-- ==========================================
-- QUERY 4: Check if 'skus' table exists (used by ensureSkusExist function)
-- ==========================================
-- Code creates/reads from 'skus' table
SELECT EXISTS (
    SELECT 1 
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'skus'
) AS skus_table_exists;

-- ==========================================
-- QUERY 5: Check skus table structure if it exists
-- ==========================================
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'skus' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- ==========================================
-- QUERY 6: Verify foreign keys on job_store_skus
-- ==========================================
SELECT
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name = 'job_store_skus'
  AND tc.table_schema = 'public'
ORDER BY kcu.ordinal_position;


