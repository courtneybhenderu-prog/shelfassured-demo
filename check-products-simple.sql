-- Simple diagnostic: Just check if products exist
-- Run these one at a time to see results

-- 1. Does the products table exist and how many rows?
SELECT COUNT(*) as total_rows FROM products;

-- 2. Show ALL columns in products table
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'products'
ORDER BY ordinal_position;

-- 3. If there are products, show first 5 with all columns
SELECT * FROM products LIMIT 5;


