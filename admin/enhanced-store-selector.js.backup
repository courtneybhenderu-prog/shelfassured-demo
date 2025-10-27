// Enhanced Store Selection for Job Creation Form - FIXED VERSION
// Uses banner_id instead of store_chain for filtering

class StoreSelector {
    constructor() {
        this.allStores = [];
        this.filteredStores = [];
        this.selectedStores = [];
        this.searchTerm = '';
        this.currentLocation = null;
        this.currentBannerFilter = null;
        this.isInitialized = false;
    }

    // Initialize store selector (don't load stores until search)
    async loadStores() {
        try {
            console.log('🔄 Initializing store selector...');
            
            // Wait for supabase to be available
            if (typeof supabase === 'undefined') {
                console.error('❌ Supabase not available');
                this.showError('Database connection not available');
                return false;
            }

            // Load banner options for dropdown
            await this.loadBannerOptions();

            // Don't load stores upfront - start empty
            this.allStores = [];
            this.filteredStores = [];
            this.isInitialized = true;
            
            console.log('✅ Store selector initialized - ready for search (LAZY LOADING ENABLED)');
            
            // Show empty state
            this.renderEmptyState();
            this.updateCounts();
            return true;
        } catch (error) {
            console.error('❌ Error initializing store selector:', error);
            this.showError('Failed to initialize store selector. Please refresh the page.');
            return false;
        }
    }

    // Load banner options for dropdown - NOW USES banner_id
    async loadBannerOptions() {
        try {
            console.log('🔄 Loading banner options...');
            
            // Load banner_id, banner_name, and store_count from view
            const { data: banners, error } = await supabase
                .from('v_distinct_banners')
                .select('banner_id, banner_name, store_count')
                .order('banner_name', { ascending: true });

            if (error) {
                console.error('❌ Error loading banners:', error);
                return;
            }

            console.log('✅ Loaded', banners.length, 'banner options');

            // Update dropdown
            const dropdown = document.getElementById('chain-filter');
            if (dropdown) {
                // Keep "All Chains" option
                const allChainsOption = dropdown.querySelector('option[value="all"]');
                dropdown.innerHTML = '';
                dropdown.appendChild(allChainsOption);

                // Add banner options with banner_id as value
                banners.forEach(banner => {
                    const option = document.createElement('option');
                    option.value = banner.banner_id;  // Use UUID as value
                    option.textContent = `${banner.banner_name} (${banner.store_count})`;  // Show store count
                    dropdown.appendChild(option);
                });

                console.log('✅ Banner dropdown updated with', banners.length, 'options');
            }
        } catch (error) {
            console.error('❌ Error loading banner options:', error);
        }
    }

    // Show empty state
    renderEmptyState() {
        const container = document.getElementById('store-search-results');
        if (container) {
            container.innerHTML = `
                <div class="text-center text-gray-500 py-8">
                    <div class="text-lg mb-2">🔍 Search for stores</div>
                    <div class="text-sm">Enter a ZIP code, city name, or store name to find stores</div>
                </div>
            `;
        }
    }

    // Show error message
    showError(message) {
        const container = document.getElementById('store-search-results');
        if (container) {
            container.innerHTML = `<div class="text-center text-red-500 py-4">${message}</div>`;
        }
    }

    // Update store counts
    updateCounts() {
        const selectedCount = document.getElementById('selected-count');
        const filteredCount = document.getElementById('filtered-count');
        
        if (selectedCount) {
            selectedCount.textContent = this.selectedStores.length;
        }
        if (filteredCount) {
            filteredCount.textContent = this.filteredStores.length;
        }
    }

    // Get user's current location for nearby store suggestions
    async getCurrentLocation() {
        return new Promise((resolve, reject) => {
            if (!navigator.geolocation) {
                reject(new Error('Geolocation not supported'));
                return;
            }

            navigator.geolocation.getCurrentPosition(
                (position) => {
                    this.currentLocation = {
                        latitude: position.coords.latitude,
                        longitude: position.coords.longitude
                    };
                    console.log('📍 Current location:', this.currentLocation);
                    this.renderStoreList(); // Re-render with distances
                    resolve(this.currentLocation);
                },
                (error) => {
                    console.warn('⚠️ Could not get location:', error.message);
                    reject(error);
                },
                { timeout: 10000, enableHighAccuracy: true }
            );
        });
    }

