/**
 * barcode-capture.js
 * ShelfAssured — Scan & Go Tool
 *
 * Replaces Google Vision API / QuaggaJS with html5-qrcode for reliable
 * in-browser barcode scanning. Handles: UPC lookup, Shadow Brand creation,
 * GPS location, photo capture, and product save.
 */

'use strict';

// ─── State ────────────────────────────────────────────────────────────────────
// NOTE: supabase client is NOT declared here — shared/api.js already declares
// SUPABASE_URL, SUPABASE_ANON_KEY, and creates the `supabase` variable as a
// module-level let. We access it via window.saSupabase (set during init below).
let _supabase = null;   // local alias — avoids collision with api.js's `supabase`
let currentUser = null;
let html5QrCode = null;
let scannerRunning = false;
let scanCooldown = false;      // Prevents duplicate scans within 2.5 seconds
let todayScanCount = 0;
let pendingPhotos = {};        // { shelf: File, product: File }
let knownBrands = [];          // Cache of brands for autocomplete
let storeValue = '';           // Persists across scans
let currentSkuId = null;       // SKU ID from catalog lookup, for scan_events

// ─── Initialise ───────────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', async () => {
    try {
        // Build a fresh Supabase client from SA_CONFIG (injected by config.js at deploy).
        // We use a local alias (_supabase) to avoid colliding with the `supabase` let
        // declared in shared/api.js which loads before this file.
        const cfg = window.SA_CONFIG || {};
        const url = cfg.SUPABASE_URL || '';
        const key = cfg.SUPABASE_ANON_KEY || '';
        if (!url || !key) {
            throw new Error('Supabase config not loaded. Check config.js / GitHub Secrets.');
        }
        _supabase = window.supabase.createClient(url, key);

        const { data: { session } } = await _supabase.auth.getSession();
        if (!session) {
            window.location.href = '../auth/signin.html';
            return;
        }
        currentUser = session.user;

        await loadKnownBrands();
        await loadTodayScanCount();
        await loadRecentScans();
        setupStoreInput();
        setupBrandAutocomplete();
        setupFormSubmit();
        // Auto-request GPS on page load (silent = no button spinner)
        setTimeout(() => captureGPSLocation(true), 500);
        // Populate category dropdown from shared categories.js if available
        const catSelect = document.getElementById('product-category');
        if (catSelect && typeof generateCategoryDropdownHTML === 'function') {
            catSelect.innerHTML = generateCategoryDropdownHTML(true);
        }

    } catch (err) {
        console.error('Init error:', err);
        // Surface the error visibly so it is not silent
        const statusText = document.getElementById('scanner-status-text');
        if (statusText) {
            statusText.textContent = 'Init error: ' + err.message;
            statusText.className = 'text-xs text-red-500';
        }
        showToast('Init error: ' + err.message, 'error');
    }
});

// ─── Auth ──────────────────────────────────────────────────────────────────────
async function handleSignOut() {
    await stopScanner();
    await _supabase.auth.signOut();
    window.location.href = '../auth/signin.html';
}

// ─── Scanner ───────────────────────────────────────────────────────────────────
async function startScanner() {
    if (scannerRunning) return;

    const placeholder = document.getElementById('scanner-placeholder');
    const scanLine = document.getElementById('scan-line');
    const startBtn = document.getElementById('start-scan-btn');
    const stopBtn = document.getElementById('stop-scan-btn');
    const statusText = document.getElementById('scanner-status-text');

    try {
        statusText.textContent = 'Starting camera...';
        statusText.className = 'text-xs text-amber-500';

        html5QrCode = new Html5Qrcode('qr-reader');

        const config = {
            fps: 15,
            qrbox: { width: 280, height: 120 },
            aspectRatio: 1.5,
            formatsToSupport: [
                Html5QrcodeSupportedFormats.EAN_13,
                Html5QrcodeSupportedFormats.EAN_8,
                Html5QrcodeSupportedFormats.UPC_A,
                Html5QrcodeSupportedFormats.UPC_E,
                Html5QrcodeSupportedFormats.CODE_128,
                Html5QrcodeSupportedFormats.CODE_39,
                Html5QrcodeSupportedFormats.ITF,
            ]
        };

        await html5QrCode.start(
            { facingMode: 'environment' },
            config,
            onScanSuccess,
            onScanFailure
        );

        scannerRunning = true;
        placeholder.classList.add('hidden');
        scanLine.classList.remove('hidden');
        startBtn.disabled = true;
        startBtn.classList.add('opacity-50', 'cursor-not-allowed');
        stopBtn.disabled = false;
        stopBtn.classList.remove('bg-gray-200', 'text-gray-400', 'cursor-not-allowed');
        stopBtn.classList.add('bg-gray-700', 'text-white', 'hover:bg-gray-800');
        statusText.textContent = 'Scanning...';
        statusText.className = 'text-xs text-green-500 font-medium';

    } catch (err) {
        console.error('Camera error:', err);
        statusText.textContent = 'Camera error';
        statusText.className = 'text-xs text-red-500';
        showToast('Camera access denied or unavailable', 'error');
    }
}

