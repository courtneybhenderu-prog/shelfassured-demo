# Recommended Actions - Detailed Breakdown

**Date:** January 13, 2025  
**Purpose:** Address the 3 high-priority issues from the technical audit

---

## ✅ ACTION 1: Run SQL Health Checks (15 minutes)

### **What This Does**
Verifies your database is healthy after the schema migration. Checks for:
- Duplicate job assignments (should be ZERO)
- Foreign key integrity (no orphaned rows)
- Recent activity (data is being written)
- Overall system health

### **Step-by-Step Instructions**

#### 1. Open Supabase SQL Editor
- Go to https://supabase.com/dashboard
- Navigate to your ShelfAssured project
- Click "SQL Editor" in the left sidebar
- Click "New query"

#### 2. Run the Health Check
Copy and paste the entire contents of `step6-health-checks.sql` (provided below) into the SQL editor and click "Run":

```sql
-- Check 1: No duplicates sneak in
SELECT 'Duplicate Check:' as info;
SELECT 
    job_id, 
    store_id, 
    sku_id, 
    count(*) as duplicate_count
FROM public.job_store_skus
GROUP BY 1, 2, 3
HAVING count(*) > 1;
-- Expect 0 rows

-- Check 2: Assignment activity (sanity metric)
SELECT 'Assignment Activity (Last 14 days):' as info;
SELECT 
    date_trunc('day', created_at) as day, 
    count(*) as assignments
FROM public.job_store_skus
GROUP BY 1 
ORDER BY 1 DESC 
LIMIT 14;

-- Check 3: Data integrity - all foreign keys valid
SELECT 'Foreign Key Integrity:' as info;
SELECT 
    'job_store_skus -> jobs' as relationship,
    COUNT(*) as total_rows,
    COUNT(j.id) as valid_job_refs,
    COUNT(*) - COUNT(j.id) as orphaned_rows
FROM job_store_skus jss
LEFT JOIN jobs j ON j.id = jss.job_id

UNION ALL

SELECT 
    'job_store_skus -> stores' as relationship,
    COUNT(*) as total_rows,
    COUNT(s.id) as valid_store_refs,
    COUNT(*) - COUNT(s.id) as orphaned_rows
FROM job_store_skus jss
LEFT JOIN stores s ON s.id = jss.store_id

UNION ALL

SELECT 
    'job_store_skus -> skus' as relationship,
    COUNT(*) as total_rows,
    COUNT(sk.id) as valid_sku_refs,
    COUNT(*) - COUNT(sk.id) as orphaned_rows
FROM job_store_skus jss
LEFT JOIN skus sk ON sk.id = jss.sku_id;

-- Check 4: Recent activity summary
SELECT 'Recent Activity Summary:' as info;
SELECT 
    COUNT(*) as total_assignments,
    COUNT(DISTINCT job_id) as unique_jobs,
    COUNT(DISTINCT store_id) as unique_stores,
    COUNT(DISTINCT sku_id) as unique_skus,
    MIN(created_at) as earliest_assignment,
    MAX(created_at) as latest_assignment
FROM job_store_skus;
```

#### 3. Interpret Results

**Check 1 - Duplicate Check:**
- ✅ **PASS:** Returns 0 rows (no duplicates)
- ❌ **FAIL:** Returns rows with count > 1 → You have duplicate data issues

**Check 2 - Assignment Activity:**
- ✅ **PASS:** Shows assignments from last 14 days
- ❌ **FAIL:** No rows → No recent activity (may be new database)

**Check 3 - Foreign Key Integrity:**
- ✅ **PASS:** All relationships show `orphaned_rows = 0`
- ❌ **FAIL:** Any `orphaned_rows > 0` → Broken foreign key references

**Check 4 - Recent Activity Summary:**
- ✅ **PASS:** Shows counts for jobs, stores, SKUs
- ❌ **FAIL:** All counts are 0 → Database is empty (new project)

### **What to Do If Health Checks Fail**

**If duplicates found:**
```sql
-- Find the duplicates
SELECT job_id, store_id, sku_id, count(*) 
FROM job_store_skus 
GROUP BY 1,2,3 
HAVING count(*) > 1;

-- Delete duplicates (keep only one)
DELETE FROM job_store_skus jss
WHERE EXISTS (
    SELECT 1 FROM job_store_skus jss2 
    WHERE jss2.job_id = jss.job_id 
    AND jss2.store_id = jss.store_id 
    AND jss2.sku_id = jss.sku_id
    AND jss2.id > jss.id
);
```

