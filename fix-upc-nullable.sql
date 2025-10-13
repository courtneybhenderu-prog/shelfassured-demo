-- Fix UPC constraint to allow NULL values (since UPC is optional)
-- This allows users to create jobs without providing UPC/SKU codes

-- Step 1: Check current constraint on upc column
SELECT 
    column_name,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'skus' 
AND column_name = 'upc';

-- Step 2: Make upc column nullable (allow NULL values)
ALTER TABLE public.skus 
ALTER COLUMN upc DROP NOT NULL;

-- Step 3: Verify the change
SELECT 
    column_name,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'skus' 
AND column_name = 'upc';

-- Step 4: Test by inserting a SKU without UPC
INSERT INTO public.skus (name, brand_id, created_at, updated_at)
VALUES ('Test Product Without UPC', (SELECT id FROM brands LIMIT 1), NOW(), NOW());

-- Step 5: Clean up test record
DELETE FROM public.skus WHERE name = 'Test Product Without UPC';

-- Step 6: Show current SKUs to verify
SELECT 
    name,
    upc,
    brand_id
FROM public.skus 
ORDER BY created_at DESC 
LIMIT 5;
