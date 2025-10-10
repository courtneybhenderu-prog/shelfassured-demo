-- STEP 5a: Add missing columns to job_submissions table
-- Run this in Supabase SQL editor

-- Add missing columns to job_submissions table
ALTER TABLE public.job_submissions ADD COLUMN IF NOT EXISTS submitted_by uuid REFERENCES public.users(id);
ALTER TABLE public.job_submissions ADD COLUMN IF NOT EXISTS submitted_at timestamptz DEFAULT now();
ALTER TABLE public.job_submissions ADD COLUMN IF NOT EXISTS status text DEFAULT 'pending_review';
ALTER TABLE public.job_submissions ADD COLUMN IF NOT EXISTS review_notes text;
ALTER TABLE public.job_submissions ADD COLUMN IF NOT EXISTS reviewed_by uuid REFERENCES public.users(id);
ALTER TABLE public.job_submissions ADD COLUMN IF NOT EXISTS reviewed_at timestamptz;
ALTER TABLE public.job_submissions ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE public.job_submissions ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- Add constraints
DO $$
BEGIN
    -- Add status constraint if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.check_constraints WHERE constraint_name = 'job_submissions_status_check') THEN
        ALTER TABLE public.job_submissions ADD CONSTRAINT job_submissions_status_check CHECK (status IN ('pending_review', 'approved', 'rejected'));
    END IF;
END $$;

-- Verify the columns were added
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'job_submissions' AND table_schema = 'public' 
ORDER BY ordinal_position;
