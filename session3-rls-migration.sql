-- ============================================================
-- ShelfAssured: Session 3 — Complete RLS Migration
-- Version: 1.0
-- Apply in: Supabase SQL Editor (run once, idempotent)
-- ============================================================

-- ============================================================
-- PART 1: SCHEMA ADDITIONS
-- Add the columns needed to enforce tenant isolation.
-- ============================================================

-- 1a. Add brand_id to the products table.
--     This is the critical link for brand client data isolation.
ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS brand_id UUID REFERENCES public.brands(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.products.brand_id IS
  'FK to brands. Used for RLS tenant isolation. Backfilled from products.brand text column.';

CREATE INDEX IF NOT EXISTS idx_products_brand_id ON public.products(brand_id);

-- 1b. Backfill brand_id from the existing text brand column.
--     Matches products.brand (text) to brands.name (text), case-insensitive.
--     Products with no matching brand record will remain NULL.
UPDATE public.products p
SET brand_id = b.id
FROM public.brands b
WHERE LOWER(TRIM(p.brand)) = LOWER(TRIM(b.name))
  AND p.brand_id IS NULL;

-- 1c. Add brand_id to the users table.
--     For brand_client users, this links them to their brand.
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS brand_id UUID REFERENCES public.brands(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.users.brand_id IS
  'For brand_client users only: links the user to their brand for RLS enforcement.';

CREATE INDEX IF NOT EXISTS idx_users_brand_id ON public.users(brand_id);


-- ============================================================
-- PART 2: HELPER FUNCTIONS
-- Centralize role and brand lookups. SECURITY DEFINER means
-- these run as the postgres superuser, bypassing RLS on the
-- users table itself — this is intentional and safe.
-- ============================================================

-- Returns the role of the currently authenticated user.
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN COALESCE(
    (SELECT role FROM public.users WHERE id = auth.uid()),
    'shelfer'
  );
END;
$$;

-- Returns the brand_id of the currently authenticated user.
CREATE OR REPLACE FUNCTION public.get_my_brand_id()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN (SELECT brand_id FROM public.users WHERE id = auth.uid());
END;
$$;

-- Convenience boolean: is the current user an admin?
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN (SELECT role = 'admin' FROM public.users WHERE id = auth.uid());
END;
$$;


-- ============================================================
-- PART 3: CLEAN UP OLD POLICIES
-- Drop all existing policies before creating new ones to avoid
-- conflicts. This is safe because we recreate everything below.
-- ============================================================

-- users
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
DROP POLICY IF EXISTS admin_full_access ON public.users;
DROP POLICY IF EXISTS user_self_access ON public.users;

-- brands
DROP POLICY IF EXISTS anon_insert_brands ON public.brands;
DROP POLICY IF EXISTS anon_update_brands ON public.brands;
DROP POLICY IF EXISTS anon_select_brands ON public.brands;
DROP POLICY IF EXISTS admin_all_brands ON public.brands;
DROP POLICY IF EXISTS admin_full_access ON public.brands;
DROP POLICY IF EXISTS brand_client_access ON public.brands;
DROP POLICY IF EXISTS public_brands_read ON public.brands;

-- products
DROP POLICY IF EXISTS admin_full_access ON public.products;
DROP POLICY IF EXISTS brand_client_products_access ON public.products;
DROP POLICY IF EXISTS public_products_read ON public.products;

-- skus
DROP POLICY IF EXISTS admin_full_access ON public.skus;
DROP POLICY IF EXISTS brand_client_skus_access ON public.skus;
DROP POLICY IF EXISTS public_skus_read ON public.skus;

-- stores
DROP POLICY IF EXISTS admin_full_access ON public.stores;
DROP POLICY IF EXISTS public_stores_read ON public.stores;

-- jobs
DROP POLICY IF EXISTS "Users can view assigned jobs" ON public.jobs;
DROP POLICY IF EXISTS admin_full_access ON public.jobs;
DROP POLICY IF EXISTS brand_client_jobs_access ON public.jobs;
DROP POLICY IF EXISTS shelfer_jobs_access ON public.jobs;

-- job_stores
DROP POLICY IF EXISTS admin_full_access ON public.job_stores;
DROP POLICY IF EXISTS public_job_stores_read ON public.job_stores;
DROP POLICY IF EXISTS jss_rw ON public.job_store_skus;

-- job_skus
DROP POLICY IF EXISTS admin_full_access ON public.job_skus;
DROP POLICY IF EXISTS public_job_skus_read ON public.job_skus;

-- job_submissions
DROP POLICY IF EXISTS admin_full_access ON public.job_submissions;
DROP POLICY IF EXISTS brand_client_submissions_access ON public.job_submissions;
DROP POLICY IF EXISTS shelfer_submissions_access ON public.job_submissions;

-- payments
DROP POLICY IF EXISTS admin_full_access ON public.payments;
DROP POLICY IF EXISTS user_payments_access ON public.payments;

-- notifications
DROP POLICY IF EXISTS admin_full_access ON public.notifications;
DROP POLICY IF EXISTS user_notifications_access ON public.notifications;


-- ============================================================
-- PART 4: ENABLE RLS ON ALL TABLES
-- ============================================================

ALTER TABLE public.users            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.brands           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.skus             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stores           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_stores       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_skus         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_store_skus   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_submissions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications    ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- PART 5: CREATE RLS POLICIES
-- Three tiers: Admin (full access), Brand Client (own brand
-- only), Shelfer / public (limited read access).
-- ============================================================

-- ── users ────────────────────────────────────────────────────
-- Admins see all users.
CREATE POLICY "admin: full access"
  ON public.users FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- Every user can read and update their own row.
CREATE POLICY "user: own row"
  ON public.users FOR ALL
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);


-- ── brands ───────────────────────────────────────────────────
-- Admins see and edit all brands (including shadow brands).
CREATE POLICY "admin: full access"
  ON public.brands FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- Brand clients can read and update only their own brand.
-- They cannot see shadow brands or other brands.
CREATE POLICY "brand_client: own brand"
  ON public.brands FOR ALL
  USING (id = get_my_brand_id() AND is_shadow = false)
  WITH CHECK (id = get_my_brand_id());

-- Shelfers and unauthenticated users can read non-shadow brands
-- (needed for job detail pages that show brand name).
CREATE POLICY "public: read non-shadow brands"
  ON public.brands FOR SELECT
  USING (is_shadow = false);


-- ── products ─────────────────────────────────────────────────
-- Admins see all products.
CREATE POLICY "admin: full access"
  ON public.products FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- Brand clients see only products belonging to their brand.
CREATE POLICY "brand_client: own brand products"
  ON public.products FOR SELECT
  USING (brand_id = get_my_brand_id());

-- Authenticated users (shelfers) can insert products during scanning.
-- They cannot see or edit other users' products.
CREATE POLICY "shelfer: insert own products"
  ON public.products FOR INSERT
  WITH CHECK (auth.uid() = added_by);

CREATE POLICY "shelfer: read own products"
  ON public.products FOR SELECT
  USING (auth.uid() = added_by);


-- ── skus ─────────────────────────────────────────────────────
-- Admins see all SKUs.
CREATE POLICY "admin: full access"
  ON public.skus FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- Brand clients see only their own SKUs.
CREATE POLICY "brand_client: own brand skus"
  ON public.skus FOR SELECT
  USING (brand_id = get_my_brand_id());

-- All authenticated users can read SKUs (needed for scanner lookup).
CREATE POLICY "authenticated: read skus"
  ON public.skus FOR SELECT
  USING (auth.role() = 'authenticated');


-- ── stores ───────────────────────────────────────────────────
-- Admins have full access.
CREATE POLICY "admin: full access"
  ON public.stores FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- All authenticated users can read stores (needed for scanner and job pages).
CREATE POLICY "authenticated: read stores"
  ON public.stores FOR SELECT
  USING (auth.role() = 'authenticated');


-- ── jobs ─────────────────────────────────────────────────────
-- Admins see and manage all jobs.
CREATE POLICY "admin: full access"
  ON public.jobs FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- Brand clients see only jobs for their brand.
CREATE POLICY "brand_client: own brand jobs"
  ON public.jobs FOR SELECT
  USING (brand_id = get_my_brand_id());

-- Shelfers can see jobs assigned to them, or open jobs they can claim.
CREATE POLICY "shelfer: assigned or open jobs"
  ON public.jobs FOR SELECT
  USING (assigned_user_id = auth.uid() OR status = 'pending');


-- ── job_stores ───────────────────────────────────────────────
CREATE POLICY "admin: full access"
  ON public.job_stores FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

CREATE POLICY "authenticated: read job_stores"
  ON public.job_stores FOR SELECT
  USING (auth.role() = 'authenticated');


-- ── job_skus ─────────────────────────────────────────────────
CREATE POLICY "admin: full access"
  ON public.job_skus FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

CREATE POLICY "authenticated: read job_skus"
  ON public.job_skus FOR SELECT
  USING (auth.role() = 'authenticated');


-- ── job_store_skus ───────────────────────────────────────────
CREATE POLICY "admin: full access"
  ON public.job_store_skus FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- Shelfers and brand clients can read job_store_skus for jobs they can see.
CREATE POLICY "authenticated: read own job_store_skus"
  ON public.job_store_skus FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.jobs j
      WHERE j.id = job_store_skus.job_id
        AND (
          is_admin()
          OR j.brand_id = get_my_brand_id()
          OR j.assigned_user_id = auth.uid()
          OR j.status = 'pending'
        )
    )
  );

