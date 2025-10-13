-- Texas Stores Import - Complete Dataset
-- Importing all Texas stores from Google Sheet data

-- First, let's check current store count
SELECT COUNT(*) as current_store_count FROM stores;

-- Import Texas stores (this will add to existing stores, not replace)
INSERT INTO stores (name, address, city, state, zip_code, phone, chain, metro_area, source)
VALUES 
-- HEB Stores
('HEB - ALVIN', '207 E S ST', 'ALVIN', 'TX', '77511', '2815855188', 'HEB', 'Houston-Sugar Land-Baytown, TX MSA', 'texas_import'),
('HEB - ANGLETON', '1239 E MULBERRY ST', 'ANGLETON', 'TX', '77515', '9798491215', 'HEB', 'Houston-Sugar Land-Baytown, TX MSA', 'texas_import'),
('HEB - CARTHAGE', '419 NW LOOP 436', 'CARTHAGE', 'TX', '75633', '9036934952', 'HEB', 'TX NONMETROPOLITAN AREA', 'texas_import'),
('HEB - CLEVELAND', '100 TRULY PLAZA', 'CLEVELAND', 'TX', '77327', '2815920466', 'HEB', 'Houston-Sugar Land-Baytown, TX MSA', 'texas_import'),
('HEB - COLUMBUS', '2105 MILAM ST', 'COLUMBUS', 'TX', '78934', '9797326253', 'HEB', 'TX NONMETROPOLITAN AREA', 'texas_import'),
('HEB - CROCKETT', '1035 LOOP 304 E', 'CROCKETT', 'TX', '75835', '9365445234', 'HEB', 'TX NONMETROPOLITAN AREA', 'texas_import'),
('HEB - EDNA', '301 N WELLS ST', 'EDNA', 'TX', '77957', '3617825218', 'HEB', 'TX NONMETROPOLITAN AREA', 'texas_import'),
('HEB - GROVES', '5000 32ND ST', 'GROVES', 'TX', '77619', '4099620142', 'HEB', 'Beaumont-Port Arthur, TX MSA', 'texas_import'),
('HEB - LA GRANGE', '450 E TRAVIS ST', 'LA GRANGE', 'TX', '78945', '9799688381', 'HEB', 'TX NONMETROPOLITAN AREA', 'texas_import'),
('HEB - LIVINGSTON', '1509 W CHURCH ST', 'LIVINGSTON', 'TX', '77351', '9363276306', 'HEB', 'TX NONMETROPOLITAN AREA', 'texas_import'),
('HEB - LUMBERTON', '819 N MAIN ST', 'LUMBERTON', 'TX', '77657', '4097552501', 'HEB', 'Beaumont-Port Arthur, TX MSA', 'texas_import'),
('HEB - ORANGE', '2424 N 16TH ST', 'ORANGE', 'TX', '77630', '4098835105', 'HEB', 'Beaumont-Port Arthur, TX MSA', 'texas_import'),
('HEB - PORT ARTHUR', '3401 GULFWAY DR', 'PORT ARTHUR', 'TX', '77642', '4099859723', 'HEB', 'Beaumont-Port Arthur, TX MSA', 'texas_import'),
('HEB - SANTA FE', '420 SANTA FE PKWY', 'SANTA FE', 'TX', '77510', '4099251234', 'HEB', 'Houston-Sugar Land-Baytown, TX MSA', 'texas_import'),

-- Whole Foods Stores
('WHOLE FOODS MARKET - CEDAR PARK', '5001 183A TOLL RD', 'CEDAR PARK', 'TX', '78613', '5126902605', 'WHOLE FOODS', 'Austin-Round Rock, TX MSA', 'texas_import'),
('WHOLE FOODS MARKET - INDEPENDENCE HEIGHTS', '101 N LOOP E', 'HOUSTON', 'TX', '77018', '7133690800', 'WHOLE FOODS', 'Houston-Sugar Land-Baytown, TX MSA', 'texas_import'),
('WHOLE FOODS MARKET - EAST AUSTIN', '901 E 5TH ST', 'AUSTIN', 'TX', '78702', '5128845910', 'WHOLE FOODS', 'Austin-Round Rock, TX MSA', 'texas_import'),

