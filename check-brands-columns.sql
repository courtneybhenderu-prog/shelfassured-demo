-- Check if logo_url column exists in brands table
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'brands' 
  AND column_name IN ('logo_url', 'logo_path', 'image_url');
