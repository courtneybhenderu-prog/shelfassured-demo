# Store Reconciliation - SQL Guide

This guide walks you through reconciling stores using pure SQL in Supabase (no Python, no API keys).

## Step 1: Upload Excel to Supabase

1. **Open Supabase Dashboard** → Your Project → **Table Editor**
2. Click **"New Table"** or use existing table
3. Name it: `stores_import`
4. Click **"Import data"** button (or use the import feature)
5. Upload your Excel file (or convert to CSV first)
6. Map columns:
   - `CHAIN` → Text
   - `DIVISION` → Text
   - `BANNER` → Text
   - `STORE LOCATION NAME` → Text
   - `STORE` → Text
   - `Store #` → Text (or Number)
   - `ADDRESS` → Text
   - `CITY` → Text
   - `STATE` → Text
   - `ZIP` → Text
   - `METRO` → Text
   - `PHONE` → Text

**Note:** Supabase will auto-detect column names from your CSV/Excel. Make sure the column names match exactly (case-sensitive).

## Step 2: Run Diagnostics

1. Open **Supabase SQL Editor**
2. Copy and paste the contents of `store-reconciliation-diagnostics.sql`
3. Click **Run**
4. Review the output:

### What to Look For:

**First 20 Excel Rows:**
- Check if `match_key` values look correct
- See if `match_status` shows `✅ MATCH FOUND` or `❌ NO MATCH`
- Compare normalized values (banner_norm, address_norm, etc.)

**20 Existing Supabase Stores:**
- Check their `match_key` values
- Compare with Excel row match keys
- Look for differences in normalization

**Match Statistics:**
- `matched_count` - How many Excel rows matched existing stores
- `new_count` - How many Excel rows are new stores

### Common Issues:

1. **Banner mismatch:** Excel has "Whole Foods Market" but Supabase has "WHOLE FOODS MARKET"
   - **Fix:** Normalization should handle this (lowercase), but check if banner column mapping is correct

2. **Address mismatch:** Excel has "123 Main St" but Supabase has "123 Main Street"
   - **Fix:** Normalization removes "St" vs "Street" differences, but check if address column is correct

3. **ZIP mismatch:** Excel has "77001-1234" but Supabase has "77001"
   - **Fix:** ZIP5 extraction should handle this, but verify zip column mapping

4. **State mismatch:** Excel has "Texas" but Supabase has "TX"
   - **Fix:** State normalization extracts first 2 chars, but check state column mapping

## Step 3: Review and Fix (if needed)

If diagnostics show issues:

1. **Check column names:** Make sure `stores_import` table has exact column names from Excel
2. **Check normalization:** Review the normalization logic in the diagnostics script
3. **Manual fixes:** If needed, update normalization rules in the SQL

## Step 4: Execute Import

**⚠️ IMPORTANT: Review diagnostics first!**

1. Open **Supabase SQL Editor**
2. Copy and paste the contents of `store-reconciliation-execute.sql`
3. **Review the SQL** - it will:
   - Update existing stores (preserves `STORE` and `id`)
   - Insert new stores with generated display names
   - Mark stores as inactive if not in Excel
4. Click **Run**

The script runs in a transaction (BEGIN/COMMIT), so if something goes wrong, you can rollback.

## Step 5: Verify Results

After running the execute script, check:

```sql
-- Total stores
SELECT COUNT(*) as total_stores FROM stores;

-- Active stores
SELECT COUNT(*) as active_stores FROM stores WHERE is_active = TRUE;

-- Inactive stores
SELECT COUNT(*) as inactive_stores FROM stores WHERE is_active = FALSE;

-- Stores with store numbers
SELECT COUNT(*) as stores_with_number FROM stores WHERE store_number IS NOT NULL;

-- Sample new stores
SELECT "STORE", banner, city, state, store_number 
FROM stores 
WHERE created_at >= NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC
LIMIT 10;
```

## Troubleshooting

### "Column does not exist" errors

- Check that `stores_import` table has all required columns
- Column names are case-sensitive in PostgreSQL
- Use double quotes for column names with spaces: `"Store #"`

### "No matches found"

- Run diagnostics first to see why
- Check if normalization is working correctly
- Verify column mappings are correct

### "Transaction rollback"

- The script uses BEGIN/COMMIT, so errors will rollback
- Check error message for specific issue
- Fix the issue and re-run

## Cleanup

After successful import, you can drop the import table:

```sql
DROP TABLE IF EXISTS stores_import;
```

Or keep it for future imports.

