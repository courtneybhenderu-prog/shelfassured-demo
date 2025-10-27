-- Check what v_distinct_banners actually returns

SELECT * FROM v_distinct_banners ORDER BY banner_name;

-- Check if the view is using the old or new structure
SELECT 
  column_name, 
  data_type
FROM information_schema.columns 
WHERE table_name = 'v_distinct_banners'
ORDER BY ordinal_position;

