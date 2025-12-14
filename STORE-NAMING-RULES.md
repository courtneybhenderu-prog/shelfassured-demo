# STORE Naming and Disambiguator Rules

## Overview
This document defines the rules and logic for generating `STORE` display names in the `stores` table. These rules are **locked** and should not be modified unless explicitly revisited in the future.

**Last Updated:** December 2025  
**Status:** ✅ Locked - No further refinements without explicit approval

---

## STORE Naming Format

### Standard Format
```
{Banner} – {City} – {State} – {Disambiguator}
```

### Components

1. **Banner** (Required)
   - Source: `banner` or `BANNER` column
   - Fallback: `'Unknown'` if both are empty/null
   - Examples: `HEB`, `WHOLE FOODS MARKET`, `TARGET`

2. **City** (Required)
   - Source: `city` or `CITY` column
   - Fallback: `'Unknown'` if both are empty/null
   - Examples: `AUSTIN`, `HOUSTON`, `DALLAS`

3. **State** (Required)
   - Source: `state` or `STATE` column
   - Normalized to 2-letter uppercase code
   - Fallback: `'Unknown'` if both are empty/null
   - Examples: `TX`, `CA`, `NY`

4. **Disambiguator** (Conditional)
   - Only added when multiple stores share the same `Banner – City – State` combination
   - Extracted from the store's address
   - Format: 2-3 meaningful tokens from the street name
   - Examples: `N JOSEY LN`, `S CONGRESS AVE`, `W SLAUGHTER LN`, `FM 1488`

### Examples

```
HEB – AUSTIN – TX – S CONGRESS AVE
WHOLE FOODS MARKET – AUSTIN – TX – BOLM
TARGET – HOUSTON – TX – WESTHEIMER RD
ALBERTSONS – CARROLLTON – TX – N JOSEY LN
```

---

## Disambiguator Rules

### When Disambiguator is Added
- **Condition:** Only when there are multiple stores with the same `Banner – City – State` combination
- **Purpose:** Distinguish between different physical locations of the same brand in the same city

### Disambiguator Extraction Logic

1. **Address Cleaning:**
   - Remove leading street numbers (e.g., `598` from `598 E US-290`)
   - Remove unit/suite/building identifiers (e.g., `STE 101`, `UNIT 5`, `BLDG A`)
   - Remove street suffixes (e.g., `ST`, `RD`, `AVE`, `BLVD`, `LN`, `DR`, `CT`, `PL`, `PKWY`, `HWY`)
   - Collapse multiple spaces to single space
   - Convert to lowercase for processing

2. **Token Extraction:**
   - Split cleaned address into tokens (words)
   - Extract first 2-3 meaningful tokens
   - Special handling for:
     - **Single-letter directions:** `N`, `S`, `E`, `W` → Include next 1-2 tokens
       - Example: `N JO` → `N JOSEY` (extended to full word)
     - **Highway patterns:** `HWY` or `HIGHWAY` → Include number/name
       - Example: `HWY` → `HWY 6`
     - **Full word prefixes:** `NORTH`, `SOUTH`, `SAN`, `SAINT` → Include next 1-2 tokens
       - Example: `SAN` → `SAN PEDRO`

3. **Final Formatting:**
   - Convert to UPPERCASE
   - Join tokens with single space
   - Maximum length: 2-3 tokens

### Examples of Disambiguator Refinement

| Before (Truncated) | After (Refined) | Address Source |
|-------------------|-----------------|----------------|
| `N JO` | `N JOSEY LN` | `2150 N JOSEY LN` |
| `S CO` | `S CONGRESS AVE` | `2400 S CONGRESS AVE` |
| `W SL` | `W SLAUGHTER LN` | `5800 W SLAUGHTER LN` |
| `HWY` | `HWY 6` | `HWY 6` |
| `N LA` | `N LAMAR` | `N LAMAR BLVD` |
| `N HA` | `N HALSTED` | `N HALSTED ST` |
| `N FR` | `N FRY` | `N FRY RD` |

### Preservation Rule

**CRITICAL:** Once a `STORE` value is set (non-null, non-empty, non-whitespace, non-placeholder), it will **NEVER** be automatically modified by any script or process.

**Placeholder Treatment:**
- `STORE = 'Unknown – Unknown – Unknown'` is treated as empty and will be regenerated
- After regeneration, the preservation rule applies strictly

---

## Why Legitimate Duplicates May Remain

### Definition of Legitimate Duplicates
Legitimate duplicates are stores that share the same `STORE` name but represent **different physical locations**. These are **not data quality issues** but actual business scenarios.

### Common Scenarios

