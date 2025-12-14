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
        this.activeFilters = {
            state: null,
            banner: null
        };
        this.searchDebounceTimer = null;
        
        // State detection mapping
        this.stateCodes = new Set([
            'al', 'ak', 'az', 'ar', 'ca', 'co', 'ct', 'de', 'dc', 'fl', 'ga',
            'hi', 'id', 'il', 'in', 'ia', 'ks', 'ky', 'la', 'me', 'md',
            'ma', 'mi', 'mn', 'ms', 'mo', 'mt', 'ne', 'nv', 'nh', 'nj',
            'nm', 'ny', 'nc', 'nd', 'oh', 'ok', 'or', 'pa', 'ri', 'sc',
            'sd', 'tn', 'tx', 'ut', 'vt', 'va', 'wa', 'wv', 'wi', 'wy'
        ]);
        
        this.stateNames = {
            'alabama': 'al', 'alaska': 'ak', 'arizona': 'az', 'arkansas': 'ar',
            'california': 'ca', 'colorado': 'co', 'connecticut': 'ct', 'delaware': 'de',
            'district of columbia': 'dc', 'florida': 'fl', 'georgia': 'ga',
            'hawaii': 'hi', 'idaho': 'id', 'illinois': 'il', 'indiana': 'in',
            'iowa': 'ia', 'kansas': 'ks', 'kentucky': 'ky', 'louisiana': 'la',
            'maine': 'me', 'maryland': 'md', 'massachusetts': 'ma', 'michigan': 'mi',
            'minnesota': 'mn', 'mississippi': 'ms', 'missouri': 'mo', 'montana': 'mt',
            'nebraska': 'ne', 'nevada': 'nv', 'new hampshire': 'nh', 'new jersey': 'nj',
            'new mexico': 'nm', 'new york': 'ny', 'north carolina': 'nc', 'north dakota': 'nd',
            'ohio': 'oh', 'oklahoma': 'ok', 'oregon': 'or', 'pennsylvania': 'pa',
            'rhode island': 'ri', 'south carolina': 'sc', 'south dakota': 'sd',
            'tennessee': 'tn', 'texas': 'tx', 'utah': 'ut', 'vermont': 'vt',
            'virginia': 'va', 'washington': 'wa', 'west virginia': 'wv',
            'wisconsin': 'wi', 'wyoming': 'wy'
        };
    }

    // Debounce function for typeahead search
    debounce(func, wait) {
        const self = this; // Capture 'this' context
        return function(...args) {
            clearTimeout(self.searchDebounceTimer);
            self.searchDebounceTimer = setTimeout(() => {
                func.apply(self, args);
            }, wait);
        };
    }

    // Parse search intent
    parseSearchIntent(term) {
        const trimmed = term.trim();
        if (!trimmed) return { type: 'empty', term: '' };
        
        const lowerTerm = trimmed.toLowerCase();
        const tokens = trimmed.split(/\s+/).filter(t => t.length > 0);
        
        // Intent 1: Store number (digits only or starts with digits)
        if (/^\d+$/.test(trimmed) || /^\d+/.test(trimmed)) {
            return { type: 'store_number', term: trimmed, prefix: /^\d+/.exec(trimmed)[0] };
        }
        
        // Intent 2: City + State (last token is valid US state code)
        if (tokens.length >= 2) {
            const lastToken = tokens[tokens.length - 1].toLowerCase();
            const stateCode = this.stateCodes.has(lastToken) ? lastToken.toUpperCase() : 
                            (this.stateNames[lastToken] ? this.stateNames[lastToken].toUpperCase() : null);
            
            if (stateCode) {
                const cityPart = tokens.slice(0, -1).join(' ');
                return { 
                    type: 'city_state', 
                    term: trimmed,
                    city: cityPart,
                    state: stateCode
                };
            }
        }
        
        // Intent 3: State only (entire input is state name or code)
        if (this.stateCodes.has(lowerTerm)) {
            return { type: 'state_only', term: trimmed, state: lowerTerm.toUpperCase() };
        }
        if (this.stateNames[lowerTerm]) {
            return { type: 'state_only', term: trimmed, state: this.stateNames[lowerTerm].toUpperCase() };
        }
        
        // Intent 4: Banner or general (query banner and STORE only, not address)
        return { type: 'banner_general', term: trimmed };
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

    // Load banner options from store_banners view (ADMIN ONLY - brands get chains from search results)
    async loadBannerOptions() {
        // Check if user is admin - only admins can load all chains
        const isAdmin = await this.isAdmin();
        if (!isAdmin) {
            console.log('🔒 Non-admin user: Banner options will be loaded from search results only');
            return;
        }
        
        console.log('🔄 Loading banners from store_banners view (ADMIN ONLY)...');
        
        try {
            // Get distinct banners from store_banners view
            // Note: The view should be created by running create-store-banners-view.sql
            // IMPORTANT: Supabase JS client queries views the same way as tables
            console.log('🔄 Attempting to load banners from store_banners view...');
            console.log('🔄 Query: .from("store_banners").select("banner")');
            
            const { data: banners, error } = await supabase
                .from('store_banners')
                .select('banner')
                .order('banner', { ascending: true });
            
            console.log('🔄 Query result - data:', banners ? `${banners.length} rows` : 'null', 'error:', error ? 'yes' : 'no');
            
            if (error) {
                console.error('❌ Error loading banners from store_banners view:', error);
                console.error('❌ Error details:', JSON.stringify(error, null, 2));
                console.log('⚠️ View may not exist yet. Run create-store-banners-view.sql first.');
                console.log('⚠️ Or the view exists but has a different name/structure.');
                // Fallback: query stores directly for distinct banners from banner column
                console.log('🔄 Falling back to querying stores directly for distinct banners...');
                const { data: storeData, error: storeError } = await supabase
                    .from('stores')
                    .select('banner')
                    .eq('is_active', true)
                    .not('banner', 'is', null)
                    .neq('banner', '')
                    .limit(5000);
                
                if (storeError) {
                    console.error('❌ Fallback also failed:', storeError);
                    // Last resort: extract from STORE column (first part before " - ")
                    console.log('🔄 Last resort: Extracting from STORE column...');
                    const { data: storeData2, error: storeError2 } = await supabase
                        .from('stores')
                        .select('STORE')
                        .eq('is_active', true)
                        .not('STORE', 'is', null)
                        .neq('STORE', '')
                        .limit(5000);
                    
                    if (storeError2) {
                        console.error('❌ Last resort also failed:', storeError2);
                        return [];
                    }
                    
                    const extractBanner = (storeName) => {
                        if (!storeName) return null;
                        // Look for " - " pattern (space-dash-space)
                        const dashIndex = storeName.indexOf(' - ');
                        if (dashIndex > 0) {
                            const banner = storeName.substring(0, dashIndex).trim();
                            // Validate: banner should not be empty and should be reasonable length
                            if (banner && banner.length > 0 && banner.length < 100) {
                                return banner;
                            }
                        }
                        return null;
                    };
                    
                    const extractedBanners = (storeData2 || [])
                        .map(s => extractBanner(s.STORE || s.store))
                        .filter(Boolean);
                    
                    const uniqueBanners = [...new Set(extractedBanners)].sort();
                    
                    console.log(`✅ Extracted ${uniqueBanners.length} unique banners from STORE column`);
                    console.log(`📋 Sample extracted banners (first 5):`, uniqueBanners.slice(0, 5));
                    console.log(`📋 Sample extracted banners (last 5):`, uniqueBanners.slice(-5));
                    
                    if (uniqueBanners.length > 100) {
                        console.warn(`⚠️ WARNING: Found ${uniqueBanners.length} unique banners (expected ~72). This suggests extraction may be incorrect.`);
                        console.warn(`⚠️ Check if STORE column format is consistent (should be "Banner - City - State")`);
                    }
                    
                    const options = [{ value: 'all', label: 'All Chains' }]
                        .concat(uniqueBanners.map(banner => ({ value: banner, label: banner })));
                    
                    this.populateBannerDropdown(options);
                    return options;
                }
                
                const uniqueBanners = [...new Set((storeData || [])
                    .map(s => s.banner)
                    .filter(Boolean))].sort();
                
                console.log(`✅ Extracted ${uniqueBanners.length} unique banners from stores.banner column`);
                const options = [{ value: 'all', label: 'All Chains' }]
                    .concat(uniqueBanners.map(banner => ({ value: banner, label: banner })));
                
                this.populateBannerDropdown(options);
                return options;
            }
            
            if (!banners || banners.length === 0) {
                console.warn('⚠️ No banners found in store_banners view');
                return [];
            }
            
            console.log('✅ Loaded', banners.length, 'banners from store_banners view');
            
            const options = [{ value: 'all', label: 'All Chains' }]
                .concat(banners.map(b => ({ value: b.banner, label: b.banner })));
            
            this.populateBannerDropdown(options);
            return options;
        } catch (error) {
            console.error('❌ Error in loadBannerOptions:', error);
            return [];
        }
    }

    // Populate banner dropdown with options
    populateBannerDropdown(options) {

        const dropdown = document.getElementById('chain-filter');
        if (dropdown) {
            dropdown.innerHTML = '';
            options.forEach(opt => {
                const option = document.createElement('option');
                option.value = opt.value;
                option.textContent = opt.label;
                dropdown.appendChild(option);
            });
            console.log(`✅ Populated dropdown with ${options.length} banner options`);
        } else {
            console.warn('⚠️ Chain filter dropdown not found!');
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

    // Search stores with intent-based queries and ranking
    async searchStores(term) {
        const trimmedTerm = (term || '').trim();
        this.searchTerm = trimmedTerm.toLowerCase();
        
        console.log('🔍 searchStores called with term:', trimmedTerm);
        
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
        
        // For admins: if no search term, show empty state
        if (!trimmedTerm) {
            console.log('⚠️ No search term provided, clearing results');
            this.allStores = [];
            this.filteredStores = [];
            this.renderStoreList();
            this.updateCounts();
            this.renderFilterChips();
            return;
        }
        
        // Parse search intent
        const intent = this.parseSearchIntent(trimmedTerm);
        console.log('🎯 Parsed search intent:', JSON.stringify(intent, null, 2));
        console.log('🎯 Intent type:', intent.type, '| State:', intent.state, '| Term:', intent.term);
        
        // CRITICAL DEBUG: Verify state detection
        if (intent.type === 'state_only') {
            console.log('✅ STATE-ONLY DETECTED - Will query ONLY state column');
            console.log('✅ State code:', intent.state);
        } else if (intent.type === 'banner_general') {
            console.log('⚠️ FALLING BACK TO BANNER_GENERAL - Will search STORE column (may match addresses)');
        }
        
        try {
            // Use pagination to get ALL matching stores
            let allResults = [];
            let from = 0;
            const pageSize = 1000;
            let hasMore = true;
            
            while (hasMore) {
                let pageQuery = supabase
                    .from('stores')
                    .select('id, name, STORE, address, city, state, zip_code, metro, METRO, metro_norm, store_number, banner')
                    .not('STORE', 'is', null)
                    .neq('STORE', '')
                    .eq('is_active', true);
                
                // Build query based on intent
                switch (intent.type) {
                    case 'store_number':
                        // Store number: query store_number only, prefix match
                        pageQuery = pageQuery.ilike('store_number', `${intent.prefix}%`);
                        console.log('🔍 Intent: Store number - querying store_number prefix:', intent.prefix);
                        break;
                    
                    case 'city_state':
                        // City + State: query city and state together (AND condition)
                        // Use ilike for case-insensitive matching
                        pageQuery = pageQuery
                            .ilike('city', `%${intent.city}%`)
                            .ilike('state', intent.state); // Exact state match (WY) - case-insensitive via ilike
                        console.log('🔍 Intent: City + State - querying city:', intent.city, 'state:', intent.state);
                        break;
                    
                    case 'state_only':
                        // State only: query ONLY state column (prevents Wyoming matching Wyoming Blvd, Ohio matching Ohio Dr)
                        // CRITICAL: Only query state column, do NOT include address, city, STORE, or any other fields
                        const stateCode = intent.state;
                        const stateName = Object.keys(this.stateNames).find(name => 
                            this.stateNames[name] === stateCode.toLowerCase()
                        );
                        
                        // Use .or() with proper Supabase syntax
                        // Format: "column.eq.value,column.ilike.pattern"
                        // This creates: (state = 'OH' OR state ILIKE '%ohio%')
                        // IMPORTANT: This ONLY matches the state column, never address or STORE
                        if (stateName) {
                            pageQuery = pageQuery.or(`state.eq.${stateCode},state.ilike.%${stateName}%`);
                            console.log('🔍 Intent: State only - querying ONLY state column');
                            console.log('🔍 Query: state =', stateCode, 'OR state ILIKE', `%${stateName}%`);
                            console.log('🔍 This will NOT match address or STORE column');
                        } else {
                            // Just match the state code exactly
                            pageQuery = pageQuery.eq('state', stateCode);
                            console.log('🔍 Intent: State only - querying ONLY state column (exact match)');
                            console.log('🔍 Query: state =', stateCode);
                        }
                        break;
                    
                    case 'banner_general':
                    default:
                        // Banner or general: query banner and STORE only, NOT address
                        const searchPattern = `%${intent.term}%`;
                        pageQuery = pageQuery.or(`banner.ilike.${searchPattern},STORE.ilike.${searchPattern}`);
                        console.log('🔍 Intent: Banner/General - querying banner and STORE only');
                        break;
                }
                
                // Apply chain filter if active
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
                    hasMore = pageData.length === pageSize;
                    console.log(`📄 Loaded page ${Math.floor(from/pageSize)}, total so far: ${allResults.length} stores`);
                } else {
                    hasMore = false;
                }
            }
            
            console.log(`✅ Search returned ${allResults.length} stores (paginated)`);
            
            // Debug: Log sample results to verify query is correct
            if (allResults.length > 0) {
                console.log(`📋 Sample results (first 3):`, allResults.slice(0, 3).map(s => ({
                    STORE: s.STORE,
                    state: s.state,
                    city: s.city,
                    address: s.address?.substring(0, 30) + '...'
                })));
            }
            
            // Rank and sort results
            if (allResults.length > 0) {
                const rankedResults = this.rankSearchResults(allResults, intent);
                this.allStores = rankedResults;
                // Apply active filters after search
                this.applyFilters();
                console.log(`🔍 Search "${term}" (${intent.type}) + Filters = ${this.filteredStores.length} stores`);
            } else {
                this.allStores = [];
                this.filteredStores = [];
                console.log(`🔍 No stores found for search term: "${term}" (${intent.type})`);
            }
            
            this.renderStoreList();
            this.updateCounts();
            this.renderFilterChips();
        } catch (error) {
            console.error('❌ Search failed:', error);
            this.showError('Search failed. Please try again.');
        }
    }

    // Rank search results by match quality
    rankSearchResults(results, intent) {
        return results.map(store => {
            let rank = 0;
            const term = intent.term.toLowerCase();
            
            switch (intent.type) {
                case 'store_number':
                    // Exact match = highest rank
                    if (store.store_number && store.store_number.toLowerCase() === term) {
                        rank = 100;
                    }
                    // Prefix match = high rank
                    else if (store.store_number && store.store_number.toLowerCase().startsWith(term)) {
                        rank = 90;
                    }
                    break;
                
                case 'city_state':
                    // Exact city + exact state = highest rank
                    if (store.city && store.state &&
                        store.city.toLowerCase() === intent.city.toLowerCase() &&
                        store.state.toUpperCase() === intent.state) {
                        rank = 100;
                    }
                    // Partial city + exact state = high rank
                    else if (store.city && store.state &&
                             store.city.toLowerCase().includes(intent.city.toLowerCase()) &&
                             store.state.toUpperCase() === intent.state) {
                        rank = 80;
                    }
                    break;
                
                case 'state_only':
                    // Exact state match = highest rank
                    if (store.state && store.state.toUpperCase() === intent.state) {
                        rank = 100;
                    }
                    break;
                
                case 'banner_general':
                default:
                    // Banner exact match = highest rank
                    if (store.banner && store.banner.toLowerCase() === term) {
                        rank = 100;
                    }
                    // STORE prefix match = high rank
                    else if (store.STORE && store.STORE.toLowerCase().startsWith(term)) {
                        rank = 90;
                    }
                    // STORE contains = medium rank
                    else if (store.STORE && store.STORE.toLowerCase().includes(term)) {
                        rank = 70;
                    }
                    break;
            }
            
            return { ...store, _searchRank: rank };
        }).sort((a, b) => {
            // Sort by rank (descending), then by STORE name
            if (b._searchRank !== a._searchRank) {
                return b._searchRank - a._searchRank;
            }
            return (a.STORE || a.name || '').localeCompare(b.STORE || b.name || '');
        });
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

    // Filter stores by chain/banner (legacy method - now uses filterByBanner)
    async filterByChain(chain) {
        // Map to new filterByBanner method for backward compatibility
        await this.filterByBanner(chain);
    }

    // Filter stores by chain/banner (new method)
    async filterByBanner(banner) {
        console.log('🔍 Filtering by banner:', banner);
        
        // Store the current chain filter for backward compatibility
        this.currentChainFilter = banner;
        
        // For brands: require search term before filtering
        const isBrand = await this.isBrand();
        if (isBrand && !this.searchTerm) {
            this.showError('Please search for stores first (e.g., "Whole Foods") before filtering by banner.');
            return;
        }
        
        // Apply banner filter
        if (banner === 'all' || !banner) {
            this.activeFilters.banner = null;
        } else {
            this.activeFilters.banner = banner;
        }
        
        // For brands: re-run search with banner filter
        if (isBrand && this.searchTerm) {
            await this.searchStores(this.searchTerm);
            this.renderFilterChips();
            return;
        }
        
        // For admins: apply filter to existing stores
        if (this.allStores.length > 0) {
            this.applyFilters();
            this.renderFilterChips();
        } else {
            // No stores loaded yet - will apply when stores are loaded
            this.renderFilterChips();
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

    // Apply state filter
    filterByState(state) {
        if (state === 'all' || !state) {
            this.activeFilters.state = null;
        } else {
            this.activeFilters.state = state;
        }
        this.applyFilters();
        this.renderFilterChips();
    }

    // Apply banner filter (chain)
    filterByBanner(banner) {
        if (banner === 'all' || !banner) {
            this.activeFilters.banner = null;
        } else {
            this.activeFilters.banner = banner;
        }
        this.applyFilters();
        this.renderFilterChips();
    }

    // Apply all active filters
    applyFilters() {
        let filtered = [...this.allStores];

        // Apply state filter
        if (this.activeFilters.state) {
            filtered = filtered.filter(store => 
                (store.state && store.state.toUpperCase() === this.activeFilters.state.toUpperCase()) ||
                (store.STATE && store.STATE.toUpperCase() === this.activeFilters.state.toUpperCase())
            );
        }

        // Apply banner filter
        if (this.activeFilters.banner) {
            filtered = filtered.filter(store => {
                const storeName = store.STORE || store.store || store.name || '';
                return storeName.toLowerCase().startsWith(this.activeFilters.banner.toLowerCase() + ' -');
            });
        }

        this.filteredStores = filtered;
        this.renderStoreList();
        this.updateCounts();
    }

    // Clear all filters
    clearFilters() {
        this.activeFilters = { state: null, banner: null };
        this.applyFilters();
        this.renderFilterChips();
        
        // Also clear chain filter dropdown if it exists
        const chainFilter = document.getElementById('chain-filter');
        if (chainFilter) {
            chainFilter.value = 'all';
        }
    }

    // Render filter chips
    renderFilterChips() {
        const container = document.getElementById('filter-chips');
        if (!container) return;

        const chips = [];
        
        if (this.activeFilters.state) {
            chips.push(`
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-blue-100 text-blue-800">
                    State: ${this.activeFilters.state}
                    <button onclick="storeSelector.filterByState('all')" class="ml-2 text-blue-600 hover:text-blue-800">×</button>
                </span>
            `);
        }

        if (this.activeFilters.banner) {
            chips.push(`
                <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800">
                    ${this.activeFilters.banner}
                    <button onclick="storeSelector.filterByBanner('all')" class="ml-2 text-green-600 hover:text-green-800">×</button>
                </span>
            `);
        }

        if (chips.length > 0) {
            container.innerHTML = `
                <div class="flex flex-wrap gap-2 items-center">
                    ${chips.join('')}
                    <button onclick="storeSelector.clearFilters()" class="text-sm text-gray-600 hover:text-gray-800 underline">
                        Clear all
                    </button>
                </div>
            `;
        } else {
            container.innerHTML = '';
        }
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

        // Set up search input with debounced typeahead
        const searchInput = document.getElementById('store-search');
        if (searchInput) {
            const debouncedSearch = storeSelector.debounce(async (value) => {
                console.log('🔍 Debounced search triggered with value:', value);
                await storeSelector.searchStores(value);
            }, 300); // 300ms debounce for typeahead

            searchInput.addEventListener('input', (e) => {
                const value = e.target.value;
                console.log('📝 Search input changed:', value);
                debouncedSearch(value);
            });
        } else {
            console.error('❌ Search input element not found!');
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