-- Ensure authenticated users (especially admins) can query brand_products with JOINs
-- This fixes the issue where products don't load when selecting an existing brand

-- Check current policies
SELECT 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual, 
    with_check
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'brand_products'
ORDER BY policyname;

-- Add a more permissive SELECT policy for authenticated users (admins specifically)
-- This ensures the JOIN query in loadBrandProducts() works
DROP POLICY IF EXISTS "Authenticated can read brand_products" ON brand_products;

CREATE POLICY "Authenticated can read brand_products" ON brand_products
    FOR SELECT TO authenticated
    USING (
        -- Allow if user is admin
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
        -- OR if user created the brand
        OR EXISTS (
            SELECT 1 FROM brands 
            WHERE brands.id = brand_products.brand_id
            AND brands.created_by = auth.uid()
        )
    );

-- Reload schema
NOTIFY pgrst, 'reload schema';

-- Verify the new policy was created
SELECT 
    policyname, 
    permissive, 
    roles, 
    cmd
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'brand_products'
ORDER BY policyname;


