#!/usr/bin/env python3
"""
Texas Stores Data Importer
This script helps import the complete Texas stores dataset from Google Sheets
"""

import csv
import json
import requests
from typing import List, Dict

def download_google_sheet_as_csv(sheet_id: str, gid: str = "0") -> str:
    """
    Download a Google Sheet as CSV
    """
    url = f"https://docs.google.com/spreadsheets/d/{sheet_id}/export?format=csv&gid={gid}"
    
    try:
        response = requests.get(url)
        response.raise_for_status()
        return response.text
    except requests.RequestException as e:
        print(f"Error downloading sheet: {e}")
        return ""

def parse_csv_to_sql(csv_content: str) -> str:
    """
    Convert CSV content to SQL INSERT statements
    """
    lines = csv_content.strip().split('\n')
    if len(lines) < 2:
        return "-- No data found"
    
    # Skip header row
    data_lines = lines[1:]
    
    sql_statements = []
    sql_statements.append("-- Texas Stores Import (Generated from Google Sheets)")
    sql_statements.append("-- Data source: https://docs.google.com/spreadsheets/d/18E6OfiZ4ikihL8jL98SdKlbyruBHkZPbZJ9QJ7VPCfU/edit?usp=sharing")
    sql_statements.append("")
    sql_statements.append("-- Create temporary table for import")
    sql_statements.append("CREATE TEMP TABLE temp_texas_stores (")
    sql_statements.append("    chain VARCHAR(100),")
    sql_statements.append("    division VARCHAR(100),")
    sql_statements.append("    banner VARCHAR(100),")
    sql_statements.append("    store_name VARCHAR(200),")
    sql_statements.append("    store_number VARCHAR(50),")
    sql_statements.append("    address VARCHAR(500),")
    sql_statements.append("    city VARCHAR(100),")
    sql_statements.append("    state VARCHAR(10),")
    sql_statements.append("    zip VARCHAR(20),")
    sql_statements.append("    metro VARCHAR(200),")
    sql_statements.append("    country VARCHAR(10),")
    sql_statements.append("    phone VARCHAR(20),")
    sql_statements.append("    state_norm VARCHAR(10)")
    sql_statements.append(");")
    sql_statements.append("")
    
    # Add INSERT statements
    sql_statements.append("-- Insert all Texas stores")
    sql_statements.append("INSERT INTO temp_texas_stores VALUES")
    
    for i, line in enumerate(data_lines):
        if not line.strip():
            continue
            
        # Parse CSV line (handle commas in values)
        reader = csv.reader([line])
        row = next(reader)
        
        # Ensure we have enough columns
        while len(row) < 13:
            row.append('')
        
        # Escape single quotes in values
        escaped_row = []
        for value in row:
            if value is None:
                escaped_row.append('')
            else:
                escaped_row.append(str(value).replace("'", "''"))
        
        # Create VALUES clause
        values_clause = f"('{escaped_row[0]}', '{escaped_row[1]}', '{escaped_row[2]}', '{escaped_row[3]}', '{escaped_row[4]}', '{escaped_row[5]}', '{escaped_row[6]}', '{escaped_row[7]}', '{escaped_row[8]}', '{escaped_row[9]}', '{escaped_row[10]}', '{escaped_row[11]}', '{escaped_row[12]}')"
        
        if i < len(data_lines) - 1:
            values_clause += ","
        else:
            values_clause += ";"
        
        sql_statements.append(values_clause)
    
    sql_statements.append("")
    sql_statements.append("-- Insert into stores table")
    sql_statements.append("INSERT INTO stores (")
    sql_statements.append("    name,")
    sql_statements.append("    address,")
    sql_statements.append("    city,")
    sql_statements.append("    state,")
    sql_statements.append("    zip_code,")
    sql_statements.append("    phone,")
    sql_statements.append("    is_active,")
    sql_statements.append("    created_at,")
    sql_statements.append("    updated_at")
    sql_statements.append(")")
    sql_statements.append("SELECT ")
    sql_statements.append("    CASE ")
    sql_statements.append("        WHEN store_name IS NOT NULL AND store_name != '' THEN store_name")
    sql_statements.append("        WHEN banner IS NOT NULL AND banner != '' THEN banner")
    sql_statements.append("        ELSE 'Unknown Store'")
    sql_statements.append("    END as name,")
    sql_statements.append("    address,")
    sql_statements.append("    city,")
    sql_statements.append("    state,")
    sql_statements.append("    zip,")
    sql_statements.append("    phone,")
    sql_statements.append("    true as is_active,")
    sql_statements.append("    NOW() as created_at,")
    sql_statements.append("    NOW() as updated_at")
    sql_statements.append("FROM temp_texas_stores")
    sql_statements.append("WHERE state = 'TX'")
    sql_statements.append("ON CONFLICT (name, address) DO UPDATE SET")
    sql_statements.append("    phone = EXCLUDED.phone,")
    sql_statements.append("    updated_at = NOW();")
    sql_statements.append("")
    sql_statements.append("-- Clean up")
    sql_statements.append("DROP TABLE temp_texas_stores;")
    
    return '\n'.join(sql_statements)

def main():
    """
    Main function to download and convert the Texas stores data
    """
    print("🏪 Texas Stores Data Importer")
    print("=" * 50)
    
    # Google Sheet ID from your URL
    sheet_id = "18E6OfiZ4ikihL8jL98SdKlbyruBHkZPbZJ9QJ7VPCfU"
    
    print(f"📥 Downloading data from Google Sheet...")
    csv_content = download_google_sheet_as_csv(sheet_id)
    
    if not csv_content:
        print("❌ Failed to download data")
        return
    
    print(f"✅ Downloaded {len(csv_content.split())} lines of data")
    
    print("🔄 Converting to SQL...")
    sql_content = parse_csv_to_sql(csv_content)
    
    # Save to file
    output_file = "texas-stores-complete-import.sql"
    with open(output_file, 'w') as f:
        f.write(sql_content)
    
    print(f"✅ SQL file created: {output_file}")
    print(f"📊 Ready to import into Supabase!")
    print("")
    print("Next steps:")
    print("1. Open Supabase SQL Editor")
    print("2. Copy and paste the contents of texas-stores-complete-import.sql")
    print("3. Run the script")
    print("4. Verify the import with: SELECT COUNT(*) FROM stores WHERE state = 'TX';")

if __name__ == "__main__":
    main()
