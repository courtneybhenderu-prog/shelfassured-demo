-- Console smoke test for job details page
-- Run this in browser console on job-details page (signed in)

/*
CONSOLE SMOKE TEST - Copy and paste this into browser console:

// Test 1: Check authentication
const authCheck = await supabase.auth.getSession();
console.log('Auth status:', !!(authCheck.data.session));

// Test 2: Get job ID from URL
const jobId = new URLSearchParams(location.search).get('job_id');
console.log('Job ID from URL:', jobId);

// Test 3: Query the view
const { data, error } = await supabase
  .from('v_job_assignments')
  .select('*')
  .eq('job_id', jobId);

console.log('View query result:', { rows: data, error });

// Test 4: Check if data has expected fields
if (data && data.length > 0) {
  const first = data[0];
  console.log('First assignment:', {
    store_chain: first.store_chain,
    store_name: first.store_name,
    brand_name: first.brand_name,
    sku_name: first.sku_name
  });
  
  // Test 5: Verify header display logic
  const storeHeader = `${first.store_chain} — ${first.store_name}`;
  const skuHeader = `${first.brand_name ? first.brand_name + ' — ' : ''}${first.sku_name}`;
  console.log('Expected headers:', { storeHeader, skuHeader });
}

// Expected Results:
// Auth status: true
// Job ID from URL: <some-uuid>
// View query result: { rows: [...], error: null }
// First assignment: { store_chain: "H-E-B", store_name: "CYPRESS MARKETPLACE", brand_name: "DJ's Boudain", sku_name: "Original Boudain" }
// Expected headers: { storeHeader: "H-E-B — CYPRESS MARKETPLACE", skuHeader: "DJ's Boudain — Original Boudain" }
*/


