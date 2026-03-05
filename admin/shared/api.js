// ShelfAssured API Layer - Shared Functions
// Supabase integration and data management

// Supabase Configuration
// SECURITY: Credentials are loaded from window.SA_CONFIG which is populated
// by config.js using environment variables. Never hardcode keys here.
const SUPABASE_URL = (window.SA_CONFIG && window.SA_CONFIG.SUPABASE_URL) || '';
const SUPABASE_ANON_KEY = (window.SA_CONFIG && window.SA_CONFIG.SUPABASE_ANON_KEY) || '';

// Initialize Supabase
let supabase;
let supabaseRetryCount = 0;
const MAX_RETRIES = 5;

// Function to initialize Supabase when ready
function initializeSupabase() {
  try {
    const lib = window.supabase;
    if (typeof lib !== 'undefined' && lib.createClient) {
      const client = lib.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
        auth: {
          // Always persist session in localStorage so mobile browsers
          // don't lose the session token when navigating between pages.
          // sessionStorage (the default) is wiped on every page load on iOS Safari/Chrome.
          storage: window.localStorage,
          persistSession: true,
          autoRefreshToken: true,
          detectSessionInUrl: true,
        }
      });
      // Set both local variable and window.saClient
      // Do NOT overwrite window.supabase — that's the library
      supabase = client;
      window.saClient = client;
      console.log('✅ Supabase client initialized (localStorage session)');
      return true;
    } else {
      console.log('⏳ Supabase library not loaded yet, waiting...');
      return false;
    }
  } catch (error) {
    console.error('❌ Supabase initialization failed:', error);
    return false;
  }
}

// Try to initialize immediately, or wait for DOM
if (!initializeSupabase()) {
  // If not ready, wait for DOM and try again
  document.addEventListener('DOMContentLoaded', function() {
    retrySupabaseInit();
  });
}

// Retry Supabase initialization with exponential backoff
function retrySupabaseInit() {
  if (supabaseRetryCount >= MAX_RETRIES) {
    console.error('❌ Supabase failed to load after', MAX_RETRIES, 'attempts');
    return;
  }
  
  supabaseRetryCount++;
  console.log(`⏳ Retry ${supabaseRetryCount}/${MAX_RETRIES}: Checking for Supabase...`);
  
  if (!initializeSupabase()) {
    const delay = Math.pow(2, supabaseRetryCount) * 500; // Exponential backoff
    console.log(`⏳ Retrying in ${delay}ms...`);
    setTimeout(retrySupabaseInit, delay);
  }
}

// Store original saGet/saSet functions as fallback
const originalSaGet = window.saGet;
const originalSaSet = window.saSet;

// Enhanced saGet/saSet functions with Supabase integration
window.saGet = async function(key, fallback = null) {
  // If Supabase is not available, use original function
  if (!supabase) {
    return originalSaGet ? originalSaGet(key, fallback) : fallback;
  }
  
  try {
    switch(key) {
      case 'brands':
        const { data: brands, error: brandsError } = await supabase
          .from('brands')
          .select('*')
          .eq('is_active', true)
          .order('name');
        if (brandsError) throw brandsError;
        return brands || fallback;
        
      case 'stores':
        const { data: stores, error: storesError } = await supabase
          .from('stores')
          .select('*')
          .eq('is_active', true)
          .order('name')
          .limit(5000);
        if (storesError) throw storesError;
        return stores || fallback;
        
      case 'skus':
        const { data: skus, error: skusError } = await supabase
          .from('skus')
          .select('*')
          .eq('is_active', true)
          .order('name');
        if (skusError) throw skusError;
        return skus || fallback;
        
      case 'users':
        const { data: users, error: usersError } = await supabase
          .from('users')
          .select('*')
          .order('created_at', { ascending: false });
        if (usersError) throw usersError;
        return users || fallback;
        
      case 'audit_requests':
        const { data: auditRequests, error: auditRequestsError } = await supabase
          .from('audit_requests')
          .select('*')
          .order('created_at', { ascending: false });
        if (auditRequestsError) throw auditRequestsError;
        return auditRequests || fallback;
        
      case 'jobs':
        const { data: jobs, error: jobsError } = await supabase
          .from('jobs')
          .select(`
            *,
            brands(name),
            job_stores(stores(name, city, state)),
            job_skus(skus(name))
          `)
          .order('created_at', { ascending: false });
        if (jobsError) throw jobsError;
        return jobs || fallback;
        
      default:
        // Fallback to original function for other keys
        return originalSaGet ? originalSaGet(key, fallback) : fallback;
    }
  } catch (error) {
    console.error('Supabase Error:', error);
    // Fallback to original function on error
    return originalSaGet ? originalSaGet(key, fallback) : fallback;
  }
};

