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
    }

    // Initialize store selector (don't load stores until search)
    async loadStores() {
        try {
            console.log('🔄 Initializing store selector...');
            
            // Don't load stores upfront - start empty
            this.allStores = [];
            this.filteredStores = [];
            
            console.log('🚀 NEW VERSION: Store selector initialized - ready for search (LAZY LOADING ENABLED)');
            
            // Show empty state
            this.renderEmptyState();
            this.updateCounts();
            return true;
        } catch (error) {
            console.error('❌ Error initializing store selector:', error);
            return false;
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
            baseStores = baseStores.filter(store => 
                store.name.toLowerCase().includes(this.searchTerm) ||
                store.city.toLowerCase().includes(this.searchTerm) ||
                store.address.toLowerCase().includes(this.searchTerm) ||
                store.zip_code.includes(this.searchTerm) ||
                (store.metro && store.metro.toLowerCase().includes(this.searchTerm)) ||
                (store.METRO && store.METRO.toLowerCase().includes(this.searchTerm))
            );
        }
        
        // Apply current chain filter if one is active
        if (this.currentChainFilter && this.currentChainFilter !== 'all') {
            baseStores = baseStores.filter(store => {
                const storeChain = store.store_chain || store.chain;
                return storeChain && storeChain.toLowerCase().includes(this.currentChainFilter.toLowerCase());
            });
        }
        
        this.filteredStores = baseStores;
        
        console.log(`🔍 Search "${term}" + Chain "${this.currentChainFilter || 'all'}" = ${this.filteredStores.length} stores`);
        
        this.renderStoreList();
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
            
        } catch (error) {
            console.error('❌ Error loading stores:', error);
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
            this.filteredStores = baseStores.filter(store => {
                const storeChain = store.store_chain || store.chain; // Try both property names
                const storeName = store.name || '';
                
                // Check both store_chain and name for matches
                const chainMatch = storeChain && storeChain.toLowerCase().includes(chain.toLowerCase());
                const nameMatch = storeName.toLowerCase().includes(chain.toLowerCase());
                
                const matches = chainMatch || nameMatch;
                if (matches) {
                    console.log('✅ Match found:', store.name, '-> chain:', storeChain, 'name match:', nameMatch);
                }
                return matches;
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
            this.updateJobSummary();
        }
    }

    // Remove store from selection
    removeStore(storeId) {
        this.selectedStores = this.selectedStores.filter(s => s.id !== storeId);
        this.renderSelectedStores();
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
        this.updateJobSummary();
    }

    // Clear all selections
    clearAll() {
        console.log('🧹 Clear All button clicked');
        console.log('📊 Selected stores before clear:', this.selectedStores.length);
        
        this.selectedStores = [];
        this.renderSelectedStores();
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
            
            return `
                <div class="store-item p-3 border border-gray-200 rounded-lg hover:bg-gray-50 cursor-pointer ${isSelected ? 'bg-blue-50 border-blue-300' : ''}" 
                     onclick="storeSelector.toggleStore('${store.id}')">
                    <div class="flex justify-between items-start">
                        <div class="flex-1">
                            <div class="font-medium text-gray-900">${store.name}</div>
                            <div class="text-sm text-gray-600">${store.address}</div>
                            <div class="text-sm text-gray-500">${store.city}, ${store.state} ${store.zip_code}</div>
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

    // Render selected stores
    renderSelectedStores() {
        const container = document.getElementById('selected-stores');
        if (!container) return;

        if (this.selectedStores.length === 0) {
            container.innerHTML = '<div class="text-center text-gray-500 py-4">No stores selected</div>';
            return;
        }

        const html = this.selectedStores.map(store => `
            <div class="selected-store-item p-2 bg-green-100 border border-green-300 rounded-lg flex justify-between items-center">
                <div class="flex-1">
                    <div class="font-medium text-green-800">${store.name}</div>
                    <div class="text-sm text-green-600">${store.city}, ${store.state}</div>
                </div>
                <button onclick="storeSelector.removeStore('${store.id}')" 
                        class="text-green-600 hover:text-green-800 font-bold">×</button>
            </div>
        `).join('');

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
        // We'll integrate this with the existing form logic
        if (typeof window.updateJobSummary === 'function') {
            window.updateJobSummary();
        }
    }

    // Get selected stores for form submission
    getSelectedStores() {
        return this.selectedStores;
    }
}

// Initialize store selector
let storeSelector;

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', async function() {
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
});

// Export for global access
window.storeSelector = storeSelector;
