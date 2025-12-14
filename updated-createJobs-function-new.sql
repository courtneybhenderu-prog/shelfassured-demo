// Updated createJobs function for manage-jobs.html
// This uses the new job_store_skus table with UPSERT logic

async function createJobs(formData) {
    const errors = [];
    const createdJobs = [];
    
    try {
        console.log('🔄 Creating jobs with form data:', formData);
        
        // Ensure brand exists
        let brandId = await ensureBrandExists(formData.brand);
        console.log('✅ Brand ID:', brandId);
        
        // Get store IDs from enhanced store selector
        const storeIds = formData.stores.map(store => store.id);
        console.log('✅ Store IDs:', storeIds);
        
        // Ensure SKUs exist
        const skuIds = await ensureSkusExist(formData.skus, brandId);
        console.log('✅ SKU IDs:', skuIds);
        
        // Create the main job record
        const jobData = {
            title: formData.title,
            description: formData.description,
            brand_id: brandId,
            priority: formData.priority || 'medium',
            status: 'pending'
        };
        
        console.log('🔄 Creating main job record...');
        const { data: job, error: jobError } = await supabase
            .from('jobs')
            .insert(jobData)
            .select()
            .single();
        
        if (jobError) throw jobError;
        console.log('✅ Main job created:', job.id);
        
        // Create job_store_skus entries using UPSERT
        console.log('🔄 Creating job-store-sku assignments...');
        const assignments = [];
        for (const storeId of storeIds) {
            for (const skuId of skuIds) {
                assignments.push({ 
                    job_id: job.id, 
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
        
        createdJobs.push(job);
        
        return {
            created: createdJobs.length,
            errors: errors.length,
            total: storeIds.length * skuIds.length,
            jobId: job.id
        };
        
    } catch (error) {
        console.error('❌ Error in createJobs:', error);
        throw error;
    }
}


