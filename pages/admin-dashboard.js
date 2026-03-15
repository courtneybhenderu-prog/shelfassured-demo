// pages/admin-dashboard.js — Admin Command Center

let currentUser = null;
let userProfile = null;

// ── Bootstrap ────────────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', async function () {
    // Wait for Supabase client
    let attempts = 0;
    while (!window.saClient && attempts < 20) {
        await new Promise(r => setTimeout(r, 100));
        attempts++;
    }
    if (!window.saClient) {
        window.location.href = '../auth/signin.html';
        return;
    }
    await initializeDashboard();
});

async function initializeDashboard() {
    try {
        const { data: { session } } = await (window.saClient || supabase).auth.getSession();
        if (!session) {
            window.location.href = '../auth/signin.html';
            return;
        }
        currentUser = session.user;

        // Load profile (non-blocking)
        const { data: profile } = await (window.saClient || supabase)
            .from('users')
            .select('role, full_name, approval_status')
            .eq('id', session.user.id)
            .single();

        userProfile = profile || { role: 'admin', full_name: session.user.email };

        // Update welcome name in nav if element exists
        const adminUserEl = document.getElementById('admin-user');
        if (adminUserEl) adminUserEl.textContent = `Welcome, ${userProfile.full_name || currentUser.email}`;

        // Show Marc's personalized welcome banner
        if (currentUser.email === 'marc@beshelfassured.com') {
            const banner = document.getElementById('marc-welcome-banner');
            if (banner) banner.classList.remove('hidden');
        }

        await loadDashboardData();
    } catch (err) {
        console.error('Dashboard init error:', err);
    }
}

async function loadDashboardData() {
    try {
        const supabaseClient = window.saClient || supabase;

        // Parallel data fetch
        const [
            { data: jobs },
            { data: users },
            { data: auditRequests },
            { data: helpRequests },
            { data: brands }
        ] = await Promise.all([
            supabaseClient.from('jobs').select('id, title, status, created_at, total_payout, client_id').order('created_at', { ascending: false }),
            supabaseClient.from('users').select('id, full_name, email, role, is_active, approval_status, created_at').order('created_at', { ascending: false }),
            supabaseClient.from('audit_requests').select('id, title, audit_type, status, created_at, client_id').order('created_at', { ascending: false }),
            supabaseClient.from('help_requests').select('id, subject, status, priority, created_at').eq('status', 'open').order('created_at', { ascending: false }),
            supabaseClient.from('brands').select('id, is_shadow')
        ]);

        const allJobs        = jobs || [];
        const allUsers       = users || [];
        const allAuditReqs   = auditRequests || [];
        const openHelpReqs   = helpRequests || [];
        const allBrands      = brands || [];

        updateStats(allJobs, allUsers, allBrands);
        buildFlags(allJobs, allUsers, allAuditReqs, openHelpReqs);
        buildRecentJobs(allJobs.slice(0, 6));
        buildAuditRequests(allAuditReqs.filter(r => r.status === 'pending_review').slice(0, 5));

        const now = new Date();
        const el = document.getElementById('last-updated');
        if (el) el.textContent = `Last updated ${now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`;

    } catch (err) {
        console.error('Error loading dashboard data:', err);
    }
}

// ── Stats ────────────────────────────────────────────────────────────────────
function updateStats(jobs, users, brands) {
    const completed     = jobs.filter(j => j.status === 'completed').length;
    const shelfers      = users.filter(u => u.role === 'shelfer' && u.approval_status === 'approved').length;
    const clientBrands  = brands.filter(b => !b.is_shadow).length;
    const shadowBrands  = brands.filter(b => b.is_shadow).length;

    setText('stat-total-jobs', jobs.length);
    setText('stat-completed',  completed);
    setText('stat-shelfers',   shelfers);
    setText('stat-brands',     clientBrands);

    const sub = document.getElementById('stat-brands-sub');
    if (sub) sub.textContent = shadowBrands > 0 ? `+ ${shadowBrands} scanned` : 'Clients';
}

