#!/usr/bin/env python3
"""
Store Reconciliation Import Script
Reconciles stores from Excel file with existing Supabase stores table.

Source: Master Texas and WFM 12132025.xlsx
Tab: SCRUBBED TEXAS + WFM US

Rules:
- Match on: BANNER, normalized ADDRESS, CITY, STATE, ZIP5
- Preserve existing stores.id and STORE display values
- Generate new STORE names: {Banner} – {City} – {State} – {Street Fragment}
- Save Store # in store_number column
- Set is_active = false for stores not in spreadsheet
- Produce dry-run summary before executing
"""

import os
import sys
import re
import pandas as pd
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
from collections import defaultdict
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

@dataclass
class StoreRecord:
    """Represents a store record from the Excel file"""
    chain: str
    division: str
    banner: str
    store_location_name: str
    store: str
    store_number: str
    address: str
    city: str
    state: str
    zip: str
    metro: str
    phone: str
    
    def normalize_banner(self) -> str:
        """Normalize banner for matching (lowercase, trimmed)"""
        return (self.banner or '').strip().lower()
    
    def normalize_address(self) -> str:
        """Normalize address for matching"""
        if not self.address:
            return ''
        # Remove extra whitespace, lowercase, remove punctuation
        addr = re.sub(r'\s+', ' ', self.address.strip().lower())
        # Remove common suffixes that vary (St, Street, Rd, Road, etc.)
        addr = re.sub(r'\b(st|street|rd|road|ave|avenue|blvd|boulevard|dr|drive|ln|lane|ct|court|pl|place)\b', '', addr)
        # Remove suite/unit numbers
        addr = re.sub(r'\b(ste|suite|unit|#)\s*\d*\b', '', addr)
        # Remove punctuation
        addr = re.sub(r'[^\w\s]', '', addr)
        return addr.strip()
    
    def normalize_city(self) -> str:
        """Normalize city for matching"""
        return (self.city or '').strip().lower()
    
    def normalize_state(self) -> str:
        """Normalize state (uppercase, 2 chars)"""
        state = (self.state or '').strip().upper()
        # Extract first 2 characters if longer
        return state[:2] if len(state) >= 2 else state
    
    def extract_zip5(self) -> str:
        """Extract clean 5-digit ZIP code"""
        if not self.zip:
            return ''
        # Extract first 5 digits
        zip_match = re.search(r'\d{5}', str(self.zip))
        if zip_match:
            return zip_match.group(0).zfill(5)  # Zero pad if needed
        return ''
    
    def extract_street_fragment(self) -> str:
        """Extract street name fragment for display name"""
        if not self.address:
            return ''
        # Get first significant word (skip numbers, common words)
        words = self.address.strip().split()
        for word in words:
            # Skip pure numbers and common prefixes
            if word.isdigit() or word.upper() in ['N', 'S', 'E', 'W', 'NE', 'NW', 'SE', 'SW']:
                continue
            # Remove punctuation and return first significant word
            clean_word = re.sub(r'[^\w]', '', word)
            if clean_word and len(clean_word) > 1:
                return clean_word
        # Fallback: use first non-number word
        for word in words:
            if not word.isdigit():
                return re.sub(r'[^\w]', '', word)
        return 'Unknown'
    
    def generate_store_display_name(self) -> str:
        """Generate STORE display name: {Banner} – {City} – {State} – {Street Fragment}"""
        banner = (self.banner or 'Unknown').strip()
        city = (self.city or 'Unknown').strip()
        state = self.normalize_state()
        street = self.extract_street_fragment()
        
        return f"{banner} – {city} – {state} – {street}"

@dataclass
class MatchResult:
    """Result of matching a store record"""
    store_id: Optional[str]
    existing_store: Optional[Dict]
    action: str  # 'match', 'new', 'duplicate'
    conflicts: List[str]

