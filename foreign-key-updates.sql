-- Foreign Key Updates for Submissions/Photos
-- Ensure submissions and photos reference the new job_store_skus table

-- Add job_store_sku_id to submissions table (if it exists)
ALTER TABLE public.submissions 
ADD COLUMN IF NOT EXISTS job_store_sku_id uuid 
REFERENCES public.job_store_skus(id) ON DELETE CASCADE;

-- Add job_store_sku_id to submission_photos table (if it exists)
ALTER TABLE public.submission_photos 
ADD COLUMN IF NOT EXISTS job_store_sku_id uuid 
REFERENCES public.job_store_skus(id) ON DELETE CASCADE;

-- Update existing foreign key constraints for submission_photos
ALTER TABLE public.submission_photos 
DROP CONSTRAINT IF EXISTS submission_photos_submission_fk;

ALTER TABLE public.submission_photos 
ADD CONSTRAINT submission_photos_submission_fk 
FOREIGN KEY (submission_id) REFERENCES public.submissions(id) ON DELETE CASCADE;

-- Verify foreign key constraints
SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name IN ('submissions', 'submission_photos', 'job_store_skus')
ORDER BY tc.table_name, tc.constraint_name;


