# ShelfAssured — AI Annotation Plan
**Version 1.0 • Date: 2025-09-08**

---

## 1. Purpose
This document defines how ShelfAssured will build a machine learning–ready dataset of grocery shelf photos for AI training. It consolidates the **Annotation Style Guide v1.1**, **Pilot Batch Test Plan**, and **Vendor Onboarding Checklist** into a single reference for internal and external use.

---

## 2. Annotation Style Guide (v1.1)

### Project Overview & Mission
**Goal:** Train an AI model for real-time retail analytics by creating a dataset of annotated shelf photos.  
**Output:** Bounding boxes + attributes for products, price tags, out-of-stock areas, promotions, and obstructions, with store/product metadata.

### Object Classes
| Class Name    | Description                                  | Annotation Type |
|---------------|----------------------------------------------|-----------------|
| product       | An individual retail product unit            | Bounding Box    |
| price_tag     | A shelf tag showing a product’s price        | Bounding Box    |
| out_of_stock  | Empty shelf space where a product should be  | Bounding Box    |
| promotion     | Marketing signage, coupon, or sale tag       | Bounding Box    |
| obstruction   | Floor display/object blocking shelf view     | Bounding Box    |

### Annotation Attributes
**Product:** brand, product_name, upc, facing_condition {good, poor, unknown}, multipack {yes, no}  
**Price Tag:** price_text, price_unit, linked_product_upc  
**Out-of-Stock:** category, expected_facings (if available)  
**Promotion:** promotion_type, promotion_text, linked_product_upc(s)  
**Obstruction:** obstruction_type, visibility_impact  

### Metadata Standards
Each image must include:  
- store_id or store_name (if provided)  
- aisle/department (if provided; blank if unknown)  
- capture_timestamp  
- image_quality: {good, blurry, glare, partial_shelf}  

### Edge Cases
- Cut-off products: annotate if >50% visible.  
- Glare/reflections: annotate; mark text as “unreadable.”  
- Overlapping products: each unit gets its own box; multipacks = one box.  
- Multi-SKU promotions: annotate once; link to all relevant UPCs.  

### Inter-Annotator Agreement (IAA)
Pilot batch will be double-annotated. Targets:  
- Bounding boxes: ≥95% IoU ≥0.5  
- Price transcription: ≥98% exact-match  
- Attributes: ≥90% agreement  

---

## 3. Pilot Batch Test Plan (v1.0)

**Scope:** 100 images (mix of categories, conditions). Deliverable = annotated dataset in COCO JSON.  

**Evaluation Criteria:**  
- Completeness: all classes covered  
- Accuracy: 95% bounding boxes, 98% price transcription, 90% attributes  
- Metadata: included when provided  
- Edge Cases: handled per rules  

**QA Process:**  
- Double annotation: 20% of images  
- Gold standard review: 100% by ShelfAssured  
- Feedback loop before scaling  

**Acceptance Thresholds:**  
- 95% IoU for boxes  
- 98% accuracy for price transcription  
- 90% attributes agreement  
- <5% critical errors  

**Next Steps After Pilot:** Scale to 1,000–5,000 images with 10% QA spot-check per batch.

---

## 4. Vendor Onboarding Checklist (v1.0)

### Core Documents
- Annotation Style Guide v1.1  
- Pilot Batch Test Plan v1.0  
- Product Catalog (UPC, brand, product_name)  
- Export Schema (COCO JSON / Pascal VOC / YOLO format)  

### Tooling Setup
- Annotation platform (e.g., CVAT, Labelbox, Roboflow)  
- Schema pre-loaded (classes + attributes)  
- Accounts provisioned  
- Pilot images uploaded with metadata fields  

### Communication
- Dedicated channel (Slack/Teams/email)  
- Primary contact: Courtney  
- Response SLA: 24 hrs for clarifications  

### Quality Control
- IAA thresholds: 95% boxes, 98% price, 90% attributes  
- Vendor QA reviewer + ShelfAssured review  
- Escalation: retrain annotators if thresholds not met  

### Deliverables & Schedule
- Pilot batch (100 images) within X business days  
- ShelfAssured review window: 3–5 days  
- Scale plan: next batch (1,000 images) with 10% QA check  
- Final format: annotated dataset in agreed schema  

### Sign-Off
- Vendor confirms receipt of style guide, pilot plan, product catalog, schema  
- ShelfAssured confirms tool access, comms, and pilot scope  

---

## 5. Summary
This plan ensures ShelfAssured’s AI training data is annotated consistently, at high quality, and with measurable QA benchmarks. It provides vendors with clear rules, deliverables, and escalation paths, reducing risk before large-scale annotation.

