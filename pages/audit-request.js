// pages/audit-request.js - Audit request functionality

// Initialize the page
document.addEventListener('DOMContentLoaded', async function() {
    console.log('🔧 Audit Request page initialized');
    
    // Check if user has access
    await checkAccess();
    
    // Setup form handlers
    setupFormHandlers();
});

// Check if user has brand client or admin access
async function checkAccess() {
    try {
        const { data: { user } } = await supabase.auth.getUser();
        
        if (!user) {
            alert('Please sign in to access this page');
            window.location.href = '../auth/signin.html';
            return;
        }

        // Get user profile to check role
        const { data: profile, error } = await supabase
            .from('users')
            .select('role, full_name')
            .eq('id', user.id)
            .single();

        if (error || !profile) {
            console.error('Error fetching user profile:', error);
            alert('Error loading user profile');
            window.location.href = '../auth/signin.html';
            return;
        }

        if (profile.role !== 'brand_client' && profile.role !== 'admin') {
            alert('Access denied. Brand client privileges required.');
            window.location.href = '../dashboard/shelfer.html';
            return;
        }

        document.getElementById('user-info').textContent = `Welcome, ${profile.full_name || user.email}`;
        console.log('✅ Brand client/admin access confirmed');
        
    } catch (error) {
        console.error('Error checking access:', error);
        alert('Error checking permissions');
        window.location.href = '../auth/signin.html';
    }
}

// Setup form event handlers
function setupFormHandlers() {
    // Add product button
    document.getElementById('add-product').addEventListener('click', addProductInput);
    
    // All stores checkbox
    document.getElementById('all-stores').addEventListener('change', toggleAllStores);
    
    // Form submission
    document.getElementById('audit-request-form').addEventListener('submit', handleFormSubmit);
    
    // Cancel button
    document.getElementById('cancel-audit').addEventListener('click', function() {
        if (confirm('Are you sure you want to cancel? All data will be lost.')) {
            window.location.href = 'brand-client.html';
        }
    });
    
    // Add initial product input
    addProductInput();
}

// Add product input field
function addProductInput() {
    const productList = document.getElementById('product-list');
    const productCount = productList.children.length;
    
    const productHtml = `
        <div class="flex items-center space-x-2 product-input">
            <input type="text" name="products" placeholder="Enter product name, SKU, or description" 
                   class="flex-1 border border-gray-300 rounded-md px-3 py-2 product-field">
            <button type="button" class="btn-gray text-sm remove-product" ${productCount === 0 ? 'style="display:none"' : ''}>Remove</button>
        </div>
    `;
    
    productList.insertAdjacentHTML('beforeend', productHtml);
    
    // Setup remove button
    const removeBtn = productList.lastElementChild.querySelector('.remove-product');
    removeBtn.addEventListener('click', function() {
        this.parentElement.remove();
        updateProductRemoveButtons();
    });
    
    updateProductRemoveButtons();
}

// Update product remove buttons visibility
function updateProductRemoveButtons() {
    const productInputs = document.querySelectorAll('.product-input');
    productInputs.forEach((input, index) => {
        const removeBtn = input.querySelector('.remove-product');
        removeBtn.style.display = productInputs.length > 1 ? 'block' : 'none';
    });
}

// Toggle all stores selection
function toggleAllStores() {
    const allStoresCheckbox = document.getElementById('all-stores');
    const storeRequirements = document.getElementById('store-requirements');
    
    if (allStoresCheckbox.checked) {
        storeRequirements.placeholder = 'Additional store requirements (optional)...';
    } else {
        storeRequirements.placeholder = 'Describe your store selection requirements, geographic preferences, store types, or any specific locations...';
    }
}

// Handle form submission
async function handleFormSubmit(event) {
    event.preventDefault();
    
    const messageEl = document.getElementById('message');
    messageEl.classList.add('hidden');
    
    try {
        // Get form data
        const formData = new FormData(event.target);
        const auditType = formData.get('audit-type');
        const title = formData.get('title').trim();
        const description = formData.get('description').trim();
        const storeRequirements = formData.get('store-requirements').trim();
        const timeline = formData.get('timeline');
        const specialRequirements = formData.get('special-requirements').trim();
        const contactPhone = formData.get('contact-phone').trim();
        const preferredContact = formData.get('preferred-contact');
        const additionalNotes = formData.get('additional-notes').trim();
        
        // Validate required fields
        if (!auditType || !title || !description || !timeline) {
            showMessage(messageEl, 'Please fill in all required fields', 'error');
            return;
        }
        
        // Get products
        const productInputs = document.querySelectorAll('.product-field');
        const products = Array.from(productInputs)
            .map(input => input.value.trim())
            .filter(product => product.length > 0);
        
        if (products.length === 0) {
            showMessage(messageEl, 'Please add at least one product', 'error');
            return;
        }
        
        // Get current user
        const { data: { user } } = await supabase.auth.getUser();
        
        // Create audit request object
        const auditRequest = {
            audit_type: auditType,
            title,
            description,
            products: products,
            all_stores: document.getElementById('all-stores').checked,
            store_requirements: storeRequirements || null,
            timeline,
            special_requirements: specialRequirements || null,
            contact_phone: contactPhone || null,
            preferred_contact: preferredContact,
            additional_notes: additionalNotes || null,
            client_id: user.id,
            status: 'pending_review',
            created_at: new Date().toISOString()
        };
        
        console.log('📝 Creating audit request:', auditRequest);
        
        // Save audit request to database
        const result = await saSet('audit_requests', auditRequest);
        
        if (result.success) {
            showMessage(messageEl, 'Audit request submitted successfully! Our team will review it within 24 hours and reach out with custom pricing.', 'success');
            
            // Clear form
            event.target.reset();
            document.getElementById('product-list').innerHTML = '';
            addProductInput();
            
            setTimeout(() => {
                window.location.href = 'brand-client.html';
            }, 3000);
        } else {
            showMessage(messageEl, 'Error submitting audit request: ' + result.error, 'error');
        }
        
    } catch (error) {
        console.error('Error submitting audit request:', error);
        showMessage(messageEl, 'Error submitting audit request: ' + error.message, 'error');
    }
}

// Show message
function showMessage(element, message, type) {
    element.textContent = message;
    element.className = `px-6 pb-6 text-sm ${type === 'success' ? 'text-green-600' : 'text-red-600'}`;
    element.classList.remove('hidden');
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