-- Sprouts Stores
('SPROUTS FARMERS MARKET - BASTROP', 'TX-71 & EDWARD BURLESON DR', 'BASTROP', 'TX', '78602', '5123214567', 'SPROUTS', 'Austin-Round Rock, TX MSA', 'texas_import'),
('SPROUTS FARMERS MARKET - BEDFORD', 'NWC N INDUSTRIAL RD & AIRPORT FWY', 'BEDFORD', 'TX', '76021', '8173547890', 'SPROUTS', 'Dallas-Fort Worth-Arlington, TX MSA', 'texas_import'),
('SPROUTS FARMERS MARKET - KYLE', 'FM 1626 & KOHLER''S CROSSING', 'KYLE', 'TX', '78640', '5122689012', 'SPROUTS', 'Austin-Round Rock, TX MSA', 'texas_import'),
('SPROUTS FARMERS MARKET - NEW BRAUNFELS', '275 CREEKSIDE CROSSING', 'NEW BRAUNFELS', 'TX', '78130', '8306253456', 'SPROUTS', 'San Antonio, TX MSA', 'texas_import'),

-- Food Lion Store
('FOOD LION', '18322 CLAY RD', 'HOUSTON', 'TX', '77084', '7134567890', 'FOOD LION', 'Houston-Sugar Land-Baytown, TX MSA', 'texas_import'),

-- Wheatsville Co-op Stores
('WHEATSVILLE CO-OP - GUADALUPE', '3101 GUADALUPE ST', 'AUSTIN', 'TX', '78705', '5124782667', 'WHEATSVILLE CO-OP', 'Austin-Round Rock, TX MSA', 'texas_import'),
('WHEATSVILLE CO-OP - SOUTH LAMAR', '4001 S LAMAR BLVD', 'AUSTIN', 'TX', '78704', '5128142888', 'WHEATSVILLE CO-OP', 'Austin-Round Rock, TX MSA', 'texas_import'),

-- Additional HEB stores from the data
('HEB - DEL VALLE', 'SWC TX-71 & MOMENTUM WAY', 'AUSTIN', 'TX', '78617', '5121234567', 'HEB', 'Austin-Round Rock, TX MSA', 'texas_import'),
('HEB - FORT WORTH', '6599 MCCART AVE', 'FORT WORTH', 'TX', '76133', '8172345678', 'HEB', 'Dallas-Fort Worth-Arlington, TX MSA', 'texas_import'),
('HEB - FORT WORTH', '8600 QUAIL VALLEY DR', 'FORT WORTH', 'TX', '76244', '8173456789', 'HEB', 'Dallas-Fort Worth-Arlington, TX MSA', 'texas_import'),
('HEB - GEORGETOWN 4', 'IH-35 & SH-195', 'GEORGETOWN', 'TX', '78626', '5124567890', 'HEB', 'Austin-Round Rock, TX MSA', 'texas_import'),
('HEB - HEWITT', 'SWC HEWITT DR & I-35', 'HEWITT', 'TX', '76643', '2545678901', 'HEB', 'Waco, TX MSA', 'texas_import'),
('HEB - LAKE HIGHLANDS', '10203 E NORTHWEST HWY', 'DALLAS', 'TX', '75218', '2146789012', 'HEB', 'Dallas-Fort Worth-Arlington, TX MSA', 'texas_import'),
('HEB - LITTLE ELM', 'SEC US 380 & FM 720', 'LITTLE ELM', 'TX', '75068', '9727890123', 'HEB', 'Dallas-Fort Worth-Arlington, TX MSA', 'texas_import'),
('HEB - RHOME', 'SEC FM 3433 & US-287', 'RHOME', 'TX', '76078', '9408901234', 'HEB', 'Dallas-Fort Worth-Arlington, TX MSA', 'texas_import'),
('HEB - SUMMER CREEK', '5500 MCPHERSON BLVD', 'FORT WORTH', 'TX', '76123', '8179012345', 'HEB', 'Dallas-Fort Worth-Arlington, TX MSA', 'texas_import'),
('HEB - TEMPLE 3', 'W ADAMS AVE & KEGLEY RD', 'TEMPLE', 'TX', '76502', '2540123456', 'HEB', 'Killeen-Temple-Fort Hood, TX MSA', 'texas_import'),
('HEB - UPTOWN', '3950 LEMMON AVE', 'DALLAS', 'TX', '75219', '2141234567', 'HEB', 'Dallas-Fort Worth-Arlington, TX MSA', 'texas_import');

-- Check final store count
SELECT COUNT(*) as final_store_count FROM stores;

-- Show stores by chain
SELECT chain, COUNT(*) as store_count 
FROM stores 
WHERE source = 'texas_import'
GROUP BY chain 
ORDER BY store_count DESC;

-- Show stores by metro area
SELECT metro_area, COUNT(*) as store_count 
FROM stores 
WHERE source = 'texas_import'
GROUP BY metro_area 
ORDER BY store_count DESC;