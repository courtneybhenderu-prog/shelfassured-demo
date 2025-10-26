# Verification Status - Store Selector Fix

## ✅ VERIFIED

### Selector & Filtering
- ✅ Dropdown emits banner_id as value (line 77 in FIXED.js)
- ✅ Dropdown displays banner_name (line 78)
- ✅ Filter uses `store.banner_id === chain` (line 270)

### Schema & Constraints
- ✅ Unique index exists on (banner_id, street_norm, city_norm, state, zip5)
- ✅ banner_id column added to stores
- ✅ status column added to stores
- ⚠️ Generated columns (zip5, state_zip) need separate migration (add-generated-columns.sql)

### Importer Behavior
- ✅ CSV parser expects: retailer,name,address,city,state_zip
- ✅ retailer resolved to banner_id via retailer_banner_aliases
- ✅ Address normalization applied
- ✅ Uses banner_id in payload instead of retailer_id
- ✅ Check uses banner_id + street_norm + city_norm + state (lines 614-621)

## ⚠️ MISSING

### Test
- ❌ Pilot upload results not yet tested
- ❌ Need to verify no duplicates created

## FILES TO DEPLOY

### SQL (Run in Supabase)
1. `create-banner-schema.sql` - Creates banner tables
2. `add-generated-columns.sql` - Adds generated columns
3. `fix-store-selector-banner-id.sql` - Diagnostics (run first!)

### JavaScript (Swap files)
1. Replace `admin/enhanced-store-selector.js` with `admin/enhanced-store-selector-FIXED.js`
2. Replace `admin/brands-new.html` with updated version (uses banner_id)

## NEXT STEPS

1. Run diagnostic SQL first to verify schema
2. Run schema migrations
3. Swap JavaScript files
4. Test with pilot CSV
5. Report matched vs created counts

