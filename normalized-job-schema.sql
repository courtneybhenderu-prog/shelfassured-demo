-- PROPER NORMALIZED JOB SYSTEM SCHEMA
-- Run this in Supabase SQL editor

-- 1) First, let's check what tables already exist and their structure
-- This will help us understand the current schema

-- 2) Create proper brands table (if not exists)
CREATE TABLE IF NOT EXISTS public.brands (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL UNIQUE,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 3) Create proper stores table (if not exists)
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

-- 4) Create proper skus table (if not exists)
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

-- 5) Create jobs table with proper relationships
CREATE TABLE IF NOT EXISTS public.jobs (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    title text NOT NULL,
    description text,
    assignee_id uuid REFERENCES public.users(id),
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'pending_review', 'approved', 'rejected')),
    priority text DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    due_at timestamptz,
    notes text,
    created_by uuid REFERENCES public.users(id),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 6) Create job_skus junction table (many-to-many)
CREATE TABLE IF NOT EXISTS public.job_skus (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    job_id uuid REFERENCES public.jobs(id) ON DELETE CASCADE,
    sku_id uuid REFERENCES public.skus(id) ON DELETE CASCADE,
    quantity_expected integer DEFAULT 1,
    notes text,
    created_at timestamptz DEFAULT now(),
    UNIQUE(job_id, sku_id)
);

-- 7) Create job_stores junction table (many-to-many)
CREATE TABLE IF NOT EXISTS public.job_stores (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    job_id uuid REFERENCES public.jobs(id) ON DELETE CASCADE,
    store_id uuid REFERENCES public.stores(id) ON DELETE CASCADE,
    notes text,
    created_at timestamptz DEFAULT now(),
    UNIQUE(job_id, store_id)
);

-- 8) Create submissions table
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

-- 9) Create submission_details table for SKU-specific data
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

-- 10) Create photos table
CREATE TABLE IF NOT EXISTS public.submission_photos (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    submission_id uuid REFERENCES public.job_submissions(id) ON DELETE CASCADE,
    sku_id uuid REFERENCES public.skus(id),
    store_id uuid REFERENCES public.stores(id),
    photo_type text NOT NULL CHECK (photo_type IN ('upclose', 'close', 'wide', 'shelf', 'price_tag')),
    url text NOT NULL,
    created_at timestamptz DEFAULT now()
);

-- 11) Enable RLS on all tables
ALTER TABLE public.brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skus ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_skus ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submission_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submission_photos ENABLE ROW LEVEL SECURITY;

-- 12) Create RLS policies for brands (read-only for authenticated users)
CREATE POLICY "brands_select_all" ON public.brands FOR SELECT USING (true);
CREATE POLICY "brands_insert_admin" ON public.brands FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "brands_update_admin" ON public.brands FOR UPDATE USING (public.is_admin());

-- 13) Create RLS policies for stores (read-only for authenticated users)
CREATE POLICY "stores_select_all" ON public.stores FOR SELECT USING (true);
CREATE POLICY "stores_insert_admin" ON public.stores FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "stores_update_admin" ON public.stores FOR UPDATE USING (public.is_admin());

-- 14) Create RLS policies for skus (read-only for authenticated users)
CREATE POLICY "skus_select_all" ON public.skus FOR SELECT USING (true);
CREATE POLICY "skus_insert_admin" ON public.skus FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "skus_update_admin" ON public.skus FOR UPDATE USING (public.is_admin());

-- 15) Create RLS policies for jobs
CREATE POLICY "jobs_select_assignee_or_admin" ON public.jobs FOR SELECT USING (
    assignee_id = auth.uid() OR created_by = auth.uid() OR public.is_admin()
);
CREATE POLICY "jobs_insert_admin" ON public.jobs FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "jobs_update_assignee_or_admin" ON public.jobs FOR UPDATE USING (
    assignee_id = auth.uid() OR public.is_admin()
);

-- 16) Create RLS policies for job_skus
CREATE POLICY "job_skus_select_assignee_or_admin" ON public.job_skus FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.jobs WHERE id = job_skus.job_id AND (assignee_id = auth.uid() OR created_by = auth.uid())) OR 
    public.is_admin()
);
CREATE POLICY "job_skus_insert_admin" ON public.job_skus FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "job_skus_update_admin" ON public.job_skus FOR UPDATE USING (public.is_admin());

-- 17) Create RLS policies for job_stores
CREATE POLICY "job_stores_select_assignee_or_admin" ON public.job_stores FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.jobs WHERE id = job_stores.job_id AND (assignee_id = auth.uid() OR created_by = auth.uid())) OR 
    public.is_admin()
);
CREATE POLICY "job_stores_insert_admin" ON public.job_stores FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "job_stores_update_admin" ON public.job_stores FOR UPDATE USING (public.is_admin());

-- 18) Create RLS policies for job_submissions
CREATE POLICY "submissions_select_creator_or_admin" ON public.job_submissions FOR SELECT USING (
    submitted_by = auth.uid() OR public.is_admin()
);
CREATE POLICY "submissions_insert_assignee" ON public.job_submissions FOR INSERT WITH CHECK (
    submitted_by = auth.uid()
);
CREATE POLICY "submissions_update_admin" ON public.job_submissions FOR UPDATE USING (public.is_admin());

-- 19) Create RLS policies for submission_details
CREATE POLICY "submission_details_select_creator_or_admin" ON public.submission_details FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.job_submissions WHERE id = submission_details.submission_id AND submitted_by = auth.uid()) OR 
    public.is_admin()
);
CREATE POLICY "submission_details_insert_assignee" ON public.submission_details FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.job_submissions WHERE id = submission_details.submission_id AND submitted_by = auth.uid())
);
CREATE POLICY "submission_details_update_admin" ON public.submission_details FOR UPDATE USING (public.is_admin());

-- 20) Create RLS policies for submission_photos
CREATE POLICY "submission_photos_select_creator_or_admin" ON public.submission_photos FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.job_submissions WHERE id = submission_photos.submission_id AND submitted_by = auth.uid()) OR 
    public.is_admin()
);
CREATE POLICY "submission_photos_insert_assignee" ON public.submission_photos FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.job_submissions WHERE id = submission_photos.submission_id AND submitted_by = auth.uid())
);
CREATE POLICY "submission_photos_update_admin" ON public.submission_photos FOR UPDATE USING (public.is_admin());

-- 21) Grant permissions
GRANT ALL ON public.brands TO authenticated;
GRANT ALL ON public.stores TO authenticated;
GRANT ALL ON public.skus TO authenticated;
GRANT ALL ON public.jobs TO authenticated;
GRANT ALL ON public.job_skus TO authenticated;
GRANT ALL ON public.job_stores TO authenticated;
GRANT ALL ON public.job_submissions TO authenticated;
GRANT ALL ON public.submission_details TO authenticated;
GRANT ALL ON public.submission_photos TO authenticated;

-- 22) Create indexes for performance
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

-- 23) Test the schema
SELECT 'Normalized job system schema created successfully' as status;
SELECT 'Tables created: brands, stores, skus, jobs, job_skus, job_stores, job_submissions, submission_details, submission_photos' as tables;
