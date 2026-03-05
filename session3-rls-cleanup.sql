-- ============================================================
-- ShelfAssured: Session 3 — RLS Security Cleanup
-- Version: 1.0
-- Apply in: Supabase SQL Editor (run once, after session3-rls-migration.sql)
-- Addresses all remaining advisories from the Supabase security linter.
-- ============================================================


-- ============================================================
-- PART 1: DROP OLD PERMISSIVE POLICIES (Critical)
-- These policies bypass RLS by allowing unrestricted access.
-- They were created before the Session 3 migration and were
-- not dropped because they had different names.
-- ============================================================

-- products — anon and authenticated open access
DROP POLICY IF EXISTS anon_insert_products       ON public.products;
DROP POLICY IF EXISTS anon_update_products       ON public.products;
DROP POLICY IF EXISTS anon_select_products       ON public.products;
DROP POLICY IF EXISTS authenticated_insert_products ON public.products;
DROP POLICY IF EXISTS authenticated_update_products ON public.products;
DROP POLICY IF EXISTS authenticated_select_products ON public.products;

-- brands — open insert/update
DROP POLICY IF EXISTS brands_insert              ON public.brands;
DROP POLICY IF EXISTS brands_update              ON public.brands;
DROP POLICY IF EXISTS brands_select              ON public.brands;

-- stores — anon and open access
DROP POLICY IF EXISTS anon_insert_stores         ON public.stores;
DROP POLICY IF EXISTS anon_select_stores         ON public.stores;
DROP POLICY IF EXISTS stores_insert              ON public.stores;
DROP POLICY IF EXISTS stores_update              ON public.stores;
DROP POLICY IF EXISTS stores_select              ON public.stores;

-- jobs — open insert
DROP POLICY IF EXISTS "allow insert on jobs for authenticated" ON public.jobs;


-- ============================================================
-- PART 2: ENABLE RLS ON ALL REMAINING UNPROTECTED TABLES
-- These tables were not included in the first migration.
-- ============================================================

ALTER TABLE public.audit_requests             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pilot_leads                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.retailers                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submission_details         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submission_photos          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_users                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.retailer_banners           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.retailer_aliases           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.retailer_banner_aliases    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_photos                 ENABLE ROW LEVEL SECURITY;

-- Backup / import tables — lock down completely (admin only)
ALTER TABLE public.stores_backup              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stores_backup_utc          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stores_import_new          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.retailer_banners_backup_utc ENABLE ROW LEVEL SECURITY;
ALTER TABLE public._probe                     ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- PART 3: ADD POLICIES FOR NEWLY PROTECTED TABLES
-- ============================================================

-- ── audit_requests ───────────────────────────────────────────
-- Drop existing policies first (they exist but RLS was off)
DROP POLICY IF EXISTS "Admins can view all audit requests"    ON public.audit_requests;
DROP POLICY IF EXISTS "Users can insert own audit requests"   ON public.audit_requests;
DROP POLICY IF EXISTS "Users can update own audit requests"   ON public.audit_requests;
DROP POLICY IF EXISTS "Users can view own audit requests"     ON public.audit_requests;

CREATE POLICY "admin: full access"
  ON public.audit_requests FOR ALL
  USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "user: own audit requests"
  ON public.audit_requests FOR ALL
  USING (auth.uid() = client_id) WITH CHECK (auth.uid() = client_id);


-- ── pilot_leads ──────────────────────────────────────────────
DROP POLICY IF EXISTS "Admins can update pilot leads"         ON public.pilot_leads;
DROP POLICY IF EXISTS "Admins can view all pilot leads"       ON public.pilot_leads;
DROP POLICY IF EXISTS "Anyone can insert pilot leads"         ON public.pilot_leads;

CREATE POLICY "admin: full access"
  ON public.pilot_leads FOR ALL
  USING (is_admin()) WITH CHECK (is_admin());

-- Allow anyone (including anon) to submit a pilot lead — this is a public intake form
CREATE POLICY "public: insert pilot lead"
  ON public.pilot_leads FOR INSERT
  WITH CHECK (true);


-- ── retailers ────────────────────────────────────────────────
DROP POLICY IF EXISTS anon_insert_retailers ON public.retailers;
DROP POLICY IF EXISTS anon_select_retailers ON public.retailers;

CREATE POLICY "admin: full access"
  ON public.retailers FOR ALL
  USING (is_admin()) WITH CHECK (is_admin());

-- All authenticated users can read retailers (needed for store selector)
CREATE POLICY "authenticated: read retailers"
  ON public.retailers FOR SELECT
  USING (auth.role() = 'authenticated');


-- ── settings ─────────────────────────────────────────────────
DROP POLICY IF EXISTS "Admins can read settings" ON public.settings;

CREATE POLICY "admin: full access"
  ON public.settings FOR ALL
  USING (is_admin()) WITH CHECK (is_admin());


-- ── submission_details ───────────────────────────────────────
DROP POLICY IF EXISTS submission_details_insert_assignee           ON public.submission_details;
DROP POLICY IF EXISTS submission_details_select_creator_or_admin   ON public.submission_details;
DROP POLICY IF EXISTS submission_details_update_admin              ON public.submission_details;

