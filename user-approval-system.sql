-- User Approval System Database Changes
-- This file adds approval status to the users table and creates the approval workflow

-- Add approval status to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS approval_status VARCHAR(20) DEFAULT 'pending';
-- Values: pending, approved, rejected, suspended

-- Add approval tracking fields
ALTER TABLE users ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS approved_by UUID REFERENCES auth.users(id);
ALTER TABLE users ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Add index for approval status queries
CREATE INDEX IF NOT EXISTS idx_users_approval_status ON users(approval_status);

-- Update existing users to approved status (except new shelfers)
UPDATE users 
SET approval_status = 'approved', 
    approved_at = created_at,
    approved_by = (SELECT id FROM users WHERE role = 'admin' LIMIT 1)
WHERE role IN ('admin', 'brand_client') 
AND approval_status = 'pending';

-- Create constraint for approval status values
ALTER TABLE users ADD CONSTRAINT users_approval_status_check 
CHECK (approval_status IN ('pending', 'approved', 'rejected', 'suspended'));

-- Update RLS policies to handle approval status
-- Users can only view their own profile
DROP POLICY IF EXISTS "Users can view own profile" ON users;
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile (but not approval status)
DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

-- Admins can view all users
DROP POLICY IF EXISTS "Admins can view all users" ON users;
CREATE POLICY "Admins can view all users" ON users
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- Add comments
COMMENT ON COLUMN users.approval_status IS 'User approval status: pending, approved, rejected, suspended';
COMMENT ON COLUMN users.approved_at IS 'When the user was approved by admin';
COMMENT ON COLUMN users.approved_by IS 'Admin who approved the user';
COMMENT ON COLUMN users.rejection_reason IS 'Reason for rejection if applicable';
