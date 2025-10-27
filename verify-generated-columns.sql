-- Verify if columns are generated
SELECT 
  column_name, 
  data_type, 
  is_nullable, 
  column_default,
  is_generated,
  generation_expression
FROM information_schema.columns 
WHERE table_name='stores' 
  AND column_name IN ('banner_id', 'status', 'zip5', 'state_zip')
ORDER BY column_name;

