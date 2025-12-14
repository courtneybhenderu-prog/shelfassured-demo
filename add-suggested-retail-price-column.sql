-- Add suggested_retail_price column to products table
-- This stores the Suggested Retail Price entered in the brand onboarding form

-- Check if column already exists
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'products' 
        AND column_name = 'suggested_retail_price'
    ) THEN
        -- Add the column
        ALTER TABLE products 
        ADD COLUMN suggested_retail_price NUMERIC(10, 2);
        
        -- Add comment for documentation
        COMMENT ON COLUMN products.suggested_retail_price IS 'Suggested retail price for the product, entered during brand onboarding';
        
        RAISE NOTICE 'Column suggested_retail_price added to products table';
    ELSE
        RAISE NOTICE 'Column suggested_retail_price already exists in products table';
    END IF;
END $$;

-- Verify the column was added
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    numeric_precision,
    numeric_scale
FROM information_schema.columns 
WHERE table_name = 'products' 
AND table_schema = 'public'
AND column_name = 'suggested_retail_price';


