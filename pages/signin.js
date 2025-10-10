// pages/signin.js - Signin page functionality

// Handle forgot password
window.handleForgotPassword = async function() {
    const email = document.getElementById('login-email').value;
    const messageEl = document.getElementById('signin-message');
    
    if (!email) {
        showMessage(messageEl, 'Please enter your email address first', 'error');
        return;
    }
    
    showMessage(messageEl, 'Sending password reset email...', 'info');
    
    try {
        // Pick base depending on where the app is running
        const SA_BASE = location.origin.includes('localhost')
            ? 'http://localhost:8000'
            : 'https://courtneybhenderu-prog.github.io/shelfassured-demo';
            
        const { error } = await supabase.auth.resetPasswordForEmail(email.trim().toLowerCase(), {
            redirectTo: `${SA_BASE}/auth/confirmed.html`
        });
        
        if (error) {
            console.error('❌ Password reset failed:', error);
            showMessage(messageEl, 'Error: ' + error.message, 'error');
        } else {
            showMessage(messageEl, 'Password reset email sent! Check your inbox.', 'success');
        }
    } catch (error) {
        console.error('❌ Password reset error:', error);
        showMessage(messageEl, 'Error: ' + error.message, 'error');
    }
};

// Handle form submission
document.getElementById('signin-form').addEventListener('submit', async function(e) {
    e.preventDefault();
    
    const email = document.getElementById('login-email').value;
    const password = document.getElementById('login-password').value;
    const messageEl = document.getElementById('signin-message');

    if (!email || !password) {
        showMessage(messageEl, 'Please enter both email and password', 'error');
        return;
    }

    showMessage(messageEl, 'Signing in...', 'info');

    try {
        const result = await saSignIn(email, password);

        if (result.success) {
            showMessage(messageEl, 'Signed in successfully!', 'success');
            console.log('✅ Signed in successfully');
            
            // Ensure profile exists and get role
            console.log('🔄 Calling ensureProfile...');
            const profile = await ensureProfile(result.data.user);
            console.log('📋 Profile result:', profile);
            console.log('🔍 Profile role:', profile.role);
            console.log('🔍 Profile data:', JSON.stringify(profile, null, 2));
            
            if (!profile) {
                showMessage(messageEl, 'Error: Could not load user profile', 'error');
                return;
            }
            console.log('✅ Profile loaded successfully, checking approval status...');
            
            // Check approval status for shelfers
            if (profile.role === 'shelfer' && profile.approval_status !== 'approved') {
                console.log('⏳ Shelfer account pending approval, redirecting to pending page');
                setTimeout(() => goToPage('../auth/pending-approval.html'), 1000);
                return;
            }
            
            // Role-based redirection
            let redirectPage;
            if (profile.role === 'admin') {
                redirectPage = '../admin/dashboard.html';
            } else if (profile.role === 'brand_client') {
                redirectPage = '../dashboard/brand-client.html';
            } else {
                redirectPage = '../dashboard/shelfer.html';
            }
            
            console.log(`🎯 Redirecting ${profile.role} user to:`, redirectPage);
            setTimeout(() => goToPage(redirectPage), 1000);
        } else if (result.needsConfirmation) {
            showMessage(messageEl, result.error, 'error');
            console.log('❌ Email confirmation required');
        } else {
            console.error('❌ Sign in failed:', result.error);
            showMessage(messageEl, 'Sign in failed: ' + result.error, 'error');
        }
    } catch (error) {
        console.error('❌ Sign in error:', error);
        showMessage(messageEl, 'Error: ' + error.message, 'error');
    }
});
