-- Brand Products and Stores Relational Tables
-- Creates junction tables to link brands with products and stores
-- DO NOT modify existing brands, products, stores, jobs, or job_store_skus tables

BEGIN;

-- Step 1: Ensure products table has globally unique SKU index
-- Handle various possible column names and normalize to sku/upc/name structure

DO $$
BEGIN
    -- If products has 'barcode' column but no 'sku', add sku column and copy data
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' AND column_name = 'barcode'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' AND column_name = 'sku'
    ) THEN
        ALTER TABLE products ADD COLUMN sku VARCHAR(50);
        UPDATE products SET sku = barcode WHERE sku IS NULL AND barcode IS NOT NULL;
    END IF;
    
    -- If products has neither sku nor barcode, add sku column (nullable for existing data)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' AND column_name IN ('sku', 'barcode')
    ) THEN
        ALTER TABLE products ADD COLUMN sku VARCHAR(50);
    END IF;
    
    -- Ensure name column exists
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' AND column_name = 'name'
    ) THEN
        ALTER TABLE products ADD COLUMN name VARCHAR(200);
    END IF;
    
    -- Ensure upc column exists (map from identifier if present)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' AND column_name = 'upc'
    ) THEN
        ALTER TABLE products ADD COLUMN upc VARCHAR(50);
        
        -- If identifier column exists, copy to upc
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'products' AND column_name = 'identifier'
        ) THEN
            UPDATE products SET upc = identifier WHERE upc IS NULL AND identifier IS NOT NULL;
        END IF;
        
        -- If sku exists but upc is null, copy sku to upc
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'products' AND column_name = 'sku'
        ) THEN
            UPDATE products SET upc = sku WHERE upc IS NULL AND sku IS NOT NULL;
        END IF;
    END IF;
END $$;

-- Create unique index on sku (globally unique, not per-brand)
CREATE UNIQUE INDEX IF NOT EXISTS products_sku_key ON products (sku) WHERE sku IS NOT NULL;

-- Step 2: Create brand_products junction table
CREATE TABLE IF NOT EXISTS brand_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    product_label TEXT,  -- Optional brand-specific display name (e.g., if CSV name differs from products.name)
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (brand_id, product_id)
);

-- Step 3: Create brand_stores junction table
CREATE TABLE IF NOT EXISTS brand_stores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    brand_id UUID NOT NULL REFERENCES brands(id) ON DELETE CASCADE,
    store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    source TEXT DEFAULT 'manual',  -- 'manual' | 'csv' | 'distributor' | 'job'
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE (brand_id, store_id)
);

-- Step 4: Create indexes for performance
CREATE INDEX IF NOT EXISTS brand_products_brand_idx ON brand_products(brand_id);
CREATE INDEX IF NOT EXISTS brand_products_product_idx ON brand_products(product_id);
CREATE INDEX IF NOT EXISTS brand_stores_brand_idx ON brand_stores(brand_id);
CREATE INDEX IF NOT EXISTS brand_stores_store_idx ON brand_stores(store_id);

-- Step 5: RLS Policies for brand_products
-- Mirror brands table access rules: admins can read/write, brand users can read their own

ALTER TABLE brand_products ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Admins can manage brand_products" ON brand_products;
DROP POLICY IF EXISTS "Brand users can read their own brand_products" ON brand_products;

-- Admins can read/write all
CREATE POLICY "Admins can manage brand_products" ON brand_products
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- Brand users can read their own brand's products
CREATE POLICY "Brand users can read their own brand_products" ON brand_products
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM brands 
            WHERE brands.id = brand_products.brand_id
            AND brands.created_by = auth.uid()
        )
    );

-- Step 6: RLS Policies for brand_stores
-- Mirror brands table access rules

ALTER TABLE brand_stores ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Admins can manage brand_stores" ON brand_stores;
DROP POLICY IF EXISTS "Brand users can read their own brand_stores" ON brand_stores;

-- Admins can read/write all
CREATE POLICY "Admins can manage brand_stores" ON brand_stores
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

-- Brand users can read their own brand's stores
CREATE POLICY "Brand users can read their own brand_stores" ON brand_stores
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM brands 
            WHERE brands.id = brand_stores.brand_id
            AND brands.created_by = auth.uid()
        )
    );

COMMIT;

-- Verification queries (run separately to check):
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'products' ORDER BY ordinal_position;
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'brand_products' ORDER BY ordinal_position;
-- SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'brand_stores' ORDER BY ordinal_position;
-- SELECT indexname FROM pg_indexes WHERE tablename = 'products' AND indexname LIKE '%sku%';

