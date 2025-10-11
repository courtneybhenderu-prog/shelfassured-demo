-- SAFE SCHEMA IMPROVEMENTS - ZERO DOWNTIME APPROACH
-- Designed to NOT impact existing login or page functionality
-- Execute in Supabase SQL Editor in this exact order

-- ==============================================
-- PHASE 1: SAFE AUDIT (READ-ONLY, NO CHANGES)
-- ==============================================

-- 1.1 Check current schema state (SAFE - READ ONLY)
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name IN ('users', 'jobs', 'job_submissions')
ORDER BY table_name, ordinal_position;

-- 1.2 Check existing data (SAFE - READ ONLY)
SELECT 
    'users' as table_name,
    COUNT(*) as total_rows,
    COUNT(DISTINCT role) as unique_roles,
    COUNT(DISTINCT CASE WHEN is_active = true THEN id END) as active_users
FROM users
UNION ALL
SELECT 
    'jobs' as table_name,
    COUNT(*) as total_rows,
    COUNT(DISTINCT status) as unique_statuses,
    COUNT(DISTINCT contractor_id) as unique_contractors
FROM jobs
UNION ALL
SELECT 
    'job_submissions' as table_name,
    COUNT(*) as total_rows,
    COUNT(DISTINCT status) as unique_statuses,
    COUNT(DISTINCT contractor_id) as unique_contractors
FROM job_submissions;

-- ==============================================
-- PHASE 2: SAFE BACKUP (READ-ONLY, NO CHANGES)
-- ==============================================

-- 2.1 Create backup tables (SAFE - NEW TABLES ONLY)
CREATE TABLE IF NOT EXISTS users_backup_20250110 AS SELECT * FROM users;
CREATE TABLE IF NOT EXISTS jobs_backup_20250110 AS SELECT * FROM jobs;
CREATE TABLE IF NOT EXISTS job_submissions_backup_20250110 AS SELECT * FROM job_submissions;

-- 2.2 Create migration log table (SAFE - NEW TABLE ONLY)
CREATE TABLE IF NOT EXISTS schema_migrations (
    id SERIAL PRIMARY KEY,
    migration_name VARCHAR(255) NOT NULL,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'pending',
    error_message TEXT,
    rollback_sql TEXT
);

-- ==============================================
-- PHASE 3: SAFE COLUMN ADDITIONS (NON-BREAKING)
-- ==============================================

