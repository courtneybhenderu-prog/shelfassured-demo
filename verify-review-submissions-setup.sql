-- ========================================
-- Verify Review Submissions MVP Setup
-- Run this to confirm everything is set up correctly
-- ========================================

-- Check notifications table
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notifications')
        THEN '✅ Notifications table exists'
        ELSE '❌ Notifications table MISSING'
    END as status;

-- Check review_outcome column
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'job_submissions' 
            AND column_name = 'review_outcome'
        )
        THEN '✅ review_outcome column exists'
        ELSE '❌ review_outcome column MISSING'
    END as status;

-- Check approve_submission RPC
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_proc 
            WHERE proname = 'approve_submission'
        )
        THEN '✅ approve_submission RPC exists'
        ELSE '❌ approve_submission RPC MISSING'
    END as status;

-- Check reject_submission RPC
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_proc 
            WHERE proname = 'reject_submission'
        )
        THEN '✅ reject_submission RPC exists'
        ELSE '❌ reject_submission RPC MISSING'
    END as status;

-- Summary: Show all at once
SELECT 
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'notifications') as notifications_table,
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'job_submissions' AND column_name = 'review_outcome') as review_outcome_column,
    (SELECT COUNT(*) FROM pg_proc WHERE proname = 'approve_submission') as approve_function,
    (SELECT COUNT(*) FROM pg_proc WHERE proname = 'reject_submission') as reject_function;


