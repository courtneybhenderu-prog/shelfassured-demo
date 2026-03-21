-- ============================================================
-- ShelfAssured: Aisle Intelligence Migration
-- Run in Supabase SQL Editor
-- ============================================================
-- Generated: 2026-03-21
-- Adds aisle tracking to brand_stores so shelfers can record
-- which aisle products are in, and the brand dashboard can
-- surface that intel to clients.
-- ============================================================

-- ── 1. ADD AISLE COLUMNS TO brand_stores ────────────────────
-- aisle: free-text aisle description (e.g. "Aisle 7", "Natural Foods", "Beverage")
-- aisle_updated_at: timestamp of last aisle update (from job submission)

ALTER TABLE public.brand_stores
  ADD COLUMN IF NOT EXISTS aisle TEXT,
  ADD COLUMN IF NOT EXISTS aisle_updated_at TIMESTAMPTZ;

-- ── 2. VERIFY ───────────────────────────────────────────────
SELECT column_name, data_type, is_nullable
  FROM information_schema.columns
 WHERE table_schema = 'public'
   AND table_name   = 'brand_stores'
   AND column_name  IN ('aisle', 'aisle_updated_at')
 ORDER BY column_name;

-- ── 3. OPTIONAL: BACKFILL from existing job_submissions ─────
-- If any prior submissions included aisle data in their JSONB,
-- this will backfill brand_stores. Safe to run — only updates
-- rows where aisle is currently NULL.

UPDATE public.brand_stores bs
SET
  aisle            = latest.aisle,
  aisle_updated_at = latest.captured_at
FROM (
  SELECT DISTINCT ON (js.store_id, j.brand_id)
    js.store_id,
    j.brand_id,
    (js.data->>'aisle')::text AS aisle,
    (js.data->>'captured_at')::timestamptz AS captured_at
  FROM public.job_submissions js
  JOIN public.jobs j ON j.id = js.job_id
  WHERE js.data->>'aisle' IS NOT NULL
    AND js.data->>'aisle' <> ''
  ORDER BY js.store_id, j.brand_id, js.created_at DESC
) latest
WHERE bs.store_id  = latest.store_id
  AND bs.brand_id  = latest.brand_id
  AND bs.aisle IS NULL;

-- ── 4. HEALTH CHECK ─────────────────────────────────────────
SELECT
  COUNT(*) AS total_brand_stores,
  COUNT(aisle) AS stores_with_aisle,
  ROUND(COUNT(aisle)::numeric / NULLIF(COUNT(*), 0) * 100, 1) AS pct_with_aisle
FROM public.brand_stores;
