-- SAFE JOB SYSTEM SCHEMA - Handles existing tables
-- Run this in Supabase SQL editor

-- 1) First, let's see what tables already exist
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;

-- 2) Create brands table (if not exists)
CREATE TABLE IF NOT EXISTS public.brands (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL UNIQUE,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 3) Create stores table (if not exists)
CREATE TABLE IF NOT EXISTS public.stores (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    address text,
    city text NOT NULL,
    state text NOT NULL,
    zip_code text,
    phone text,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 4) Create skus table (if not exists)
CREATE TABLE IF NOT EXISTS public.skus (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    brand_id uuid REFERENCES public.brands(id),
    category text,
    barcode text UNIQUE,
    size text,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 5) Check if jobs table exists and what columns it has
SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'jobs' AND table_schema = 'public';

-- 6) Add missing columns to jobs table if they don't exist
DO $$ 
BEGIN
    -- Add assignee_id column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'jobs' AND column_name = 'assignee_id' AND table_schema = 'public') THEN
        ALTER TABLE public.jobs ADD COLUMN assignee_id uuid REFERENCES public.users(id);
    END IF;
    
    -- Add status column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'jobs' AND column_name = 'status' AND table_schema = 'public') THEN
        ALTER TABLE public.jobs ADD COLUMN status text DEFAULT 'pending';
    END IF;
    
    -- Add priority column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'jobs' AND column_name = 'priority' AND table_schema = 'public') THEN
        ALTER TABLE public.jobs ADD COLUMN priority text DEFAULT 'normal';
    END IF;
    
    -- Add due_at column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'jobs' AND column_name = 'due_at' AND table_schema = 'public') THEN
        ALTER TABLE public.jobs ADD COLUMN due_at timestamptz;
    END IF;
    
    -- Add notes column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'jobs' AND column_name = 'notes' AND table_schema = 'public') THEN
        ALTER TABLE public.jobs ADD COLUMN notes text;
    END IF;
    
    -- Add created_by column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'jobs' AND column_name = 'created_by' AND table_schema = 'public') THEN
        ALTER TABLE public.jobs ADD COLUMN created_by uuid REFERENCES public.users(id);
    END IF;
    
    -- Add updated_at column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'jobs' AND column_name = 'updated_at' AND table_schema = 'public') THEN
        ALTER TABLE public.jobs ADD COLUMN updated_at timestamptz DEFAULT now();
    END IF;
END $$;

-- 7) Add constraints to jobs table if they don't exist
DO $$
BEGIN
    -- Add status constraint if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.check_constraints WHERE constraint_name LIKE '%jobs_status%') THEN
        ALTER TABLE public.jobs ADD CONSTRAINT jobs_status_check CHECK (status IN ('pending', 'active', 'pending_review', 'approved', 'rejected'));
    END IF;
    
    -- Add priority constraint if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.check_constraints WHERE constraint_name LIKE '%jobs_priority%') THEN
        ALTER TABLE public.jobs ADD CONSTRAINT jobs_priority_check CHECK (priority IN ('low', 'normal', 'high', 'urgent'));
    END IF;
END $$;

-- 8) Create junction tables (these should be new)
CREATE TABLE IF NOT EXISTS public.job_skus (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    job_id uuid REFERENCES public.jobs(id) ON DELETE CASCADE,
    sku_id uuid REFERENCES public.skus(id) ON DELETE CASCADE,
    quantity_expected integer DEFAULT 1,
    notes text,
    created_at timestamptz DEFAULT now(),
    UNIQUE(job_id, sku_id)
);

CREATE TABLE IF NOT EXISTS public.job_stores (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    job_id uuid REFERENCES public.jobs(id) ON DELETE CASCADE,
    store_id uuid REFERENCES public.stores(id) ON DELETE CASCADE,
    notes text,
    created_at timestamptz DEFAULT now(),
    UNIQUE(job_id, store_id)
);

-- 9) Create submissions table (if not exists)
CREATE TABLE IF NOT EXISTS public.job_submissions (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    job_id uuid REFERENCES public.jobs(id) ON DELETE CASCADE,
    submitted_by uuid REFERENCES public.users(id),
    submitted_at timestamptz DEFAULT now(),
    status text DEFAULT 'pending_review' CHECK (status IN ('pending_review', 'approved', 'rejected')),
    review_notes text,
    reviewed_by uuid REFERENCES public.users(id),
    reviewed_at timestamptz,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 10) Create submission_details table (if not exists)
CREATE TABLE IF NOT EXISTS public.submission_details (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    submission_id uuid REFERENCES public.job_submissions(id) ON DELETE CASCADE,
    sku_id uuid REFERENCES public.skus(id),
    store_id uuid REFERENCES public.stores(id),
    price_found text,
    quantity_found integer,
    issue_flag boolean DEFAULT false,
    issue_type text,
    issue_description text,
    notes text,
    created_at timestamptz DEFAULT now()
);

