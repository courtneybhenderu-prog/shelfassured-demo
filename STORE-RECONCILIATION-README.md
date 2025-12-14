# Store Reconciliation Import Script

This script reconciles stores from an Excel file with the existing Supabase `stores` table.

## Source File

- **File:** `Master Texas and WFM 12132025.xlsx`
- **Tab:** `SCRUBBED TEXAS + WFM US`
- **Columns:** CHAIN, DIVISION, BANNER, STORE LOCATION NAME, STORE, Store #, ADDRESS, CITY, STATE, ZIP, METRO, PHONE

## Features

1. **Matching Logic:**
   - Matches existing stores using: BANNER (normalized), ADDRESS (normalized), CITY, STATE, ZIP5
   - Preserves existing `stores.id` and `STORE` display values
   - Never overwrites existing `STORE` values

2. **New Store Creation:**
   - Generates `STORE` display name: `{Banner} – {City} – {State} – {Street Fragment}`
   - Example: `Whole Foods Market – Austin – TX – Lamar`
   - Saves `Store #` in `store_number` column (indexed for search)

3. **Data Handling:**
   - Normalizes addresses, cities, banners for matching
   - Extracts clean 5-digit ZIP codes (zero-padded)
   - Handles duplicates: keeps row with most complete data (store number wins)

4. **Active/Inactive Management:**
   - Sets `is_active = false` for stores in database but not in Excel
   - Sets `is_active = true` for all stores in Excel (new and existing)

5. **Safety:**
   - **Dry-run mode by default** - shows summary before making changes
   - Requires explicit confirmation before executing
   - Produces detailed summary report

## Setup

1. **Install dependencies:**
   ```bash
   pip install -r store-reconciliation-requirements.txt
   ```

2. **Set up environment variables:**
   Create a `.env` file in the project root:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
   ```
   
   **Note:** Use `SUPABASE_SERVICE_ROLE_KEY` for full access, or `SUPABASE_ANON_KEY` if using RLS.

3. **Prepare the database:**
   Run `add-store-number-column.sql` in Supabase SQL Editor to ensure the `store_number` column exists.

4. **Place Excel file:**
   Ensure `Master Texas and WFM 12132025.xlsx` is in the same directory as the script.

## Usage

1. **Run the script:**
   ```bash
   python store-reconciliation-import.py
   ```

2. **Review the dry-run summary:**
   - The script will display a summary showing:
     - Number of new stores to insert
     - Number of existing stores matched
     - Number of stores to deactivate
     - Sample records for each category
   - Summary is also saved to `store-reconciliation-dry-run-summary.txt`

3. **Confirm execution:**
   - Type `yes` to execute the import
   - Type anything else to cancel

## Output

### Dry-Run Summary

The script produces a detailed summary including:

- **Statistics:**
  - Total rows in Excel
  - New stores to insert
  - Existing stores matched
  - Duplicate rows removed
  - Stores to deactivate

- **Sample Records:**
  - First 10 new stores with display names
  - First 10 stores to be deactivated
  - Any conflicts found

### Execution Log

When executed, the script will:
1. Insert new stores with generated display names
2. Update existing stores (preserving `STORE` values)
3. Deactivate stores not in Excel
4. Report progress for each step

## Matching Rules

### Exact Match Criteria

Stores are matched using these normalized fields:
- **BANNER:** Lowercased, trimmed
- **ADDRESS:** Normalized (removes suffixes, suite numbers, punctuation)
- **CITY:** Lowercased, trimmed
- **STATE:** Uppercase, 2 characters
- **ZIP5:** First 5 digits, zero-padded

### Address Normalization

The script normalizes addresses by:
- Removing common street suffixes (St, Street, Rd, Road, Ave, etc.)
- Removing suite/unit numbers
- Removing punctuation
- Lowercasing and trimming whitespace

### Display Name Generation

For new stores, the `STORE` display name is generated as:
```
{Banner} – {City} – {State} – {Street Fragment}
```

Where:
- **Banner:** From BANNER column (preserves original casing)
- **City:** From CITY column
- **State:** Normalized to 2-letter uppercase
- **Street Fragment:** First significant word from ADDRESS (skips numbers, directions)

## Safety Features

1. **No Deletion:** Stores are never deleted, only marked `is_active = false`
2. **Preserve Existing:** Existing `STORE` values are never overwritten
3. **Dry-Run First:** Always shows summary before making changes
4. **Explicit Confirmation:** Requires user to type "yes" to execute
5. **Error Handling:** Catches and reports errors without crashing

## Troubleshooting

### Column Missing Error

If you see an error about `store_number` column:
1. Run `add-store-number-column.sql` in Supabase SQL Editor
2. Re-run the import script

### Excel File Not Found

Ensure:
- File is named exactly: `Master Texas and WFM 12132025.xlsx`
- File is in the same directory as the script
- Tab name is exactly: `SCRUBBED TEXAS + WFM US`

### Supabase Connection Error

Check:
- `SUPABASE_URL` is correct
- `SUPABASE_SERVICE_ROLE_KEY` has proper permissions
- Network connection is working

## Notes

- **Non-Goals:** This script does NOT:
  - Refactor schema
  - Change RLS policies
  - Touch jobs, submissions, or brand data
  - Rename existing STORE values

- **Store Number:** The `store_number` column is optional but recommended for search/indexing. If a store doesn't have a number, it will be set to `NULL`.

- **Duplicates:** If duplicate rows exist in Excel (same match key), the script keeps the row with a store number, or the first row if neither has a number.

