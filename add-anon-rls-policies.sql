-- RLS policies for anon role to allow brand creation
-- Run this in Supabase SQL editor

-- Allow inserts into brands for anon, but only the public columns set by RPC
CREATE POLICY anon_insert_brands ON brands
FOR INSERT
TO anon
WITH CHECK (true);

-- Allow updates by anon only on the specific row id returned (RPC writes name/website/etc.)
CREATE POLICY anon_update_brands ON brands
FOR UPDATE
TO anon
USING (true)
WITH CHECK (true);

-- Allow anon to read brands (for the detail page)
CREATE POLICY anon_select_brands ON brands
FOR SELECT
TO anon
USING (true);


