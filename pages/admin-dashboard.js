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

    document.getElementById('total-jobs').textContent = totalJobs;
    document.getElementById('active-jobs').textContent = activeJobs;
    document.getElementById('active-users').textContent = activeUsers;
    document.getElementById('pending-reviews').textContent = pendingReviews;
    document.getElementById('help-requests').textContent = helpRequests;
}

// Update recent activity
function updateRecentActivity(jobs, users) {
    const container = document.getElementById('recent-activity');
    
    // Get recent jobs (last 5)
    const recentJobs = jobs
        .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
        .slice(0, 5);
    
    if (recentJobs.length === 0) {
        container.innerHTML = '<div class="text-center text-gray-500">No recent activity</div>';
        return;
    }
    
    const activityHtml = recentJobs.map(job => `
        <div class="py-3 border-b border-gray-200 last:border-b-0">
            <div class="flex items-start justify-between">
                <div class="flex-1">
                    <div class="font-medium text-gray-900">${job.title}</div>
                    <div class="text-sm text-gray-600">Status: <span class="font-medium ${job.status === 'completed' ? 'text-green-600' : job.status === 'pending' ? 'text-blue-600' : 'text-gray-600'}">${job.status}</span></div>
                    <div class="text-sm text-gray-500">Created: ${new Date(job.created_at).toLocaleDateString()}</div>
                </div>
                <div class="text-right">
                    <div class="text-sm font-medium text-gray-900">$${job.total_cost || 0}</div>
                </div>
            </div>
        </div>
    `).join('');
    
    container.innerHTML = activityHtml;
}

// Update user management
function updateUserManagement(users) {
    const container = document.getElementById('user-management');
    
    // Get users needing approval
    const pendingUsers = users.filter(user => user.approval_status === 'pending');
    
    if (pendingUsers.length === 0) {
        container.innerHTML = '<div class="text-center text-gray-500">No users pending approval</div>';
        return;
    }
    
    const usersHtml = pendingUsers.map(user => `
        <div class="py-3 border-b border-gray-200 last:border-b-0">
            <div class="flex items-start justify-between">
                <div class="flex-1">
                    <div class="font-medium text-gray-900">${user.full_name || 'No name'}</div>
                    <div class="text-sm text-gray-600">${user.email}</div>
                    <div class="text-sm text-gray-500">Role: ${user.role}</div>
                </div>
                <div class="text-right">
                    <div class="text-sm font-medium text-gray-900">${user.is_active ? 'Active' : 'Inactive'}</div>
                </div>
            </div>
        </div>
    `).join('');
    
    container.innerHTML = usersHtml;
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
