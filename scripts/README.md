# 📋 Security Review Automation Scripts

This directory contains automation scripts for maintaining security reviews.

## 🚀 Quick Setup

### 1. Monthly Reminders (GitHub Action)
The GitHub Action automatically:
- Creates a monthly security review issue
- Updates the "Last Reviewed" date in the checklist
- Sends notifications to the team

**No setup required** - it runs automatically on the 1st of each month.

### 2. Local Scripts (Optional)
If you prefer local reminders:

```bash
# Monthly reminder (run manually or via cron)
./scripts/reminders/security-review.sh

# Quarterly deep review (run manually or via cron)
./scripts/reminders/security-deep-review.sh
```

### 3. Cron Job Setup (Optional)
Add to your crontab for automatic local reminders:

```bash
# Monthly security review reminder (1st of each month at 9 AM)
0 9 1 * * bash ~/projects/shelfassured/scripts/reminders/security-review.sh

# Quarterly deep review (1st of each quarter at 9 AM)
0 9 1 1,4,7,10 * bash ~/projects/shelfassured/scripts/reminders/security-deep-review.sh
```

## 📅 Review Schedule

| Frequency | Type | Time Required | Automation |
|-----------|------|---------------|------------|
| **Monthly** | Quick Review | 30 minutes | GitHub Action |
| **Quarterly** | Deep Review | 2 hours | Manual trigger |

## 🎯 What Gets Automated

- ✅ **Monthly reminders** via GitHub issues
- ✅ **Date tracking** in documentation
- ✅ **Review logging** for audit trail
- ✅ **Issue creation** with proper labels
- ✅ **Documentation updates** automatically

## 🔧 Manual Override

You can always run reviews manually:
- **Monthly:** Complete the checklist in `docs/security-review-checklist.md`
- **Quarterly:** Run the deep review script and complete Phase 3 items

## 📞 Support

- **GitHub Action issues:** Check the Actions tab in your repository
- **Script problems:** Check file permissions (`chmod +x`)
- **Cron issues:** Check your system's cron service

---

**Remember: Automation is a tool to help you stay on track, not a replacement for thorough security reviews!**
