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
        console.log('🔄 Loading shelfer dashboard data...');
        
        // Get current user
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) {
            console.error('❌ No user found');
            window.location.href = '../auth/signin.html';
            return;
        }
        const currentUserId = user.id;
        
        // Load all relevant jobs with stores and brands
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
            .in('status', ['pending', 'assigned', 'in_progress', 'pending_review', 'completed'])
            .order('created_at', { ascending: false });
        
        if (jobsError) {
            console.error('❌ Error loading jobs:', jobsError);
            throw jobsError;
        }
        
        console.log('📊 All jobs loaded:', allJobs?.length || 0);
        
        // Filter jobs by role-specific logic
        const availableJobs = (allJobs || []).filter(job => 
            job.status === 'pending' && (!job.assigned_to || job.assigned_to === null)
        );
        
        const inProgressJobs = (allJobs || []).filter(job => 
            (job.status === 'assigned' || job.status === 'in_progress') && 
            job.assigned_to === currentUserId
        );
        
        const pendingApprovalJobs = (allJobs || []).filter(job => 
            job.status === 'pending_review' && 
            job.assigned_to === currentUserId
        );
        
        // Calculate total earnings from completed jobs
        const completedJobs = (allJobs || []).filter(job => 
            job.status === 'completed' && 
            job.assigned_to === currentUserId
        );
        
        const totalEarnings = completedJobs.reduce((sum, job) => {
            return sum + parseFloat(job.payout_per_store || 0);
        }, 0);
        
        console.log('📊 Shelfer dashboard stats:', {
            available: availableJobs.length,
            inProgress: inProgressJobs.length,
            pendingApproval: pendingApprovalJobs.length,
            completed: completedJobs.length,
            totalEarnings: totalEarnings
        });
        
        // Update earnings display
        const totalIncomeEl = document.getElementById('total-income');
        if (totalIncomeEl) {
            totalIncomeEl.textContent = `$${totalEarnings.toFixed(2)}`;
        }
        
        // Update available jobs count
        const availableJobsEl = document.getElementById('available-jobs');
        if (availableJobsEl) {
            availableJobsEl.textContent = availableJobs.length;
        }
        
        // Render jobs grouped by store
        renderJobsByStore(availableJobs, inProgressJobs, pendingApprovalJobs);
        
    } catch (error) {
        console.error('❌ Error loading dashboard:', error);
        const jobsList = document.getElementById('jobs-list');
        if (jobsList) {
            jobsList.innerHTML = saEmptyState('Error loading jobs', 'Please try again later');
        }
    }
}

