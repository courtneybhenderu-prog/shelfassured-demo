# Submission Review System - Technical Specification

## ✅ What We Have

### Database Structure
1. **`job_submissions` table** - Fully set up with:
   - `id`, `job_id`, `contractor_id` (shelfer)
   - `submission_type`, `data` (JSONB with price, stock_level, notes, captured_at, device)
   - `files` (JSONB array with photos - URLs or base64)
   - `is_validated`, `validated_by`, `validated_at`, `validation_notes`

2. **`jobs` table** - Has:
   - Status values: `pending`, `assigned`, `pending_review`, `completed`, `rejected`
   - `payout_per_store`, `total_payout`
   - Links to `brands`, `stores`, `skus`

3. **`payments` table** - Exists with:
   - `job_id`, `contractor_id`, `amount`, `status`
   - Status values: `pending`, `processing`, `completed`, `failed`, `cancelled`

### Current Implementation
- ✅ Basic review page structure
- ✅ Photo display (supports both storage URLs and base64)
- ✅ Approve/reject functionality
- ✅ Status filtering
- ✅ Connection to jobs and brands

---

## ❓ What We Need to Clarify

### 1. **Approval Workflow**
**Question:** What happens when a submission is approved?
- [ ] Job status changes to `completed`? ✅ (currently implemented)
- [ ] Payment record created automatically? ⚠️ (TODO in code)
- [ ] Payment amount = `jobs.payout_per_store`? Or something else?
- [ ] Payment status = `pending` or `completed` immediately?
- [ ] Should we create one payment per job, or per submission?
- [ ] Should shelfer/brand get notifications?

**Recommendation:** 
- Create payment record on approve
- Set amount = `jobs.payout_per_store` (from job)
- Set status = `pending` (admin processes later)
- Send notification to shelfer

### 2. **Rejection Workflow**
**Question:** What happens when rejected?
- [ ] Job status goes back to `pending`? ✅ (currently implemented)
- [ ] Should shelfer be able to resubmit?
- [ ] Does job need to be reassigned?
- [ ] Should shelfer get notification with rejection reason?

**Recommendation:**
- Job status → `pending` (allows resubmission)
- Send notification with `validation_notes`
- Keep submission record for audit trail

### 3. **RLS Policies** (Row Level Security)
**Question:** Can admins read `job_submissions`?
- Need to verify RLS policies allow admin access
- Need to verify admins can update `is_validated`, `validation_notes`

**Action Required:**
```sql
-- Check if this policy exists
SELECT * FROM pg_policies 
WHERE tablename = 'job_submissions' 
AND policyname LIKE '%admin%';
```

### 4. **Missing Data Display**
**Current Implementation Shows:**
- ✅ Job title, brand name, shelfer name
- ✅ Submission date, stock level, price, notes
- ✅ Photos (with modal view)

**Missing:**
- ❓ Store name/location (submission has `store_id` but not displayed)
- ❓ Product/SKU info (submission has `sku_id` but not displayed)
- ❓ Job payout amount (to show what shelfer will earn)
- ❓ Link to original job details

**Recommendation:** Add these fields to display

### 5. **Connected Pages**
**Question:** Where should this page link to?

**Current Links:**
- ✅ Back to admin dashboard

