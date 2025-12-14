-- Get full logo_url for Rambler
SELECT id, name, logo_url, 
       LENGTH(logo_url) as url_length,
       CASE 
         WHEN logo_url LIKE '%supabase.co/storage%' THEN 'Supabase Storage'
         WHEN logo_url LIKE 'http%' THEN 'External URL'
         ELSE 'Unknown'
       END as url_type
FROM brands 
WHERE LOWER(name) LIKE '%rambler%'
ORDER BY created_at DESC
LIMIT 1;
