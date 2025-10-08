// pages/reset-password.js - Password reset functionality

// Handle form submission
document.getElementById('reset-password-form').addEventListener('submit', async function(e) {
    e.preventDefault();
    
    const newPassword = document.getElementById('new-password').value;
    const confirmPassword = document.getElementById('confirm-password').value;
    const messageEl = document.getElementById('reset-message');

    // Basic validation
    if (!newPassword || !confirmPassword) {
        showMessage(messageEl, 'Please fill in all fields', 'error');
        return;
    }

    if (newPassword.length < 6) {
        showMessage(messageEl, 'Password must be at least 6 characters', 'error');
        return;
    }

    if (newPassword !== confirmPassword) {
        showMessage(messageEl, 'Passwords do not match', 'error');
        return;
    }

    showMessage(messageEl, 'Updating password...', 'info');

    try {
        // Get URL parameters for reset token
        const urlParams = new URLSearchParams(window.location.search);
        const accessToken = urlParams.get('access_token');
        const refreshToken = urlParams.get('refresh_token');

        if (!accessToken) {
            showMessage(messageEl, 'Invalid reset link. Please request a new password reset.', 'error');
            return;
        }

        // Update password using Supabase
        const { error } = await supabase.auth.updateUser({
            password: newPassword
        });

        if (error) {
            console.error('❌ Password update failed:', error);
            showMessage(messageEl, 'Error: ' + error.message, 'error');
        } else {
            showMessage(messageEl, 'Password updated successfully! You can now sign in.', 'success');
            console.log('✅ Password updated successfully');
            setTimeout(() => goToPage('signin.html'), 2000);
        }
    } catch (error) {
        console.error('❌ Password reset error:', error);
        showMessage(messageEl, 'Error: ' + error.message, 'error');
    }
});
