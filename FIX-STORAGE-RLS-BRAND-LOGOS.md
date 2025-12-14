# Fix Storage RLS for brand_logos Bucket

## Problem
Logo uploads fail with error: **"new row violates row-level security policy"**

This means the `brand_logos` storage bucket has RLS enabled but no policy allows authenticated users to upload files.

## Solution: Add Storage Bucket Policies

Storage bucket policies **cannot** be created via SQL - they must be set in the Supabase Dashboard.

### Step-by-Step Instructions:

1. **Go to Supabase Dashboard → Storage**
2. **Click on the `brand_logos` bucket** (or create it if it doesn't exist)
3. **Click the "Policies" tab** (next to "Files")
4. **Click "New Policy"** button

### Policy 1: Allow Authenticated Users to Upload

- **Policy name:** `Allow authenticated uploads`
- **Allowed operation:** `INSERT`
- Click **"For full customization"**
- **Policy definition** (paste this):
  ```sql
  (bucket_id = 'brand_logos'::text)
  ```
- **WITH CHECK expression** (same):
  ```sql
  (bucket_id = 'brand_logos'::text)
  ```
- Click **"Review"** then **"Save policy"**

### Policy 2: Allow Public Reads (if bucket is public)

- **Policy name:** `Allow public reads`
- **Allowed operation:** `SELECT`
- Click **"For full customization"**
- **Policy definition**:
  ```sql
  (bucket_id = 'brand_logos'::text)
  ```
- Click **"Save policy"**

### Policy 3: Allow Authenticated Users to Update/Replace

- **Policy name:** `Allow authenticated updates`
- **Allowed operation:** `UPDATE`
- Click **"For full customization"**
- **Policy definition**:
  ```sql
  (bucket_id = 'brand_logos'::text)
  ```
- **WITH CHECK expression** (same):
  ```sql
  (bucket_id = 'brand_logos'::text)
  ```
- Click **"Save policy"**

### Policy 4: Allow Authenticated Users to Delete (optional)

- **Policy name:** `Allow authenticated deletes`
- **Allowed operation:** `DELETE`
- Click **"For full customization"**
- **Policy definition**:
  ```sql
  (bucket_id = 'brand_logos'::text)
  ```
- Click **"Save policy"**

## Verify

After adding policies:
1. Try uploading a logo again in `/admin/brands-new.html`
2. The upload should succeed without the RLS error
3. The logo should appear on brand dashboards

## Quick Alternative: Use Public Bucket

If the bucket is marked as **Public**, you may only need the SELECT policy. However, for uploads you still need the INSERT policy.


