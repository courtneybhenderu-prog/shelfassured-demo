// ShelfAssured API Layer
// Supabase integration and data management

class ShelfAssuredAPI {
  constructor(supabaseUrl, supabaseKey) {
    this.supabase = supabase.createClient(supabaseUrl, supabaseKey);
    this.user = null;
  }

  // Authentication methods
  async signUp(email, password, userData = {}) {
    try {
      const { data, error } = await this.supabase.auth.signUp({
        email,
        password,
        options: {
          data: userData
        }
      });
      
      if (error) throw error;
      
      // Create user profile
      if (data.user) {
        await this.createUserProfile(data.user.id, userData);
      }
      
      return { success: true, data };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  async signIn(email, password) {
    try {
      const { data, error } = await this.supabase.auth.signInWithPassword({
        email,
        password
      });
      
      if (error) throw error;
      
      this.user = data.user;
      return { success: true, data };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  async signOut() {
    try {
      const { error } = await this.supabase.auth.signOut();
      if (error) throw error;
      
      this.user = null;
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // User management
  async createUserProfile(userId, userData) {
    const { data, error } = await this.supabase
      .from('users')
      .insert([{
        id: userId,
        email: userData.email,
        full_name: userData.fullName,
        phone: userData.phone,
        role: userData.role || 'contractor'
      }]);
    
    if (error) throw error;
    return data;
  }

  async getCurrentUser() {
    try {
      const { data: { user } } = await this.supabase.auth.getUser();
      this.user = user;
      return user;
    } catch (error) {
      return null;
    }
  }

  // Brand management
  async getBrands() {
    try {
      const { data, error } = await this.supabase
        .from('brands')
        .select('*')
        .eq('is_active', true)
        .order('name');
      
      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  async createBrand(brandData) {
    // Validate data
    const validation = Validator.validate(brandData, ValidationRules.brand);
    if (!validation.isValid) {
      return { success: false, error: 'Validation failed', details: validation.errors };
    }

    try {
      const { data, error } = await this.supabase
        .from('brands')
        .insert([{
          ...brandData,
          created_by: this.user?.id
        }])
        .select();
      
      if (error) throw error;
      return { success: true, data: data[0] };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Store management
  async getStores() {
    try {
      const { data, error } = await this.supabase
        .from('stores')
        .select('*')
        .eq('is_active', true)
        .order('name')
        .limit(5000);
      
      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  async createStore(storeData) {
    // Validate data
    const validation = Validator.validate(storeData, ValidationRules.store);
    if (!validation.isValid) {
      return { success: false, error: 'Validation failed', details: validation.errors };
    }

    try {
      const { data, error } = await this.supabase
        .from('stores')
        .insert([{
          ...storeData,
          created_by: this.user?.id
        }])
        .select();
      
      if (error) throw error;
      return { success: true, data: data[0] };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // SKU management
  async getSkus(brandId = null) {
    try {
      let query = this.supabase
        .from('skus')
        .select('*, brands(name)')
        .eq('is_active', true);
      
      if (brandId) {
        query = query.eq('brand_id', brandId);
      }
      
      const { data, error } = await query.order('name');
      
      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  async createSku(skuData) {
    // Validate data
    const validation = Validator.validate(skuData, ValidationRules.sku);
    if (!validation.isValid) {
      return { success: false, error: 'Validation failed', details: validation.errors };
    }

    try {
      const { data, error } = await this.supabase
        .from('skus')
        .insert([{
          ...skuData,
          created_by: this.user?.id
        }])
        .select();
      
      if (error) throw error;
      return { success: true, data: data[0] };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Job management
  async getJobs(filters = {}) {
    try {
      let query = this.supabase
        .from('jobs')
        .select(`
          *,
          brands(name),
          job_stores(store_id, stores(name, address)),
          job_skus(sku_id, skus(name, upc))
        `);
      
      // Apply filters
      if (filters.status) {
        query = query.eq('status', filters.status);
      }
      
      if (filters.contractorId) {
        query = query.eq('contractor_id', filters.contractorId);
      }
      
      if (filters.brandId) {
        query = query.eq('brand_id', filters.brandId);
      }
      
      const { data, error } = await query.order('created_at', { ascending: false });
      
      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  async createJob(jobData) {
    // Validate data
    const validation = Validator.validate(jobData, ValidationRules.job);
    if (!validation.isValid) {
      return { success: false, error: 'Validation failed', details: validation.errors };
    }

    // Business rule validations
    const storeValidation = Validator.businessRules.validateJobStores(jobData);
    if (!storeValidation.isValid) {
      return { success: false, error: storeValidation.error };
    }

    const skuValidation = Validator.businessRules.validateJobSkus(jobData);
    if (!skuValidation.isValid) {
      return { success: false, error: skuValidation.error };
    }

    try {
      // Start transaction
      const { data: job, error: jobError } = await this.supabase
        .from('jobs')
        .insert([{
          ...jobData,
          created_by: this.user?.id
        }])
        .select();
      
      if (jobError) throw jobError;

      const jobId = job[0].id;

      // Add store relationships
      if (jobData.storeIds && jobData.storeIds.length > 0) {
        const storeRelations = jobData.storeIds.map(storeId => ({
          job_id: jobId,
          store_id: storeId
        }));

        const { error: storeError } = await this.supabase
          .from('job_stores')
          .insert(storeRelations);
        
        if (storeError) throw storeError;
      }

      // Add SKU relationships
      if (jobData.skuIds && jobData.skuIds.length > 0) {
        const skuRelations = jobData.skuIds.map(skuId => ({
          job_id: jobId,
          sku_id: skuId
        }));

        const { error: skuError } = await this.supabase
          .from('job_skus')
          .insert(skuRelations);
        
        if (skuError) throw skuError;
      }

      return { success: true, data: job[0] };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  async updateJobStatus(jobId, status, additionalData = {}) {
    try {
      const updateData = {
        status,
        updated_at: new Date().toISOString(),
        ...additionalData
      };

      if (status === 'in_progress') {
        updateData.started_at = new Date().toISOString();
      } else if (status === 'completed') {
        updateData.completed_at = new Date().toISOString();
      }

      const { data, error } = await this.supabase
        .from('jobs')
        .update(updateData)
        .eq('id', jobId)
        .select();
      
      if (error) throw error;
      return { success: true, data: data[0] };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Job submissions
  async submitJobData(jobId, submissionData) {
    // Validate data
    const validation = Validator.validate(submissionData, ValidationRules.jobSubmission);
    if (!validation.isValid) {
      return { success: false, error: 'Validation failed', details: validation.errors };
    }

    try {
      const { data, error } = await this.supabase
        .from('job_submissions')
        .insert([{
          ...submissionData,
          job_id: jobId,
          contractor_id: this.user?.id
        }])
        .select();
      
      if (error) throw error;
      return { success: true, data: data[0] };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Payment management
  async getPayments(contractorId = null) {
    try {
      let query = this.supabase
        .from('payments')
        .select('*, jobs(title)')
        .order('created_at', { ascending: false });
      
      if (contractorId) {
        query = query.eq('contractor_id', contractorId);
      }
      
      const { data, error } = await query;
      
      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Notifications
  async getNotifications() {
    try {
      const { data, error } = await this.supabase
        .from('notifications')
        .select('*')
        .eq('user_id', this.user?.id)
        .order('created_at', { ascending: false });
      
      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  async markNotificationRead(notificationId) {
    try {
      const { error } = await this.supabase
        .from('notifications')
        .update({ is_read: true })
        .eq('id', notificationId)
        .eq('user_id', this.user?.id);
      
      if (error) throw error;
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  // Migration helpers (from localStorage to Supabase)
  async migrateFromLocalStorage() {
    try {
      // Get existing data from localStorage
      const brands = saGet('brands') || [];
      const stores = saGet('stores') || [];
      const skus = saGet('skus') || [];
      const jobs = saGet('jobs') || [];

      // Migrate brands
      for (const brand of brands) {
        await this.createBrand(brand);
      }

      // Migrate stores
      for (const store of stores) {
        await this.createStore(store);
      }

      // Migrate SKUs
      for (const sku of skus) {
        await this.createSku(sku);
      }

      // Migrate jobs
      for (const job of jobs) {
        await this.createJob(job);
      }

      return { success: true, message: 'Migration completed successfully' };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }
}

// Initialize API instance (you'll need to provide your Supabase credentials)
let shelfAssuredAPI = null;

function initializeAPI(supabaseUrl, supabaseKey) {
  shelfAssuredAPI = new ShelfAssuredAPI(supabaseUrl, supabaseKey);
  return shelfAssuredAPI;
}

// Export for use
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { ShelfAssuredAPI, initializeAPI };
} else if (typeof window !== 'undefined') {
  window.ShelfAssuredAPI = ShelfAssuredAPI;
  window.initializeAPI = initializeAPI;
}
