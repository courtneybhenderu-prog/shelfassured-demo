-- ========================================
-- Database State Verification Script
-- Run this in Supabase SQL Editor
-- ========================================
-- Purpose: Verify notifications schema, storage bucket, and RPC functions
-- Date: 2025-01-13

-- ========================================
-- PART 1: Check Notifications Table Schema
-- ========================================
SELECT 
    'NOTIFICATIONS SCHEMA CHECK' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'notifications'
ORDER BY ordinal_position;

-- Check if old schema columns exist
SELECT 
    'OLD SCHEMA DETECTION' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'notifications' AND column_name = 'title'
        ) THEN '⚠️ OLD SCHEMA DETECTED (has title, message, is_read)'
        ELSE '✅ NEW SCHEMA ONLY (has type, payload, read_at)'
    END as schema_status;

-- Check if new schema columns exist
SELECT 
    'NEW SCHEMA DETECTION' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'notifications' AND column_name = 'type'
        ) THEN '✅ NEW SCHEMA PRESENT (has type, payload, read_at)'
        ELSE '❌ NEW SCHEMA MISSING'
    END as schema_status;

-- ========================================
-- PART 2: Check Storage Bucket (via storage.objects)
-- ========================================
-- Note: This checks if bucket exists and has objects
-- RLS policies are checked separately in Supabase Dashboard

SELECT 
    'STORAGE BUCKET CHECK' as check_type,
    bucket_id,
    COUNT(*) as object_count,
    MAX(created_at) as latest_upload
FROM storage.objects
WHERE bucket_id = 'job_submissions'
GROUP BY bucket_id;

-- If no rows returned, bucket doesn't exist or is empty
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM storage.objects WHERE bucket_id = 'job_submissions'
        ) THEN '✅ Bucket exists and has objects'
        ELSE '⚠️ Bucket may not exist or is empty (check Supabase Dashboard > Storage)'
    END as bucket_status;

-- ========================================
-- PART 3: Verify RPC Functions Exist
-- ========================================
SELECT 
    'RPC FUNCTION CHECK' as check_type,
    proname as function_name,
    pg_get_function_arguments(oid) as arguments,
    CASE 
        WHEN proname = 'approve_submission' THEN '✅ approve_submission exists'
        WHEN proname = 'reject_submission' THEN '✅ reject_submission exists'
        ELSE 'Other function'
    END as status
FROM pg_proc
WHERE proname IN ('approve_submission', 'reject_submission')
ORDER BY proname;

-- Check if both functions exist
SELECT 
    'RPC COMPLETENESS' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'approve_submission')
         AND EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'reject_submission')
        THEN '✅ Both RPC functions exist'
        WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'approve_submission')
        THEN '⚠️ Only approve_submission exists'
        WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'reject_submission')
        THEN '⚠️ Only reject_submission exists'
        ELSE '❌ Neither function exists'
    END as rpc_status;

-- ========================================
-- PART 4: Check job_submissions review_outcome column
-- ========================================
SELECT 
    'REVIEW_OUTCOME COLUMN' as check_type,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'job_submissions' 
  AND column_name = 'review_outcome';

-- Check constraint values
SELECT 
    'REVIEW_OUTCOME VALUES' as check_type,
    review_outcome,
    COUNT(*) as count
FROM job_submissions
GROUP BY review_outcome
ORDER BY review_outcome;

-- ========================================
-- PART 5: Check payments table structure
-- ========================================
SELECT 
    'PAYMENTS TABLE CHECK' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'payments'
ORDER BY ordinal_position;

-- ========================================
-- SUMMARY REPORT
-- ========================================
SELECT 
    '=== SUMMARY ===' as summary,
    'Run this query to see all results above' as note,
    'Check Supabase Dashboard > Storage for bucket RLS policies' as storage_note;

