# 🧭 MASTER REFERENCE — DO NOT MODIFY

**This document defines the correct implementation of the Job Creation page and Store Selector logic.**

**If the system breaks, re-align code to match this document exactly.**

---

# Job Creation & Store Selector Documentation

## Overview

This document provides a comprehensive guide to the job creation page (`admin/manage-jobs.html`) and the enhanced store selector component. It serves as a reference to prevent functionality drift and ensure consistent implementation.

**Last Updated:** January 13, 2025

---

## Quick Reference

### Critical Facts (Need to know immediately)

- **Total Stores:** 2,334 stores in database
- **Total Chains:** 72 unique chains (extracted from `STORE` column)
- **Display Name Source:** Always use `STORE` column (UPPERCASE, quoted identifier)
- **Chain Pattern:** `"BANNER - CITY"` (2,209 stores) OR `"BANNER"` standalone (125 stores)
- **Pagination Required:** Always paginate when loading > 1000 rows (Supabase default limit)

### Common Tasks

| Task | Quick Answer |
|------|--------------|
| **Display store name** | `store.STORE \|\| store.store \|\| store.name` |
| **Extract chain from STORE** | Split on `" - "`; if no dash, use whole value |
| **Filter by chain** | `query.ilike('STORE', '\${chain} - %')` |
| **Search metro-wide** | Search `metro`, `METRO`, `metro_norm` columns |
| **Get all stores** | Paginate: pages of 1000 until all fetched |
| **Get all chains** | Extract chains from all stores (paginated), then deduplicate |

### File Locations

- **Job Creation Page:** `admin/manage-jobs.html`
- **Store Selector Component:** `admin/enhanced-store-selector.js`
- **Supabase Client:** `shared/api.js`

### Data Patterns

| Pattern | Example | Extraction Result |
|---------|---------|-------------------|
| With dash | `"United Supermarkets - Andrews"` | Chain: `"United Supermarkets"` |
| No dash | `"BIG 8 FOODS"` | Chain: `"BIG 8 FOODS"` |

### Troubleshooting Quick Fixes

| Issue | Quick Fix |
|-------|-----------|
| Only 37 chains showing | Paginate when loading stores for chain extraction |
| Search returns only 1000 stores | Add pagination loop in `searchStores()` |
| Chain filter not working | Filter `STORE` column (not `store_chain` or `banner`) |
| Metro search too narrow | Include `metro`, `METRO`, `metro_norm` in search |

### ⚠️ Critical Rules

