-- RLS policies for anon role to allow brand creation
CREATE POLICY anon_insert_brands ON brands FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY anon_update_brands ON brands FOR UPDATE TO anon USING (true) WITH CHECK (true);
CREATE POLICY anon_select_brands ON brands FOR SELECT TO anon USING (true);

