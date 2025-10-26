// pages/create-job.js - Job creation functionality

// Initialize the page
document.addEventListener('DOMContentLoaded', async function() {
    console.log('🔧 Create Job page initialized');
    
    // Check if user has access
    await checkAccess();
    
    // Load stores and products
    await loadStores();
    await loadProducts();
    
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

// Load available stores
async function loadStores() {
    try {
        const stores = await saGet('stores', []);
        console.log('📊 Stores loaded:', stores);
        
        const storeList = document.getElementById('store-list');
        
        if (stores.length === 0) {
            storeList.innerHTML = '<p class="text-sm text-gray-500">No stores available. Contact admin to add stores.</p>';
            return;
        }
        
        const storesHtml = stores.map(store => `
            <div class="flex items-center">
                <input type="checkbox" id="store-${store.id}" name="stores" value="${store.id}" 
                       class="rounded border-gray-300 store-checkbox">
                <label for="store-${store.id}" class="ml-2 text-sm text-gray-700">
                    ${store.name} - ${store.location}
                </label>
            </div>
        `).join('');
        
        storeList.innerHTML = storesHtml;
        
    } catch (error) {
        console.error('Error loading stores:', error);
        document.getElementById('store-list').innerHTML = '<p class="text-sm text-red-500">Error loading stores</p>';
    }
}

// Load available products
async function loadProducts() {
    try {
        const products = await saGet('products', []);
        console.log('📊 Products loaded:', products);
        
        // Store products globally for SKU selection
        window.availableProducts = products;
        
    } catch (error) {
        console.error('Error loading products:', error);
    }
}

// Setup form event handlers
function setupFormHandlers() {
    // Add SKU button
    document.getElementById('add-sku').addEventListener('click', addSkuInput);
    
    // Add store button
    document.getElementById('add-store').addEventListener('click', addNewStore);
    
    // All stores checkbox
    document.getElementById('all-stores').addEventListener('change', toggleAllStores);
    
    // Store checkboxes
    document.addEventListener('change', function(e) {
        if (e.target.classList.contains('store-checkbox')) {
            updateTotalCost();
        }
    });
    
    // Cost per job input
    document.getElementById('cost-per-job').addEventListener('input', updateTotalCost);
    
    // Form submission
    document.getElementById('create-job-form').addEventListener('submit', handleFormSubmit);
    
    // Cancel button
    document.getElementById('cancel-job').addEventListener('click', function() {
        if (confirm('Are you sure you want to cancel? All data will be lost.')) {
            window.location.href = 'brand-client.html';
        }
    });
    
    // Add initial SKU input
    addSkuInput();
}

// Add SKU input field
function addSkuInput() {
    const skuList = document.getElementById('sku-list');
    const skuCount = skuList.children.length;
    
    const skuHtml = `
        <div class="flex items-center space-x-2 sku-input">
            <input type="text" name="skus" placeholder="Enter SKU or product name" 
                   class="flex-1 border border-gray-300 rounded-md px-3 py-2 sku-field"
                   list="product-suggestions">
            <button type="button" class="btn-gray text-sm remove-sku" ${skuCount === 0 ? 'style="display:none"' : ''}>Remove</button>
        </div>
    `;
    
    skuList.insertAdjacentHTML('beforeend', skuHtml);
    
    // Setup remove button
    const removeBtn = skuList.lastElementChild.querySelector('.remove-sku');
    removeBtn.addEventListener('click', function() {
        this.parentElement.remove();
        updateSkuRemoveButtons();
    });
    
    updateSkuRemoveButtons();
}

// Update SKU remove buttons visibility
function updateSkuRemoveButtons() {
    const skuInputs = document.querySelectorAll('.sku-input');
    skuInputs.forEach((input, index) => {
        const removeBtn = input.querySelector('.remove-sku');
        removeBtn.style.display = skuInputs.length > 1 ? 'block' : 'none';
    });
}

// Add new store
async function addNewStore() {
    const storeName = document.getElementById('new-store-name').value.trim();
    const storeLocation = document.getElementById('new-store-location').value.trim();
    
    if (!storeName || !storeLocation) {
        alert('Please enter both store name and location');
        return;
    }
    
    try {
        // Create new store in database
        const newStore = {
            name: storeName,
            location: storeLocation,
            is_active: true,
            created_at: new Date().toISOString()
        };
        
        console.log('📝 Creating new store:', newStore);
        
        // Save store to database
        const result = await saSet('stores', newStore);
        
        if (result.success) {
            // Add store to the list
            addStoreToList(result.data);
            
            // Clear the form
            document.getElementById('new-store-name').value = '';
            document.getElementById('new-store-location').value = '';
            
            console.log('✅ Store created successfully');
        } else {
            alert('Error creating store: ' + result.error);
        }
        
    } catch (error) {
        console.error('Error creating store:', error);
        alert('Error creating store: ' + error.message);
    }
}

// Add store to the checkbox list
function addStoreToList(store) {
    const storeList = document.getElementById('store-list');
    
    const storeHtml = `
        <div class="flex items-center">
            <input type="checkbox" id="store-${store.id}" name="stores" value="${store.id}" 
                   class="rounded border-gray-300 store-checkbox">
            <label for="store-${store.id}" class="ml-2 text-sm text-gray-700">
                ${store.name} - ${store.location}
            </label>
        </div>
    `;
    
    storeList.insertAdjacentHTML('beforeend', storeHtml);
    
    // Update total cost
    updateTotalCost();
}

// Toggle all stores selection
function toggleAllStores() {
    const allStoresCheckbox = document.getElementById('all-stores');
    const storeCheckboxes = document.querySelectorAll('.store-checkbox');
    
    storeCheckboxes.forEach(checkbox => {
        checkbox.checked = allStoresCheckbox.checked;
    });
    
    updateTotalCost();
}

// Update total cost calculation
function updateTotalCost() {
    const costPerJob = parseFloat(document.getElementById('cost-per-job').value) || 0;
    const selectedStores = document.querySelectorAll('.store-checkbox:checked').length;
    const allStoresChecked = document.getElementById('all-stores').checked;
    
    let totalStores = selectedStores;
    if (allStoresChecked) {
        // Get total number of stores
        const allStores = document.querySelectorAll('.store-checkbox').length;
        totalStores = allStores;
    }
    
    const totalCost = costPerJob * totalStores;
    document.getElementById('total-job-cost').value = totalCost.toFixed(2);
}

// Handle form submission
async function handleFormSubmit(event) {
    event.preventDefault();
    
    const messageEl = document.getElementById('message');
    messageEl.classList.add('hidden');
    
    try {
        // Get form data
        const formData = new FormData(event.target);
        const title = formData.get('title').trim();
        const description = formData.get('description').trim();
        const instructions = formData.get('instructions').trim();
        const costPerJob = parseFloat(formData.get('cost-per-job'));
        
        // Validate required fields
        if (!title || !description || costPerJob <= 0) {
            showMessage(messageEl, 'Please fill in all required fields', 'error');
            return;
        }
        
        // Get selected stores
        const allStoresChecked = document.getElementById('all-stores').checked;
        let storeIds = [];
        
        if (allStoresChecked) {
            // Get all store IDs
            const stores = await saGet('stores', []);
            storeIds = stores.map(store => store.id);
        } else {
            // Get selected store IDs
            const selectedStores = document.querySelectorAll('.store-checkbox:checked');
            storeIds = Array.from(selectedStores).map(checkbox => checkbox.value);
        }
        
        if (storeIds.length === 0) {
            showMessage(messageEl, 'Please select at least one store', 'error');
            return;
        }
        
        // Get SKUs
        const skuInputs = document.querySelectorAll('.sku-field');
        const skus = Array.from(skuInputs)
            .map(input => input.value.trim())
            .filter(sku => sku.length > 0);
        
        if (skus.length === 0) {
            showMessage(messageEl, 'Please add at least one product/SKU', 'error');
            return;
        }
        
        // Get current user
        const { data: { user } } = await supabase.auth.getUser();
        
        // Ensure brand exists - for now we'll use a default brand
        // TODO: Implement brand selection in UI
        let brandId;
        const { data: brandData, error: brandError } = await supabase
            .from('brands')
            .select('id')
            .limit(1)
            .single();
        
        if (brandError) {
            console.error('❌ Error fetching brand:', brandError);
            showMessage(messageEl, 'Error loading brands: ' + brandError.message, 'error');
            return;
        }
        
        brandId = brandData?.id;
        
        if (!brandId) {
            showMessage(messageEl, 'No brands available. Please create a brand first.', 'error');
            return;
        }
        
        // Create main job record
        const jobData = {
            title,
            description,
            instructions: instructions || null,
            brand_id: brandId,
            client_id: user.id,
            status: 'pending',
            payout_per_store: costPerJob,
            created_at: new Date().toISOString()
        };
        
        console.log('📝 Creating job:', jobData);
        
        // Insert job into database
        const { data: jobRow, error: jobError } = await supabase
            .from('jobs')
            .insert(jobData)
            .select()
            .single();
        
        if (jobError) {
            console.error('❌ Job creation error:', jobError);
            showMessage(messageEl, 'Error creating job: ' + jobError.message, 'error');
            return;
        }
        
        console.log('✅ Main job created:', jobRow.id);
        
        // Get SKU IDs from product names/barcodes
        const skuIds = [];
        for (const skuName of skus) {
            // Try to find existing SKU by name or barcode
            const { data: skuData } = await supabase
                .from('skus')
                .select('id')
                .or(`name.ilike.%${skuName}%,upc.eq.${skuName}`)
                .limit(1)
                .single();
            
            if (skuData) {
                skuIds.push(skuData.id);
            }
        }
        
        if (skuIds.length === 0) {
            showMessage(messageEl, 'No matching SKUs found. Please add products first.', 'error');
            return;
        }
        
        // Create job_store_sku assignments
        const assignments = [];
        for (const storeId of storeIds) {
            for (const skuId of skuIds) {
                assignments.push({
                    job_id: jobRow.id,
                    store_id: storeId,
                    sku_id: skuId,
                    status: 'pending'
                });
            }
        }
        
        console.log(`📝 Creating ${assignments.length} assignments...`);
        
        const { error: assignmentError } = await supabase
            .from('job_store_skus')
            .upsert(assignments, {
                onConflict: 'job_id,store_id,sku_id',
                ignoreDuplicates: true
            });
        
        if (assignmentError) {
            console.error('❌ Assignment error:', assignmentError);
            showMessage(messageEl, 'Error creating assignments: ' + assignmentError.message, 'error');
            return;
        }
        
        console.log('✅ Job and assignments created successfully');
        showMessage(messageEl, 'Job created successfully! Redirecting to dashboard...', 'success');
        setTimeout(() => {
            window.location.href = 'brand-client.html';
        }, 2000);
        
    } catch (error) {
        console.error('Error creating job:', error);
        showMessage(messageEl, 'Error creating job: ' + error.message, 'error');
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
