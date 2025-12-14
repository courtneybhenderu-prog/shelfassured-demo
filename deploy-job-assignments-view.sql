-- Deploy v_job_assignments view for job details page
-- This view provides clean access to job assignment data

-- 1) Create/replace the view
CREATE OR REPLACE VIEW public.v_job_assignments AS
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

-- 2) Make it readable to signed-in users (not anon)
GRANT SELECT ON public.v_job_assignments TO authenticated;

-- 3) Refresh PostgREST's schema cache
NOTIFY pgrst, 'reload schema';

-- 4) Verify the view was created
SELECT 'View created successfully' AS status;
SELECT 
    table_name,
    table_type,
    is_updatable
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name = 'v_job_assignments';


