// ========================================
// Product Categories - Single Source of Truth
// ========================================
// This file contains the canonical list of 72 product categories
// Used across: brand onboarding, job creation, product management
// Date: 2025-01-13

const PRODUCT_CATEGORIES = [
    'Air Care',
    'Asian Foods',
    'Baby Food',
    'Bagels',
    'Beef',
    'Beer',
    'Body Care',
    'Bread',
    'Butter',
    'Candy',
    'Canned Fruit',
    'Canned Tomatoes',
    'Canned Vegetables',
    'Cat Food',
    'Cheese',
    'Chips',
    'Cleaning Supplies',
    'Coffee',
    'Cold Cereal',
    'Condiments',
    'Cookies',
    'Diapers',
    'Dog Food',
    'Eggs',
    'Energy & Functional Beverage',
    'Feminine Hygiene',
    'Fresh Fruit',
    'Fresh Vegetables',
    'Frozen Bread',
    'Frozen Desserts & Novelties',
    'Frozen Fruits',
    'Frozen Meals',
    'Frozen Pizza',
    'Frozen Potatoes',
    'Frozen Vegetables',
    'Granola',
    'Herbs',
    'Ice Cream',
    'Laundry',
    'Meat Alternatives',
    'Mediterranean Foods',
    'Mexican Foods',
    'Milk',
    'Nuts',
    'Oatmeal',
    'Oil & Vinegar',
    'Other International Foods',
    'Packaged Salads',
    'Pancake Mix',
    'Paper Goods',
    'Pasta',
    'Pasta Sauce',
    'Pastries',
    'Pet Treats',
    'Pork',
    'Poultry',
    'Protein Bars',
    'Ready to Drink Coffee & Tea',
    'Rice, Beans & Grains',
    'Salad Dressing',
    'Seafood',
    'Sparkling Water',
    'Spices & Seasonings',
    'Spirits',
    'Still Water',
    'Supplements',
    'Tea',
    'Trail Mix',
    'Vitamins',
    'Wine',
    'Wipes',
    'Yogurt'
];

// Helper function to generate category dropdown HTML
function generateCategoryDropdownHTML(includeEmptyOption = true) {
    let html = '';
    if (includeEmptyOption) {
        html += '<option value="">Select category</option>';
    }
    PRODUCT_CATEGORIES.forEach(category => {
        html += `<option value="${escapeHtml(category)}">${escapeHtml(category)}</option>`;
    });
    return html;
}

// Helper function to generate category reference list HTML (for CSV uploads)
function generateCategoryReferenceHTML() {
    return PRODUCT_CATEGORIES.map(cat => `<span>${escapeHtml(cat)}</span>`).join('\n            ');
}

// Helper function to escape HTML (if not already available)
function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Export for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        PRODUCT_CATEGORIES,
        generateCategoryDropdownHTML,
        generateCategoryReferenceHTML
    };
}


