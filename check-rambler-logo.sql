-- Check if Rambler brand has a logo_url
SELECT id, name, logo_url, website, created_at 
FROM brands 
WHERE LOWER(name) LIKE '%rambler%'
ORDER BY created_at DESC;
