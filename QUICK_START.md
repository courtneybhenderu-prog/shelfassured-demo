# Quick Start Guide - Running ShelfAssured Demo

## The Error You're Seeing

If you see "The requested resource has not been defined" from "NT-ware MOM HTTP Server", it means:
- You might be using a different HTTP server than expected
- The server might not be running from the correct directory
- There might be a path/routing issue

## ✅ Solution: Use Python HTTP Server (Simplest)

### Step 1: Open PowerShell
Press `Win + X` and select "Windows PowerShell" (NOT as Administrator)

### Step 2: Navigate to Project Folder
```powershell
cd "c:\Users\LavanyaBhenderu\.cursor\shelfassured-demo"
```

### Step 3: Verify You're in the Right Place
```powershell
dir index.html
```
You should see `index.html` listed. If not, you're in the wrong directory.

### Step 4: Start Python Server
```powershell
python -m http.server 8000
```

If that doesn't work, try:
```powershell
py -m http.server 8000
```

### Step 5: Open in Browser
1. Open your web browser (Chrome, Edge, Firefox)
2. Go to: `http://localhost:8000`
3. You should see the ShelfAssured landing page

### Step 6: Test the Server
Try opening: `http://localhost:8000/test-server.html`
If you see "✅ Server is working!", your server is configured correctly.

## 🔧 Troubleshooting

### Problem: "python is not recognized"
**Solution:** Install Python from python.org, or use Node.js instead (see below)

### Problem: "Port 8000 already in use"
**Solution:** Use a different port:
```powershell
python -m http.server 8080
```
Then go to: `http://localhost:8080`

### Problem: Still seeing "NT-ware MOM HTTP Server" error
**Solution:** 
1. Make sure you're using Python's HTTP server, not another server
2. Check if you have any corporate proxy or firewall software interfering
3. Try closing any other web servers that might be running
4. Verify you're accessing `http://localhost:8000` (not a different URL)

### Problem: ERR_CERT_AUTHORITY_INVALID or Certificate Error
**Solution:** This means your browser is trying to use HTTPS instead of HTTP
1. **Make sure you're using `http://` NOT `https://`**
   - Correct: `http://localhost:8000`
   - Wrong: `https://localhost:8000`
2. **Clear browser cache:**
   - Press `Ctrl + Shift + Delete`
   - Clear cached images and files
   - Try again
3. **Try incognito/private mode:**
   - Chrome: `Ctrl + Shift + N`
   - Edge: `Ctrl + Shift + P`
   - Firefox: `Ctrl + Shift + P`
4. **Type the URL manually** in the address bar (don't use bookmarks or history)
5. **Try a different browser** (Chrome, Edge, Firefox)

### Problem: Page loads but shows errors
**Solution:**
1. Open browser Developer Tools (F12)
2. Check the Console tab for JavaScript errors
3. Check the Network tab to see if files are loading correctly

## Alternative: Node.js HTTP Server

If Python doesn't work, use Node.js:

### Step 1: Install http-server (one-time)
```powershell
npm install -g http-server
```

### Step 2: Navigate to Project
```powershell
cd "c:\Users\LavanyaBhenderu\.cursor\shelfassured-demo"
```

### Step 3: Start Server
```powershell
http-server -p 8000
```

### Step 4: Open Browser
Go to: `http://localhost:8000`

## What Should Happen

When you open `http://localhost:8000`, you should see:
- A page with "Shelf" and "Assured" branding
- Two buttons: "Create Account" and "Sign In"
- A beige/cream colored background

If you see this, the demo is working! 🎉

## Need More Help?

1. Check the browser console (F12) for any error messages
2. Verify the server is running (you should see log messages in PowerShell)
3. Make sure you're accessing the correct URL: `http://localhost:8000` (not `https://` or a different port)
