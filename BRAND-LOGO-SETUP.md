# Brand Logo Setup Guide

## Overview
Brand logos can be added via file upload to Supabase Storage or by providing an external URL.

## Setup Steps

### 1. Create Supabase Storage Bucket (if using file upload)
1. Go to Supabase Dashboard → Storage
2. Click "New bucket"
3. Name: `brand_logos`
4. Set as **Public** (uncheck "Private bucket")
5. Save

### 2. Run SQL Migration
Run `add-brand-logo-support.sql` to ensure the `logo_url` column exists in the `brands` table.

### 3. Add Logo via Brand Onboarding Form
1. Navigate to `admin/brands-new.html`
2. In the "Brand Logo" section:
   - Click "Upload Logo" to select an image file, OR
   - Paste a logo URL in the "Or paste logo URL" field
3. Logo preview will appear
4. Complete the form and save

### 4. View Logos
- **Admin Dashboard**: Logos appear in the Brands panel next to each brand name
- **Brand Dashboard**: Logo appears in the header and brand info section

## Features
- **File Upload**: Upload logo images (JPG, PNG, SVG) to Supabase Storage
- **URL Support**: Paste external logo URLs (e.g., from CDN or website)
- **Preview**: See logo preview before saving
- **Display**: Logos display on admin brands list and brand dashboards
- **Fallback**: Shows "No Logo" placeholder if no logo is set

## File Locations
- Upload form: `admin/brands-new.html`
- Display: 
  - `admin/dashboard.html` (Brands panel)
  - `brand/dashboard.html` (Brand dashboard)

## Storage Path
Logos are stored in Supabase Storage at:
- Path: `brand_logos/{brandId}_{timestamp}.{ext}`
- Example: `brand_logos/abc123_1704067200000.png`

## Troubleshooting
- **"Bucket not found" error**: Create the `brand_logos` bucket in Supabase Storage (see step 1)
- **Logo not displaying**: Check that the bucket is set to Public
- **Image not loading**: Verify the URL is accessible and uses HTTPS


