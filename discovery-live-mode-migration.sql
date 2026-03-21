-- ============================================================
-- ShelfAssured: Discovery vs. Live Mode Migration
-- Run in Supabase SQL Editor
-- ============================================================
-- Generated: 2026-03-21
--
-- Discovery Mode: shelfer checks shelf presence and reports
--   what they find. Photos are optional. Useful for brands
--   entering a new market or verifying distribution.
--
-- Live Mode (default): full job execution with required photos.
--   Standard paid audit workflow.
--
-- The mode flag cascades: brand-level → job-level → product-level.
-- Job-level overrides brand-level. Product-level overrides job-level.
-- The app reads job.mode first, then brand.mode as fallback.
-- ============================================================

-- ── 1. ADD mode COLUMN TO brands ────────────────────────────
ALTER TABLE public.brands
  ADD COLUMN IF NOT EXISTS mode TEXT DEFAULT 'live'
    CHECK (mode IN ('live', 'discovery'));

-- ── 2. ADD mode COLUMN TO jobs ──────────────────────────────
ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS mode TEXT DEFAULT NULL
    CHECK (mode IN ('live', 'discovery') OR mode IS NULL);
-- NULL means "inherit from brand"

-- ── 3. ADD mode COLUMN TO skus (product-level override) ─────
ALTER TABLE public.skus
  ADD COLUMN IF NOT EXISTS mode TEXT DEFAULT NULL
    CHECK (mode IN ('live', 'discovery') OR mode IS NULL);
-- NULL means "inherit from job/brand"

-- ── 4. VERIFY ───────────────────────────────────────────────
SELECT table_name, column_name, data_type, column_default, is_nullable
  FROM information_schema.columns
 WHERE table_schema = 'public'
   AND table_name   IN ('brands', 'jobs', 'skus')
   AND column_name  = 'mode'
 ORDER BY table_name;

-- ── 5. SET EXISTING BRANDS TO 'live' (safe default) ─────────
UPDATE public.brands
   SET mode = 'live'
 WHERE mode IS NULL;

-- ── 6. USAGE EXAMPLES ───────────────────────────────────────
-- Set a brand to Discovery Mode:
--   UPDATE brands SET mode = 'discovery' WHERE name = 'Some Brand';
--
-- Override a single job to Discovery Mode:
--   UPDATE jobs SET mode = 'discovery' WHERE id = '<job_uuid>';
--
-- Reset a job to inherit brand mode:
--   UPDATE jobs SET mode = NULL WHERE id = '<job_uuid>';
--
-- Set a specific SKU to Discovery Mode:
--   UPDATE skus SET mode = 'discovery' WHERE id = '<sku_uuid>';

-- ── 7. HEALTH CHECK ─────────────────────────────────────────
SELECT
  'brands' AS table_name,
  mode,
  COUNT(*) AS count
FROM public.brands
GROUP BY mode

UNION ALL

SELECT
  'jobs' AS table_name,
  COALESCE(mode, '(inherit)') AS mode,
  COUNT(*) AS count
FROM public.jobs
GROUP BY mode

ORDER BY table_name, mode;
