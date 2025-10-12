-- FIXED PROFESSIONAL SCHEMA MIGRATION
-- Addresses critical issues identified in review

-- ==============================================
-- STEP 1: SAFE SCHEMA AUDIT (IMPROVED)
-- ==============================================

-- 1.1 Check current schema state (SAFE - handles missing tables)
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

-- 1.2 Check if skus table exists before auditing
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'skus' AND table_schema = 'public')
        THEN 'skus table exists'
        ELSE 'skus table does not exist'
    END as skus_status;

-- 1.3 Check existing constraints and indexes (SAFE)
SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'public' 
    AND tc.table_name IN ('users', 'jobs', 'job_submissions')
ORDER BY tc.table_name, tc.constraint_type;

-- ==============================================
-- STEP 2: SAFE DATA BACKUP
-- ==============================================

-- 2.1 Create backup tables (SAFE - only if tables exist)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
        CREATE TABLE IF NOT EXISTS users_backup_20250110 AS SELECT * FROM users;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'jobs' AND table_schema = 'public') THEN
        CREATE TABLE IF NOT EXISTS jobs_backup_20250110 AS SELECT * FROM jobs;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'job_submissions' AND table_schema = 'public') THEN
        CREATE TABLE IF NOT EXISTS job_submissions_backup_20250110 AS SELECT * FROM job_submissions;
    END IF;
END $$;

-- 2.2 Create migration log table (SAFE)
CREATE TABLE IF NOT EXISTS schema_migrations (
    id SERIAL PRIMARY KEY,
    migration_name VARCHAR(255) NOT NULL,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'pending',
    error_message TEXT,
    rollback_sql TEXT
);

-- ==============================================
-- STEP 3: SAFE COLUMN ADDITIONS (NON-BREAKING)
-- ==============================================

-- 3.1 Add new columns safely (WON'T BREAK EXISTING CODE)
ALTER TABLE job_submissions 
ADD COLUMN IF NOT EXISTS submission_time TIMESTAMP WITH TIME ZONE DEFAULT NOW();

ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS assigned_user_id UUID REFERENCES users(id);

ALTER TABLE job_submissions 
ADD COLUMN IF NOT EXISTS submission_user_id UUID REFERENCES users(id);

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS user_type VARCHAR(20) DEFAULT 'shelfer' 
CHECK (user_type IN ('admin', 'shelfer', 'brand_client'));

-- ==============================================
-- STEP 4: SAFE DATA MIGRATION
-- ==============================================

-- 4.1 Migrate existing data safely
UPDATE jobs 
SET assigned_user_id = contractor_id 
WHERE contractor_id IS NOT NULL 
    AND assigned_user_id IS NULL;

UPDATE job_submissions 
SET submission_user_id = contractor_id 
WHERE contractor_id IS NOT NULL 
    AND submission_user_id IS NULL;

-- 4.2 Update user_type based on existing role (SAFE)
UPDATE users 
SET user_type = CASE 
    WHEN role = 'admin' THEN 'admin'
    WHEN role = 'shelfer' THEN 'shelfer'
    WHEN role = 'brand_client' THEN 'brand_client'
    WHEN role = 'contractor' THEN 'shelfer'  -- Handle existing contractor role
    ELSE 'shelfer'
END
WHERE user_type IS NULL;

-- ==============================================
-- STEP 5: SAFE PERFORMANCE OPTIMIZATION
-- ==============================================

-- 5.1 Create indexes safely
CREATE INDEX IF NOT EXISTS idx_jobs_assigned_user_id ON jobs(assigned_user_id);
CREATE INDEX IF NOT EXISTS idx_job_submissions_submission_user_id ON job_submissions(submission_user_id);
CREATE INDEX IF NOT EXISTS idx_job_submissions_submission_time ON job_submissions(submission_time);
CREATE INDEX IF NOT EXISTS idx_users_user_type ON users(user_type);

-- ==============================================
-- STEP 6: SAFE DATA VALIDATION
-- ==============================================

-- 6.1 Validate data integrity (SAFE)
DO $$
DECLARE
    validation_passed BOOLEAN := true;
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
        validation_passed := false;
    END IF;
    
    -- Check for orphaned submissions
    IF EXISTS (
        SELECT 1 FROM job_submissions js
        LEFT JOIN users u ON js.submission_user_id = u.id
        WHERE js.submission_user_id IS NOT NULL AND u.id IS NULL
    ) THEN
        RAISE WARNING 'Found orphaned submissions';
        error_count := error_count + 1;
        validation_passed := false;
    END IF;
    
    -- Check for invalid user types
    IF EXISTS (
        SELECT 1 FROM users
        WHERE user_type NOT IN ('admin', 'shelfer', 'brand_client')
    ) THEN
        RAISE WARNING 'Found users with invalid user_type';
        error_count := error_count + 1;
        validation_passed := false;
    END IF;
    
    -- Log the result
    INSERT INTO schema_migrations (migration_name, status, executed_at)
    VALUES ('reetika_schema_improvements', 
            CASE WHEN validation_passed THEN 'completed' ELSE 'failed' END, 
            NOW());
    
    IF validation_passed THEN
        RAISE NOTICE 'Data validation completed successfully - NO ERRORS';
    ELSE
        RAISE WARNING 'Data validation found % issues', error_count;
    END IF;
END $$;

-- ==============================================
-- STEP 7: SAFE HELPFUL VIEWS (CONDITIONAL)
-- ==============================================

-- 7.1 Create views only if all required columns exist
DO $$
BEGIN
    -- Check if all required columns exist before creating views
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' AND column_name = 'assigned_user_id'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'job_submissions' AND column_name = 'submission_user_id'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'user_type'
    ) THEN
        
        -- Create job assignments view
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
        
        -- Create submission tracking view
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
        
        RAISE NOTICE 'Views created successfully';
    ELSE
        RAISE WARNING 'Required columns not found - skipping view creation';
    END IF;
END $$;

-- ==============================================
-- STEP 8: SAFE DOCUMENTATION
-- ==============================================

-- 8.1 Add table comments safely
COMMENT ON COLUMN jobs.assigned_user_id IS 'User assigned to complete this job (usually a shelfer)';
COMMENT ON COLUMN job_submissions.submission_user_id IS 'User who submitted this data (usually a shelfer)';
COMMENT ON COLUMN job_submissions.submission_time IS 'Timestamp when the submission was made';
COMMENT ON COLUMN users.user_type IS 'Type of user: admin, shelfer, or brand_client';

-- ==============================================
-- FINAL VERIFICATION
-- ==============================================

-- Verify that existing functionality still works
SELECT 
    'MIGRATION COMPLETE' as status,
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
-- ROLLBACK PLAN (SAFE)
-- ==============================================

-- If rollback is needed, run this:
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
