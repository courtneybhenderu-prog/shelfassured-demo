-- Simplified Foreign Key Updates for Submissions/Photos
-- Only adds foreign keys if the tables exist

-- Check if submissions table exists and add foreign key
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'submissions' AND table_schema = 'public') THEN
        ALTER TABLE public.submissions 
        ADD COLUMN IF NOT EXISTS job_store_sku_id uuid 
        REFERENCES public.job_store_skus(id) ON DELETE CASCADE;
        
        RAISE NOTICE 'Added job_store_sku_id to submissions table';
    ELSE
        RAISE NOTICE 'submissions table does not exist - skipping';
    END IF;
END $$;

-- Check if submission_photos table exists and add foreign key
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'submission_photos' AND table_schema = 'public') THEN
        ALTER TABLE public.submission_photos 
        ADD COLUMN IF NOT EXISTS job_store_sku_id uuid 
        REFERENCES public.job_store_skus(id) ON DELETE CASCADE;
        
        RAISE NOTICE 'Added job_store_sku_id to submission_photos table';
    ELSE
        RAISE NOTICE 'submission_photos table does not exist - skipping';
    END IF;
END $$;

-- Verify foreign key constraints for job_store_skus
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
    AND tc.table_name = 'job_store_skus'
ORDER BY tc.constraint_name;


