// ShelfAssured API Layer - Shared Functions
// Supabase integration and data management

// Supabase Configuration
const SUPABASE_URL = 'https://mlmhmzhvwtsswigfvkwx.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1sbWhtemh2d3Rzc3dpZ2Z2a3d4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg3NTYwNDQsImV4cCI6MjA3NDMzMjA0NH0.sr3x6TkgXlK4Nc8SHPwoS6q5TDGXeExfFK2vPoOTPYk';

// Initialize Supabase
let supabase;
try {
  supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  console.log('✅ Supabase client initialized');
} catch (error) {
  console.error('❌ Supabase initialization failed:', error);
  supabase = null;
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
          .order('name');
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
        
      case 'jobs':
        const { data: jobs, error: jobsError } = await supabase
          .from('jobs')
          .select(`
            *,
            brands(name),
            job_stores(store_id, stores(name, address)),
            job_skus(sku_id, skus(name, upc))
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
    console.log('🔄 Calling supabase.auth.signUp...');
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: userData }
    });
    
    console.log('📋 Auth signup response:', { data, error });
    
    if (error) {
      console.error('❌ Auth signup error:', error);
      throw error;
    }
    
    // Create user profile
    if (data.user) {
      console.log('🔄 Creating user profile...', data.user.id);
        const { error: profileError } = await supabase
          .from('users')
          .insert([{
            id: data.user.id,
            email: userData.email,
            full_name: userData.fullName,
            phone: userData.phone,
            role: userData.role || 'shelfer'
          }]);
      
      if (profileError) {
        console.error('❌ Profile creation error:', profileError);
      } else {
        console.log('✅ User profile created successfully');
      }
    } else {
      console.warn('⚠️ No user data returned from auth signup');
    }
    
    return { success: true, data };
  } catch (error) {
    console.error('❌ saSignUp error:', error);
    return { success: false, error: error.message };
  }
};

window.saSignIn = async function(email, password) {
  if (!supabase) {
    return { success: false, error: 'Supabase not available' };
  }
  
  try {
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });
    
    if (error) throw error;
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

// Navigation helper
function goToPage(page) {
  window.location.href = page;
}

// Ensure user profile exists and return it
window.ensureProfile = async function(user) {
  if (!supabase) {
    return { role: 'shelfer' };
  }
  
  try {
    // Try to get existing profile
    const { data: existingProfile, error: getError } = await supabase
      .from('users')
      .select('*')
      .eq('id', user.id)
      .single();
    
    if (existingProfile) {
      return existingProfile;
    }
    
    // Create profile if it doesn't exist
    const { data: newProfile, error: createError } = await supabase
      .from('users')
      .insert([{
        id: user.id,
        email: user.email,
        full_name: user.user_metadata?.full_name || '',
        phone: user.user_metadata?.phone || '',
        role: user.user_metadata?.role || 'shelfer'
      }])
      .select()
      .single();
    
    if (createError) throw createError;
    return newProfile;
  } catch (error) {
    console.error('❌ Error ensuring profile:', error);
    return { role: 'shelfer' };
  }
};

// Initialize app with Supabase
document.addEventListener('DOMContentLoaded', async function() {
  console.log('🚀 ShelfAssured API initialized with Supabase!');
  
  // Check if user is logged in
  const { data: { user } } = await supabase.auth.getUser();
  if (user) {
    console.log('✅ User logged in:', user.email);
  } else {
    console.log('ℹ️ No user logged in');
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