class StoreReconciliationImporter:
    """Handles store reconciliation import"""
    
    def __init__(self, supabase_url: str, supabase_key: str):
        self.supabase: Client = create_client(supabase_url, supabase_key)
        self.existing_stores: Dict[str, Dict] = {}
        self.matches: List[MatchResult] = []
        self.stats = {
            'total_excel_rows': 0,
            'new_stores': 0,
            'matched_stores': 0,
            'duplicates': 0,
            'stores_to_deactivate': 0,
            'conflicts': []
        }
    
    def load_existing_stores(self):
        """Load all existing stores from Supabase (no filters, no limits, paginated)"""
        print("📥 Loading existing stores from Supabase...")
        
        all_stores = []
        page_size = 1000
        offset = 0
        
        # Paginate through all stores
        while True:
            response = self.supabase.table('stores').select('*', count='exact').range(offset, offset + page_size - 1).execute()
            
            if response.data:
                all_stores.extend(response.data)
                print(f"   Loaded {len(all_stores)} stores so far...", end='\r')
                
                # Check if we got all records
                if len(response.data) < page_size:
                    break
                
                offset += page_size
            else:
                break
        
        print()  # New line after progress
        
        if all_stores:
            for store in all_stores:
                # Create match key from normalized fields
                banner_norm = self._normalize_banner(store.get('banner') or store.get('STORE') or '')
                address_norm = self._normalize_address(store.get('address') or '')
                city_norm = self._normalize_city(store.get('city') or '')
                state_norm = self._normalize_state(store.get('state') or '')
                zip5 = self._extract_zip5(store.get('zip_code') or '')
                
                # Create composite key for matching
                match_key = f"{banner_norm}|{address_norm}|{city_norm}|{state_norm}|{zip5}"
                
                self.existing_stores[match_key] = store
            
            print(f"✅ Loaded {len(all_stores)} total stores from database")
            print(f"✅ Indexed {len(self.existing_stores)} stores for matching")
        else:
            print("⚠️  No existing stores found")
    
    def _normalize_banner(self, banner: str) -> str:
        """Normalize banner for matching"""
        return (banner or '').strip().lower()
    
    def _normalize_address(self, address: str) -> str:
        """Normalize address for matching"""
        if not address:
            return ''
        addr = re.sub(r'\s+', ' ', address.strip().lower())
        addr = re.sub(r'\b(st|street|rd|road|ave|avenue|blvd|boulevard|dr|drive|ln|lane|ct|court|pl|place)\b', '', addr)
        addr = re.sub(r'\b(ste|suite|unit|#)\s*\d*\b', '', addr)
        addr = re.sub(r'[^\w\s]', '', addr)
        return addr.strip()
    
    def _normalize_city(self, city: str) -> str:
        """Normalize city for matching"""
        return (city or '').strip().lower()
    
    def _normalize_state(self, state: str) -> str:
        """Normalize state"""
        state = (state or '').strip().upper()
        return state[:2] if len(state) >= 2 else state
    
    def _extract_zip5(self, zip_code: str) -> str:
        """Extract 5-digit ZIP"""
        if not zip_code:
            return ''
        zip_match = re.search(r'\d{5}', str(zip_code))
        return zip_match.group(0).zfill(5) if zip_match else ''
    
    def match_store(self, record: StoreRecord) -> MatchResult:
        """Match a store record against existing stores"""
        banner_norm = record.normalize_banner()
        address_norm = record.normalize_address()
        city_norm = record.normalize_city()
        state_norm = record.normalize_state()
        zip5 = record.extract_zip5()
        
        # Create match key
        match_key = f"{banner_norm}|{address_norm}|{city_norm}|{state_norm}|{zip5}"
        
        # Check for exact match
        if match_key in self.existing_stores:
            existing = self.existing_stores[match_key]
            return MatchResult(
                store_id=existing['id'],
                existing_store=existing,
                action='match',
                conflicts=[]
            )
        
        # No match found
        return MatchResult(
            store_id=None,
            existing_store=None,
            action='new',
            conflicts=[]
        )
    
    def load_excel_file(self, file_path: str, sheet_name: str) -> List[StoreRecord]:
        """Load store records from Excel file"""
        print(f"📖 Reading Excel file: {file_path}")
        print(f"   Tab: {sheet_name}")
        
        try:
            df = pd.read_excel(file_path, sheet_name=sheet_name)
            
            # Validate required columns
            required_cols = ['CHAIN', 'DIVISION', 'BANNER', 'STORE LOCATION NAME', 'STORE', 
                            'Store #', 'ADDRESS', 'CITY', 'STATE', 'ZIP', 'METRO', 'PHONE']
            missing_cols = [col for col in required_cols if col not in df.columns]
            if missing_cols:
                raise ValueError(f"Missing required columns: {missing_cols}")
            
            records = []
            for _, row in df.iterrows():
                # Skip empty rows
                if pd.isna(row.get('BANNER')) and pd.isna(row.get('ADDRESS')):
                    continue
                
                record = StoreRecord(
                    chain=str(row.get('CHAIN', '') or ''),
                    division=str(row.get('DIVISION', '') or ''),
                    banner=str(row.get('BANNER', '') or ''),
                    store_location_name=str(row.get('STORE LOCATION NAME', '') or ''),
                    store=str(row.get('STORE', '') or ''),
                    store_number=str(row.get('Store #', '') or ''),
                    address=str(row.get('ADDRESS', '') or ''),
                    city=str(row.get('CITY', '') or ''),
                    state=str(row.get('STATE', '') or ''),
                    zip=str(row.get('ZIP', '') or ''),
                    metro=str(row.get('METRO', '') or ''),
                    phone=str(row.get('PHONE', '') or '')
                )
                records.append(record)
            
            print(f"✅ Loaded {len(records)} store records from Excel")
            return records
            
        except Exception as e:
            print(f"❌ Error reading Excel file: {e}")
            raise
    
    def process_records(self, records: List[StoreRecord]) -> List[MatchResult]:
        """Process all records and match against existing stores"""
        print("\n🔍 Matching records against existing stores...")
        
        # DEBUG: Print first 20 Excel rows with their match keys
        print("\n" + "=" * 80)
        print("DEBUG: First 20 Excel Rows - Match Keys")
        print("=" * 80)
        for i, record in enumerate(records[:20]):
            banner_norm = record.normalize_banner()
            address_norm = record.normalize_address()
            city_norm = record.normalize_city()
            state_norm = record.normalize_state()
            zip5 = record.extract_zip5()
            match_key = f"{banner_norm}|{address_norm}|{city_norm}|{state_norm}|{zip5}"
            
            exists = match_key in self.existing_stores
            print(f"\nRow {i+1}:")
            print(f"  Banner (raw): '{record.banner}'")
            print(f"  Banner (norm): '{banner_norm}'")
            print(f"  Address (raw): '{record.address}'")
            print(f"  Address (norm): '{address_norm}'")
            print(f"  City (raw): '{record.city}'")
            print(f"  City (norm): '{city_norm}'")
            print(f"  State (raw): '{record.state}'")
            print(f"  State (norm): '{state_norm}'")
            print(f"  ZIP (raw): '{record.zip}'")
            print(f"  ZIP5: '{zip5}'")
            print(f"  Match Key: '{match_key}'")
            print(f"  Exists in index: {exists}")
            if exists:
                existing = self.existing_stores[match_key]
                print(f"  ✅ MATCH FOUND - Store ID: {existing.get('id')}")
        
        # DEBUG: Print 20 existing Supabase stores with their match keys
        print("\n" + "=" * 80)
        print("DEBUG: 20 Existing Supabase Stores - Match Keys")
        print("=" * 80)
        existing_list = list(self.existing_stores.values())[:20]
        for i, store in enumerate(existing_list):
            banner_norm = self._normalize_banner(store.get('banner') or store.get('STORE') or '')
            address_norm = self._normalize_address(store.get('address') or '')
            city_norm = self._normalize_city(store.get('city') or '')
            state_norm = self._normalize_state(store.get('state') or '')
            zip5 = self._extract_zip5(store.get('zip_code') or '')
            match_key = f"{banner_norm}|{address_norm}|{city_norm}|{state_norm}|{zip5}"
            
            print(f"\nStore {i+1} (ID: {store.get('id')}):")
            print(f"  Banner (raw): '{store.get('banner') or store.get('STORE') or 'N/A'}'")
            print(f"  Banner (norm): '{banner_norm}'")
            print(f"  Address (raw): '{store.get('address') or 'N/A'}'")
            print(f"  Address (norm): '{address_norm}'")
            print(f"  City (raw): '{store.get('city') or 'N/A'}'")
            print(f"  City (norm): '{city_norm}'")
            print(f"  State (raw): '{store.get('state') or 'N/A'}'")
            print(f"  State (norm): '{state_norm}'")
            print(f"  ZIP (raw): '{store.get('zip_code') or 'N/A'}'")
            print(f"  ZIP5: '{zip5}'")
            print(f"  Match Key: '{match_key}'")
            print(f"  STORE field: '{store.get('STORE') or 'N/A'}'")
            print(f"  name field: '{store.get('name') or 'N/A'}'")
        
        print("\n" + "=" * 80)
        
        # Handle duplicates: group by match key, keep row with most complete data
        record_groups = defaultdict(list)
        for i, record in enumerate(records):
            match_key = f"{record.normalize_banner()}|{record.normalize_address()}|{record.normalize_city()}|{record.normalize_state()}|{record.extract_zip5()}"
            record_groups[match_key].append((i, record))
        
        # Process each group (handle duplicates)
        results = []
        for match_key, group in record_groups.items():
            if len(group) > 1:
                # Duplicate found - keep row with store number
                group.sort(key=lambda x: 1 if x[1].store_number else 0, reverse=True)
                record = group[0][1]
                self.stats['duplicates'] += len(group) - 1
            else:
                record = group[0][1]
            
            match_result = self.match_store(record)
            results.append(match_result)
            
            if match_result.action == 'match':
                self.stats['matched_stores'] += 1
            elif match_result.action == 'new':
                self.stats['new_stores'] += 1
        
        self.stats['total_excel_rows'] = len(records)
        self.matches = results
        
        print(f"\n✅ Matching complete:")
        print(f"   - Matched: {self.stats['matched_stores']}")
        print(f"   - New: {self.stats['new_stores']}")
        print(f"   - Duplicates removed: {self.stats['duplicates']}")
        
        return results
    
    def identify_stores_to_deactivate(self, matched_store_ids: set):
        """Identify stores that should be deactivated (not in Excel)"""
        print("\n🔍 Identifying stores to deactivate...")
        
        all_existing_ids = {store['id'] for store in self.existing_stores.values()}
        stores_to_deactivate = all_existing_ids - matched_store_ids
        
        self.stats['stores_to_deactivate'] = len(stores_to_deactivate)
        print(f"✅ Found {len(stores_to_deactivate)} stores to deactivate")
        
        return stores_to_deactivate
    
    def generate_dry_run_summary(self, records: List[StoreRecord], results: List[MatchResult]) -> str:
        """Generate dry-run summary report"""
        matched_ids = {r.store_id for r in results if r.store_id}
        stores_to_deactivate = self.identify_stores_to_deactivate(matched_ids)
        
        summary = []
        summary.append("=" * 80)
        summary.append("STORE RECONCILIATION - DRY RUN SUMMARY")
        summary.append("=" * 80)
        summary.append("")
        
        # Statistics
        summary.append("📊 STATISTICS")
        summary.append(f"   Total rows in Excel: {self.stats['total_excel_rows']}")
        summary.append(f"   New stores to insert: {self.stats['new_stores']}")
        summary.append(f"   Existing stores matched: {self.stats['matched_stores']}")
        summary.append(f"   Duplicate rows removed: {self.stats['duplicates']}")
        summary.append(f"   Stores to deactivate: {self.stats['stores_to_deactivate']}")
        summary.append("")
        
        # Sample new stores
        if self.stats['new_stores'] > 0:
            summary.append("🆕 SAMPLE NEW STORES (first 10):")
            new_count = 0
            for record, result in zip(records, results):
                if result.action == 'new' and new_count < 10:
                    display_name = record.generate_store_display_name()
                    summary.append(f"   {new_count + 1}. {display_name}")
                    summary.append(f"      Banner: {record.banner}")
                    summary.append(f"      Address: {record.address}, {record.city}, {record.state} {record.zip}")
                    summary.append(f"      Store #: {record.store_number or 'N/A'}")
                    summary.append("")
                    new_count += 1
            if self.stats['new_stores'] > 10:
                summary.append(f"   ... and {self.stats['new_stores'] - 10} more")
            summary.append("")
        
        # Sample stores to deactivate
        if stores_to_deactivate:
            summary.append("⚠️  SAMPLE STORES TO DEACTIVATE (first 10):")
            deactivate_count = 0
            for store in self.existing_stores.values():
                if store['id'] in stores_to_deactivate and deactivate_count < 10:
                    store_name = store.get('STORE') or store.get('name') or 'Unknown'
                    summary.append(f"   {deactivate_count + 1}. {store_name}")
                    summary.append(f"      ID: {store['id']}")
                    summary.append(f"      Address: {store.get('address', 'N/A')}, {store.get('city', 'N/A')}, {store.get('state', 'N/A')}")
                    summary.append("")
                    deactivate_count += 1
            if len(stores_to_deactivate) > 10:
                summary.append(f"   ... and {len(stores_to_deactivate) - 10} more")
            summary.append("")
        
        # Conflicts
        if self.stats['conflicts']:
            summary.append("⚠️  CONFLICTS FOUND:")
            for conflict in self.stats['conflicts'][:10]:
                summary.append(f"   - {conflict}")
            if len(self.stats['conflicts']) > 10:
                summary.append(f"   ... and {len(self.stats['conflicts']) - 10} more")
            summary.append("")
        
        summary.append("=" * 80)
        summary.append("⚠️  This is a DRY RUN - no changes have been made to the database")
        summary.append("=" * 80)
        
        return "\n".join(summary)
    
    def ensure_store_number_column(self):
        """Ensure store_number column exists in stores table"""
        print("\n🔍 Checking for store_number column...")
        
        # Check if column exists by trying to select it
        try:
            response = self.supabase.table('stores').select('store_number').limit(1).execute()
            print("✅ store_number column exists")
            return True
        except Exception as e:
            if 'column' in str(e).lower() and 'does not exist' in str(e).lower():
                print("⚠️  store_number column does not exist - will need to be added")
                print("   Run this SQL in Supabase:")
                print("   ALTER TABLE stores ADD COLUMN IF NOT EXISTS store_number VARCHAR(50);")
                print("   CREATE INDEX IF NOT EXISTS idx_stores_store_number ON stores(store_number);")
                return False
            else:
                # Column might exist but no data, or other error
                print("✅ store_number column exists (or will be created)")
                return True
    
    def execute_import(self, records: List[StoreRecord], results: List[MatchResult], confirm: bool = False):
        """Execute the import (only if confirmed)"""
        if not confirm:
            print("\n❌ Import not confirmed - skipping execution")
            return
        
        print("\n🚀 Executing import...")
        
        # Ensure store_number column exists
        self.ensure_store_number_column()
        
        # 1. Insert new stores
        new_stores = []
        for record, result in zip(records, results):
            if result.action == 'new':
                display_name = record.generate_store_display_name()
                zip5 = record.extract_zip5()
                
                new_store = {
                    'STORE': display_name,
                    'name': display_name,  # Also set name for compatibility
                    'banner': record.banner,
                    'store_chain': record.chain,  # Legacy field
                    'address': record.address,
                    'city': record.city,
                    'state': record.normalize_state(),
                    'zip_code': record.zip,
                    'zip5': zip5,
                    'metro': record.metro if record.metro else None,
                    'phone': record.phone if record.phone else None,
                    'store_number': record.store_number if record.store_number else None,
                    'is_active': True
                    # created_at and updated_at will use database defaults
                }
                new_stores.append(new_store)
        
        if new_stores:
            print(f"   Inserting {len(new_stores)} new stores...")
            try:
                response = self.supabase.table('stores').insert(new_stores).execute()
                print(f"   ✅ Inserted {len(response.data)} new stores")
            except Exception as e:
                print(f"   ❌ Error inserting new stores: {e}")
                raise
        
        # 2. Update existing stores (preserve STORE, update other fields)
        matched_stores = []
        for record, result in zip(records, results):
            if result.action == 'match' and result.store_id:
                # Update fields but preserve existing STORE value
                existing = result.existing_store
                update_data = {
                    'banner': record.banner,
                    'store_chain': record.chain,
                    'address': record.address,
                    'city': record.city,
                    'state': record.normalize_state(),
                    'zip_code': record.zip,
                    'zip5': record.extract_zip5(),
                    'metro': record.metro if record.metro else existing.get('metro'),
                    'phone': record.phone if record.phone else existing.get('phone'),
                    'store_number': record.store_number if record.store_number else existing.get('store_number'),
                    'is_active': True
                    # updated_at will use database default/trigger
                }
                # Preserve existing STORE value
                if 'STORE' in existing:
                    update_data['STORE'] = existing['STORE']
                elif 'name' in existing:
                    update_data['STORE'] = existing['name']
                
                matched_stores.append((result.store_id, update_data))
        
        if matched_stores:
            print(f"   Updating {len(matched_stores)} existing stores...")
            for store_id, update_data in matched_stores:
                try:
                    self.supabase.table('stores').update(update_data).eq('id', store_id).execute()
                except Exception as e:
                    print(f"   ⚠️  Error updating store {store_id}: {e}")
            print(f"   ✅ Updated {len(matched_stores)} stores")
        
        # 3. Deactivate stores not in Excel
        matched_ids = {r.store_id for r in results if r.store_id}
        all_existing_ids = {store['id'] for store in self.existing_stores.values()}
        stores_to_deactivate = all_existing_ids - matched_ids
        
        if stores_to_deactivate:
            print(f"   Deactivating {len(stores_to_deactivate)} stores...")
            try:
                self.supabase.table('stores').update({'is_active': False}).in_('id', list(stores_to_deactivate)).execute()
                print(f"   ✅ Deactivated {len(stores_to_deactivate)} stores")
            except Exception as e:
                print(f"   ❌ Error deactivating stores: {e}")
                raise
        
        print("\n✅ Import complete!")

