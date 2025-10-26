# Error Log: Brand Onboarding Issues

**Date:** January 13, 2025  
**Issue:** Brand onboarding failing with multiple schema errors

## Errors Encountered

### 1. RLS Policy Error (Fixed)
**Error:** `new row violates row-level security policy for table "brands"`  
**Status:** ✅ FIXED  
**Solution:** Created `fix-brands-rls.sql` with:
- Authenticated user INSERT/UPDATE/SELECT policies for brands
- SECURITY DEFINER on upsert_brand_public RPC function
- Grant execute permissions

### 2. Missing state_zip Column (Partially Fixed)
**Error:** `Could not find the 'state_zip' column of 'stores' in the schema cache`  
**Status:** ⚠️ PARTIALLY FIXED  
**Solution Attempt:** Updated `admin/brands-new.html` to use `state` and `zip_code` instead of `state_zip`  
**Issue:** Schema cache not reloaded - PostgREST still has old schema cached  
**Fix Applied:** Created `reload-schema.sql` with `NOTIFY pgrst, 'reload schema';`  
**User Action Needed:** Run reload command in Supabase SQL Editor

### 3. Missing status Column (Current Error)
**Error:** `Could not find the 'status' column of 'stores' in the schema cache`  
**Status:** ❌ NOT YET FIXED  
**Issue:** 
- Code tries to insert `status: 'unverified'` into stores table
- Your stores table doesn't have a `status` column
- Schema mismatch between code expectations and actual database

### 4. Duplicate Brands (New Issue)
**Problem:** "Evive" brand appears 3 times in brands table  
**Status:** ⚠️ NEEDS RESOLUTION  
**Issue:** 
- No unique constraint on brand names
- Multiple successful brand creations created duplicates
- upsert_brand_public RPC should prevent this but it doesn't check uniqueness

## Schema Mismatch Analysis

**Your Actual stores Table Has:**
- id, name, address, city, state, zip_code
- store_chain, created_at, updated_at, is_active
- retailer_id, street_norm, city_norm, state, zip5 (from migration)

**Your stores Table Does NOT Have:**
- ❌ `state_zip` column
- ❌ `status` column

**Code Expects:**
- `state_zip` OR separate `state` + `zip_code`
- `status` column with 'unverified' value
- These columns don't exist in your schema

## Attempted Fixes

### Fix 1: Update Payload to Match Schema
Changed from:
```javascript
state_zip: s.state_zip  // ❌ Doesn't exist
```

To:
```javascript
state: state || (s.state_zip?.split(' ')[0] || null),
zip_code: s.state_zip || zip5,
```

### Fix 2: Remove status Column
Code still tries to insert `status: 'unverified'` which doesn't exist.

### Fix 3: Schema Reload
Created reload command but needs to be executed by user in Supabase.

## What I've Done

1. ✅ Fixed RLS policies for brands table
2. ✅ Updated retailer normalization to use retailer_aliases
3. ✅ Added deduplication logic in migration
4. ✅ Updated store payload to use correct column names
5. ⚠️ Created schema reload command (not executed yet)
6. ❌ Still trying to insert `status` column that doesn't exist

## Files Modified

- `fix-retailer-normalization.sql` - Added retailers/aliases tables + deduplication
- `fix-brands-rls.sql` - Added RLS policies for brands
- `admin/brands-new.html` - Updated store insertion logic
- `admin/manage-jobs.html` - Fixed brand autocomplete dropdown

## Immediate Action Needed

**Issue:** Code tries to insert columns that don't exist in stores table

**Need to:** 
1. Either ADD `status` column to stores table
2. OR REMOVE `status` from the code payload
3. Either ADD `state_zip` column  
4. OR KEEP using separate `state` + `zip_code` (current approach)

**Question:** Which approach do you want?
- Option A: Add missing columns to stores table (status, state_zip)
- Option B: Remove these from the code