async function stopScanner() {
    if (!scannerRunning || !html5QrCode) return;
    try {
        await html5QrCode.stop();
        html5QrCode.clear();
    } catch (e) {
        // Ignore stop errors
    }
    scannerRunning = false;

    const placeholder = document.getElementById('scanner-placeholder');
    const scanLine = document.getElementById('scan-line');
    const startBtn = document.getElementById('start-scan-btn');
    const stopBtn = document.getElementById('stop-scan-btn');
    const statusText = document.getElementById('scanner-status-text');

    placeholder.classList.remove('hidden');
    scanLine.classList.add('hidden');
    startBtn.disabled = false;
    startBtn.classList.remove('opacity-50', 'cursor-not-allowed');
    stopBtn.disabled = true;
    stopBtn.classList.add('bg-gray-200', 'text-gray-400', 'cursor-not-allowed');
    stopBtn.classList.remove('bg-gray-700', 'text-white', 'hover:bg-gray-800');
    statusText.textContent = 'Ready';
    statusText.className = 'text-xs text-gray-400';
}

function onScanSuccess(decodedText) {
    if (scanCooldown) return;
    scanCooldown = true;
    setTimeout(() => { scanCooldown = false; }, 2500);

    // Visual + haptic feedback
    const viewport = document.getElementById('scanner-viewport');
    viewport.classList.add('scan-success');
    setTimeout(() => viewport.classList.remove('scan-success'), 600);
    if (navigator.vibrate) navigator.vibrate([100, 50, 100]);

    stopScanner().then(() => {
        processUPC(decodedText.trim());
    });
}

function onScanFailure() {
    // Silent — fires constantly while scanning, no action needed
}

// ─── Manual Entry ──────────────────────────────────────────────────────────────
function toggleManualEntry() {
    const row = document.getElementById('manual-entry-row');
    row.classList.toggle('hidden');
    if (!row.classList.contains('hidden')) {
        document.getElementById('manual-upc').focus();
    }
}

function lookupManualUPC() {
    const val = document.getElementById('manual-upc').value.trim();
    if (!val) {
        showToast('Please enter a UPC', 'error');
        return;
    }
    document.getElementById('manual-entry-row').classList.add('hidden');
    processUPC(val);
}

// ─── Open Food Facts Lookup ───────────────────────────────────────────────────
async function lookupOpenFoodFacts(upc) {
    try {
        const fields = 'product_name,brands,quantity,categories_tags,image_front_url';
        const res = await fetch(
            `https://world.openfoodfacts.org/api/v2/product/${encodeURIComponent(upc)}.json?fields=${fields}`,
            { headers: { 'User-Agent': 'ShelfAssured/1.0 (shelfassured.com)' } }
        );
        if (!res.ok) return null;
        const data = await res.json();
        if (data.status !== 1) return null;
        const p = data.product;

        // Map OFF categories to our category options
        const catTags = (p.categories_tags || []).map(t => t.replace(/^en:/, ''));
        const catMap = {
            'beverages': 'Beverages', 'drinks': 'Beverages', 'waters': 'Beverages',
            'snacks': 'Snacks', 'bars': 'Snacks', 'chips': 'Snacks', 'crackers': 'Snacks',
            'dairy': 'Dairy', 'cheeses': 'Dairy', 'yogurts': 'Dairy', 'milks': 'Dairy',
            'frozen': 'Frozen', 'frozen-foods': 'Frozen',
            'fresh-produce': 'Produce', 'fruits': 'Produce', 'vegetables': 'Produce',
            'meats': 'Meat & Seafood', 'seafood': 'Meat & Seafood', 'fish': 'Meat & Seafood',
            'breads': 'Bakery', 'pastries': 'Bakery', 'baked-goods': 'Bakery',
            'condiments': 'Pantry', 'sauces': 'Pantry', 'cereals': 'Pantry',
            'beauty': 'Health & Beauty', 'supplements': 'Health & Beauty',
            'baby-foods': 'Baby', 'pet-foods': 'Pet',
        };
        let category = '';
        for (const tag of catTags) {
            if (catMap[tag]) { category = catMap[tag]; break; }
        }

        return {
            name:     (p.product_name || '').trim(),
            brand:    (p.brands || '').split(',')[0].trim(),  // first brand only
            size:     (p.quantity || '').trim(),
            category: category,
            imageUrl: p.image_front_url || '',
        };
    } catch (e) {
        console.warn('Open Food Facts lookup failed:', e);
        return null;
    }
}