CREATE POLICY "admin: full access"
  ON public.submission_details FOR ALL
  USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "shelfer: own submission details"
  ON public.submission_details FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.job_submissions js
      WHERE js.id = submission_details.submission_id
        AND (js.submission_user_id = auth.uid() OR js.contractor_id = auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.job_submissions js
      WHERE js.id = submission_details.submission_id
        AND (js.submission_user_id = auth.uid() OR js.contractor_id = auth.uid())
    )
  );


-- ── submission_photos ────────────────────────────────────────
DROP POLICY IF EXISTS submission_photos_insert_assignee          ON public.submission_photos;
DROP POLICY IF EXISTS submission_photos_select_creator_or_admin  ON public.submission_photos;
DROP POLICY IF EXISTS submission_photos_update_admin             ON public.submission_photos;

CREATE POLICY "admin: full access"
  ON public.submission_photos FOR ALL
  USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "shelfer: own submission photos"
  ON public.submission_photos FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.job_submissions js
      WHERE js.id = submission_photos.submission_id
        AND (js.submission_user_id = auth.uid() OR js.contractor_id = auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.job_submissions js
      WHERE js.id = submission_photos.submission_id
        AND (js.submission_user_id = auth.uid() OR js.contractor_id = auth.uid())
    )
  );


-- ── app_users ────────────────────────────────────────────────
CREATE POLICY "admin: full access"
  ON public.app_users FOR ALL
  USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "user: own app_user row"
  ON public.app_users FOR SELECT
  USING (auth.uid() = id);


-- ── retailer_banners ─────────────────────────────────────────
CREATE POLICY "admin: full access"
  ON public.retailer_banners FOR ALL
  USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "authenticated: read retailer_banners"
  ON public.retailer_banners FOR SELECT
  USING (auth.role() = 'authenticated');


-- ── retailer_aliases ─────────────────────────────────────────
CREATE POLICY "admin: full access"
  ON public.retailer_aliases FOR ALL
  USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "authenticated: read retailer_aliases"
  ON public.retailer_aliases FOR SELECT
  USING (auth.role() = 'authenticated');


-- ── retailer_banner_aliases ──────────────────────────────────
CREATE POLICY "admin: full access"
  ON public.retailer_banner_aliases FOR ALL
  USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "authenticated: read retailer_banner_aliases"
  ON public.retailer_banner_aliases FOR SELECT
  USING (auth.role() = 'authenticated');


-- ── job_photos ───────────────────────────────────────────────
-- RLS was enabled but no policies existed — nobody could read/write photos.
CREATE POLICY "admin: full access"
  ON public.job_photos FOR ALL
  USING (is_admin()) WITH CHECK (is_admin());

CREATE POLICY "shelfer: own job photos"
  ON public.job_photos FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.jobs j
      WHERE j.id = job_photos.job_id
        AND j.assigned_user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.jobs j
      WHERE j.id = job_photos.job_id
        AND j.assigned_user_id = auth.uid()
    )
  );

CREATE POLICY "brand_client: read own job photos"
  ON public.job_photos FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.jobs j
      WHERE j.id = job_photos.job_id
        AND j.brand_id = get_my_brand_id()
    )
  );


-- ── backup / import / probe tables (admin only) ──────────────
CREATE POLICY "admin: full access" ON public.stores_backup              FOR ALL USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "admin: full access" ON public.stores_backup_utc          FOR ALL USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "admin: full access" ON public.stores_import_new          FOR ALL USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "admin: full access" ON public.retailer_banners_backup_utc FOR ALL USING (is_admin()) WITH CHECK (is_admin());
CREATE POLICY "admin: full access" ON public._probe                     FOR ALL USING (is_admin()) WITH CHECK (is_admin());


-- ============================================================
-- PART 4: REBUILD SECURITY DEFINER VIEWS AS SECURITY INVOKER
-- SECURITY DEFINER views bypass RLS — they run as the view
-- owner (postgres) and can see all rows regardless of the
-- caller's permissions. SECURITY INVOKER is the safe default:
-- the view runs as the calling user and respects their RLS.
-- ============================================================

-- ── v_distinct_banners ───────────────────────────────────────
DROP VIEW IF EXISTS public.v_distinct_banners CASCADE;
CREATE VIEW public.v_distinct_banners
  WITH (security_invoker = true)
AS
SELECT DISTINCT
  s.banner_id,
  rb.name AS banner_name
FROM public.stores s
JOIN public.retailer_banners rb ON rb.id = s.banner_id
WHERE s.is_active = true AND s.banner_id IS NOT NULL
ORDER BY rb.name;

GRANT SELECT ON public.v_distinct_banners TO authenticated;


-- ── store_banners ────────────────────────────────────────────
DROP VIEW IF EXISTS public.store_banners CASCADE;
CREATE VIEW public.store_banners
  WITH (security_invoker = true)
AS
SELECT DISTINCT
  banner,
  COUNT(*) AS store_count
