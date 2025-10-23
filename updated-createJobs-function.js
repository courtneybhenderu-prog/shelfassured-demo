// Updated createJobs function using job_store_skus table
// This replaces the old createJobs function in manage-jobs.html

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
        
        // Create a single job (not one per store-SKU combination)
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
        
        const { data: job, error: jobError } = await supabase
            .from('jobs')
            .insert(jobData)
            .select()
            .single();
        
        if (jobError) throw jobError;
        
        console.log('✅ Job created:', job.id);
        createdJobs.push(job);
        
        // Create job_store_skus assignments using UPSERT
        const assignments = [];
        for (const storeId of storeIds) {
            for (const skuId of skuIds) {
                assignments.push({
                    job_id: job.id,
                    store_id: storeId,
                    sku_id: skuId,
                    status: 'pending'
                });
            }
        }
        
        // Use UPSERT to handle duplicates gracefully
        const { data: assignmentsData, error: assignmentError } = await supabase
            .from('job_store_skus')
            .upsert(assignments, {
                onConflict: 'job_id,store_id,sku_id',
                ignoreDuplicates: true
            })
            .select();
        
        if (assignmentError) {
            console.error('❌ Error creating assignments:', assignmentError);
            throw assignmentError;
        }
        
        console.log('✅ Assignments created:', assignmentsData.length);
        
        return {
            created: createdJobs.length,
            assignments: assignmentsData.length,
            errors: errors.length,
            total: storeIds.length * skuIds.length
        };
        
    } catch (error) {
        console.error('❌ Error in createJobs:', error);
        throw error;
    }
}

// Helper function to get job details with stores and SKUs
async function getJobDetails(jobId) {
    try {
        const { data, error } = await supabase
            .from('job_store_skus')
            .select(`
                stores(id, name, city, state, address),
                skus(id, name, upc),
                status
            `)
            .eq('job_id', jobId);
        
        if (error) throw error;
        
        // Group by store
        const storeGroups = {};
        data.forEach(assignment => {
            const store = assignment.stores;
            const sku = assignment.skus;
            
            if (!storeGroups[store.id]) {
                storeGroups[store.id] = {
                    store: store,
                    skus: []
                };
            }
            
            storeGroups[store.id].skus.push(sku);
        });
        
        return Object.values(storeGroups);
        
    } catch (error) {
        console.error('❌ Error getting job details:', error);
        throw error;
    }
}

// Example usage in the form submission handler:
// Replace the existing handleFormSubmit function with this:

async function handleFormSubmit(event) {
    event.preventDefault();
    
    try {
        // Validate form
        if (!validateForm()) {
            return;
        }
        
        // Show loading state
        setLoadingState(true);
        hideError();
        hideSuccess();
        
        // Get form data
        const formData = getFormData();
        
        // Create job using new method
        const result = await createJobs(formData);
        
        // Show success
        showSuccess(result);
        
        // Redirect after delay
        setTimeout(() => {
            window.location.href = 'dashboard.html';
        }, 3000);
        
    } catch (error) {
        console.error('❌ Error creating jobs:', error);
        showError(error.message);
    } finally {
        setLoadingState(false);
    }
}
