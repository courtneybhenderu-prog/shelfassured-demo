"""
ShelfAssured Job Report Generator
Generates a branded PDF report for a completed shelf audit job.

Usage:
    python3 generate_report.py '<json_data>' output.pdf

Or import and call generate_report(data_dict, output_path)
"""

import sys
import json
import os
import io
import requests
from datetime import datetime
from reportlab.lib.pagesizes import letter
from reportlab.lib.units import inch
from reportlab.lib.colors import HexColor, white, black
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    Image, HRFlowable, KeepTogether
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT
from reportlab.platypus import Flowable

# ── Brand Colors ──────────────────────────────────────────────────────────────
RED        = HexColor('#C62828')
CHROME     = HexColor('#B0BEC5')   # silver/chrome accent
DARK_CHROME= HexColor('#78909C')
LIGHT_GRAY = HexColor('#F5F5F5')
MID_GRAY   = HexColor('#9E9E9E')
DARK_GRAY  = HexColor('#424242')
TEXT_BLACK = HexColor('#1A1A1A')
GREEN      = HexColor('#2E7D32')
AMBER      = HexColor('#E65100')


class ChromeRule(Flowable):
    """A decorative chrome/silver horizontal rule with a red left accent."""
    def __init__(self, width, height=4):
        Flowable.__init__(self)
        self.width  = width
        self.height = height

    def draw(self):
        # Red left accent block
        self.canv.setFillColor(RED)
        self.canv.rect(0, 0, 24, self.height, fill=1, stroke=0)
        # Chrome rule for the rest
        self.canv.setFillColor(CHROME)
        self.canv.rect(24, 0, self.width - 24, self.height, fill=1, stroke=0)


def fetch_image(url, max_w=2.8*inch, max_h=2.4*inch):
    """Download an image URL and return a ReportLab Image flowable, or None."""
    if not url:
        return None
    try:
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        img_data = io.BytesIO(resp.content)
        img = Image(img_data)
        # Scale proportionally to fit within max dimensions
        ratio = min(max_w / img.drawWidth, max_h / img.drawHeight)
        img.drawWidth  *= ratio
        img.drawHeight *= ratio
        return img
    except Exception as e:
        print(f"  Warning: could not fetch image {url}: {e}", file=sys.stderr)
        return None


def make_styles():
    styles = getSampleStyleSheet()

    styles.add(ParagraphStyle(
        'BrandName',
        fontName='Helvetica-Bold',
        fontSize=22,
        textColor=RED,
        spaceAfter=0,
    ))
    styles.add(ParagraphStyle(
        'Tagline',
        fontName='Helvetica',
        fontSize=9,
        textColor=DARK_CHROME,
        spaceAfter=0,
    ))
    styles.add(ParagraphStyle(
        'ReportTitle',
        fontName='Helvetica-Bold',
        fontSize=16,
        textColor=TEXT_BLACK,
        spaceBefore=10,
        spaceAfter=4,
    ))
    styles.add(ParagraphStyle(
        'SectionHeader',
        fontName='Helvetica-Bold',
        fontSize=11,
        textColor=TEXT_BLACK,
        spaceBefore=14,
        spaceAfter=6,
        textTransform='uppercase',
        letterSpacing=1,
    ))
    styles.add(ParagraphStyle(
        'FieldLabel',
        fontName='Helvetica-Bold',
        fontSize=9,
        textColor=DARK_CHROME,
        spaceAfter=1,
    ))
    styles.add(ParagraphStyle(
        'FieldValue',
        fontName='Helvetica',
        fontSize=10,
        textColor=TEXT_BLACK,
        spaceAfter=6,
    ))
    styles.add(ParagraphStyle(
        'PhotoCaption',
        fontName='Helvetica-Oblique',
        fontSize=8,
        textColor=MID_GRAY,
        alignment=TA_CENTER,
        spaceAfter=4,
    ))
    styles.add(ParagraphStyle(
        'StatusGood',
        fontName='Helvetica-Bold',
        fontSize=10,
        textColor=GREEN,
    ))
    styles.add(ParagraphStyle(
        'StatusWarn',
        fontName='Helvetica-Bold',
        fontSize=10,
        textColor=AMBER,
    ))
    styles.add(ParagraphStyle(
        'FooterText',
        fontName='Helvetica',
        fontSize=7,
        textColor=MID_GRAY,
        alignment=TA_CENTER,
    ))
    styles.add(ParagraphStyle(
        'PersonalNote',
        fontName='Helvetica-Oblique',
        fontSize=10,
        textColor=DARK_GRAY,
        spaceBefore=4,
        spaceAfter=4,
        leftIndent=12,
        rightIndent=12,
    ))
    return styles


