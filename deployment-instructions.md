## Store Selector Filtering Fix

### Problem
The store selector was only showing Sprouts stores because:
1. The v_distinct_banners view wasn't returning the correct store chain names
2. The dropdown values were being lowercased, causing mismatches with store_chain values

### Solution
1. **Update the view** - Run `fix-store-selector-filtering.sql` in Supabase SQL editor
2. **Code fix** - Already committed to git

### Steps
1. Open Supabase SQL Editor
2. Run `fix-store-selector-filtering.sql`
3. Wait 30 seconds for GitHub Pages to update
4. Test by searching "Bridgeland" - should show H-E-B store

