# Storage Bucket Setup Instructions

## Quick Setup Guide

The `job_submissions` storage bucket is required for photo uploads when shelfers complete jobs.

### ⚠️ Important
**Storage buckets CANNOT be created via SQL!** You must use the Supabase Dashboard.

---

## Step 1: Create the Bucket (Dashboard)

1. **Go to Supabase Dashboard**
   - Navigate to your project
   - Click **Storage** in the left sidebar
   - Click **Buckets**

2. **Create New Bucket**
   - Click **New bucket** button (top right)
   - **Name:** `job_submissions`
   - **Public bucket:** ✅ **YES** (check this box - photos need to be accessible)
   - **File size limit:** 10MB (or larger if needed)
   - **Allowed MIME types:** `image/*` (or leave empty)
   - Click **Create bucket**

---

## Step 2: Set Up RLS Policies (SQL Editor)

After creating the bucket, go to **SQL Editor** and run:

```sql
-- Copy and paste the contents of setup-job-submissions-bucket.sql
```

Or manually create these policies in **Storage → job_submissions → Policies**:

### Policy 1: Contractors can upload
- **Policy name:** `Contractors can upload job photos`
- **Allowed operation:** INSERT
- **Target roles:** authenticated
- **WITH CHECK expression:**
  ```sql
  bucket_id = 'job_submissions' AND
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'shelfer'
  )
  ```

### Policy 2: Users can read their uploads
- **Policy name:** `Users can read their uploads`
- **Allowed operation:** SELECT
- **Target roles:** authenticated
- **USING expression:**
  ```sql
  bucket_id = 'job_submissions' AND owner = auth.uid()
  ```

### Policy 3: Admins can read all
- **Policy name:** `Admins can read all job photos`
- **Allowed operation:** SELECT
- **Target roles:** authenticated
- **USING expression:**
  ```sql
  bucket_id = 'job_submissions' AND
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'admin'
  )
  ```

---

## Step 3: Verify Setup

1. **Check bucket exists:**
   - Go to **Storage → Buckets**
   - Verify `job_submissions` appears in the list

2. **Check policies:**
   - Go to **Storage → job_submissions → Policies**
   - You should see 4-5 policies listed

3. **Test upload:**
   - Try submitting a test job with photos
   - Check browser console (F12) for any errors
   - Verify photos appear in **Storage → job_submissions → jobs/{job_id}/**

---

## Current Status

✅ **Job submissions work WITHOUT bucket** (fallback to base64 storage)
⚠️ **But bucket is recommended** for:
- Better performance (smaller database)
- Faster photo loading
- Proper photo organization
- Better scalability

---

## Troubleshooting

**Error: "Bucket not found"**
- Bucket hasn't been created yet → Follow Step 1

**Error: "new row violates row-level security policy"**
- RLS policies not set up → Follow Step 2

**Photos upload but can't view them**
- Bucket might not be public → Check "Public bucket" setting
- RLS policies too restrictive → Check Policy 2 and 3

**Photos work for admins but not brands**
- Missing brand client policy → Add Policy 4 from setup script

---

## File Structure

Photos are stored at:
```
job_submissions/
  └── jobs/
      └── {job_id}/
          ├── product_closeup_{timestamp}.jpg
          ├── section_context_{timestamp}.jpg
          └── wide_angle_{timestamp}.jpg
```

Example:
```
job_submissions/jobs/e804a194-3543-4c26-b6f6-5d4cfa126234/product_closeup_1699030123456.jpg
```