1. **Never use `store_chain` or `banner` for filtering** - they're legacy fields
2. **Always use `STORE` column** for display and chain extraction
3. **Always paginate** when loading all stores (2,334 total)
4. **Metro search** returns metro-wide results, not just city matches

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Store Data Structure](#store-data-structure)
3. [Store Selector Component](#store-selector-component)
4. [Chain/Banner System](#chainbanner-system)
5. [Search & Filtering](#search--filtering)
6. [Pagination Implementation](#pagination-implementation)
7. [Key Files & Dependencies](#key-files--dependencies)
8. [Database Schema](#database-schema)
9. [Important Conventions](#important-conventions)

---

## Architecture Overview

### Job Creation Page (`admin/manage-jobs.html`)

The job creation page allows admins to:
- Create new jobs for brand clients
- Select stores (multiple stores per job)
- Assign jobs to users
- Set job details (title, description, due date, etc.)

### Store Selector Component (`admin/enhanced-store-selector.js`)

A reusable JavaScript component that provides:
- Store search functionality (by name, address, city, ZIP, metro)
- Chain/banner filtering
- Location-based store suggestions
- Multi-select store capability
- Pagination to handle 2,000+ stores

---

## Store Data Structure

### Database Columns Used

| Column Name | Type | Purpose | Example Values |
|------------|------|---------|----------------|
| `id` | UUID | Primary key | `abc-123-def-456` |
| `name` | TEXT | Display name (legacy) | `Sprouts Farmers Market` |
| **`STORE`** | TEXT | **Primary display name** | `United Supermarkets - Andrews` |
| `address` | TEXT | Street address | `123 Main St` |
| `city` | TEXT | City name | `Austin` |
| `state` | TEXT | State code | `TX` |
| `zip_code` | TEXT | Full ZIP code | `78701-1234` |
| `metro` | TEXT | Metro area name | `Austin-Round Rock-Georgetown, TX MSA` |
| `METRO` | TEXT | Uppercase metro (legacy) | `AUSTIN-ROUND ROCK...` |
| `metro_norm` | TEXT | Normalized metro for search | `austin round rock georgetown tx msa` |
| `store_chain` | TEXT | Chain name (legacy) | `HEB`, `Kroger` |
| `banner` | TEXT | Banner name (legacy) | `Tom Thumb` |
| `zip5` | TEXT (generated) | First 5 digits of ZIP | `78701` |
| `state_zip` | TEXT (generated) | State + ZIP5 | `TX-78701` |

### Critical Data Pattern

**The `STORE` column contains the canonical store display name:**

- **With dash pattern:** `"BANNER - CITY"` 
  - Example: `"United Supermarkets - Andrews"`
  - Banner = `"United Supermarkets"`
  - City = `"Andrews"`
  
- **Without dash pattern:** `"BANNER"` (standalone)
  - Example: `"BIG 8 FOODS"`
  - Banner = `"BIG 8 FOODS"` (entire value)
  - No city suffix

**⚠️ IMPORTANT:** Always use `STORE` column for:
- Store display names in UI
- Chain/banner extraction
- User-facing labels

**Never use:** `name`, `store_chain`, or `banner` for display (these are legacy fields).

---

## Store Selector Component

### Initialization

```javascript
// Component initializes on page load
const storeSelector = new EnhancedStoreSelector('store-search-input', {
    onStoreSelected: (store) => { /* callback */ },
    onStoreRemoved: (store) => { /* callback */ }
});
```

### Key Methods

#### `loadBannerOptions()`
- **Purpose:** Load all chain/banner options for the dropdown
- **Process:**
  1. Paginates through ALL stores (not limited to 1000)
  2. Extracts chain name from `STORE` column
  3. Deduplicates to get unique chains
  4. Populates dropdown with chain options
- **Expected Result:** 72 unique chains + "All Chains" option = 73 total

#### `searchStores(term)`
- **Purpose:** Search stores by name, address, city, ZIP, or metro
- **Features:**
  - Case-insensitive search
  - Searches across multiple columns (STORE, name, city, address, zip_code, metro, METRO, metro_norm)
  - Supports metro-wide search (searching "Austin" returns all stores in Austin metro)
  - Uses pagination to return ALL matching stores (not limited to 2000)
- **Pagination:** Fetches in pages of 1000 until all results retrieved

#### `filterByChainQuery(query, selectedChain)`
- **Purpose:** Apply chain filter to Supabase query
- **Logic:**
  - If "all" or empty: return query unchanged
  - If specific chain: filter `STORE` column using `ilike('STORE', '${chain} - %')`
  - Matches stores where `STORE` starts with chain name followed by " - "

#### `getDisplayName(store)`
- **Purpose:** Get human-readable store name
- **Priority:** `store.STORE || store.store || store.name || 'Unknown Store'`
- **Always shows:** The exact value from `STORE` column (not derived/transformed)

---

## Chain/Banner System

### Chain Extraction Logic

```javascript
const extractChain = (storeName) => {
    if (!storeName) return null;
    const trimmed = storeName.trim();
    const dashIndex = trimmed.indexOf(' - ');
    
    if (dashIndex > 0) {
        // Pattern: "BANNER - CITY"
        return trimmed.substring(0, dashIndex).trim();
    }
    
    // Pattern: "BANNER" (no dash)
    return trimmed;
};
```

### Chain Count

- **Total Banners:** 72 unique chains
- **Total Stores:** 2,334 stores
- **Distribution:**
  - 2,209 stores follow "BANNER - CITY" pattern
  - 125 stores are standalone banners (no " - " in STORE column)

### Chain Examples

| Store STORE Value | Extracted Chain |
|-------------------|----------------|
| `United Supermarkets - Andrews` | `United Supermarkets` |
| `H-E-B - Houston 51` | `H-E-B` |
| `99 RANCH MARKET - AUSTIN` | `99 RANCH MARKET` |
| `BIG 8 FOODS` | `BIG 8 FOODS` |
| `TRADER JOE'S - DALLAS` | `TRADER JOE'S` |

### Chain Dropdown

- **Source:** Extracted from `STORE` column (paginated across all stores)
- **Format:** `[{value: 'chain_name', label: 'chain_name'}, ...]`
- **First Option:** `{value: 'all', label: 'All Chains'}`
- **Display:** Shows chain names exactly as extracted (case preserved)

---

## Search & Filtering

### Search Fields

The search function searches across these columns:
- `STORE` (primary display name)
- `name` (legacy fallback)
- `city`
- `address`
- `zip_code`
- `metro` (metro area name)
- `METRO` (uppercase metro)
- `metro_norm` (normalized metro for fuzzy matching)

### Search Examples

| Search Term | Returns | Logic |
|------------|---------|-------|
| `Austin` | All stores in Austin metro | Searches `metro`, `METRO`, `metro_norm` |
| `78701` | Stores with ZIP containing "78701" | Searches `zip_code` |
| `HEB` | All H-E-B stores | Searches `STORE`, `name` |
| `480 Northwest Pkwy` | Store at that address | Searches `address` |

### Filtering Flow

1. **User types search term** → `searchStores(term)` called
2. **Build query** with:
   - Base: All stores where `STORE IS NOT NULL AND STORE != ''`
   - Search: `.or()` across all searchable columns
   - Chain: `.ilike('STORE', '${chain} - %')` if chain selected
3. **Paginate results** (1000 per page until all fetched)
4. **Display all matches** with count

### Metro Search

**Key Feature:** Searching by city name returns stores in the entire metro area, not just stores with that city in their address.

Example:
- Searching "Houston" returns all 449 stores in the "Houston-Sugar Land-Baytown, TX MSA" metro
- Not just stores with "Houston" in the `city` column

---

## Pagination Implementation

### Why Pagination?

Supabase defaults to 1000-row limit per query. To get all 2,334 stores, we must paginate.

### Pagination Pattern

```javascript
let allResults = [];
let from = 0;
const pageSize = 1000;
let hasMore = true;

while (hasMore) {
    const { data: pageData } = await query.range(from, from + pageSize - 1);
    
    if (pageData && pageData.length > 0) {
        allResults = allResults.concat(pageData);
        from += pageSize;
        hasMore = pageData.length === pageSize; // Full page = might be more
    } else {
        hasMore = false;
    }
}
```

### Where Pagination is Used

1. **`loadBannerOptions()`**
   - Paginates through all stores to extract unique chains
   - Ensures all 72 chains are found (not just first 37)

2. **`searchStores()`**
   - Paginates search results to get ALL matches
   - Previously capped at 2000; now returns complete result set

3. **`loadStoresFromDatabase()`**
   - Paginates when loading stores for initial display
   - Uses same pattern as above

### Pagination Verification

Check console logs for:
- `📄 Loaded page X, total so far: Y stores`
- `✅ Search returned X stores (paginated)`
- `📊 Total stores loaded: 2334` (or matching your total)

---

## Key Files & Dependencies

### Core Files

| File | Purpose | Key Features |
|------|---------|--------------|
| `admin/manage-jobs.html` | Job creation page UI | Form inputs, brand autocomplete, store selector integration |
| `admin/enhanced-store-selector.js` | Store selector component | Search, filter, pagination, location services |
| `shared/api.js` | Supabase client initialization | Provides `supabase` global object |

### File Structure

```
admin/
  ├── manage-jobs.html          # Main job creation page
  ├── enhanced-store-selector.js # Store selector component (752 lines)
  └── ...

shared/
  ├── api.js                    # Supabase config & client
  └── styles.css                # Shared styles
```

### External Dependencies

- **Supabase JS Client:** Database queries, authentication
- **No jQuery:** Vanilla JavaScript only
- **Tailwind CSS:** Styling (via `shared/styles.css`)

---

## Database Schema

### Stores Table

```sql
CREATE TABLE stores (
    id UUID PRIMARY KEY,
    name TEXT,                    -- Legacy display name
    STORE TEXT,                   -- PRIMARY display name (UPPERCASE column name)
    address TEXT,
    city TEXT,
    state TEXT,
    zip_code TEXT,
    metro TEXT,                   -- Metro area name
    METRO TEXT,                   -- Uppercase metro (legacy)
    metro_norm TEXT,              -- Normalized metro for search
    store_chain TEXT,             -- Legacy chain field
    banner TEXT,                   -- Legacy banner field
    zip5 TEXT GENERATED ALWAYS AS (LEFT(zip_code, 5)) STORED,
    state_zip TEXT GENERATED ALWAYS AS (state || '-' || zip5) STORED,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

### Important Constraints

- **Unique Index:** `(banner_id, street_norm, city_norm, state, zip5)` (prevents duplicates)
- **Required:** `STORE IS NOT NULL AND STORE != ''` for all displayed stores

### Data Distribution

- **Total Stores:** 2,334
- **Stores with dash pattern:** 2,209 (`"BANNER - CITY"`)
- **Stores without dash:** 125 (standalone banners)
- **Unique Chains:** 72 (extracted from STORE column)

---

## Important Conventions

### Column Name Casing

⚠️ **CRITICAL:** PostgreSQL is case-sensitive for quoted identifiers.

- `STORE` (uppercase, quoted) = Actual column name in database
- `store` (lowercase) = May not exist; use only as fallback
- Always reference: `store.STORE || store.store || store.name`

### Display Name Priority

```javascript
// CORRECT:
store.STORE || store.store || store.name || 'Unknown Store'

// WRONG:
store.name  // Legacy field, inconsistent data
store.store_chain  // Not the display name
```

### Chain Filtering

**Always filter by STORE column, not store_chain or banner:**

```javascript
// CORRECT:
query.ilike('STORE', `${chain} - %`)

// WRONG:
query.eq('store_chain', chain)  // Legacy field, inconsistent
```

### Search Query Pattern

```javascript
// Search across multiple columns with OR logic
query.or(`STORE.ilike.%${term}%,name.ilike.%${term}%,city.ilike.%${term}%,address.ilike.%${term}%,zip_code.ilike.%${term}%,metro.ilike.%${term}%,METRO.ilike.%${term}%,metro_norm.ilike.%${term}%`)
```

### Pagination Always Required

**Never assume Supabase will return all rows.** Always paginate if:
- Loading all stores (2,334 total)
- Loading all chains (need all stores to extract chains)
- Search results might exceed 1000 matches

### Metro Search

Metro search is a **key feature**:
- User searches "Austin" → returns all Austin metro stores (not just city="Austin")
- Searches `metro`, `METRO`, and `metro_norm` columns
- Critical for metro-wide job assignments

---

## Troubleshooting

### Issue: Only 37 chains showing in dropdown

**Cause:** Not paginating when loading stores for chain extraction.

**Fix:** Ensure `loadBannerOptions()` paginates through ALL stores (not just first 1000).

### Issue: Search returns only 1000 stores

**Cause:** Not paginating search results.

**Fix:** Ensure `searchStores()` uses pagination loop (not `.limit(2000)`).

### Issue: Stores not matching chain filter

**Cause:** Filtering wrong column or wrong pattern.

**Fix:** 
- Filter `STORE` column (not `store_chain`)
- Use pattern: `ilike('STORE', '${chain} - %')`
- Confirm chain value matches extracted chain name exactly

### Issue: "Available Stores (1000)" shows incorrect count

**Cause:** `updateCounts()` not called after paginated search, or search not paginated.

**Fix:** Ensure `searchStores()` calls `updateCounts()` after setting `this.filteredStores`.

### Issue: Metro search not working (Houston only returns 37 stores)

**Cause:** Not searching `metro`, `METRO`, `metro_norm` columns, or only searching `city`.

**Fix:** Include all metro columns in search `.or()` clause.

---

## Testing Checklist

### Chain Dropdown
- [ ] Dropdown shows "All Chains" as first option
- [ ] All 72 chains are listed (check console: "Found 72 unique chains")
- [ ] Chains are sorted alphabetically
- [ ] Selecting a chain filters stores correctly

### Search Functionality
- [ ] Search by city (e.g., "Austin") returns metro-wide results
- [ ] Search by ZIP code works
- [ ] Search by address works
- [ ] Search by store name works
- [ ] Search shows correct count in "Available Stores (X)"

### Pagination
- [ ] Console shows: "Loaded page 1, total so far: 1000"
- [ ] Console shows: "Loaded page 2, total so far: 2000"
- [ ] Console shows: "Loaded page 3, total so far: 2334" (or total)
- [ ] Search returns all matching stores (not capped at 1000)

### Store Display
- [ ] Store names show `STORE` column value (e.g., "United Supermarkets - Andrews")
- [ ] Address is formatted correctly
- [ ] Selected stores show in selected list
- [ ] Count updates when stores selected/deselected

---

## Code Snippets Reference

### Correct Chain Extraction

```javascript
const extractChain = (storeName) => {
    if (!storeName) return null;
    const trimmed = storeName.trim();
    const dashIndex = trimmed.indexOf(' - ');
    if (dashIndex > 0) {
        return trimmed.substring(0, dashIndex).trim();
    }
    return trimmed;
};
```

### Correct Display Name

```javascript
getDisplayName(store) {
    return store.STORE || store.store || store.name || 'Unknown Store';
}
```

### Correct Pagination Pattern

```javascript
let allResults = [];
let from = 0;
const pageSize = 1000;
let hasMore = true;

while (hasMore) {
    const { data: pageData } = await query.range(from, from + pageSize - 1);
    if (pageData && pageData.length > 0) {
        allResults = allResults.concat(pageData);
        from += pageSize;
        hasMore = pageData.length === pageSize;
    } else {
        hasMore = false;
    }
}
```

### Correct Chain Filtering

```javascript
filterByChainQuery(query, selectedChain) {
    if (selectedChain && selectedChain !== 'all' && selectedChain !== 'All Chains') {
        return query.ilike('STORE', `${selectedChain} - %`);
    }
    return query;
}
```

---

## Version History

- **2025-01-13:** Initial documentation created
  - Documented store selector functionality
  - Documented chain extraction logic
  - Documented pagination implementation
  - Added troubleshooting guide

---

## Contact

If you encounter issues or need clarification on any section, refer to:
- Console logs (check for error messages and pagination logs)
- Database schema (verify column names and data patterns)
- This documentation (verify conventions are followed)

**Remember:** The `STORE` column is the source of truth for display names and chain extraction. Always prioritize it over legacy fields.
