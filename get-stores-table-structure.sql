-- ========================================
-- Get exact stores table structure
-- ========================================

SELECT 
    column_name,
    data_type,
    character_maximum_length,
    numeric_precision,
    numeric_scale,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns
WHERE table_name = 'stores'
ORDER BY ordinal_position;

