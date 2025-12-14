# Store Reconciliation - Quick Start

## Prerequisites

1. **Python 3.8+** installed
2. **Excel file** in current directory: `Master Texas and WFM 12132025.xlsx`
3. **Supabase credentials** in `.env` file

## Quick Setup (5 minutes)

```bash
# 1. Install dependencies
pip install -r store-reconciliation-requirements.txt

# 2. Create .env file
cat > .env << EOF
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
EOF

# 3. Run SQL to add store_number column (in Supabase SQL Editor)
# Open: add-store-number-column.sql
# Copy/paste into Supabase SQL Editor and run

# 4. Run the import script
python store-reconciliation-import.py
```

## What It Does

1. **Reads** Excel file (`SCRUBBED TEXAS + WFM US` tab)
2. **Matches** existing stores using: BANNER, ADDRESS, CITY, STATE, ZIP5
3. **Preserves** existing `stores.id` and `STORE` display values
4. **Creates** new stores with display name: `{Banner} – {City} – {State} – {Street}`
5. **Deactivates** stores not in Excel (`is_active = false`)
6. **Shows** dry-run summary before making changes

## Output Files

- `store-reconciliation-dry-run-summary.txt` - Detailed summary report

## Example Output

```
📊 STATISTICS
   Total rows in Excel: 2,500
   New stores to insert: 150
   Existing stores matched: 2,300
   Duplicate rows removed: 50
   Stores to deactivate: 25

🆕 SAMPLE NEW STORES (first 10):
   1. Whole Foods Market – Austin – TX – Lamar
      Banner: Whole Foods Market
      Address: 525 N Lamar Blvd, Austin, TX 78703
      Store #: 10652
   ...

⚠️  SAMPLE STORES TO DEACTIVATE (first 10):
   1. HEB - ALVIN
      ID: abc123...
      Address: 207 E S ST, ALVIN, TX
   ...
```

## Confirmation

When prompted, type `yes` to execute, or anything else to cancel.

## Troubleshooting

**"store_number column does not exist"**
→ Run `add-store-number-column.sql` in Supabase SQL Editor

**"Excel file not found"**
→ Ensure file is named exactly: `Master Texas and WFM 12132025.xlsx`

**"SUPABASE_URL not set"**
→ Check your `.env` file has correct values

