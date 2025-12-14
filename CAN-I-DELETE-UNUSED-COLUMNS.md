# Can I Delete Unused Columns from Stores Table?

## ⚠️ **SHORT ANSWER: NOT RECOMMENDED**

## Columns You Want to Keep (15 - Used by App)
- `id`, `STORE`, `name`, `address`, `city`, `state`, `zip_code`, `metro`, `METRO`, `metro_norm`, `is_active`, `banner`, `store_chain`, `created_at`, `updated_at`

## Columns You're Considering Deleting
- `banner_norm`, `address_norm`, `city_norm`, `state_norm`, `zip5_norm` - Normalization columns
- `match_key` - Composite matching key
- `store_number` - Store number from import
- `zip5` - Generated column (5-digit ZIP)
- `state_zip` - Generated column (state-zip combo)

## ⚠️ **RISKS OF DELETING:**

### 1. **Generated Columns (`zip5`, `state_zip`)**
- These are **computed columns** - they don't store data, just calculate it
- **No storage cost** - they're free
- **Useful for queries** - even if app doesn't use them directly
- **Safe to keep** - no downside

### 2. **Reconciliation Columns (`*_norm`, `match_key`)**
- **Future imports** - If you ever need to reconcile stores again, you'll need these
- **Data integrity** - They help ensure consistent matching
- **Low storage cost** - Text columns are relatively small
- **If deleted** - You'd need to recreate them for any future reconciliation

### 3. **Store Number (`store_number`)**
- **Useful metadata** - Store numbers can be valuable for reporting
- **Low storage cost** - Small text field
- **Future use** - Might be needed for integrations or reporting

## ✅ **RECOMMENDATION:**

### **DO NOT DELETE** - Keep all columns because:

1. **Generated columns are free** - `zip5` and `state_zip` cost nothing
2. **Reconciliation columns are small** - Text normalization columns are minimal storage
3. **Future-proofing** - You may need reconciliation again
4. **No performance impact** - Unused columns don't slow down queries
5. **Data preservation** - `store_number` might be useful later

### **If you MUST delete** (not recommended):

**Only consider deleting if:**
- You're 100% certain you'll never reconcile stores again
- You're running out of storage (unlikely for text columns)
- You have a specific requirement to minimize columns

**Safe to delete (if you must):**
- `banner_norm`, `address_norm`, `city_norm`, `state_norm`, `zip5_norm` - Only if you'll never reconcile again
- `match_key` - Only if you'll never reconcile again
- `store_number` - Only if you don't need store numbers

**DO NOT DELETE:**
- `zip5` - Generated column, useful, costs nothing
- `state_zip` - Generated column, useful, costs nothing

## 🔍 **BEFORE DELETING - Run This:**

1. Run `check-stores-column-dependencies.sql` to check for:
   - Indexes that might reference these columns
   - Foreign keys or constraints
   - Views that use these columns

2. **Backup first** - Always backup before schema changes

3. **Test in dev** - Test deletion in a development environment first

## 💡 **ALTERNATIVE APPROACH:**

Instead of deleting, consider:
- **Document which columns are "internal"** - Mark them as reconciliation-only
- **Add comments to columns** - Use `COMMENT ON COLUMN` to document purpose
- **Monitor usage** - Track if any queries start using these columns

## 📊 **Storage Impact:**

Text columns are typically small:
- `*_norm` columns: ~50-200 bytes each
- `match_key`: ~100-300 bytes
- `store_number`: ~10-50 bytes
- **Total**: ~500-1000 bytes per row (negligible)

For 5,000 stores: ~2.5-5 MB total (very small)

## ✅ **FINAL RECOMMENDATION:**

**Keep all columns.** The storage cost is negligible, and the risk of needing them later is high. Only delete if you have a specific, compelling reason.

