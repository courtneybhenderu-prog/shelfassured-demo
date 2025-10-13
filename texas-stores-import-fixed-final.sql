-- Fixed Texas Stores Import Script (Using Actual Table Structure)
-- This script works with your current stores table columns:
-- id, name, address, city, state, zip_code, latitude, longitude, phone, store_chain

-- Step 1: Create temporary table for import
CREATE TEMP TABLE temp_texas_stores (
    chain VARCHAR(100),           -- Column A: CHAIN
    division VARCHAR(100),        -- Column B: DIVISION  
    banner VARCHAR(100),          -- Column C: BANNER
    store_location_name VARCHAR(200), -- Column D: STORE LOCATION NAME
    store VARCHAR(200),          -- Column E: STORE (this is our display name)
    store_name VARCHAR(200),      -- Column F: Store (duplicate?)
    store_number VARCHAR(50),     -- Column G: Store #
    address VARCHAR(500),         -- Column H: ADDRESS
    city VARCHAR(100),            -- Column I: CITY
    state VARCHAR(10),            -- Column J: STATE
    zip VARCHAR(20),              -- Column K: ZIP
    metro VARCHAR(200),           -- Column L: METRO
    phone VARCHAR(20)             -- Column M: PHONE
);

-- Step 2: Insert sample Texas stores with correct column mapping
INSERT INTO temp_texas_stores VALUES
-- H-E-B Stores (Primary focus) - using Column E (STORE) for display names
('HEB', 'HEB', 'HEB', 'ALVIN', 'HEB - ALVIN', 'HEB - ALVIN', '288', '207 E S ST', 'ALVIN', 'TX', '77511', 'Houston-Sugar Land-Baytown, TX MSA', '2815855188'),
('HEB', 'HEB', 'HEB', 'ANGLETON', 'HEB - ANGLETON', 'HEB - ANGLETON', '17', '1239 E MULBERRY ST', 'ANGLETON', 'TX', '77515', 'Houston-Sugar Land-Baytown, TX MSA', '9798491215'),
('HEB', 'HEB', 'HEB', 'CARTHAGE', 'HEB - CARTHAGE', 'HEB - CARTHAGE', '458', '419 NW LOOP 436', 'CARTHAGE', 'TX', '75633', 'TX NONMETROPOLITAN AREA', '9036934952'),
('HEB', 'HEB', 'HEB', 'CLEVELAND', 'HEB - CLEVELAND', 'HEB - CLEVELAND', '257', '100 TRULY PLAZA', 'CLEVELAND', 'TX', '77327', 'Houston-Sugar Land-Baytown, TX MSA', '2815920466'),
('HEB', 'HEB', 'HEB', 'COLUMBUS', 'HEB - COLUMBUS', 'HEB - COLUMBUS', '256', '2105 MILAM ST', 'COLUMBUS', 'TX', '78934', 'TX NONMETROPOLITAN AREA', '9797326253'),
('HEB', 'HEB', 'HEB', 'CROCKETT', 'HEB - CROCKETT', 'HEB - CROCKETT', '287', '1035 LOOP 304 E', 'CROCKETT', 'TX', '75835', 'TX NONMETROPOLITAN AREA', '9365445234'),
('HEB', 'HEB', 'HEB', 'EDNA', 'HEB - EDNA', 'HEB - EDNA', '351', '301 N WELLS ST', 'EDNA', 'TX', '77957', 'TX NONMETROPOLITAN AREA', '3617825218'),
('HEB', 'HEB', 'HEB', 'GROVES', 'HEB - GROVES', 'HEB - GROVES', '53', '5000 32ND ST', 'GROVES', 'TX', '77619', 'Beaumont-Port Arthur, TX MSA', '4099620142'),
('HEB', 'HEB', 'HEB', 'LA GRANGE', 'HEB - LA GRANGE', 'HEB - LA GRANGE', '416', '450 E TRAVIS ST', 'LA GRANGE', 'TX', '78945', 'TX NONMETROPOLITAN AREA', '9799688381'),
('HEB', 'HEB', 'HEB', 'LIVINGSTON', 'HEB - LIVINGSTON', 'HEB - LIVINGSTON', '339', '1509 W CHURCH ST', 'LIVINGSTON', 'TX', '77351', 'TX NONMETROPOLITAN AREA', '9363276306'),
('HEB', 'HEB', 'HEB', 'LUMBERTON', 'HEB - LUMBERTON', 'HEB - LUMBERTON', '116', '819 N MAIN ST', 'LUMBERTON', 'TX', '77657', 'Beaumont-Port Arthur, TX MSA', '4097552501'),
('HEB', 'HEB', 'HEB', 'ORANGE', 'HEB - ORANGE', 'HEB - ORANGE', '35', '2424 N 16TH ST', 'ORANGE', 'TX', '77630', 'Beaumont-Port Arthur, TX MSA', '4098835105'),
('HEB', 'HEB', 'HEB', 'PORT ARTHUR', 'HEB - PORT ARTHUR', 'HEB - PORT ARTHUR', '86', '3401 GULFWAY DR', 'PORT ARTHUR', 'TX', '77642', 'Beaumont-Port Arthur, TX MSA', '4099859723'),
('HEB', 'HEB', 'HEB', 'SANTA FE', 'HEB - SANTA FE', 'HEB - SANTA FE', '348', '4206 AVE T', 'SANTA FE', 'TX', '77510', 'Houston-Sugar Land-Baytown, TX MSA', '4099255186'),
('HEB', 'HEB', 'HEB', 'WEST COLUMBIA', 'HEB - WEST COLUMBIA', 'HEB - WEST COLUMBIA', '271', '110 W BRAZOS ST', 'WEST COLUMBIA', 'TX', '77486', 'Houston-Sugar Land-Baytown, TX MSA', '9793456950'),
('HEB', 'HEB', 'HEB', 'YOAKUM', 'HEB - YOAKUM', 'HEB - YOAKUM', '355', '201 W GONZALES', 'YOAKUM', 'TX', '77995', 'TX NONMETROPOLITAN AREA', '3612935281'),