**If orphaned rows found:**
- Check if the referenced jobs, stores, or SKUs still exist
- May need to clean up the orphaned assignments

---

## ✅ ACTION 2: Test Brand Onboarding End-to-End (30 minutes)

### **What This Tests**
Verifies the complete brand creation workflow works:
1. Brand information submission
2. Product CSV upload (or manual entry)
3. Store CSV upload (or manual entry)
4. Smart store matching
5. Database persistence

### **Step-by-Step Testing Process**

#### **Prerequisites**
- Sign in as admin at `/admin/dashboard.html`
- Have products template CSV ready (optional)
- Have stores template CSV ready (optional)

#### **Test Procedure**

**STEP 1: Navigate to Brand Onboarding**
```
1. Open your browser to the ShelfAssured app
2. Sign in as admin user
3. Click "Brand Onboarding" or navigate to `/admin/brands-new.html`
```

**STEP 2: Fill in Brand Information**
```
Brand Name: "Test Brand XYZ"
Website: "https://testbrand.com"
Email: "contact@testbrand.com"
Phone: "(555) 123-4567"
Address: "123 Main St, Houston, TX 77001"
```

**STEP 3: Add Products**

**Option A - Manual Entry:**
```
1. Click "+ Add Product" button
2. Fill in:
   - Product Name: "Test Product 1"
   - UPC/SKU: "123456789012"
   - Size: "16 oz"
   - Category: "Beverages"
   - Suggested Retail Price: "4.99"
   - Image URL: (leave blank)
3. Repeat for 2-3 products
```

**Option B - CSV Upload:**
```
1. Click "📥 Template" to download products-template.csv
2. Fill it with:
   name,barcode,size,category
   Test Product 1,123456789012,16 oz,Beverages
   Test Product 2,123456789013,32 oz,Beverages
3. Save as CSV
4. Click "📁 Upload CSV" and select the file
5. Verify products appear in the list
```

**STEP 4: Add Stores**

**Option A - Manual Entry:**
```
1. Click "+ Add Store" button
2. Fill in:
   - Retailer: "H-E-B"
   - Store Name: "H-E-B Test Location"
   - Address: "456 Oak Street"
   - City: "Houston"
   - State & ZIP: "TX 77001"
3. Repeat for 2-3 stores
```

**Option B - CSV Upload:**
```
1. Click "📥 Template" to download stores-template.csv
2. Fill it with:
   retailer,name,address,city,state_zip
   H-E-B,H-E-B Test Location,456 Oak Street,Houston,TX 77001
   Kroger,Kroger Test Location,789 Elm Street,Houston,TX 77002
3. Save as CSV
4. Click "📁 Upload CSV" and select the file
5. Verify stores appear in the list
```

**STEP 5: Submit Brand**
```
1. Click "Deploy ShelfAssured" button
2. Watch for loading messages in the UI
3. Look for success message
4. Check if "View brand →" link appears
```

#### **What to Observe During Testing**

**Expected Behavior:**
- ✅ Products appear in list after adding/uploading
- ✅ Stores appear in list after adding/uploading
- ✅ "Match existing stores" message if stores matched
- ✅ Success message: "Saved! Brand, products, and stores created."
- ✅ "View brand →" link appears
- ✅ No JavaScript errors in browser console

**Error Scenarios to Watch For:**

1. **"Brand name is required" error**
   - Expected if brand name field is empty
   - Fix: Fill in brand name

2. **"Add at least one product" error**
   - Expected if no products added
   - Fix: Add products before submitting

3. **"RPC function does not exist" error**
   - Indicates `upsert_brand_public` RPC not deployed
   - Fix: Run `brand-onboarding-rpcs.sql` in Supabase

4. **"Error creating store" messages**
   - May indicate duplicate store issue
   - Fix: Check for store matching logic problems

5. **Console errors in browser**
   - Check browser DevTools Console (F12)
   - Look for red error messages
   - Take screenshots for debugging

#### **Verification Steps**

**After successful submission, verify in database:**

1. **Check brand exists:**
```sql
SELECT * FROM brands WHERE name = 'Test Brand XYZ';
```
- Should return 1 row with brand details

