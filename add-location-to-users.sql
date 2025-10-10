-- Add location field to users table for location-based job filtering
-- This allows shelfers to see jobs in their area and enables location-based job assignment

-- Add location column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS location VARCHAR(100);

-- Add index for location-based queries
CREATE INDEX IF NOT EXISTS idx_users_location ON users(location);

-- Add location to jobs table for store location filtering
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS store_location VARCHAR(200);

-- Add index for store location queries
CREATE INDEX IF NOT EXISTS idx_jobs_store_location ON jobs(store_location);

-- Add assigned_to and assigned_at fields for job assignment tracking
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES auth.users(id);
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS assigned_at TIMESTAMP WITH TIME ZONE;

-- Add indexes for assignment tracking
CREATE INDEX IF NOT EXISTS idx_jobs_assigned_to ON jobs(assigned_to);
CREATE INDEX IF NOT EXISTS idx_jobs_assigned_at ON jobs(assigned_at);

-- Update RLS policies to allow users to update their own location
CREATE POLICY "Users can update own location" ON users
    FOR UPDATE USING (auth.uid() = id);

-- Add comment explaining the location system
COMMENT ON COLUMN users.location IS 'User location for location-based job filtering (e.g., Houston, Austin, Dallas)';
COMMENT ON COLUMN jobs.store_location IS 'Store location for this job (e.g., Houston, TX)';
COMMENT ON COLUMN jobs.assigned_to IS 'Shelfer assigned to this job';
COMMENT ON COLUMN jobs.assigned_at IS 'When the job was assigned to a shelfer';