// ─── UPC Processing & Lookup ───────────────────────────────────────────────────
async function processUPC(upc) {
    document.getElementById('upc-value').value = upc;
    document.getElementById('upc-badge').textContent = upc;

    const lookupEl = document.getElementById('lookup-result');
    lookupEl.className = 'mb-3 p-2.5 rounded-lg text-sm font-medium bg-blue-50 text-blue-700';
    lookupEl.textContent = 'Looking up UPC...';
    lookupEl.classList.remove('hidden');

    showProductForm();

    try {
        // Step 1: Check our own Supabase database first
        const [productsResult, skusResult] = await Promise.all([
            _supabase
                .from('products')
                .select('*')
                .or(`barcode.eq.${upc},upc.eq.${upc}`)
                .limit(1)
                .maybeSingle(),
            _supabase
                .from('skus')
                .select('*, brands(id, name, is_shadow)')
                .eq('upc', upc)
                .limit(1)
                .maybeSingle()
        ]);

        if (productsResult.data) {
            const p = productsResult.data;
            populateFormFromProduct(p);
            currentSkuId = null;  // product record, not a SKU catalog entry
            lookupEl.className = 'mb-3 p-2.5 rounded-lg text-sm font-medium bg-green-50 text-green-700';
            lookupEl.innerHTML = '\u2713 Found in your database \u2014 <strong>re-scan: update price/stock if changed</strong>';
            document.getElementById('existing-product-id').value = p.id;
            return;
        }

        if (skusResult.data) {
            const s = skusResult.data;
            populateFormFromSKU(s);
            currentSkuId = s.id || null;  // Track for scan_event
            lookupEl.className = 'mb-3 p-2.5 rounded-lg text-sm font-medium bg-green-50 text-green-700';
            lookupEl.innerHTML = '\u2713 Found in SKU catalog \u2014 <strong>confirm details and save</strong>';
            return;
        }

        // Step 2: Not in our DB — try Open Food Facts
        lookupEl.textContent = 'Not in database \u2014 checking Open Food Facts...';
        const off = await lookupOpenFoodFacts(upc);

        if (off && off.name) {
            populateFormFromOFF(off);
            lookupEl.className = 'mb-3 p-2.5 rounded-lg text-sm font-medium bg-purple-50 text-purple-700';
            lookupEl.textContent = '\u2728 Auto-filled from Open Food Facts \u2014 verify and save';
        } else {
            lookupEl.className = 'mb-3 p-2.5 rounded-lg text-sm font-medium bg-amber-50 text-amber-700';
            lookupEl.textContent = '\u2295 New product \u2014 fill in details below';
            document.getElementById('product-name').focus();
        }

    } catch (err) {
        console.error('Lookup error:', err);
        lookupEl.className = 'mb-3 p-2.5 rounded-lg text-sm font-medium bg-red-50 text-red-700';
        lookupEl.textContent = 'Lookup failed \u2014 enter details manually';
    }
}

function populateFormFromProduct(p) {
    document.getElementById('brand-input').value = p.brand || '';
    document.getElementById('product-name').value = p.name || '';
    document.getElementById('product-size').value = p.size || '';
    document.getElementById('product-notes').value = '';
    setCategory(p.category);
    checkBrandShadowStatus(p.brand);
}

function populateFormFromSKU(s) {
    const brandName = s.brands ? s.brands.name : '';
    const brandId = s.brands ? s.brands.id : '';
    const isShadow = s.brands ? (s.brands.is_shadow || false) : false;

    document.getElementById('brand-input').value = brandName;
    document.getElementById('brand-id-value').value = brandId;
    document.getElementById('brand-is-shadow').value = isShadow ? 'true' : 'false';
    document.getElementById('product-name').value = s.name || '';
    document.getElementById('product-size').value = s.size || '';
    document.getElementById('product-notes').value = '';
    setCategory(s.category);

    if (isShadow) {
        document.getElementById('shadow-brand-notice').classList.remove('hidden');
    }
}

function populateFormFromOFF(off) {
    // Populate brand — try to match against known brands first
    document.getElementById('brand-input').value = off.brand;
    document.getElementById('brand-id-value').value = '';
    document.getElementById('brand-is-shadow').value = 'new';
    // Check if brand already exists in our cache
    const existing = knownBrands.find(b => b.name.toLowerCase() === off.brand.toLowerCase());
    if (existing) {
        document.getElementById('brand-id-value').value = existing.id;
        document.getElementById('brand-is-shadow').value = existing.is_shadow ? 'true' : 'false';
        if (existing.is_shadow) {
            document.getElementById('shadow-brand-notice').classList.remove('hidden');
        }
    } else if (off.brand) {
        document.getElementById('shadow-brand-notice').classList.remove('hidden');
    }

    document.getElementById('product-name').value = off.name;
    document.getElementById('product-size').value = off.size;
    document.getElementById('product-notes').value = '';
    setCategory(off.category);
}

function setCategory(cat) {
    if (!cat) return;
    const sel = document.getElementById('product-category');
    const options = Array.from(sel.options);
    const match = options.find(o =>
        o.value.toLowerCase() === cat.toLowerCase() ||
        o.text.toLowerCase() === cat.toLowerCase()
    );
    if (match) sel.value = match.value;
}

