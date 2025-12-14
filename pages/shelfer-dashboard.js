// pages/shelfer-dashboard.js - Shelfer dashboard functionality

// Check email confirmation before loading dashboard
async function checkAccess() {
    const isConfirmed = await requireEmailConfirmation();
    if (!isConfirmed) {
        return false; // User will be redirected
    }
    return true;
}

// Load dashboard data
async function loadDashboard() {
    try {
        console.log('🔄 Loading dashboard data...');
        
        // Load jobs with stores and brands (using Supabase query for better joins)
        const { data: allJobs, error: jobsError } = await supabase
            .from('jobs')
            .select(`
                *,
                brands (
                    id,
                    name
                ),
                job_store_skus (
                    store_id,
                    stores (
                        id,
                        STORE,
                        name,
                        address,
                        city,
                        state,
                        zip_code
                    )
                )
            `)
            .in('status', ['pending', 'assigned'])
            .order('created_at', { ascending: false });
        
        if (jobsError) {
            console.error('❌ Error loading jobs:', jobsError);
            throw jobsError;
        }
        
        console.log('📊 Jobs loaded with stores:', allJobs);
        
        // Update UI
        document.getElementById('available-jobs').textContent = allJobs?.length || 0;
        
        // Render jobs
        const jobsList = document.getElementById('jobs-list');
        if (!allJobs || allJobs.length === 0) {
            jobsList.innerHTML = saEmptyState('No jobs available', 'Check back later for new opportunities');
        } else {
            jobsList.innerHTML = allJobs.map(job => {
                // Get stores from job_store_skus
                const jobStores = job.job_store_skus || [];
                const stores = jobStores
                    .map(jss => jss.stores)
                    .filter(Boolean)
                    .filter((store, index, self) => 
                        index === self.findIndex(s => s?.id === store?.id) // Deduplicate stores
                    );
                
                // Display first store (or multiple if there are many)
                const storeDisplay = stores.length > 0 ? stores[0] : null;
                const storeName = storeDisplay ? (storeDisplay.STORE || storeDisplay.name || 'Store') : null;
                const storeAddress = storeDisplay && storeDisplay.address ? 
                    `${storeDisplay.address}${storeDisplay.city ? ', ' + storeDisplay.city : ''}${storeDisplay.state ? ', ' + storeDisplay.state : ''}${storeDisplay.zip_code ? ' ' + storeDisplay.zip_code : ''}`.trim() : 
                    null;
                
                const multipleStores = stores.length > 1;
                
                // Escape HTML helper
                const escapeHtml = (text) => {
                    if (!text) return '';
                    const div = document.createElement('div');
                    div.textContent = text;
                    return div.innerHTML;
                };
                
                return `
                    <div class="sa-card p-4 cursor-pointer hover:shadow-md transition-shadow" onclick="viewJob('${job.id}')">
                        <div class="flex justify-between items-start mb-2">
                            <h4 class="font-semibold text-gray-900">${escapeHtml(job.title || 'Untitled Job')}</h4>
                            <span class="inline-block px-2 py-1 bg-yellow-100 text-yellow-800 rounded text-xs ml-2">${escapeHtml(job.status)}</span>
                        </div>
                        <p class="text-sm text-gray-600 mb-1">
                            <strong>Brand:</strong> ${escapeHtml(job.brands?.name || 'Unknown Brand')}
                        </p>
                        ${storeName ? `
                            <p class="text-sm text-gray-700 font-medium mt-2 mb-1">
                                📍 ${escapeHtml(storeName)}
                                ${multipleStores ? ` <span class="text-xs text-gray-500">(+${stores.length - 1} more)</span>` : ''}
                            </p>
                            ${storeAddress ? `
                                <p class="text-xs text-gray-500 mb-2">${escapeHtml(storeAddress)}</p>
                            ` : ''}
                        ` : '<p class="text-sm text-gray-500 italic">Store information not available</p>'}
                        <p class="text-sm font-semibold text-blue-600 mt-2">$${parseFloat(job.payout_per_store || 0).toFixed(2)} per store</p>
                    </div>
                `;
            }).join('');
        }
        
    } catch (error) {
        console.error('❌ Error loading dashboard:', error);
        document.getElementById('jobs-list').innerHTML = saEmptyState('Error loading jobs', 'Please try again later');
    }
}

function viewJob(jobId) {
    console.log('Viewing job:', jobId);
    // Navigate to job details page
    window.location.href = `job-details.html?job_id=${jobId}`;
}

// Load dashboard when page loads
document.addEventListener('DOMContentLoaded', async function() {
    const hasAccess = await checkAccess();
    if (hasAccess) {
        loadDashboard();
    }
});
