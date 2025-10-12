-- PRE-IMPLEMENTATION SCHEMA AUDIT & PREPARATION
-- Professional software engineering approach to schema improvements

-- ==============================================
-- STEP 1: SCHEMA AUDIT & CONFLICT RESOLUTION
-- ==============================================

-- 1.1 Check current schema state
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name IN ('users', 'jobs', 'job_submissions', 'skus')
ORDER BY table_name, ordinal_position;

-- 1.2 Check existing constraints and indexes
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

-- 1.3 Check existing indexes
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public' 
    AND tablename IN ('users', 'jobs', 'job_submissions')
ORDER BY tablename, indexname;

-- ==============================================
-- STEP 2: DATA BACKUP & MIGRATION STRATEGY
-- ==============================================

-- 2.1 Create backup tables before migration
CREATE TABLE IF NOT EXISTS users_backup AS SELECT * FROM users;
CREATE TABLE IF NOT EXISTS jobs_backup AS SELECT * FROM jobs;
CREATE TABLE IF NOT EXISTS job_submissions_backup AS SELECT * FROM job_submissions;

-- 2.2 Create migration log table
CREATE TABLE IF NOT EXISTS schema_migrations (
    id SERIAL PRIMARY KEY,
    migration_name VARCHAR(255) NOT NULL,
    executed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'pending',
    error_message TEXT,
    rollback_sql TEXT
);

-- ==============================================
-- STEP 3: SAFE MIGRATION IMPLEMENTATION
-- ==============================================

-- 3.1 Fix critical schema issues first
-- Fix missing primary key in skus table
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'skus' AND column_name = 'id'
    ) THEN
        ALTER TABLE skus ADD COLUMN id UUID PRIMARY KEY DEFAULT uuid_generate_v4();
    END IF;
END $$;

-- 3.2 Standardize role naming (contractor -> shelfer)
UPDATE users 
SET role = 'shelfer' 
WHERE role = 'contractor';

-- Update constraint to match new naming
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check 
    CHECK (role IN ('admin', 'shelfer', 'brand_client'));

-- 3.3 Add new columns safely with proper defaults
-- Add submission_time to job_submissions
ALTER TABLE job_submissions 
ADD COLUMN IF NOT EXISTS submission_time TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Add assigned_user_id to jobs (more explicit than contractor_id)
ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS assigned_user_id UUID REFERENCES users(id);

-- Add submission_user_id to job_submissions (more explicit than contractor_id)
ALTER TABLE job_submissions 
ADD COLUMN IF NOT EXISTS submission_user_id UUID REFERENCES users(id);

-- Add user_type column (more explicit than role)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS user_type VARCHAR(20) DEFAULT 'shelfer' 
CHECK (user_type IN ('admin', 'shelfer', 'brand_client'));

-- ==============================================
-- STEP 4: DATA MIGRATION
-- ==============================================

-- 4.1 Migrate existing data to new columns
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
-- STEP 5: PERFORMANCE OPTIMIZATION
-- ==============================================

-- 5.1 Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_jobs_assigned_user_id ON jobs(assigned_user_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status_priority ON jobs(status, priority);
CREATE INDEX IF NOT EXISTS idx_job_submissions_submission_user_id ON job_submissions(submission_user_id);
CREATE INDEX IF NOT EXISTS idx_job_submissions_submission_time ON job_submissions(submission_time);
CREATE INDEX IF NOT EXISTS idx_job_submissions_job_status ON job_submissions(job_id, status);
CREATE INDEX IF NOT EXISTS idx_users_user_type ON users(user_type);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);

-- 5.2 Create composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_jobs_client_status ON jobs(client_id, status);
CREATE INDEX IF NOT EXISTS idx_jobs_assigned_status ON jobs(assigned_user_id, status);
CREATE INDEX IF NOT EXISTS idx_job_submissions_job_user_time ON job_submissions(job_id, submission_user_id, submission_time);

-- ==============================================
-- STEP 6: DATA VALIDATION & INTEGRITY CHECKS
-- ==============================================

-- 6.1 Validate data integrity after migration
DO $$
DECLARE
    orphaned_jobs INTEGER;
    orphaned_submissions INTEGER;
    invalid_users INTEGER;
BEGIN
    -- Check for orphaned job assignments
    SELECT COUNT(*) INTO orphaned_jobs
    FROM jobs j
    LEFT JOIN users u ON j.assigned_user_id = u.id
    WHERE j.assigned_user_id IS NOT NULL AND u.id IS NULL;
    
    -- Check for orphaned submissions
    SELECT COUNT(*) INTO orphaned_submissions
    FROM job_submissions js
    LEFT JOIN users u ON js.submission_user_id = u.id
    WHERE js.submission_user_id IS NOT NULL AND u.id IS NULL;
    
    -- Check for invalid user types
    SELECT COUNT(*) INTO invalid_users
    FROM users
    WHERE user_type NOT IN ('admin', 'shelfer', 'brand_client');
    
    -- Report issues
    IF orphaned_jobs > 0 THEN
        RAISE WARNING 'Found % orphaned job assignments', orphaned_jobs;
    END IF;
    
    IF orphaned_submissions > 0 THEN
        RAISE WARNING 'Found % orphaned submissions', orphaned_submissions;
    END IF;
    
    IF invalid_users > 0 THEN
        RAISE WARNING 'Found % users with invalid user_type', invalid_users;
    END IF;
    
    RAISE NOTICE 'Data validation completed successfully';
