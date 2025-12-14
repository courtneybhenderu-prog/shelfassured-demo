# Stores Table Columns Used in Application

## Summary

Based on codebase analysis, here are the columns from the `stores` table that are actively used or referenced in the application:

## Primary Columns (Used in SELECT queries)

### Core Identity & Display
- **`id`** - Primary key, used in all queries for joins and references
- **`STORE`** - Primary display name (uppercase column name, critical for display)
- **`name`** - Fallback display name (legacy field)

### Location Data
- **`address`** - Used for search and display
- **`city`** - Used for search, filtering, and display
- **`state`** - Used for search, filtering, and display
- **`zip_code`** - Used for search and display

### Metro/Area Data
- **`metro`** - Used for search (lowercase)
- **`METRO`** - Used for search (uppercase, legacy)
- **`metro_norm`** - Used for search (normalized)

## Secondary Columns (Used for filtering/sorting)

- **`is_active`** - Implicitly used for filtering active stores
- **`banner`** - Legacy field, may be referenced
- **`store_chain`** - Legacy field, may be referenced
- **`created_at`** - Used for sorting
- **`updated_at`** - Used for sorting

## Internal Columns (Not used in app, but used in reconciliation)

- **`banner_norm`** - Normalized banner for matching
- **`address_norm`** - Normalized address for matching
- **`city_norm`** - Normalized city for matching
- **`state_norm`** - Normalized state for matching
- **`zip5_norm`** - Normalized ZIP for matching
- **`match_key`** - Composite key for matching stores
- **`store_number`** - Store number from import
- **`zip5`** - Generated column (5-digit ZIP)
- **`state_zip`** - Generated column (state-zip combo)

## Files That Query Stores Table

### 1. `admin/enhanced-store-selector.js`
**Columns selected:**
```javascript
.select('id, name, STORE, address, city, state, zip_code, metro, METRO, metro_norm')
```

**Usage:**
- Search across: `STORE`, `name`, `city`, `address`, `zip_code`, `metro`, `METRO`, `metro_norm`
- Filter by chain using `STORE` column
- Display all selected columns in store cards

### 2. `pages/shelfer-dashboard.js`
**Columns selected:**
```javascript
stores (
    id,
    STORE,
    name,
    address,
    city,
    state,
    zip_code
)
```

**Usage:**
- Display store name: `STORE || name`
- Display address: `address, city, state zip_code`

### 3. `dashboard/brand-jobs.html`
**Columns selected:**
```javascript
stores(name, city, state)
```

**Usage:**
- Display store location information

### 4. Other Files
- `pages/create-job.js` - Uses store objects from enhanced-store-selector
- `admin/manage-jobs.html` - Uses store objects from enhanced-store-selector
- `dashboard/create-job.html` - Uses store objects from enhanced-store-selector

## Critical Notes

### Column Name Casing
⚠️ **IMPORTANT:** PostgreSQL is case-sensitive for quoted identifiers.
- `STORE` (uppercase, quoted) = Actual column name
- Always use: `store.STORE || store.name || 'Unknown Store'` for display

### Display Name Priority
```javascript
// CORRECT:
store.STORE || store.name || 'Unknown Store'

// WRONG:
store.name  // Legacy field, inconsistent
store.store_chain  // Not the display name
```

### Search Pattern
The app searches across multiple columns:
- `STORE`, `name`, `city`, `address`, `zip_code`, `metro`, `METRO`, `metro_norm`

### Filtering Pattern
Chain/banner filtering uses:
- `STORE` column with `ilike` pattern matching (e.g., `STORE.ilike.%Whole Foods%`)

## Columns NOT Used in Application

These columns exist in the table but are not referenced in application code:
- Internal normalization columns (`*_norm`, `match_key`)
- Reconciliation-specific columns (`store_number`)
- Generated columns (`zip5`, `state_zip`) - though `zip5` may be used implicitly

## Recommendation

If you're cleaning up the `stores` table, **DO NOT remove**:
- ✅ All columns listed in "Primary Columns" section
- ✅ All columns listed in "Secondary Columns" section
- ⚠️ Internal columns can be kept for reconciliation but are not needed for app functionality

