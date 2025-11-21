# Storage Bucket Verification & Setup

## Purpose
Verify that the `job_submissions` storage bucket exists and has proper RLS policies for:
- **Shelfers**: Upload photos when submitting jobs
- **Admins**: Read/view photos when reviewing submissions

---

## Step 1: Check if Bucket Exists

### Via Supabase Dashboard:
1. Go to **Supabase Dashboard** → **Storage**
2. Look for bucket named: `job_submissions`
3. If it exists, note the settings
4. If it doesn't exist, proceed to Step 2

### Via SQL (run in SQL Editor):
```sql
SELECT 
    bucket_id,
    COUNT(*) as object_count
FROM storage.objects
WHERE bucket_id = 'job_submissions'
GROUP BY bucket_id;
```

**Expected Result:**
- If bucket exists: Returns bucket_id and count
- If bucket doesn't exist: Returns no rows

---

## Step 2: Create Bucket (if missing)

### Via Supabase Dashboard:
1. Go to **Storage** → **Create Bucket**
2. Name: `job_submissions`
3. **Public bucket**: ✅ YES (admins need to view photos)
4. **File size limit**: 5MB (or as needed)
5. **Allowed MIME types**: `image/*` (or leave blank for all)

### Via SQL (alternative):
```sql
-- Note: Bucket creation via SQL may require special permissions
-- Dashboard method is recommended
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'job_submissions',
    'job_submissions',
    true,
    5242880,  -- 5MB in bytes
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;
```

---

## Step 3: Set Up RLS Policies

### Policy 1: Shelfers can upload
**Purpose**: Allow shelfers (contractors) to upload photos when submitting jobs

```sql
-- Allow contractors to upload to their own submissions
CREATE POLICY "Contractors can upload job submission photos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'job_submissions' AND
    auth.uid() IN (
        SELECT contractor_id 
        FROM job_submissions 
        WHERE id::text = (storage.foldername(name))[1]
    )
);
```

**Alternative (simpler - allows any authenticated user to upload):**
```sql
CREATE POLICY "Authenticated users can upload job submission photos"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'job_submissions');
```

### Policy 2: Admins can read
**Purpose**: Allow admins to view photos when reviewing submissions

```sql
-- Allow admins to read all job submission photos
CREATE POLICY "Admins can read job submission photos"
ON storage.objects
FOR SELECT
TO authenticated
USING (
    bucket_id = 'job_submissions' AND
    EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid()
        AND users.role = 'admin'
    )
);
```

### Policy 3: Contractors can read their own
**Purpose**: Allow shelfers to view their own uploaded photos

```sql
-- Allow contractors to read their own submission photos
CREATE POLICY "Contractors can read own job submission photos"
ON storage.objects
FOR SELECT
TO authenticated
USING (
    bucket_id = 'job_submissions' AND
    auth.uid() IN (
        SELECT contractor_id 
        FROM job_submissions 
        WHERE id::text = (storage.foldername(name))[1]
    )
);
```

---

## Step 4: Verify Policies

### Check existing policies:
```sql
SELECT 
    policyname,
    cmd as operation,
    qual as using_expression,
    with_check as with_check_expression
FROM pg_policies
WHERE tablename = 'objects'
  AND schemaname = 'storage'
  AND policyname LIKE '%job_submission%';
```

**Expected Result:**
- Should see 2-3 policies (upload, read for admins, read for contractors)

---

## Step 5: Test Upload (Optional)

### Test via Supabase Dashboard:
1. Go to **Storage** → `job_submissions` bucket
2. Try uploading a test image
3. Verify it appears in the bucket

### Test via Code:
The upload should work when a shelfer submits a job from `dashboard/job-details.html`

---

## Troubleshooting

### Issue: "Bucket not found" error
**Solution**: Create bucket (Step 2)

### Issue: "Permission denied" on upload
**Solution**: Check RLS policies (Step 3), ensure user is authenticated

### Issue: "Permission denied" on read
**Solution**: Verify admin role in users table, check read policies

### Issue: Photos not displaying in review page
**Solution**: 
- Check bucket is public
- Verify file paths match what code expects
- Check browser console for errors

---

## File Path Convention

The app expects photos to be stored with paths like:
```
job_submissions/{submission_id}/{photo_type}.jpg
```

Example:
```
job_submissions/abc123-def456/shelf_photo.jpg
job_submissions/abc123-def456/closeup_photo.jpg
```

---

## Next Steps

After verification:
1. ✅ Bucket exists
2. ✅ RLS policies set
3. ✅ Test upload works
4. ✅ Test read works (admin view)

Then proceed with testing the submission review flow.

