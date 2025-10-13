-- Fix store names and chain data for existing stores
-- This updates the existing stores with correct names from Column E (STORE)

-- Step 1: Update H-E-B stores with correct names
UPDATE public.stores 
SET 
    name = CASE 
        WHEN city = 'ALVIN' THEN 'HEB - ALVIN'
        WHEN city = 'ANGLETON' THEN 'HEB - ANGLETON'
        WHEN city = 'CARTHAGE' THEN 'HEB - CARTHAGE'
        WHEN city = 'CLEVELAND' THEN 'HEB - CLEVELAND'
        WHEN city = 'COLUMBUS' THEN 'HEB - COLUMBUS'
        WHEN city = 'CROCKETT' THEN 'HEB - CROCKETT'
        WHEN city = 'EDNA' THEN 'HEB - EDNA'
        WHEN city = 'GROVES' THEN 'HEB - GROVES'
        WHEN city = 'LA GRANGE' THEN 'HEB - LA GRANGE'
        WHEN city = 'LIVINGSTON' THEN 'HEB - LIVINGSTON'
        WHEN city = 'LUMBERTON' THEN 'HEB - LUMBERTON'
        WHEN city = 'ORANGE' THEN 'HEB - ORANGE'
        WHEN city = 'PORT ARTHUR' THEN 'HEB - PORT ARTHUR'
        WHEN city = 'SANTA FE' THEN 'HEB - SANTA FE'
        WHEN city = 'WEST COLUMBIA' THEN 'HEB - WEST COLUMBIA'
        WHEN city = 'YOAKUM' THEN 'HEB - YOAKUM'
        ELSE name
    END,
    store_chain = 'HEB'
WHERE city IN ('ALVIN', 'ANGLETON', 'CARTHAGE', 'CLEVELAND', 'COLUMBUS', 'CROCKETT', 'EDNA', 'GROVES', 'LA GRANGE', 'LIVINGSTON', 'LUMBERTON', 'ORANGE', 'PORT ARTHUR', 'SANTA FE', 'WEST COLUMBIA', 'YOAKUM')
AND state = 'TX';

-- Step 2: Update Whole Foods stores
UPDATE public.stores 
SET 
    name = CASE 
        WHEN city = 'CEDAR PARK' THEN 'WHOLE FOODS MARKET - CEDAR PARK'
        WHEN city = 'HOUSTON' AND address LIKE '%N LOOP E%' THEN 'WHOLE FOODS MARKET - INDEPENDENCE HEIGHTS'
        WHEN city = 'AUSTIN' AND address LIKE '%E 5TH ST%' THEN 'WHOLE FOODS MARKET - EAST AUSTIN'
        ELSE name
    END,
    store_chain = 'AMAZON'
WHERE (city = 'CEDAR PARK' OR (city = 'HOUSTON' AND address LIKE '%N LOOP E%') OR (city = 'AUSTIN' AND address LIKE '%E 5TH ST%'))
AND state = 'TX';

-- Step 3: Update Tom Thumb stores
UPDATE public.stores 
SET 
    name = CASE 
        WHEN city = 'ARGYLE' THEN 'TOM THUMB - ARGYLE HARVEST'
        WHEN city = 'FORNEY' THEN 'TOM THUMB - FORNEY'
        WHEN city = 'MIDLOTHIAN' THEN 'TOM THUMB - MIDLOTHIAN'
        WHEN city = 'SANGER' THEN 'TOM THUMB - SANGER'
        WHEN city = 'SUNNYVALE' THEN 'TOM THUMB - SUNNYVALE'
        ELSE name
    END,
    store_chain = 'ALBERTSONS'
WHERE city IN ('ARGYLE', 'FORNEY', 'MIDLOTHIAN', 'SANGER', 'SUNNYVALE')
AND state = 'TX';

-- Step 4: Update Sprouts stores
UPDATE public.stores 
SET 
    name = CASE 
        WHEN city = 'BASTROP' THEN 'SPROUTS FARMERS MARKET - BASTROP'
        WHEN city = 'BEDFORD' THEN 'SPROUTS FARMERS MARKET - BEDFORD'
        WHEN city = 'KYLE' THEN 'SPROUTS FARMERS MARKET - KYLE'
        WHEN city = 'NEW BRAUNFELS' THEN 'SPROUTS FARMERS MARKET - NEW BRAUNFELS'
        ELSE name
    END,
    store_chain = 'SPROUTS'
WHERE city IN ('BASTROP', 'BEDFORD', 'KYLE', 'NEW BRAUNFELS')
AND state = 'TX';

-- Step 5: Update other stores
UPDATE public.stores 
SET 
    name = CASE 
        WHEN city = 'WACO' THEN 'NATURAL GROCERS - WACO'
        WHEN city = 'HOUSTON' AND address LIKE '%CLAY RD%' THEN 'FOOD LION - HOUSTON'
        WHEN city = 'AUSTIN' AND address LIKE '%GUADALUPE ST%' THEN 'WHEATSVILLE CO-OP - GUADALUPE'
        WHEN city = 'AUSTIN' AND address LIKE '%S LAMAR BLVD%' THEN 'WHEATSVILLE CO-OP - SOUTH LAMAR'
        ELSE name
    END,
    store_chain = CASE 
        WHEN city = 'WACO' THEN 'NATURAL GROCERS'
        WHEN city = 'HOUSTON' AND address LIKE '%CLAY RD%' THEN 'AHOLD'
        WHEN city = 'AUSTIN' AND (address LIKE '%GUADALUPE ST%' OR address LIKE '%S LAMAR BLVD%') THEN 'NCG'
        ELSE store_chain
    END
WHERE (city = 'WACO' OR (city = 'HOUSTON' AND address LIKE '%CLAY RD%') OR (city = 'AUSTIN' AND (address LIKE '%GUADALUPE ST%' OR address LIKE '%S LAMAR BLVD%')))
AND state = 'TX';

-- Step 6: Verify the updates
SELECT 
    name,
    address,
    city,
    state,
    store_chain
FROM public.stores 
WHERE state = 'TX' 
ORDER BY name
LIMIT 10;