    // Search stores by name, city, or address
    async searchStores(term) {
        this.searchTerm = term.toLowerCase();
        
        // If we haven't loaded stores yet and user is searching, load them now
        if (this.allStores.length === 0 && this.searchTerm) {
            await this.loadStoresFromDatabase();
        }
        
        // Start with all stores or current banner filter
        let baseStores = [...this.allStores];
        
        // Apply search filter if there's a search term
        if (this.searchTerm) {
            baseStores = baseStores.filter(store => {
                const matches = store.name.toLowerCase().includes(this.searchTerm) ||
                    store.city.toLowerCase().includes(this.searchTerm) ||
                    store.address.toLowerCase().includes(this.searchTerm) ||
                    store.zip_code.includes(this.searchTerm) ||
                    (store.metro && store.metro.toLowerCase().includes(this.searchTerm)) ||
                    (store.METRO && store.METRO.toLowerCase().includes(this.searchTerm));
                
                return matches;
            });
        }
        
        // Apply current banner filter if one is active
        if (this.currentBannerFilter && this.currentBannerFilter !== 'all') {
            baseStores = baseStores.filter(store => {
                return store.banner_id === this.currentBannerFilter;
            });
        }
        
        this.filteredStores = baseStores;
        
        console.log(`🔍 Search "${term}" + Banner "${this.currentBannerFilter || 'all'}" = ${this.filteredStores.length} stores`);
        
        this.renderStoreList();
        this.updateCounts();
    }

    // Load stores from database when needed
    async loadStoresFromDatabase() {
        try {
            console.log('🔄 Loading stores from database...');
            console.log('🔍 Query details: Using pagination to get all stores');
            
            let allStores = [];
            let from = 0;
            const pageSize = 1000;
            let hasMore = true;
            
            while (hasMore) {
                console.log(`📄 Loading page ${Math.floor(from/pageSize) + 1} (records ${from + 1} to ${from + pageSize})`);
                
                const { data, error } = await supabase
                    .from('stores')
                    .select('*')
                    .eq('state', 'TX')
                    .eq('is_active', true)
                    .order('name')
                    .range(from, from + pageSize - 1);

                if (error) {
                    console.error('❌ Supabase error:', error);
                    throw error;
                }
                
                console.log(`📊 Page response: ${data ? data.length : 0} stores`);
                
                if (data && data.length > 0) {
                    allStores = allStores.concat(data);
                    from += pageSize;
                    hasMore = data.length === pageSize;
                } else {
                    hasMore = false;
                }
            }
            
            console.log(`✅ Loaded ${allStores.length} stores from database`);
            
            this.allStores = allStores;
            this.filteredStores = [...this.allStores];
            
            this.renderStoreList();
            this.updateCounts();
            
        } catch (error) {
            console.error('❌ Error loading stores:', error);
            this.showError('Failed to load stores. Please try again.');
        }
    }

    // Filter stores by banner - NOW USES banner_id
    filterByChain(chain) {
        console.log('🔍 Filtering by banner_id:', chain);
        
        // Store the current banner filter
        this.currentBannerFilter = chain;
        
        // Safety check
        if (!this.allStores || this.allStores.length === 0) {
            console.warn('⚠️ No stores loaded yet, loading stores first...');
            this.loadStoresFromDatabase().then(() => {
                this.filterByChain(chain);
            });
            return;
        }
        
        console.log('📊 Total stores available:', this.allStores.length);
        
        // Start with all stores
        let baseStores = [...this.allStores];
        
        // Apply banner filter using banner_id
        if (!chain || chain === 'all') {
            this.filteredStores = baseStores;
            console.log('✅ Showing all stores:', this.filteredStores.length);
        } else {
            this.filteredStores = baseStores.filter(store => {
                return store.banner_id === chain;
            });
            console.log('🎯 Filtered stores for banner:', this.filteredStores.length);
        }
        
        // Apply current search filter if there's a search term
        if (this.searchTerm) {
            this.filteredStores = this.filteredStores.filter(store => 
                store.name.toLowerCase().includes(this.searchTerm) ||
                store.city.toLowerCase().includes(this.searchTerm) ||
                store.address.toLowerCase().includes(this.searchTerm) ||
                store.zip_code.includes(this.searchTerm) ||
                (store.metro && store.metro.toLowerCase().includes(this.searchTerm)) ||
                (store.METRO && store.METRO.toLowerCase().includes(this.searchTerm))
            );
            console.log(`🔍 After search "${this.searchTerm}": ${this.filteredStores.length} stores`);
        }
        
        this.renderStoreList();
        this.updateCounts();
    }

    // Add store to selection
    addStore(store) {
        if (!this.selectedStores.find(s => s.id === store.id)) {
            this.selectedStores.push(store);
            this.renderSelectedStores();
            this.updateCounts();
            this.updateJobSummary();
        }
    }

    // Remove store from selection
    removeStore(storeId) {
        this.selectedStores = this.selectedStores.filter(s => s.id !== storeId);
        this.renderSelectedStores();
        this.updateCounts();
        this.updateJobSummary();
    }

    // Select all filtered stores
    selectAllFiltered() {
        this.filteredStores.forEach(store => {
            if (!this.selectedStores.find(s => s.id === store.id)) {
                this.selectedStores.push(store);
            }
        });
        this.renderSelectedStores();
        this.updateCounts();
        this.updateJobSummary();
    }

    // Clear all selections
    clearAll() {
        this.selectedStores = [];
        this.renderSelectedStores();
        this.updateCounts();
        this.updateJobSummary();
    }

