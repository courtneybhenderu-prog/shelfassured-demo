// CORRECTED createJobs function for manage-jobs.html
// This replaces the old approach with the new job_store_skus table

async function createJobs(formData) {
    try {
        console.log('🔄 Creating job with new 3-way junction table approach:', formData);
        
        // Ensure brand exists
        let brandId = await ensureBrandExists(formData.brand);
        console.log('✅ Brand ID:', brandId);
        
        // Get store IDs from enhanced store selector
        const storeIds = formData.stores.map(store => store.id);
        console.log('✅ Store IDs:', storeIds);
        
        // Ensure SKUs exist
        const skuIds = await ensureSkusExist(formData.skus, brandId);
        console.log('✅ SKU IDs:', skuIds);
        
        // 1) Create ONE job record (not one per store-SKU combination)
        const jobData = {
            title: formData.title,
            description: formData.description,
            brand_id: brandId,
            assigned_user_id: formData.assignedUserId,
            priority: formData.priority,
            due_date: formData.dueDate || null,
            instructions: formData.specialInstructions,
            status: 'pending',
            payout_per_store: 5.00, // Standard $5 per store
            created_at: new Date().toISOString()
        };
        
        console.log('🔄 Creating main job record...');
        const { data: jobRow, error: jobErr } = await supabase
            .from('jobs')
            .insert(jobData)
            .select()
            .single();
        
        if (jobErr) throw jobErr;
        console.log('✅ Main job created:', jobRow.id);
        
        // 2) Create assignments in job_store_skus (3-way junction table)
        console.log('🔄 Creating job-store-sku assignments...');
        const assignments = [];
        for (const storeId of storeIds) {
            for (const skuId of skuIds) {
                assignments.push({
                    job_id: jobRow.id,
                    store_id: storeId,
                    sku_id: skuId
                });
            }
        }
        
        const { error: assignmentError } = await supabase
            .from('job_store_skus')
            .upsert(assignments, { 
                onConflict: 'job_id,store_id,sku_id', 
                ignoreDuplicates: true 
            });
        
        if (assignmentError) throw assignmentError;
        console.log('✅ Assignments created:', assignments.length);
        
        return {
            created: 1, // Only one job created
            assignments: assignments.length, // Multiple assignments
            jobId: jobRow.id,
            errors: 0
        };
        
    } catch (error) {
        console.error('❌ Error in createJobs:', error);
        throw error;
    }
}

// REMOVE/DISABLE any remaining calls to job_stores and job_skus
// Search for these patterns and remove them:
// - supabase.from('job_stores').insert
// - supabase.from('job_skus').insert
// - Any references to the old two-table approach

