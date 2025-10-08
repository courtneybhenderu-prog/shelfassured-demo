-- Create products table for admin barcode capture
-- This table stores product information with barcodes for the admin tool
-- Updated with Marc's requirements: date, store location, SKU, brand, product description, size

CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    barcode VARCHAR(50) UNIQUE NOT NULL, -- SKU/UPC
    brand VARCHAR(100) NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT, -- Product description
    size VARCHAR(50), -- Package size (e.g., "12oz", "500ml", "1lb")
    category VARCHAR(50) NOT NULL,
    store VARCHAR(100), -- Store location
    scan_date DATE DEFAULT CURRENT_DATE, -- Date scanned
    added_by UUID REFERENCES users(id) ON DELETE SET NULL,
    notes TEXT, -- Additional notes
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on barcode for fast lookups
CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode);

-- Create index on brand for filtering
CREATE INDEX IF NOT EXISTS idx_products_brand ON products(brand);

-- Create index on category for filtering
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_products_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_products_updated_at_trigger
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_products_updated_at();

-- RLS Policies for products table
-- Only admins can insert/update/delete products
-- All users can read products (for job validation)

CREATE POLICY "Admins can manage products" ON products
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );

CREATE POLICY "Users can view products" ON products
    FOR SELECT USING (true);

-- Enable RLS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
