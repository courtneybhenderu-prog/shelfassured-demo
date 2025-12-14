-- Soft-Delete Future-Proofing for job_store_skus
-- Convert unique constraint to partial unique index for soft deletes
-- Execute only if you introduce deleted_at column in the future

-- Step 1: Add deleted_at column (when needed)
-- ALTER TABLE public.job_store_skus 
-- ADD COLUMN deleted_at timestamptz DEFAULT NULL;

-- Step 2: Drop existing unique constraint
-- ALTER TABLE public.job_store_skus 
-- DROP CONSTRAINT IF EXISTS job_store_skus_job_id_store_id_sku_id_key;

-- Step 3: Create partial unique index
-- CREATE UNIQUE INDEX job_store_skus_unique_active
-- ON public.job_store_skus(job_id, store_id, sku_id)
-- WHERE deleted_at IS NULL;

-- Step 4: Add index for soft delete queries
-- CREATE INDEX idx_job_store_skus_deleted_at
-- ON public.job_store_skus(deleted_at)
-- WHERE deleted_at IS NOT NULL;

-- Verification query (run after implementing soft deletes)
-- SELECT 
--     indexname,
--     indexdef
-- FROM pg_indexes 
-- WHERE tablename = 'job_store_skus'
-- ORDER BY indexname;

-- Soft delete function (when needed)
-- CREATE OR REPLACE FUNCTION soft_delete_job_store_sku(p_job_id uuid, p_store_id uuid, p_sku_id uuid)
-- RETURNS void AS $$
-- BEGIN
--     UPDATE public.job_store_skus 
--     SET deleted_at = NOW()
--     WHERE job_id = p_job_id 
--         AND store_id = p_store_id 
--         AND sku_id = p_sku_id
--         AND deleted_at IS NULL;
-- END;
-- $$ LANGUAGE plpgsql;

-- Restore function (when needed)
-- CREATE OR REPLACE FUNCTION restore_job_store_sku(p_job_id uuid, p_store_id uuid, p_sku_id uuid)
-- RETURNS void AS $$
-- BEGIN
--     UPDATE public.job_store_skus 
--     SET deleted_at = NULL
--     WHERE job_id = p_job_id 
--         AND store_id = p_store_id 
--         AND sku_id = p_sku_id
--         AND deleted_at IS NOT NULL;
-- END;
-- $$ LANGUAGE plpgsql;


