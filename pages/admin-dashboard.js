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
        
        // Hide Brands button from non-admin users
        const brandsButton = document.getElementById('brands-quick-action');
        if (brandsButton && userProfile.role !== 'admin') {
            brandsButton.style.display = 'none';
            console.log('🔒 Hiding Brands button for non-admin user');
        }
        
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
        
        // Load brands separately to handle errors better
        let brands = [];
        console.log('🔄 Starting brands query...');
        try {
            const brandsResult = await supabase
                .from('brands')
                .select('id, name, website, created_at, logo_url')
                .order('created_at', { ascending: false })
                .limit(100);
            
            console.log('📊 Brands query result:', brandsResult);
            
            if (brandsResult.error) {
                console.error('❌ Error loading brands:', brandsResult.error);
                console.error('Error details:', JSON.stringify(brandsResult.error, null, 2));
                // Set empty state immediately on error
                const brandsContainer = document.getElementById('brands-list');
                if (brandsContainer) {
                    brandsContainer.innerHTML = '<div class="text-center text-red-500 text-sm">Error loading brands. Please refresh the page.</div>';
                }
            } else {
                brands = brandsResult.data || [];
                console.log('✅ Brands query successful');
                
                if (brands.length > 0) {
                    console.log('📊 Brands sample:', brands.slice(0, 3));
                    // Prioritize brands with logos for better UX
                    const brandsWithLogos = brands.filter(b => b.logo_url);
                    const brandsWithoutLogos = brands.filter(b => !b.logo_url);
                    console.log(`📊 Brands with logos: ${brandsWithLogos.length}, without: ${brandsWithoutLogos.length}`);
                    // Show brands with logos first, then others, limited to top 50 for performance
                    const sortedBrands = [...brandsWithLogos, ...brandsWithoutLogos].slice(0, 50);
                    brands = sortedBrands;
                } else {
                    console.warn('⚠️ No brands found in database');
                    // Set empty state immediately
                    const brandsContainer = document.getElementById('brands-list');
                    if (brandsContainer) {
                        brandsContainer.innerHTML = '<div class="text-center text-gray-500">No brands found</div>';
                    }
                }
            }
        } catch (error) {
            console.error('❌ Exception loading brands:', error);
            console.error('Exception stack:', error.stack);
            // Set error state immediately
            const brandsContainer = document.getElementById('brands-list');
            if (brandsContainer) {
                brandsContainer.innerHTML = '<div class="text-center text-red-500 text-sm">Error loading brands. Please refresh the page.</div>';
            }
        }

        // Update metrics
        updateMetrics(jobs, users, auditRequests);
        
        // Update recent activity
        updateRecentActivity(jobs, users);
        
        // Update user management
        updateUserManagement(users);
        
        // Update brands panel (shows all, but prioritized)
        // Use requestAnimationFrame to ensure DOM is ready, then small delay
        if (brands.length > 0 || document.getElementById('brands-list')?.textContent.includes('Loading')) {
            requestAnimationFrame(() => {
                setTimeout(() => {
                    console.log('🎨 Updating brands panel UI...');
                    updateBrandsPanel(brands, true);
                }, 200);
            });
        }

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

// Store all brands for search filtering
let allBrandsList = [];

