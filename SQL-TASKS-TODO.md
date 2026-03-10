# SQL Tasks — Run in Supabase SQL Editor

These SQL scripts need to be run in your Supabase SQL Editor to fix the
Brand Hub and Shelfer Hub data loading issues. Run them **in order**.

---

## TASK 1 — Fix RLS so admins can read all users and brands (CRITICAL)

**Why:** The `users` table has RLS enabled with a policy that only lets each
user see their own row. Admins need to see all rows. This is why Brand Hub
shows 0 brands and Shelfer Hub shows 0 shelfers.

**File in repo:** `session3-rls-migration.sql`

Run the full contents of `session3-rls-migration.sql` in the Supabase SQL
editor. It is idempotent (safe to run multiple times).

**What it does:**
- Creates `is_admin()`, `get_my_role()`, `get_my_brand_id()` helper functions
  using `SECURITY DEFINER` (bypasses RLS safely)
- Drops all old conflicting policies
- Creates correct 3-tier RLS: Admin (full access), Brand Client (own brand),
  Shelfer (limited read)

---

## TASK 2 — Set admin role in JWT app_metadata (CRITICAL)

**Why:** The `is_admin()` function in `session3-rls-migration.sql` checks the
`users` table using SECURITY DEFINER. But `fix-rls-policies-proper.sql` uses a
JWT-based check. Make sure your admin user's `app_metadata` has `role: admin`
set in Supabase Auth.

**Steps:**
1. Go to Supabase Dashboard → Authentication → Users
2. Find your admin account (courtney@beshelfassured.com or similar)
3. Click the user → Edit → set `app_metadata` to: `{"role": "admin"}`
4. Save

---

## TASK 3 — Verify brands table has correct is_shadow values

**Why:** Brand Hub "Total Brands" was showing 0 because it was filtering
`is_shadow = false` but all brands may have `is_shadow = true` or `null`.

Run this to check:

```sql
SELECT 
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE is_shadow = false OR is_shadow IS NULL) as client_brands,
  COUNT(*) FILTER (WHERE is_shadow = true) as shadow_brands
FROM brands;
```

If all brands show as shadow, run:

```sql
-- Update brands that have paying users to is_shadow = false
UPDATE brands b
SET is_shadow = false
WHERE EXISTS (
  SELECT 1 FROM users u 
  WHERE u.brand_id = b.id 
  AND u.role = 'brand_client'
);
```

---

## TASK 4 — Verify shelfer role values in users table

**Why:** Shelfer Hub queries for `role = 'shelfer'` but some users may have
`role = 'contractor'` or another value.

Run this to check what role values exist:

```sql
SELECT role, COUNT(*) as count 
FROM users 
GROUP BY role 
ORDER BY count DESC;
```

If shelfers have a different role value (e.g., `contractor`), either:
- Update the role values: `UPDATE users SET role = 'shelfer' WHERE role = 'contractor';`
- Or note the actual value so the code can be updated to match.

---

## TASK 5 — Add pipeline_stage column to brands if missing

**Why:** Brand Hub uses `pipeline_stage` column for the pipeline status
dropdown. If this column doesn't exist, the All Brands tab will show errors.

```sql
ALTER TABLE public.brands 
ADD COLUMN IF NOT EXISTS pipeline_stage TEXT DEFAULT 'prospect';

-- Update shadow brands to 'scanned' stage
UPDATE public.brands 
SET pipeline_stage = 'scanned' 
WHERE is_shadow = true AND pipeline_stage IS NULL;
```

---

## TASK 6 — Verify scan_events table structure for photo gallery

**Why:** The scan-intelligence photo gallery queries `scan_events` for
`photo_url` field. Verify the column exists:

```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'scan_events' 
ORDER BY ordinal_position;
```

---

## TASK 7 — Create product-photos Storage Bucket (fixes Upload Photo on brand dashboard)

**Why:** The "Upload Photo" button on the brand client dashboard fails if the `product-photos` storage bucket doesn't exist.

**Steps:**
1. Go to Supabase Dashboard → Storage
2. Click "New bucket"
3. Name it exactly: `product-photos`
4. Set it to **Public**
5. Click Save

**Then run this SQL:**

```sql
-- Allow authenticated users to upload to product-photos bucket
CREATE POLICY IF NOT EXISTS "Authenticated users can upload product photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'product-photos');

-- Allow public read access
CREATE POLICY IF NOT EXISTS "Public can view product photos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'product-photos');

-- Allow users to update their own uploads
CREATE POLICY IF NOT EXISTS "Authenticated users can update product photos"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'product-photos');
```

---

## TASK 8 — Flip Oh Sugar! from shadow to client brand (for demo)

**Why:** Oh Sugar! exists in the `brands` table with `is_shadow = true`, which means it shows up as a shadow/intelligence brand rather than a client brand. For the Marc demo, flip it to a client brand so it appears cleanly in Brand Hub and doesn't trigger the "new brand detected" alert during scans.

```sql
UPDATE brands 
SET is_shadow = false 
WHERE id = 'a29d005d-e3c1-435c-b3d8-bfb79c433900';
```

**Confirmed:** Oh Sugar! exists in the database with the exact name `Oh Sugar!` — the scanner's brand detection was working correctly all along. The flag was accurate (it IS a shadow brand). This task just promotes it to client status for the demo.

---

## Summary Checklist

| # | Task | Priority | Status |
|---|------|----------|--------|
| 1 | Run `session3-rls-migration.sql` | 🔴 Critical | Pending |
| 2 | Set admin `app_metadata` `{"role": "admin"}` in Supabase Auth | 🔴 Critical | Pending |
| 3 | Verify `is_shadow` values on brands | 🟡 High | Pending |
| 4 | Check shelfer role values in users table | 🟡 High | Pending |
| 5 | Add `pipeline_stage` column to brands | 🟠 Medium | Pending |
| 6 | Verify `scan_events` table structure | 🟢 Low | Pending |
| 7 | Create `product-photos` storage bucket | 🟡 High | Pending |
| 8 | Flip Oh Sugar! to `is_shadow = false` for demo | 🟡 High | Pending |

---

*Generated: March 10, 2026 — Run these after returning from your day out.*