window.saSet = async function(key, val) {
  try {
    // For now, just store in localStorage as backup
    // In production, you'd want to save to Supabase
    if (originalSaSet) {
      return originalSaSet(key, val);
    } else {
      try { localStorage.setItem(key, JSON.stringify(val)); }
      catch(e){ localStorage.setItem(key, val); }
      return true;
    }
  } catch (error) {
    console.error('Storage Error:', error);
    return false;
  }
};

// Authentication functions
window.saSignUp = async function(email, password, userData = {}) {
  console.log('🔧 saSignUp called with:', { email, userData });
  
  if (!supabase) {
    console.error('❌ Supabase not available');
    return { success: false, error: 'Supabase not available' };
  }
  
  try {
    // Pick base depending on where the app is running
    const SA_BASE = location.origin.includes('localhost')
      ? 'http://localhost:8000'
      : 'https://courtneybhenderu-prog.github.io/shelfassured-demo';
    
    console.log('🔄 Calling supabase.auth.signUp...');
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: { 
        data: {
          full_name: userData.full_name,
          phone: userData.phone,
          role: userData.role
        },
        emailRedirectTo: `${SA_BASE}/auth/confirmed.html`
      }
    });
    
    console.log('📋 Auth signup response:', { data, error });
    
    if (error) {
      console.error('❌ Auth signup error:', error);
      throw error;
    }
    
    // Note: Profile will be created by ensureProfile() when user first logs in
    // This is more reliable than trying to create it during signup
    console.log('✅ Auth signup successful, profile will be created on first login');
    
    return { success: true, data };
  } catch (error) {
    console.error('❌ saSignUp error:', error);
    return { success: false, error: error.message };
  }
};

window.saSignIn = async function(email, password, rememberMe = false) {
  if (!supabase) {
    return { success: false, error: 'Supabase not available' };
  }
  
  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
      // Session persistence is handled at the client level (localStorage, persistSession: true)
      // so the session survives page navigation on mobile browsers.
    });
    
    if (error) throw error;
    
    // Check if email is confirmed
    if (data.user && !data.user.email_confirmed_at) {
      return { 
        success: false, 
        error: 'Please check your email and click the confirmation link before signing in.',
        needsConfirmation: true 
      };
    }
    
    return { success: true, data };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