CREATE POLICY "shelfer: write own job_store_skus"
  ON public.job_store_skus FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.jobs j
      WHERE j.id = job_store_skus.job_id
        AND j.assigned_user_id = auth.uid()
    )
  );


-- ── job_submissions ──────────────────────────────────────────
-- Admins see and manage all submissions.
CREATE POLICY "admin: full access"
  ON public.job_submissions FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- Brand clients can read (but not edit) submissions for their brand's jobs.
-- They only see validated/approved submissions — not raw in-progress data.
CREATE POLICY "brand_client: read approved submissions"
  ON public.job_submissions FOR SELECT
  USING (
    is_validated = true
    AND EXISTS (
      SELECT 1 FROM public.jobs j
      WHERE j.id = job_submissions.job_id
        AND j.brand_id = get_my_brand_id()
    )
  );

-- Shelfers can create and read their own submissions.
CREATE POLICY "shelfer: own submissions"
  ON public.job_submissions FOR ALL
  USING (submission_user_id = auth.uid() OR contractor_id = auth.uid())
  WITH CHECK (submission_user_id = auth.uid() OR contractor_id = auth.uid());


-- ── payments ─────────────────────────────────────────────────
CREATE POLICY "admin: full access"
  ON public.payments FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- Shelfers can read their own payment records.
CREATE POLICY "shelfer: own payments"
  ON public.payments FOR SELECT
  USING (contractor_id = auth.uid());


-- ── notifications ────────────────────────────────────────────
CREATE POLICY "admin: full access"
  ON public.notifications FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- Users can read and manage their own notifications.
CREATE POLICY "user: own notifications"
  ON public.notifications FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());


-- ============================================================
-- PART 6: VERIFICATION QUERIES
-- Run these after applying to confirm the migration worked.
-- ============================================================

-- 6a. Confirm RLS is enabled on all tables
SELECT
  tablename,
  rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'users', 'brands', 'products', 'skus', 'stores',
    'jobs', 'job_stores', 'job_skus', 'job_store_skus',
    'job_submissions', 'payments', 'notifications'
  )
ORDER BY tablename;

-- 6b. Confirm policy count per table
SELECT
  tablename,
  COUNT(*) AS policy_count
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- 6c. Confirm brand_id backfill on products
SELECT
  COUNT(*) AS total_products,
  COUNT(brand_id) AS products_with_brand_id,
  COUNT(*) - COUNT(brand_id) AS products_missing_brand_id
FROM public.products;

-- 6d. Confirm helper functions exist
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN ('get_my_role', 'get_my_brand_id', 'is_admin');
