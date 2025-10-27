# Store Selector Testing Checklist

## ✅ Completed
- [x] Schema migrations applied
- [x] Banner tables created (12 retailers, 15 banners)
- [x] All 2,376 stores now have banner_id linked
- [x] JavaScript files deployed to GitHub Pages
- [x] Generated columns working (zip5, state_zip)

## 🧪 Test Now

### 1. Open Job Creation Form
Go to: https://courtneybhenderu-prog.github.io/shelfassured-demo/admin/manage-jobs.html

### 2. Test Store Search
- [ ] Type "Bridgeland" → Should show H-E-B Bridgeland
- [ ] Type "Austin" → Should show ALL Austin stores (H-E-B, Whole Foods, Sprouts, etc.)
- [ ] Type "Houston" → Should show ALL Houston stores

### 3. Test Chain Filtering
- [ ] Open "Filter by Chain" dropdown
- [ ] Should see: H-E-B, Albertsons, Walmart, Target, Kroger, etc.
- [ ] Select H-E-B → Should show 429 stores
- [ ] Select Albertsons → Should show 480 stores
- [ ] Select Walmart → Should show 639 stores
- [ ] Select "All Chains" → Should show all stores

### 4. Test Metro Search
- [ ] Search "Austin" → Should find stores with metro matching "Austin"
- [ ] Search "Dallas" → Should find stores with metro matching "Dallas"
- [ ] Search "Houston" → Should find stores with metro matching "Houston"

## Expected Results
✅ Multiple chains visible in dropdown (not just Kroger)
✅ Filtering shows correct number of stores per chain
✅ Search finds stores across all chains (not just Sprouts)
✅ Metro searches work properly
✅ No duplicate stores created (unique index enforces)

## Issues to Report
If any test fails, note:
1. What you searched for
2. What stores appeared
3. What stores should have appeared
4. Any console errors (F12 → Console tab)

