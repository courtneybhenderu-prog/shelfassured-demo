# 🧭 Development Debugging System

**Instant visibility into redirect issues and role timing problems.**

## Quick Start
- **Enable:** Add `?dev=1` to any URL
- **Disable:** Add `?dev=0` or run `localStorage.removeItem('SA_DEV')`

## What You'll See
- 🔵 **Blue logs:** Normal guard execution
- 🔴 **Red warnings:** Missing SA_PAGE_ROLE (problems!)
- 🟢 **Green logs:** Role confirmation

## Why It Exists
Prevents redirect loops caused by script loading order issues. Originally, `shared/api.js` ran before `SA_PAGE_ROLE` was set, causing every page to redirect. This system catches that instantly.

## Developer Benefits
- **Instant problem detection** — see issues in one glance
- **Zero production impact** — silent when disabled
- **Future-proof** — catches timing bugs before they break redirects

> "Every future redirect, timing bug, or role mismatch will show up instantly in a single glance."

[📖 Full Documentation](docs/development-debugging-system.md)
