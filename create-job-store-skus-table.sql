-- Create job_store_skus table - 3-way junction for jobs × stores × SKUs
-- This solves the duplicate constraint issue when reusing brands/SKUs

-- Table creation (idempotent)
CREATE TABLE IF NOT EXISTS public.job_store_skus (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id uuid NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
    store_id uuid NOT NULL REFERENCES public.stores(id) ON DELETE RESTRICT,
    sku_id uuid NOT NULL REFERENCES public.skus(id) ON DELETE RESTRICT,
    status text DEFAULT 'pending',
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (job_id, store_id, sku_id)
);

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_jss_job ON public.job_store_skus(job_id);
CREATE INDEX IF NOT EXISTS idx_jss_store ON public.job_store_skus(store_id);
CREATE INDEX IF NOT EXISTS idx_jss_sku ON public.job_store_skus(sku_id);

-- RLS setup (disabled initially for stability)
ALTER TABLE public.job_store_skus DISABLE ROW LEVEL SECURITY;

-- Optional: Backfill existing data from current job_stores + job_skus
-- This creates the cross-product of existing relationships
INSERT INTO public.job_store_skus (job_id, store_id, sku_id)
SELECT js.job_id, js.store_id, jsk.sku_id
FROM public.job_stores js
JOIN public.job_skus jsk ON jsk.job_id = js.job_id
ON CONFLICT (job_id, store_id, sku_id) DO NOTHING;

-- Verify table creation
SELECT 
    'job_store_skus table created successfully' as status,
    COUNT(*) as existing_records
FROM public.job_store_skus;