END $$;

-- ==============================================
-- STEP 7: UPDATE RLS POLICIES
-- ==============================================

-- 7.1 Update RLS policies for new columns
-- Note: This should be done carefully to avoid breaking existing access

-- Update jobs table policies to include assigned_user_id
DROP POLICY IF EXISTS "jobs_select_policy" ON jobs;
CREATE POLICY "jobs_select_policy" ON jobs
    FOR SELECT
    USING (
        auth.uid() = client_id OR 
        auth.uid() = assigned_user_id OR 
        auth.uid() = contractor_id OR
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND user_type = 'admin')
    );

-- Update job_submissions table policies to include submission_user_id
DROP POLICY IF EXISTS "job_submissions_select_policy" ON job_submissions;
CREATE POLICY "job_submissions_select_policy" ON job_submissions
    FOR SELECT
    USING (
        auth.uid() = submission_user_id OR 
        auth.uid() = contractor_id OR
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND user_type = 'admin')
    );

-- ==============================================
-- STEP 8: CREATE HELPFUL VIEWS
-- ==============================================

-- 8.1 Create views for better reporting
CREATE OR REPLACE VIEW job_assignments AS
SELECT 
    j.id as job_id,
    j.title,
    j.status,
    j.priority,
    j.created_at as job_created_at,
    j.due_date,
    u_assigned.email as assigned_user_email,
    u_assigned.user_type as assigned_user_type,
    u_client.email as client_email,
    u_client.user_type as client_type,
    COUNT(js.id) as submission_count,
    MAX(js.submission_time) as last_submission_time,
    j.total_payout
FROM jobs j
LEFT JOIN users u_assigned ON j.assigned_user_id = u_assigned.id
LEFT JOIN users u_client ON j.client_id = u_client.id
LEFT JOIN job_submissions js ON j.id = js.job_id
GROUP BY j.id, j.title, j.status, j.priority, j.created_at, j.due_date,
         u_assigned.email, u_assigned.user_type,
         u_client.email, u_client.user_type, j.total_payout;

-- 8.2 Create submission tracking view
CREATE OR REPLACE VIEW submission_tracking AS
SELECT 
    js.id as submission_id,
    js.job_id,
    j.title as job_title,
    js.submission_time,
    js.created_at as submission_created_at,
    u_submitter.email as submitter_email,
    u_submitter.user_type as submitter_type,
    js.status as submission_status,
    js.is_validated,
    u_validator.email as validator_email,
    js.validation_notes,
    js.submission_type
FROM job_submissions js
JOIN jobs j ON js.job_id = j.id
LEFT JOIN users u_submitter ON js.submission_user_id = u_submitter.id
LEFT JOIN users u_validator ON js.validated_by = u_validator.id;

-- ==============================================
-- STEP 9: MIGRATION LOGGING
-- ==============================================

-- 9.1 Log successful migration
INSERT INTO schema_migrations (migration_name, status, executed_at)
VALUES ('reetika_schema_improvements', 'completed', NOW());

-- ==============================================
-- STEP 10: CLEANUP & OPTIMIZATION
-- ==============================================

-- 10.1 Add table comments for documentation
COMMENT ON COLUMN jobs.assigned_user_id IS 'User assigned to complete this job (usually a shelfer)';
COMMENT ON COLUMN job_submissions.submission_user_id IS 'User who submitted this data (usually a shelfer)';
COMMENT ON COLUMN job_submissions.submission_time IS 'Timestamp when the submission was made';
COMMENT ON COLUMN users.user_type IS 'Type of user: admin, shelfer, or brand_client';

-- 10.2 Update table statistics for better query planning
ANALYZE users;
ANALYZE jobs;
ANALYZE job_submissions;

-- ==============================================
-- ROLLBACK PLAN (if needed)
-- ==============================================

-- If rollback is needed, run these commands:
/*
-- Restore from backup tables
TRUNCATE users, jobs, job_submissions;
INSERT INTO users SELECT * FROM users_backup;
INSERT INTO jobs SELECT * FROM jobs_backup;
INSERT INTO job_submissions SELECT * FROM job_submissions_backup;

-- Drop new columns
ALTER TABLE jobs DROP COLUMN IF EXISTS assigned_user_id;
ALTER TABLE job_submissions DROP COLUMN IF EXISTS submission_user_id;
ALTER TABLE job_submissions DROP COLUMN IF EXISTS submission_time;
ALTER TABLE users DROP COLUMN IF EXISTS user_type;

-- Drop new indexes
DROP INDEX IF EXISTS idx_jobs_assigned_user_id;
DROP INDEX IF EXISTS idx_job_submissions_submission_user_id;
DROP INDEX IF EXISTS idx_job_submissions_submission_time;
DROP INDEX IF EXISTS idx_users_user_type;

-- Log rollback
INSERT INTO schema_migrations (migration_name, status, executed_at)
VALUES ('reetika_schema_improvements', 'rolled_back', NOW());
*/