function showProductForm() {
    const section = document.getElementById('product-form-section');
    section.classList.remove('hidden');
    section.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

// ─── Brand Autocomplete & Shadow Brand Logic ───────────────────────────────────
async function loadKnownBrands() {
    try {
        const { data } = await _supabase
            .from('brands')
            .select('id, name, is_shadow')
            .order('name');
        knownBrands = data || [];
    } catch (e) {
        console.warn('Could not load brands:', e);
    }
}

function setupBrandAutocomplete() {
    const input = document.getElementById('brand-input');
    const suggestions = document.getElementById('brand-suggestions');

    input.addEventListener('input', () => {
        const query = input.value.toLowerCase().trim();
        if (!query) {
            suggestions.classList.add('hidden');
            clearBrandSelection();
            return;
        }

        const matches = knownBrands.filter(b => b.name.toLowerCase().includes(query)).slice(0, 8);

        if (matches.length === 0) {
            suggestions.classList.add('hidden');
            document.getElementById('shadow-brand-notice').classList.remove('hidden');
            document.getElementById('brand-id-value').value = '';
            document.getElementById('brand-is-shadow').value = 'new';
            return;
        }

        document.getElementById('shadow-brand-notice').classList.add('hidden');
        suggestions.innerHTML = matches.map(b => `
            <div class="px-3 py-2 hover:bg-gray-50 cursor-pointer text-sm flex items-center justify-between"
                 onclick="selectBrand('${b.id}', '${escapeAttr(b.name)}', ${b.is_shadow || false})">
                <span>${escapeHtml(b.name)}</span>
                ${b.is_shadow ? '<span class="text-xs text-amber-600 bg-amber-50 px-1.5 py-0.5 rounded">Shadow</span>' : ''}
            </div>
        `).join('');
        suggestions.classList.remove('hidden');
    });

    input.addEventListener('blur', () => {
        setTimeout(() => suggestions.classList.add('hidden'), 200);
    });
}

function selectBrand(id, name, isShadow) {
    document.getElementById('brand-input').value = name;
    document.getElementById('brand-id-value').value = id;
    document.getElementById('brand-is-shadow').value = isShadow ? 'true' : 'false';
    document.getElementById('brand-suggestions').classList.add('hidden');
    if (isShadow) {
        document.getElementById('shadow-brand-notice').classList.remove('hidden');
    } else {
        document.getElementById('shadow-brand-notice').classList.add('hidden');
    }
}

function clearBrandSelection() {
    document.getElementById('brand-id-value').value = '';
    document.getElementById('brand-is-shadow').value = '';
    document.getElementById('shadow-brand-notice').classList.add('hidden');
}

async function checkBrandShadowStatus(brandName) {
    if (!brandName) return;
    const nameLower = brandName.toLowerCase().trim();
    // Try exact match first, then partial match (handles 'Oh Sugar' vs 'Oh Sugar!')
    let found = knownBrands.find(b => b.name.toLowerCase() === nameLower);
    if (!found) {
        // Try partial match: brand name contains query or query contains brand name
        found = knownBrands.find(b => {
            const bLower = b.name.toLowerCase();
            return bLower.includes(nameLower) || nameLower.includes(bLower);
        });
    }
    if (found) {
        document.getElementById('brand-id-value').value = found.id;
        document.getElementById('brand-is-shadow').value = found.is_shadow ? 'true' : 'false';
        if (found.is_shadow) {
            document.getElementById('shadow-brand-notice').classList.remove('hidden');
        } else {
            document.getElementById('shadow-brand-notice').classList.add('hidden');
        }
    } else {
        document.getElementById('brand-id-value').value = '';
        document.getElementById('brand-is-shadow').value = 'new';
        document.getElementById('shadow-brand-notice').classList.remove('hidden');
    }
}

// ─── GPS Location ──────────────────────────────────────────────────────────────
async function applyGPSPosition(pos, status, btn) {
    const lat = pos.coords.latitude;
    const lng = pos.coords.longitude;
    document.getElementById('store-lat').value = lat;
    document.getElementById('store-lng').value = lng;
    try {
        const resp = await fetch(
            `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lng}&format=json`,
            { headers: { 'Accept-Language': 'en' } }
        );
        const geo = await resp.json();
        const addr = geo.address || {};
        const storeName = addr.shop || addr.amenity || addr.building || '';
        const city = addr.city || addr.town || addr.village || '';
        const state = addr.state || '';
        const suggestion = [storeName, city, state].filter(Boolean).join(', ');
        if (suggestion) {
            document.getElementById('store-input').value = suggestion;
            storeValue = suggestion;
        }
        status.textContent = `GPS locked \u2014 ${city || lat.toFixed(4) + ', ' + lng.toFixed(4)}`;
        document.getElementById('store-locked-badge').classList.remove('hidden');
        if (city) { searchStoresTypeahead(city); }
    } catch {
        status.textContent = `GPS: ${lat.toFixed(5)}, ${lng.toFixed(5)}`;
        // Still search by coords even if reverse-geocode failed
        searchStoresTypeahead('');
    }
    btn.innerHTML = `<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/></svg> GPS`;
    btn.disabled = false;
}

function captureGPSLocation(silent = false) {
    const btn = document.getElementById('gps-btn');
    const status = document.getElementById('gps-status');

    if (!navigator.geolocation) {
        if (!silent) { status.textContent = 'GPS not available on this device'; status.classList.remove('hidden'); }
        return;
    }

    if (!silent) {
        btn.textContent = '...';
        btn.disabled = true;
        status.textContent = 'Getting location…';
        status.classList.remove('hidden');
    }

    const resetBtn = () => {
        btn.innerHTML = `<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"/></svg> GPS`;
        btn.disabled = false;
    };

    // Build a human-readable error message based on the actual error code.
    // iOS Safari sometimes returns code 1 (PERMISSION_DENIED) even when the
    // user has granted access — this happens when the system-level Location
    // Services switch is off, or when the page hasn't received a user gesture
    // yet. We use the Permissions API (where available) to distinguish a true
    // denial from a timeout so we never show a misleading message.
    const buildErrorMsg = async (err, isFallback) => {
        let msg = 'Could not get location — enter store manually';
        if (err.code === 1) {
            // Check Permissions API before blaming the user
            if (navigator.permissions) {
                try {
                    const perm = await navigator.permissions.query({ name: 'geolocation' });
                    if (perm.state === 'denied') {
                        msg = 'Location blocked — tap GPS to retry, or type store name';
                    } else {
                        // State is 'granted' or 'prompt' — likely a system-level block
                        msg = 'Location unavailable — check iOS Settings > Privacy > Location Services';
                    }
                } catch {
                    msg = 'Location unavailable — enter store manually';
                }
            } else {
                msg = 'Location unavailable — enter store manually';
            }
        } else if (err.code === 2) {
            msg = 'Location unavailable — enter store manually';
        } else if (err.code === 3) {
            msg = isFallback
                ? 'Location timed out — enter store manually or tap GPS again'
                : null; // will retry low-accuracy, don't show yet
        }
        return msg;
    };

    // Low-accuracy fallback (cell/WiFi) — longer timeout for indoor use
    const tryLowAccuracy = async (err) => {
        console.warn('High-accuracy GPS failed, trying low-accuracy:', err.code, err.message);
        navigator.geolocation.getCurrentPosition(
            (pos) => applyGPSPosition(pos, status, btn),
            async (err2) => {
                console.error('GPS error (low-accuracy fallback):', err2.code, err2.message);
                const msg = await buildErrorMsg(err2, true);
                if (silent) {
                    // Auto-attempt on page load: hide status, don't alarm the user
                    status.classList.add('hidden');
                } else {
                    status.textContent = msg || 'Could not get location — enter store manually';
                }
                resetBtn();
            },
            { enableHighAccuracy: false, timeout: 12000, maximumAge: 300000 }
        );
    };

    // High-accuracy first (GPS chip), generous timeout for iOS cold-start
    navigator.geolocation.getCurrentPosition(
        (pos) => applyGPSPosition(pos, status, btn),
        tryLowAccuracy,
        { enableHighAccuracy: true, timeout: 10000, maximumAge: 60000 }
    );
}

function setupStoreInput() {
    const input = document.getElementById('store-input');
    let storeSearchTimer = null;

    input.addEventListener('input', () => {
        storeValue = input.value;
        if (storeValue) {
            document.getElementById('store-locked-badge').classList.remove('hidden');
        } else {
            document.getElementById('store-locked-badge').classList.add('hidden');
        }
        // Debounced typeahead search
        clearTimeout(storeSearchTimer);
        if (storeValue.length >= 2) {
            storeSearchTimer = setTimeout(() => searchStoresTypeahead(storeValue), 300);
        } else {
            hideStoreSuggestions();
        }
    });

    input.addEventListener('blur', () => {
        setTimeout(hideStoreSuggestions, 200);
    });
}

async function searchStoresTypeahead(query) {
    if (!query || query.length < 2) { hideStoreSuggestions(); return; }
    try {
        const { data: stores } = await _supabase
            .from('stores')
            .select('id, STORE, city, state, banner')
            .or(`STORE.ilike.%${query}%,city.ilike.%${query}%,banner.ilike.%${query}%`)
            .limit(8);
        renderStoreSuggestions(stores || []);
    } catch (e) {
        console.warn('Store search error:', e);
    }
}

function renderStoreSuggestions(stores) {
    const suggestions = document.getElementById('store-suggestions');
    if (!suggestions) return;
    if (stores.length === 0) { hideStoreSuggestions(); return; }
    suggestions.innerHTML = stores.map(s => {
        const label = s.STORE || `${s.banner || ''} – ${s.city || ''}, ${s.state || ''}`;
        return `<div class="px-3 py-2 hover:bg-gray-50 cursor-pointer text-sm"
            onclick="selectStoreSuggestion('${escapeAttr(label)}', '${s.id}')"
        ><span class="font-medium">${escapeHtml(label)}</span></div>`;
    }).join('');
    suggestions.classList.remove('hidden');
}

function selectStoreSuggestion(label, storeId) {
    const input = document.getElementById('store-input');
    input.value = label;
    storeValue = label;
    // Store the store ID for the scan event
    const storeIdField = document.getElementById('store-id');
    if (storeIdField) storeIdField.value = storeId;
    document.getElementById('store-locked-badge').classList.remove('hidden');
    hideStoreSuggestions();
}

function hideStoreSuggestions() {
    const suggestions = document.getElementById('store-suggestions');
    if (suggestions) suggestions.classList.add('hidden');
}

// ─── Photos ────────────────────────────────────────────────────────────────────
function triggerPhoto(inputId) {
    document.getElementById(inputId).click();
}

function handlePhotoSelected(input, type) {
    const file = input.files[0];
    if (!file) return;
    pendingPhotos[type] = file;

    const reader = new FileReader();
    reader.onload = (e) => {
        const previews = document.getElementById('photo-previews');
        const existingId = `preview-${type}`;
        const existing = document.getElementById(existingId);
        if (existing) existing.remove();

        const div = document.createElement('div');
        div.id = existingId;
        div.className = 'relative';
        div.innerHTML = `
            <img src="${e.target.result}" class="w-20 h-20 object-cover rounded-lg border border-gray-200" alt="${type} photo">
            <span class="absolute bottom-0 left-0 right-0 text-center text-xs bg-black bg-opacity-50 text-white rounded-b-lg py-0.5">${type}</span>
            <button type="button" onclick="removePhoto('${type}')" class="absolute -top-1 -right-1 w-5 h-5 bg-red-500 text-white rounded-full text-xs flex items-center justify-center leading-none">&times;</button>
        `;
        previews.appendChild(div);
    };
    reader.readAsDataURL(file);
}

function removePhoto(type) {
    delete pendingPhotos[type];
    const el = document.getElementById(`preview-${type}`);
    if (el) el.remove();
    document.getElementById(`photo-${type}`).value = '';
}

async function uploadPhotos(productId) {
    const urls = {};
    for (const [type, file] of Object.entries(pendingPhotos)) {
        try {
            const ext = (file.name.split('.').pop() || 'jpg').toLowerCase();
            const path = `products/${productId}/${type}-${Date.now()}.${ext}`;
            const { error } = await _supabase.storage
                .from('product-photos')
                .upload(path, file, { upsert: true });
            if (!error) {
                const { data: { publicUrl } } = _supabase.storage
                    .from('product-photos')
                    .getPublicUrl(path);
                urls[type] = publicUrl;
            }
        } catch (e) {
            console.warn(`Photo upload failed for ${type}:`, e);
        }
    }
    return urls;
}

// ─── Shadow Brand Creation ─────────────────────────────────────────────────────
async function ensureBrandExists(brandName) {
    if (!brandName) return null;

    const existingId = document.getElementById('brand-id-value').value;
    if (existingId) return existingId;

    // Check DB (case-insensitive)
    const { data: existing } = await _supabase
        .from('brands')
        .select('id, is_shadow')
        .ilike('name', brandName)
        .maybeSingle();

    if (existing) {
        return existing.id;
    }

    // Create new Shadow Brand
    const { data: newBrand, error } = await _supabase
        .from('brands')
        .insert({
            name: brandName,
            is_shadow: true,
            created_source: 'scan_capture',   // Tracks origin: scan_capture | manual_admin | import | brand_onboarding
            data_source: 'scan_capture',       // Existing column — mirrors created_source for compatibility
            created_by: currentUser.id,
            created_at: new Date().toISOString()
        })
        .select('id')
        .single();

    if (error) {
        console.error('Shadow brand creation error:', error);
        return null;
    }

    knownBrands.push({ id: newBrand.id, name: brandName, is_shadow: true });
    showToast(`Shadow Brand created: ${brandName}`, 'info');
    return newBrand.id;
}

// ─── Form Submission ───────────────────────────────────────────────────────────
function setupFormSubmit() {
    document.getElementById('product-form').addEventListener('submit', async (e) => {
        e.preventDefault();
        await saveProduct();
    });
}

async function saveProduct() {
    const submitBtn = document.querySelector('#product-form button[type="submit"]');
    submitBtn.disabled = true;
    submitBtn.textContent = 'Saving...';

    try {
        const upc = document.getElementById('upc-value').value.trim();
        const brandName = document.getElementById('brand-input').value.trim();
        const productName = document.getElementById('product-name').value.trim();
        const size = document.getElementById('product-size').value.trim();
        const category = document.getElementById('product-category').value;
        const notes = document.getElementById('product-notes').value.trim();
        const storeName = document.getElementById('store-input').value.trim();
        const existingId = document.getElementById('existing-product-id').value;

        if (!brandName || !productName) {
            showToast('Brand and product name are required', 'error');
            submitBtn.disabled = false;
            submitBtn.textContent = 'Save & Scan Next';
            return;
        }

        const brandId = await ensureBrandExists(brandName);

        const productData = {
            barcode: upc,
            upc: upc,
            brand: brandName,
            brand_id: brandId || null,   // UUID FK — required for RLS tenant isolation
            name: productName,
            size: size || null,
            category: category || null,
            notes: notes || null,
            store: storeName || null,
            scan_date: new Date().toISOString().split('T')[0],
            added_by: currentUser.id,
            updated_at: new Date().toISOString()
        };

        let savedId = existingId;

        if (existingId) {
            const { error } = await _supabase
                .from('products')
                .update(productData)
                .eq('id', existingId);
            if (error) throw error;
        } else {
            productData.created_at = new Date().toISOString();
            const { data, error } = await _supabase
                .from('products')
                .insert(productData)
                .select('id')
                .single();
            if (error) throw error;
            savedId = data.id;
        }

        if (Object.keys(pendingPhotos).length > 0 && savedId) {
            await uploadPhotos(savedId);
        }

        // Save scan_event record (gracefully handles missing table until SQL migration runs)
        try {
            const storeId = document.getElementById('store-id')?.value || null;
            const scanEventData = {
                barcode: upc || null,
                sku_id: currentSkuId || null,
                store_id: storeId || null,
                shelfer_id: currentUser.id,
                scan_type: existingId ? 'rescan' : (currentSkuId ? 'known_sku' : 'new_product'),
                notes: notes || null,
                scanned_at: new Date().toISOString()
            };
            const { error: scanEventErr } = await _supabase.from('scan_events').insert(scanEventData);
            if (scanEventErr && !scanEventErr.message?.includes('does not exist')) {
                console.warn('scan_event save warning:', scanEventErr.message);
            }
        } catch (scanEventEx) {
            // Non-blocking — scan_events table may not exist yet
            console.info('scan_events not saved (table may not exist yet):', scanEventEx.message);
        }

        // Also upsert into skus for the SKU catalog
        if (brandId && upc) {
            await _supabase.from('skus').upsert({
                upc: upc,
                name: productName,
                brand_id: brandId,
                category: category || null,
                size: size || null,
                is_active: true,
                created_by: currentUser.id,
                updated_at: new Date().toISOString()
            }, { onConflict: 'upc' });
        }

        todayScanCount++;
        document.getElementById('scan-count-badge').textContent = `${todayScanCount} today`;

        showToast(`Saved: ${productName}`, 'success');
        await loadRecentScans();
        resetForm(true);

    } catch (err) {
        console.error('Save error:', err);
        showToast('Save failed: ' + (err.message || 'Unknown error'), 'error');
    } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = 'Save & Scan Next';
    }
}

