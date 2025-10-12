-- Reetika's Schema Feedback Implementation
-- Based on feedback from Reetika about improving the database structure

-- 1. Add submission_time to job_submissions table
ALTER TABLE job_submissions 
ADD COLUMN IF NOT EXISTS submission_time TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 2. Add assigned_user_id to jobs table (more explicit than contractor_id)
ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS assigned_user_id UUID REFERENCES users(id);

-- 3. Add submission_user_id to job_submissions table (more explicit than contractor_id)
ALTER TABLE job_submissions 
ADD COLUMN IF NOT EXISTS submission_user_id UUID REFERENCES users(id);

-- 4. Add user_type column to users table for better role tracking
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS user_type VARCHAR(20) DEFAULT 'shelfer' 
CHECK (user_type IN ('admin', 'shelfer', 'brand_client'));

-- 5. Add is_active column to users table (though we might already have this)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- 6. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_jobs_assigned_user_id ON jobs(assigned_user_id);
CREATE INDEX IF NOT EXISTS idx_job_submissions_submission_user_id ON job_submissions(submission_user_id);
CREATE INDEX IF NOT EXISTS idx_job_submissions_submission_time ON job_submissions(submission_time);
CREATE INDEX IF NOT EXISTS idx_users_user_type ON users(user_type);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);

-- 7. Update existing data to populate new columns
-- Migrate contractor_id to assigned_user_id in jobs table
UPDATE jobs 
SET assigned_user_id = contractor_id 
WHERE contractor_id IS NOT NULL AND assigned_user_id IS NULL;

-- Migrate contractor_id to submission_user_id in job_submissions table
UPDATE job_submissions 
SET submission_user_id = contractor_id 
WHERE contractor_id IS NOT NULL AND submission_user_id IS NULL;

-- Update user_type based on existing role column
UPDATE users 
SET user_type = CASE 
    WHEN role = 'admin' THEN 'admin'
    WHEN role = 'shelfer' THEN 'shelfer'
    WHEN role = 'brand_client' THEN 'brand_client'
    ELSE 'shelfer'
END
WHERE user_type IS NULL;

-- 8. Add comments for clarity
COMMENT ON COLUMN jobs.assigned_user_id IS 'User assigned to complete this job (usually a shelfer)';
COMMENT ON COLUMN job_submissions.submission_user_id IS 'User who submitted this data (usually a shelfer)';
COMMENT ON COLUMN job_submissions.submission_time IS 'Timestamp when the submission was made';
COMMENT ON COLUMN users.user_type IS 'Type of user: admin, shelfer, or brand_client';
COMMENT ON COLUMN users.is_active IS 'Whether the user account is active and can log in';

-- 9. Create a view for better job tracking
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

-- 10. Create a view for submission tracking
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

-- Summary of improvements:
-- ✅ Added submission_time for better tracking
-- ✅ Added assigned_user_id for clearer job assignment
-- ✅ Added submission_user_id for clearer submission tracking
-- ✅ Added user_type for better role management
-- ✅ Added is_active for user status tracking
-- ✅ Created performance indexes
-- ✅ Created helpful views for reporting
-- ✅ Added descriptive comments
-- ✅ Migrated existing data to new columns