// Render jobs grouped by store
function renderJobsByStore(availableJobs, inProgressJobs, pendingApprovalJobs) {
    const jobsList = document.getElementById('jobs-list');
    if (!jobsList) return;
    
    // Escape HTML helper
    const escapeHtml = (text) => {
        if (!text) return '';
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    };
    
    // Helper to get store display name
    const getStoreDisplay = (store) => {
        return store?.STORE || store?.name || 'Unknown Store';
    };
    
    // Helper to get store address
    const getStoreAddress = (store) => {
        if (!store) return null;
        const parts = [store.address, store.city, store.state, store.zip_code].filter(Boolean);
        return parts.length > 0 ? parts.join(', ') : null;
    };
    
    // Group jobs by store
    const groupJobsByStore = (jobs) => {
        const grouped = {};
        jobs.forEach(job => {
            const jobStores = job.job_store_skus || [];
            jobStores.forEach(jss => {
                const store = jss.stores;
                if (store) {
                    const storeId = store.id;
                    if (!grouped[storeId]) {
                        grouped[storeId] = {
                            store: store,
                            jobs: []
                        };
                    }
                    // Only add job once per store (deduplicate)
                    if (!grouped[storeId].jobs.find(j => j.id === job.id)) {
                        grouped[storeId].jobs.push(job);
                    }
                }
            });
        });
        return grouped;
    };
    
    // Build HTML for a job card
    const renderJobCard = (job) => {
        const jobStores = job.job_store_skus || [];
        const stores = jobStores.map(jss => jss.stores).filter(Boolean);
        const storeDisplay = stores.length > 0 ? stores[0] : null;
        const storeName = getStoreDisplay(storeDisplay);
        const storeAddress = getStoreAddress(storeDisplay);
        const multipleStores = stores.length > 1;
        
        // Status badge color
        let statusColor = 'bg-yellow-100 text-yellow-800';
        if (job.status === 'assigned' || job.status === 'in_progress') {
            statusColor = 'bg-blue-100 text-blue-800';
        } else if (job.status === 'pending_review') {
            statusColor = 'bg-orange-100 text-orange-800';
        }
        
        return `
            <div class="sa-card p-4 cursor-pointer hover:shadow-md transition-shadow mb-3" onclick="viewJob('${job.id}')">
                <div class="flex justify-between items-start mb-2">
                    <h4 class="font-semibold text-gray-900">${escapeHtml(job.title || 'Untitled Job')}</h4>
                    <span class="inline-block px-2 py-1 ${statusColor} rounded text-xs ml-2">${escapeHtml(job.status)}</span>
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
    };
    
    // Build HTML for a store group
    const renderStoreGroup = (store, jobs, sectionTitle) => {
        const storeName = getStoreDisplay(store);
        const storeAddress = getStoreAddress(store);
        
        return `
            <div class="mb-4">
                <div class="mb-3 pb-2 border-b border-gray-200">
                    <h3 class="text-lg font-semibold text-gray-900">${escapeHtml(storeName)}</h3>
                    ${storeAddress ? `<p class="text-sm text-gray-600">${escapeHtml(storeAddress)}</p>` : ''}
                    <p class="text-xs text-gray-500 mt-1">${jobs.length} job${jobs.length !== 1 ? 's' : ''} ${sectionTitle}</p>
                </div>
                <div class="space-y-2">
                    ${jobs.map(job => renderJobCard(job)).join('')}
                </div>
            </div>
        `;
    };
    
    // Combine all jobs for grouping
    const allJobsToShow = [...availableJobs, ...inProgressJobs, ...pendingApprovalJobs];
    
    if (allJobsToShow.length === 0) {
        jobsList.innerHTML = saEmptyState('No jobs available', 'Check back later for new opportunities');
        return;
    }
    
    // Group by store
    const groupedByStore = groupJobsByStore(allJobsToShow);
    const storeIds = Object.keys(groupedByStore);
    
    if (storeIds.length === 0) {
        jobsList.innerHTML = saEmptyState('No jobs available', 'Check back later for new opportunities');
        return;
    }
    
    // Render sections
    let html = '';
    
    // Available Jobs section
    if (availableJobs.length > 0) {
        const availableGrouped = groupJobsByStore(availableJobs);
        html += '<div class="mb-8"><h2 class="text-xl font-bold text-gray-900 mb-4">Available Jobs</h2>';
        Object.values(availableGrouped).forEach(({ store, jobs }) => {
            html += renderStoreGroup(store, jobs, 'available');
        });
        html += '</div>';
    }
    
    // In-Progress Jobs section
    if (inProgressJobs.length > 0) {
        const inProgressGrouped = groupJobsByStore(inProgressJobs);
        html += '<div class="mb-6"><h2 class="text-xl font-bold text-gray-900 mb-4">In-Progress Jobs</h2>';
        Object.values(inProgressGrouped).forEach(({ store, jobs }) => {
            html += renderStoreGroup(store, jobs, 'in progress');
        });
        html += '</div>';
    }
    
    // Pending Approval section
    if (pendingApprovalJobs.length > 0) {
        const pendingGrouped = groupJobsByStore(pendingApprovalJobs);
        html += '<div class="mb-6"><h2 class="text-xl font-bold text-gray-900 mb-4">Pending Approval</h2>';
        Object.values(pendingGrouped).forEach(({ store, jobs }) => {
            html += renderStoreGroup(store, jobs, 'pending approval');
        });
        html += '</div>';
    }
    
    jobsList.innerHTML = html || saEmptyState('No jobs available', 'Check back later for new opportunities');
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
