-- ========================================
-- Count rows in stores_import_new where ADDRESS, CITY, STATE are NULL
-- ========================================

-- Query 1: Count rows with NULL in address, city, state columns
-- Handles both uppercase (ADDRESS, CITY, STATE) and lowercase (address, city, state) column names
SELECT 
    'NULL ADDRESS, CITY, STATE COUNT' as info,
    COUNT(*) as total_rows,
    COUNT(*) FILTER (WHERE 
        (address IS NULL OR "ADDRESS" IS NULL) AND
        (city IS NULL OR "CITY" IS NULL) AND
        (state IS NULL OR "STATE" IS NULL)
    ) as rows_with_all_three_null,
    COUNT(*) FILTER (WHERE address IS NULL OR "ADDRESS" IS NULL) as rows_with_null_address,
    COUNT(*) FILTER (WHERE city IS NULL OR "CITY" IS NULL) as rows_with_null_city,
    COUNT(*) FILTER (WHERE state IS NULL OR "STATE" IS NULL) as rows_with_null_state,
    COUNT(*) FILTER (WHERE 
        (address IS NULL OR "ADDRESS" IS NULL) OR
        (city IS NULL OR "CITY" IS NULL) OR
        (state IS NULL OR "STATE" IS NULL)
    ) as rows_with_any_null
FROM stores_import_new;

-- Query 2: Breakdown by which columns are NULL
SELECT 
    'NULL BREAKDOWN' as info,
    CASE 
        WHEN (address IS NULL OR "ADDRESS" IS NULL) AND
             (city IS NULL OR "CITY" IS NULL) AND
             (state IS NULL OR "STATE" IS NULL) THEN 'All three NULL'
        WHEN (address IS NULL OR "ADDRESS" IS NULL) AND
             (city IS NULL OR "CITY" IS NULL) THEN 'Address and City NULL'
        WHEN (address IS NULL OR "ADDRESS" IS NULL) AND
             (state IS NULL OR "STATE" IS NULL) THEN 'Address and State NULL'
        WHEN (city IS NULL OR "CITY" IS NULL) AND
             (state IS NULL OR "STATE" IS NULL) THEN 'City and State NULL'
        WHEN address IS NULL OR "ADDRESS" IS NULL THEN 'Only Address NULL'
        WHEN city IS NULL OR "CITY" IS NULL THEN 'Only City NULL'
        WHEN state IS NULL OR "STATE" IS NULL THEN 'Only State NULL'
        ELSE 'All have values'
    END as null_pattern,
    COUNT(*) as row_count
FROM stores_import_new
GROUP BY 
    CASE 
        WHEN (address IS NULL OR "ADDRESS" IS NULL) AND
             (city IS NULL OR "CITY" IS NULL) AND
             (state IS NULL OR "STATE" IS NULL) THEN 'All three NULL'
        WHEN (address IS NULL OR "ADDRESS" IS NULL) AND
             (city IS NULL OR "CITY" IS NULL) THEN 'Address and City NULL'
        WHEN (address IS NULL OR "ADDRESS" IS NULL) AND
             (state IS NULL OR "STATE" IS NULL) THEN 'Address and State NULL'
        WHEN (city IS NULL OR "CITY" IS NULL) AND
             (state IS NULL OR "STATE" IS NULL) THEN 'City and State NULL'
        WHEN address IS NULL OR "ADDRESS" IS NULL THEN 'Only Address NULL'
        WHEN city IS NULL OR "CITY" IS NULL THEN 'Only City NULL'
        WHEN state IS NULL OR "STATE" IS NULL THEN 'Only State NULL'
        ELSE 'All have values'
    END
ORDER BY row_count DESC;

-- Query 3: Sample rows with all three NULL
SELECT 
    'SAMPLE ROWS: All three NULL (ADDRESS, CITY, STATE)' as info,
    id,
    "STORE",
    name,
    banner,
    store_chain,
    address,
    "ADDRESS",
    city,
    "CITY",
    state,
    "STATE",
    zip_code
FROM stores_import_new
WHERE (address IS NULL OR "ADDRESS" IS NULL) AND
      (city IS NULL OR "CITY" IS NULL) AND
      (state IS NULL OR "STATE" IS NULL)
LIMIT 20;

-- Query 4: Check which column names actually exist
SELECT 
    'COLUMN CHECK' as info,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'stores_import_new'
  AND column_name IN ('address', 'ADDRESS', 'city', 'CITY', 'state', 'STATE')
ORDER BY column_name;

