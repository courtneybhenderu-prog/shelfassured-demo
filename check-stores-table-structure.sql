-- Check the current stores table structure to see what columns exist
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'stores' 
ORDER BY ordinal_position;
