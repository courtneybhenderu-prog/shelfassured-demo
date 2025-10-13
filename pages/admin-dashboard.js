// pages/admin-dashboard.js - Admin dashboard functionality

let currentUser = null;
let userProfile = null;

// Initialize dashboard
document.addEventListener('DOMContentLoaded', async function() {
    console.log('🔧 Admin Dashboard initialized');
    
    // Wait for Supabase to be available
    let attempts = 0;
    while (!window.supabase && attempts < 10) {
        console.log('⏳ Waiting for Supabase to load...', attempts);
        await new Promise(resolve => setTimeout(resolve, 100));
        attempts++;
    }
    
    if (!window.supabase) {
        console.error('❌ Supabase failed to load');
        window.location.href = '../auth/signin.html';
        return;
    }
    
    console.log('✅ Supabase loaded, initializing dashboard');
    await initializeDashboard();
});

// Initialize dashboard (admin access already checked by inline guard)
async function initializeDashboard() {
    try {
        console.log('🚀 Starting initializeDashboard...');
        
        // Get current user (should already be set by inline guard)
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) {
            console.log('❌ No user found, redirecting to signin');
            window.location.href = '../auth/signin.html';
            return;
        }
        currentUser = user;
        
        // Get user profile
        const { data: profile, error } = await supabase
            .from('users')
            .select('role, full_name, approval_status')
            .eq('id', user.id)
            .single();
            
        if (error || !profile) {
            console.error('❌ Error fetching user profile:', error);
            window.location.href = '../auth/signin.html';
            return;
        }
        
        userProfile = profile;
        console.log('✅ Profile loaded:', profile);
        
        // Update UI
        document.getElementById('admin-user').textContent = `Welcome, ${userProfile.full_name || user.email}`;
        
        // Load dashboard data
        await loadDashboardData();

    } catch (error) {
        console.error('Error initializing dashboard:', error);
        window.location.href = '../auth/signin.html';
    }
}

// Load dashboard data
async function loadDashboardData() {
    try {
        // Load all data in parallel
        const [jobs, users, auditRequests] = await Promise.all([
            saGet('jobs', []),
            saGet('users', []),
            saGet('audit_requests', [])
        ]);

        // Update metrics
        updateMetrics(jobs, users, auditRequests);
        
        // Update recent activity
        updateRecentActivity(jobs, users);
        
        // Update user management
        updateUserManagement(users);

    } catch (error) {
        console.error('Error loading dashboard data:', error);
    }
}

// Update dashboard metrics
function updateMetrics(jobs, users, auditRequests) {
    const totalJobs = jobs.length;
    const activeJobs = jobs.filter(job => job.status === 'pending' || job.status === 'assigned').length;
    const activeUsers = users.filter(user => user.is_active).length;
    const pendingReviews = jobs.filter(job => job.status === 'pending').length;
    const helpRequests = auditRequests.filter(req => req.status === 'pending_review').length;

    // Update elements only if they exist
    const totalJobsEl = document.getElementById('total-jobs');
    const activeJobsEl = document.getElementById('active-jobs');
    const activeUsersEl = document.getElementById('active-users');
    const pendingReviewsEl = document.getElementById('pending-reviews');
    const helpRequestsEl = document.getElementById('help-requests');

    if (totalJobsEl) totalJobsEl.textContent = totalJobs;
    if (activeJobsEl) activeJobsEl.textContent = activeJobs;
    if (activeUsersEl) activeUsersEl.textContent = activeUsers;
    if (pendingReviewsEl) pendingReviewsEl.textContent = pendingReviews;
    if (helpRequestsEl) helpRequestsEl.textContent = helpRequests;
}

// Update recent activity
function updateRecentActivity(jobs, users) {
    // Update Recent Jobs section
    const recentJobsContainer = document.getElementById('recent-jobs');
    if (recentJobsContainer) {
        const recentJobs = jobs
            .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
            .slice(0, 5);
        
        if (recentJobs.length === 0) {
            recentJobsContainer.innerHTML = '<div class="text-center text-gray-500">No recent jobs</div>';
        } else {
            const jobsHtml = recentJobs.map(job => `
                <div class="py-3 border-b border-gray-200 last:border-b-0 cursor-pointer hover:bg-gray-50" onclick="viewJobDetails('${job.id}')">
                    <div class="flex items-start justify-between">
                        <div class="flex-1">
                            <div class="font-medium text-gray-900">${job.title || 'Untitled Job'}</div>
                            <div class="text-sm text-gray-600">Status: <span class="font-medium ${job.status === 'completed' ? 'text-green-600' : job.status === 'pending' ? 'text-blue-600' : 'text-gray-600'}">${job.status || 'unknown'}</span></div>
                            <div class="text-sm text-gray-500">Created: ${new Date(job.created_at).toLocaleDateString()}</div>
                        </div>
                        <div class="text-right">
                            <div class="text-sm font-medium text-gray-900">$${job.total_payout || 0}</div>
                        </div>
                    </div>
                </div>
            `).join('');
            recentJobsContainer.innerHTML = jobsHtml;
        }
    }
    
    // Update Recent Users section
    const recentUsersContainer = document.getElementById('recent-users');
    if (recentUsersContainer) {
        const recentUsers = users
            .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
            .slice(0, 5);
        
        if (recentUsers.length === 0) {
            recentUsersContainer.innerHTML = '<div class="text-center text-gray-500">No recent users</div>';
        } else {
            const usersHtml = recentUsers.map(user => `
                <div class="py-3 border-b border-gray-200 last:border-b-0">
                    <div class="flex items-start justify-between">
                        <div class="flex-1">
                            <div class="font-medium text-gray-900">${user.full_name || 'No name'}</div>
                            <div class="text-sm text-gray-600">${user.email}</div>
                            <div class="text-sm text-gray-500">Role: ${user.role}</div>
                        </div>
                        <div class="text-right">
                            <span class="px-2 py-1 text-xs font-semibold rounded-full ${user.is_active ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}">
                                ${user.is_active ? 'Active' : 'Inactive'}
                            </span>
                        </div>
                    </div>
                </div>
            `).join('');
            recentUsersContainer.innerHTML = usersHtml;
        }
    }
}

// Update user management (this function is called but the container doesn't exist in current HTML)
function updateUserManagement(users) {
    // This function is kept for compatibility but the user management
    // is now handled by the dedicated user-management.html page
    console.log('📊 User management data loaded:', users.length, 'users');
}

// Handle sign out
async function handleSignOut() {
    try {
        await supabase.auth.signOut();
        window.location.href = '../auth/signin.html';
    } catch (error) {
        console.error('Error signing out:', error);
        window.location.href = '../auth/signin.html';
    }
}

// Navigation helper
function goToPage(page) {
    window.location.href = page;
}

// View job details
function viewJobDetails(jobId) {
    console.log('Viewing job details:', jobId);
    window.location.href = `../dashboard/job-details.html?job_id=${jobId}`;
}
