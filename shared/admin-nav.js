/**
 * ShelfAssured — Shared Admin Navigation
 * Injects a responsive top header + hamburger slide-out drawer into every admin page.
 *
 * Usage: Add ONE line to any admin page <body>:
 *   <script src="../shared/admin-nav.js" data-page="dashboard"></script>
 *
 * data-page values:
 *   dashboard | manage-jobs | review-submissions | scan-intelligence |
 *   user-management | brands | barcode-capture | help-support
 */
(function () {
  const NAV_ITEMS = [
    { id: 'dashboard',           label: 'Dashboard',           href: 'dashboard.html' },
    { id: 'shelfer-hub',         label: 'Shelfer Hub',         href: 'shelfer-hub.html' },
    { id: 'brand-hub',           label: 'Brand Hub',           href: 'brand-hub.html' },
    { id: 'scan-intelligence',   label: 'Scan Intelligence',   href: 'scan-intelligence.html' },
    { id: 'review-submissions',  label: 'Review Submissions',  href: 'review-submissions.html' },
    { id: 'manage-jobs',         label: 'Manage Jobs',         href: 'manage-jobs.html' },
    { id: 'brands',              label: 'Brands',              href: 'brands.html' },
    { id: 'user-management',     label: 'User Management',     href: 'user-management.html' },
    { id: 'barcode-capture',     label: 'Barcode Scanner',     href: 'barcode-capture.html' },
    { id: 'help-support',        label: 'Help & Support',      href: 'help-support.html' },
  ];

  // Determine current page from script tag attribute
  const scriptTag = document.currentScript ||
    document.querySelector('script[data-page]');
  const currentPage = scriptTag ? scriptTag.getAttribute('data-page') : '';

  // Page titles map
  const PAGE_TITLES = {
    'dashboard':          'Admin Dashboard',
    'shelfer-hub':        'Shelfer Hub',
    'brand-hub':          'Brand Hub',
    'scan-intelligence':  'Scan Intelligence',
    'review-submissions': 'Review Submissions',
    'manage-jobs':        'Manage Jobs',
    'brands':             'Brands',
    'user-management':    'User Management',
    'barcode-capture':    'Barcode Scanner',
    'help-support':       'Help & Support',
  };

  const pageTitle = PAGE_TITLES[currentPage] || 'Admin';

  // ── Inject CSS ──────────────────────────────────────────────────────────────
  const style = document.createElement('style');
  style.textContent = `
    /* SA Admin Nav */
    #sa-admin-nav {
      position: sticky;
      top: 0;
      z-index: 1000;
      background: #fff;
      border-bottom: 1px solid #e5e7eb;
      box-shadow: 0 1px 4px rgba(0,0,0,.06);
    }
    #sa-admin-nav .nav-inner {
      max-width: 1280px;
      margin: 0 auto;
      padding: 0 1rem;
      height: 56px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 1rem;
    }
    #sa-admin-nav .nav-logo {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      text-decoration: none;
    }
    #sa-admin-nav .nav-logo-text {
      font-weight: 800;
      font-size: 1rem;
      color: #C62828;
      letter-spacing: -0.02em;
    }
    #sa-admin-nav .nav-page-title {
      font-size: 1rem;
      font-weight: 600;
      color: #111827;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }
    #sa-admin-nav .nav-badge {
      background: #fee2e2;
      color: #C62828;
      font-size: 0.65rem;
      font-weight: 700;
      padding: 2px 7px;
      border-radius: 999px;
      letter-spacing: .04em;
    }
    #sa-admin-nav .nav-right {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      flex-shrink: 0;
    }
    /* Desktop quick links (hidden on small screens) */
    #sa-admin-nav .nav-desktop-links {
      display: none;
      align-items: center;
      gap: 0.25rem;
    }
    @media (min-width: 900px) {
      #sa-admin-nav .nav-desktop-links { display: flex; }
    }
    #sa-admin-nav .nav-desktop-links a {
      font-size: 0.8rem;
      font-weight: 500;
      color: #6b7280;
      text-decoration: none;
      padding: 0.35rem 0.6rem;
      border-radius: 0.375rem;
      transition: background .15s, color .15s;
      white-space: nowrap;
    }
    #sa-admin-nav .nav-desktop-links a:hover {
      background: #f3f4f6;
      color: #111827;
    }
    #sa-admin-nav .nav-desktop-links a.active {
      background: #fee2e2;
      color: #C62828;
      font-weight: 700;
    }
    /* Hamburger button */
    #sa-hamburger {
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      gap: 5px;
      width: 40px;
      height: 40px;
      background: none;
      border: none;
      cursor: pointer;
      padding: 6px;
      border-radius: 0.375rem;
      transition: background .15s;
      flex-shrink: 0;
    }
    #sa-hamburger:hover { background: #f3f4f6; }
    #sa-hamburger span {
      display: block;
      width: 22px;
      height: 2px;
      background: #374151;
      border-radius: 2px;
      transition: transform .25s, opacity .25s;
    }
    #sa-hamburger.open span:nth-child(1) { transform: translateY(7px) rotate(45deg); }
    #sa-hamburger.open span:nth-child(2) { opacity: 0; }
    #sa-hamburger.open span:nth-child(3) { transform: translateY(-7px) rotate(-45deg); }

    /* Overlay */
    #sa-nav-overlay {
      display: none;
      position: fixed;
      inset: 0;
      background: rgba(0,0,0,.35);
      z-index: 1100;
    }
    #sa-nav-overlay.open { display: block; }

    /* Drawer */
    #sa-nav-drawer {
      position: fixed;
      top: 0;
      right: 0;
      bottom: 0;
      width: 280px;
      max-width: 85vw;
      background: #fff;
      z-index: 1200;
      transform: translateX(100%);
      transition: transform .28s cubic-bezier(.4,0,.2,1);
      display: flex;
      flex-direction: column;
      box-shadow: -4px 0 24px rgba(0,0,0,.12);
    }
    #sa-nav-drawer.open { transform: translateX(0); }

    .drawer-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 1rem 1.25rem;
      border-bottom: 1px solid #f3f4f6;
    }
    .drawer-header-title {
      font-weight: 800;
      font-size: 1.1rem;
      color: #C62828;
    }
    .drawer-close {
      background: none;
      border: none;
      font-size: 1.4rem;
      color: #6b7280;
      cursor: pointer;
      line-height: 1;
      padding: 4px 8px;
      border-radius: 0.375rem;
    }
    .drawer-close:hover { background: #f3f4f6; color: #111; }

    .drawer-user {
      padding: 0.75rem 1.25rem;
      font-size: 0.8rem;
      color: #6b7280;
      background: #fafafa;
      border-bottom: 1px solid #f3f4f6;
    }
    .drawer-user strong { color: #111827; }

    .drawer-nav {
      flex: 1;
      overflow-y: auto;
      padding: 0.5rem 0;
    }
    .drawer-nav a {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      padding: 0.75rem 1.25rem;
      font-size: 0.95rem;
      font-weight: 500;
      color: #374151;
      text-decoration: none;
      transition: background .15s, color .15s;
    }
    .drawer-nav a:hover { background: #f9fafb; color: #111827; }
    .drawer-nav a.active {
      background: #fee2e2;
      color: #C62828;
      font-weight: 700;
      border-right: 3px solid #C62828;
    }
    .drawer-divider {
      height: 1px;
      background: #f3f4f6;
      margin: 0.5rem 0;
    }
    .drawer-footer {
      padding: 1rem 1.25rem;
      border-top: 1px solid #f3f4f6;
    }
    .drawer-signout {
      width: 100%;
      padding: 0.65rem 1rem;
      background: #fef2f2;
      color: #C62828;
      border: 1px solid #fecaca;
      border-radius: 0.5rem;
      font-weight: 600;
      font-size: 0.9rem;
      cursor: pointer;
      transition: background .15s;
    }
    .drawer-signout:hover { background: #fee2e2; }

    /* Push body down so sticky nav doesn't overlap content */
    body { padding-top: 0 !important; }
  `;
  document.head.appendChild(style);

  // ── Build HTML ──────────────────────────────────────────────────────────────
  function buildDesktopLinks() {
    return NAV_ITEMS.map(item => {
      const active = item.id === currentPage ? ' class="active"' : '';
      return `<a href="${item.href}"${active}>${item.label}</a>`;
    }).join('');
  }

  function buildDrawerLinks() {
    return NAV_ITEMS.map(item => {
      const active = item.id === currentPage ? ' class="active"' : '';
      return `<a href="${item.href}"${active}>${item.label}</a>`;
    }).join('');
  }

  const navHTML = `
    <nav id="sa-admin-nav" role="navigation" aria-label="Admin navigation">
      <div class="nav-inner">
        <a href="dashboard.html" class="nav-logo" aria-label="ShelfAssured Admin Home">
          <span class="nav-logo-text">ShelfAssured</span>
          <span class="nav-badge">ADMIN</span>
        </a>
        <span class="nav-page-title">${pageTitle}</span>
        <div class="nav-right">
          <nav class="nav-desktop-links" aria-label="Quick navigation">
            ${buildDesktopLinks()}
          </nav>
          <button id="sa-hamburger" aria-label="Open navigation menu" aria-expanded="false" aria-controls="sa-nav-drawer">
            <span></span><span></span><span></span>
          </button>
        </div>
      </div>
    </nav>

    <!-- Overlay -->
    <div id="sa-nav-overlay" role="presentation"></div>

    <!-- Slide-out drawer -->
    <aside id="sa-nav-drawer" role="dialog" aria-modal="true" aria-label="Navigation menu">
      <div class="drawer-header">
        <span class="drawer-header-title">Menu</span>
        <button class="drawer-close" id="sa-drawer-close" aria-label="Close menu">×</button>
      </div>
      <div class="drawer-user">
        Signed in as <strong id="sa-nav-user-name">Admin</strong>
      </div>
      <nav class="drawer-nav" aria-label="Admin pages">
        ${buildDrawerLinks()}
        <div class="drawer-divider"></div>
      </nav>
      <div class="drawer-footer">
        <button class="drawer-signout" id="sa-nav-signout">Sign Out</button>
      </div>
    </aside>
  `;

  // Insert nav as first child of body
  const wrapper = document.createElement('div');
  wrapper.innerHTML = navHTML;
  document.body.insertBefore(wrapper, document.body.firstChild);

  // ── Behaviour ───────────────────────────────────────────────────────────────
  const hamburger = document.getElementById('sa-hamburger');
  const overlay   = document.getElementById('sa-nav-overlay');
  const drawer    = document.getElementById('sa-nav-drawer');
  const closeBtn  = document.getElementById('sa-drawer-close');
  const signoutBtn = document.getElementById('sa-nav-signout');

  function openDrawer() {
    drawer.classList.add('open');
    overlay.classList.add('open');
    hamburger.classList.add('open');
    hamburger.setAttribute('aria-expanded', 'true');
    document.body.style.overflow = 'hidden';
  }

  function closeDrawer() {
    drawer.classList.remove('open');
    overlay.classList.remove('open');
    hamburger.classList.remove('open');
    hamburger.setAttribute('aria-expanded', 'false');
    document.body.style.overflow = '';
  }

  hamburger.addEventListener('click', () => {
    drawer.classList.contains('open') ? closeDrawer() : openDrawer();
  });
  overlay.addEventListener('click', closeDrawer);
  closeBtn.addEventListener('click', closeDrawer);

  // Keyboard: Escape closes drawer
  document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && drawer.classList.contains('open')) closeDrawer();
  });

  // Sign out — calls whatever signOut function the page defines
  signoutBtn.addEventListener('click', () => {
    closeDrawer();
    // Try common sign-out function names used across the app
    if (typeof signOut === 'function') signOut();
    else if (typeof handleSignOut === 'function') handleSignOut();
    else {
      // Fallback: clear Supabase session and redirect
      try {
        const sb = window.supabase || (window._supabase);
        if (sb) sb.auth.signOut().then(() => { window.location.href = '../index.html'; });
        else window.location.href = '../index.html';
      } catch(e) { window.location.href = '../index.html'; }
    }
  });

  // Populate user name from Supabase session if available
  function trySetUserName() {
    try {
      const sb = window.supabase || window._supabase;
      if (!sb) return;
      sb.auth.getUser().then(({ data }) => {
        if (data && data.user) {
          const name = data.user.user_metadata?.full_name ||
                       data.user.user_metadata?.name ||
                       data.user.email || 'Admin';
          const el = document.getElementById('sa-nav-user-name');
          if (el) el.textContent = name;
        }
      });
    } catch(e) {}
  }

  // Wait for Supabase to be ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', trySetUserName);
  } else {
    setTimeout(trySetUserName, 500);
  }

})();
