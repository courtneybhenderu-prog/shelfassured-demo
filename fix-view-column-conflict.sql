-- Fix view column name conflict
-- Drop the existing view first, then recreate with correct columns

-- 1) Drop existing view
DROP VIEW IF EXISTS public.v_job_assignments;

-- 2) Create the view with correct column names
CREATE VIEW public.v_job_assignments AS
SELECT
  j.id                AS job_id,
  j.title             AS job_title,
  s.id                AS store_id,
  s.store_chain       AS store_chain,
  s.name              AS store_name,
  k.id                AS sku_id,
  k.name              AS sku_name,
  k.upc               AS sku_code,
  b.id                AS brand_id,
  b.name              AS brand_name,
  j.created_at
FROM public.job_store_skus jss
JOIN public.jobs        j ON j.id = jss.job_id
JOIN public.stores      s ON s.id = jss.store_id
JOIN public.skus        k ON k.id = jss.sku_id
LEFT JOIN public.brands b ON b.id = k.brand_id;

-- 3) Grant permissions
GRANT SELECT ON public.v_job_assignments TO authenticated;

-- 4) Refresh PostgREST cache
NOTIFY pgrst, 'reload schema';

-- 5) Verify the view
SELECT 'View created successfully' AS status;
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name = 'v_job_assignments';

