# Job Submission Troubleshooting Guide

## Issue: "Bucket" Error When Submitting Job

**Symptoms:**
- Error message mentioning "bucket" appears briefly when clicking "Submit for review"
- Job doesn't appear in completed jobs
- Job submission seems to fail silently

**Root Cause:**
The job submission process tries to upload photos to a Supabase Storage bucket called `job_submissions`. If this bucket doesn't exist or has RLS policies blocking uploads, the submission fails.

## Troubleshooting Steps

### Step 1: Check if `job_submissions` bucket exists

1. Go to Supabase Dashboard → Storage
2. Look for a bucket named `job_submissions`
3. If it doesn't exist, you need to create it

### Step 2: Create the bucket (if missing)

**In Supabase Dashboard:**
1. Go to **Storage** → **Buckets**
2. Click **New bucket**
3. Name: `job_submissions`
4. Make it **Public** (so photos can be accessed)
5. Click **Create bucket**

### Step 3: Set up RLS policies for the bucket

**The bucket needs policies to allow:**
- Contractors to upload photos
- Admins to read photos
- Brands to read their own job photos

**Create these policies in Supabase Dashboard → Storage → job_submissions → Policies:**

#### Policy 1: Allow contractors to upload
```sql
-- Allow authenticated users with contractor role to upload
CREATE POLICY "Contractors can upload job photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'job_submissions' AND
  EXISTS (
    SELECT 1 FROM users
    WHERE users.id = auth.uid()
    AND users.role = 'shelfer'
  )
);
```

#### Policy 2: Allow users to read their own uploads
```sql
-- Allow users to read photos they uploaded
CREATE POLICY "Users can read their uploads"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'job_submissions'
);
```

#### Policy 3: Allow admins to read all
```sql
-- Allow admins to read all job photos
CREATE POLICY "Admins can read all job photos"
ON storage.objects FOR SELECT
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

### Step 4: Improve Error Visibility (Code Fix)

The error message disappears too quickly. We need to:
1. Make error messages stay visible longer
2. Prevent auto-redirect if there's an error
3. Show full error details in console and on screen

### Step 5: Verify Job Submission Table

Check if `job_submissions` table exists and has proper structure:
- Table should exist in Supabase
- Should have columns: `job_id`, `contractor_id`, `submission_type`, `data`, `files`

## Quick Fix: Check Browser Console

When the error appears:
1. Open browser Developer Tools (F12)
2. Go to **Console** tab
3. Look for errors starting with "❌ Storage upload error:" or "❌ Error submitting job:"
4. Copy the full error message
5. Share it for troubleshooting

## Expected Behavior After Fix

After bucket is set up correctly:
1. Photos upload to `job_submissions/jobs/{job_id}/{filename}`
2. Job submission record created in `job_submissions` table
3. Job status updated to `pending_review`
4. Success message shows
5. Job appears in brand dashboard

## Temporary Workaround

If bucket setup is delayed, the code has a fallback that:
- Stores photos as base64 in the `files` JSONB column
- Still creates the job submission record
- Shows a warning about storage bucket needing setup

But this should only be temporary - photos stored as base64 are much larger and less efficient.


