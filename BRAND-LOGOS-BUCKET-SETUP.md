# Brand Logos Storage Bucket Setup

## Problem
The `brand_logos` bucket doesn't exist in Supabase Storage, which is why logos aren't loading.

## Solution: Create the Bucket

### Step 1: Create the Bucket
1. In Supabase Dashboard, go to **Storage** (left sidebar)
2. Click **"+ New bucket"** button
3. Set the bucket name to: `brand_logos` (with underscore, no spaces)
4. **Important settings:**
   - ✅ Check **"Public bucket"** - this allows public access to logo images
   - Leave other settings as default
5. Click **"Create bucket"**

### Step 2: Verify Bucket Settings
After creating, click on the `brand_logos` bucket and verify:
- ✅ It's marked as **Public**
- ✅ You can see the bucket contents (will be empty initially)

### Step 3: Upload Existing Logos (if any)
If you have logo files that were uploaded before, you'll need to re-upload them:
1. Go to the brand onboarding form
2. Select the brand
3. Upload the logo file again
4. The new upload will save to the correct bucket

### Step 4: Test
After creating the bucket:
1. Go back to `/admin/brands.html`
2. Refresh the page
3. Logos should now load (if files were uploaded)

## Alternative: Check for Existing Bucket
The bucket might exist with a different name:
- Check for `brand logos` (with space instead of underscore)
- Check for any other variations

If you find an existing bucket with logos, we can either:
1. Rename it to `brand_logos` (recommended)
2. Update the code to use the existing bucket name


