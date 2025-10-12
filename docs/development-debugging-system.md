# 🧭 ShelfAssured Development Debugging System

A lightweight, developer-friendly debugging system that surfaces redirect and role timing issues instantly — without affecting production.

---

## 🎯 Purpose

This system was built after the redirect-loop issue caused by `window.SA_PAGE_ROLE` loading **after** the global guard in `shared/api.js`.  
It now provides instant visibility into page roles, guard behavior, and script order — helping you catch timing or setup issues before they cause redirects.

---

## ⚙️ How It Works

| Mode | How to Activate | What It Does |
|------|------------------|--------------|
| **Dev Mode** | Add `?dev=1` to any URL | Enables debugging logs |
| **Disable Mode** | Add `?dev=0` or run `localStorage.removeItem('SA_DEV')` | Turns off logs |
| **Manual Control** | `localStorage.setItem('SA_DEV', '1')` in console | Enables manually |

---

## 🧩 Implementation Overview

### 1️⃣ Dev Mode Toggle (in `<head>`)

```html
<script>
  // Enable with ?dev=1, disable with ?dev=0
  (function () {
    const q = new URLSearchParams(location.search);
    if (q.get('dev') === '1') localStorage.setItem('SA_DEV', '1');
    if (q.get('dev') === '0') localStorage.removeItem('SA_DEV');
    window.__SA_DEV__ = !!localStorage.getItem('SA_DEV');
  })();
</script>
```

### 2️⃣ Guard Debugging (in shared/api.js)

```javascript
if (window.__SA_DEV__) {
  console.info(
    '%c[SA][guard]',
    'color: #6cf;',
    'path=',
    location.pathname,
    'role=',
    window.SA_PAGE_ROLE ?? '(undefined)'
  );

  if (typeof window.SA_PAGE_ROLE === 'undefined') {
    console.warn(
      '%c[SA][guard] ⚠️ Missing SA_PAGE_ROLE on',
      'color: #f66;',
      location.pathname
    );
  }
}
```

### 3️⃣ Role Confirmation (on each page)

```html
<script>
  window.__SA_DEV__ &&
    console.debug(
      '%c[SA][page]',
      'color: #6f6;',
      'role set to',
      window.SA_PAGE_ROLE,
      'before shared/api.js'
    );
</script>
```

---

## 🌈 Color System

| Color | Meaning | Example Output |
|-------|---------|----------------|
| 🔵 Blue | Normal guard execution (info) | `[SA][guard] path=/ role=public` |
| 🔴 Red | Warning – missing role | `[SA][guard] ⚠️ Missing SA_PAGE_ROLE on /index.html` |
| 🟢 Green | Confirmation of correct script order | `[SA][page] role set to public before shared/api.js` |

---

## 🧠 Why It Exists

**Problem it prevents:**
Redirect loops and incorrect routing caused by missing or late-loaded `SA_PAGE_ROLE`.

**What it catches:**
- Script loading order issues
- Missing role definitions  
- Unexpected redirect triggers

**Real example:**
Originally, `shared/api.js` ran before `SA_PAGE_ROLE` was set, causing the global guard to redirect every page.
Now, the console instantly shows if that ever happens again.

---

## 💡 Developer Benefits

- 🕵️ **Instant understanding** — see role status and guard behavior in one glance
- 🧩 **Problem prevention** — catches timing issues before they break redirects
- 🧘 **Maintenance friendly** — clear comments and structured logs
- 🚀 **Zero impact on production** — silent when `__SA_DEV__` is false

---

## ✅ Summary

This is a professional-grade debugging system designed for clarity, speed, and simplicity.

> "Now that this system's in place, every future redirect, timing bug, or role mismatch will show up instantly in a single glance."

- **Enable with** `?dev=1`
- **Disable with** `?dev=0`
- **Enjoy painless debugging.** 🌿
