# 🔒 Security Review Checklist

**A practical, phased security audit system for small teams.**

## Quick Start
- **Phase 1:** Immediate fixes (30 min) - API keys, RLS, authentication
- **Phase 2:** Short-term improvements (1-2 hours) - Validation, error handling
- **Phase 3:** Medium-term hardening (2-4 hours) - Headers, monitoring

## Critical Tests
- ✅ **Email confirmation** - Unconfirmed users blocked
- ✅ **Role-based access** - Admin/shelfer/brand_client isolation
- ✅ **Data isolation** - Users can't access other users' data
- ✅ **API security** - Protected endpoints require authentication

## Monthly Review (30 minutes)
- Review security logs for unusual activity
- Update dependencies and apply patches
- Test authentication flows
- Verify role-based access

## Emergency Response
- **Security Issues:** [Contact info]
- **Supabase Support:** [Contact info]
- **GitHub Security:** [Contact info]

[📖 Full Security Checklist](docs/security-review-checklist.md)
