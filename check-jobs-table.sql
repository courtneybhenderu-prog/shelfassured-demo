-- STEP 1: Check existing jobs table structure
-- Run this first in Supabase SQL editor

SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'jobs' AND table_schema = 'public' 
ORDER BY ordinal_position;
