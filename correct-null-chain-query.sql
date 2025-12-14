-- ========================================
-- CORRECT query to find rows where CHAIN is NULL
-- ========================================

-- ✅ CORRECT: Use IS NULL to check for NULL values
SELECT * 
FROM stores_import_new 
WHERE "CHAIN" IS NULL;

-- ❌ WRONG: "CHAIN" == "NULL" 
-- Issues:
-- 1. "select all" should be "SELECT *"
-- 2. "==" is not SQL syntax (use "=" for equality, but not for NULL)
-- 3. "NULL" in quotes is a string, not the SQL NULL value
-- 4. NULL values cannot be compared with = or ==, must use IS NULL

-- Alternative correct syntax:
SELECT * 
FROM stores_import_new 
WHERE "CHAIN" IS NULL
ORDER BY id;

-- If you want to check for both NULL and empty string:
SELECT * 
FROM stores_import_new 
WHERE "CHAIN" IS NULL OR "CHAIN" = '';

-- If you want to check for NOT NULL:
SELECT * 
FROM stores_import_new 
WHERE "CHAIN" IS NOT NULL;

