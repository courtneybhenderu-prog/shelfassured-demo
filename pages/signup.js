// pages/signup.js - Signup page functionality

// Password strength validation
function validatePasswordStrength(password) {
    const requirements = {
        length: password.length >= 8,
        uppercase: /[A-Z]/.test(password),
        lowercase: /[a-z]/.test(password),
        number: /[0-9]/.test(password),
        special: /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password)
    };
    
    // Update visual indicators
    updateRequirementIndicator('req-length', requirements.length);
    updateRequirementIndicator('req-uppercase', requirements.uppercase);
    updateRequirementIndicator('req-lowercase', requirements.lowercase);
    updateRequirementIndicator('req-number', requirements.number);
    updateRequirementIndicator('req-special', requirements.special);
    
    return Object.values(requirements).every(req => req);
}

function updateRequirementIndicator(elementId, isValid) {
    const element = document.getElementById(elementId);
    const icon = element.querySelector('span');
    if (isValid) {
        icon.textContent = '✅';
        icon.className = 'w-4 h-4 mr-2 text-green-500';
    } else {
        icon.textContent = '○';
        icon.className = 'w-4 h-4 mr-2 text-gray-400';
    }
}

// Real-time password confirmation validation
function validatePasswordMatch() {
    const password = document.getElementById('signup-password').value;
    const confirmPassword = document.getElementById('signup-confirm-password').value;
    const messageEl = document.getElementById('signup-message');
    
    if (confirmPassword && password !== confirmPassword) {
        showMessage(messageEl, 'Passwords do not match', 'error');
    } else if (confirmPassword && password === confirmPassword) {
        showMessage(messageEl, 'Passwords match!', 'success');
    } else {
        messageEl.classList.add('hidden');
    }
}

// Add event listeners for both password fields
document.getElementById('signup-password').addEventListener('input', function() {
    validatePasswordStrength(this.value);
    validatePasswordMatch();
});
document.getElementById('signup-confirm-password').addEventListener('input', validatePasswordMatch);

// Handle form submission
document.getElementById('signup-form').addEventListener('submit', async function(e) {
    e.preventDefault();
    
    const email = document.getElementById('signup-email').value;
    const password = document.getElementById('signup-password').value;
    const confirmPassword = document.getElementById('signup-confirm-password').value;
    const fullName = document.getElementById('signup-name').value;
    const phone = document.getElementById('signup-phone').value;
    const role = document.getElementById('signup-role').value;
    const messageEl = document.getElementById('signup-message');

    // Basic validation
    if (!email || !password || !confirmPassword || !fullName || !role) {
        showMessage(messageEl, 'Please fill in all required fields', 'error');
        return;
    }

    if (!validatePasswordStrength(password)) {
        showMessage(messageEl, 'Password does not meet security requirements. Please check the requirements above.', 'error');
        return;
    }

    if (password !== confirmPassword) {
        showMessage(messageEl, 'Passwords do not match. Please try again.', 'error');
        return;
    }

    showMessage(messageEl, 'Creating account...', 'info');

    try {
        console.log('🔄 Attempting to create account...', { email, role });
        
        const result = await saSignUp(email, password, {
            full_name: fullName,
            phone: phone,
            role: role
        });

        console.log('📋 Signup result:', result);

        if (result.success) {
            showMessage(messageEl, 'Account created successfully! Please check your email to verify your account.', 'success');
            console.log('✅ Account created successfully');
            
            // Redirect to email confirmation page instead of dashboard
            setTimeout(() => goToPage('../auth/email-confirmation-sent.html'), 2000);
        } else {
            console.error('❌ Signup failed:', result.error);
            showMessage(messageEl, 'Error: ' + result.error, 'error');
        }
    } catch (error) {
        console.error('❌ Signup error:', error);
        showMessage(messageEl, 'Error: ' + error.message, 'error');
    }
});
