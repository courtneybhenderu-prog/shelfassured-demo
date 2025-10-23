-- Create view for job assignments using the new job_store_skus table
-- This view provides a clean interface for displaying job details

CREATE OR REPLACE VIEW public.v_job_assignments AS
SELECT 
    jss.job_id,
    jss.store_id,
    jss.sku_id,
    jss.status as assignment_status,
    jss.created_at as assignment_created_at,
    
    -- Job details
    j.title as job_title,
    j.description as job_description,
    j.priority as job_priority,
    j.status as job_status,
    j.payout_per_store,
    j.created_at as job_created_at,
    
    -- Brand details
    b.name as brand_name,
    b.id as brand_id,
    
    -- Store details
    s.name as store_name,
    s.store_chain,
    s.city as store_city,
    s.state as store_state,
    s.address as store_address,
    s.zip_code as store_zip,
    
    -- SKU details
    sk.name as sku_name,
    sk.upc as sku_code,
    sk.description as sku_description,
    sk.price as sku_price,
    sk.size as sku_size,
    sk.flavor as sku_flavor
    
FROM public.job_store_skus jss
JOIN public.jobs j ON j.id = jss.job_id
JOIN public.brands b ON b.id = j.brand_id
JOIN public.stores s ON s.id = jss.store_id
JOIN public.skus sk ON sk.id = jss.sku_id
WHERE jss.status != 'deleted'  -- Exclude soft-deleted assignments
ORDER BY jss.job_id, s.store_chain, s.name, sk.name;

-- Grant access to authenticated users
GRANT SELECT ON public.v_job_assignments TO authenticated;

-- Add comment for documentation
COMMENT ON VIEW public.v_job_assignments IS 'View providing job assignment details with store and SKU information for the new job_store_skus architecture';