def field_row(label, value, styles):
    """Return a two-item list [label_para, value_para] for a detail row."""
    return [
        Paragraph(label, styles['FieldLabel']),
        Paragraph(str(value) if value else 'N/A', styles['FieldValue']),
    ]


def generate_report(data: dict, output_path: str, personal_note: str = None):
    """
    Generate a ShelfAssured PDF report.

    data keys expected:
        job_title, brand_name, brand_logo_url (optional),
        store_banner, store_name, store_address,
        sku_name, sku_upc,
        shelfer_first_name,
        submitted_at,
        photos: list of {url, caption}
        price_verified (bool or None), price_found (str), price_expected (str),
        stock_level (str),
        shelfer_notes (str),
        report_id (str)
    """
    s = make_styles()
    doc = SimpleDocTemplate(
        output_path,
        pagesize=letter,
        leftMargin=0.75*inch,
        rightMargin=0.75*inch,
        topMargin=0.6*inch,
        bottomMargin=0.75*inch,
        title=f"ShelfAssured Report — {data.get('job_title', 'Shelf Audit')}",
        author='ShelfAssured',
    )

    page_w = letter[0] - 1.5*inch  # usable width
    story  = []

    # ── Header ────────────────────────────────────────────────────────────────
    header_data = [[
        Paragraph('<font color="#C62828"><b>ShelfAssured</b></font>', ParagraphStyle(
            'H', fontName='Helvetica-Bold', fontSize=24, textColor=RED)),
        Paragraph(
            f'<font color="#78909C">Shelf Audit Report</font><br/>'
            f'<font color="#9E9E9E" size="8">Generated {datetime.now().strftime("%B %d, %Y")}</font>',
            ParagraphStyle('HR', fontName='Helvetica', fontSize=11, alignment=TA_RIGHT)
        )
    ]]
    header_tbl = Table(header_data, colWidths=[page_w * 0.55, page_w * 0.45])
    header_tbl.setStyle(TableStyle([
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 0),
    ]))
    story.append(header_tbl)
    story.append(Spacer(1, 6))
    story.append(ChromeRule(page_w))
    story.append(Spacer(1, 14))

    # ── Job Title ─────────────────────────────────────────────────────────────
    story.append(Paragraph(data.get('job_title', 'Shelf Audit'), s['ReportTitle']))
    story.append(Spacer(1, 4))

    # ── Summary Table ─────────────────────────────────────────────────────────
    story.append(Paragraph('Job Summary', s['SectionHeader']))

    submitted_str = 'N/A'
    if data.get('submitted_at'):
        try:
            dt = datetime.fromisoformat(data['submitted_at'].replace('Z', '+00:00'))
            submitted_str = dt.strftime('%B %d, %Y at %I:%M %p')
        except Exception:
            submitted_str = data['submitted_at']

    summary_rows = [
        ['Brand',         data.get('brand_name', 'N/A')],
        ['Store Banner',  data.get('store_banner', 'N/A')],
        ['Store Name',    data.get('store_name', 'N/A')],
        ['Store Address', data.get('store_address', 'N/A')],
        ['Product / SKU', data.get('sku_name', 'N/A')],
        ['UPC',           data.get('sku_upc', 'N/A')],
        ['Completed',     submitted_str],
        ['Verified By',   data.get('shelfer_first_name', 'ShelfAssured Shelfer')],
    ]

    tbl_data = [[
        Paragraph(row[0], s['FieldLabel']),
        Paragraph(str(row[1]), s['FieldValue'])
    ] for row in summary_rows]

    summary_tbl = Table(tbl_data, colWidths=[1.4*inch, page_w - 1.4*inch])
    summary_tbl.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (0, -1), LIGHT_GRAY),
        ('VALIGN',     (0, 0), (-1, -1), 'TOP'),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 5),
        ('LEFTPADDING',   (0, 0), (-1, -1), 8),
        ('RIGHTPADDING',  (0, 0), (-1, -1), 8),
        ('LINEBELOW', (0, 0), (-1, -2), 0.5, HexColor('#E0E0E0')),
        ('BOX', (0, 0), (-1, -1), 0.5, CHROME),
    ]))
    story.append(summary_tbl)
    story.append(Spacer(1, 14))

    # ── Verification Results ──────────────────────────────────────────────────
    story.append(Paragraph('Verification Results', s['SectionHeader']))

    price_verified = data.get('price_verified')
    price_found    = data.get('price_found', 'N/A')
    price_expected = data.get('price_expected', 'N/A')
    stock_level    = data.get('stock_level', 'N/A')

    if price_verified is True:
        price_status_style = s['StatusGood']
        price_status_text  = 'VERIFIED — Price matches expected'
    elif price_verified is False:
        price_status_style = s['StatusWarn']
        price_status_text  = 'MISMATCH — Price does not match expected'
    else:
        price_status_style = s['FieldValue']
        price_status_text  = 'Not recorded'

    if stock_level and stock_level.lower() in ('in stock', 'full'):
        stock_style = s['StatusGood']
    elif stock_level and stock_level.lower() in ('low', 'low stock'):
        stock_style = s['StatusWarn']
    elif stock_level and stock_level.lower() in ('out of stock', 'empty'):
        stock_style = ParagraphStyle('StockBad', fontName='Helvetica-Bold', fontSize=10, textColor=RED)
    else:
        stock_style = s['FieldValue']

    verif_data = [
        [Paragraph('Price Status', s['FieldLabel']),
         Paragraph(price_status_text, price_status_style)],
        [Paragraph('Price Found', s['FieldLabel']),
         Paragraph(f'${price_found}' if price_found and price_found != 'N/A' else 'N/A', s['FieldValue'])],
        [Paragraph('Expected Price', s['FieldLabel']),
         Paragraph(f'${price_expected}' if price_expected and price_expected != 'N/A' else 'N/A', s['FieldValue'])],
        [Paragraph('Stock Level', s['FieldLabel']),
         Paragraph(str(stock_level), stock_style)],
    ]

    verif_tbl = Table(verif_data, colWidths=[1.4*inch, page_w - 1.4*inch])
    verif_tbl.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (0, -1), LIGHT_GRAY),
        ('VALIGN',     (0, 0), (-1, -1), 'MIDDLE'),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
        ('LEFTPADDING',   (0, 0), (-1, -1), 8),
        ('RIGHTPADDING',  (0, 0), (-1, -1), 8),
        ('LINEBELOW', (0, 0), (-1, -2), 0.5, HexColor('#E0E0E0')),
        ('BOX', (0, 0), (-1, -1), 0.5, CHROME),
    ]))
    story.append(verif_tbl)
    story.append(Spacer(1, 14))

    # ── Photos ────────────────────────────────────────────────────────────────
    photos = data.get('photos', [])
    if photos:
        story.append(Paragraph('Shelf Photos', s['SectionHeader']))

        photo_captions = {
            'product_closeup': 'Product Close-Up',
            'section_context': 'Shelf Section',
            'wide_angle':      'Wide-Angle Aisle View',
        }

        # Fetch images (up to 3)
        photo_cells = []
        for ph in photos[:3]:
            url     = ph.get('url', '')
            ph_type = ph.get('type', '')
            caption = photo_captions.get(ph_type, ph.get('caption', ph_type.replace('_', ' ').title()))
            img = fetch_image(url, max_w=2.2*inch, max_h=2.0*inch)
            if img:
                cell = [img, Paragraph(caption, s['PhotoCaption'])]
            else:
                cell = [
                    Paragraph(f'[Photo not available]', s['PhotoCaption']),
                    Paragraph(caption, s['PhotoCaption'])
                ]
            photo_cells.append(cell)

        # Pad to 3 columns
        while len(photo_cells) < 3:
            photo_cells.append(['', ''])

        col_w = page_w / 3
        photo_tbl = Table(
            [photo_cells],
            colWidths=[col_w, col_w, col_w]
        )
        photo_tbl.setStyle(TableStyle([
            ('ALIGN',   (0, 0), (-1, -1), 'CENTER'),
            ('VALIGN',  (0, 0), (-1, -1), 'TOP'),
            ('TOPPADDING',    (0, 0), (-1, -1), 6),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
            ('BOX', (0, 0), (-1, -1), 0.5, CHROME),
            ('INNERGRID', (0, 0), (-1, -1), 0.25, HexColor('#E0E0E0')),
            ('BACKGROUND', (0, 0), (-1, -1), LIGHT_GRAY),
        ]))
        story.append(photo_tbl)
        story.append(Spacer(1, 14))

    # ── Shelfer Notes ─────────────────────────────────────────────────────────
    shelfer_notes = data.get('shelfer_notes', '').strip()
    if shelfer_notes:
        story.append(Paragraph('Field Notes', s['SectionHeader']))
        notes_tbl = Table(
            [[Paragraph(shelfer_notes, s['FieldValue'])]],
            colWidths=[page_w]
        )
        notes_tbl.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), LIGHT_GRAY),
            ('BOX', (0, 0), (-1, -1), 0.5, CHROME),
            ('TOPPADDING',    (0, 0), (-1, -1), 8),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
            ('LEFTPADDING',   (0, 0), (-1, -1), 10),
            ('RIGHTPADDING',  (0, 0), (-1, -1), 10),
        ]))
        story.append(notes_tbl)
        story.append(Spacer(1, 14))

    # ── Personal Note from ShelfAssured ──────────────────────────────────────
    if personal_note and personal_note.strip():
        story.append(Paragraph('A Note from ShelfAssured', s['SectionHeader']))
        note_tbl = Table(
            [[Paragraph(personal_note.strip(), s['PersonalNote'])]],
            colWidths=[page_w]
        )
        note_tbl.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, -1), HexColor('#FFF8F8')),
            ('BOX', (0, 0), (-1, -1), 1, RED),
            ('TOPPADDING',    (0, 0), (-1, -1), 10),
            ('BOTTOMPADDING', (0, 0), (-1, -1), 10),
            ('LEFTPADDING',   (0, 0), (-1, -1), 12),
            ('RIGHTPADDING',  (0, 0), (-1, -1), 12),
        ]))
        story.append(note_tbl)
        story.append(Spacer(1, 14))

    # ── Footer Rule ───────────────────────────────────────────────────────────
    story.append(Spacer(1, 6))
    story.append(ChromeRule(page_w))
    story.append(Spacer(1, 6))

    report_id = data.get('report_id', '')
    footer_text = (
        'This report was prepared by ShelfAssured and is intended solely for the recipient named above. '
        'Photos and data remain the property of ShelfAssured. '
        'For questions, contact hello@beshelfassured.com'
    )
    if report_id:
        footer_text += f'  |  Report ID: {report_id}'

    story.append(Paragraph(footer_text, s['FooterText']))

    # ── Build ─────────────────────────────────────────────────────────────────
    doc.build(story)
    print(f"Report generated: {output_path}")
    return output_path


# ── CLI entry point ────────────────────────────────────────────────────────────
if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python3 generate_report.py '<json>' output.pdf [personal_note]")
        sys.exit(1)

    data        = json.loads(sys.argv[1])
    output_path = sys.argv[2]
    note        = sys.argv[3] if len(sys.argv) > 3 else None

    generate_report(data, output_path, note)
