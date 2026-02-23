USE Banking_data_model;

-- BusinessUnit
SET IDENTITY_INSERT dbo.BusinessUnit ON;

INSERT INTO dbo.BusinessUnit (business_unit_id, business_unit_code, business_unit_name, status, created_at, updated_at)
VALUES
(1, 'HL',  'Home Loan',                 'ACTIVE', SYSUTCDATETIME(), SYSUTCDATETIME()),
(2, 'LAP', 'Loan Against Property',     'ACTIVE', SYSUTCDATETIME(), SYSUTCDATETIME()),
(3, 'BIL', 'Business Investment Loan',  'ACTIVE', SYSUTCDATETIME(), SYSUTCDATETIME());

SET IDENTITY_INSERT dbo.BusinessUnit OFF;

-- Branch
SET IDENTITY_INSERT dbo.Branch ON;

INSERT INTO dbo.Branch (branch_id, branch_code, branch_name, city, state, country, status)
VALUES
(1, 'PHX01', 'Phoenix Downtown', 'Phoenix', 'AZ', 'USA', 'ACTIVE'),
(2, 'TUC01', 'Tucson Central',   'Tucson',  'AZ', 'USA', 'ACTIVE'),
(3, 'TEM01', 'Tempe Branch',     'Tempe',   'AZ', 'USA', 'ACTIVE');

SET IDENTITY_INSERT dbo.Branch OFF;

-- Employee
SET IDENTITY_INSERT dbo.Employee ON;

INSERT INTO dbo.Employee (employee_id, employee_code, employee_name, employee_role, branch_id, business_unit_id, status)
VALUES
(1,  'E-S-1001', 'Ava Martin',     'SALES',        1, 1, 'ACTIVE'),
(2,  'E-S-1002', 'Noah Johnson',   'SALES',        2, 2, 'ACTIVE'),
(3,  'E-S-1003', 'Mia Patel',      'SALES',        3, 3, 'ACTIVE'),

(4,  'E-R-2001', 'Liam Garcia',    'RELATIONSHIP', 1, 1, 'ACTIVE'),
(5,  'E-R-2002', 'Sophia Lee',     'RELATIONSHIP', 2, 2, 'ACTIVE'),
(6,  'E-R-2003', 'Ethan Brown',    'RELATIONSHIP', 3, 3, 'ACTIVE'),

(7,  'E-U-3001', 'Olivia Wilson',  'UNDERWRITER',  1, 1, 'ACTIVE'),
(8,  'E-U-3002', 'James Davis',    'UNDERWRITER',  2, 2, 'ACTIVE'),
(9,  'E-U-3003', 'Isabella Clark', 'UNDERWRITER',  3, 3, 'ACTIVE'),

(10, 'E-A-4001', 'Benjamin Hall',  'APPROVER',     1, 1, 'ACTIVE'),
(11, 'E-A-4002', 'Charlotte Young','APPROVER',     2, 2, 'ACTIVE'),
(12, 'E-A-4003', 'Henry King',     'APPROVER',     3, 3, 'ACTIVE');

SET IDENTITY_INSERT dbo.Employee OFF;

-- Customer
SET IDENTITY_INSERT dbo.Customer ON;

INSERT INTO dbo.Customer (customer_id, customer_number, customer_name, customer_type, date_of_birth_or_incorp_date)
VALUES
(1, 'CUST0001', 'Aditya Chichghare',     'INDIVIDUAL', '1999-03-14'),
(2, 'CUST0002', 'Riya Sharma',           'INDIVIDUAL', '1998-11-02'),
(3, 'CUST0003', 'Karan Mehta',           'INDIVIDUAL', '1996-06-21'),
(4, 'CUST0004', 'Neha Verma',            'INDIVIDUAL', '1997-01-09'),
(5, 'CUST0005', 'Desert Retail LLC',     'BUSINESS',   '2018-05-10'),
(6, 'CUST0006', 'Sunrise Traders Inc',   'BUSINESS',   '2016-02-25'),
(7, 'CUST0007', 'Arjun Rao',             'INDIVIDUAL', '1995-09-30'),
(8, 'CUST0008', 'Meera Nair',            'INDIVIDUAL', '2000-12-18');

SET IDENTITY_INSERT dbo.Customer OFF;

-- LoanProduct
-- One per BU, and product_code must be HL/LAP/BIL/STLAP etc.
SET IDENTITY_INSERT dbo.LoanProduct ON;

INSERT INTO dbo.LoanProduct (loan_product_id, business_unit_id, product_code, product_name, loan_type)
VALUES
(1, 1, 'HL',  'Home Loan Standard',             'SECURED'),
(2, 2, 'LAP', 'Loan Against Property Standard', 'SECURED'),
(3, 3, 'BIL', 'Business Investment Loan',       'UNSECURED');

