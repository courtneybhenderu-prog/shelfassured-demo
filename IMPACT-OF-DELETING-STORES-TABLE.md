# Impact of Deleting Stores Table and Starting Fresh

## What Would Be Lost

### 1. **Existing Store IDs**
- All `stores.id` values would be lost
- Any foreign key relationships would break:
  - `job_store_skus.store_id` → Would become orphaned/invalid
  - `job_stores.store_id` → Would become orphaned/invalid
  - `job_submissions.store_id` → Would become orphaned/invalid
  - `brand_stores.store_id` → Would become orphaned/invalid
  - Any other tables referencing `stores.id`

### 2. **Existing STORE Display Names**
- All legacy `stores.STORE` values would be lost
- Would be replaced with new generated names: `{Banner} – {City} – {State} – {Disambiguator}`
- Historical continuity would be broken

### 3. **Existing Relationships**
- `brand_stores` junction table links would break
- `job_store_skus` relationships would break
- `job_submissions` would reference non-existent stores
- Any jobs currently assigned to stores would break

### 4. **Metadata**
- `created_at` timestamps would be lost
- `created_by` user references would be lost
- `banner_id` relationships (if any) would be lost
- Any custom fields or historical data would be lost

## What Would Need to Be Done

### 1. **Cascade Deletes or Manual Cleanup**
- Delete or update all foreign key references:
  - `job_store_skus` (delete rows or set store_id to NULL)
  - `job_stores` (delete rows or set store_id to NULL)
  - `job_submissions` (delete rows or set store_id to NULL)
  - `brand_stores` (delete rows or set store_id to NULL)

### 2. **Re-import All Data**
- Import fresh from Excel
- All stores get new UUIDs
- All stores get new generated display names

### 3. **Re-link Relationships (If Possible)**
- Would need to match old job_submissions to new stores (by address/ZIP)
- Would need to re-create brand_stores relationships
- Would need to re-create job_store_skus relationships
- **This would be very difficult without matching logic**

## Risks

### High Risk
- **Data Loss:** Historical relationships would be lost
- **Orphaned Records:** Jobs, submissions, brand relationships would break
- **No Rollback:** Once deleted, can't easily restore relationships

### Medium Risk
- **Re-linking Complexity:** Matching old references to new stores would require complex logic
- **Timeline Disruption:** Any active jobs would break

### Low Risk
- **Fresh Start:** Clean slate, no legacy data issues
- **Consistent Naming:** All stores would have new generated names

## Recommendation

**DO NOT DELETE** unless:
1. You're okay losing all historical relationships
2. You're okay with breaking all existing jobs/submissions
3. You have a plan to re-link critical data
4. You're in early development/testing phase

**Better Alternative:**
- Keep existing stores
- Mark unmatched stores as inactive
- Insert new stores
- Preserve all relationships and history

