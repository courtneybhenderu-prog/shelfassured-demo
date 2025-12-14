# Store Reconciliation - Intent Confirmed

## Core Principles (Locked)

### 1. Existing Stores
- ✅ **Preserve `stores.id` exactly** - Never change existing IDs
- ✅ **Preserve `stores.STORE` values exactly** - Never rename or normalize legacy display names
- ✅ **Update other fields only** - banner, address, city, state, zip, phone, store_number, etc.
- ✅ **Optional fields acceptable** - Missing phone/store_number don't block matching

### 2. New Stores
- ✅ **Ignore spreadsheet STORE column** - Don't use Excel STORE values
- ✅ **Generate display names** - Use rule: `{Banner} – {City} – {State} – {Disambiguator}`
- ✅ **Disambiguator** - First significant word from address (skips numbers, directions)

### 3. Matching Strategy
- ✅ **Conservative matching only** - Exact matches on normalized fields
- ✅ **Avoid false positives** - Better to have low match count than wrong matches
- ✅ **Preserve data continuity** - Don't risk breaking existing relationships

### 4. Out of Scope
- ✅ **CBSA/Metro enrichment** - Out of scope for this step
- ✅ **Does not block reconciliation** - Can be added later after stores are stable

## Matching Criteria

**Exact match required on:**
- `banner_norm` (normalized banner name)
- `address_norm` (normalized address, suite/unit/building removed)
- `city_norm` (normalized city)
- `state_norm` (2-letter uppercase)
- `zip5` (5-digit ZIP code)

**Match key format:**
```
banner_norm|address_norm|city_norm|state_norm|zip5
```

## Execution Behavior

### For Matched Stores (Existing)
- Keep existing `id` (no change)
- Keep existing `STORE` (no change)
- Update: banner, address, city, state, zip, phone, store_number, metro
- Update: normalization fields (banner_norm, address_norm, etc.) for future matching
- Set: `is_active = TRUE`

### For New Stores (Not Matched)
- Generate new `id` (UUID)
- Generate `STORE` using: `{Banner} – {City} – {State} – {Disambiguator}`
- Set: `is_active = TRUE`
- Include: All fields from Excel (banner, address, city, state, zip, etc.)
- Optional fields: phone, store_number, metro can be NULL

### For Missing Stores (In DB but not in Excel)
- Keep existing `id` (no change)
- Keep existing `STORE` (no change)
- Set: `is_active = FALSE`
- No other changes

## Files Updated

- ✅ `store-reconciliation-execute.sql` - Confirmed STORE preservation, removed CBSA lookup
- ✅ `find-why-no-matches.sql` - Updated comments for conservative matching intent
- ✅ `RECONCILIATION-INTENT-CONFIRMED.md` - This document