// Update brands panel
function updateBrandsPanel(brands, isInitial = false) {
    const brandsContainer = document.getElementById('brands-list');
    if (!brandsContainer) {
        console.warn('⚠️ Brands container (#brands-list) not found. Checking DOM...');
        // Retry after a short delay if container doesn't exist
        if (isInitial) {
            setTimeout(() => {
                const retryContainer = document.getElementById('brands-list');
                if (retryContainer && brands.length > 0) {
                    console.log('✅ Container found on retry, updating brands panel');
                    updateBrandsPanel(brands, true);
                } else {
                    console.error('❌ Brands container still not found after retry');
                }
            }, 500);
        }
        return;
    }
    
    // Store the full list on initial load
    if (isInitial) {
        allBrandsList = brands;
        console.log('Stored brands list:', allBrandsList.length);
    }
    
    // Use provided brands (filtered) or all brands
    const displayBrands = brands || allBrandsList;
    
    console.log('Updating brands panel with', displayBrands.length, 'brands');
    
    if (displayBrands.length === 0) {
        brandsContainer.innerHTML = '<div class="text-center text-gray-500">No brands found</div>';
        return;
    }
    
    const brandsHtml = displayBrands.map(brand => {
        // Debug log for logo URLs
        if (brand.logo_url) {
            console.log(`Brand ${brand.name} logo URL:`, brand.logo_url.substring(0, 80) + '...');
        }
        
        let logoHtml;
        if (brand.logo_url) {
            // Fix URL encoding issues (spaces, etc.)
            let logoUrl = brand.logo_url;
            // Check if URL has unencoded spaces in bucket name path
            if (logoUrl.includes('/brand logos/')) {
                logoUrl = logoUrl.replace('/brand logos/', '/brand_logos/');
                console.warn(`⚠️ Fixed logo URL space issue for ${brand.name}, replacing 'brand logos' with 'brand_logos'`);
            }
            // Encode any remaining spaces in the URL
            logoUrl = encodeURI(logoUrl);
            
            logoHtml = `<img src="${escapeHtml(logoUrl)}" alt="${escapeHtml(brand.name)} logo" 
                 class="w-12 h-12 object-contain rounded border border-gray-200 bg-white p-1"
                 loading="lazy"
                 onerror="console.error('❌ Logo failed to load for ${escapeHtml(brand.name)}:', '${escapeHtml(brand.logo_url).substring(0, 50)}...'); this.onerror=null; this.parentElement.innerHTML='<div class=\\'w-12 h-12 flex items-center justify-center bg-gray-100 rounded border border-gray-200 text-gray-400 text-xs\\'>No Logo</div>'"
                 onload="console.log('✅ Logo loaded successfully for ${escapeHtml(brand.name)}')">`;
        } else {
            logoHtml = `<div class="w-12 h-12 flex items-center justify-center bg-gray-100 rounded border border-gray-200 text-gray-400 text-xs">No Logo</div>`;
        }
        
        return `
        <div class="py-3 border-b border-gray-200 last:border-b-0 hover:bg-gray-50">
            <div class="flex items-center justify-between">
                <div class="flex items-center space-x-3 flex-1">
                    ${logoHtml}
                    <div class="flex-1">
                        <a href="../dashboard/brand-client.html?brand_id=${brand.id}" class="font-medium text-blue-600 hover:text-blue-800 hover:underline">
                            ${escapeHtml(brand.name || 'Unnamed Brand')}
                        </a>
                        ${brand.website ? `<div class="text-sm text-gray-500 mt-1">${escapeHtml(brand.website)}</div>` : ''}
                        <div class="text-xs text-gray-400 mt-1">Created: ${brand.created_at ? new Date(brand.created_at).toLocaleDateString() : 'N/A'}</div>
                    </div>
                </div>
                <div class="flex items-center space-x-2">
                    <a href="../dashboard/brand-client.html?brand_id=${brand.id}" target="_blank" rel="noopener" 
                       class="text-gray-400 hover:text-gray-600 text-sm" title="Open in new tab">
                        ↗
                    </a>
                </div>
            </div>
        </div>
        `;
    }).join('');
    
    brandsContainer.innerHTML = brandsHtml;
    
    // Set up search filtering only on initial load
    if (isInitial) {
        // Delay search setup to ensure input exists
        setTimeout(() => {
            const searchInput = document.getElementById('brand-search');
            if (searchInput) {
                console.log('✅ Setting up search input for', allBrandsList.length, 'brands');
                
                // Clear any existing listeners by removing and re-adding
                const searchContainer = searchInput.parentNode;
                const clonedInput = searchInput.cloneNode(true);
                searchContainer.replaceChild(clonedInput, searchInput);
                
                clonedInput.addEventListener('input', function(e) {
                    const term = e.target.value.toLowerCase().trim();
                    console.log('🔍 Search term:', term);
                    console.log('📊 All brands available:', allBrandsList.length);
                    const filtered = term ? allBrandsList.filter(b => {
                        const nameMatch = (b.name || '').toLowerCase().includes(term);
                        const websiteMatch = (b.website || '').toLowerCase().includes(term);
                        return nameMatch || websiteMatch;
                    }) : allBrandsList;
                    console.log('✅ Filtered to', filtered.length, 'brands');
                    updateBrandsPanel(filtered, false);
                });
                
                // Also handle Enter key
                clonedInput.addEventListener('keypress', function(e) {
                    if (e.key === 'Enter') {
                        e.preventDefault();
                        const term = e.target.value.toLowerCase().trim();
                        const filtered = term ? allBrandsList.filter(b => {
                            const nameMatch = (b.name || '').toLowerCase().includes(term);
                            const websiteMatch = (b.website || '').toLowerCase().includes(term);
                            return nameMatch || websiteMatch;
                        }) : allBrandsList;
                        updateBrandsPanel(filtered, false);
                    }
                });
            } else {
                console.warn('⚠️ Search input (#brand-search) not found. Retrying...');
                // Retry once more
                setTimeout(() => {
                    const retryInput = document.getElementById('brand-search');
                    if (retryInput) {
                        console.log('✅ Found search input on retry');
                        retryInput.addEventListener('input', function(e) {
                            const term = e.target.value.toLowerCase().trim();
                            const filtered = term ? allBrandsList.filter(b => {
                                const nameMatch = (b.name || '').toLowerCase().includes(term);
                                const websiteMatch = (b.website || '').toLowerCase().includes(term);
                                return nameMatch || websiteMatch;
                            }) : allBrandsList;
                            updateBrandsPanel(filtered, false);
                        });
                    } else {
                        console.error('❌ Search input still not found after retry');
                    }
                }, 500);
            }
        }, 300);
    }
}

// Helper function to escape HTML
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
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