**Should Link To:**
- [ ] Job details page (view original job requirements)
- [ ] Shelfer profile (view shelfer's submission history)
- [ ] Brand dashboard (brand can see approved submissions)
- [ ] Payment processing page (for approved submissions)

### 6. **Quality Control Features**
**Current:** Basic approve/reject with notes

**Could Add:**
- [ ] Quality score/rating (1-5 stars)
- [ ] Photo quality checks (blur, lighting, readability)
- [ ] Data validation (price reasonable? stock level matches photo?)
- [ ] Batch approval (approve multiple at once)
- [ ] Export for reporting

### 7. **Payment Processing**
**Current:** TODO comment in code

**Questions:**
- [ ] Manual payout processing or automatic?
- [ ] Integration with payment gateway (Stripe, PayPal)?
- [ ] Payment scheduling (daily, weekly, monthly)?
- [ ] Payment history page needed?

**Recommendation for MVP:**
- Create payment record on approve (status = `pending`)
- Build separate "Payment Processing" page later
- Admin manually marks payments as `completed`

---

## 📋 Implementation Checklist

### Phase 1: Core Functionality (Current)
- [x] Display pending submissions
- [x] Show photos (storage URL or base64)
- [x] Approve/reject with notes
- [x] Update job status
- [ ] **CREATE PAYMENT RECORD** (need to implement)

### Phase 2: Enhanced Display
- [ ] Add store name/location
- [ ] Add product/SKU info
- [ ] Add payout amount display
- [ ] Add link to job details page

### Phase 3: Workflow
- [ ] Create payment records on approve
- [ ] Send notifications to shelfer/brand
- [ ] Add quality control ratings
- [ ] Batch operations

### Phase 4: Reporting
- [ ] Export submissions for reporting
- [ ] Quality metrics dashboard
- [ ] Payment reconciliation

---

## 🔗 Connected Pages

### Pages That Should Link HERE:
1. **Admin Dashboard** → "Review Submissions" button (already exists)
2. **Job Details Page** → "Review Submission" (if status = pending_review)
3. **Brand Dashboard** → "View Approved Submissions"

### Pages This Should Link TO:
1. **Job Details** (`admin/manage-jobs.html?edit_job_id={job_id}`)
2. **Shelfer Profile** (`admin/users.html?user_id={contractor_id}`)
3. **Payment Processing** (`admin/payments.html?submission_id={id}`) - doesn't exist yet

---

## 🗄️ Database Queries Needed

### Current Query (Working):
```sql
SELECT job_submissions.*,
       jobs.*,
       brands.*,
       users.*
FROM job_submissions
LEFT JOIN jobs ON jobs.id = job_submissions.job_id
LEFT JOIN brands ON brands.id = jobs.brand_id
LEFT JOIN users ON users.id = job_submissions.contractor_id
```

### Should Also Join:
```sql
-- Store info
LEFT JOIN stores ON stores.id = job_submissions.store_id

-- SKU/Product info  
LEFT JOIN skus ON skus.id = job_submissions.sku_id
```

### Payment Creation Query (Need to Implement):
```sql
INSERT INTO payments (job_id, contractor_id, amount, status)
VALUES (
  {job_id},
  {contractor_id},
  (SELECT payout_per_store FROM jobs WHERE id = {job_id}),
  'pending'
);
```

---

## ⚠️ Critical Questions to Answer

1. **Payment Amount:** 
   - Is it `payout_per_store` from the job? Or something else?
   - What if job has multiple stores? One payment per store submission?

2. **Multiple Submissions:**
   - Can one job have multiple submissions?
   - What happens if first submission is rejected but second is approved?

3. **Notifications:**
   - Should we implement email/SMS notifications?
   - Or just in-app notifications table?

4. **Rejection Handling:**
   - Does job go back to `pending` (allowing resubmission)?
   - Or stay `pending_review` with feedback?

5. **Admin Permissions:**
   - Can all admins approve/reject?
   - Or only certain admins?
   - Need audit trail of who approved what?

---

## 🎯 Recommended Next Steps

1. **Immediate (Finish Current Build):**
   - Verify RLS policies allow admin access
   - Add store/SKU info to display
   - Implement payment record creation on approve

2. **Short Term:**
   - Add links to job details and shelfer profile
   - Add notification creation
   - Test with real data

3. **Medium Term:**
   - Build payment processing page
   - Add quality ratings
   - Add export functionality

4. **Long Term:**
   - Payment gateway integration
   - Automated quality checks
   - Analytics dashboard

---

## 📝 For ChatGPT Spec Generation

If you want ChatGPT to create a detailed spec, ask it:

"Create a detailed technical specification for a job submission review system with:
- Approve/reject workflow
- Payment processing on approval
- Quality control features
- Admin permissions and audit trail
- Notifications system
- Database schema integration
- UI/UX requirements"

Then we can compare and fill in gaps!


