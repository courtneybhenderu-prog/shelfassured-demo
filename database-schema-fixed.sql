-- ShelfAssured Database Schema - FIXED VERSION
-- Designed for Supabase PostgreSQL

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users table (authentication)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255),
    phone VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    role VARCHAR(50) DEFAULT 'contractor' CHECK (role IN ('admin', 'contractor', 'client'))
);

-- Brands table
CREATE TABLE brands (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    logo_url VARCHAR(500),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES users(id)
);

-- Stores table
CREATE TABLE stores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(50) NOT NULL,
    zip_code VARCHAR(20) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    phone VARCHAR(20),
    store_chain VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES users(id)
);

-- SKUs/Products table
CREATE TABLE skus (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    upc VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    brand_id UUID REFERENCES brands(id),
    category VARCHAR(100),
    size VARCHAR(50),
    description TEXT,
    image_url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES users(id)
);

-- Jobs table (main entity) - FIXED VERSION
CREATE TABLE jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    brand_id UUID REFERENCES brands(id),
    client_id UUID REFERENCES users(id),
    contractor_id UUID REFERENCES users(id),
    
    -- Job configuration
    all_stores BOOLEAN DEFAULT false,
    payout_per_store DECIMAL(10,2) NOT NULL DEFAULT 5.00,
    total_payout DECIMAL(10,2) DEFAULT 0.00, -- Will be calculated by trigger
    
    -- Job details
    category VARCHAR(100),
    job_type VARCHAR(50) DEFAULT 'photo_audit' CHECK (job_type IN ('photo_audit', 'inventory_check', 'price_verification', 'shelf_analysis')),
    instructions TEXT,
    requirements JSONB DEFAULT '{}',
    
    -- Status and timing
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'assigned', 'in_progress', 'completed', 'cancelled', 'rejected')),
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    due_date TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

-- Job-Store relationship (many-to-many)
CREATE TABLE job_stores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
    store_id UUID REFERENCES stores(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(job_id, store_id)
);

-- Job-SKU relationship (many-to-many)
CREATE TABLE job_skus (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
    sku_id UUID REFERENCES skus(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(job_id, sku_id)
);

-- Job submissions (photos, data, etc.)
CREATE TABLE job_submissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
    store_id UUID REFERENCES stores(id),
    sku_id UUID REFERENCES skus(id),
    contractor_id UUID REFERENCES users(id),
    
    -- Submission data
    submission_type VARCHAR(50) NOT NULL CHECK (submission_type IN ('photo', 'inventory_data', 'price_data', 'shelf_data')),
    data JSONB NOT NULL DEFAULT '{}',
    files JSONB DEFAULT '[]', -- Array of file URLs/metadata
    
    -- Validation
    is_validated BOOLEAN DEFAULT false,
    validated_by UUID REFERENCES users(id),
    validated_at TIMESTAMP WITH TIME ZONE,
    validation_notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Payments table
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    job_id UUID REFERENCES jobs(id),
    contractor_id UUID REFERENCES users(id),
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
    payment_method VARCHAR(50),
    transaction_id VARCHAR(255),
    processed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notifications table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    data JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_jobs_status ON jobs(status);
CREATE INDEX idx_jobs_contractor ON jobs(contractor_id);
CREATE INDEX idx_jobs_brand ON jobs(brand_id);
CREATE INDEX idx_jobs_due_date ON jobs(due_date);
CREATE INDEX idx_job_stores_job_id ON job_stores(job_id);
CREATE INDEX idx_job_stores_store_id ON job_stores(store_id);
CREATE INDEX idx_job_skus_job_id ON job_skus(job_id);
CREATE INDEX idx_job_submissions_job_id ON job_submissions(job_id);
CREATE INDEX idx_job_submissions_contractor ON job_submissions(contractor_id);
CREATE INDEX idx_payments_contractor ON payments(contractor_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = false;

-- Row Level Security (RLS) policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE skus ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_skus ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Basic RLS policies (users can only see their own data)
CREATE POLICY "Users can view own profile" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);

-- Jobs policies
CREATE POLICY "Users can view assigned jobs" ON jobs FOR SELECT USING (
    contractor_id = auth.uid() OR client_id = auth.uid() OR created_by = auth.uid()
);

-- Add more RLS policies as needed...

-- Functions for common operations
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Function to calculate job total payout
CREATE OR REPLACE FUNCTION calculate_job_payout()
RETURNS TRIGGER AS $$
DECLARE
    store_count INTEGER;
BEGIN
    -- Calculate number of stores for this job
    IF NEW.all_stores THEN
        -- Count all active stores
        SELECT COUNT(*) INTO store_count FROM stores WHERE is_active = true;
    ELSE
        -- Count stores assigned to this job
        SELECT COUNT(*) INTO store_count 
        FROM job_stores 
        WHERE job_id = NEW.id;
    END IF;
    
    -- Calculate total payout
    NEW.total_payout = NEW.payout_per_store * store_count;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Function to recalculate payout when job_stores changes
CREATE OR REPLACE FUNCTION recalculate_job_payout()
RETURNS TRIGGER AS $$
DECLARE
    job_record RECORD;
    store_count INTEGER;
BEGIN
    -- Get the job record
    IF TG_OP = 'DELETE' THEN
        job_record = OLD;
    ELSE
        job_record = NEW;
    END IF;
    
    -- Recalculate store count for this job
    IF job_record.all_stores THEN
        SELECT COUNT(*) INTO store_count FROM stores WHERE is_active = true;
    ELSE
        SELECT COUNT(*) INTO store_count 
        FROM job_stores 
        WHERE job_id = job_record.job_id;
    END IF;
    
    -- Update the job's total payout
    UPDATE jobs 
    SET total_payout = payout_per_store * store_count
    WHERE id = job_record.job_id;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_brands_updated_at BEFORE UPDATE ON brands FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_stores_updated_at BEFORE UPDATE ON stores FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_skus_updated_at BEFORE UPDATE ON skus FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_jobs_updated_at BEFORE UPDATE ON jobs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_job_submissions_updated_at BEFORE UPDATE ON job_submissions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON payments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Triggers for payout calculation
CREATE TRIGGER calculate_job_payout_trigger 
    BEFORE INSERT OR UPDATE ON jobs 
    FOR EACH ROW EXECUTE FUNCTION calculate_job_payout();

CREATE TRIGGER recalculate_payout_on_store_change
    AFTER INSERT OR UPDATE OR DELETE ON job_stores
    FOR EACH ROW EXECUTE FUNCTION recalculate_job_payout();
