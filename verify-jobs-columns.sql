-- Quick verification of jobs table columns vs code
-- This will help identify any remaining mismatches

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'jobs' 
AND column_name IN (
    'title',
    'description', 
    'brand_id',
    'assigned_user_id',
    'priority',
    'due_date',
    'instructions',
    'status',
    'total_payout',
    'created_at'
)
ORDER BY column_name;
