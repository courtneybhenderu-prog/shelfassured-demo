-- ========================================
-- Submission Review RPC Testing Script
-- Run this AFTER verifying database state
-- ========================================
-- Purpose: Test approve_submission and reject_submission RPCs
-- Date: 2025-01-13

-- ========================================
-- SETUP: Find a test submission
-- ========================================
-- Find a pending_review submission to test with
SELECT 
    'TEST SUBMISSION SELECTION' as step,
    js.id as submission_id,
    js.job_id,
    js.contractor_id,
    j.title as job_title,
    j.status as job_status,
    j.payout_per_store,
    js.is_validated,
    js.review_outcome
FROM job_submissions js
JOIN jobs j ON j.id = js.job_id
WHERE j.status = 'pending_review'
  AND js.is_validated IS DISTINCT FROM true
  AND js.review_outcome IS NULL
ORDER BY js.created_at DESC
LIMIT 1;

-- ========================================
-- TEST 1: Approve Submission
-- ========================================
-- Replace {submission_id} and {admin_id} with actual values
-- Uncomment and run when ready to test

/*
DO $$
DECLARE
    v_submission_id uuid := '{submission_id}';  -- Replace with actual submission_id
    v_admin_id uuid := '{admin_id}';            -- Replace with actual admin user_id
    v_payment_count_before int;
    v_payment_count_after int;
    v_notification_count_before int;
    v_notification_count_after int;
    v_job_status_before text;
    v_job_status_after text;
BEGIN
    -- Record state before
    SELECT COUNT(*) INTO v_payment_count_before 
    FROM payments 
    WHERE job_id = (SELECT job_id FROM job_submissions WHERE id = v_submission_id);
    
    SELECT COUNT(*) INTO v_notification_count_before 
    FROM notifications 
    WHERE user_id = (SELECT contractor_id FROM job_submissions WHERE id = v_submission_id);
    
    SELECT status INTO v_job_status_before 
    FROM jobs 
    WHERE id = (SELECT job_id FROM job_submissions WHERE id = v_submission_id);
    
    RAISE NOTICE 'BEFORE: Payments: %, Notifications: %, Job Status: %', 
        v_payment_count_before, v_notification_count_before, v_job_status_before;
    
    -- Call approve RPC
    PERFORM approve_submission(v_submission_id, v_admin_id, 'Test approval - automated test');
    
    -- Record state after
    SELECT COUNT(*) INTO v_payment_count_after 
    FROM payments 
    WHERE job_id = (SELECT job_id FROM job_submissions WHERE id = v_submission_id);
    
    SELECT COUNT(*) INTO v_notification_count_after 
    FROM notifications 
    WHERE user_id = (SELECT contractor_id FROM job_submissions WHERE id = v_submission_id);
    
    SELECT status INTO v_job_status_after 
    FROM jobs 
    WHERE id = (SELECT job_id FROM job_submissions WHERE id = v_submission_id);
    
    RAISE NOTICE 'AFTER: Payments: %, Notifications: %, Job Status: %', 
        v_payment_count_after, v_notification_count_after, v_job_status_after;
    
    -- Verify results
    IF v_payment_count_after > v_payment_count_before THEN
        RAISE NOTICE '✅ Payment created successfully';
    ELSE
        RAISE WARNING '❌ Payment was not created';
    END IF;
    
    IF v_notification_count_after > v_notification_count_before THEN
        RAISE NOTICE '✅ Notification created successfully';
    ELSE
        RAISE WARNING '❌ Notification was not created';
    END IF;
    
    IF v_job_status_after = 'completed' THEN
        RAISE NOTICE '✅ Job status updated to completed';
    ELSE
        RAISE WARNING '❌ Job status not updated correctly (expected: completed, got: %)', v_job_status_after;
    END IF;
    
END $$;
*/

-- ========================================
-- TEST 2: Reject Submission
-- ========================================
-- Note: This requires a job that's back in 'pending' status
-- You may need to manually set a job back to pending first

/*
DO $$
DECLARE
    v_submission_id uuid := '{submission_id}';  -- Replace with actual submission_id
    v_admin_id uuid := '{admin_id}';            -- Replace with actual admin user_id
    v_job_status_before text;
    v_job_status_after text;
    v_notification_count_before int;
    v_notification_count_after int;
BEGIN
    -- Record state before
    SELECT status INTO v_job_status_before 
    FROM jobs 
    WHERE id = (SELECT job_id FROM job_submissions WHERE id = v_submission_id);
    
    SELECT COUNT(*) INTO v_notification_count_before 
    FROM notifications 
    WHERE user_id = (SELECT contractor_id FROM job_submissions WHERE id = v_submission_id);
    
    RAISE NOTICE 'BEFORE: Job Status: %, Notifications: %', 
        v_job_status_before, v_notification_count_before;
    
    -- Call reject RPC
    PERFORM reject_submission(v_submission_id, v_admin_id, 'Test rejection - automated test');
    
    -- Record state after
    SELECT status INTO v_job_status_after 
    FROM jobs 
    WHERE id = (SELECT job_id FROM job_submissions WHERE id = v_submission_id);
    
    SELECT COUNT(*) INTO v_notification_count_after 
    FROM notifications 
    WHERE user_id = (SELECT contractor_id FROM job_submissions WHERE id = v_submission_id);
    
    RAISE NOTICE 'AFTER: Job Status: %, Notifications: %', 
        v_job_status_after, v_notification_count_after;
    
    -- Verify results
    IF v_job_status_after = 'pending' THEN
        RAISE NOTICE '✅ Job status updated to pending (reopened)';
    ELSE
        RAISE WARNING '❌ Job status not updated correctly (expected: pending, got: %)', v_job_status_after;
    END IF;
    
    IF v_notification_count_after > v_notification_count_before THEN
        RAISE NOTICE '✅ Notification created successfully';
    ELSE
        RAISE WARNING '❌ Notification was not created';
    END IF;
    
    -- Verify no payment was created
    IF NOT EXISTS (
        SELECT 1 FROM payments 
        WHERE job_id = (SELECT job_id FROM job_submissions WHERE id = v_submission_id)
    ) THEN
        RAISE NOTICE '✅ No payment created (correct for rejection)';
    ELSE
        RAISE WARNING '⚠️ Payment exists (should not exist for rejected submission)';
    END IF;
    
END $$;
*/

-- ========================================
-- VERIFICATION QUERIES
-- ========================================
-- Run these after testing to verify results

-- Check submission review outcomes
SELECT 
    'REVIEW OUTCOMES SUMMARY' as check_type,
    review_outcome,
    COUNT(*) as count
FROM job_submissions
GROUP BY review_outcome
ORDER BY review_outcome;

-- Check payments created from approvals
SELECT 
    'PAYMENTS FROM APPROVALS' as check_type,
    p.id,
    p.job_id,
    p.contractor_id,
    p.amount,
    p.status,
    j.title as job_title
FROM payments p
JOIN jobs j ON j.id = p.job_id
WHERE j.status = 'completed'
ORDER BY p.created_at DESC
LIMIT 10;

-- Check notifications created
SELECT 
    'NOTIFICATIONS SUMMARY' as check_type,
    type,
    COUNT(*) as count,
    MAX(created_at) as latest
FROM notifications
GROUP BY type
ORDER BY type;

-- Check superseded submissions
SELECT 
    'SUPERSEDED SUBMISSIONS' as check_type,
    COUNT(*) as count
FROM job_submissions
WHERE review_outcome = 'superseded';