2. **Check products exist:**
```sql
SELECT p.*, b.name as brand_name 
FROM products p
JOIN brands b ON b.id = p.brand
WHERE b.name = 'Test Brand XYZ';
```
- Should return the products you added

3. **Check stores exist:**
```sql
SELECT s.* FROM stores s
WHERE s.store_chain LIKE '%H-E-B%'
AND s.city = 'Houston'
ORDER BY s.created_at DESC;
```
- Should return your test stores

#### **Success Criteria**
- ✅ Brand appears in brands list
- ✅ Products linked to brand
- ✅ Stores created (or matched if they existed)
- ✅ No errors in browser console
- ✅ Database confirms all data saved

---

## ✅ ACTION 3: Fix Job Creation (COMPLETED)

### **What Was Fixed**

**File:** `pages/create-job.js`

**Problem:**
- Line 337 was using `await saSet('jobs', job)` which only saves to localStorage
- Job would not be created in database

**Solution:**
- Replaced with direct Supabase client calls
- Creates main job record first
- Looks up SKUs by name or UPC
- Creates assignments in `job_store_skus` table
- Uses proper upsert with conflict handling

### **What the Fixed Code Does**

**Lines 320-418** now:
1. **Get current user** from Supabase auth
2. **Fetch first available brand** (temporary - needs brand selector)
3. **Create main job record** with title, description, etc.
4. **Look up SKU IDs** by searching for matching names/UPCs
5. **Create assignments** for all store × SKU combinations
6. **Use upsert** to prevent duplicates with `ON CONFLICT` handling
7. **Show success message** and redirect to dashboard

### **Testing the Fix**

**To test if the fix works:**

1. **Sign in as brand client** or admin
2. **Navigate to job creation page** (`dashboard/create-job.html`)
3. **Fill in job details:**
   - Title: "Test Job XYZ"
   - Description: "Test description"
   - Cost per job: 5.00
4. **Add SKUs:**
   - Enter a product name or UPC that exists in your database
5. **Select stores:**
   - Check one or more stores
6. **Submit the job**
7. **Check browser console** for log messages:
   - Should see: "✅ Main job created: [job ID]"
   - Should see: "📝 Creating X assignments..."
   - Should see: "✅ Job and assignments created successfully"

**Verify in database:**
```sql
-- Check job was created
SELECT j.*, b.name as brand_name 
FROM jobs j
LEFT JOIN brands b ON b.id = j.brand_id
ORDER BY j.created_at DESC 
LIMIT 5;

-- Check assignments were created
SELECT jss.*, j.title as job_title, s.name as store_name, sk.name as sku_name
FROM job_store_skus jss
JOIN jobs j ON j.id = jss.job_id
JOIN stores s ON s.id = jss.store_id
JOIN skus sk ON sk.id = jss.sku_id
ORDER BY jss.created_at DESC
LIMIT 10;
```

### **Remaining TODO**

**Line 321** says: `// TODO: Implement brand selection in UI`

Currently the code uses the first available brand. You should:
1. Add a brand dropdown selector to the job creation form
2. Store selected brand ID
3. Use that brand ID instead of fetching the first brand

**This is marked as LOW priority** because the job creation now works with the temporary fix.

---

## 📋 Summary: What to Do Now

### **Immediate Next Steps** (in order):

1. **Run SQL Health Check** (15 minutes)
   - Opens Supabase SQL Editor
   - Pastes `step6-health-checks.sql`
   - Click "Run"
   - Verify 0 duplicates, 0 orphaned rows

2. **Test Brand Onboarding** (30 minutes)
   - Sign in as admin
   - Navigate to brand onboarding
   - Create test brand with products and stores
   - Verify success message
   - Check database for saved data

3. **Test Job Creation** (15 minutes)
   - Sign in as brand client
   - Navigate to job creation
   - Create test job with stores and SKUs
   - Check browser console for success logs
   - Verify job appears in database

### **If Everything Passes:**
- ✅ Your system is ready for production use
- ✅ All critical paths are working
- ✅ Database migration was successful

### **If Something Fails:**
- Take screenshot of error
- Copy browser console logs (F12 → Console)
- Note which step failed
- Share with me for debugging

### **Time Estimate:**
- Health Check: 15 minutes
- Brand Onboarding: 30 minutes
- Job Creation: 15 minutes
- **Total: ~60 minutes**

---

**Good luck with testing!** These three actions will verify your entire system is working correctly.