FROM public.stores
WHERE is_active = TRUE
  AND banner IS NOT NULL
  AND banner != ''
GROUP BY banner
ORDER BY banner;

GRANT SELECT ON public.store_banners TO authenticated;


-- ── v_job_assignments ────────────────────────────────────────
DROP VIEW IF EXISTS public.v_job_assignments CASCADE;
CREATE VIEW public.v_job_assignments
  WITH (security_invoker = true)
AS
SELECT
  j.id            AS job_id,
  j.title         AS job_title,
  s.id            AS store_id,
  s.store_chain   AS store_chain,
  s.name          AS store_name,
  k.id            AS sku_id,
  k.name          AS sku_name,
  k.upc           AS sku_code,
  b.id            AS brand_id,
  b.name          AS brand_name,
  j.created_at
FROM public.job_store_skus jss
JOIN public.jobs        j ON j.id  = jss.job_id
JOIN public.stores      s ON s.id  = jss.store_id
JOIN public.skus        k ON k.id  = jss.sku_id
LEFT JOIN public.brands b ON b.id  = k.brand_id;

GRANT SELECT ON public.v_job_assignments TO authenticated;


-- ── job_assignments ──────────────────────────────────────────
DROP VIEW IF EXISTS public.job_assignments CASCADE;
CREATE VIEW public.job_assignments
  WITH (security_invoker = true)
AS
SELECT
  j.id                          AS job_id,
  j.title,
  j.status,
  j.created_at                  AS job_created_at,
  u_assigned.email              AS assigned_user_email,
  u_assigned.user_type          AS assigned_user_type,
  u_client.email                AS client_email,
  u_client.user_type            AS client_type,
  COUNT(js.id)                  AS submission_count,
  MAX(js.submission_time)       AS last_submission_time
FROM public.jobs j
LEFT JOIN public.users u_assigned ON j.assigned_user_id = u_assigned.id
LEFT JOIN public.users u_client   ON j.client_id        = u_client.id
LEFT JOIN public.job_submissions js ON j.id             = js.job_id
GROUP BY
  j.id, j.title, j.status, j.created_at,
  u_assigned.email, u_assigned.user_type,
  u_client.email,   u_client.user_type;

GRANT SELECT ON public.job_assignments TO authenticated;


-- ── submission_tracking ──────────────────────────────────────
DROP VIEW IF EXISTS public.submission_tracking CASCADE;
CREATE VIEW public.submission_tracking
  WITH (security_invoker = true)
AS
SELECT
  js.id                     AS submission_id,
  js.job_id,
  j.title                   AS job_title,
  js.submission_time,
  u_submitter.email         AS submitter_email,
  u_submitter.user_type     AS submitter_type,
  js.status                 AS submission_status,
  js.is_validated,
  u_validator.email         AS validator_email,
  js.validation_notes
FROM public.job_submissions js
JOIN public.jobs j ON js.job_id = j.id
LEFT JOIN public.users u_submitter ON js.submission_user_id = u_submitter.id
LEFT JOIN public.users u_validator ON js.validated_by       = u_validator.id;

GRANT SELECT ON public.submission_tracking TO authenticated;


-- ============================================================
-- PART 5: FIX FUNCTION SEARCH PATHS (Medium)
-- Prevents search_path injection attacks on SECURITY DEFINER
-- functions. Adding SET search_path = public pins the function
-- to the correct schema at definition time.
-- ============================================================

-- Note: We cannot ALTER these functions without knowing their
-- full signatures. The safest approach is to recreate them
-- with the fixed search_path. However, since these functions
-- (reject_submission, approve_submission, merge_brand_records,
-- upsert_brand_public, update_help_requests_updated_at) are
-- operational and their full bodies are not available here,
-- we add the search_path fix as a targeted ALTER instead.

DO $$
DECLARE
  fn RECORD;
BEGIN
  FOR fn IN
    SELECT routine_name, routine_schema
    FROM information_schema.routines
    WHERE routine_schema = 'public'
      AND routine_name IN (
        'reject_submission',
        'approve_submission',
        'merge_brand_records',
        'upsert_brand_public',
        'update_help_requests_updated_at'
      )
  LOOP
    EXECUTE format(
      'ALTER FUNCTION public.%I SET search_path = public',
      fn.routine_name
    );
  END LOOP;
END;
$$;


-- ============================================================
-- PART 6: VERIFICATION
-- ============================================================

-- 6a. Confirm no tables remain unprotected
SELECT
  tablename,
  rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY rls_enabled ASC, tablename;

-- 6b. Confirm no "always true" permissive policies remain on key tables
SELECT
  tablename,
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('products', 'brands', 'stores', 'jobs')
ORDER BY tablename, policyname;

-- 6c. Confirm views are now SECURITY INVOKER
SELECT
  viewname,
  definition
FROM pg_views
WHERE schemaname = 'public'
  AND viewname IN (
    'v_distinct_banners', 'store_banners',
    'v_job_assignments', 'job_assignments', 'submission_tracking'
  );

SELECT 'RLS cleanup complete.' AS status;
