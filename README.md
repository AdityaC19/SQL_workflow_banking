# Banking Loan Data Model

## Overview

This project implements a realistic banking loan origination and disbursement data model.  
It captures the lifecycle of a loan from application through underwriting, sanction, account booking, and tranche-based disbursement.

---

## Loan Application Lifecycle

The loan application journey in this model follows these stages:

### 1. Loan Application
- A customer applies for a loan product  
- Stored in `LoanApplication` with status `SUBMITTED`

### 2. Underwriting Review
- An underwriter evaluates the application  
- Decision recorded in `UnderwritingReview` (`APPROVE` / `DECLINE`)  
- Recommended amount and tenor captured  

### 3. Sanction
- If underwriting decision is `APPROVE`, a sanction record is created  
- Stored in `Sanction` with final sanctioned terms  

### 4. Loan Account Booking
- Approved loans become active accounts  
- Stored in `LoanAccount`  

### 5. Disbursement
- Funds released in one or more tranches  
- Stored in `Disbursement`  

---
## Important Relationships

- Customer → LoanApplication (1:M)  
- LoanApplication → UnderwritingReview (1:1)  
- UnderwritingReview (APPROVE) → Sanction (1:1)  
- LoanApplication → LoanAccount (0..1)  
- LoanAccount → Disbursement (1:M)  
- LoanProduct → LoanApplication (1:M)  
- Employee → UnderwritingReview / Sanction (1:M)  

---

## Use Cases Supported

- Loan origination tracking  
- Underwriting decisions  
- Approved vs requested comparison  
- Portfolio exposure analysis  
- Disbursement monitoring  
- Employee performance metrics  

---

## Summary

This model represents a simplified lending pipeline:

**Application → Underwriting → Sanction → Account → Disbursement**

It balances realism with conceptual clarity, making it suitable for learning, analytics practice, and database design demonstrations.
