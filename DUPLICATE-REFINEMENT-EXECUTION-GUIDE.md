# Duplicate Store Refinement - Execution Guide

## Overview
This process refines duplicate `STORE` values in two steps:
1. **Merge true duplicates** (same physical location, different records)
2. **Refine disambiguators** (fix truncated names like "N JO" → "N JOSEY")

## Execution Order

### Step 1: Identify True Duplicates
**File:** `identify-true-duplicate-stores.sql`

Run this first to see all suspected true duplicates grouped by normalized match key (banner + city + state + normalized street address).

**What it shows:**
- Duplicate groups with same physical location
- Proposed survivor (most complete data)
- Stores that would be merged

---

### Step 2: Review Merge Plan (DRY RUN)
**File:** `merge-true-duplicate-stores-dry-run.sql`

**⚠️ IMPORTANT: Run this before executing the merge!**

This shows:
- How many duplicate groups will be merged
- How many stores will be marked inactive
- Expected store count after merge
- Detailed merge plan for each group

**Review the output carefully before proceeding.**

---

### Step 3: Execute True Duplicate Merge
**File:** `merge-true-duplicate-stores-execute.sql`

**⚠️ WARNING: This will mark duplicate stores as `is_active = FALSE`**

Only run this after reviewing the dry-run output and confirming the merge plan is correct.

**What it does:**
- Marks duplicate stores (not the survivor) as inactive
- Preserves the store with most complete data (store_number, phone, zip, metro)
- Uses a transaction (can be rolled back if needed)

**After running:**
- Check the summary output
- Verify inactive stores count matches dry-run expectations

---

### Step 4: Refine Disambiguators for Remaining Duplicates
**File:** `refine-disambiguator-remaining-duplicates.sql`

**Run this only after Step 3 is complete.**

This script:
1. Identifies remaining duplicate `STORE` groups (after true duplicates merged)
2. Refines disambiguators by extracting 2-3 meaningful tokens from addresses
3. Handles special cases:
   - `N JO` → `N JOSEY`
   - `S CO` → `S CONGRESS`
   - `W SL` → `W SLAUGHTER`
   - `HWY` → `HWY 6`
   - `N LA` → `N LAMAR`
   - `N HA` → `N HALSTED`
   - `N FR` → `N FRY`

**What it does:**
- Only updates stores still in duplicate groups
- Preserves base name (Banner – City – State)
- Replaces truncated disambiguator with 2-3 meaningful tokens

---

### Step 5: Final Duplicate Report
**File:** `final-duplicate-report.sql`

Run this to see the final state after all refinements.

**What it shows:**
- Total unique store names
- Remaining duplicate groups (if any)
- Detailed list of all remaining duplicates
- Uniqueness status

**Expected result:**
- Most duplicates should be resolved
- Remaining duplicates should be legitimate (different stores with same name)

---

## Quick Reference

```sql
-- 1. See true duplicates
\i identify-true-duplicate-stores.sql

-- 2. Review merge plan (DRY RUN)
\i merge-true-duplicate-stores-dry-run.sql

-- 3. Execute merge (after review)
\i merge-true-duplicate-stores-execute.sql

-- 4. Refine disambiguators
\i refine-disambiguator-remaining-duplicates.sql

-- 5. Final report
\i final-duplicate-report.sql
```

## Notes

- **True duplicates** are identified by normalized match key (banner + city + state + normalized address)
- **Normalized address** strips suite/unit/building numbers and punctuation
- **Survivor selection** prioritizes stores with most complete data (store_number, phone, zip, metro)
- **Disambiguator refinement** only applies to stores still in duplicate groups after merge
- **Preservation rule**: Once `STORE` is set (non-null, non-empty, non-placeholder), it won't be modified except for this refinement pass

## Safety

- All scripts use transactions where appropriate
- Dry-run scripts available for review
- No data deletion (only marking as inactive)
- Can rollback if needed

