-- Create function to resolve banner_id from retailer alias
-- This replaces retailer_id resolution with banner_id

CREATE OR REPLACE FUNCTION resolve_banner_id_from_alias(alias_text TEXT)
RETURNS UUID AS $$
DECLARE
  result_banner_id UUID;
BEGIN
  -- First try retailer_banner_aliases
  SELECT bba.banner_id INTO result_banner_id
  FROM retailer_banner_aliases bba
  WHERE bba.alias = LOWER(TRIM(alias_text));
  
  IF result_banner_id IS NOT NULL THEN
    RETURN result_banner_id;
  END IF;
  
  -- Fallback to retailers if retailer_banner_aliases doesn't have it
  SELECT rb.id INTO result_banner_id
  FROM retailers r
  JOIN retailer_banners rb ON rb.retailer_id = r.id
  WHERE LOWER(TRIM(r.name)) = LOWER(TRIM(alias_text))
  LIMIT 1;
  
  RETURN result_banner_id;
END;
$$ LANGUAGE plpgsql;

-- Grant execute
GRANT EXECUTE ON FUNCTION resolve_banner_id_from_alias TO authenticated;

-- Verify it works
SELECT 
  'H-E-B' as test_alias,
  resolve_banner_id_from_alias('H-E-B') as banner_id;