-- Whole Foods Market
('AMAZON', 'CENTRAL WEST', 'WHOLE FOODS MARKET', 'CEDAR PARK', 'WHOLE FOODS MARKET - CEDAR PARK', 'WHOLE FOODS MARKET - CEDAR PARK', '10665', '5001 183A TOLL RD', 'CEDAR PARK', 'TX', '78613', 'Austin-Round Rock, TX MSA', '5126902605'),
('AMAZON', 'CENTRAL WEST', 'WHOLE FOODS MARKET', 'INDEPENDENCE HEIGHTS', 'WHOLE FOODS MARKET - INDEPENDENCE HEIGHTS', 'WHOLE FOODS MARKET - INDEPENDENCE HEIGHTS', '10652', '101 N LOOP E', 'HOUSTON', 'TX', '77018', 'Houston-Sugar Land-Baytown, TX MSA', '7133690800'),
('AMAZON', 'CENTRAL WEST', 'WHOLE FOODS MARKET', 'EAST AUSTIN', 'WHOLE FOODS MARKET - EAST AUSTIN', 'WHOLE FOODS MARKET - EAST AUSTIN', '10721', '901 E 5TH ST', 'AUSTIN', 'TX', '78702', 'Austin-Round Rock, TX MSA', '5128845910'),

-- Tom Thumb (Albertsons)
('ALBERTSONS', 'SOUTHERN', 'TOM THUMB', 'ARGYLE HARVEST', 'TOM THUMB - ARGYLE HARVEST', 'TOM THUMB - ARGYLE HARVEST', '12', 'NEC FM 407 & HARVEST WAY', 'ARGYLE', 'TX', '76226', 'Dallas-Fort Worth-Arlington, TX MSA', ''),
('ALBERTSONS', 'SOUTHERN', 'TOM THUMB', 'FORNEY', 'TOM THUMB - FORNEY', 'TOM THUMB - FORNEY', '26', '435 FM 548', 'FORNEY', 'TX', '75126', 'Dallas-Fort Worth-Arlington, TX MSA', ''),
('ALBERTSONS', 'SOUTHERN', 'TOM THUMB', 'MIDLOTHIAN', 'TOM THUMB - MIDLOTHIAN', 'TOM THUMB - MIDLOTHIAN', '4789', 'NEC N WALNUT GROVE RD & FM 1387', 'MIDLOTHIAN', 'TX', '76065', 'Dallas-Fort Worth-Arlington, TX MSA', ''),
('ALBERTSONS', 'SOUTHERN', 'TOM THUMB', 'SANGER', 'TOM THUMB - SANGER', 'TOM THUMB - SANGER', '', 'NWC 1-35 & CHAPMAN RD', 'SANGER', 'TX', '76266', 'Dallas-Fort Worth-Arlington, TX MSA', ''),
('ALBERTSONS', 'SOUTHERN', 'TOM THUMB', 'SUNNYVALE', 'TOM THUMB - SUNNYVALE', 'TOM THUMB - SUNNYVALE', '4788', 'SEC BELTLINE RD & E TOWN EAST BLVD', 'SUNNYVALE', 'TX', '75182', 'Dallas-Fort Worth-Arlington, TX MSA', ''),

