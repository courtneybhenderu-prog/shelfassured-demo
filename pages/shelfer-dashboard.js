// pages/shelfer-dashboard.js - Shelfer dashboard functionality

// Load dashboard data
async function loadDashboard() {
    try {
        console.log('🔄 Loading dashboard data...');
        
        // Load jobs
        const jobs = await saGet('jobs', []);
        console.log('📊 Jobs loaded:', jobs);
        
        // Update UI
        document.getElementById('available-jobs').textContent = jobs.length;
        
        // Render jobs
        const jobsList = document.getElementById('jobs-list');
        if (jobs.length === 0) {
            jobsList.innerHTML = saEmptyState('No jobs available', 'Check back later for new opportunities');
        } else {
            jobsList.innerHTML = jobs.map(job => `
                <div class="sa-card p-4 cursor-pointer" onclick="viewJob('${job.id}')">
                    <h4 class="font-semibold">${job.title}</h4>
                    <p class="text-sm text-gray-600">${job.brands?.name || 'Unknown Brand'}</p>
                    <p class="text-sm text-gray-600">$${job.total_payout || 0} total</p>
                    <span class="inline-block px-2 py-1 bg-yellow-100 text-yellow-800 rounded text-xs mt-2">${job.status}</span>
                </div>
            `).join('');
        }
        
    } catch (error) {
        console.error('❌ Error loading dashboard:', error);
        document.getElementById('jobs-list').innerHTML = saEmptyState('Error loading jobs', 'Please try again later');
    }
}

function viewJob(jobId) {
    console.log('Viewing job:', jobId);
    // Navigate to job details page
    goToPage(`../jobs/details.html?id=${jobId}`);
}

// Load dashboard when page loads
document.addEventListener('DOMContentLoaded', loadDashboard);
