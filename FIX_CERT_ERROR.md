# Fix: ERR_CERT_AUTHORITY_INVALID Error

## The Problem
You're seeing a certificate error because your browser is trying to connect via **HTTPS** instead of **HTTP**.

## ✅ Quick Fix

### Step 1: Use HTTP (NOT HTTPS)
Make sure you're typing:
```
http://localhost:8000
```

**NOT:**
```
https://localhost:8000  ❌
```

### Step 2: Clear Browser Cache
1. Press `Ctrl + Shift + Delete`
2. Select "Cached images and files"
3. Click "Clear data"
4. Try accessing `http://localhost:8000` again

### Step 3: Use Incognito/Private Mode
This bypasses cached redirects:

**Chrome/Edge:**
- Press `Ctrl + Shift + N`
- Type: `http://localhost:8000`

**Firefox:**
- Press `Ctrl + Shift + P`
- Type: `http://localhost:8000`

### Step 4: Type URL Manually
Don't use:
- Bookmarks
- Browser history
- Auto-complete suggestions

Instead, **manually type** in the address bar:
```
http://localhost:8000
```

### Step 5: Try a Different Port
If port 8000 has issues, try a different port:

1. **Stop the current server** (Ctrl+C in PowerShell)

2. **Start on a new port:**
   ```powershell
   python -m http.server 3000
   ```

3. **Access:**
   ```
   http://localhost:3000
   ```

## Why This Happens

- Your browser may have cached a redirect to HTTPS
- Corporate proxy/firewall might be intercepting
- Browser security settings forcing HTTPS
- Previous visit to the site used HTTPS

## Verify Your Server is Running

In PowerShell, you should see:
```
Serving HTTP on :: port 8000 (http://[::]:8000/) ...
127.0.0.1 - - [date] "GET / HTTP/1.1" 200 -
```

If you see this, your server is working correctly!

## Still Not Working?

1. **Check if server is actually running:**
   - Look at your PowerShell window
   - You should see "Serving HTTP on..." message
   - If not, the server isn't running

2. **Try a different browser:**
   - If using Chrome, try Edge
   - If using Edge, try Firefox

3. **Check for proxy settings:**
   - Some corporate networks force HTTPS
   - Try from a different network if possible

4. **Verify the URL:**
   - Make sure there are no typos
   - Should be exactly: `http://localhost:8000`
   - No `https://`, no extra slashes, no spaces
