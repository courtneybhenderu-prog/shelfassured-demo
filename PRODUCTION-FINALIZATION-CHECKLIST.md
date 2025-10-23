-- PRODUCTION FINALIZATION CHECKLIST
-- Run these scripts in order to complete production hardening

-- ✅ Step 1: PostgREST Schema Reload
-- File: step1-postgrest-reload.sql
-- Purpose: Prevents any stale "relation" ghosts

-- ✅ Step 2: Execution Foreign Keys  
-- File: step2-execution-fks.sql
-- Purpose: Ensure submissions point to the triple and photos point to submissions

-- ✅ Step 3: RLS Posture Setup
-- File: step3-rls-posture.sql  
-- Purpose: Keep RLS ON for jobs, OFF for job_store_skus during stabilization

-- ✅ Step 4: Legacy Trigger Cleanup
-- File: step4-trigger-cleanup.sql
-- Purpose: Confirm no legacy triggers remain that could cause issues

-- ✅ Step 5: Security Advisor Pass
-- File: step5-security-advisor.sql
-- Purpose: Check for common security issues

-- ✅ Step 6: Health Checks
-- File: step6-health-checks.sql
-- Purpose: Quick verification that everything is working correctly

-- 🎯 PRODUCTION READY CHECKLIST:
-- [ ] PostgREST schema reloaded
-- [ ] Execution FKs added (if submissions/photos exist)
-- [ ] RLS posture configured (jobs protected, junction relaxed)
-- [ ] Legacy triggers cleaned up
-- [ ] Security Advisor passed
-- [ ] Health checks passed (0 duplicates, valid FKs)

-- 📝 OPS NOTES:
-- 1. If you add soft delete (deleted_at) to job_store_skus, swap the unique constraint for a partial unique index on active rows
-- 2. If any code uses the REST endpoint (not the JS client), remember the header: Prefer: resolution=merge-duplicates,ignore-duplicates
-- 3. When ready for production security, uncomment the RLS policy in step3-rls-posture.sql

-- 🚀 CALL IT PRODUCTION:
-- You're functionally there. Run the schema reload, confirm the execution FKs (if applicable), and keep jobs protected. 
-- When you're ready, flip on the parent-deferred RLS policy for job_store_skus.
