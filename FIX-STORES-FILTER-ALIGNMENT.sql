-- Fix stores filter alignment
-- Make dropdown values match filter field exactly

CREATE OR REPLACE VIEW v_store_chains AS
SELECT
  store_chain AS chain_value,
  store_chain AS chain_label,
  COUNT(*) AS store_count
FROM stores
WHERE store_chain IS NOT NULL AND store_chain <> '' AND is_active = true
GROUP BY store_chain
ORDER BY store_chain;

GRANT SELECT ON v_store_chains TO authenticated;
GRANT SELECT ON v_store_chains TO anon;

-- Verify alignment: dropdown values = filter values
-- This should return zero rows if aligned
SELECT 
  'Mismatch found' AS status,
  s.store_chain AS stores_chain_value,
  v.chain_value AS view_chain_value
FROM (SELECT DISTINCT store_chain FROM stores WHERE store_chain IS NOT NULL AND store_chain <> '') s
LEFT JOIN v_store_chains v ON v.chain_value = s.store_chain
WHERE v.chain_value IS NULL
LIMIT 10;

-- Show what will be in the dropdown
SELECT chain_value, chain_label, store_count
FROM v_store_chains
ORDER BY chain_label;

