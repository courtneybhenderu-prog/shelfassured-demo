# Store Search Troubleshooting - Request for Team Help

## 🎯 Goal

Create a store search that allows users to find stores by:
- **Banner name** (e.g., "Whole Foods Market")
- **City** (e.g., "Jackson")
- **State** (e.g., "Wyoming", "WY")
- **City + State combo** (e.g., "Jackson Wyoming", "Jackson, WY")
- **Store number** (e.g., "12345")
- **Address** (as a fallback, but should not interfere with state searches)

**Expected Behavior:**
- Searching "Wyoming" should find stores in Wyoming state
- Searching "Jackson Wyoming" should find stores in Jackson, Wyoming
- Searching "Wyoming" should NOT find stores on "Wyoming Blvd" in other states

---

## 🐛 Current Issues

### Issue 1: State searches matching street addresses
**Problem:** Searching "Wyoming" returns:
- ❌ Whole Foods in Albuquerque, NM on "Wyoming Blvd" (false positive)
- ❌ Whole Foods in Kentwood, MI (incorrect match)
- ❌ Missing: Whole Foods in Jackson, Wyoming (should appear but doesn't)

**Root Cause:** The search is matching "Wyoming" in the `address` field (Wyoming Blvd) instead of prioritizing the `state` field.

### Issue 2: Banner dropdown showing all stores
**Problem:** The "Filter by Chain" dropdown shows every single store (thousands of entries) instead of just unique banner names.

**Expected:** Should show ~20-30 banner names (H-E-B, Whole Foods Market, Albertsons, etc.)

---

## 🔧 What We've Tried

### Architecture Note
**Current Implementation:** Client-side JavaScript filtering (not SQL queries)
- Loads all stores into `this.allStores` array
- Filters client-side using JavaScript `.filter()` method
- File: `admin/enhanced-store-selector.js` (but WORKING.js shows the pattern)

### Attempt 1: Basic search with all fields
```javascript
// Client-side filtering - searches: name, city, address, zip_code, metro
baseStores = baseStores.filter(store => {
    const matches = store.name.toLowerCase().includes(this.searchTerm) ||
        store.city.toLowerCase().includes(this.searchTerm) ||
        store.address.toLowerCase().includes(this.searchTerm) ||
        store.zip_code.includes(this.searchTerm) ||
        (store.metro && store.metro.toLowerCase().includes(this.searchTerm));
    return matches;
});
```
**Result:** ❌ Matched "Wyoming" in addresses (Wyoming Blvd), causing false positives
**Missing:** `state` and `store_number` fields not included in search

### Attempt 2: Prioritize city/state in OR query order
```javascript
// Put city/state first in OR query
orQuery = `city.ilike.${pattern},state.ilike.${pattern},address.ilike.${pattern}...`;
```
**Result:** ❌ Still matched addresses because OR queries match ANY condition

### Attempt 3: Exclude address for state searches
```javascript
// Detect state searches and exclude address field
const stateNames = ['ohio', 'texas', 'wyoming', 'wy', ...];
if (isStateSearch) {
    orQuery = `state.ilike.${pattern}`; // Only state field
}
```
**Result:** ❌ Partial - still showing incorrect results, and missing actual Wyoming stores

### Attempt 4: Fix banner dropdown
```javascript
// Try to use retailer_banners table
const { data: banners } = await supabase
    .from('retailer_banners')
    .select('name');
// Fallback: Extract from STORE column (first part before " - ")
```
**Result:** ❌ Dropdown still showing all stores instead of just banners

---

## 🔍 Current Code Location

**File:** `admin/enhanced-store-selector.js` (currently uses Supabase queries)
**Alternative:** `admin/enhanced-store-selector-WORKING.js` (uses client-side JavaScript filtering)

**Current Implementation (enhanced-store-selector.js):**
- Uses Supabase server-side queries with `.or()` method
- `searchStores(term)` - Lines ~270-390 (builds Supabase query)
- `loadBannerOptions()` - Lines ~117-193

**Alternative Implementation (WORKING.js):**
- Loads all stores, then filters client-side with JavaScript `.filter()`
- `searchStores(term)` - Lines ~150-198 (JavaScript filtering)
- Pattern: `baseStores.filter(store => store.city.includes(term) || ...)`

**Question:** Should we use client-side JavaScript filtering (like WORKING.js) instead of Supabase queries?

---

## ❓ What We Need Help With

### Question 1: Database Schema
- Does the `retailer_banners` table exist and have data?
- What's the structure of the `stores` table? (columns: `state`, `city`, `address`, `STORE`, etc.)
- Is there a view like `v_distinct_banners` that we should use?

### Question 2: Search Implementation Approach
**Current approach:** Supabase server-side queries with `.or()` method

**Alternative approach:** Client-side JavaScript filtering (like WORKING.js)

**Decision needed:** Which approach should we use?

**Option A: Client-side JavaScript filtering (WORKING.js pattern)**
```javascript
// Load all stores first, then filter client-side
baseStores = baseStores.filter(store => {
    const matches = store.name.toLowerCase().includes(this.searchTerm) ||
        store.city.toLowerCase().includes(this.searchTerm) ||
        store.state.toLowerCase().includes(this.searchTerm) ||  // ✅ Add state
        store.address.toLowerCase().includes(this.searchTerm) ||  // ❌ Causes false positives
        store.store_number.includes(this.searchTerm);  // ✅ Add store_number
    return matches;
});
```
**Pros:** Simple, fast for small datasets, easy to debug  
**Cons:** Must load all stores first, slower for large datasets

**Option B: Supabase server-side queries (current)**
```javascript
// Filter at database level
pageQuery = pageQuery.or(`state.ilike.%${term}%,city.ilike.%${term}%,address.ilike.%${term}%...`);
```
**Pros:** Efficient for large datasets, only loads matching stores  
**Cons:** Harder to prioritize matches, OR queries match any condition

**Problem with both:** OR conditions match ANY field, so "Wyoming" matches:
- ✅ `state.includes('wyoming')` (correct)
- ❌ `address.includes('wyoming')` (false positive - Wyoming Blvd)

**Fix needed (either approach):**
1. **Priority-based filtering:** Check state first, only check address if no state match
2. **State detection:** If search term is a state name/abbreviation, ONLY match state field
3. **Post-filter results:** Get all matches, then remove address matches if state matches exist

### Question 3: State Detection
**Current approach:** Hardcoded list of state names/abbreviations.

**Problem:** 
- Incomplete list (might miss some states)
- Doesn't handle edge cases (e.g., "New York" vs "NY")

**Options:**
- Use a proper state detection library/function?
- Query the database to get valid state values?
- Use regex patterns?

### Question 4: Banner Dropdown
**Current approach:** 
1. Try `retailer_banners` table
2. Fallback: Extract from `stores.STORE` column (first part before " - ")

**Problem:** Still showing all stores instead of unique banners.

**Questions:**
- Does `retailer_banners` table exist?
- Should we use a different table/view?
- Is the STORE column format consistent? (e.g., "BANNER – CITY – STATE")
- Should we query `stores.banner` column instead?

### Question 5: Missing Results
**Problem:** Known store (Whole Foods in Jackson, Wyoming) not appearing in search results.

**Possible causes:**
- Store not in database?
- Store has `is_active = false`?
- Store's `state` field not set to "WY" or "Wyoming"?
- Search query not matching the store's data format?

**Need:** Query to verify store exists and check its data:
```sql
SELECT id, "STORE", city, state, address, is_active
FROM stores
WHERE LOWER("STORE") LIKE '%whole foods%'
  AND (LOWER(city) LIKE '%jackson%' OR LOWER(state) LIKE '%wyoming%' OR state = 'WY');
```

---

## 📋 Specific Test Cases

### Test Case 1: State Search
**Input:** "Wyoming"  
**Expected:** All stores in Wyoming state (WY)  
**Actual:** Stores on "Wyoming Blvd" in other states + missing actual Wyoming stores  
**Status:** ❌ Failing

### Test Case 2: City + State Search
**Input:** "Jackson Wyoming"  
**Expected:** Stores in Jackson, Wyoming  
**Actual:** Not tested yet (but likely failing based on state search)  
**Status:** ❓ Unknown

### Test Case 3: Banner Dropdown
**Expected:** ~20-30 unique banner names  
**Actual:** Thousands of individual store entries  
**Status:** ❌ Failing

---

## 🛠️ Suggested Next Steps

1. **Verify database state:**
   - Check if Whole Foods in Jackson, Wyoming exists in database
   - Verify `retailer_banners` table exists and has data
   - Check `stores` table structure and sample data

2. **Fix search query logic:**
   - Consider using separate queries with priority (state first, then others)
   - Or use PostgreSQL ranking/weights to prioritize state matches
   - Or post-filter results to remove address matches when state matches exist

3. **Fix banner dropdown:**
   - Verify `retailer_banners` table or find correct source
   - Or fix STORE column extraction logic
   - Or use `stores.banner` column if it exists

4. **Improve state detection:**
   - Use proper state detection (database query or library)
   - Handle all 50 states + DC + territories

---

## 📝 Files to Review

- `admin/enhanced-store-selector.js` - Main search logic
- `test-ohio-search.sql` - Test query for debugging
- Database schema files (if available)

---

## 🎯 Success Criteria

✅ Searching "Wyoming" finds stores in Wyoming state only  
✅ Searching "Jackson Wyoming" finds stores in Jackson, Wyoming  
✅ Banner dropdown shows only unique banner names (~20-30 options)  
✅ No false positives from street addresses (e.g., "Wyoming Blvd")  
✅ All known stores appear in search results when appropriate

---

**Status:** Blocked - Need team input on database schema and query approach

