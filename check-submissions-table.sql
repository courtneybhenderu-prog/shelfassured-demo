-- Check existing job_submissions table structure
-- Run this in Supabase SQL editor

SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'job_submissions' AND table_schema = 'public' 
ORDER BY ordinal_position;
