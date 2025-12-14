// REST API Upsert Headers Configuration
// Ensure REST endpoints use proper conflict resolution headers

// For direct REST API calls (not JS client), use these headers:
const restHeaders = {
    'Content-Type': 'application/json',
    'Prefer': 'resolution=merge-duplicates,ignore-duplicates'
};

// Example REST API call with proper headers
const upsertJobStoreSku = async (jobId, storeId, skuId) => {
    const response = await fetch(`${SUPABASE_URL}/rest/v1/job_store_skus`, {
        method: 'POST',
        headers: {
            ...restHeaders,
            'Authorization': `Bearer ${SUPABASE_ANON_KEY}`,
            'apikey': SUPABASE_ANON_KEY
        },
        body: JSON.stringify({
            job_id: jobId,
            store_id: storeId,
            sku_id: skuId,
            status: 'pending'
        })
    });
    
    return response.json();
};

// Verify JS client parity (already implemented)
const jsClientUpsert = async (assignments) => {
    return await supabase
        .from('job_store_skus')
        .upsert(assignments, {
            onConflict: 'job_id,store_id,sku_id',
            ignoreDuplicates: true
        });
};

export { restHeaders, upsertJobStoreSku, jsClientUpsert };


