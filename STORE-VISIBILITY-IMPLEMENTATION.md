# Store Visibility Implementation - Role-Based Access

## Overview
This document describes the role-based store visibility implementation to protect store data while allowing appropriate access for different user roles.

## Roles and Permissions

### 1. Admin
- **Can see:** All stores in the database (nationwide)
- **Can do:** 
  - Search stores by name, city, metro, state
  - View all stores for debugging and data maintenance
  - Load full store lists
  - Filter by chain without search requirement
- **Restrictions:** None

### 2. Brand Client
- **Can see:** Only stores they search for
- **Can do:**
  - Search stores (search-first pattern required)
  - Attach any store to their brand via `brand_stores`
  - Filter by chain only after searching
- **Restrictions:**
  - Must enter search term before seeing any stores
  - Cannot load full store lists
  - Cannot see "download all stores" or "show all stores"
  - Banner/chain dropdown only populated from search results

### 3. Shelfer
- **Can see:** Stores only via jobs (in job cards)
- **Can do:** View store name and address in job details
- **Restrictions:**
  - No store search
  - No store browser
  - No general store list access

## Implementation Details

### Files Modified

#### 1. `admin/enhanced-store-selector.js`
**Changes:**
- Added `getUserRole()`, `isAdmin()`, `isBrand()` methods for role checking
- Modified `loadStores()` to check role and set appropriate behavior
- Modified `searchStores()` to require search term for brands
- Modified `loadStoresFromDatabase()` to be admin-only
- Modified `filterByChain()` to require search for brands
- Modified `loadBannerOptions()` to be admin-only
- Added `updateBannerOptionsFromResults()` for brands to get chains from search results

**Key Logic:**
```javascript
// Brands must search first
if (isBrand && !trimmedTerm) {
    showError('Please enter a search term...');
    return;
}

// Only admins can load all stores
if (!isAdmin) {
    showError('Full store lists are only available to administrators.');
    return;
}
```

#### 2. `shared/api.js`
**Changes:**
- Disabled `saGet('stores')` function that was loading all stores (5000 limit)
- Added warning message to prevent accidental use
- Returns fallback instead of full store list

**Rationale:** This prevents any code from accidentally loading all stores via the generic `saGet()` function.

### Pages Using Store Selector

#### Admin Pages (Full Access)
- `admin/manage-jobs.html` - Can load all stores, filter freely
- Uses `enhanced-store-selector.js` with admin privileges

#### Brand Pages (Search-First)
- `dashboard/create-job.html` - Must search before seeing stores
- `pages/create-job.js` - Uses enhanced store selector with brand restrictions
- Brand onboarding pages (`admin/brands-new.html`, `brand-onboarding.html`) - Use manual entry, not store browser

#### Shelfer Pages (No Store Browser)
- `dashboard/shelfer.html` - Only sees stores via jobs
- `pages/shelfer-dashboard.js` - Loads jobs with store info, no store browser

## Data Protection Measures

### 1. No Full Store Dumps
- Removed `saGet('stores')` that loaded 5000 stores
- Brands cannot call `loadStoresFromDatabase()` directly
- All store queries for brands require a search term

### 2. Search-First Pattern
- Brands must type something (e.g., "Whole Foods Austin") before seeing matches
- Empty search returns no results for brands
- Search term is validated before query execution

### 3. Chain Filtering
- Admins: Can filter by chain without search
- Brands: Can only filter by chain after searching (chains extracted from search results)

### 4. Banner Options
- Admins: Load all chains from all stores
- Brands: Only see chains from their search results

## Testing Checklist

### Admin Access
- [ ] Can load all stores without search
- [ ] Can filter by chain without search
- [ ] Can see all banner options in dropdown
- [ ] Can search stores freely
- [ ] Can view stores nationwide

### Brand Access
- [ ] Cannot see stores without searching
- [ ] Search with empty term shows error
- [ ] Search with term shows matching stores
- [ ] Can filter by chain only after searching
- [ ] Banner dropdown only shows chains from search results
- [ ] Cannot load full store list
- [ ] Can attach any store to brand (via search)

### Shelfer Access
- [ ] No store browser/search available
- [ ] Only sees stores in job cards
- [ ] Cannot access store selection UI

## Rollout Markets vs Data Collection

### Data Collection (Current)
- Brands can attach stores from any market to their brand
- All Whole Foods locations in database (nationwide)
- No geographic restrictions on `brand_stores` relationships

### Operational Rollout (Future)
- Jobs only created in Houston and Austin for now
- Shelfer job visibility limited to active markets
- Can add "live markets" configuration later to control where jobs are visible

## Security Notes

### Current Implementation
- **Application-layer enforcement** (not RLS yet)
- Role checking happens in JavaScript
- Queries are role-aware but not database-enforced

### Future Considerations
- Can add RLS policies later for database-level enforcement
- Consider API endpoint restrictions
- Monitor for any code that bypasses role checks

## Migration Notes

### Breaking Changes
- `saGet('stores')` no longer returns stores (returns fallback)
- Brands using store selector must now search first
- Any code expecting full store list via `saGet('stores')` will break

### Backward Compatibility
- Admin pages continue to work as before
- Brand pages need search term (UI should guide users)
- Shelfer pages unaffected (never had store browser)

## Files to Review

### Store Query Locations
1. `admin/enhanced-store-selector.js` - ✅ Fixed
2. `shared/api.js` - ✅ Fixed
3. `admin/brands-new.html` - ✅ Uses manual entry (safe)
4. `brand-onboarding.html` - ✅ Uses manual entry (safe)
5. `pages/create-job.js` - ✅ Uses enhanced selector (fixed)
6. `dashboard/create-job.html` - ✅ Uses enhanced selector (fixed)
7. `pages/shelfer-dashboard.js` - ✅ Only loads stores via jobs (safe)

### No Changes Needed
- Shelfer dashboard - Already only shows stores via jobs
- Brand onboarding - Uses manual store entry, not browser
- Job details pages - Only show store info, not browser

## Summary

✅ **Admin:** Full access to all stores
✅ **Brand:** Search-first pattern enforced
✅ **Shelfer:** No store browser, only sees stores via jobs
✅ **Data Protection:** No full store dumps to non-admins
✅ **Application Layer:** Role-based logic implemented

---

**Last Updated:** After implementing role-based store visibility
**Status:** Implementation complete, ready for testing


