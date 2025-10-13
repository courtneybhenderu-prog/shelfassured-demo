-- Fixed Texas Stores Import Script (Corrected VALUES)
-- This script imports the curated Texas store data into the Supabase stores table
-- Data source: https://docs.google.com/spreadsheets/d/18E6OfiZ4ikihL8jL98SdKlbyruBHkZPbZJ9QJ7VPCfU/edit?usp=sharing

-- Step 1: Check current stores table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'stores' 
ORDER BY ordinal_position;

-- Step 2: Create temporary table for import
CREATE TEMP TABLE temp_texas_stores (
    chain VARCHAR(100),
    division VARCHAR(100),
    banner VARCHAR(100),
    store_name VARCHAR(200),
    store_number VARCHAR(50),
    address VARCHAR(500),
    city VARCHAR(100),
    state VARCHAR(10),
    zip VARCHAR(20),
    metro VARCHAR(200),
    country VARCHAR(10),
    phone VARCHAR(20),
    state_norm VARCHAR(10)
);

-- Step 3: Insert sample Texas stores (all rows have exactly 13 values)
INSERT INTO temp_texas_stores VALUES
-- H-E-B Stores (Primary focus)
('HEB', 'HEB', 'HEB', 'ALVIN', '288', '207 E S ST', 'ALVIN', 'TX', '77511', 'Houston-Sugar Land-Baytown, TX MSA', 'US', '2815855188', 'TX'),
('HEB', 'HEB', 'HEB', 'ANGLETON', '17', '1239 E MULBERRY ST', 'ANGLETON', 'TX', '77515', 'Houston-Sugar Land-Baytown, TX MSA', 'US', '9798491215', 'TX'),
('HEB', 'HEB', 'HEB', 'CARTHAGE', '458', '419 NW LOOP 436', 'CARTHAGE', 'TX', '75633', 'TX NONMETROPOLITAN AREA', 'US', '9036934952', 'TX'),
('HEB', 'HEB', 'HEB', 'CLEVELAND', '257', '100 TRULY PLAZA', 'CLEVELAND', 'TX', '77327', 'Houston-Sugar Land-Baytown, TX MSA', 'US', '2815920466', 'TX'),
('HEB', 'HEB', 'HEB', 'COLUMBUS', '256', '2105 MILAM ST', 'COLUMBUS', 'TX', '78934', 'TX NONMETROPOLITAN AREA', 'US', '9797326253', 'TX'),
('HEB', 'HEB', 'HEB', 'CROCKETT', '287', '1035 LOOP 304 E', 'CROCKETT', 'TX', '75835', 'TX NONMETROPOLITAN AREA', 'US', '9365445234', 'TX'),
('HEB', 'HEB', 'HEB', 'EDNA', '351', '301 N WELLS ST', 'EDNA', 'TX', '77957', 'TX NONMETROPOLITAN AREA', 'US', '3617825218', 'TX'),
('HEB', 'HEB', 'HEB', 'GROVES', '53', '5000 32ND ST', 'GROVES', 'TX', '77619', 'Beaumont-Port Arthur, TX MSA', 'US', '4099620142', 'TX'),
('HEB', 'HEB', 'HEB', 'LA GRANGE', '416', '450 E TRAVIS ST', 'LA GRANGE', 'TX', '78945', 'TX NONMETROPOLITAN AREA', 'US', '9799688381', 'TX'),
('HEB', 'HEB', 'HEB', 'LIVINGSTON', '339', '1509 W CHURCH ST', 'LIVINGSTON', 'TX', '77351', 'TX NONMETROPOLITAN AREA', 'US', '9363276306', 'TX'),
('HEB', 'HEB', 'HEB', 'LUMBERTON', '116', '819 N MAIN ST', 'LUMBERTON', 'TX', '77657', 'Beaumont-Port Arthur, TX MSA', 'US', '4097552501', 'TX'),
('HEB', 'HEB', 'HEB', 'ORANGE', '35', '2424 N 16TH ST', 'ORANGE', 'TX', '77630', 'Beaumont-Port Arthur, TX MSA', 'US', '4098835105', 'TX'),
('HEB', 'HEB', 'HEB', 'PORT ARTHUR', '86', '3401 GULFWAY DR', 'PORT ARTHUR', 'TX', '77642', 'Beaumont-Port Arthur, TX MSA', 'US', '4099859723', 'TX'),
('HEB', 'HEB', 'HEB', 'SANTA FE', '348', '4206 AVE T', 'SANTA FE', 'TX', '77510', 'Houston-Sugar Land-Baytown, TX MSA', 'US', '4099255186', 'TX'),
('HEB', 'HEB', 'HEB', 'WEST COLUMBIA', '271', '110 W BRAZOS ST', 'WEST COLUMBIA', 'TX', '77486', 'Houston-Sugar Land-Baytown, TX MSA', 'US', '9793456950', 'TX'),
('HEB', 'HEB', 'HEB', 'YOAKUM', '355', '201 W GONZALES', 'YOAKUM', 'TX', '77995', 'TX NONMETROPOLITAN AREA', 'US', '3612935281', 'TX'),

