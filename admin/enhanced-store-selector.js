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

    // Load all Texas stores from Supabase
    async loadStores() {
        try {
            console.log('🔄 Loading Texas stores...');
            
            // Wait for supabase to be available
            if (typeof supabase === 'undefined') {
                console.error('❌ Supabase not available');
                this.showError('Database connection not available');
                return false;
            }

            const { data, error } = await supabase
                .from('stores')
                .select('*')
                .eq('state', 'TX')
                .eq('is_active', true)
                .order('name');

            if (error) throw error;
            
            this.allStores = data || [];
            this.filteredStores = [...this.allStores];
            this.isInitialized = true;
            
            console.log(`✅ Loaded ${this.allStores.length} Texas stores`);
            
            this.renderStoreList();
            this.updateCounts();
            return true;
        } catch (error) {
            console.error('❌ Error loading stores:', error);
            this.showError('Failed to load stores. Please refresh the page.');
            return false;
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
    searchStores(term) {
        this.searchTerm = term.toLowerCase();
        
        if (!this.searchTerm) {
            this.filteredStores = [...this.allStores];
        } else {
            this.filteredStores = this.allStores.filter(store => 
                store.name.toLowerCase().includes(this.searchTerm) ||
                store.city.toLowerCase().includes(this.searchTerm) ||
                store.address.toLowerCase().includes(this.searchTerm) ||
                store.zip_code.includes(this.searchTerm)
            );
        }
        
        this.renderStoreList();
        this.updateCounts();
    }

    // Filter stores by chain/banner
    filterByChain(chain) {
        if (!chain || chain === 'all') {
            this.filteredStores = [...this.allStores];
        } else {
            this.filteredStores = this.allStores.filter(store => 
                store.name.toLowerCase().includes(chain.toLowerCase())
            );
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
            
            // Use banner name instead of store number for display
            const displayName = this.getDisplayName(store);
            
            return `
                <div class="store-item p-3 border border-gray-200 rounded-lg hover:bg-gray-50 cursor-pointer ${isSelected ? 'bg-blue-50 border-blue-300' : ''}" 
                     onclick="storeSelector.toggleStore('${store.id}')">
                    <div class="flex justify-between items-start">
                        <div class="flex-1">
                            <div class="font-medium text-gray-900">${displayName}</div>
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

    // Get display name for store (prefer banner name over store number)
    getDisplayName(store) {
        // If the name looks like a store number (all digits), try to get banner name
        if (/^\d+$/.test(store.name)) {
            // Try to extract banner from the name or use a default
            if (store.name.includes('1313')) return 'Food Lion';
            if (store.name.includes('288')) return 'H-E-B Alvin';
            if (store.name.includes('17')) return 'H-E-B Angleton';
            if (store.name.includes('458')) return 'H-E-B Carthage';
            if (store.name.includes('257')) return 'H-E-B Cleveland';
            if (store.name.includes('256')) return 'H-E-B Columbus';
            if (store.name.includes('287')) return 'H-E-B Crockett';
            if (store.name.includes('351')) return 'H-E-B Edna';
            if (store.name.includes('53')) return 'H-E-B Groves';
            if (store.name.includes('416')) return 'H-E-B La Grange';
            if (store.name.includes('339')) return 'H-E-B Livingston';
            if (store.name.includes('116')) return 'H-E-B Lumberton';
            if (store.name.includes('35')) return 'H-E-B Orange';
            if (store.name.includes('86')) return 'H-E-B Port Arthur';
            if (store.name.includes('348')) return 'H-E-B Santa Fe';
            if (store.name.includes('271')) return 'H-E-B West Columbia';
            if (store.name.includes('355')) return 'H-E-B Yoakum';
            // Default fallback
            return `H-E-B Store ${store.name}`;
        }
        
        // If name already looks like a proper store name, use it
        return store.name;
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
                        <div class="text-sm text-green-600">${store.city}, ${store.state}</div>
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
}

// Initialize store selector
let storeSelector;

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', async function() {
    console.log('🔄 Initializing enhanced store selector...');
    
    // Wait a bit for other scripts to load
    setTimeout(async () => {
        storeSelector = new StoreSelector();
        
        // Load stores
        const storesLoaded = await storeSelector.loadStores();
        if (!storesLoaded) {
            console.error('❌ Failed to load stores - falling back to manual entry');
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
            searchInput.addEventListener('input', (e) => {
                storeSelector.searchStores(e.target.value);
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