// ─── Quick Save ───────────────────────────────────────────────────────────────
async function quickSave() {
    const upc = document.getElementById('upc-value').value.trim();
    const brandName = document.getElementById('brand-input').value.trim();
    const productName = document.getElementById('product-name').value.trim();
    const storeName = document.getElementById('store-input').value.trim();
    const existingId = document.getElementById('existing-product-id').value;

    if (!brandName || !productName) {
        showToast('Brand and product name are required', 'error');
        return;
    }

    const quickBtn = document.querySelector('button[onclick="quickSave()"]');
    quickBtn.disabled = true;
    quickBtn.textContent = 'Saving...';

    try {
        const brandId = await ensureBrandExists(brandName);

        const productData = {
            barcode: upc || null,
            upc: upc || null,
            brand: brandName,
            brand_id: brandId || null,
            name: productName,
            store: storeName || null,
            scan_date: new Date().toISOString().split('T')[0],
            added_by: currentUser.id,
            updated_at: new Date().toISOString(),
            needs_review: true  // Flag for admin to fill in details later
        };

        let savedId = existingId;
        if (existingId) {
            const { error } = await _supabase.from('products').update(productData).eq('id', existingId);
            if (error) throw error;
        } else {
            productData.created_at = new Date().toISOString();
            const { data, error } = await _supabase.from('products').insert(productData).select('id').single();
            if (error) throw error;
            savedId = data.id;
        }

        // Upload any photos that were already taken
        if (Object.keys(pendingPhotos).length > 0 && savedId) {
            await uploadPhotos(savedId);
        }

        // Upsert into skus catalog
        if (brandId && upc) {
            await _supabase.from('skus').upsert({
                upc: upc,
                name: productName,
                brand_id: brandId,
                is_active: true,
                created_by: currentUser.id,
                updated_at: new Date().toISOString()
            }, { onConflict: 'upc' });
        }

        todayScanCount++;
        document.getElementById('scan-count-badge').textContent = `${todayScanCount} today`;
        showToast(`⚡ Quick saved: ${productName}`, 'success');
        await loadRecentScans();
        resetForm(true);
    } catch (err) {
        console.error('Quick save error:', err);
        showToast('Quick save failed: ' + (err.message || 'Unknown error'), 'error');
    } finally {
        quickBtn.disabled = false;
        quickBtn.textContent = '⚡ Quick Save';
    }
}

