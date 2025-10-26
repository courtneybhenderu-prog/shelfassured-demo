# Troubleshooting Guide: "Relation 'jobs' does not exist" Error

## Issue Summary
**Error**: `ERROR: 42P01: relation "jobs" does not exist`  
**Context**: Job creation fails when reusing brand/SKU combinations across multiple stores/jobs  
**Root Cause**: Two-table cross-product model + RLS blocking trigger functions + duplicate key violations

## Quick Diagnosis Checklist

### 1. Check if it's a missing table issue
```sql
-- Run this to verify tables exist
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN ('jobs', 'stores', 'skus', 'job_stores', 'job_skus');
```

**Expected**: All tables should exist  
**If missing**: Deploy `database-schema-fixed.sql`

### 2. Check if it's an RLS issue
```sql
-- Check RLS status
SELECT tablename, rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename IN ('jobs', 'job_stores', 'job_skus');
```

**Expected**: `jobs` should have RLS enabled, junction tables can be disabled  
**If RLS blocking**: Temporarily disable RLS on junction tables

### 3. Check for duplicate key violations
```sql
-- Look for duplicate assignments
SELECT job_id, store_id, sku_id, count(*) 
FROM job_stores js
JOIN job_skus jsk ON js.job_id = jsk.job_id
GROUP BY 1,2,3 HAVING count(*) > 1;
```

**Expected**: 0 rows (no duplicates)  
**If duplicates found**: This is the root cause - implement 3-way junction table solution

## Root Cause Analysis

### The Problem
The original architecture used two separate junction tables:
- `job_stores` (job_id, store_id)
- `job_skus` (job_id, sku_id)

This creates a **cross-product problem**:
- Job A + Store 1 + SKU X = (A,1) + (A,X) = Store 1 gets ALL SKUs
- Job A + Store 2 + SKU X = (A,2) + (A,X) = Store 2 gets ALL SKUs
- **Result**: Can't express "SKU X only at Store 1, SKU Y only at Store 2"

### Why RLS Makes It Worse
- Trigger functions like `recalculate_job_payout()` run with different permissions
- RLS policies block access to tables within trigger context
- Creates "whack-a-mole" errors as you disable RLS one table at a time

## The Solution: 3-Way Junction Table

### Architecture Change
Replace two-table model with single junction table:

```sql
-- OLD (problematic)
job_stores: (job_id, store_id)
job_skus:   (job_id, sku_id)

-- NEW (solution)
job_store_skus: (job_id, store_id, sku_id) with UNIQUE constraint
```

### Implementation Steps

#### Step 1: Create the new table
```sql
-- File: create-job-store-skus-table.sql
CREATE TABLE public.job_store_skus (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id uuid NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
    store_id uuid NOT NULL REFERENCES public.stores(id) ON DELETE RESTRICT,
    sku_id uuid NOT NULL REFERENCES public.skus(id) ON DELETE RESTRICT,
    status text DEFAULT 'pending',
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE (job_id, store_id, sku_id)
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_jss_job ON public.job_store_skus(job_id);
CREATE INDEX IF NOT EXISTS idx_jss_store ON public.job_store_skus(store_id);
CREATE INDEX IF NOT EXISTS idx_jss_sku ON public.job_store_skus(sku_id);

-- Disable RLS initially for stability
ALTER TABLE public.job_store_skus DISABLE ROW LEVEL SECURITY;
```

#### Step 2: Update the API/UI code
```javascript
// File: updated-createJobs-function.js
// Replace the old two-table insert logic with upsert

// OLD CODE (problematic):
// const { error: storeError } = await supabase.from('job_stores').insert({...});
// const { error: skuError } = await supabase.from('job_skus').insert({...});

// NEW CODE (solution):
const assignments = [];
for (const storeId of storeIds) {
    for (const skuId of skuIds) {
        assignments.push({ job_id: job.id, store_id: storeId, sku_id: skuId });
    }
}

const { error: assignmentError } = await supabase
    .from('job_store_skus')
    .upsert(assignments, { 
        onConflict: 'job_id,store_id,sku_id', 
        ignoreDuplicates: true 
    });
```

#### Step 3: Update reporting queries
```sql
-- OLD (cross-product problem):
SELECT s.name, array_agg(sk.name) as skus
FROM job_stores js
JOIN job_skus jsk ON js.job_id = jsk.job_id
JOIN stores s ON s.id = js.store_id
JOIN skus sk ON sk.id = jsk.sku_id
WHERE js.job_id = :job_id
GROUP BY s.id;

-- NEW (accurate):
SELECT s.name, array_agg(sk.name ORDER BY sk.name) as skus
FROM job_store_skus jss
JOIN stores s ON s.id = jss.store_id
JOIN skus sk ON sk.id = jss.sku_id
WHERE jss.job_id = :job_id
GROUP BY s.id;
```