window.saSignOut = async function() {
  if (!supabase) {
    return { success: false, error: 'Supabase not available' };
  }
  
  try {
    const { error } = await supabase.auth.signOut();
    if (error) throw error;
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
};

// Helper function for empty states
window.saEmptyState = function(title, sub){
  return '<div class="rounded-2xl border p-6 text-center bg-white">' +
    '<div class="text-base font-medium">' + title + '</div>' +
    '<div class="text-sm text-gray-500 mt-1">' + sub + '</div>' +
    '</div>';
};

// Utility functions
function showMessage(element, message, type) {
  element.textContent = message;
  element.classList.remove('hidden');
  
  // Remove existing classes
  element.classList.remove('text-green-600', 'text-red-600', 'text-blue-600');
  
  // Add appropriate class
  if (type === 'success') {
    element.classList.add('text-green-600');
  } else if (type === 'error') {
    element.classList.add('text-red-600');
  } else {
    element.classList.add('text-blue-600');
  }
}

// Navigation helper with error handling
function goToPage(page) {
  try {
    console.log('🔍 Navigation: Going to', page);
    window.location.href = page;
  } catch (error) {
    console.error('❌ Navigation error:', error);
    // Fallback: try direct assignment
    try {
      window.location.assign(page);
    } catch (fallbackError) {
      console.error('❌ Fallback navigation failed:', fallbackError);
      alert('Navigation failed. Please refresh the page.');
    }
  }
}

// Expose goToPage globally for HTML onclick handlers
window.goToPage = goToPage;

// Check if current user's email is confirmed
window.isEmailConfirmed = async function() {
  if (!supabase) return false;
  
  try {
    const { data: { user } } = await supabase.auth.getUser();
    return user && user.email_confirmed_at;
  } catch (error) {
    console.error('❌ Error checking email confirmation:', error);
    return false;
  }
};

// Redirect unconfirmed users to email confirmation page
window.requireEmailConfirmation = async function() {
  const isConfirmed = await isEmailConfirmed();
  if (!isConfirmed) {
    window.location.href = '../auth/email-confirmation-required.html';
    return false;
  }
  return true;
};

// Ensure user profile exists and return it
window.ensureProfile = async function(user) {
  if (!supabase) {
    console.log('❌ Supabase not available in ensureProfile');
    return { role: 'shelfer' };
  }
  
  try {
    // If no user provided, get current user
    if (!user) {
      const { data: { user: currentUser } } = await supabase.auth.getUser();
      if (!currentUser) {
        console.log('❌ No current user found');
        return null;
      }
      user = currentUser;
    }
    
    console.log('🔍 Ensuring profile for user:', user.id, user.email);
    const md = user.user_metadata || {};
    console.log('📋 User metadata:', md);
    
    // First try to get existing profile
    const { data: existingProfile, error: getError } = await supabase
      .from('users')
      .select('*')
      .eq('id', user.id)
      .single();
    
    if (existingProfile) {
      console.log('✅ Found existing profile:', existingProfile);
      console.log('🔍 Existing profile role:', existingProfile.role);
      console.log('🔍 Existing profile data:', JSON.stringify(existingProfile, null, 2));
      return existingProfile;
    }
    
    // If no existing profile, create one
    console.log('🔄 Creating new profile for user');
    const role = md.role || 'shelfer';
    const profileData = {
      id: user.id,
      email: user.email,
      full_name: md.full_name || null,
      phone: md.phone || null,
      role: role,
      approval_status: 'approved' // All users approved by default
    };
    console.log('📋 Profile data to insert:', profileData);
    
    const { data: newProfile, error: createError } = await supabase
      .from('users')
      .insert(profileData)
      .select()
      .single();
    
    if (createError) {
      console.error('❌ Error creating profile:', createError);
      console.error('❌ Full error details:', JSON.stringify(createError, null, 2));
      // Don't return fallback - let the error propagate
      throw createError;
    }
    
    console.log('✅ Profile created:', newProfile);
    return newProfile;
  } catch (error) {
    console.error('❌ Error ensuring profile:', error);
    // Return a fallback profile instead of null
    return { 
      id: user?.id || 'unknown', 
      email: user?.email || 'unknown', 
      role: 'shelfer',
      full_name: user?.user_metadata?.full_name || null,
      phone: user?.user_metadata?.phone || null
    };
  }
};

// Initialize app with Supabase
document.addEventListener('DOMContentLoaded', async function() {
  console.log('🚀 ShelfAssured API initialized with Supabase!');
  
  // Wait for Supabase to be available
  if (!supabase) {
    console.log('⏳ Waiting for Supabase to initialize...');
    return;
  }
  
  // DEVELOPMENT DEBUGGING: Colorized console logging for troubleshooting
  // This system helps debug redirect issues, role mismatches, and script loading problems
  // Enable with ?dev=1 on any page, disable with ?dev=0
  
  // Blue info log: Shows what the guard sees (path and role) every time it runs
  // This helps verify the guard is working correctly and roles are set properly
  window.__SA_DEV__ && console.info('%c[SA][guard]', 'color: #2563eb; font-weight: bold;', 'path=', location.pathname, 'role=', String(window.SA_PAGE_ROLE));
  
  // Red warning log: Alerts when a page forgot to set SA_PAGE_ROLE
  // This catches the exact issue we had where index.html wasn't setting the role before shared/api.js loaded
  window.__SA_DEV__ && typeof window.SA_PAGE_ROLE === 'undefined' && console.warn('%c[SA][guard] Missing SA_PAGE_ROLE on', 'color: #dc2626; font-weight: bold;', location.pathname);
  
  // Cooperative global guard - respects per-page overrides
  console.log('🔍 GLOBAL GUARD: Checking flags...');
  console.log('🔍 GLOBAL GUARD: SA_DISABLE_GLOBAL_GUARD =', window.SA_DISABLE_GLOBAL_GUARD);
  console.log('🔍 GLOBAL GUARD: SA_PAGE_ROLE =', window.SA_PAGE_ROLE);
  
  if (window.SA_DISABLE_GLOBAL_GUARD === true) {
    console.log('🔒 Global guard disabled by page');
    return;
  }
  
  // Check if user is logged in
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    console.log('ℹ️ No user logged in');
    // Only redirect if no page role is declared
    if (!window.SA_PAGE_ROLE) {
      console.log('🔄 No page role declared, redirecting to signin');
      window.location.href = '../auth/signin.html';
    }
    return;
  }
  
  console.log('✅ User logged in:', user.email);
  
  // If page has declared a role, check if user matches
  if (window.SA_PAGE_ROLE) {
    console.log('🔍 Page role declared:', window.SA_PAGE_ROLE);
    
    // Handle public pages (no authentication required)
    if (window.SA_PAGE_ROLE === 'public') {
      console.log('✅ Public page, no authentication required');
      return;
    }
    
    // If admin page and already passed admin check, do nothing
    if (window.SA_PAGE_ROLE === 'admin' && window.SA_ADMIN_READY === true) {
      console.log('✅ Admin page already passed checks, skipping global guard');
      return;
    }
    
    // Get user profile to check role
    try {
      const prof = await ensureProfile(user);
      const role = prof?.role ?? user?.user_metadata?.role ?? 'shelfer';
      
      if (role !== window.SA_PAGE_ROLE) {
        console.log('❌ Role mismatch:', role, 'vs', window.SA_PAGE_ROLE);
        // Redirect to correct dashboard
        const base = location.origin.includes('localhost')
          ? 'http://localhost:8000'
          : 'https://courtneybhenderu-prog.github.io/shelfassured-demo';
        
        if (role === 'admin') {
          window.location.href = `${base}/admin/dashboard.html`;
        } else if (role === 'brand_client') {
          window.location.href = `${base}/dashboard/brand-client.html`;
        } else {
          window.location.href = `${base}/dashboard/shelfer.html`;
        }
        return;
      }
      
      console.log('✅ Role matches page requirement:', role);
    } catch (error) {
      console.error('❌ Error checking role:', error);
    }
  }
  
  // Load data from Supabase
  try {
    const brands = await saGet('brands', []);
    const stores = await saGet('stores', []);
    const jobs = await saGet('jobs', []);
    
    console.log('📊 Data loaded:', { 
      brands: brands.length, 
      stores: stores.length, 
      jobs: jobs.length 
    });
  } catch (error) {
    console.error('❌ Error loading data:', error);
  }
});
