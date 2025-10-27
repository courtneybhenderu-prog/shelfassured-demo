# Locked Decisions and Implementation Plan

## Locked Decisions

### UI Display
- **Store label**: Uses `stores.name` (from CSV STORE column)
- **Chain filtering**: Uses `stores.banner_id` (dropdown value = banner_id, label = banner_name)
- **Metro filtering**: Uses `stores.metro` (display) / `stores.metro_norm` (query)

### Normalization
- **Title case**: Display-only; matching is normalized (lowercase, hyphens unified, whitespace collapsed)
- **Address matching**: Case-insensitive, tolerant of abbreviations (Suite, Ste, Unit)

## Implementation Plan

### Step 1 - Diagnostics (RUN FIRST)
Run `step1-diagnostics-locked.sql` in Supabase SQL Editor and paste results.

This will show:
1. Current columns in stores table
2. Sample store rows with banner_id, metro, metro_norm
3. Banners available (will error if tables don't exist yet)
4. v_distinct_banners view output
5. Whether metro_norm column exists
6. Whether generated columns (zip5, state_zip) exist

### Step 2 - Schema Migrations (Apply if needed)
Run in order:

1. `create-banner-schema.sql` - Creates retailers, retailer_banners, retailer_banner_aliases; adds banner_id to stores
2. `add-metro-normalized.sql` - Adds metro_norm column for normalized matching (IF it doesn't exist)
3. `add-generated-columns.sql` - Adds generated columns zip5 and state_zip

### Step 3 - Swap JavaScript Files
1. Replace `admin/enhanced-store-selector.js` with `admin/enhanced-store-selector-FIXED.js`
2. Verify `admin/brands-new.html` uses:
   - `banner_id` (not retailer_id)
   - Writes `stores.name = STORE` (display name from CSV)
   - Upserts with conflict target: (banner_id, street_norm, city_norm, state, zip5)

### Step 4 - Pilot Test
Test with 10-row pilot CSV:
- Headers: retailer, name, address, city, state_zip (optional metro as 6th column)
- Report: row#, resolved banner_id, match rule, store id used/created

### Acceptance Criteria
✅ Selector shows multiple chains (not just Sprouts)
✅ Choosing a chain filters correctly
✅ Store list displays STORE values (title-cased names)
✅ Metro filter works using metro_norm
✅ No duplicates created (unique index enforces)

## Files Ready
- `step1-diagnostics-locked.sql` - Diagnostic queries
- `create-banner-schema.sql` - Banner tables + banner_id
- `add-metro-normalized.sql` - Metro normalization
- `add-generated-columns.sql` - Generated columns
- `admin/enhanced-store-selector-FIXED.js` - Fixed selector
- `admin/brands-new.html` - Updated importer

