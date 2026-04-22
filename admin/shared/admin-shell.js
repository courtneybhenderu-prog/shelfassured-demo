/**
 * admin-shell.js
 * Injects the ShelfAssured Admin left sidebar + layout shell into every admin page.
 * Usage: <script src="../shared/admin-shell.js" data-page="shelfer-hub" data-title="Shelfer Hub" data-sub="Manage your field team"></script>
 *
 * data-page   : matches the id in NAV_ITEMS to set the active link
 * data-title  : topbar heading (defaults to page title)
 * data-sub    : topbar subtitle (optional)
 * data-actions: JSON string of {label, href, primary} objects for topbar buttons (optional)
 */
(function () {
  const script = document.currentScript;
  const pageId    = script.getAttribute('data-page') || '';
  const pageTitle = script.getAttribute('data-title') || document.title.split(' - ')[0].split(' — ')[0];
  const pageSub   = script.getAttribute('data-sub') || '';
  const actionsRaw = script.getAttribute('data-actions') || '[]';
  let topbarActions = [];
  try { topbarActions = JSON.parse(actionsRaw); } catch(e) {}

  /* ── CSS ─────────────────────────────────────────────────────────────── */
  const css = `
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    html, body { height: 100%; font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #F7F2EC; color: #1a1a1a; }
    body { display: flex; min-height: 100vh; }

    /* ── Sidebar ── */
    #sa-sidebar {
      width: 232px; min-height: 100vh; background: #1C1C1E; display: flex; flex-direction: column;
      position: fixed; top: 0; left: 0; bottom: 0; z-index: 100; overflow-y: auto;
      transition: transform .22s cubic-bezier(.4,0,.2,1);
    }
    .sb-logo { padding: 20px 16px 14px; display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid rgba(255,255,255,.07); }
    .sb-logo-text { font-size: 17px; font-weight: 800; color: #fff; letter-spacing: -.3px; }
    .sb-logo-text span { color: #D4A017; }
    .sb-admin-badge { font-size: 9px; font-weight: 700; letter-spacing: .8px; background: #C62828; color: #fff; padding: 2px 6px; border-radius: 4px; }
    .sb-section { padding: 14px 10px 4px; }
    .sb-section-label { font-size: 9.5px; font-weight: 700; color: rgba(255,255,255,.3); letter-spacing: 1.2px; text-transform: uppercase; padding: 0 8px 6px; }
    .sb-link { display: flex; align-items: center; gap: 9px; padding: 8px 10px; border-radius: 8px; font-size: 13px; font-weight: 500; color: rgba(255,255,255,.58); text-decoration: none; cursor: pointer; transition: background .12s, color .12s; position: relative; }
    .sb-link:hover { background: rgba(255,255,255,.07); color: rgba(255,255,255,.9); }
    .sb-link.active { background: rgba(198,40,40,.2); color: #fff; }
    .sb-link.active .sb-icon { color: #ef4444; }
    .sb-icon { font-size: 15px; width: 18px; text-align: center; flex-shrink: 0; }
    .sb-badge { margin-left: auto; background: #C62828; color: #fff; font-size: 10px; font-weight: 700; padding: 1px 6px; border-radius: 10px; min-width: 18px; text-align: center; display: none; }
    .sb-badge.gold { background: #D4A017; }
    .sb-badge.show { display: inline-block; }
    .sb-footer { margin-top: auto; padding: 14px 10px; border-top: 1px solid rgba(255,255,255,.08); }
    .sb-user { display: flex; align-items: center; gap: 9px; padding: 8px 10px; border-radius: 8px; cursor: pointer; }
    .sb-user:hover { background: rgba(255,255,255,.07); }
    .sb-avatar { width: 30px; height: 30px; border-radius: 50%; background: #C62828; color: #fff; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 700; flex-shrink: 0; }
    .sb-user-name { font-size: 12.5px; font-weight: 600; color: #fff; }
    .sb-user-role { font-size: 10.5px; color: rgba(255,255,255,.4); }
    .sb-signout-btn { display: block; width: 100%; margin-top: 8px; padding: 7px 10px; border-radius: 7px; background: transparent; border: 1px solid rgba(255,255,255,.12); color: rgba(255,255,255,.5); font-size: 12px; font-weight: 600; cursor: pointer; text-align: center; transition: all .12s; }
    .sb-signout-btn:hover { background: rgba(255,255,255,.06); color: rgba(255,255,255,.8); }

    /* ── Overlay & hamburger ── */
    #sa-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,.5); z-index: 99; }
    #sa-overlay.open { display: block; }
    #sa-hamburger { display: none; position: fixed; top: 14px; left: 14px; z-index: 101; background: #1C1C1E; border: none; border-radius: 8px; padding: 8px; cursor: pointer; flex-direction: column; gap: 4px; }
    #sa-hamburger span { display: block; width: 18px; height: 2px; background: rgba(255,255,255,.7); border-radius: 2px; }

    /* ── Main area ── */
    #sa-main { margin-left: 232px; flex: 1; min-height: 100vh; display: flex; flex-direction: column; }
    #sa-topbar { background: #fff; border-bottom: 1px solid #E8E0D8; padding: 14px 24px; display: flex; align-items: center; justify-content: space-between; position: sticky; top: 0; z-index: 50; }
    .sa-topbar-title { font-size: 17px; font-weight: 800; color: #1a1a1a; }
    .sa-topbar-sub { font-size: 11.5px; color: #9a8f84; margin-top: 1px; }
    .sa-topbar-actions { display: flex; gap: 8px; align-items: center; }
    .sa-btn { padding: 7px 14px; border-radius: 8px; font-size: 12.5px; font-weight: 600; cursor: pointer; border: none; display: inline-flex; align-items: center; gap: 5px; text-decoration: none; transition: opacity .12s; }
    .sa-btn:hover { opacity: .88; }
    .sa-btn-primary { background: #C62828; color: #fff; }
    .sa-btn-ghost { background: #F5F0EB; color: #1a1a1a; border: 1px solid #E0D8CF; }
    #sa-content { padding: 22px 24px; flex: 1; }

    /* ── Responsive ── */
    @media (max-width: 900px) {
      #sa-sidebar { transform: translateX(-100%); }
      #sa-sidebar.open { transform: translateX(0); }
      #sa-hamburger { display: flex; }
      #sa-main { margin-left: 0; }
      #sa-topbar { padding-left: 56px; }
    }
    @media (max-width: 480px) {
      #sa-content { padding: 14px; }
    }
  `;

  /* ── Sidebar HTML ─────────────────────────────────────────────────────── */
  const NAV = [
    { section: 'Main', items: [
      { id: 'dashboard',          icon: '⊞', label: 'Command Center',    href: 'dashboard.html' },
      { id: 'review-submissions', icon: '✓', label: 'Review Submissions', href: 'review-submissions.html', badge: 'submissions', badgeClass: '' },
      { id: 'manage-jobs',        icon: '📝', label: 'Manage Jobs',       href: 'manage-jobs.html' },
    ]},
    { section: 'Hubs', items: [
      { id: 'brand-hub',          icon: '🏷️', label: 'Brand Hub',         href: 'brand-hub.html' },
      { id: 'shelfer-hub',        icon: '👥', label: 'Shelfer Hub',       href: 'shelfer-hub.html', badge: 'shelfers', badgeClass: 'gold' },
      { id: 'prospect-pipeline',  icon: '📊', label: 'Prospect Pipeline', href: 'prospect-pipeline.html' },
    ]},
    { section: 'Intelligence', items: [
      { id: 'scan-intelligence',  icon: '🔍', label: 'Scan Intelligence', href: 'scan-intelligence.html' },
      { id: 'report-queue',       icon: '📈', label: 'Report Queue',      href: 'report-queue.html' },
    ]},
    { section: 'Settings', items: [
      { id: 'user-management',    icon: '⚙️', label: 'User Management',   href: 'user-management.html' },
      { id: 'help-support',       icon: '❓', label: 'Help & Support',    href: 'help-support.html' },
      { id: 'barcode-capture',    icon: '📷', label: 'Barcode Scanner',   href: 'barcode-capture.html' },
    ]},
  ];

  function buildSidebar() {
    let html = `<aside id="sa-sidebar">
  <div class="sb-logo">
    <div><div class="sb-logo-text">Shelf<span>Assured</span></div></div>
    <span class="sb-admin-badge">ADMIN</span>
  </div>`;
    NAV.forEach(group => {
      html += `<div class="sb-section"><div class="sb-section-label">${group.section}</div>`;
      group.items.forEach(item => {
        const active = item.id === pageId ? ' active' : '';
        const badgeHtml = item.badge
          ? `<span class="sb-badge ${item.badgeClass}" id="sa-badge-${item.badge}">0</span>`
          : '';
        html += `<a class="sb-link${active}" href="${item.href}"><span class="sb-icon">${item.icon}</span> ${item.label}${badgeHtml}</a>`;
      });
      html += `</div>`;
    });
    html += `
  <div class="sb-footer">
    <div class="sb-user">
      <div class="sb-avatar" id="sa-avatar">?</div>
      <div>
        <div class="sb-user-name" id="sa-user-name">Loading…</div>
        <div class="sb-user-role">Admin · ShelfAssured</div>
      </div>
    </div>
    <button class="sb-signout-btn" id="sa-signout">Sign Out</button>
  </div>
</aside>
<button id="sa-hamburger" aria-label="Open menu"><span></span><span></span><span></span></button>
<div id="sa-overlay"></div>`;
    return html;
  }

  function buildTopbar() {
    let actionsHtml = '';
    topbarActions.forEach(a => {
      const cls = a.primary ? 'sa-btn sa-btn-primary' : 'sa-btn sa-btn-ghost';
      actionsHtml += `<a class="${cls}" href="${a.href}">${a.label}</a>`;
    });
    return `<div id="sa-topbar">
  <div>
    <div class="sa-topbar-title">${pageTitle}</div>
    <div class="sa-topbar-sub" id="sa-topbar-sub">${pageSub}</div>
  </div>
  <div class="sa-topbar-actions">${actionsHtml}</div>
</div>`;
  }

  /* ── Inject into DOM ──────────────────────────────────────────────────── */
  function inject() {
    // Inject CSS
    const style = document.createElement('style');
    style.textContent = css;
    document.head.appendChild(style);

    // Wrap existing body content
    const existingContent = document.body.innerHTML;
    document.body.innerHTML =
      buildSidebar() +
      `<div id="sa-main">${buildTopbar()}<div id="sa-content">${existingContent}</div></div>`;

    // Wire hamburger
    const sidebar   = document.getElementById('sa-sidebar');
    const overlay   = document.getElementById('sa-overlay');
    const hamburger = document.getElementById('sa-hamburger');
    hamburger.addEventListener('click', () => { sidebar.classList.toggle('open'); overlay.classList.toggle('open'); });
    overlay.addEventListener('click',   () => { sidebar.classList.remove('open'); overlay.classList.remove('open'); });

    // Wire sign-out
    document.getElementById('sa-signout').addEventListener('click', async () => {
      try {
        const sb = window.supabase || (window._supabase);
        if (sb) await sb.auth.signOut();
      } catch(e) {}
      window.location.href = '../index.html';
    });

    // Populate user info from Supabase session
    function populateUser() {
      const sb = window.supabase || window._supabase;
      if (!sb) { setTimeout(populateUser, 300); return; }
      sb.auth.getUser().then(({ data }) => {
        if (!data?.user) return;
        const meta = data.user.user_metadata || {};
        const name = meta.full_name || meta.name || data.user.email?.split('@')[0] || '?';
        const initials = name.split(' ').map(w => w[0]).join('').slice(0,2).toUpperCase();
        const avatarEl = document.getElementById('sa-avatar');
        const nameEl   = document.getElementById('sa-user-name');
        if (avatarEl) avatarEl.textContent = initials;
        if (nameEl)   nameEl.textContent   = name;
      });
    }
    populateUser();

    // Load badge counts
    function loadBadges() {
      const sb = window.supabase || window._supabase;
      if (!sb) { setTimeout(loadBadges, 400); return; }
      // Pending submissions badge
      sb.from('job_submissions').select('id', { count: 'exact', head: true }).eq('status', 'pending_review').then(({ count }) => {
        if (count > 0) {
          const el = document.getElementById('sa-badge-submissions');
          if (el) { el.textContent = count; el.classList.add('show'); }
        }
      });
      // Pending shelfer approvals badge
      sb.from('users').select('id', { count: 'exact', head: true }).eq('role', 'shelfer').eq('approval_status', 'pending').then(({ count }) => {
        if (count > 0) {
          const el = document.getElementById('sa-badge-shelfers');
          if (el) { el.textContent = count; el.classList.add('show'); }
        }
      });
    }
    loadBadges();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', inject);
  } else {
    inject();
  }
})();
