// ShelfAssured Validation Layer
// Business rules and data validation functions

const ValidationRules = {
  // User validation
  user: {
    email: {
      required: true,
      pattern: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
      message: 'Valid email address is required'
    },
    fullName: {
      required: true,
      minLength: 2,
      maxLength: 100,
      pattern: /^[a-zA-Z\s'-]+$/,
      message: 'Full name must be 2-100 characters, letters only'
    },
    phone: {
      required: false,
      pattern: /^[\+]?[1-9][\d]{0,15}$/,
      message: 'Valid phone number is required'
    },
    role: {
      required: true,
      allowedValues: ['admin', 'contractor', 'client'],
      message: 'Role must be admin, contractor, or client'
    }
  },

  // Brand validation
  brand: {
    name: {
      required: true,
      minLength: 2,
      maxLength: 255,
      message: 'Brand name must be 2-255 characters'
    },
    contactEmail: {
      required: false,
      pattern: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
      message: 'Valid email address is required'
    },
    contactPhone: {
      required: false,
      pattern: /^[\+]?[1-9][\d]{0,15}$/,
      message: 'Valid phone number is required'
    }
  },

  // Store validation
  store: {
    name: {
      required: true,
      minLength: 2,
      maxLength: 255,
      message: 'Store name must be 2-255 characters'
    },
    address: {
      required: true,
      minLength: 10,
      maxLength: 500,
      message: 'Address must be 10-500 characters'
    },
    city: {
      required: true,
      minLength: 2,
      maxLength: 100,
      pattern: /^[a-zA-Z\s'-]+$/,
      message: 'City must be 2-100 characters, letters only'
    },
    state: {
      required: true,
      minLength: 2,
      maxLength: 50,
      pattern: /^[a-zA-Z\s]+$/,
      message: 'State must be 2-50 characters, letters only'
    },
    zipCode: {
      required: true,
      pattern: /^\d{5}(-\d{4})?$/,
      message: 'Valid US zip code is required (12345 or 12345-6789)'
    },
    latitude: {
      required: false,
      min: -90,
      max: 90,
      message: 'Latitude must be between -90 and 90'
    },
    longitude: {
      required: false,
      min: -180,
      max: 180,
      message: 'Longitude must be between -180 and 180'
    }
  },

  // SKU validation
  sku: {
    upc: {
      required: true,
      pattern: /^[0-9]{8,14}$/,
      message: 'UPC must be 8-14 digits'
    },
    name: {
      required: true,
      minLength: 2,
      maxLength: 255,
      message: 'SKU name must be 2-255 characters'
    },
    category: {
      required: false,
      allowedValues: [
        'beverages', 'snacks', 'dairy', 'produce', 'meat', 'bakery',
        'frozen', 'canned', 'condiments', 'health', 'beauty', 'household',
        'other'
      ],
      message: 'Category must be from allowed list'
    }
  },

  // Job validation
  job: {
    title: {
      required: true,
      minLength: 5,
      maxLength: 255,
      message: 'Job title must be 5-255 characters'
    },
    description: {
      required: false,
      maxLength: 2000,
      message: 'Description must be less than 2000 characters'
    },
    payoutPerStore: {
      required: true,
      min: 0.01,
      max: 1000.00,
      message: 'Payout per store must be between $0.01 and $1000.00'
    },
    category: {
      required: false,
      allowedValues: [
        'shelf_audit', 'inventory_check', 'price_verification',
        'product_placement', 'competitor_analysis', 'other'
      ],
      message: 'Category must be from allowed list'
    },
    jobType: {
      required: true,
      allowedValues: ['photo_audit', 'inventory_check', 'price_verification', 'shelf_analysis'],
      message: 'Job type must be from allowed list'
    },
    dueDate: {
      required: false,
      futureDate: true,
      message: 'Due date must be in the future'
    },
    priority: {
      required: true,
      allowedValues: ['low', 'normal', 'high', 'urgent'],
      message: 'Priority must be low, normal, high, or urgent'
    }
  },

  // Job submission validation
  jobSubmission: {
    submissionType: {
      required: true,
      allowedValues: ['photo', 'inventory_data', 'price_data', 'shelf_data'],
      message: 'Submission type must be from allowed list'
    },
    data: {
      required: true,
      isObject: true,
      message: 'Submission data must be a valid object'
    },
    files: {
      required: false,
      isArray: true,
      maxItems: 10,
      message: 'Maximum 10 files allowed per submission'
    }
  }
};

// Validation utility functions
const Validator = {
  // Generic validation function
  validate(data, rules) {
    const errors = {};
    
    for (const [field, rule] of Object.entries(rules)) {
      const value = data[field];
      const fieldErrors = this.validateField(value, rule, field);
      if (fieldErrors.length > 0) {
        errors[field] = fieldErrors;
      }
    }
    
    return {
      isValid: Object.keys(errors).length === 0,
      errors
    };
  },

  // Validate individual field
  validateField(value, rule, fieldName) {
    const errors = [];
    
    // Required check
    if (rule.required && (value === undefined || value === null || value === '')) {
      errors.push(rule.message || `${fieldName} is required`);
      return errors;
    }
    
    // Skip other validations if value is empty and not required
    if (!rule.required && (value === undefined || value === null || value === '')) {
      return errors;
    }
    
    // Type checks
    if (rule.isObject && typeof value !== 'object') {
      errors.push(rule.message || `${fieldName} must be an object`);
    }
    
    if (rule.isArray && !Array.isArray(value)) {
      errors.push(rule.message || `${fieldName} must be an array`);
    }
    
    // String validations
    if (typeof value === 'string') {
      if (rule.minLength && value.length < rule.minLength) {
        errors.push(rule.message || `${fieldName} must be at least ${rule.minLength} characters`);
      }
      
      if (rule.maxLength && value.length > rule.maxLength) {
        errors.push(rule.message || `${fieldName} must be no more than ${rule.maxLength} characters`);
      }
      
      if (rule.pattern && !rule.pattern.test(value)) {
        errors.push(rule.message || `${fieldName} format is invalid`);
      }
    }
    
    // Number validations
    if (typeof value === 'number') {
      if (rule.min !== undefined && value < rule.min) {
        errors.push(rule.message || `${fieldName} must be at least ${rule.min}`);
      }
      
      if (rule.max !== undefined && value > rule.max) {
        errors.push(rule.message || `${fieldName} must be no more than ${rule.max}`);
      }
    }
    
    // Array validations
    if (Array.isArray(value)) {
      if (rule.maxItems && value.length > rule.maxItems) {
        errors.push(rule.message || `${fieldName} can have at most ${rule.maxItems} items`);
      }
    }
    
    // Allowed values check
    if (rule.allowedValues && !rule.allowedValues.includes(value)) {
      errors.push(rule.message || `${fieldName} must be one of: ${rule.allowedValues.join(', ')}`);
    }
    
    // Future date check
    if (rule.futureDate && value instanceof Date && value <= new Date()) {
      errors.push(rule.message || `${fieldName} must be in the future`);
    }
    
    return errors;
  },

  // Business rule validations
  businessRules: {
    // Job must have at least one store or be marked as all_stores
    validateJobStores(job) {
      if (!job.allStores && (!job.storeIds || job.storeIds.length === 0)) {
        return { isValid: false, error: 'Job must have at least one store or be marked for all stores' };
      }
      return { isValid: true };
    },

    // Job must have at least one SKU
    validateJobSkus(job) {
      if (!job.skuIds || job.skuIds.length === 0) {
        return { isValid: false, error: 'Job must have at least one SKU' };
      }
      return { isValid: true };
    },

    // Payout calculation validation
    validatePayout(job, stores) {
      const nStores = job.allStores ? stores.length : (job.storeIds || []).length;
      const expectedPayout = job.payoutPerStore * nStores;
      
      if (job.totalPayout && Math.abs(job.totalPayout - expectedPayout) > 0.01) {
        return { 
          isValid: false, 
          error: `Payout mismatch. Expected $${expectedPayout.toFixed(2)}, got $${job.totalPayout.toFixed(2)}` 
        };
      }
      return { isValid: true };
    },

    // Store assignment validation
    validateStoreAssignment(job, contractorId) {
      // Check if contractor has access to assigned stores
      // This would integrate with your store access logic
      return { isValid: true };
    },

    // Due date validation
    validateDueDate(dueDate, jobType) {
      if (!dueDate) return { isValid: true };
      
      const now = new Date();
      const due = new Date(dueDate);
      const daysDiff = (due - now) / (1000 * 60 * 60 * 24);
      
      // Minimum lead time based on job type
      const minLeadTime = {
        'photo_audit': 1,
        'inventory_check': 2,
        'price_verification': 1,
        'shelf_analysis': 3
      };
      
      if (daysDiff < minLeadTime[jobType]) {
        return { 
          isValid: false, 
          error: `${jobType} requires at least ${minLeadTime[jobType]} day(s) lead time` 
        };
      }
      
      return { isValid: true };
    }
  }
};

// Export for use in your application
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { ValidationRules, Validator };
} else if (typeof window !== 'undefined') {
  window.ValidationRules = ValidationRules;
  window.Validator = Validator;
}
