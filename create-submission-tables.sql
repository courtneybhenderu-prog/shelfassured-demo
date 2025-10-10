-- STEP 4: Create submission and photo tables
-- Run this in Supabase SQL editor

-- Create job_submissions table
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

-- Create submission_details table for SKU-specific data
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

-- Create submission_photos table
CREATE TABLE IF NOT EXISTS public.submission_photos (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    submission_id uuid REFERENCES public.job_submissions(id) ON DELETE CASCADE,
    sku_id uuid REFERENCES public.skus(id),
    store_id uuid REFERENCES public.stores(id),
    photo_type text NOT NULL CHECK (photo_type IN ('upclose', 'close', 'wide', 'shelf', 'price_tag')),
    url text NOT NULL,
    created_at timestamptz DEFAULT now()
);

-- Verify tables were created
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('job_submissions', 'submission_details', 'submission_photos') ORDER BY table_name;
