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
        this.userRole = null; // Will be set during initialization
    }

    // Get current user role (admin, brand_client, or shelfer)
    async getUserRole() {
        if (this.userRole) return this.userRole;
        
        try {
            const { data: { user } } = await supabase.auth.getUser();
            if (!user) return null;
            
            const { data: profile } = await supabase
                .from('users')
                .select('role')
                .eq('id', user.id)
                .single();
            
            this.userRole = profile?.role || null;
            return this.userRole;
        } catch (error) {
            console.error('Error getting user role:', error);
            return null;
        }
    }

    // Check if user is admin
    async isAdmin() {
        const role = await this.getUserRole();
        return role === 'admin';
    }

    // Check if user is brand
    async isBrand() {
        const role = await this.getUserRole();
        return role === 'brand_client';
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

            // Get user role early
            await this.getUserRole();
            const isAdmin = await this.isAdmin();
            const isBrand = await this.isBrand();
            console.log(`👤 User role: ${this.userRole || 'unknown'} (admin: ${isAdmin}, brand: ${isBrand})`);

            // Load banner options for dropdown (admins can see all, brands need search first)
            if (isAdmin) {
                await this.loadBannerOptions();
            } else {
                // For brands: don't load banner options until they search
                console.log('🔒 Brand user: Banner options will load after search');
            }

            // Don't load stores upfront - start empty
            this.allStores = [];
            this.filteredStores = [];
            this.isInitialized = true;
            
            // Show appropriate message based on role
            if (isBrand) {
                console.log('✅ Store selector initialized for BRAND - search required');
            } else if (isAdmin) {
                console.log('✅ Store selector initialized for ADMIN - full access');
            } else {
                console.log('✅ Store selector initialized - ready for search');
            }
            
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

    // Load chain options by extracting from STORE column (ADMIN ONLY - brands get chains from search results)
    async loadBannerOptions() {
        // Check if user is admin - only admins can load all chains
        const isAdmin = await this.isAdmin();
        if (!isAdmin) {
            console.log('🔒 Non-admin user: Banner options will be loaded from search results only');
            // For brands: we'll extract chains from search results instead
            return;
        }
        
        console.log('🔄 Loading chains from STORE column (ADMIN ONLY)...');
        
        // First, get all columns to see what's actually available
        const { data: sampleData, error: sampleError } = await supabase
            .from('stores')
            .select('*')
            .limit(5);
        
        if (sampleData && sampleData.length > 0) {
            console.log('🔍 First store sample (all columns):', sampleData[0]);
            console.log('🔍 First store keys:', Object.keys(sampleData[0]));
        }
        
        // Get STORE column - get ALL stores with STORE populated (paginate to get all stores)
        // ADMIN ONLY - this loads all stores to extract chains
        let allStoresData = [];
        let page = 0;
        const pageSize = 1000;
        let hasMore = true;
        
        while (hasMore) {
            const { data: pageData, error: pageError } = await supabase
                .from('stores')
                .select('STORE')
                .not('STORE', 'is', null)
                .neq('STORE', '')
                .order('STORE', { ascending: true })
                .range(page * pageSize, (page + 1) * pageSize - 1);
            
            if (pageError) {
                console.error('❌ Error loading page', page, ':', pageError);
                if (page === 0) {
                    // First page failed, try without pagination
                    const { data: data2, error: error2 } = await supabase
                        .from('stores')
                        .select('STORE')
                        .not('STORE', 'is', null)
                        .neq('STORE', '')
                        .order('STORE', { ascending: true })
                        .limit(1000);
                    if (error2) {
                        console.error('❌ Fallback also failed:', error2);
                        return [];
                    }
                    allStoresData = data2 || [];
                    break;
                }
                break;
            }
            
            if (pageData && pageData.length > 0) {
                allStoresData = allStoresData.concat(pageData);
                hasMore = pageData.length === pageSize;
                page++;
                console.log(`📄 Loaded page ${page}, total so far: ${allStoresData.length}`);
            } else {
                hasMore = false;
            }
        }
        
        const data = allStoresData;
        
        if (!data || data.length === 0) {
            console.warn('⚠️ No store data returned');
            return [];
        }

        // Check what keys are actually in the response
        if (data && data.length > 0) {
            console.log('🔍 Sample row keys:', Object.keys(data[0]));
            console.log('🔍 Sample row:', data[0]);
            console.log(`📊 Total stores loaded: ${data.length}`);
        }

        // Extract chain name (banner)
        // If STORE has " - ", extract part before it (e.g., "United Supermarkets - Andrews" → "United Supermarkets")
        // If STORE has no " - ", use whole value (e.g., "BIG 8 FOODS" → "BIG 8 FOODS")
        const extractChain = (storeName) => {
            if (!storeName) return null;
            const trimmed = storeName.trim();
            const dashIndex = trimmed.indexOf(' - ');
            if (dashIndex > 0) {
                return trimmed.substring(0, dashIndex).trim();
            }
            return trimmed; // No dash, use whole value as chain
        };

        // Extract unique chains from all stores
        const unique = [...new Set(data.map(r => {
            const storeValue = r.STORE || r.store || r.name || r['STORE'];
            return extractChain(storeValue);
        }).filter(Boolean))];
        
        console.log('📊 Found', unique.length, 'unique chains (expected: 72)');
        console.log('📊 First 10 chains:', unique.slice(0, 10));
        console.log('📊 Last 10 chains:', unique.slice(-10));
        
        const options = [{ value: 'all', label: 'All Chains' }]
            .concat(unique.map(chain => ({ value: chain, label: chain })));

        console.log('✅ Loaded', options.length - 1, 'chain options from STORE column');

        // Populate dropdown
        const dropdown = document.getElementById('chain-filter');
        if (dropdown) {
            dropdown.innerHTML = '';
            let addedCount = 0;
            options.forEach(opt => {
                const option = document.createElement('option');
                option.value = opt.value;
                option.textContent = opt.label;
                dropdown.appendChild(option);
                addedCount++;
            });
            console.log(`✅ Added ${addedCount} options to dropdown (should be ${options.length})`);
            console.log('✅ Dropdown now has', dropdown.options.length, 'total options');
            
            // Log last few options to verify
            if (dropdown.options.length > 0) {
                const lastFew = Array.from(dropdown.options).slice(-5).map(opt => opt.textContent);
                console.log('📋 Last 5 options in dropdown:', lastFew);
            }
        } else {
            console.warn('⚠️ Chain filter dropdown not found!');
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
        const trimmedTerm = (term || '').trim();
        this.searchTerm = trimmedTerm.toLowerCase();
        
        // For brands: require search term (search-first pattern)
        const isBrand = await this.isBrand();
        if (isBrand && !trimmedTerm) {
            this.showError('Please enter a search term (e.g., "Whole Foods Austin") to find stores.');
            this.allStores = [];
            this.filteredStores = [];
            this.renderStoreList();
            this.updateCounts();
            return;
        }
        
        try {
            console.log('🔍 Query built, executing with pagination...');
            
            // Use pagination to get ALL matching stores (not just first 2000)
            let allResults = [];
            let from = 0;
            const pageSize = 1000;
            let hasMore = true;
            
            while (hasMore) {
                // Rebuild query for each page to avoid Supabase query builder issues
                let pageQuery = supabase
                    .from('stores')
                    .select('id, name, STORE, address, city, state, zip_code, metro, METRO, metro_norm')
                    .not('STORE', 'is', null)
                    .neq('STORE', '');
                
                // Apply search filters (required for brands, optional for admins)
                if (this.searchTerm) {
                    pageQuery = pageQuery.or(`STORE.ilike.%${this.searchTerm}%,name.ilike.%${this.searchTerm}%,city.ilike.%${this.searchTerm}%,address.ilike.%${this.searchTerm}%,zip_code.ilike.%${this.searchTerm}%,metro.ilike.%${this.searchTerm}%,METRO.ilike.%${this.searchTerm}%,metro_norm.ilike.%${this.searchTerm}%`);
                } else if (isBrand) {
                    // Brand tried to search without term - should not happen due to check above
                    this.showError('Please enter a search term to find stores.');
                    return;
                }
                
                // Apply chain filter
                pageQuery = this.filterByChainQuery(pageQuery, this.currentChainFilter);
                
                const { data: pageData, error: pageError } = await pageQuery
                    .range(from, from + pageSize - 1);
                
                if (pageError) {
                    console.error('Search error:', pageError);
                    this.showError('Failed to search stores');
                    return;
                }
                
                if (pageData && pageData.length > 0) {
                    allResults = allResults.concat(pageData);
                    from += pageSize;
                    hasMore = pageData.length === pageSize; // If we got a full page, there might be more
                    console.log(`📄 Loaded page ${Math.floor(from/pageSize)}, total so far: ${allResults.length} stores`);
                } else {
                    hasMore = false;
                }
            }
            
            console.log(`✅ Search returned ${allResults.length} stores (paginated)`);
            
            this.allStores = allResults;
            this.filteredStores = [...this.allStores];
            
            console.log(`🔍 Search "${term}" + Chain "${this.currentChainFilter || 'all'}" = ${this.filteredStores.length} stores`);
            
            this.renderStoreList();
            this.updateCounts();
        } catch (error) {
            console.error('❌ Search failed:', error);
            this.showError('Search failed. Please try again.');
        }
    }

    // Helper function to apply chain filter to query (matches chain from STORE column)
    filterByChainQuery(query, selectedChain) {
        if (selectedChain && selectedChain !== 'all' && selectedChain !== 'All Chains') {
            // Filter by STORE starting with chain name + " - "
            return query.ilike('STORE', `${selectedChain} - %`);
        }
        return query;
    }

    // Build query with optional chain filter
    buildStoreQuery(selectedChain) {
        let query = supabase
            .from('stores')
            .select('*')
            .not('STORE', 'is', null)  // Only stores with STORE populated
            .neq('STORE', '');
            // Removed state filter
        
        // Apply chain filter at database level (exact match)
        query = this.filterByChainQuery(query, selectedChain);
        
        return query.order('STORE');
    }

    // Load stores from database when needed (ADMIN ONLY - brands must use search)
    async loadStoresFromDatabase() {
        // Check if user is admin - only admins can load all stores
        const isAdmin = await this.isAdmin();
        if (!isAdmin) {
            console.warn('⚠️ Non-admin user attempted to load all stores. This is blocked.');
            this.showError('Please use the search function to find stores. Full store lists are only available to administrators.');
            return;
        }
        
        try {
            console.log('🔄 Loading stores from database (ADMIN ONLY)...');
            console.log('🔍 Query details: Using pagination to get all stores');
            
            let allStores = [];
            let from = 0;
            const pageSize = 1000;
            let hasMore = true;
            
            while (hasMore) {
                console.log(`📄 Loading page ${Math.floor(from/pageSize) + 1} (records ${from + 1} to ${from + pageSize})`);
                
                const query = this.buildStoreQuery(this.currentChainFilter);
                const { data, error } = await query
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
    async filterByChain(chain) {
        console.log('🔍 Filtering by chain:', chain);
        
        // Store the current chain filter
        this.currentChainFilter = chain;
        
        // For brands: require search term before filtering
        const isBrand = await this.isBrand();
        if (isBrand && !this.searchTerm) {
            this.showError('Please search for stores first (e.g., "Whole Foods") before filtering by chain.');
            return;
        }
        
        // For brands: re-run search with chain filter
        if (isBrand && this.searchTerm) {
            await this.searchStores(this.searchTerm);
            return;
        }
        
        // For admins: can load all stores with chain filter
        const isAdmin = await this.isAdmin();
        if (isAdmin) {
            this.allStores = [];
            this.filteredStores = [];
            this.loadStoresFromDatabase();
        } else {
            this.showError('Chain filtering requires a search term. Please search for stores first.');
        }
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

    // Get display name for store (use STORE column)
    getDisplayName(store) {
        // Use the STORE column (uppercase) which contains values like "99 RANCH MARKET - AUSTIN"
        // Supabase may return it as lowercase 'store'
        return store.STORE || store.store || store.name || 'Unknown Store';
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

    // Programmatically set selected stores (array of store objects with id/name/STORE...)
    setSelectedStores(stores) {
        if (!Array.isArray(stores)) return;
        // Normalize to unique by id
        const uniq = new Map();
        stores.forEach(s => { if (s && s.id) uniq.set(s.id, s); });
        this.selectedStores = Array.from(uniq.values());
        this.renderSelectedStores();
        this.updateCounts();
        this.updateJobSummary();
    }

    // Programmatically set selected stores by IDs (fetch details if not in memory)
    async setSelectedStoresByIds(storeIds) {
        if (!Array.isArray(storeIds) || storeIds.length === 0) {
            this.setSelectedStores([]);
            return;
        }
        const need = new Set(storeIds);
        const have = new Map(this.allStores.map(s => [s.id, s]));
        const toFetch = storeIds.filter(id => !have.has(id));

        let fetched = [];
        if (toFetch.length > 0) {
            const { data, error } = await supabase
                .from('stores')
                .select('id, name, STORE, address, city, state, zip_code')
                .in('id', toFetch);
            if (!error && data) fetched = data;
        }
        const all = storeIds
            .map(id => have.get(id) || fetched.find(s => s.id === id))
            .filter(Boolean);
        this.setSelectedStores(all);
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