-- Check what columns actually exist in stores table
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'stores' 
ORDER BY ordinal_position;