-- Sprouts Farmers Market
('SPROUTS', 'SPROUTS', 'SPROUTS FARMERS MARKET', 'BASTROP', 'SPROUTS FARMERS MARKET - BASTROP', 'SPROUTS FARMERS MARKET - BASTROP', '', 'TX-71 & EDWARD BURLESON DR', 'BASTROP', 'TX', '78602', 'Austin-Round Rock, TX MSA', ''),
('SPROUTS', 'SPROUTS', 'SPROUTS FARMERS MARKET', 'BEDFORD', 'SPROUTS FARMERS MARKET - BEDFORD', 'SPROUTS FARMERS MARKET - BEDFORD', '', 'NWC N INDUSTRIAL RD & AIRPORT FWY', 'BEDFORD', 'TX', '76021', 'Dallas-Fort Worth-Arlington, TX MSA', ''),
('SPROUTS', 'SPROUTS', 'SPROUTS FARMERS MARKET', 'KYLE', 'SPROUTS FARMERS MARKET - KYLE', 'SPROUTS FARMERS MARKET - KYLE', '', 'FM 1626 & KOHLER''S CROSSING', 'KYLE', 'TX', '78640', 'Austin-Round Rock, TX MSA', ''),
('SPROUTS', 'SPROUTS', 'SPROUTS FARMERS MARKET', 'NEW BRAUNFELS', 'SPROUTS FARMERS MARKET - NEW BRAUNFELS', 'SPROUTS FARMERS MARKET - NEW BRAUNFELS', '', '275 CREEKSIDE CROSSING', 'NEW BRAUNFELS', 'TX', '78130', 'San Antonio, TX MSA', ''),

-- Natural Grocers
('NATURAL GROCERS', 'NATURAL GROCERS', 'NATURAL GROCERS', 'WACO', 'NATURAL GROCERS - WACO', 'NATURAL GROCERS - WACO', '', '601 N VALLEY MILLS DR', 'WACO', 'TX', '76710', 'Waco, TX MSA', ''),

-- Food Lion
('AHOLD', 'FOOD LION', 'FOOD LION', 'FOOD LION', 'FOOD LION - HOUSTON', 'FOOD LION - HOUSTON', '1313', '18322 CLAY RD', 'HOUSTON', 'TX', '77084', '', ''),

-- Wheatsville Co-op
('NCG', 'WEST', 'WHEATSVILLE CO-OP', 'GUADALUPE', 'WHEATSVILLE CO-OP - GUADALUPE', 'WHEATSVILLE CO-OP - GUADALUPE', '', '3101 GUADALUPE ST', 'AUSTIN', 'TX', '78705', 'Austin-Round Rock, TX MSA', '5124782667'),
('NCG', 'WEST', 'WHEATSVILLE CO-OP', 'SOUTH LAMAR', 'WHEATSVILLE CO-OP - SOUTH LAMAR', 'WHEATSVILLE CO-OP - SOUTH LAMAR', '', '4001 S LAMAR BLVD', 'AUSTIN', 'TX', '78704', 'Austin-Round Rock, TX MSA', '5128142888');

-- Step 3: Check imported data
SELECT COUNT(*) as total_stores FROM temp_texas_stores;
SELECT chain, COUNT(*) as store_count FROM temp_texas_stores GROUP BY chain ORDER BY store_count DESC;

-- Step 4: Insert into main stores table (using only existing columns)
INSERT INTO public.stores (
    name,           -- Column E (STORE) - clean display name
    address,         -- Column H (ADDRESS)
    city,            -- Column I (CITY)
    state,           -- Column J (STATE)
    zip_code,        -- Column K (ZIP)
    store_chain,     -- Column A (CHAIN) - maps to existing store_chain column
    phone            -- Column M (PHONE)
)
SELECT
    tts.store,                    -- Column E: Clean display name
    tts.address,                  -- Column H: Address
    tts.city,                     -- Column I: City
    tts.state,                    -- Column J: State
    tts.zip,                      -- Column K: ZIP
    tts.chain,                    -- Column A: Chain (maps to store_chain)
    tts.phone                     -- Column M: Phone
FROM
    temp_texas_stores tts;

-- Clean up temporary table
DROP TABLE temp_texas_stores;

-- Verify final count
SELECT COUNT(*) as total_texas_stores FROM public.stores WHERE state = 'TX';

-- Show sample of imported stores
SELECT 
    name,
    address,
    city,
    state,
    zip_code,
    store_chain
FROM public.stores 
WHERE state = 'TX' 
ORDER BY created_at DESC 
LIMIT 10;
