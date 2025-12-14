# Re-Import Fixed Spreadsheet

## Step 1: Fix Your Spreadsheet

1. **Re-add the metro lookup tab** that you deleted
2. **Verify the formulas** - make sure all 2,596 rows have data
3. **Save the Excel file** (keep it as Excel or convert to CSV)

## Step 2: Clear Existing Import Data

You have two options:

### Option A: Truncate (Clear all rows, keep table structure)
```sql
TRUNCATE TABLE stores_import;
```

### Option B: Drop and Recreate (Clean slate)
```sql
-- Drop the table
DROP TABLE IF EXISTS stores_import;

-- Recreate it (run create-stores-import-table.sql again)
-- Or just run:
CREATE TABLE stores_import (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    "CHAIN" TEXT,
    "DIVISION" TEXT,
    "BANNER" TEXT,
    "STORE LOCATION NAME" TEXT,
    "STORE" TEXT,
    "Store #" TEXT,
    "ADDRESS" TEXT,
    "CITY" TEXT,
    "STATE" TEXT,
    "ZIP" TEXT,
    "METRO" TEXT,
    "PHONE" TEXT,
    banner_norm TEXT,
    address_norm TEXT,
    city_norm TEXT,
    state_norm TEXT,
    zip5 TEXT,
    match_key TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Recommendation:** Use Option A (TRUNCATE) - it's faster and keeps the table structure.

## Step 3: Re-Import Fixed Spreadsheet

1. **Go to Table Editor** → Click on `stores_import` table
2. **Click "Insert"** → **"Import data from CSV"**
3. **Upload your fixed Excel/CSV file**
4. **Verify import:**
   ```sql
   SELECT COUNT(*) as row_count FROM stores_import;
   -- Should show ~2596 (or close to it)
   
   -- Check for empty rows
   SELECT COUNT(*) as empty_rows
   FROM stores_import
   WHERE ("BANNER" IS NULL OR "BANNER" = '') 
     AND ("ADDRESS" IS NULL OR "ADDRESS" = '');
   -- Should show 0 or very few
   ```

## Step 4: Re-Run Diagnostics

Once the fixed data is imported:

1. **Run `store-reconciliation-diagnostics.sql`** again
2. **Review the results:**
   - Should show `excel_rows_with_data: ~2596`
   - Should show `matched_count` and `new_count` based on complete data
   - First 20 Excel rows should all have data

## Step 5: Execute Import (After Review)

Once diagnostics look good:

1. **Review the match statistics**
2. **Check the first 20 Excel rows vs 20 existing stores** to verify matching logic
3. **Run `store-reconciliation-execute.sql`** when ready

## Quick SQL to Check Data Quality After Re-Import

```sql
-- Total rows
SELECT COUNT(*) as total_rows FROM stores_import;

-- Rows with data
SELECT COUNT(*) as rows_with_data 
FROM stores_import
WHERE ("BANNER" IS NOT NULL AND "BANNER" != '') 
   OR ("ADDRESS" IS NOT NULL AND "ADDRESS" != '');

-- Empty rows (should be 0 or very few)
SELECT COUNT(*) as empty_rows
FROM stores_import
WHERE ("BANNER" IS NULL OR "BANNER" = '') 
  AND ("ADDRESS" IS NULL OR "ADDRESS" = '');

-- Sample rows to verify
SELECT "BANNER", "ADDRESS", "CITY", "STATE", "ZIP", "METRO"
FROM stores_import
WHERE "BANNER" IS NOT NULL
LIMIT 5;
```

