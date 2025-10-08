// pages/signin.js - Signin page functionality

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
            
            // For now, redirect to shelfer dashboard (we'll add role detection later)
            setTimeout(() => goToPage('../dashboard/shelfer.html'), 1000);
        } else {
            console.error('❌ Sign in failed:', result.error);
            showMessage(messageEl, 'Sign in failed: ' + result.error, 'error');
        }
    } catch (error) {
        console.error('❌ Sign in error:', error);
        showMessage(messageEl, 'Error: ' + error.message, 'error');
    }
});
