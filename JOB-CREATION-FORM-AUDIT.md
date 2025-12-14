# Job Creation Form Audit Report

## Form Fields Identified

### Input Fields in HTML Form:
1. **job-title** (required) - Text input
2. **job-description** (optional) - Textarea
3. **brand-name** (required) - Text input with autocomplete
4. **Store Selection** (required) - Enhanced store selector (multiple selection)
5. **Products to Check** (required) - Product autocomplete + SKU input (multiple)
6. **assigned-user** (required) - Select dropdown
7. **priority** (optional) - Select dropdown (low, normal, high, urgent)
8. **due-date** (optional) - datetime-local input
9. **special-instructions** (optional) - Textarea

### Form Data Extraction (`getFormData()` function)
Returns:
- `title` → from `job-title`
- `description` → from `job-description`
- `brand` → from `brand-name` (brand name as text)
- `stores` → from enhanced store selector (array of store objects)
- `skus` → from `selectedSkus` array (array of {name, sku})
- `assignedUserId` → from `assigned-user`
- `priority` → from `priority`
- `dueDate` → from `due-date`
- `specialInstructions` → from `special-instructions`

## Database Save Operations

### CREATE Job (`createJobs()` function - lines 1350-1422)
Saves to `jobs` table:
```javascript
{
    title: formData.title,                      ✅
    description: formData.description,          ✅
    brand_id: brandId,                          ✅ (resolved from brand name)
    assigned_user_id: formData.assignedUserId,  ✅
    priority: formData.priority,                 ✅
    due_date: formData.dueDate || null,         ✅
    instructions: formData.specialInstructions, ✅ (mapped from specialInstructions)
    status: 'pending',                           ✅ (hardcoded)
    payout_per_store: 5.00,                     ✅ (hardcoded)
    created_at: new Date().toISOString()        ✅
}
```

Saves to `job_store_skus` table:
```javascript
{
    job_id: jobRow.id,
    store_id: storeId,
    sku_id: skuId
}
```

### UPDATE Job (`updateJob()` function - lines 1664-1706)
**⚠️ ISSUE FOUND:** The update function has field name mismatches:

```javascript
.update({
    title: formData.title,                      ✅
    description: formData.description,          ✅
    brand_id: formData.brandId,                 ❌ (formData doesn't have 'brandId')
    assigned_to: formData.assignedTo,           ❌ (formData has 'assignedUserId', DB column is 'assigned_user_id')
    priority: formData.priority,                 ✅
    due_date: formData.dueDate,                 ✅
    additional_notes: formData.additionalNotes, ❌ (formData has 'specialInstructions', DB column is 'instructions')
    updated_at: new Date().toISOString()        ✅
})
```

### LOAD Job for Edit (`loadJobForEdit()` function - lines 401-524)
Reads from database:
- `job.title` → `job-title` ✅
- `job.description` → `job-description` ✅
- `job.brands.name` → `brand-name` ✅
- `job.priority` → `priority` ✅
- `job.due_date` → `due-date` ✅ (converted to date format)
- `job.assigned_user_id` → `assigned-user` ✅
- `job.instructions` → `special-instructions` ✅

## Database Schema Check Needed

Run `audit-job-creation-form.sql` to verify:
1. All columns referenced in code actually exist
2. Data types match expectations
3. Foreign key constraints are correct

## Issues Found

### ✅ FIXED: Critical Issue #1: updateJob() Field Mismatches
**STATUS:** Fixed in code

The `updateJob()` function had incorrect field names:
- ~~Uses `formData.brandId`~~ → Now correctly uses `ensureBrandExists(formData.brand)` to get brandId
- ~~Uses `formData.assignedTo`~~ → Now correctly uses `formData.assignedUserId`
- ~~Uses `formData.additionalNotes`~~ → Now correctly uses `formData.specialInstructions`
- ~~Uses column name `assigned_to`~~ → Now correctly uses `assigned_user_id`
- ~~Uses column name `additional_notes`~~ → Now correctly uses `instructions`
- Added proper date conversion for `due_date` (datetime-local to ISO string)

### ✅ FIXED: Critical Issue #2: updateJob() Store/SKU Handling
**STATUS:** Fixed in code

The `updateJob()` function was using incorrect table structure:
- ~~Used separate `job_stores` and `job_skus` tables~~ → Now correctly uses unified `job_store_skus` table (matches create operation)
- ~~Incorrectly expected storeIds array~~ → Now correctly extracts store IDs from formData.stores array of objects
- ~~Incorrectly expected skuIds array~~ → Now correctly calls `ensureSkusExist()` to resolve SKU IDs from formData.skus
- Creates proper job_store_skus relationships (one per store-SKU combination)

### ⚠️ Potential Issue #3: Date/Time Format
- Form uses `datetime-local` but saves as ISO string
- ✅ Fixed: Added proper date conversion in updateJob()
- Need to verify `due_date` column accepts TIMESTAMP WITH TIME ZONE (run audit SQL)

### ⚠️ Potential Issue #3: Missing Fields Check
- `payout_per_store` is hardcoded to 5.00 - should verify if this should be editable
- `status` is hardcoded to 'pending' on create - verify if this is correct
- `created_by` column may exist but is not being set

## Recommended Actions

1. ✅ **Fix updateJob() function** - COMPLETED - aligned field names with form data and database columns
2. ✅ **Fix date conversion** - COMPLETED - added proper datetime-local to ISO string conversion in both create and update
3. ✅ **Fix store/SKU update logic** - COMPLETED - now uses job_store_skus table consistently
4. **Run audit-job-creation-form.sql** - verify actual database schema matches expectations
5. **Test create and update workflows** - ensure data flows correctly end-to-end
6. **Verify foreign key constraints** - ensure brand_id, assigned_user_id, etc. have proper FKs

## Summary

### ✅ Issues Fixed:
1. `updateJob()` field name mismatches - all corrected
2. Date conversion for `due_date` - added to both create and update
3. Store/SKU update logic - now uses `job_store_skus` table consistently
4. Null handling - added proper null coalescing for optional fields

### ⚠️ Remaining Verification Needed:
- Run `audit-job-creation-form.sql` to verify database schema
- Test end-to-end create and update workflows
- Verify foreign key constraints are properly set up

