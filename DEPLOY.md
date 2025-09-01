# Deploying to GitHub Pages

1) Ensure repo root contains `index.html` (this prototype is a single file).
2) In GitHub: **Settings → Pages** → Source: **Deploy from a branch** → Branch: `main` (or `gh-pages`) → `/` (root).
3) Wait for Pages to build; visit the shown URL.
4) If you update the file and don’t see changes, hard-refresh (Ctrl/Cmd+Shift+R) due to CDN cache.

## Assets
- Demo photo names referenced: `demo_peets_aisle.jpg`, `demo_peets_shelf.jpg`, `demo_sparkling_aisle.jpg`.
  - If you want the Auto Demo images to appear, add these files to the same directory as `index.html` (or switch to your own filenames in `loadDemoPhoto()` / `setDemoSet()`).
