# Store Selector Fix Plan

## Problem Summary
The store selector was filtering on `store_chain` but populating dropdown from `v_distinct_banners`, causing mismatches. The system should use `banner_id` for both dropdown and filtering.

## Required Steps

### Step 1: Run Diagnostics (FIRST - DO NOT SKIP)
In Supabase SQL Editor, run `fix-store-selector-banner-id.sql` and paste the results.

This will show:
- Current stores table schema
- Sample stores with their banner_id, store_chain values
- Whether retailer_banners table exists
- What v_distinct_banners currently returns
- Any mismatches

### Step 2: Create Banner Schema (if needed)
Run `create-banner-schema.sql` in Supabase SQL Editor.

This creates:
- `retailer_banners` table
- `retailer_banner_aliases` table
- Populates with H-E-B, Kroger, Sprouts
- Adds `banner_id` column to stores
- Updates `v_distinct_banners` to return banner_id and banner_name
- Creates unique index on (banner_id, street_norm, city_norm, state, zip5)

### Step 3: Swap JavaScript File
Replace `admin/enhanced-store-selector.js` with `admin/enhanced-store-selector-FIXED.js`.

The fixed version:
- Loads dropdown with banner_id values (UUID)
- Filters by banner_id instead of store_chain string matching
- Properly matches dropdown selection to store filtering

### Step 4: Test
1. Refresh admin/manage-jobs.html
2. Search for "Bridgeland" - should show H-E-B Bridgeland
3. Filter by any chain - should show all chains, not just Sprouts

## Files Created
- `stores-diagnostic-queries.sql` - Diagnostic queries
- `fix-store-selector-banner-id.sql` - Modified diagnostic queries with correct table names
- `create-banner-schema.sql` - Creates banner tables and updates view
- `admin/enhanced-store-selector-FIXED.js` - Fixed selector code

## DO NOT RUN ANYTHING YET
Wait for diagnostic results from Step 1.
