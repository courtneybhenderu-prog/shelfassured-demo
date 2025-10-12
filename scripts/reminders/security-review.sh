#!/bin/bash
# Security Review Reminder Script
# Run this monthly to remind team to complete security review

echo "🔐 Time for your Monthly Security Review!"
echo "=========================================="
echo ""
echo "📋 Checklist: docs/security-review-checklist.md"
echo "⏱️  Estimated time: 30 minutes"
echo "🎯 Focus: Phase 1 items + any new security concerns"
echo ""
echo "📅 Last review: $(date -d '1 month ago' '+%Y-%m-%d')"
echo "📅 Today's date: $(date '+%Y-%m-%d')"
echo ""
echo "🚨 Critical items to check:"
echo "  ✅ API key security"
echo "  ✅ Database RLS policies"
echo "  ✅ Authentication flows"
echo "  ✅ User access controls"
echo ""
echo "📞 Need help? Check docs/security-quick-reference.md"
echo ""
echo "Press Enter to mark review as started..."
read
echo "✅ Security review started at $(date '+%Y-%m-%d %H:%M')"
