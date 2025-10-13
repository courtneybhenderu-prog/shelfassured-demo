-- Fix SunnyGem Austin Audit jobs
-- These jobs have NULL stores and a default "SODA" SKU

-- 1. Delete the broken jobs
DELETE FROM job_stores 
WHERE job_id IN (
    SELECT id FROM jobs WHERE title = 'SunnyGem Austin Audit'
);

DELETE FROM job_skus 
WHERE job_id IN (
    SELECT id FROM jobs WHERE title = 'SunnyGem Austin Audit'
);

DELETE FROM jobs 
WHERE title = 'SunnyGem Austin Audit';

-- 2. Delete the default "SODA" SKU (if it's not needed)
DELETE FROM skus 
WHERE name = 'SODA' AND upc = '123456789123';

-- 3. Verify cleanup
SELECT 'Jobs remaining:' as check_type, COUNT(*) as count FROM jobs WHERE title = 'SunnyGem Austin Audit'
UNION ALL
SELECT 'SODA SKUs remaining:', COUNT(*) FROM skus WHERE name = 'SODA';