def main():
    """Main function"""
    print("=" * 80)
    print("STORE RECONCILIATION IMPORT")
    print("=" * 80)
    print()
    
    # Configuration
    excel_file = "Master Texas and WFM 12132025.xlsx"
    sheet_name = "SCRUBBED TEXAS + WFM US"
    
    # Get Supabase credentials
    supabase_url = os.getenv('SUPABASE_URL')
    supabase_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY') or os.getenv('SUPABASE_ANON_KEY')
    
    if not supabase_url or not supabase_key:
        print("❌ Error: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY (or SUPABASE_ANON_KEY) must be set")
        print("   Create a .env file with:")
        print("   SUPABASE_URL=https://your-project.supabase.co")
        print("   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key")
        sys.exit(1)
    
    # Check if Excel file exists
    if not os.path.exists(excel_file):
        print(f"❌ Error: Excel file not found: {excel_file}")
        print(f"   Please ensure the file is in the current directory")
        sys.exit(1)
    
    # Initialize importer
    importer = StoreReconciliationImporter(supabase_url, supabase_key)
    
    # Load existing stores
    importer.load_existing_stores()
    
    # Load Excel file
    records = importer.load_excel_file(excel_file, sheet_name)
    
    # Process records
    results = importer.process_records(records)
    
    # Generate dry-run summary
    summary = importer.generate_dry_run_summary(records, results)
    print("\n" + summary)
    
    # Save summary to file
    with open('store-reconciliation-dry-run-summary.txt', 'w') as f:
        f.write(summary)
    print("\n💾 Dry-run summary saved to: store-reconciliation-dry-run-summary.txt")
    
    # Ask for confirmation
    print("\n" + "=" * 80)
    response = input("Do you want to execute the import? (yes/no): ").strip().lower()
    
    if response == 'yes':
        importer.execute_import(records, results, confirm=True)
    else:
        print("\n❌ Import cancelled by user")
        print("   Review the dry-run summary and run again when ready")

if __name__ == "__main__":
    main()