-- 11) Create submission_photos table (if not exists)
CREATE TABLE IF NOT EXISTS public.submission_photos (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    submission_id uuid REFERENCES public.job_submissions(id) ON DELETE CASCADE,
    sku_id uuid REFERENCES public.skus(id),
    store_id uuid REFERENCES public.stores(id),
    photo_type text NOT NULL CHECK (photo_type IN ('upclose', 'close', 'wide', 'shelf', 'price_tag')),
    url text NOT NULL,
    created_at timestamptz DEFAULT now()
);

-- 12) Enable RLS on all tables
ALTER TABLE public.brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skus ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_skus ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submission_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submission_photos ENABLE ROW LEVEL SECURITY;

-- 13) Create RLS policies (drop existing ones first)
DROP POLICY IF EXISTS "brands_select_all" ON public.brands;
DROP POLICY IF EXISTS "brands_insert_admin" ON public.brands;
DROP POLICY IF EXISTS "brands_update_admin" ON public.brands;
DROP POLICY IF EXISTS "stores_select_all" ON public.stores;
DROP POLICY IF EXISTS "stores_insert_admin" ON public.stores;
DROP POLICY IF EXISTS "stores_update_admin" ON public.stores;
DROP POLICY IF EXISTS "skus_select_all" ON public.skus;
DROP POLICY IF EXISTS "skus_insert_admin" ON public.skus;
DROP POLICY IF EXISTS "skus_update_admin" ON public.skus;
DROP POLICY IF EXISTS "jobs_select_assignee_or_admin" ON public.jobs;
DROP POLICY IF EXISTS "jobs_insert_admin" ON public.jobs;
DROP POLICY IF EXISTS "jobs_update_assignee_or_admin" ON public.jobs;

-- 14) Create new RLS policies
CREATE POLICY "brands_select_all" ON public.brands FOR SELECT USING (true);
CREATE POLICY "brands_insert_admin" ON public.brands FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "brands_update_admin" ON public.brands FOR UPDATE USING (public.is_admin());

CREATE POLICY "stores_select_all" ON public.stores FOR SELECT USING (true);
CREATE POLICY "stores_insert_admin" ON public.stores FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "stores_update_admin" ON public.stores FOR UPDATE USING (public.is_admin());

CREATE POLICY "skus_select_all" ON public.skus FOR SELECT USING (true);
CREATE POLICY "skus_insert_admin" ON public.skus FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "skus_update_admin" ON public.skus FOR UPDATE USING (public.is_admin());

CREATE POLICY "jobs_select_assignee_or_admin" ON public.jobs FOR SELECT USING (
    assignee_id = auth.uid() OR created_by = auth.uid() OR public.is_admin()
);
CREATE POLICY "jobs_insert_admin" ON public.jobs FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "jobs_update_assignee_or_admin" ON public.jobs FOR UPDATE USING (
    assignee_id = auth.uid() OR public.is_admin()
);

-- 15) Grant permissions
GRANT ALL ON public.brands TO authenticated;
GRANT ALL ON public.stores TO authenticated;
GRANT ALL ON public.skus TO authenticated;
GRANT ALL ON public.jobs TO authenticated;
GRANT ALL ON public.job_skus TO authenticated;
GRANT ALL ON public.job_stores TO authenticated;
GRANT ALL ON public.job_submissions TO authenticated;
GRANT ALL ON public.submission_details TO authenticated;
GRANT ALL ON public.submission_photos TO authenticated;

-- 16) Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_jobs_assignee_id ON public.jobs(assignee_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON public.jobs(status);
CREATE INDEX IF NOT EXISTS idx_job_skus_job_id ON public.job_skus(job_id);
CREATE INDEX IF NOT EXISTS idx_job_skus_sku_id ON public.job_skus(sku_id);
CREATE INDEX IF NOT EXISTS idx_job_stores_job_id ON public.job_stores(job_id);
CREATE INDEX IF NOT EXISTS idx_job_stores_store_id ON public.job_stores(store_id);
CREATE INDEX IF NOT EXISTS idx_submissions_job_id ON public.job_submissions(job_id);
CREATE INDEX IF NOT EXISTS idx_submissions_status ON public.job_submissions(status);
CREATE INDEX IF NOT EXISTS idx_submission_details_submission_id ON public.submission_details(submission_id);
CREATE INDEX IF NOT EXISTS idx_submission_photos_submission_id ON public.submission_photos(submission_id);

-- 17) Test the schema
SELECT 'Safe job system schema created successfully' as status;
SELECT 'Tables updated: brands, stores, skus, jobs (with new columns), job_skus, job_stores, job_submissions, submission_details, submission_photos' as tables;
