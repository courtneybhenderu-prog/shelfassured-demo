-- ========================================
-- Add Documentation Comment to STORE Column
-- Documents that STORE is a generated display field
-- ========================================

COMMENT ON COLUMN stores."STORE" IS 'Generated display field. Format: {Banner} – {City} – {State} – {Disambiguator}. Auto-generated from banner, city, state, and address. Do not manually edit. See STORE-NAMING-RULES.md for full documentation.';

