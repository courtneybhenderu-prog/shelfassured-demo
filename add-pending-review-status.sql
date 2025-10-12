-- Add 'pending_review' status to jobs table constraint
-- This allows jobs to transition to 'pending_review' after submission

-- First, drop the existing constraint
ALTER TABLE jobs DROP CONSTRAINT IF EXISTS jobs_status_check;

-- Add the new constraint with 'pending_review' included
ALTER TABLE jobs ADD CONSTRAINT jobs_status_check 
CHECK (status IN ('pending', 'assigned', 'in_progress', 'pending_review', 'completed', 'cancelled', 'rejected'));

-- Update any existing 'in_progress' jobs that should be 'pending_review'
-- (This is optional - only run if you want to migrate existing data)
-- UPDATE jobs SET status = 'pending_review' WHERE status = 'in_progress' AND id IN (
--   SELECT DISTINCT job_id FROM job_submissions WHERE is_validated = false
-- );

-- Success message
SELECT 'Jobs table status constraint updated successfully. Added pending_review status.' as status;
