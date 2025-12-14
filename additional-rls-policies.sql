-- Additional RLS policies for products and stores
-- Run this in Supabase SQL editor

-- Products policies
CREATE POLICY anon_insert_products ON products FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY anon_select_products ON products FOR SELECT TO anon USING (true);

-- Stores policies  
CREATE POLICY anon_insert_stores ON stores FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY anon_select_stores ON stores FOR SELECT TO anon USING (true);

-- Retailers policies
CREATE POLICY anon_insert_retailers ON retailers FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY anon_select_retailers ON retailers FOR SELECT TO anon USING (true);


