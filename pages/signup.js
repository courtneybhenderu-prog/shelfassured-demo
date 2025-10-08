// pages/signup.js - Signup page functionality

// Handle form submission
document.getElementById('signup-form').addEventListener('submit', async function(e) {
    e.preventDefault();
    
    const email = document.getElementById('signup-email').value;
    const password = document.getElementById('signup-password').value;
    const fullName = document.getElementById('signup-name').value;
    const phone = document.getElementById('signup-phone').value;
    const role = document.getElementById('signup-role').value;
    const messageEl = document.getElementById('signup-message');

    // Basic validation
    if (!email || !password || !fullName || !role) {
        showMessage(messageEl, 'Please fill in all required fields', 'error');
        return;
    }

    if (password.length < 6) {
        showMessage(messageEl, 'Password must be at least 6 characters', 'error');
        return;
    }

    showMessage(messageEl, 'Creating account...', 'info');

    try {
        console.log('🔄 Attempting to create account...', { email, role });
        
        const result = await saSignUp(email, password, {
            fullName: fullName,
            phone: phone,
            role: role
        });

        console.log('📋 Signup result:', result);

        if (result.success) {
            showMessage(messageEl, 'Account created successfully! Please check your email to verify your account.', 'success');
            console.log('✅ Account created successfully');
            
            // Redirect based on role
            const redirectPage = role === 'brand_client' ? '../dashboard/brand-client.html' : '../dashboard/shelfer.html';
            setTimeout(() => goToPage(redirectPage), 2000);
        } else {
            console.error('❌ Signup failed:', result.error);
            showMessage(messageEl, 'Error: ' + result.error, 'error');
        }
    } catch (error) {
        console.error('❌ Signup error:', error);
        showMessage(messageEl, 'Error: ' + error.message, 'error');
    }
});