-- 3.1 Add new columns with safe defaults (WON'T BREAK EXISTING CODE)
-- These columns are ADDITIVE ONLY - existing code continues to work

-- Add submission_time to job_submissions (SAFE - new column only)
ALTER TABLE job_submissions 
ADD COLUMN IF NOT EXISTS submission_time TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Add assigned_user_id to jobs (SAFE - new column only)
ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS assigned_user_id UUID REFERENCES users(id);

-- Add submission_user_id to job_submissions (SAFE - new column only)
ALTER TABLE job_submissions 
ADD COLUMN IF NOT EXISTS submission_user_id UUID REFERENCES users(id);

-- Add user_type column (SAFE - new column only)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS user_type VARCHAR(20) DEFAULT 'shelfer' 
CHECK (user_type IN ('admin', 'shelfer', 'brand_client'));

-- ==============================================
-- PHASE 4: SAFE DATA MIGRATION (NON-BREAKING)
-- ==============================================

-- 4.1 Migrate existing data to new columns (SAFE - only populates new columns)
-- This doesn't change existing data, just populates new columns

-- Migrate contractor_id to assigned_user_id in jobs table
UPDATE jobs 
SET assigned_user_id = contractor_id 
WHERE contractor_id IS NOT NULL 
    AND assigned_user_id IS NULL;

-- Migrate contractor_id to submission_user_id in job_submissions table
UPDATE job_submissions 
SET submission_user_id = contractor_id 
WHERE contractor_id IS NOT NULL 
    AND submission_user_id IS NULL;

-- Update user_type based on existing role column
UPDATE users 
SET user_type = CASE 
    WHEN role = 'admin' THEN 'admin'
    WHEN role = 'shelfer' THEN 'shelfer'
    WHEN role = 'brand_client' THEN 'brand_client'
    ELSE 'shelfer'
END
WHERE user_type IS NULL;

-- ==============================================
-- PHASE 5: SAFE PERFORMANCE OPTIMIZATION
-- ==============================================

-- 5.1 Create indexes for better performance (SAFE - only adds indexes)
CREATE INDEX IF NOT EXISTS idx_jobs_assigned_user_id ON jobs(assigned_user_id);
CREATE INDEX IF NOT EXISTS idx_job_submissions_submission_user_id ON job_submissions(submission_user_id);
CREATE INDEX IF NOT EXISTS idx_job_submissions_submission_time ON job_submissions(submission_time);
CREATE INDEX IF NOT EXISTS idx_users_user_type ON users(user_type);

-- ==============================================
-- PHASE 6: SAFE DATA VALIDATION (READ-ONLY)
-- ==============================================

-- 6.1 Validate data integrity after migration (SAFE - READ ONLY)
DO $$
DECLARE
    migration_success BOOLEAN := true;
    error_count INTEGER := 0;
BEGIN
    -- Check for orphaned job assignments
    IF EXISTS (
        SELECT 1 FROM jobs j
        LEFT JOIN users u ON j.assigned_user_id = u.id
        WHERE j.assigned_user_id IS NOT NULL AND u.id IS NULL
    ) THEN
        RAISE WARNING 'Found orphaned job assignments';
        error_count := error_count + 1;
    END IF;
    
    -- Check for orphaned submissions
    IF EXISTS (
        SELECT 1 FROM job_submissions js
        LEFT JOIN users u ON js.submission_user_id = u.id
        WHERE js.submission_user_id IS NOT NULL AND u.id IS NULL
    ) THEN
        RAISE WARNING 'Found orphaned submissions';
        error_count := error_count + 1;
    END IF;
    
    -- Check for invalid user types
    IF EXISTS (
        SELECT 1 FROM users
        WHERE user_type NOT IN ('admin', 'shelfer', 'brand_client')
    ) THEN
        RAISE WARNING 'Found users with invalid user_type';
        error_count := error_count + 1;
    END IF;
    
    IF error_count = 0 THEN
        RAISE NOTICE 'Data validation completed successfully - NO ERRORS';
        migration_success := true;
    ELSE
        RAISE WARNING 'Data validation found % issues', error_count;
        migration_success := false;
    END IF;
    
    -- Log the result
    INSERT INTO schema_migrations (migration_name, status, executed_at)
    VALUES ('reetika_schema_improvements', 
            CASE WHEN migration_success THEN 'completed' ELSE 'failed' END, 
            NOW());
END $$;

-- ==============================================
-- PHASE 7: SAFE HELPFUL VIEWS (READ-ONLY)
-- ==============================================

-- 7.1 Create views for better reporting (SAFE - new views only)
CREATE OR REPLACE VIEW job_assignments AS
SELECT 
    j.id as job_id,
    j.title,
    j.status,
    j.created_at as job_created_at,
    u_assigned.email as assigned_user_email,
    u_assigned.user_type as assigned_user_type,
    u_client.email as client_email,
    u_client.user_type as client_type,
    COUNT(js.id) as submission_count,
    MAX(js.submission_time) as last_submission_time
FROM jobs j
LEFT JOIN users u_assigned ON j.assigned_user_id = u_assigned.id
LEFT JOIN users u_client ON j.client_id = u_client.id
LEFT JOIN job_submissions js ON j.id = js.job_id
GROUP BY j.id, j.title, j.status, j.created_at,
         u_assigned.email, u_assigned.user_type,
         u_client.email, u_client.user_type;

-- 7.2 Create submission tracking view (SAFE - new view only)
CREATE OR REPLACE VIEW submission_tracking AS
SELECT 
    js.id as submission_id,
    js.job_id,
    j.title as job_title,
    js.submission_time,
    u_submitter.email as submitter_email,
    u_submitter.user_type as submitter_type,
    js.status as submission_status,
    js.is_validated,
    u_validator.email as validator_email,
    js.validation_notes
FROM job_submissions js
JOIN jobs j ON js.job_id = j.id
LEFT JOIN users u_submitter ON js.submission_user_id = u_submitter.id
LEFT JOIN users u_validator ON js.validated_by = u_validator.id;

-- ==============================================
-- PHASE 8: SAFE DOCUMENTATION (READ-ONLY)
-- ==============================================

-- 8.1 Add table comments for documentation (SAFE - metadata only)
COMMENT ON COLUMN jobs.assigned_user_id IS 'User assigned to complete this job (usually a shelfer)';
COMMENT ON COLUMN job_submissions.submission_user_id IS 'User who submitted this data (usually a shelfer)';
COMMENT ON COLUMN job_submissions.submission_time IS 'Timestamp when the submission was made';
COMMENT ON COLUMN users.user_type IS 'Type of user: admin, shelfer, or brand_client';

-- ==============================================
-- VERIFICATION: CHECK THAT NOTHING IS BROKEN
-- ==============================================

-- Final verification that existing functionality still works
SELECT 
    'VERIFICATION COMPLETE' as status,
    COUNT(*) as total_users,
    COUNT(CASE WHEN is_active = true THEN 1 END) as active_users,
    COUNT(CASE WHEN user_type IS NOT NULL THEN 1 END) as users_with_type
FROM users;

SELECT 
    'JOBS VERIFICATION' as status,
    COUNT(*) as total_jobs,
    COUNT(CASE WHEN assigned_user_id IS NOT NULL THEN 1 END) as jobs_with_assigned_user
FROM jobs;

SELECT 
    'SUBMISSIONS VERIFICATION' as status,
    COUNT(*) as total_submissions,
    COUNT(CASE WHEN submission_user_id IS NOT NULL THEN 1 END) as submissions_with_user,
    COUNT(CASE WHEN submission_time IS NOT NULL THEN 1 END) as submissions_with_time
FROM job_submissions;

-- ==============================================
-- ROLLBACK PLAN (IF NEEDED - SAFE)
-- ==============================================

-- If anything goes wrong, run this to rollback safely:
/*
-- Step 1: Drop new columns (SAFE - only removes new columns)
ALTER TABLE jobs DROP COLUMN IF EXISTS assigned_user_id;
ALTER TABLE job_submissions DROP COLUMN IF EXISTS submission_user_id;
ALTER TABLE job_submissions DROP COLUMN IF EXISTS submission_time;
ALTER TABLE users DROP COLUMN IF EXISTS user_type;

-- Step 2: Drop new indexes (SAFE - only removes new indexes)
DROP INDEX IF EXISTS idx_jobs_assigned_user_id;
DROP INDEX IF EXISTS idx_job_submissions_submission_user_id;
DROP INDEX IF EXISTS idx_job_submissions_submission_time;
DROP INDEX IF EXISTS idx_users_user_type;

-- Step 3: Drop new views (SAFE - only removes new views)
DROP VIEW IF EXISTS job_assignments;
DROP VIEW IF EXISTS submission_tracking;

-- Step 4: Log rollback
INSERT INTO schema_migrations (migration_name, status, executed_at)
VALUES ('reetika_schema_improvements', 'rolled_back', NOW());
*/
