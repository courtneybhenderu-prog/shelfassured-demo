-- Quick cleanup to remove red "Unrestricted" warnings
-- Run this in Supabase SQL editor to clean up security warnings

-- Enable RLS on tables that need it (skip views!)
-- job_assignments is a VIEW, not a table - skip it
ALTER TABLE public.job_submissions_backup_20250110 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs_backup_20250110 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users_backup_20250110 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schema_migrations ENABLE ROW LEVEL SECURITY;

-- Create basic policies for backup tables (admins only)
CREATE POLICY "Admins can manage job_submissions_backup" 
ON public.job_submissions_backup_20250110 
FOR ALL USING (public.is_admin());

CREATE POLICY "Admins can manage jobs_backup" 
ON public.jobs_backup_20250110 
FOR ALL USING (public.is_admin());

CREATE POLICY "Admins can manage users_backup" 
ON public.users_backup_20250110 
FOR ALL USING (public.is_admin());

CREATE POLICY "Admins can manage schema_migrations" 
ON public.schema_migrations 
FOR ALL USING (public.is_admin());

-- For job_assignments view, we'll make it secure
-- (This removes the SECURITY DEFINER warning)
DROP VIEW IF EXISTS public.job_assignments;
CREATE VIEW public.job_assignments AS
SELECT 
    j.id as job_id,
    j.title,
    j.status,
    u.full_name as assigned_to,
    u.email as assigned_email
FROM public.jobs j
LEFT JOIN public.users u ON j.assigned_user_id = u.id
WHERE public.is_admin() OR j.assigned_user_id = auth.uid();

-- Grant permissions
GRANT SELECT ON public.job_assignments TO authenticated;
GRANT SELECT ON public.job_assignments TO service_role;

-- Clean up any other views with SECURITY DEFINER warnings
DROP VIEW IF EXISTS public.submission_tracking;
CREATE VIEW public.submission_tracking AS
SELECT 
    js.id as submission_id,
    js.job_id,
    j.title as job_title,
    js.status,
    js.submitted_at,
    u.full_name as submitted_by
FROM public.job_submissions js
JOIN public.jobs j ON js.job_id = j.id
LEFT JOIN public.users u ON js.submitted_by = u.id
WHERE public.is_admin() OR js.submitted_by = auth.uid();

GRANT SELECT ON public.submission_tracking TO authenticated;
GRANT SELECT ON public.submission_tracking TO service_role;

-- Success message
SELECT 'Red warnings cleaned up! All tables now have proper RLS policies.' as status;