// ── Flags ────────────────────────────────────────────────────────────────────
function buildFlags(jobs, users, auditRequests, helpRequests) {
    const flags = [];
    const now = Date.now();
    const HOURS = h => h * 60 * 60 * 1000;

    // 1. Jobs not accepted within 48 business hours
    const unaccepted = jobs.filter(j => {
        if (j.status !== 'pending') return false;
        const age = now - new Date(j.created_at).getTime();
        return age > HOURS(48);
    });
    if (unaccepted.length > 0) {
        flags.push({
            level: 'urgent',
            label: 'Jobs not accepted',
            detail: `${unaccepted.length} job${unaccepted.length > 1 ? 's' : ''} posted over 48 business hours ago with no shelfer assigned`,
            action: 'manage-jobs.html',
            actionLabel: 'Review Jobs'
        });
    }

    // 2. Jobs accepted but stalled (assigned > 48 hours, not submitted)
    const stalled = jobs.filter(j => {
        if (j.status !== 'assigned') return false;
        const age = now - new Date(j.created_at).getTime();
        return age > HOURS(48);
    });
    if (stalled.length > 0) {
        flags.push({
            level: 'urgent',
            label: 'Stalled jobs',
            detail: `${stalled.length} job${stalled.length > 1 ? 's' : ''} accepted but not completed after 48 hours`,
            action: 'manage-jobs.html',
            actionLabel: 'Review Jobs'
        });
    }

    // 3. Open help tickets
    if (helpRequests.length > 0) {
        flags.push({
            level: 'warning',
            label: 'Open help tickets',
            detail: `${helpRequests.length} unresolved support request${helpRequests.length > 1 ? 's' : ''} awaiting response`,
            action: 'help-support.html',
            actionLabel: 'View Tickets'
        });
    }

    // 4. Pending audit requests — tiered urgency based on 48 business hour SLA
    const pendingAudits = auditRequests.filter(r => r.status === 'pending_review');
    const overdueAudits = pendingAudits.filter(r => {
        const age = now - new Date(r.created_at).getTime();
        return age > HOURS(48);
    });
    const approachingAudits = pendingAudits.filter(r => {
        const age = now - new Date(r.created_at).getTime();
        return age > HOURS(36) && age <= HOURS(48);
    });
    if (overdueAudits.length > 0) {
        flags.push({
            level: 'urgent',
            label: 'Overdue audit requests',
            detail: `${overdueAudits.length} audit request${overdueAudits.length > 1 ? 's have' : ' has'} exceeded the 48 business hour response window — respond now`,
            action: 'brand-hub.html',
            actionLabel: 'View Requests'
        });
    } else if (approachingAudits.length > 0) {
        flags.push({
            level: 'warning',
            label: 'Audit requests approaching deadline',
            detail: `${approachingAudits.length} audit request${approachingAudits.length > 1 ? 's are' : ' is'} approaching the 48 business hour response window`,
            action: 'brand-hub.html',
            actionLabel: 'View Requests'
        });
    } else if (pendingAudits.length > 0) {
        flags.push({
            level: 'warning',
            label: 'Pending audit requests',
            detail: `${pendingAudits.length} custom audit request${pendingAudits.length > 1 ? 's' : ''} need pricing and response within 48 business hours`,
            action: 'brand-hub.html',
            actionLabel: 'View Requests'
        });
    }

    // 5. Shelfers awaiting approval
    const pendingShelfers = users.filter(u => u.role === 'shelfer' && u.approval_status === 'pending');
    if (pendingShelfers.length > 0) {
        flags.push({
            level: 'info',
            label: 'Shelfers awaiting approval',
            detail: `${pendingShelfers.length} new shelfer${pendingShelfers.length > 1 ? 's' : ''} registered and pending review`,
            action: 'shelfer-hub.html',
            actionLabel: 'Review Shelfers'
        });
    }

    // 5b. Exception-reported jobs
    const exceptionJobs = jobs.filter(j => j.status === 'exception_reported');
    if (exceptionJobs.length > 0) {
        flags.push({
            level: 'warning',
            label: 'Exception reports',
            detail: `${exceptionJobs.length} job${exceptionJobs.length > 1 ? 's' : ''} flagged by shelfers as unable to complete — product not found, wrong item, or out of stock`,
            action: 'manage-jobs.html',
            actionLabel: 'Review Exceptions'
        });
    }

    // 6. New brand signups (last 7 days)
    const newBrands = users.filter(u => {
        if (u.role !== 'brand_client') return false;
        const age = now - new Date(u.created_at).getTime();
        return age < HOURS(24 * 7);
    });
    if (newBrands.length > 0) {
        flags.push({
            level: 'info',
            label: 'New brand signups',
            detail: `${newBrands.length} brand${newBrands.length > 1 ? 's' : ''} joined in the last 7 days`,
            action: 'brand-hub.html',
            actionLabel: 'View Brands'
        });
    }

    const container = document.getElementById('flags-container');
    const countEl   = document.getElementById('flags-count');
    if (!container) return;

    if (flags.length === 0) {
        container.innerHTML = `
            <div class="bg-white rounded-lg p-5 text-center">
                <div class="w-3 h-3 bg-green-400 rounded-full inline-block mb-2"></div>
                <p class="text-sm font-medium text-gray-700">All clear — no items need attention right now.</p>
            </div>`;
        if (countEl) countEl.textContent = '0 flags';
        return;
    }

    if (countEl) countEl.textContent = `${flags.length} flag${flags.length > 1 ? 's' : ''}`;

    const urgentCount  = flags.filter(f => f.level === 'urgent').length;
    const warningCount = flags.filter(f => f.level === 'warning').length;

    container.innerHTML = flags.map(f => `
        <div class="flag-card flag-${f.level} bg-white rounded-lg p-4 flex items-start justify-between gap-4">
            <div class="flex-1">
                <p class="text-sm font-semibold text-gray-900">${escapeHtml(f.label)}</p>
                <p class="text-xs text-gray-500 mt-1">${escapeHtml(f.detail)}</p>
            </div>
            <a href="${f.action}" class="shrink-0 text-xs font-medium text-[#C62828] hover:underline whitespace-nowrap">${f.actionLabel}</a>
        </div>
    `).join('');
}

