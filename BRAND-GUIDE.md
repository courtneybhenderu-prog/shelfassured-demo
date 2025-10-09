# ShelfAssured Brand Guide

## 🎨 Color Palette

### Primary Colors
- **Red (Primary)**: `#dc2626` - Used for main CTA buttons (Create Account)
- **Red Hover**: `#b91c1c` - Darker shade for button hover states
- **Gray (Secondary)**: `#6b7280` - Used for secondary buttons (Sign In)
- **Gray Hover**: `#4b5563` - Darker shade for button hover states

### Neutral Colors
- **Background**: `#f9fafb` (gray-50) - Main page background
- **Card Background**: `#ffffff` (white) - Card and content backgrounds
- **Text Primary**: `#111827` (gray-900) - Main headings and important text
- **Text Secondary**: `#6b7280` (gray-600) - Subheadings and body text
- **Border**: `#e5e7eb` (gray-200) - Subtle borders and dividers

## 🔤 Typography

### Font Family
- **Primary**: System fonts (`system-ui, sans-serif`)
- **Fallback**: `'Inter', sans-serif` (if available)

### Font Sizes
- **H1 (Main Headings)**: `text-4xl` (36px) - Page titles
- **H2 (Section Headings)**: `text-2xl` (24px) - Section titles
- **H3 (Subheadings)**: `text-xl` (20px) - Subsection titles
- **Body Text**: `text-base` (16px) - Regular content
- **Small Text**: `text-sm` (14px) - Captions and hints
- **Button Text**: `font-semibold` (600 weight) - Button labels

## 🔘 Button Styles

### Primary Button (.btn-red)
```css
.btn-red {
    background-color: #dc2626;
    color: white;
    padding: 12px 24px;
    border-radius: 8px;
    font-weight: 600;
    text-align: center;
    transition: background-color 0.2s;
    border: none;
    cursor: pointer;
}
.btn-red:hover {
    background-color: #b91c1c;
}
```

### Secondary Button (.btn-gray)
```css
.btn-gray {
    background-color: #6b7280;
    color: white;
    padding: 12px 24px;
    border-radius: 8px;
    font-weight: 600;
    text-align: center;
    transition: background-color 0.2s;
    border: none;
    cursor: pointer;
}
.btn-gray:hover {
    background-color: #4b5563;
}
```

## 📐 Layout & Spacing

### Container Sizes
- **Max Width**: `max-w-7xl` (1280px) - Main content containers
- **Padding**: `px-4 sm:px-6 lg:px-8` - Responsive horizontal padding
- **Vertical Spacing**: `py-6`, `py-12` - Consistent vertical spacing

### Grid System
- **Mobile**: Single column layout
- **Tablet**: Responsive grid with `sm:` breakpoints
- **Desktop**: Multi-column layouts with `lg:` breakpoints

## 🖼️ Logo Usage

### Logo Specifications
- **File**: `logo_shelfassured.png`
- **Height**: `h-8` (32px) - Standard header size
- **Alt Text**: "ShelfAssured"
- **Spacing**: `ml-2` (8px) margin from brand name

### Brand Name
- **Font**: `text-xl font-bold text-gray-900`
- **Spacing**: `ml-2` from logo
- **Color**: Primary text color (#111827)

## 🎯 Component Examples

### Header
```html
<header class="bg-white shadow-sm">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between items-center py-6">
            <div class="flex items-center">
                <img src="logo_shelfassured.png" alt="ShelfAssured" class="h-8 w-auto">
                <span class="ml-2 text-xl font-bold text-gray-900">ShelfAssured</span>
            </div>
        </div>
    </div>
</header>
```

### Card Component
```html
<div class="bg-white rounded-lg shadow-md p-8">
    <!-- Card content -->
</div>
```

### Button Group
```html
<div class="space-y-3">
    <button class="w-full btn-red">Primary Action</button>
    <button class="w-full btn-gray">Secondary Action</button>
</div>
```

## 📱 Responsive Design

### Breakpoints
- **Mobile**: Default (0px+)
- **Small**: `sm:` (640px+)
- **Medium**: `md:` (768px+)
- **Large**: `lg:` (1024px+)
- **Extra Large**: `xl:` (1280px+)

### Mobile-First Approach
- Design for mobile first
- Use `sm:`, `md:`, `lg:` prefixes for larger screens
- Ensure touch targets are at least 44px

## 🎨 Usage Guidelines

### Do's ✅
- Use consistent spacing with Tailwind classes
- Maintain proper contrast ratios
- Use the defined color palette
- Follow the button hierarchy (red = primary, gray = secondary)
- Keep logos and branding consistent

### Don'ts ❌
- Don't use custom colors outside the palette
- Don't mix different button styles
- Don't use inconsistent spacing
- Don't override the brand colors
- Don't use fonts outside the system font stack

## 🔧 Implementation

### CSS Framework
- **Primary**: Tailwind CSS (CDN)
- **Custom**: Inline `<style>` blocks for brand-specific classes
- **Responsive**: Mobile-first with Tailwind breakpoints

### File Structure
- **Brand CSS**: Inline in each HTML file
- **Shared Styles**: `shared/styles.css` (if needed)
- **Component Styles**: Component-specific inline styles

---

*This brand guide ensures consistent visual identity across all ShelfAssured pages and components.*
