-- ========================================
-- Setup Help Requests Table
-- Run this in Supabase SQL Editor
-- ========================================

-- Create help_requests table for user support messages
CREATE TABLE IF NOT EXISTS help_requests (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subject VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    priority VARCHAR(10) NOT NULL DEFAULT 'medium',
    status VARCHAR(20) NOT NULL DEFAULT 'open',
    admin_response TEXT,
    resolution_notes TEXT,
    responded_at TIMESTAMP WITH TIME ZONE,
    responded_by UUID REFERENCES auth.users(id),
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID REFERENCES auth.users(id),
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_help_requests_user_id ON help_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_help_requests_status ON help_requests(status);
CREATE INDEX IF NOT EXISTS idx_help_requests_priority ON help_requests(priority);
CREATE INDEX IF NOT EXISTS idx_help_requests_created_at ON help_requests(created_at DESC);

-- Enable Row Level Security
ALTER TABLE help_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Users can view their own help requests
CREATE POLICY "Users can view own help requests" ON help_requests
    FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own help requests
CREATE POLICY "Users can insert own help requests" ON help_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own help requests (before admin responds)
CREATE POLICY "Users can update own help requests" ON help_requests
    FOR UPDATE USING (auth.uid() = user_id);

-- Admins can view all help requests
DROP POLICY IF EXISTS "Admins can view all help requests" ON help_requests;
CREATE POLICY "Admins can view all help requests" ON help_requests
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- Admins can update all help requests (to respond, resolve, etc.)
-- This is covered by the "Admins can view all help requests" policy above (FOR ALL)

-- Create trigger function for updated_at
CREATE OR REPLACE FUNCTION update_help_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS update_help_requests_updated_at_trigger ON help_requests;
CREATE TRIGGER update_help_requests_updated_at_trigger
    BEFORE UPDATE ON help_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_help_requests_updated_at();

-- Add comments
COMMENT ON TABLE help_requests IS 'User support messages and help requests';
COMMENT ON COLUMN help_requests.priority IS 'Request priority: low, medium, high, urgent';
COMMENT ON COLUMN help_requests.status IS 'Request status: open, in_progress, resolved, closed';

-- ========================================
-- Verification
-- ========================================
SELECT 
    '✅ help_requests table created' as status
WHERE EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'help_requests'
);

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'help_requests'
ORDER BY ordinal_position;