    // Render the store list with search results
    renderStoreList() {
        const container = document.getElementById('store-search-results');
        if (!container) return;

        if (this.filteredStores.length === 0) {
            container.innerHTML = '<div class="text-center text-gray-500 py-4">No stores found</div>';
            return;
        }

        const html = this.filteredStores.map(store => {
            const isSelected = this.selectedStores.find(s => s.id === store.id);
            const distance = this.calculateDistance(store);
            
            // Use stores.name (not banner name) - this is the store display name from CSV STORE column
            const address = this.getFormattedAddress(store);
            
            return `
                <div class="store-item p-3 border border-gray-200 rounded-lg hover:bg-gray-50 cursor-pointer ${isSelected ? 'bg-blue-50 border-blue-300' : ''}" 
                     onclick="storeSelector.toggleStore('${store.id}')">
                    <div class="flex justify-between items-start">
                        <div class="flex-1">
                            <div class="font-medium text-gray-900">${store.name || 'Unnamed Store'}</div>
                            <div class="text-sm text-gray-600">${address}</div>
                            ${store.phone ? `<div class="text-sm text-gray-500">${store.phone}</div>` : ''}
                        </div>
                        <div class="text-right">
                            ${distance ? `<div class="text-sm text-blue-600">${distance} mi</div>` : ''}
                            <div class="text-sm text-gray-500">${isSelected ? '✓ Selected' : 'Click to select'}</div>
                        </div>
                    </div>
                </div>
            `;
        }).join('');

        container.innerHTML = html;
    }

    // Get formatted address
    getFormattedAddress(store) {
        const parts = [];
        if (store.address) parts.push(store.address);
        if (store.city) parts.push(store.city);
        if (store.state) parts.push(store.state);
        if (store.zip_code) parts.push(store.zip_code);
        
        return parts.join(', ');
    }

    // Render selected stores
    renderSelectedStores() {
        const container = document.getElementById('selected-stores');
        if (!container) return;

        if (this.selectedStores.length === 0) {
            container.innerHTML = '<div class="text-center text-gray-500 py-4">No stores selected</div>';
            return;
        }

        const html = this.selectedStores.map(store => {
            return `
                <div class="selected-store-item p-2 bg-green-100 border border-green-300 rounded-lg flex justify-between items-center">
                    <div class="flex-1">
                        <div class="font-medium text-green-800">${store.name}</div>
                        <div class="text-sm text-green-600">${this.getFormattedAddress(store)}</div>
                    </div>
                    <button onclick="storeSelector.removeStore('${store.id}')" 
                            class="text-green-600 hover:text-green-800 font-bold">×</button>
                </div>
            `;
        }).join('');

        container.innerHTML = html;
    }

    // Toggle store selection
    toggleStore(storeId) {
        const store = this.filteredStores.find(s => s.id === storeId);
        if (!store) return;

        const isSelected = this.selectedStores.find(s => s.id === storeId);
        if (isSelected) {
            this.removeStore(storeId);
        } else {
            this.addStore(store);
        }
    }

    // Calculate distance from current location (if available)
    calculateDistance(store) {
        if (!this.currentLocation || !store.latitude || !store.longitude) {
            return null;
        }

        const R = 3959; // Earth's radius in miles
        const dLat = this.toRad(store.latitude - this.currentLocation.latitude);
        const dLon = this.toRad(store.longitude - this.currentLocation.longitude);
        const lat1 = this.toRad(this.currentLocation.latitude);
        const lat2 = this.toRad(store.latitude);

        const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(lat1) * Math.cos(lat2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        const distance = R * c;

        return Math.round(distance * 10) / 10;
    }

    // Convert degrees to radians
    toRad(deg) {
        return deg * (Math.PI/180);
    }

    // Update job summary with selected stores
    updateJobSummary() {
        if (typeof window.updateJobSummary === 'function') {
            window.updateJobSummary();
        }
    }

    // Get selected stores for form submission
    getSelectedStores() {
        return this.selectedStores;
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', async function() {
    console.log('🔄 Initializing enhanced store selector...');
    
    // Wait a bit for other scripts to load
    setTimeout(async () => {
        window.storeSelector = new StoreSelector();
        
        const initialized = await window.storeSelector.loadStores();
        if (!initialized) {
            console.error('❌ Failed to initialize store selector');
            return;
        }

        // Try to get current location
        try {
            await window.storeSelector.getCurrentLocation();
            console.log('📍 Location-based store suggestions enabled');
        } catch (error) {
            console.log('📍 Location not available - using search only');
        }

        // Set up search input
        const searchInput = document.getElementById('store-search');
        if (searchInput) {
            searchInput.addEventListener('input', async (e) => {
                await window.storeSelector.searchStores(e.target.value);
            });
        }

        // Set up chain filter
        const chainFilter = document.getElementById('chain-filter');
        if (chainFilter) {
            chainFilter.addEventListener('change', (e) => {
                window.storeSelector.filterByChain(e.target.value);
            });
        }

        console.log('✅ Enhanced store selector initialized');
    }, 1000);
});