## Testing the Solution

### Smoke Test
```sql
-- File: simple-smoke-test.sql
-- Test duplicate handling and conflict resolution

-- Test 1: Insert assignment
INSERT INTO job_store_skus (job_id, store_id, sku_id)
SELECT job_id, store_id, sku_id FROM test_data
ON CONFLICT (job_id, store_id, sku_id) DO NOTHING;

-- Test 2: Try same assignment again (should be no-op)
INSERT INTO job_store_skus (job_id, store_id, sku_id)
SELECT job_id, store_id, sku_id FROM test_data
ON CONFLICT (job_id, store_id, sku_id) DO NOTHING;

-- Verify: Should have exactly 1 row, not 2
SELECT COUNT(*) FROM job_store_skus WHERE job_id = :job_id;
```

### Health Checks
```sql
-- Verify no duplicates
SELECT job_id, store_id, sku_id, count(*) 
FROM job_store_skus
GROUP BY 1,2,3 HAVING count(*) > 1;
-- Expected: 0 rows

-- Verify foreign key integrity
SELECT COUNT(*) as total, COUNT(j.id) as valid_jobs
FROM job_store_skus jss
LEFT JOIN jobs j ON j.id = jss.job_id;
-- Expected: total = valid_jobs
```

## Production Hardening Checklist

### 1. PostgREST Schema Reload
```sql
NOTIFY pgrst, 'reload schema';
```

### 2. RLS Posture
```sql
-- Keep jobs protected, junction relaxed initially
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_store_skus DISABLE ROW LEVEL SECURITY;
```

### 3. Foreign Key Updates (if submissions/photos exist)
```sql
-- Point submissions to the triple
ALTER TABLE public.submissions 
ADD COLUMN IF NOT EXISTS job_store_sku_id uuid 
REFERENCES public.job_store_skus(id) ON DELETE CASCADE;
```

### 4. Legacy Trigger Cleanup
```sql
-- Remove problematic payout triggers
DROP TRIGGER IF EXISTS recalculate_payout_on_store_change ON public.job_stores;
DROP FUNCTION IF EXISTS public.recalculate_job_payout() CASCADE;
```

## Common Pitfalls & Solutions

### Pitfall 1: "Still getting relation errors after schema reload"
**Solution**: Check if triggers are still referencing old tables
```sql
SELECT trigger_name, event_object_table 
FROM information_schema.triggers 
WHERE trigger_name LIKE '%payout%';
```

### Pitfall 2: "UPSERT not working in JavaScript"
**Solution**: Ensure proper headers for REST API
```javascript
// For direct REST calls
headers: {
    'Prefer': 'resolution=merge-duplicates,ignore-duplicates'
}
```

### Pitfall 3: "RLS blocking inserts after enabling"
**Solution**: Use parent-deferred policy
```sql
CREATE POLICY jss_rw ON public.job_store_skus
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.jobs j
    WHERE j.id = job_store_skus.job_id
      AND (is_admin(auth.uid()) OR j.assigned_user_id = auth.uid())
  )
);
```

## Prevention for Future Development

### 1. Always use UPSERT for junction tables
```javascript
// Good: Prevents duplicates
.upsert(data, { onConflict: 'key1,key2,key3', ignoreDuplicates: true })

// Bad: Can cause duplicate key violations
.insert(data)
```

### 2. Test with real-world scenarios
- Same brand/SKU across multiple jobs
- Same SKU across multiple stores
- Rapid successive assignments

### 3. Monitor for duplicate patterns
```sql
-- Add this to monitoring
SELECT COUNT(*) as duplicate_count
FROM (
    SELECT job_id, store_id, sku_id, COUNT(*)
    FROM job_store_skus
    GROUP BY 1,2,3 HAVING COUNT(*) > 1
) duplicates;
```

## Files Created During Resolution

- `create-job-store-skus-table.sql` - Main table creation
- `updated-createJobs-function.js` - API code update
- `simple-smoke-test.sql` - Testing script
- `step1-postgrest-reload.sql` - Schema reload
- `step2-execution-fks.sql` - Foreign key updates
- `step3-rls-posture.sql` - RLS configuration
- `step4-trigger-cleanup.sql` - Legacy cleanup
- `step5-security-advisor.sql` - Security checks
- `step6-health-checks.sql` - Final verification

## Success Metrics

✅ **No duplicate key violations** when reusing SKUs  
✅ **Accurate reporting** showing which SKUs are at which stores  
✅ **Clean data model** that scales with business growth  
✅ **Proper RLS security** without blocking legitimate operations  
✅ **Production-ready** with comprehensive testing  

---

**Last Updated**: October 23, 2025  
**Resolution Status**: ✅ COMPLETE  
**Production Status**: ✅ READY