// ─── Form Reset ────────────────────────────────────────────────────────────────
function resetForm(keepStore) {
    document.getElementById('product-form-section').classList.add('hidden');
    document.getElementById('upc-value').value = '';
    document.getElementById('existing-product-id').value = '';
    currentSkuId = null;  // Reset SKU tracking
    document.getElementById('upc-badge').textContent = '';
    document.getElementById('brand-input').value = '';
    document.getElementById('brand-id-value').value = '';
    document.getElementById('brand-is-shadow').value = '';
    document.getElementById('product-name').value = '';
    document.getElementById('product-size').value = '';
    document.getElementById('product-category').value = '';
    document.getElementById('product-notes').value = '';
    document.getElementById('shadow-brand-notice').classList.add('hidden');
    document.getElementById('lookup-result').classList.add('hidden');
    document.getElementById('photo-previews').innerHTML = '';
    document.getElementById('photo-shelf').value = '';
    document.getElementById('photo-product').value = '';
    pendingPhotos = {};

    if (!keepStore) {
        document.getElementById('store-input').value = '';
        document.getElementById('store-lat').value = '';
        document.getElementById('store-lng').value = '';
        document.getElementById('store-id').value = '';
        document.getElementById('store-locked-badge').classList.add('hidden');
        document.getElementById('gps-status').classList.add('hidden');
        storeValue = '';
    }

    // Auto-restart scanner
    setTimeout(() => startScanner(), 300);
}

