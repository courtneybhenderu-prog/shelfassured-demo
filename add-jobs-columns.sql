-- STEP 2: Add missing columns to jobs table
-- Run this in Supabase SQL editor

-- Add assignee_id column
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS assignee_id uuid REFERENCES public.users(id);

-- Add status column
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS status text DEFAULT 'pending';

-- Add priority column
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS priority text DEFAULT 'normal';

-- Add due_at column
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS due_at timestamptz;

-- Add notes column
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS notes text;

-- Add created_by column
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES public.users(id);

-- Add updated_at column
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- Add constraints
ALTER TABLE public.jobs ADD CONSTRAINT IF NOT EXISTS jobs_status_check CHECK (status IN ('pending', 'active', 'pending_review', 'approved', 'rejected'));
ALTER TABLE public.jobs ADD CONSTRAINT IF NOT EXISTS jobs_priority_check CHECK (priority IN ('low', 'normal', 'high', 'urgent'));

-- Verify the columns were added
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'jobs' AND table_schema = 'public' 
ORDER BY ordinal_position;
