-- Create audit_requests table for custom audit service requests
CREATE TABLE IF NOT EXISTS audit_requests (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    audit_type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    products JSONB NOT NULL DEFAULT '[]',
    all_stores BOOLEAN NOT NULL DEFAULT false,
    store_requirements TEXT,
    timeline VARCHAR(50) NOT NULL,
    special_requirements TEXT,
    contact_phone VARCHAR(20),
    preferred_contact VARCHAR(20) NOT NULL DEFAULT 'email',
    additional_notes TEXT,
    client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending_review',
    admin_notes TEXT,
    custom_pricing DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_audit_requests_client_id ON audit_requests(client_id);
CREATE INDEX IF NOT EXISTS idx_audit_requests_status ON audit_requests(status);
CREATE INDEX IF NOT EXISTS idx_audit_requests_created_at ON audit_requests(created_at);

-- Enable Row Level Security
ALTER TABLE audit_requests ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view own audit requests" ON audit_requests
    FOR SELECT USING (auth.uid() = client_id);

CREATE POLICY "Users can insert own audit requests" ON audit_requests
    FOR INSERT WITH CHECK (auth.uid() = client_id);

CREATE POLICY "Users can update own audit requests" ON audit_requests
    FOR UPDATE USING (auth.uid() = client_id);

-- Admin can view all audit requests
CREATE POLICY "Admins can view all audit requests" ON audit_requests
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_audit_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_audit_requests_updated_at_trigger
    BEFORE UPDATE ON audit_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_audit_requests_updated_at();