// ─── Recent Scans ──────────────────────────────────────────────────────────────
async function loadRecentScans() {
    const container = document.getElementById('recent-scans');
    try {
        const { data, error } = await _supabase
            .from('products')
            .select('id, name, brand, upc, barcode, store, scan_date, created_at')
            .order('created_at', { ascending: false })
            .limit(10);

        if (error) throw error;

        if (!data || data.length === 0) {
            container.innerHTML = '<div class="text-center text-gray-400 text-sm py-4">No scans yet</div>';
            return;
        }

        container.innerHTML = data.map(p => `
            <div class="flex items-center justify-between py-2 border-b border-gray-50 last:border-0">
                <div class="flex-1 min-w-0">
                    <div class="text-sm font-medium text-gray-900 truncate">${escapeHtml(p.name)}</div>
                    <div class="text-xs text-gray-500">${escapeHtml(p.brand || '')} &middot; ${escapeHtml(p.upc || p.barcode || '')}</div>
                </div>
                <div class="text-xs text-gray-400 ml-2 whitespace-nowrap">${formatRelativeTime(p.created_at)}</div>
            </div>
        `).join('');
    } catch (err) {
        container.innerHTML = '<div class="text-center text-red-400 text-sm py-4">Failed to load</div>';
        console.error('Recent scans error:', err);
    }
}

