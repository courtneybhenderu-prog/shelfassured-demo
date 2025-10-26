-- Step 2: Execution Foreign Keys
-- Ensure submissions point to the triple and photos point to submissions

-- Check if submissions table exists first
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'submissions') THEN
        -- Add job_store_sku_id column to submissions if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'submissions' AND column_name = 'job_store_sku_id'
        ) THEN
            ALTER TABLE public.submissions 
            ADD COLUMN job_store_sku_id uuid 
            REFERENCES public.job_store_skus(id) ON DELETE CASCADE;
            
            RAISE NOTICE 'Added job_store_sku_id column to submissions table';
        ELSE
            RAISE NOTICE 'job_store_sku_id column already exists in submissions table';
        END IF;
    ELSE
        RAISE NOTICE 'submissions table does not exist - skipping FK addition';
    END IF;
END $$;

-- Check if submission_photos table exists and add FK constraint
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'submission_photos') THEN
        -- Add foreign key constraint if it doesn't exist
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'submission_photos_submission_fk'
        ) THEN
            ALTER TABLE public.submission_photos
            ADD CONSTRAINT submission_photos_submission_fk
            FOREIGN KEY (submission_id) REFERENCES public.submissions(id) ON DELETE CASCADE;
            
            RAISE NOTICE 'Added foreign key constraint to submission_photos table';
        ELSE
            RAISE NOTICE 'Foreign key constraint already exists on submission_photos table';
        END IF;
    ELSE
        RAISE NOTICE 'submission_photos table does not exist - skipping FK addition';
    END IF;
END $$;