-- Whole Foods Market
('AMAZON', 'CENTRAL WEST', 'WHOLE FOODS MARKET', 'CEDAR PARK', '10665', '5001 183A TOLL RD', 'CEDAR PARK', 'TX', '78613', 'Austin-Round Rock, TX MSA', 'US', '5126902605', 'TX'),
('AMAZON', 'CENTRAL WEST', 'WHOLE FOODS MARKET', 'INDEPENDENCE HEIGHTS', '10652', '101 N LOOP E', 'HOUSTON', 'TX', '77018', 'Houston-Sugar Land-Baytown, TX MSA', 'US', '7133690800', 'TX'),
('AMAZON', 'CENTRAL WEST', 'WHOLE FOODS MARKET', 'EAST AUSTIN', '10721', '901 E 5TH ST', 'AUSTIN', 'TX', '78702', 'Austin-Round Rock, TX MSA', 'US', '5128845910', 'TX'),

-- Tom Thumb (Albertsons)
('ALBERTSONS', 'SOUTHERN', 'TOM THUMB', 'ARGYLE HARVEST', '12', 'NEC FM 407 & HARVEST WAY', 'ARGYLE', 'TX', '76226', 'Dallas-Fort Worth-Arlington, TX MSA', 'US', '', 'TX'),
('ALBERTSONS', 'SOUTHERN', 'TOM THUMB', 'FORNEY', '26', '435 FM 548', 'FORNEY', 'TX', '75126', 'Dallas-Fort Worth-Arlington, TX MSA', 'US', '', 'TX'),
('ALBERTSONS', 'SOUTHERN', 'TOM THUMB', 'MIDLOTHIAN', '4789', 'NEC N WALNUT GROVE RD & FM 1387', 'MIDLOTHIAN', 'TX', '76065', 'Dallas-Fort Worth-Arlington, TX MSA', 'US', '', 'TX'),
('ALBERTSONS', 'SOUTHERN', 'TOM THUMB', 'SANGER', '', 'NWC 1-35 & CHAPMAN RD', 'SANGER', 'TX', '76266', 'Dallas-Fort Worth-Arlington, TX MSA', 'US', '', 'TX'),
('ALBERTSONS', 'SOUTHERN', 'TOM THUMB', 'SUNNYVALE', '4788', 'SEC BELTLINE RD & E TOWN EAST BLVD', 'SUNNYVALE', 'TX', '75182', 'Dallas-Fort Worth-Arlington, TX MSA', 'US', '', 'TX'),

