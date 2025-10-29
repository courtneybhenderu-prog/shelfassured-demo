// Admin Barcode Capture - JavaScript functionality
// This file handles barcode scanning, form management, and database operations

let scannerActive = false;
let currentUser = null;

// Google Vision API integration (GS1 removed due to cost)
// API key loaded from Supabase settings table
// TODO: Fix Google Vision API key (403 error) - priority for grocery store testing
let GOOGLE_VISION_API_KEY = '';

// Load API key from Supabase
async function loadApiKey() {
    try {
        const { data, error } = await supabase
            .from('settings')
            .select('value')
            .eq('key', 'google_vision_api_key')
            .single();
        
        if (error) throw error;
        
        // Parse the JSON value to get the actual API key
        const credentials = JSON.parse(data.value);
        GOOGLE_VISION_API_KEY = credentials.private_key;
        
        console.log('✅ API key loaded from Supabase');
        return true;
    } catch (error) {
        console.error('❌ Error loading API key:', error);
        return false;
    }
}

// Note: GS1 API removed due to $500/month cost - using manual entry + Google Vision instead

// Google Vision API function
async function extractTextFromImage(imageFile) {
    try {
        console.log('📸 Extracting text from image using Google Vision API');
        
        // Convert image to base64
        const base64Image = await fileToBase64(imageFile);
        
        const response = await fetch(`https://vision.googleapis.com/v1/images:annotate?key=${GOOGLE_VISION_API_KEY}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                requests: [{
                    image: {
                        content: base64Image
                    },
                    features: [{
                        type: 'TEXT_DETECTION',
                        maxResults: 1
                    }]
                }]
            })
        });
        
        if (!response.ok) {
            throw new Error(`Google Vision API error: ${response.status}`);
        }
        
        const data = await response.json();
        console.log('✅ Google Vision extraction successful:', data);
        
        if (data.responses && data.responses[0] && data.responses[0].textAnnotations) {
            const extractedText = data.responses[0].textAnnotations[0].description;
            return {
                success: true,
                text: extractedText
            };
        } else {
            return { success: false, error: 'No text found in image' };
        }
    } catch (error) {
        console.log('⚠️ Google Vision extraction failed:', error.message);
        return { success: false, error: error.message };
    }
}

// Helper function to convert file to base64
function fileToBase64(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.readAsDataURL(file);
        reader.onload = () => {
            const base64 = reader.result.split(',')[1]; // Remove data:image/...;base64, prefix
            resolve(base64);
        };
        reader.onerror = error => reject(error);
    });
}

// Initialize the page
document.addEventListener('DOMContentLoaded', async function() {
    console.log('🔧 Admin Barcode Capture initialized');
    
    // Load API key from Supabase
    const apiKeyLoaded = await loadApiKey();
    if (!apiKeyLoaded) {
        console.warn('⚠️ API key not loaded - barcode scanning may not work');
    }
    
    // Check if user is admin
    await checkAdminAccess();
    
    // Set up event listeners
    setupEventListeners();
    
    // Set default scan date to today
    document.getElementById('scan_date').value = new Date().toISOString().split('T')[0];
    
    // Load recent products
    await loadRecentProducts();
});

// Check if user has admin access
async function checkAdminAccess() {
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

        if (profile.role !== 'admin') {
            alert('Access denied. Admin privileges required.');
            window.location.href = '../dashboard/shelfer.html';
            return;
        }

        currentUser = user;
        document.getElementById('admin-user').textContent = `Welcome, ${profile.full_name || user.email}`;
        console.log('✅ Admin access confirmed');
        
    } catch (error) {
        console.error('Error checking admin access:', error);
        alert('Error checking permissions');
        window.location.href = '../auth/signin.html';
    }
}

// Set up event listeners
function setupEventListeners() {
    // Scanner controls
    document.getElementById('start-scanner').addEventListener('click', startScanner);
    document.getElementById('stop-scanner').addEventListener('click', stopScanner);
    document.getElementById('manual-entry').addEventListener('click', toggleManualEntry);
    
    // Form submission
    document.getElementById('product-form').addEventListener('submit', handleFormSubmit);
    document.getElementById('clear-form').addEventListener('click', clearForm);
    
    // Manual barcode entry
    document.getElementById('manual-barcode').addEventListener('input', function(e) {
        document.getElementById('barcode').value = e.target.value;
    });
    
    // GPS location button
    document.getElementById('gps-location').addEventListener('click', getCurrentLocation);
    
    // Photo upload functionality
    setupPhotoUpload();
}

// Start barcode scanner
async function startScanner() {
    console.log('🔄 Starting barcode scanner...');
    
    try {
        // Show scanner container
        document.getElementById('scanner-container').classList.remove('hidden');
        document.getElementById('start-scanner').disabled = true;
        document.getElementById('stop-scanner').disabled = false;
        document.getElementById('manual-entry').disabled = true;
        
        // Initialize QuaggaJS
        await Quagga.init({
            inputStream: {
                name: "Live",
                type: "LiveStream",
                target: document.querySelector('#scanner'),
                constraints: {
                    width: 640,
                    height: 480,
                    facingMode: "environment" // Use back camera
                },
            },
            decoder: {
                readers: [
                    "code_128_reader",
                    "ean_reader",
                    "ean_8_reader",
                    "code_39_reader",
                    "code_39_vin_reader",
                    "codabar_reader",
                    "upc_reader",
                    "upc_e_reader",
                    "i2of5_reader"
                ]
            },
            locate: true,
            locator: {
                patchSize: "medium",
                halfSample: true
            },
            numOfWorkers: 2,
            frequency: 10,
            debug: {
                drawBoundingBox: true,
                showFrequency: true,
                drawScanline: true,
                showPatch: true
            },
            multiple: false
        }, function(err) {
            if (err) {
                console.error('Scanner initialization error:', err);
                showMessage('Error initializing scanner: ' + err.message, 'error');
                stopScanner();
                return;
            }
            
            console.log("✅ Scanner initialized successfully");
            scannerActive = true;
            Quagga.start();
            updateScannerStatus('Scanner active - point camera at barcode');
        });

        // Handle successful barcode detection
        Quagga.onDetected(function(result) {
            if (result && result.codeResult) {
                const code = result.codeResult.code;
                console.log('📱 Barcode detected:', code);
                handleBarcodeDetected(code);
            }
        });

    } catch (error) {
        console.error('Error starting scanner:', error);
        showMessage('Error starting scanner: ' + error.message, 'error');
        stopScanner();
    }
}

// Stop barcode scanner
function stopScanner() {
    console.log('🛑 Stopping barcode scanner...');
    
    if (scannerActive) {
        Quagga.stop();
        scannerActive = false;
    }
    
    document.getElementById('scanner-container').classList.add('hidden');
    document.getElementById('start-scanner').disabled = false;
    document.getElementById('stop-scanner').disabled = true;
    document.getElementById('manual-entry').disabled = false;
    
    updateScannerStatus('Scanner stopped');
}

// Toggle manual entry mode
function toggleManualEntry() {
    const manualForm = document.getElementById('manual-form');
    const scannerContainer = document.getElementById('scanner-container');
    
    if (manualForm.classList.contains('hidden')) {
        // Show manual entry, hide scanner
        manualForm.classList.remove('hidden');
        scannerContainer.classList.add('hidden');
        stopScanner();
        document.getElementById('manual-barcode').focus();
    } else {
        // Hide manual entry
        manualForm.classList.add('hidden');
    }
}

// Handle detected barcode
async function handleBarcodeDetected(code) {
    console.log('✅ Barcode detected:', code);
    
    // Stop scanner
    stopScanner();
    
    // Fill in the barcode field
    document.getElementById('barcode').value = code;
    document.getElementById('manual-barcode').value = code;
    
    // Show detected barcode confirmation
    document.getElementById('detected-code').textContent = code;
    document.getElementById('detected-barcode').classList.remove('hidden');
    
    // Show success message
    showMessage('Barcode detected! Please enter product details manually or upload a photo for AI text extraction.', 'success');
    
    // Focus on next field
    document.getElementById('brand').focus();
}

// Setup photo upload functionality
function setupPhotoUpload() {
    const photoInput = document.getElementById('product-photo');
    const photoPreview = document.getElementById('photo-preview');
    const previewImage = document.getElementById('preview-image');
    const removePhotoBtn = document.getElementById('remove-photo');
    const extractTextBtn = document.getElementById('extract-text');
    
    // Handle file selection
    photoInput.addEventListener('change', function(e) {
        const file = e.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = function(e) {
                previewImage.src = e.target.result;
                photoPreview.classList.remove('hidden');
                extractTextBtn.disabled = false;
            };
            reader.readAsDataURL(file);
        }
    });
    
    // Remove photo
    removePhotoBtn.addEventListener('click', function() {
        photoInput.value = '';
        photoPreview.classList.add('hidden');
        extractTextBtn.disabled = true;
    });
    
    // Extract text from photo
    extractTextBtn.addEventListener('click', async function() {
        const file = photoInput.files[0];
        if (!file) return;
        
        extractTextBtn.disabled = true;
        extractTextBtn.textContent = 'Extracting...';
        
        try {
            const result = await extractTextFromImage(file);
            console.log('🔍 Extraction result:', result);
            
            if (result.success) {
                // Display the raw extracted text
                const extractedTextDisplay = document.getElementById('extracted-text-display');
                const extractedTextContent = document.getElementById('extracted-text-content');
                
                extractedTextContent.textContent = result.text;
                extractedTextDisplay.classList.remove('hidden');
                
                console.log('📝 About to parse text:', result.text);
                
                // Parse extracted text and try to populate fields
                await parseExtractedText(result.text);
                showMessage('Text extracted from photo successfully! Check console for details.', 'success');
            } else {
                console.error('❌ Extraction failed:', result.error);
                showMessage('Could not extract text from photo: ' + result.error, 'error');
            }
        } catch (error) {
            console.error('❌ Text extraction error:', error);
            showMessage('Error extracting text from photo: ' + error.message, 'error');
        } finally {
            extractTextBtn.disabled = false;
            extractTextBtn.textContent = 'Extract Text from Photo';
        }
    });
}

// Parse extracted text and populate form fields
async function parseExtractedText(text) {
    console.log('📝 Parsing extracted text:', text);
    
    // Clean up the text - remove extra spaces and normalize
    const cleanedText = text.replace(/\s+/g, ' ').trim();
    console.log('📝 Cleaned text:', cleanedText);
    
    // Try to identify brand, product name, size, etc.
    let brand = '';
    let productName = '';
    let size = '';
    let description = '';
    
    // Look for size patterns first (most reliable)
    const sizePattern = /(\d+(?:\.\d+)?)\s*(oz|fl oz|ml|g|kg|lbs?|lb|pound|ounce|gram|liter|gallon|quart|pint|cups?)/i;
    const sizeMatch = cleanedText.match(sizePattern);
    if (sizeMatch) {
        size = sizeMatch[0];
        console.log('✅ Found size:', size);
    }
    
    // Look for brand patterns - common brand indicators
    const brandPatterns = [
        /Little Sesame/i,
        /Coca.?Cola/i,
        /Pepsi/i,
        /Nestle/i,
        /Kraft/i,
        /General Mills/i,
        /USDA ORGANIC/i
    ];
    
    for (const pattern of brandPatterns) {
        const match = cleanedText.match(pattern);
        if (match) {
            brand = match[0];
            console.log('✅ Found brand:', brand);
            break;
        }
    }
    
    // If no specific brand found, try to extract from common patterns
    if (!brand) {
        // Look for text before common product words
        const productWords = ['HUMMUS', 'CUPS', 'FOR KIDS', 'ON-THE-GO'];
        for (const word of productWords) {
            const beforeWord = cleanedText.split(word)[0].trim();
            if (beforeWord && beforeWord.length > 2) {
                brand = beforeWord;
                console.log('✅ Extracted brand from context:', brand);
                break;
            }
        }
    }
    
    // Extract product name - look for descriptive text
    if (cleanedText.includes('HUMMUS FOR KIDS')) {
        productName = 'Hummus for Kids';
    } else if (cleanedText.includes('ON-THE-GO')) {
        productName = 'On-the-Go Hummus Cups';
    } else {
        // Try to find product name between brand and size
        const parts = cleanedText.split(/\d+(?:\.\d+)?\s*(oz|fl oz|ml|g|kg|lbs?|lb|pound|ounce|gram|liter|gallon|quart|pint|cups?)/i);
        if (parts.length > 1) {
            productName = parts[1].trim();
        }
    }
    
    // Use the full cleaned text as description
    description = cleanedText;
    
    console.log('📝 Parsed data:', { brand, productName, size, description });
    
    // Populate form fields if we found data
    if (brand) {
        document.getElementById('brand').value = brand;
        console.log('✅ Set brand field to:', brand);
    }
    if (productName) {
        document.getElementById('name').value = productName;
        console.log('✅ Set name field to:', productName);
    }
    if (size) {
        document.getElementById('size').value = size;
        console.log('✅ Set size field to:', size);
    }
    if (description) {
        document.getElementById('description').value = description;
        console.log('✅ Set description field to:', description);
    }
    
    console.log('✅ Text parsing complete:', { brand, productName, size, description });
}

// Test function to verify form field population
function testFormPopulation() {
    console.log('🧪 Testing form field population...');
    
    // Test data
    const testData = {
        brand: 'Coca-Cola Company',
        name: 'Coca-Cola Classic',
        description: 'Classic cola beverage with original recipe',
        size: '12 fl oz',
        category: 'Beverages',
        store: 'Whole Foods Market Houston',
        notes: 'Test data for debugging form population'
    };
    
    // Populate each field
    Object.keys(testData).forEach(key => {
        const element = document.getElementById(key);
        if (element) {
            element.value = testData[key];
            console.log(`✅ Set ${key} field to:`, testData[key]);
        } else {
            console.error(`❌ Field ${key} not found!`);
        }
    });
    
    console.log('🧪 Test complete - check form fields');
    showMessage('Test data populated! Check console for details.', 'success');
}

// Update scanner status
function updateScannerStatus(message) {
    document.getElementById('scanner-status').textContent = message;
}

// Handle form submission
async function handleFormSubmit(event) {
    event.preventDefault();
    
    const formData = new FormData(event.target);
    const productData = {
        barcode: formData.get('barcode'),
        brand: formData.get('brand'),
        name: formData.get('name'),
        description: formData.get('description'),
        size: formData.get('size'),
        category: formData.get('category'),
        store: formData.get('store'),
        scan_date: formData.get('scan_date') || new Date().toISOString().split('T')[0],
        notes: formData.get('notes') || null,
        added_by: currentUser.id
    };
    
    console.log('💾 Saving product:', productData);
    
    try {
        const barcode = productData.barcode.trim();
        const brandName = productData.brand.trim();
        
        if (!barcode || !brandName) {
            showMessage('Barcode and brand name are required', 'error');
            return;
        }
        
        // Step 1: Check if product exists by SKU (globally unique) - use sku or barcode column
        const { data: existingProduct, error: checkError } = await supabase
            .from('products')
            .select('id, name, sku, barcode, brand')
            .or(`sku.eq.${barcode},barcode.eq.${barcode}`)
            .maybeSingle();
        
        let productId;
        
        if (existingProduct) {
            // Product exists - don't create duplicate, just link to brand
            const existingName = existingProduct.name || 'Unknown';
            const existingBrand = existingProduct.brand || 'Unknown';
            
            const shouldLink = confirm(
                `Product with SKU ${barcode} already exists:\n\n` +
                `Brand: ${existingBrand}\n` +
                `Name: ${existingName}\n\n` +
                `This product will be linked to "${brandName}" instead of creating a duplicate.\n\n` +
                `Continue?`
            );
            
            if (!shouldLink) {
                return;
            }
            
            productId = existingProduct.id;
            
            // Update sku if barcode column exists but sku is null
            if (!existingProduct.sku && barcode) {
                await supabase
                    .from('products')
                    .update({ sku: barcode })
                    .eq('id', productId);
            }
        } else {
            // Product doesn't exist - create it with both barcode and sku
            const newProductData = {
                ...productData,
                sku: barcode,  // Set sku = barcode for global uniqueness
                barcode: barcode
            };
            
            const { data: newProduct, error: insertError } = await supabase
                .from('products')
                .insert(newProductData)
                .select('id')
                .single();
            
            if (insertError) {
                if (insertError.code === '23505') {
                    // Unique constraint - product was created between check and insert
                    // Retry fetch
                    const { data: retryProduct } = await supabase
                        .from('products')
                        .select('id')
                        .or(`sku.eq.${barcode},barcode.eq.${barcode}`)
                        .maybeSingle();
                    
                    if (retryProduct) {
                        productId = retryProduct.id;
                        showMessage('Product already exists - linking to brand', 'warning');
                    } else {
                        throw insertError;
                    }
                } else {
                    throw insertError;
                }
            } else {
                productId = newProduct.id;
            }
        }
        
        // Step 2: Link product to brand via brand_products (if brand exists)
        if (productId && brandName) {
            // Find brand by name
            const { data: brand, error: brandError } = await supabase
                .from('brands')
                .select('id')
                .ilike('name', brandName)
                .maybeSingle();
            
            if (brand && !brandError) {
                // Brand exists - link product
                const { error: linkError } = await supabase
                    .from('brand_products')
                    .upsert({
                        brand_id: brand.id,
                        product_id: productId
                    }, {
                        onConflict: 'brand_id,product_id',
                        ignoreDuplicates: false
                    });
                
                if (linkError) {
                    console.warn('Could not link product to brand:', linkError);
                } else {
                    console.log(`✅ Linked product to brand: ${brandName}`);
                }
            } else {
                console.log(`⚠️ Brand "${brandName}" not found - product saved but not linked`);
            }
        }
        
        console.log('✅ Product saved successfully:', productId);
        showMessage('Product saved successfully!', 'success');
        
        // Clear form
        clearForm();
        
        // Reload recent products
        await loadRecentProducts();
        
    } catch (error) {
        console.error('Error saving product:', error);
        showMessage('Error saving product: ' + error.message, 'error');
    }
}

// Clear form
function clearForm() {
    document.getElementById('product-form').reset();
    document.getElementById('detected-barcode').classList.add('hidden');
    document.getElementById('manual-form').classList.add('hidden');
    document.getElementById('barcode').focus();
}

// Load recent products
async function loadRecentProducts() {
    try {
        const { data: products, error } = await supabase
            .from('products')
            .select('*')
            .order('created_at', { ascending: false })
            .limit(10);
        
        if (error) {
            console.error('Error loading recent products:', error);
            document.getElementById('recent-products').innerHTML = '<div class="text-center text-red-500">Error loading products</div>';
            return;
        }
        
        if (!products || products.length === 0) {
            document.getElementById('recent-products').innerHTML = '<div class="text-center text-gray-500">No products added yet</div>';
            return;
        }
        
        const productsHtml = products.map(product => `
            <div class="py-3 border-b border-gray-200 last:border-b-0">
                <div class="flex items-start justify-between">
                    <div class="flex-1">
                        <div class="flex items-center mb-1">
                            <span class="font-mono text-sm bg-gray-100 px-2 py-1 rounded mr-3">${product.barcode}</span>
                            <div class="font-medium text-gray-900">${product.brand} - ${product.name}</div>
                        </div>
                        <div class="text-sm text-gray-600 mb-1">${product.description}</div>
                        <div class="flex items-center text-sm text-gray-500">
                            <span class="mr-4">Size: ${product.size}</span>
                            <span class="mr-4">Category: ${product.category}</span>
                            <span class="mr-4">Store: ${product.store}</span>
                            <span>Scanned: ${new Date(product.scan_date).toLocaleDateString()}</span>
                        </div>
                    </div>
                </div>
            </div>
        `).join('');
        
        document.getElementById('recent-products').innerHTML = productsHtml;
        
    } catch (error) {
        console.error('Error loading recent products:', error);
        document.getElementById('recent-products').innerHTML = '<div class="text-center text-red-500">Error loading products</div>';
    }
}

// Show message
function showMessage(message, type) {
    const messageEl = document.getElementById('message');
    messageEl.textContent = message;
    messageEl.classList.remove('hidden', 'text-green-600', 'text-red-600', 'text-blue-600');
    
    if (type === 'success') {
        messageEl.classList.add('text-green-600');
    } else if (type === 'error') {
        messageEl.classList.add('text-red-600');
    } else {
        messageEl.classList.add('text-blue-600');
    }
    
    // Auto-hide after 3 seconds
    setTimeout(() => {
        messageEl.classList.add('hidden');
    }, 3000);
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

// Get current location using GPS
async function getCurrentLocation() {
    const gpsButton = document.getElementById('gps-location');
    const storeInput = document.getElementById('store');
    const statusEl = document.getElementById('location-status');
    
    // Check if geolocation is supported
    if (!navigator.geolocation) {
        showLocationStatus('GPS not supported by this browser', 'error');
        return;
    }
    
    // Show loading state
    gpsButton.disabled = true;
    gpsButton.innerHTML = `
        <svg class="h-4 w-4 animate-spin" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
        </svg>
        <span class="ml-1 text-xs">Getting...</span>
    `;
    showLocationStatus('Getting your location...', 'info');
    
    try {
        // Get current position
        const position = await new Promise((resolve, reject) => {
            navigator.geolocation.getCurrentPosition(resolve, reject, {
                enableHighAccuracy: true,
                timeout: 10000,
                maximumAge: 300000 // 5 minutes
            });
        });
        
        const { latitude, longitude } = position.coords;
        console.log('📍 GPS coordinates:', { latitude, longitude });
        
        // Try to get address from coordinates using reverse geocoding
        try {
            const address = await reverseGeocode(latitude, longitude);
            if (address) {
                storeInput.value = address;
                showLocationStatus(`Location detected: ${address}`, 'success');
            } else {
                // Fallback to coordinates
                storeInput.value = `${latitude.toFixed(6)}, ${longitude.toFixed(6)}`;
                showLocationStatus(`Coordinates: ${latitude.toFixed(6)}, ${longitude.toFixed(6)}`, 'info');
            }
        } catch (geocodeError) {
            console.warn('Reverse geocoding failed:', geocodeError);
            // Fallback to coordinates
            storeInput.value = `${latitude.toFixed(6)}, ${longitude.toFixed(6)}`;
            showLocationStatus(`Coordinates: ${latitude.toFixed(6)}, ${longitude.toFixed(6)}`, 'info');
        }
        
    } catch (error) {
        console.error('GPS error:', error);
        let errorMessage = 'Unable to get location';
        
        if (error.code === 1) {
            errorMessage = 'Location access denied by user';
        } else if (error.code === 2) {
            errorMessage = 'Location unavailable';
        } else if (error.code === 3) {
            errorMessage = 'Location request timed out';
        }
        
        showLocationStatus(errorMessage, 'error');
    } finally {
        // Reset button
        gpsButton.disabled = false;
        gpsButton.innerHTML = `
            <svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path>
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path>
            </svg>
            <span class="ml-1 text-xs">GPS</span>
        `;
    }
}

// Reverse geocoding to get address from coordinates
async function reverseGeocode(latitude, longitude) {
    try {
        // Using OpenStreetMap Nominatim API (free, no API key required)
        const response = await fetch(
            `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}&zoom=18&addressdetails=1`
        );
        
        if (!response.ok) {
            throw new Error('Geocoding service unavailable');
        }
        
        const data = await response.json();
        
        if (data && data.display_name) {
            // Extract relevant parts of the address
            const address = data.display_name;
            
            // Try to extract store name or business name
            if (data.address) {
                const { shop, amenity, name, house_number, road, city, state } = data.address;
                
                // Look for business names
                if (name && (shop || amenity)) {
                    return `${name} - ${city || state || 'Unknown City'}`;
                }
                
                // Fallback to street address
                if (road && city) {
                    return `${road} ${house_number || ''}, ${city}`.trim();
                }
            }
            
            // Final fallback
            return address.split(',')[0] + ', ' + (data.address?.city || data.address?.state || 'Unknown');
        }
        
        return null;
    } catch (error) {
        console.error('Reverse geocoding error:', error);
        return null;
    }
}

// Show location status message
function showLocationStatus(message, type) {
    const statusEl = document.getElementById('location-status');
    statusEl.textContent = message;
    statusEl.classList.remove('hidden', 'text-green-600', 'text-red-600', 'text-blue-600');
    
    if (type === 'success') {
        statusEl.classList.add('text-green-600');
    } else if (type === 'error') {
        statusEl.classList.add('text-red-600');
    } else {
        statusEl.classList.add('text-blue-600');
    }
    
    // Auto-hide after 5 seconds
    setTimeout(() => {
        statusEl.classList.add('hidden');
    }, 5000);
}