SET IDENTITY_INSERT dbo.LoanProduct OFF;

-- LoanApplication
SET IDENTITY_INSERT dbo.LoanApplication ON;

INSERT INTO dbo.LoanApplication
(application_id, customer_id, loan_product_id, requested_amount, requested_tenor_months, interest_mode,
 sales_officer_id, relationship_officer_id, status)
VALUES
(1, 1, 1, 420000.00, 240, 'EMI',           1, 4, 'APPROVED'),
(2, 2, 1, 310000.00, 180, 'EMI',           1, 4, 'APPROVED'),
(3, 3, 2, 150000.00, 120, 'EMI',           2, 5, 'REJECTED'),
(4, 4, 2, 220000.00, 180, 'INTEREST_ONLY', 2, 5, 'SUBMITTED'),
(5, 5, 3, 500000.00,  60, 'EMI',           3, 6, 'APPROVED'),
(6, 6, 3, 650000.00,  84, 'EMI',           3, 6, 'APPROVED'),
(7, 7, 2, 175000.00, 120, 'EMI',           2, 5, 'APPROVED'),
(8, 8, 1, 290000.00, 240, 'EMI',           1, 4, 'SUBMITTED'),
(9, 3, 3, 400000.00,  72, 'INTEREST_ONLY', 3, 6, 'REJECTED'),
(10,2, 2, 260000.00, 180, 'EMI',           2, 5, 'APPROVED');

SET IDENTITY_INSERT dbo.LoanApplication OFF;

-- Sanction
-- One per approved application only
INSERT INTO dbo.Sanction
(application_id, approver_id, sanctioned_amount, sanctioned_tenor_months, secured_flag)
VALUES
(1,  10, 410000.00, 240, 1),
(2,  10, 300000.00, 180, 1),
(5,  12, 480000.00,  60, 0),
(6,  12, 630000.00,  84, 0),
(7,  11, 170000.00, 120, 1),
(10, 11, 250000.00, 180, 1);

-- LoanAccount
-- One per sanctioned application
SET IDENTITY_INSERT dbo.LoanAccount ON;

INSERT INTO dbo.LoanAccount
(loan_account_id, application_id, account_number, booked_date)
VALUES
(1,  1,  'LN00000001', '2026-01-10'),
(2,  2,  'LN00000002', '2026-01-12'),
(3,  5,  'LN00000003', '2026-01-20'),
(4,  6,  'LN00000004', '2026-01-22'),
(5,  7,  'LN00000005', '2026-02-01'),
(6, 10,  'LN00000006', '2026-02-05');

SET IDENTITY_INSERT dbo.LoanAccount OFF;

-- Disbursement (multi-tranche)
SET IDENTITY_INSERT dbo.Disbursement ON;

INSERT INTO dbo.Disbursement
(disbursement_id, loan_account_id, tranche_no, amount, disbursement_date, status)
VALUES
-- LN00000001 (2 tranches)
(1, 1, 1, 250000.00, '2026-01-15', 'DISBURSED'),
(2, 1, 2, 160000.00, '2026-02-10', 'SCHEDULED'),

-- LN00000002 (1 tranche)
(3, 2, 1, 300000.00, '2026-01-18', 'DISBURSED'),

-- LN00000003 (3 tranches)
(4, 3, 1, 200000.00, '2026-01-25', 'DISBURSED'),
(5, 3, 2, 150000.00, '2026-02-15', 'SCHEDULED'),
(6, 3, 3, 130000.00, '2026-03-15', 'SCHEDULED'),

-- LN00000004 (2 tranches)
(7, 4, 1, 330000.00, '2026-01-28', 'DISBURSED'),
(8, 4, 2, 300000.00, '2026-02-20', 'SCHEDULED'),

-- LN00000005 (1 tranche)
(9, 5, 1, 170000.00, '2026-02-03', 'DISBURSED'),

-- LN00000006 (2 tranches)
(10, 6, 1, 150000.00, '2026-02-08', 'DISBURSED'),
(11, 6, 2, 100000.00, '2026-02-25', 'SCHEDULED');

SET IDENTITY_INSERT dbo.Disbursement OFF;

--sanity checks
SELECT * FROM dbo.BusinessUnit;
SELECT * FROM dbo.Branch;
SELECT * FROM dbo.Employee;
SELECT * FROM dbo.Customer;
SELECT * FROM dbo.LoanProduct;

SELECT * FROM dbo.LoanApplication ORDER BY application_id;
SELECT * FROM dbo.Sanction ORDER BY application_id;
SELECT * FROM dbo.LoanAccount ORDER BY loan_account_id;
SELECT * FROM dbo.Disbursement ORDER BY loan_account_id, tranche_no;
