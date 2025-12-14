# Import CBSA Lookup Table

## Step 1: Create the Table

Run `create-cbsa-lookup-table.sql` in Supabase SQL Editor to create the `cbsa_lookup` table.

## Step 2: Import CBSA LIST Tab

1. **Export your "CBSA LIST" tab to CSV:**
   - Open your Excel file
   - Go to the "CBSA LIST" tab
   - File → Save As → Choose "CSV (Comma delimited) (*.csv)"
   - Save it as `cbsa_list.csv`

2. **Import to Supabase:**
   - Go to **Table Editor** → Click on `cbsa_lookup` table
   - Click **"Insert"** → **"Import data from CSV"**
   - Upload `cbsa_list.csv`
   - **Map columns:**
     - `ZIP CODE` → `zip_code`
     - `STATE` → `state`
     - `MSA No.` → `msa_number`
     - `County No.` → `county_number`
     - `MSA Name` → `msa_name`

3. **Verify import:**
   ```sql
   SELECT COUNT(*) as total_cbsa_entries FROM cbsa_lookup;
   -- Should match the number of rows in your CBSA LIST tab
   
   SELECT * FROM cbsa_lookup LIMIT 5;
   -- Verify data looks correct
   ```

## Step 3: Update Store Reconciliation Scripts

The reconciliation scripts will now:
- JOIN `stores_import` with `cbsa_lookup` to populate METRO
- Use the actual MSA names instead of VLOOKUP formulas

## Alternative: Convert Formulas to Values in Excel

If you prefer not to create a lookup table:

1. **In Excel:**
   - Select all cells with VLOOKUP formulas
   - Copy (Cmd+C / Ctrl+C)
   - Right-click → **"Paste Special"** → **"Values"**
   - This converts formulas to actual values
   - Save and import

**But the lookup table approach is better** because:
- More maintainable
- Can update CBSA data without re-importing stores
- Faster lookups in SQL
- Can be reused for other purposes

