# Help & Support Page - Troubleshooting Checklist

## ✅ What We've Completed

1. **Built the Help & Support page** (`admin/help-support.html`)
   - Full UI with filters, request list, response modal
   - All functionality implemented (respond, resolve, close, mark in progress)

2. **Created the database table** (`setup-help-requests-table.sql`)
   - Table structure verified ✅
   - All columns present ✅

3. **Fixed the query** (simplified joins, better error handling)

## ❌ Current Issue

**Error:** "Error loading help requests. Check console for details."

The page is still showing an error when trying to load help requests, even though the table exists.

## 🔍 Troubleshooting Steps (When You Return)

### Step 1: Check Browser Console
1. Open the Help & Support page
2. Press `F12` (or right-click → Inspect)
3. Go to the **Console** tab
4. Look for error messages (usually red)
5. **Copy the exact error message** - this will tell us what's wrong

### Step 2: Check RLS Policies
The error might be due to Row Level Security (RLS) blocking the query.

**In Supabase SQL Editor, run this:**
```sql
-- Check if RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'help_requests';

-- Check existing policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'help_requests';
```

**If policies are missing or incorrect, run this fix:**
```sql
-- Ensure admin policy exists and works
DROP POLICY IF EXISTS "Admins can view all help requests" ON help_requests;
CREATE POLICY "Admins can view all help requests" ON help_requests
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = auth.uid() 
            AND users.role = 'admin'
        )
    );
```

### Step 3: Test Direct Query
**In Supabase SQL Editor, test if you can query the table:**
```sql
-- Test query (should return empty array if no requests exist)
SELECT * FROM help_requests LIMIT 10;
```

**If this fails**, the table might not be fully set up or there's a permission issue.

### Step 4: Check User Authentication
The page checks if you're an admin. Verify:
1. You're logged in as an admin user
2. Your user has `role = 'admin'` in the `users` table

**Check your user role:**
```sql
-- Check your user role (replace with your email)
SELECT id, email, full_name, role 
FROM users 
WHERE email = 'your-email@example.com';
```

### Step 5: Test with Sample Data
**Insert a test request to see if the issue is with empty data:**
```sql
-- Get your user ID first
SELECT id FROM users WHERE role = 'admin' LIMIT 1;

-- Then insert test request (replace 'YOUR_USER_ID' with actual UUID)
INSERT INTO help_requests (user_id, subject, message, priority, status)
VALUES (
    'YOUR_USER_ID',  -- Replace with your user ID
    'Test Request',
    'This is a test message',
    'medium',
    'open'
);
```

### Step 6: Check Supabase Client Configuration
Verify the Supabase client is configured correctly in the page:
- Check `shared/api.js` exists and has correct Supabase URL/key
- Check browser console for Supabase connection errors

## 🛠️ Common Fixes

### Fix 1: RLS Policy Issue
If RLS is blocking admin access, temporarily disable it for testing:
```sql
-- TEMPORARY: Disable RLS for testing (re-enable after!)
ALTER TABLE help_requests DISABLE ROW LEVEL SECURITY;

-- Test the page again

-- Re-enable RLS after testing
ALTER TABLE help_requests ENABLE ROW LEVEL SECURITY;
```

### Fix 2: Foreign Key Issue
If `user_id` foreign key is causing issues:
```sql
-- Check foreign key constraint
SELECT 
    tc.constraint_name, 
    tc.table_name, 
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'help_requests' 
  AND tc.constraint_type = 'FOREIGN KEY';
```

### Fix 3: Users Table Reference
The query tries to join with `users` table. Verify:
```sql
-- Check if users table exists and has the right columns
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND column_name IN ('id', 'full_name', 'email', 'role');
```

## 📋 What to Report Back

When you return, please provide:
1. **Exact error message from browser console** (F12 → Console)
2. **Results of RLS policy check** (Step 2)
3. **Results of direct query test** (Step 3)
4. **Your user role** (Step 4)
5. **Any other errors or warnings** in the console

## 🎯 Expected Behavior

Once fixed, the page should:
- Load without errors (even with 0 requests)
- Show "No Help Requests Found" message when empty
- Display requests when they exist
- Allow filtering, responding, resolving, etc.

## 📝 Notes

- The table structure is correct ✅
- The page code is correct ✅
- The issue is likely RLS policies or authentication ✅
- Most common fix: Update RLS policies to allow admin access

---

**Last Updated:** After creating help_requests table
**Status:** Table created, page shows error (likely RLS/auth issue)


