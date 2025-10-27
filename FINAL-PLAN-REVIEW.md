# Final Plan Review - Single SQL Script

## What This Script Does

**File:** `COMPLETE-FIX-SINGLE-RUN.sql`

This single script will:
1. ✅ Add missing retailers (Sprouts, Whole Foods, Fiesta Mart, etc.)
2. ✅ Add missing banners (Trader Joes, Tom Thumb, etc.)
3. ✅ Link ALL stores to banners using normalized matching (HEB → H-E-B)
4. ✅ Rebuild v_distinct_banners view to show all chains
5. ✅ Report results (how many stores linked, banners available)

## Expected Results After Running

- All ~2,376 stores will have banner_id
- Dropdown will show ALL chains:
  - Albertsons
  - Brookshires
  - Brookshire Brothers  
  - Costco
  - Fiesta Mart
  - H-E-B
  - Kroger
  - Lowes Markets
  - Marketplace
  - Market Street
  - Natural Grocers
  - Randalls
  - Sprouts Farmers Market
  - Target
  - Tom Thumb
  - Trader Joes
  - Walmart
  - Whole Foods Market

- Search will work for all chains:
  - "Bridgeland" → shows H-E-B Bridgeland
  - "Austin" → shows ALL Austin stores (not just Sprouts)

## Safety Features

- Uses `ON CONFLICT DO NOTHING` - won't error if things already exist
- Only updates stores without banner_id
- Rebuilds view safely (DROP + CREATE)

## How to Run

1. Copy the entire `COMPLETE-FIX-SINGLE-RUN.sql` file
2. Paste into Supabase SQL Editor
3. Click Run
4. Wait ~10-30 seconds
5. Review the results table at the end
6. Hard refresh the web page (Cmd+Shift+R)

## What Could Go Wrong

**Low Risk:**
- If retailers/banners already exist → Script skips them (ON CONFLICT)
- If some stores don't match any banner → They stay as NULL (won't error)

**You're Safe To Run:** This script is idempotent (can run multiple times safely)

## After Running

1. Hard refresh: https://courtneybhenderu-prog.github.io/shelfassured-demo/admin/manage-jobs.html
2. Test:
   - Search "Bridgeland" → Should see H-E-B stores
   - Search "Austin" → Should see stores from all chains
   - Filter by H-E-B → Should see 429 stores
   - Filter by Albertsons → Should see 480 stores
   - Dropdown → Should show all chains including Tom Thumb, Trader Joes

## If Something Goes Wrong

Run this to see what happened:
```sql
SELECT COUNT(*) as stores_with_banner FROM stores WHERE banner_id IS NOT NULL;
SELECT * FROM v_distinct_banners ORDER BY banner_name;
```