// ── Recent Jobs ──────────────────────────────────────────────────────────────
function buildRecentJobs(jobs) {
    const container = document.getElementById('recent-jobs');
    if (!container) return;

    if (jobs.length === 0) {
        container.innerHTML = '<div class="p-4 text-center text-gray-400 text-sm">No jobs yet</div>';
        return;
    }

    container.innerHTML = jobs.map(job => {
        const statusColor = {
            completed:          'text-green-600',
            assigned:           'text-blue-600',
            pending:            'text-orange-500',
            pending_review:     'text-blue-600',
            exception_reported: 'text-amber-600',
            cancelled:          'text-red-500'
        }[job.status] || 'text-gray-500';
        const statusLabel = {
            pending_review:     'Pending Review',
            exception_reported: '⚠️ Exception Reported',
            completed:          'Completed',
            assigned:           'Assigned',
            pending:            'Pending',
            cancelled:          'Cancelled'
        }[job.status] || capitalize(job.status || 'unknown');

        return `
        <div class="px-4 py-3 hover:bg-gray-50 cursor-pointer" onclick="goToPage('../dashboard/job-details.html?job_id=${job.id}')">
            <div class="flex items-center justify-between">
                <div class="flex-1 min-w-0">
                    <p class="text-sm font-medium text-gray-900 truncate">${escapeHtml(job.title || 'Untitled Job')}</p>
                    <p class="text-xs mt-0.5">
                        <span class="font-medium ${statusColor}">${statusLabel}</span>
                        <span class="text-gray-400 ml-2">${timeAgo(job.created_at)}</span>
                    </p>
                </div>
                <span class="text-sm font-semibold text-gray-700 ml-3">$${job.total_payout || 0}</span>
            </div>
        </div>`;
    }).join('');
}

// ── Audit Requests ───────────────────────────────────────────────────────────
function buildAuditRequests(requests) {
    const container = document.getElementById('audit-requests');
    if (!container) return;

    if (requests.length === 0) {
        container.innerHTML = '<div class="p-4 text-center text-gray-400 text-sm">No pending audit requests</div>';
        return;
    }

    container.innerHTML = requests.map(r => `
        <div class="px-4 py-3 hover:bg-gray-50">
            <div class="flex items-center justify-between">
                <div class="flex-1 min-w-0">
                    <p class="text-sm font-medium text-gray-900 truncate">${escapeHtml(r.title || 'Untitled Request')}</p>
                    <p class="text-xs text-gray-500 mt-0.5">${escapeHtml(r.audit_type || '')} &middot; ${timeAgo(r.created_at)}</p>
                </div>
                <span class="ml-3 px-2 py-0.5 text-xs font-semibold rounded-full bg-orange-100 text-orange-700">Pending</span>
            </div>
        </div>
    `).join('');
}

// ── Helpers ──────────────────────────────────────────────────────────────────
function setText(id, value) {
    const el = document.getElementById(id);
    if (el) el.textContent = value;
}

function escapeHtml(text) {
    if (text == null) return '';
    const d = document.createElement('div');
    d.textContent = String(text);
    return d.innerHTML;
}

function capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1);
}

function timeAgo(dateStr) {
    if (!dateStr) return '';
    const diff = Date.now() - new Date(dateStr).getTime();
    const mins  = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days  = Math.floor(diff / 86400000);
    if (mins < 60)  return `${mins}m ago`;
    if (hours < 24) return `${hours}h ago`;
    return `${days}d ago`;
}

async function refreshDashboard() {
    const el = document.getElementById('last-updated');
    if (el) el.textContent = 'Refreshing...';
    await loadDashboardData();
}

async function handleSignOut() {
    try {
        await (window.saClient || supabase).auth.signOut();
    } catch (_) {}
    window.location.href = '../auth/signin.html';
}

function goToPage(page) { window.location.href = page; }
window.goToPage = goToPage;
window.refreshDashboard = refreshDashboard;