1. **Multiple Stores on the Same Street**
   - Example: `ALBERTSONS – CARROLLTON – TX – N JOSEY LN`
     - Store 1: `2150 N JOSEY LN`
     - Store 2: `2149 N JOSEY LN`
   - These are two different stores on the same road, requiring additional context (full address or store number) to distinguish

2. **Different Store Numbers, Same Location Name**
   - Example: `TARGET – HOUSTON – TX – WESTHEIMER RD`
     - Store 1: `8605 WESTHEIMER RD`
     - Store 2: `2075 WESTHEIMER RD`
   - Different store numbers indicate separate locations, but the disambiguator (street name) is the same

3. **Same Street, Different Intersections**
   - Example: `HEB – AUSTIN – TX – S CONGRESS AVE`
     - Store 1: `2400 S CONGRESS AVE`
     - Store 2: `8801 S CONGRESS`
   - Both on the same major street but at different intersections

### Why We Don't Further Refine These

1. **Store Numbers:** Not always available or reliable
2. **ZIP Codes:** Too granular and may not be meaningful to users
3. **Full Addresses:** Too long for display names
4. **User Context:** The full address is available in the store record for disambiguation when needed

### Acceptable State
- Remaining duplicates are **expected and acceptable**
- They represent real-world scenarios where multiple stores exist on the same street
- The disambiguator provides sufficient context for most use cases
- Full addresses are available in the database for precise identification

---

## Final Duplicate Count (December 2025)

**Status:** After true duplicate merge and disambiguator refinement

> **Note:** Run `get-final-duplicate-count.sql` to get exact current numbers.

**As of December 2025:**
- **Total Active Stores:** 2,593 (after merging 2 true duplicates from 2,595)
- **Unique STORE Names:** ~2,538 (approximate)
- **Remaining Duplicate Groups:** ~54 groups (approximate)
- **Stores in Duplicate Groups:** ~57 stores (approximate)

**Breakdown:**
- **True Duplicates Merged:** 2 stores inactivated (same physical location)
  - `HEB – DRIPPING SPRINGS – TX – E US` (598 E US-290)
  - `WHOLE FOODS MARKET – AUSTIN – TX – BOLM` (6201 BOLM RD STE 101)
- **Legitimate Duplicates Remaining:** ~54 groups (different physical locations sharing same street name)

**Uniqueness Rate:** ~97.9% of stores have unique `STORE` names

**To Update This Section:**
Run `get-final-duplicate-count.sql` and update the numbers above with the exact values.

---

## Data Quality Rules

### Matching Logic (for True Duplicates)
True duplicates are identified using a normalized match key:
```
LOWER(banner) | LOWER(city) | UPPER(state) | normalized_address
```

Where `normalized_address`:
- Strips suite/unit/building numbers
- Removes punctuation
- Converts to lowercase
- Collapses spaces

### Survivor Selection (for Merges)
When true duplicates are found, the survivor is selected based on:
1. **Completeness Score** (highest wins):
   - Store number present: +1
   - Phone present: +1
   - ZIP code present: +1
   - Metro present: +1
2. **ID** (if scores tie, lowest ID wins)

---

## Maintenance Guidelines

### Do NOT Modify
- ❌ STORE naming format
- ❌ Disambiguator extraction logic
- ❌ Preservation rule
- ❌ Matching logic for true duplicates

### Allowed Modifications (with approval)
- ✅ Adding new stores (will auto-generate STORE names)
- ✅ Updating store data (address, banner, city, state)
- ✅ Manual corrections for specific edge cases (with documentation)

### Future Refinements
Any future changes to STORE naming or disambiguator logic must:
1. Be explicitly requested and approved
2. Include a clear business justification
3. Be tested on a subset before full deployment
4. Update this documentation

---

## Technical Implementation Notes

### Generated STORE Names
- Generated automatically when `STORE` is NULL, empty, or placeholder
- Uses `UPDATE` statement with conditional logic
- Only runs for stores missing STORE values

### Disambiguator Refinement
- Only applies to stores in duplicate groups
- Uses token-based extraction from cleaned addresses
- Preserves base name (Banner – City – State)
- Updates only the disambiguator portion

### True Duplicate Merging
- Identifies duplicates using normalized match keys
- Marks non-survivor stores as `is_active = FALSE`
- Preserves all data (no deletion)
- Uses transaction for safety

---

## References

- **Initial Population:** `restore-and-populate-store-column.sql`
- **True Duplicate Detection:** `identify-true-duplicate-stores.sql`
- **True Duplicate Merge:** `merge-true-duplicate-stores-execute.sql`
- **Disambiguator Refinement:** `refine-disambiguator-remaining-duplicates.sql`
- **Final Report:** `final-duplicate-report.sql`

---

**Document Status:** ✅ Final - Locked for future reference

