# Manual Test Plan (Smoke)

## Shopper happy path
1) screen1 → **Sign In** → screen3 → **Sign In** → screen4
2) On “Jobs Near You”, click **Rambler** → screen5
3) Enter invalid price (e.g., "2..9") → screen7 → **Submit for Review** → alert appears and returns to screen5
4) Enter valid price "2.99" → screen6 → choose Auto Demo → **Use This Photo** → screen7
5) **Analyze This Photo** → ensure summary appears; **Submit for Review** → screen9
6) Go to screen8 → **Open Client Snapshot** → confirm brand/store/price/date and analysis show → **Print** (only #screen19 prints)

## Client
1) screen8 → **Create New Job** → screen13 → **Select Job Type** → screen20
2) Fill Brand/Store, choose type (launch/rush changes payout), **Publish Job**
3) Confirm screen4 shows new group header (store) and card; select it → screen5

## Brands
- screen10 shows 5 brands; open each → screen12; Back → screen10

## Admin
- screen1 → **Admin Login** → screen14 → open 15/16/17 and back
- Quick Nav opens via **≡ Menu**, closes on scroll or mask click

## Visual & controls
- Taskbar present on screens 4, 9–11 and active tab highlighted red
- Buttons use red/gray styling; dropdown menu does not obstruct scrolling
- Map toggle switches between image and embedded map
