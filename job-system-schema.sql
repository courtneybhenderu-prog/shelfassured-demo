-- Job Creation System Database Schema
-- Run this in Supabase SQL editor

-- 1) Create jobs table
CREATE TABLE IF NOT EXISTS public.jobs (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    title text NOT NULL,
    brand_text text NOT NULL,
    store_text text NOT NULL,
    city_state text NOT NULL,
    assignee_id uuid REFERENCES public.users(id),
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'pending_review', 'approved', 'rejected')),
    due_at timestamptz,
    notes text,
    created_by uuid REFERENCES public.users(id),
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- 2) Create submissions table
CREATE TABLE IF NOT EXISTS public.submissions (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    job_id uuid REFERENCES public.jobs(id) ON DELETE CASCADE,
    submitted_by uuid REFERENCES public.users(id),
    submitted_at timestamptz DEFAULT now(),
    price_text text,
    issue_flag boolean DEFAULT false,
    issue_type text,
    notes text,
    status text DEFAULT 'pending_review' CHECK (status IN ('pending_review', 'approved', 'rejected')),
    review_notes text,
    reviewed_by uuid REFERENCES public.users(id),
    reviewed_at timestamptz
);

-- 3) Create photos table
CREATE TABLE IF NOT EXISTS public.photos (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    submission_id uuid REFERENCES public.submissions(id) ON DELETE CASCADE,
    kind text NOT NULL CHECK (kind IN ('upclose', 'close', 'wide')),
    url text NOT NULL,
    created_at timestamptz DEFAULT now()
);

-- 4) Enable RLS on all tables
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.photos ENABLE ROW LEVEL SECURITY;

-- 5) Create RLS policies for jobs table
CREATE POLICY "jobs_select_assignee_or_admin"
ON public.jobs
FOR SELECT
USING (
    assignee_id = auth.uid() OR 
    created_by = auth.uid() OR 
    public.is_admin()
);

CREATE POLICY "jobs_insert_admin_only"
ON public.jobs
FOR INSERT
WITH CHECK (
    public.is_admin()
);

CREATE POLICY "jobs_update_assignee_or_admin"
ON public.jobs
FOR UPDATE
USING (
    assignee_id = auth.uid() OR 
    public.is_admin()
)
WITH CHECK (
    assignee_id = auth.uid() OR 
    public.is_admin()
);

-- 6) Create RLS policies for submissions table
CREATE POLICY "submissions_select_creator_or_admin"
ON public.submissions
FOR SELECT
USING (
    submitted_by = auth.uid() OR 
    public.is_admin()
);

CREATE POLICY "submissions_insert_assignee"
ON public.submissions
FOR INSERT
WITH CHECK (
    submitted_by = auth.uid()
);

CREATE POLICY "submissions_update_admin_only"
ON public.submissions
FOR UPDATE
USING (
    public.is_admin()
)
WITH CHECK (
    public.is_admin()
);

-- 7) Create RLS policies for photos table
CREATE POLICY "photos_select_creator_or_admin"
ON public.photos
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.submissions 
        WHERE id = photos.submission_id 
        AND submitted_by = auth.uid()
    ) OR 
    public.is_admin()
);

CREATE POLICY "photos_insert_assignee"
ON public.photos
FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.submissions 
        WHERE id = photos.submission_id 
        AND submitted_by = auth.uid()
    )
);

-- 8) Grant permissions
GRANT ALL ON public.jobs TO authenticated;
GRANT ALL ON public.submissions TO authenticated;
GRANT ALL ON public.photos TO authenticated;

-- 9) Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_jobs_assignee_id ON public.jobs(assignee_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON public.jobs(status);
CREATE INDEX IF NOT EXISTS idx_submissions_job_id ON public.submissions(job_id);
CREATE INDEX IF NOT EXISTS idx_submissions_status ON public.submissions(status);
CREATE INDEX IF NOT EXISTS idx_photos_submission_id ON public.photos(submission_id);

-- 10) Test the tables
SELECT 'Jobs table created successfully' as status;
SELECT 'Submissions table created successfully' as status;
SELECT 'Photos table created successfully' as status;