-- Sprouts Farmers Market
('SPROUTS', 'SPROUTS', 'SPROUTS FARMERS MARKET', 'BASTROP', '', 'TX-71 & EDWARD BURLESON DR', 'BASTROP', 'TX', '78602', 'Austin-Round Rock, TX MSA', 'US', '', 'TX'),
('SPROUTS', 'SPROUTS', 'SPROUTS FARMERS MARKET', 'BEDFORD', '', 'NWC N INDUSTRIAL RD & AIRPORT FWY', 'BEDFORD', 'TX', '76021', 'Dallas-Fort Worth-Arlington, TX MSA', 'US', '', 'TX'),
('SPROUTS', 'SPROUTS', 'SPROUTS FARMERS MARKET', 'KYLE', '', 'FM 1626 & KOHLER''S CROSSING', 'KYLE', 'TX', '78640', 'Austin-Round Rock, TX MSA', 'US', '', 'TX'),
('SPROUTS', 'SPROUTS', 'SPROUTS FARMERS MARKET', 'NEW BRAUNFELS', '', '275 CREEKSIDE CROSSING', 'NEW BRAUNFELS', 'TX', '78130', 'San Antonio, TX MSA', 'US', '', 'TX'),

-- Natural Grocers
('NATURAL GROCERS', 'NATURAL GROCERS', 'NATURAL GROCERS', 'WACO', '', '601 N VALLEY MILLS DR', 'WACO', 'TX', '76710', 'Waco, TX MSA', 'US', '', 'TX'),

-- Food Lion (FIXED - now has 13 values)
('AHOLD', 'FOOD LION', 'FOOD LION', '1313', '1313', '18322 CLAY RD', 'HOUSTON', 'TX', '77084', '', 'US', '', 'TX'),

-- Wheatsville Co-op
('NCG', 'WEST', 'WHEATSVILLE CO-OP', 'GUADALUPE', '', '3101 GUADALUPE ST', 'AUSTIN', 'TX', '78705', 'Austin-Round Rock, TX MSA', 'US', '5124782667', 'TX'),
('NCG', 'WEST', 'WHEATSVILLE CO-OP', 'SOUTH LAMAR', '', '4001 S LAMAR BLVD', 'AUSTIN', 'TX', '78704', 'Austin-Round Rock, TX MSA', 'US', '5128142888', 'TX');

-- Step 4: Check imported data
SELECT COUNT(*) as total_stores FROM temp_texas_stores;
SELECT chain, COUNT(*) as store_count FROM temp_texas_stores GROUP BY chain ORDER BY store_count DESC;

-- Step 5: Insert into stores table (without ON CONFLICT)
INSERT INTO stores (
    name,
    address,
    city,
    state,
    zip_code,
    phone,
    is_active,
    created_at,
    updated_at
)
SELECT 
    CASE 
        WHEN store_name IS NOT NULL AND store_name != '' THEN store_name
        WHEN banner IS NOT NULL AND banner != '' THEN banner
        ELSE 'Unknown Store'
    END as name,
    address,
    city,
    state,
    zip,
    phone,
    true as is_active,
    NOW() as created_at,
    NOW() as updated_at
FROM temp_texas_stores
WHERE state = 'TX';  -- Only Texas stores

-- Step 6: Check results
SELECT COUNT(*) as imported_stores FROM stores WHERE state = 'TX';
SELECT name, city, state FROM stores WHERE state = 'TX' ORDER BY name LIMIT 10;

-- Step 7: Clean up temp table
DROP TABLE temp_texas_stores;

-- Step 8: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_stores_state ON stores(state);
CREATE INDEX IF NOT EXISTS idx_stores_city ON stores(city);
CREATE INDEX IF NOT EXISTS idx_stores_name ON stores(name);
CREATE INDEX IF NOT EXISTS idx_stores_zip ON stores(zip_code);

-- Step 9: Verify the import
SELECT 
    'Import Complete' as status,
    COUNT(*) as total_stores,
    COUNT(DISTINCT city) as cities_covered,
    COUNT(DISTINCT state) as states_covered
FROM stores 
WHERE state = 'TX' AND is_active = true;
