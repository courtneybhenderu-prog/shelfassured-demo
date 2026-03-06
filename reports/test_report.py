"""Test the PDF report generator with sample data."""
import sys
sys.path.insert(0, '/home/ubuntu/shelfassured-demo/reports')
from generate_report import generate_report

sample_data = {
    "job_title": "DJ's Boudain — Kroger Pearland Shelf Audit",
    "brand_name": "DJ's Boudain",
    "store_banner": "Kroger",
    "store_name": "Kroger Pearland",
    "store_address": "2350 Smith Ranch Rd, Pearland, TX 77584",
    "sku_name": "Original Boudain",
    "sku_upc": "736526115552",
    "shelfer_first_name": "Courtney",
    "submitted_at": "2026-03-06T14:32:00Z",
    "photos": [
        {"url": "", "type": "product_closeup", "caption": "Product Close-Up"},
        {"url": "", "type": "section_context", "caption": "Shelf Section"},
        {"url": "", "type": "wide_angle",      "caption": "Wide-Angle Aisle View"},
    ],
    "price_verified": True,
    "price_found": "5.99",
    "price_expected": "5.99",
    "stock_level": "In Stock",
    "shelfer_notes": "Product was well-stocked and properly faced. Price tag was clearly visible. No competitor products were blocking the facing.",
    "report_id": "RPT-20260306-001",
}

personal_note = (
    "Hi Sarah — we noticed your Pearland location is well-stocked and properly priced. "
    "Great shelf presence this week! Reach out if you have any questions about this report."
)

output = '/home/ubuntu/shelfassured-demo/reports/sample_report.pdf'
generate_report(sample_data, output, personal_note)
print(f"Test complete. Output: {output}")
