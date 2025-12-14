# How to Upload Excel to Supabase

## Quick Steps

1. **Open Supabase Dashboard**
   - Go to your project
   - Click **"Table Editor"** in the left sidebar

2. **Create New Table**

   **Option A: Use SQL (Recommended)**
   - Open Supabase SQL Editor
   - Run `create-stores-import-table.sql`
   - This creates the table with proper structure and primary key
   
   **Option B: Manual Creation**
   - Click **"New Table"** button (top right)
   - Name it: `stores_import`
   - **Add a primary key column:**
     - Click **"Add Column"**
     - Name: `id`
     - Type: `uuid`
     - Check **"Is Primary Key"**
     - Check **"Has Default Value"** → Select `gen_random_uuid()`
   - Click **"Create"**
   - **Note:** You'll get a warning about no primary key - you can ignore it for now, or add the `id` column as above

3. **Import Your Excel File**

   **Option A: Direct CSV Import (Recommended)**
   - Convert your Excel to CSV first:
     - Open Excel file
     - File → Save As → Choose "CSV (Comma delimited) (*.csv)"
   - In Supabase Table Editor:
     - Click on the `stores_import` table
     - Click **"Insert"** → **"Import data from CSV"**
     - Upload your CSV file
     - Supabase will auto-detect columns

   **Option B: Manual Column Creation**
   - Create columns manually:
     - Click **"Add Column"** for each:
       - `CHAIN` (text)
       - `DIVISION` (text)
       - `BANNER` (text)
       - `STORE LOCATION NAME` (text)
       - `STORE` (text)
       - `Store #` (text) - Note: Use quotes for column name with #
       - `ADDRESS` (text)
       - `CITY` (text)
       - `STATE` (text)
       - `ZIP` (text)
       - `METRO` (text)
       - `PHONE` (text)
   - Then use "Insert" → "Import data from CSV"

4. **Verify Upload**
   - Check that all rows imported
   - Verify column names match exactly (case-sensitive!)
   - Run this query to check:
   ```sql
   SELECT COUNT(*) as row_count FROM stores_import;
   SELECT column_name FROM information_schema.columns 
   WHERE table_name = 'stores_import' 
   ORDER BY ordinal_position;
   ```

## Important Notes

- **Column names are case-sensitive** in PostgreSQL
- If your Excel has different column names, either:
  1. Rename columns in Excel before exporting to CSV
  2. Or update the SQL scripts to use your actual column names

- **Special characters in column names** (like `Store #`) need to be quoted in SQL:
  - Use double quotes: `"Store #"`

## Troubleshooting

**"Table already exists"**
- Either drop it first: `DROP TABLE stores_import;`
- Or use a different name and update the SQL scripts

**"Column not found"**
- Check exact column names (case-sensitive)
- Run `check-import-table.sql` to see what columns exist

**"Import failed"**
- Make sure CSV is properly formatted
- Check for special characters or encoding issues
- Try importing a smaller sample first

