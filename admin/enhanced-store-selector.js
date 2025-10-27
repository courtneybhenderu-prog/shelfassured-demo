// Enhanced Store Selection for Job Creation Form
// This replaces the manual store entry with smart search and GPS integration

// Store search and filtering functionality
class StoreSelector {
    constructor() {
        this.allStores = [];
        this.filteredStores = [];
        this.selectedStores = [];
        this.searchTerm = '';
        this.currentLocation = null;
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

    // Load chain options directly from stores table
    async loadBannerOptions() {
        const { data, error } = await supabase
            .from('stores')
            .select('store_chain')
            .not('store_chain', 'is', null)
            .neq('store_chain', '')
            .order('store_chain', { ascending: true });

        if (error) {
            console.error('loadBannerOptions error:', error);
            return [];
        }

        const unique = [...new Set((data || []).map(r => r.store_chain))];
        // Value MUST equal the exact store_chain used in WHERE
        const options = [{ value: 'all', label: 'All Chains' }]
            .concat(unique.map(chain => ({ value: chain, label: chain })));

        console.log('✅ Loaded', options.length - 1, 'chain options from stores');

        // Populate dropdown
        const dropdown = document.getElementById('chain-filter');
        if (dropdown) {
            dropdown.innerHTML = '';
            options.forEach(opt => {
                const option = document.createElement('option');
                option.value = opt.value;
                option.textContent = opt.label;
                dropdown.appendChild(option);
            });
        }

        return options;
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
        
        // Start with all stores or current chain filter
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
                
                // Debug logging for metro matches
                if (this.searchTerm === 'austin' && (store.metro || store.METRO)) {
                    console.log(`🔍 Metro check for ${store.name}:`, {
                        metro: store.metro,
                        METRO: store.METRO,
                        matches: matches
                    });
                }
                
                return matches;
            });
        }
        
        // Apply current chain filter if one is active (EXACT match)
        if (this.currentChainFilter && this.currentChainFilter !== 'all') {
            baseStores = baseStores.filter(store => {
                return store.store_chain === this.currentChainFilter;
            });
        }
        
        this.filteredStores = baseStores;
        
        console.log(`🔍 Search "${term}" + Chain "${this.currentChainFilter || 'all'}" = ${this.filteredStores.length} stores`);
        
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
                    hasMore = data.length === pageSize; // If we got a full page, there might be more
                } else {
                    hasMore = false;
                }
            }
            
            console.log('📊 Final response from Supabase:');
            console.log('  - Data type:', typeof allStores);
            console.log('  - Data length:', allStores.length);
            console.log('  - Is array:', Array.isArray(allStores));
            
            this.allStores = allStores;
            this.filteredStores = [...this.allStores];
            
            console.log(`✅ Loaded ${this.allStores.length} stores from database`);
            console.log('🔍 First few stores:', this.allStores.slice(0, 3).map(s => s.name));
            console.log('🔍 Last few stores:', this.allStores.slice(-3).map(s => s.name));
            
            this.renderStoreList();
            this.updateCounts();
            
        } catch (error) {
            console.error('❌ Error loading stores:', error);
            this.showError('Failed to load stores. Please try again.');
        }
    }

    // Filter stores by chain/banner
    filterByChain(chain) {
        console.log('🔍 Filtering by chain:', chain);
        
        // Store the current chain filter
        this.currentChainFilter = chain;
        
        // Safety check
        if (!this.allStores || this.allStores.length === 0) {
            console.warn('⚠️ No stores loaded yet, loading stores first...');
            this.loadStoresFromDatabase().then(() => {
                this.filterByChain(chain); // Retry after loading
            });
            return;
        }
        
        console.log('📊 Total stores available:', this.allStores.length);
        
        // Update button active states
        this.updateActiveButton(chain);
        
        // Start with all stores
        let baseStores = [...this.allStores];
        
        // Apply chain filter
        if (!chain || chain === 'all') {
            this.filteredStores = baseStores;
            console.log('✅ Showing all stores:', this.filteredStores.length);
        } else {
            // EXACT match on store_chain field
            this.filteredStores = baseStores.filter(store => {
                return store.store_chain === chain;
            });
            console.log('🎯 Filtered stores for', chain + ':', this.filteredStores.length);
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

    // Update active button visual state
    updateActiveButton(activeChain) {
        // Remove active class from all buttons
        const buttons = document.querySelectorAll('[onclick*="filterByChain"]');
        buttons.forEach(button => {
            button.classList.remove('bg-blue-600', 'ring-2', 'ring-blue-500');
            button.classList.add('bg-green-600');
        });
        
        // Add active class to clicked button
        const activeButton = document.querySelector(`[onclick*="filterByChain('${activeChain}')"]`);
        if (activeButton) {
            activeButton.classList.remove('bg-green-600');
            activeButton.classList.add('bg-blue-600', 'ring-2', 'ring-blue-500');
        }
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
        console.log('🧹 Clear All button clicked');
        console.log('📊 Selected stores before clear:', this.selectedStores.length);
        
        this.selectedStores = [];
        this.renderSelectedStores();
        this.updateCounts();
        this.updateJobSummary();
        
        console.log('✅ All stores cleared');
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
            
            // Use banner name instead of store number for display
            const displayName = this.getDisplayName(store);
            
            return `
                <div class="store-item p-3 border border-gray-200 rounded-lg hover:bg-gray-50 cursor-pointer ${isSelected ? 'bg-blue-50 border-blue-300' : ''}" 
                     onclick="storeSelector.toggleStore('${store.id}')">
                    <div class="flex justify-between items-start">
                        <div class="flex-1">
                            <div class="font-medium text-gray-900">${displayName}</div>
                            <div class="text-sm text-gray-600">${this.getFormattedAddress(store)}</div>
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

    // Get display name for store (use Column E - STORE from Google Sheet)
    getDisplayName(store) {
        // Use the 'name' field which should contain Column E (STORE) from Google Sheet
        // This gives us clean names like "HEB - ALVIN", "WHOLE FOODS MARKET - CEDAR PARK"
        return store.name || 'Unknown Store';
    }

    // Get formatted address (concatenate G+H+I+J: ADDRESS + CITY + STATE + ZIP)
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
            const displayName = this.getDisplayName(store);
            return `
                <div class="selected-store-item p-2 bg-green-100 border border-green-300 rounded-lg flex justify-between items-center">
                    <div class="flex-1">
                        <div class="font-medium text-green-800">${displayName}</div>
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

        return Math.round(distance * 10) / 10; // Round to 1 decimal place
    }

    // Convert degrees to radians
    toRad(deg) {
        return deg * (Math.PI/180);
    }

    // Update job summary with selected stores
    updateJobSummary() {
        // This will be called by the existing updateJobSummary function
        if (typeof window.updateJobSummary === 'function') {
            window.updateJobSummary();
        }
    }

    // Get selected stores for form submission
    getSelectedStores() {
        return this.selectedStores;
    }

    // Add new store (for future implementation)
    async addNewStore(storeData) {
        try {
            console.log('🔄 Adding new store:', storeData);
            
            // Auto-geocode address to get GPS coordinates
            const coordinates = await this.geocodeAddress(storeData.address, storeData.city, storeData.state);
            
            const newStore = {
                name: storeData.name,
                address: storeData.address,
                city: storeData.city,
                state: storeData.state,
                zip_code: storeData.zip_code,
                chain: storeData.chain || 'Unknown',
                banner: storeData.banner || storeData.name,
                store_number: storeData.store_number || '',
                phone: storeData.phone || '',
                metro: storeData.metro || '',
                country: 'US',
                latitude: coordinates.lat,
                longitude: coordinates.lng,
                source: 'user_added', // Flag as user-added
                is_active: true,
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
            };

            const { data, error } = await supabase
                .from('stores')
                .insert([newStore])
                .select()
                .single();

            if (error) throw error;

            // Add to local arrays
            this.allStores.push(data);
            this.filteredStores.push(data);
            
            // Re-render
            this.renderStoreList();
            this.updateCounts();

            console.log('✅ New store added:', data);
            
            // Notify admin (future implementation)
            await this.notifyAdminNewStore(data);
            
            return data;
        } catch (error) {
            console.error('❌ Error adding new store:', error);
            throw error;
        }
    }

    // Geocode address to get GPS coordinates
    async geocodeAddress(address, city, state) {
        try {
            const fullAddress = `${address}, ${city}, ${state}`;
            console.log('📍 Geocoding address:', fullAddress);
            
            const response = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(fullAddress)}&limit=1&countrycodes=us`);
            const data = await response.json();
            
            if (data && data.length > 0) {
                const result = data[0];
                console.log('✅ Geocoding successful:', result);
                
                // Validate coordinates are in Texas (rough bounds)
                const lat = parseFloat(result.lat);
                const lng = parseFloat(result.lon);
                
                if (lat >= 25.5 && lat <= 36.5 && lng >= -106.5 && lng <= -93.5) {
                    return { lat, lng };
                } else {
                    console.warn('⚠️ Coordinates outside Texas bounds, using fallback');
                }
            }
            
            throw new Error('Address not found or outside Texas');
        } catch (error) {
            console.error('❌ Geocoding failed:', error);
            // Return default coordinates (Austin, TX) as fallback
            return { lat: 30.2672, lng: -97.7431 };
        }
    }

    // Notify admin of new store (future implementation)
    async notifyAdminNewStore(store) {
        try {
            // This could send an email notification or create a notification record
            console.log('📧 Admin notification: New store added by user:', store.name);
            
            // Future: Send email notification to admin
            // Future: Create notification record in database
            // Future: Update admin dashboard with pending review items
            
        } catch (error) {
            console.error('❌ Error sending admin notification:', error);
        }
    }
}

// Initialize store selector
// Global store selector instance
let storeSelector;

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', async function() {
    console.log('🔄 Initializing enhanced store selector...');
    
    // Wait a bit for other scripts to load
    setTimeout(async () => {
        storeSelector = new StoreSelector();
        
        // Make storeSelector globally accessible
        window.storeSelector = storeSelector;
        
        // Initialize store selector (don't load stores until search)
        const initialized = await storeSelector.loadStores();
        if (!initialized) {
            console.error('❌ Failed to initialize store selector');
            return;
        }

        // Try to get current location
        try {
            await storeSelector.getCurrentLocation();
            console.log('📍 Location-based store suggestions enabled');
        } catch (error) {
            console.log('📍 Location not available - using search only');
        }

        // Set up search input
        const searchInput = document.getElementById('store-search');
        if (searchInput) {
            searchInput.addEventListener('input', async (e) => {
                await storeSelector.searchStores(e.target.value);
            });
        }

        // Set up chain filter
        const chainFilter = document.getElementById('chain-filter');
        if (chainFilter) {
            chainFilter.addEventListener('change', (e) => {
                storeSelector.filterByChain(e.target.value);
            });
        }

        console.log('✅ Enhanced store selector initialized');
    }, 1000); // Wait 1 second for other scripts to load
});

// Export for global access
window.storeSelector = storeSelector;