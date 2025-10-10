-- STEP 5: Enable RLS and create security policies
-- Run this in Supabase SQL editor

-- Enable RLS on all tables
ALTER TABLE public.brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skus ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_skus ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submission_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submission_photos ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for brands (read-only for authenticated users)
CREATE POLICY "brands_select_all" ON public.brands FOR SELECT USING (true);
CREATE POLICY "brands_insert_admin" ON public.brands FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "brands_update_admin" ON public.brands FOR UPDATE USING (public.is_admin());

-- Create RLS policies for stores (read-only for authenticated users)
CREATE POLICY "stores_select_all" ON public.stores FOR SELECT USING (true);
CREATE POLICY "stores_insert_admin" ON public.stores FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "stores_update_admin" ON public.stores FOR UPDATE USING (public.is_admin());

-- Create RLS policies for skus (read-only for authenticated users)
CREATE POLICY "skus_select_all" ON public.skus FOR SELECT USING (true);
CREATE POLICY "skus_insert_admin" ON public.skus FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "skus_update_admin" ON public.skus FOR UPDATE USING (public.is_admin());

-- Create RLS policies for jobs
CREATE POLICY "jobs_select_assignee_or_admin" ON public.jobs FOR SELECT USING (
    assignee_id = auth.uid() OR created_by = auth.uid() OR public.is_admin()
);
CREATE POLICY "jobs_insert_admin" ON public.jobs FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "jobs_update_assignee_or_admin" ON public.jobs FOR UPDATE USING (
    assignee_id = auth.uid() OR public.is_admin()
);

-- Create RLS policies for job_skus
CREATE POLICY "job_skus_select_assignee_or_admin" ON public.job_skus FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.jobs WHERE id = job_skus.job_id AND (assignee_id = auth.uid() OR created_by = auth.uid())) OR 
    public.is_admin()
);
CREATE POLICY "job_skus_insert_admin" ON public.job_skus FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "job_skus_update_admin" ON public.job_skus FOR UPDATE USING (public.is_admin());

-- Create RLS policies for job_stores
CREATE POLICY "job_stores_select_assignee_or_admin" ON public.job_stores FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.jobs WHERE id = job_stores.job_id AND (assignee_id = auth.uid() OR created_by = auth.uid())) OR 
    public.is_admin()
);
CREATE POLICY "job_stores_insert_admin" ON public.job_stores FOR INSERT WITH CHECK (public.is_admin());
CREATE POLICY "job_stores_update_admin" ON public.job_stores FOR UPDATE USING (public.is_admin());

-- Create RLS policies for job_submissions
CREATE POLICY "submissions_select_creator_or_admin" ON public.job_submissions FOR SELECT USING (
    submitted_by = auth.uid() OR public.is_admin()
);
CREATE POLICY "submissions_insert_assignee" ON public.job_submissions FOR INSERT WITH CHECK (
    submitted_by = auth.uid()
);
CREATE POLICY "submissions_update_admin" ON public.job_submissions FOR UPDATE USING (public.is_admin());

-- Create RLS policies for submission_details
CREATE POLICY "submission_details_select_creator_or_admin" ON public.submission_details FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.job_submissions WHERE id = submission_details.submission_id AND submitted_by = auth.uid()) OR 
    public.is_admin()
);
CREATE POLICY "submission_details_insert_assignee" ON public.submission_details FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.job_submissions WHERE id = submission_details.submission_id AND submitted_by = auth.uid())
);
CREATE POLICY "submission_details_update_admin" ON public.submission_details FOR UPDATE USING (public.is_admin());

-- Create RLS policies for submission_photos
CREATE POLICY "submission_photos_select_creator_or_admin" ON public.submission_photos FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.job_submissions WHERE id = submission_photos.submission_id AND submitted_by = auth.uid()) OR 
    public.is_admin()
);
CREATE POLICY "submission_photos_insert_assignee" ON public.submission_photos FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.job_submissions WHERE id = submission_photos.submission_id AND submitted_by = auth.uid())
);
CREATE POLICY "submission_photos_update_admin" ON public.submission_photos FOR UPDATE USING (public.is_admin());

-- Grant permissions
GRANT ALL ON public.brands TO authenticated;
GRANT ALL ON public.stores TO authenticated;
GRANT ALL ON public.skus TO authenticated;
GRANT ALL ON public.jobs TO authenticated;
GRANT ALL ON public.job_skus TO authenticated;
GRANT ALL ON public.job_stores TO authenticated;
GRANT ALL ON public.job_submissions TO authenticated;
GRANT ALL ON public.submission_details TO authenticated;
GRANT ALL ON public.submission_photos TO authenticated;

-- Verify RLS is enabled
SELECT schemaname, tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename IN ('brands', 'stores', 'skus', 'jobs', 'job_skus', 'job_stores', 'job_submissions', 'submission_details', 'submission_photos') ORDER BY tablename;
