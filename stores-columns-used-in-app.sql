-- ========================================
-- Columns from stores table that are used/referenced in the application
-- Based on codebase analysis
-- ========================================

-- Summary of columns used:
SELECT 
    'COLUMNS USED IN APPLICATION' as info,
    column_name,
    CASE 
        WHEN column_name IN ('id', 'STORE', 'name', 'address', 'city', 'state', 'zip_code', 'metro', 'METRO', 'metro_norm') THEN 'PRIMARY - Used in queries'
        WHEN column_name IN ('is_active', 'banner', 'store_chain', 'created_at', 'updated_at') THEN 'SECONDARY - Used for filtering/display'
        WHEN column_name LIKE '%_norm' OR column_name LIKE 'match_key' OR column_name LIKE 'store_number' THEN 'INTERNAL - Used for matching/reconciliation'
        ELSE 'UNUSED - Not found in application code'
    END as usage_category
FROM information_schema.columns
WHERE table_name = 'stores'
ORDER BY 
    CASE 
        WHEN column_name IN ('id', 'STORE', 'name', 'address', 'city', 'state', 'zip_code', 'metro', 'METRO', 'metro_norm') THEN 1
        WHEN column_name IN ('is_active', 'banner', 'store_chain', 'created_at', 'updated_at') THEN 2
        WHEN column_name LIKE '%_norm' OR column_name LIKE 'match_key' OR column_name LIKE 'store_number' THEN 3
        ELSE 4
    END,
    column_name;

-- Detailed breakdown by file/usage:

-- 1. admin/enhanced-store-selector.js
--    SELECT queries use:
--      - id (primary key, used everywhere)
--      - name (fallback display name)
--      - STORE (primary display name, uppercase column)
--      - address (search and display)
--      - city (search and display)
--      - state (search and display)
--      - zip_code (search and display)
--      - metro (search)
--      - METRO (search, legacy)
--      - metro_norm (search, normalized)
--    Filtering uses:
--      - STORE (for chain/banner filtering)
--      - is_active (implicitly, via WHERE clauses)
--    Display uses:
--      - All of the above for rendering store cards

-- 2. pages/shelfer-dashboard.js
--    SELECT queries use:
--      - id (join key)
--      - STORE (display name)
--      - name (fallback display name)
--      - address (display)
--      - city (display)
--      - state (display)
--      - zip_code (display)

-- 3. dashboard/brand-jobs.html
--    SELECT queries use:
--      - name (display)
--      - city (display)
--      - state (display)

-- 4. Other files (create-job.js, manage-jobs.html)
--    Use store objects from enhanced-store-selector, which includes:
--      - id, name, STORE, address, city, state, zip_code, metro, METRO, metro_norm

-- Complete list of columns actually used:
SELECT 
    'COMPLETE LIST OF USED COLUMNS' as info,
    string_agg(column_name, ', ' ORDER BY column_name) as used_columns
FROM (
    SELECT DISTINCT column_name
    FROM information_schema.columns
    WHERE table_name = 'stores'
      AND column_name IN (
          'id',                    -- Primary key, used in all queries
          'STORE',                -- Primary display name (uppercase column)
          'name',                 -- Fallback display name
          'address',              -- Search and display
          'city',                 -- Search and display
          'state',                -- Search and display
          'zip_code',             -- Search and display
          'metro',                -- Search (lowercase)
          'METRO',                -- Search (uppercase, legacy)
          'metro_norm',           -- Search (normalized)
          'is_active',            -- Filtering (implicit)
          'banner',               -- Legacy field, may be used
          'store_chain',          -- Legacy field, may be used
          'created_at',           -- Sorting/display
          'updated_at'            -- Sorting/display
      )
) subq;

