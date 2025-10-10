-- Admin Dashboard Database Tables
-- This file creates the necessary tables for the admin dashboard functionality

-- Create job_submissions table for photo submissions from shelfers
CREATE TABLE IF NOT EXISTS job_submissions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    shelfer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    photos JSONB NOT NULL DEFAULT '[]', -- Array of photo URLs
    notes TEXT, -- Shelfer's notes about the submission
    status VARCHAR(20) NOT NULL DEFAULT 'pending_review',
    admin_notes TEXT, -- Admin's review notes
    reviewed_at TIMESTAMP WITH TIME ZONE,
    reviewed_by UUID REFERENCES auth.users(id),
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

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
CREATE INDEX IF NOT EXISTS idx_job_submissions_job_id ON job_submissions(job_id);
CREATE INDEX IF NOT EXISTS idx_job_submissions_shelfer_id ON job_submissions(shelfer_id);
CREATE INDEX IF NOT EXISTS idx_job_submissions_status ON job_submissions(status);
CREATE INDEX IF NOT EXISTS idx_job_submissions_submitted_at ON job_submissions(submitted_at);

CREATE INDEX IF NOT EXISTS idx_help_requests_user_id ON help_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_help_requests_status ON help_requests(status);
CREATE INDEX IF NOT EXISTS idx_help_requests_priority ON help_requests(priority);
CREATE INDEX IF NOT EXISTS idx_help_requests_is_read ON help_requests(is_read);
CREATE INDEX IF NOT EXISTS idx_help_requests_created_at ON help_requests(created_at);

-- Enable Row Level Security
ALTER TABLE job_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE help_requests ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for job_submissions
CREATE POLICY "Users can view own submissions" ON job_submissions
    FOR SELECT USING (auth.uid() = shelfer_id);

CREATE POLICY "Users can insert own submissions" ON job_submissions
    FOR INSERT WITH CHECK (auth.uid() = shelfer_id);

CREATE POLICY "Users can update own submissions" ON job_submissions
    FOR UPDATE USING (auth.uid() = shelfer_id);

-- Admins can view all submissions
CREATE POLICY "Admins can view all submissions" ON job_submissions
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- Create RLS policies for help_requests
CREATE POLICY "Users can view own help requests" ON help_requests
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own help requests" ON help_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own help requests" ON help_requests
    FOR UPDATE USING (auth.uid() = user_id);

-- Admins can view all help requests
CREATE POLICY "Admins can view all help requests" ON help_requests
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- Create trigger functions for updated_at
CREATE OR REPLACE FUNCTION update_job_submissions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_help_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER update_job_submissions_updated_at_trigger
    BEFORE UPDATE ON job_submissions
    FOR EACH ROW
    EXECUTE FUNCTION update_job_submissions_updated_at();

CREATE TRIGGER update_help_requests_updated_at_trigger
    BEFORE UPDATE ON help_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_help_requests_updated_at();

-- Add comments
COMMENT ON TABLE job_submissions IS 'Photo submissions from shelfers for job completion';
COMMENT ON TABLE help_requests IS 'User support messages and help requests';
COMMENT ON COLUMN job_submissions.photos IS 'Array of photo URLs submitted by shelfer';
COMMENT ON COLUMN job_submissions.status IS 'Submission status: pending_review, approved, rejected, revision_requested';
COMMENT ON COLUMN help_requests.priority IS 'Request priority: low, medium, high, urgent';
COMMENT ON COLUMN help_requests.status IS 'Request status: open, in_progress, resolved, closed';
