-- Add source field to stores table for tracking user-added vs imported stores
-- This enables quality control and analytics

-- Add source column to stores table
ALTER TABLE public.stores 
ADD COLUMN IF NOT EXISTS source VARCHAR(20) DEFAULT 'imported';

-- Add comment to explain the field
COMMENT ON COLUMN public.stores.source IS 'Source of store data: imported, user_added, admin_added';

-- Update existing stores to have 'imported' source
UPDATE public.stores 
SET source = 'imported' 
WHERE source IS NULL;

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_stores_source ON public.stores(source);

-- Verify the changes
SELECT 
    source,
    COUNT(*) as store_count
FROM public.stores 
GROUP BY source 
ORDER BY store_count DESC;

-- Show sample of stores with source
SELECT 
    name,
    city,
    state,
    source,
    created_at
FROM public.stores 
ORDER BY created_at DESC 
LIMIT 10;