async function loadTodayScanCount() {
    try {
        const today = new Date().toISOString().split('T')[0];
        const { count } = await _supabase
            .from('products')
            .select('id', { count: 'exact', head: true })
            .eq('scan_date', today)
            .eq('added_by', currentUser.id);
        todayScanCount = count || 0;
        document.getElementById('scan-count-badge').textContent = `${todayScanCount} today`;
    } catch (e) {
        console.warn('Count error:', e);
    }
}

// ─── Utilities ─────────────────────────────────────────────────────────────────
function showToast(message, type) {
    const toast = document.getElementById('toast');
    const inner = document.getElementById('toast-inner');
    const colors = {
        success: 'bg-green-600',
        error: 'bg-red-600',
        info: 'bg-blue-600',
        warning: 'bg-amber-600'
    };
    inner.className = `px-5 py-3 rounded-xl shadow-xl text-sm font-semibold text-white min-w-52 text-center ${colors[type] || colors.info}`;
    inner.textContent = message;
    toast.classList.remove('hidden');
    setTimeout(() => toast.classList.add('hidden'), 3000);
}

function goToPage(path) {
    window.location.href = path;
}

function formatRelativeTime(isoString) {
    if (!isoString) return '';
    const diff = Date.now() - new Date(isoString).getTime();
    const mins = Math.floor(diff / 60000);
    if (mins < 1) return 'just now';
    if (mins < 60) return `${mins}m ago`;
    const hrs = Math.floor(mins / 60);
    if (hrs < 24) return `${hrs}h ago`;
    return new Date(isoString).toLocaleDateString();
}

function escapeHtml(str) {
    if (!str) return '';
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

function escapeAttr(str) {
    if (!str) return '';
    return String(str).replace(/'/g, "\\'").replace(/"/g, '\\"');
}

// ─── Window Exports ───────────────────────────────────────────────────────────
// Required: 'use strict' prevents inline onclick="fn()" from finding functions
// unless they are explicitly attached to window.
window.startScanner       = startScanner;
window.stopScanner        = stopScanner;
window.toggleManualEntry  = toggleManualEntry;
window.lookupManualUPC    = lookupManualUPC;
window.captureGPSLocation = captureGPSLocation;
window.triggerPhoto       = triggerPhoto;
window.handlePhotoSelected= handlePhotoSelected;
window.resetForm          = resetForm;
window.loadRecentScans    = loadRecentScans;
window.selectBrand        = selectBrand;
window.clearBrandSelection= clearBrandSelection;
window.removePhoto        = removePhoto;
window.handleSignOut      = handleSignOut;
window.goToPage           = goToPage;
