# How to Import Excel/CSV Data into stores_import Table

## Method 1: Using Supabase Table Editor (Recommended)

1. **Go to Table Editor**
   - Supabase Dashboard → **Table Editor** (left sidebar)
   - Click on **`stores_import`** table

2. **Import Data**
   - Look for **"Insert"** button (usually top right or in a menu)
   - Click **"Insert"** → Look for **"Import data"** or **"Import CSV"** option
   - **NOT "Export"** - that's for downloading data

3. **Upload File**
   - Click **"Choose File"** or drag and drop
   - Select your Excel file (or CSV if you converted it)
   - Supabase will auto-detect columns

4. **Map Columns** (if needed)
   - Supabase will try to match columns automatically
   - Verify the mapping is correct
   - Click **"Import"** or **"Save"**

## Method 2: Using SQL INSERT (If import button doesn't work)

If the import button isn't working, you can use SQL directly:

1. **Convert Excel to CSV first:**
   - Open Excel file
   - File → Save As → Choose "CSV (Comma delimited) (*.csv)"
   - Save it

2. **Use Supabase's SQL Editor:**
   - Go to **SQL Editor**
   - Use the `COPY` command (PostgreSQL native import)

```sql
-- First, check your CSV file structure
-- Then use COPY command (adjust path/format as needed)

-- Note: Supabase might require using the Storage bucket instead
-- See Method 3 below
```

## Method 3: Using Supabase Storage + SQL

1. **Upload CSV to Storage:**
   - Go to **Storage** (left sidebar)
   - Create a bucket (or use existing)
   - Upload your CSV file

2. **Import via SQL:**
   ```sql
   -- This requires the file to be in a Storage bucket
   -- Then use COPY FROM with the file path
   ```

## Method 4: Manual Row Insert (For Testing)

If you just want to test with a few rows first:

1. **In Table Editor:**
   - Click on `stores_import` table
   - Click **"Insert row"** or **"New row"**
   - Manually enter data for a few test rows
   - Click **"Save"**

## Troubleshooting

**"No rows to export" error:**
- You clicked **"Export"** instead of **"Import"**
- Look for **"Import"** or **"Insert"** button instead

**"Import" button not visible:**
- Make sure you're in **Table Editor** (not SQL Editor)
- Make sure you've selected the `stores_import` table
- Try refreshing the page

**Column mapping issues:**
- Make sure your CSV has headers
- Column names should match: CHAIN, DIVISION, BANNER, etc.
- Check for special characters in column names

**File format issues:**
- Convert Excel to CSV first (File → Save As → CSV)
- Make sure CSV uses comma delimiters
- Check for encoding issues (use UTF-8)

## Quick Test

After importing, verify with:
```sql
SELECT COUNT(*) as row_count FROM stores_import;
SELECT * FROM stores_import LIMIT 5;
```

