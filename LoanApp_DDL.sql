----------C R E A T I N G   T A B L E S---------------
USE Banking_data_model;

CREATE TABLE BusinessUnit (
    business_unit_id  BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    business_unit_code VARCHAR(10) NOT NULL UNIQUE,  -- HL, LAP, BIL
    business_unit_name  VARCHAR(100) NOT NULL,
    status   VARCHAR(20) NOT NULL DEFAULT('ACTIVE'),
    created_at  DATETIME2(0) NOT NULL DEFAULT(SYSUTCDATETIME()),
    updated_at  DATETIME2(0) NOT NULL DEFAULT(SYSUTCDATETIME()),
    CONSTRAINT CK_BusinessUnit_status CHECK (status IN ('ACTIVE','INACTIVE'))
);
GO

CREATE TABLE Branch (
    branch_id  BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    branch_code  VARCHAR(20) NOT NULL UNIQUE,
    branch_name  VARCHAR(120) NOT NULL,
    city   VARCHAR(80) NOT NULL,
    state VARCHAR(80) NOT NULL,
    country VARCHAR(80) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT('ACTIVE'),
    CONSTRAINT CK_Branch_status CHECK (status IN ('ACTIVE','INACTIVE'))
);
GO

CREATE TABLE Employee (
    employee_id  BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    employee_code  VARCHAR(30) NOT NULL UNIQUE,
    employee_name  VARCHAR(120) NOT NULL,
    employee_role VARCHAR(20) NOT NULL,  -- SALES, RELATIONSHIP, UNDERWRITER, APPROVER
    branch_id  BIGINT NULL,
    business_unit_id BIGINT NULL,
    status VARCHAR(20) NOT NULL DEFAULT('ACTIVE'),
    CONSTRAINT FK_Employee_Branch FOREIGN KEY (branch_id) REFERENCES dbo.Branch(branch_id),
    CONSTRAINT FK_Employee_BusinessUnit FOREIGN KEY (business_unit_id) REFERENCES dbo.BusinessUnit(business_unit_id),
    CONSTRAINT CK_Employee_role CHECK (employee_role IN ('SALES','RELATIONSHIP','UNDERWRITER','APPROVER')),
    CONSTRAINT CK_Employee_status CHECK (status IN ('ACTIVE','INACTIVE'))
);
GO


CREATE TABLE Customer (
    customer_id   BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    customer_number  VARCHAR(30) NOT NULL UNIQUE,
    customer_name  VARCHAR(160) NOT NULL,
    customer_type  VARCHAR(20) NOT NULL,  -- INDIVIDUAL, BUSINESS
    date_of_birth_or_incorp_date DATE NULL,
    CONSTRAINT CK_Customer_type CHECK (customer_type IN ('INDIVIDUAL','BUSINESS'))
);
GO

CREATE TABLE LoanProduct (
    loan_product_id   BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    business_unit_id  BIGINT NOT NULL,
    product_code VARCHAR(10) NOT NULL,   -- HL, LAP, BIL 
    product_name  VARCHAR(120) NOT NULL,
    loan_type  VARCHAR(20) NOT NULL,   -- SECURED, UNSECURED
    CONSTRAINT FK_LoanProduct_BusinessUnit FOREIGN KEY (business_unit_id) REFERENCES dbo.BusinessUnit(business_unit_id),
    CONSTRAINT UQ_LoanProduct_BuCode UNIQUE (business_unit_id, product_code),
    CONSTRAINT CK_LoanProduct_code CHECK (product_code IN ('HL','LAP','BIL')),
    CONSTRAINT CK_LoanProduct_type CHECK (loan_type IN ('SECURED','UNSECURED'))
);
GO

CREATE TABLE LoanApplication (
    application_id  BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    customer_id   BIGINT NOT NULL,
    loan_product_id BIGINT NOT NULL,
    requested_amount DECIMAL(18,2) NOT NULL,
    requested_tenor_months  INT NOT NULL,
    interest_mode  VARCHAR(20) NOT NULL,  -- EMI, INTEREST_ONLY
    sales_officer_id  BIGINT NULL,
    relationship_officer_id BIGINT NULL,
    status  VARCHAR(20) NOT NULL,  -- SUBMITTED, APPROVED, REJECTED

    CONSTRAINT FK_LoanApplication_Customer FOREIGN KEY (customer_id) REFERENCES dbo.Customer(customer_id),
    CONSTRAINT FK_LoanApplication_LoanProduct FOREIGN KEY (loan_product_id) REFERENCES dbo.LoanProduct(loan_product_id),
    CONSTRAINT FK_LoanApplication_SalesOfficer FOREIGN KEY (sales_officer_id) REFERENCES dbo.Employee(employee_id),
    CONSTRAINT FK_LoanApplication_RelationshipOfficer FOREIGN KEY (relationship_officer_id) REFERENCES dbo.Employee(employee_id),

    CONSTRAINT CK_LoanApplication_amount CHECK (requested_amount > 0),
    CONSTRAINT CK_LoanApplication_tenor CHECK (requested_tenor_months > 0),
    CONSTRAINT CK_LoanApplication_interest CHECK (interest_mode IN ('EMI','INTEREST_ONLY')),
    CONSTRAINT CK_LoanApplication_status CHECK (status IN ('SUBMITTED','APPROVED','REJECTED'))
);
GO

CREATE TABLE dbo.UnderwritingReview
(
    application_id BIGINT NOT NULL PRIMARY KEY,  -- 1:1 with LoanApplication
    underwriter_id BIGINT NOT NULL,
    decision  VARCHAR(20) NOT NULL,          -- APPROVE / DECLINE
    reviewed_at DATETIME2(0) NOT NULL CONSTRAINT DF_UW_reviewed_at DEFAULT (SYSUTCDATETIME()),
    comments  VARCHAR(500) NULL,

    CONSTRAINT FK_UW_Application FOREIGN KEY (application_id) REFERENCES dbo.LoanApplication(application_id),
	CONSTRAINT FK_UW_Underwriter FOREIGN KEY (underwriter_id) REFERENCES dbo.Employee(employee_id),
    CONSTRAINT CK_UW_decision CHECK (decision IN ('APPROVE','DECLINE'))
);

Go
ALTER TABLE dbo.UnderwritingReview
ADD recommended_amount DECIMAL(18,2),
    recommended_tenor_months INT;

-- 1 sanction per application (application_id is PK)
CREATE TABLE Sanction (
    application_id  BIGINT NOT NULL PRIMARY KEY,
    approver_id  BIGINT NOT NULL,
    sanctioned_amount DECIMAL(18,2) NOT NULL,
    sanctioned_tenor_months INT NOT NULL,
    secured_flag   BIT NOT NULL,

    CONSTRAINT FK_Sanction_Application FOREIGN KEY (application_id) REFERENCES dbo.LoanApplication(application_id),
    CONSTRAINT FK_Sanction_Approver FOREIGN KEY (approver_id) REFERENCES dbo.Employee(employee_id),

    CONSTRAINT CK_Sanction_amount CHECK (sanctioned_amount > 0),
    CONSTRAINT CK_Sanction_tenor CHECK (sanctioned_tenor_months > 0)
);
GO

-- 0..1 loan account per application
CREATE TABLE LoanAccount (
    loan_account_id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    application_id  BIGINT NOT NULL UNIQUE,
    account_number  VARCHAR(30) NOT NULL UNIQUE,
    booked_date  DATE NOT NULL,

    CONSTRAINT FK_LoanAccount_Application FOREIGN KEY (application_id) REFERENCES dbo.LoanApplication(application_id)
);
GO

-- Many disbursements (tranches) per loan account
CREATE TABLE Disbursement (
    disbursement_id  BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    loan_account_id BIGINT NOT NULL,
    tranche_no   INT NOT NULL,
    amount  DECIMAL(18,2) NOT NULL,
    disbursement_date DATE NOT NULL,
    status  VARCHAR(20) NOT NULL,  -- SCHEDULED, DISBURSED

    CONSTRAINT FK_Disbursement_LoanAccount FOREIGN KEY (loan_account_id) REFERENCES dbo.LoanAccount(loan_account_id),
    CONSTRAINT UQ_Disbursement_Tranche UNIQUE (loan_account_id, tranche_no),

    CONSTRAINT CK_Disbursement_amount CHECK (amount > 0),
    CONSTRAINT CK_Disbursement_tranche CHECK (tranche_no > 0),
    CONSTRAINT CK_Disbursement_status CHECK (status IN ('SCHEDULED','DISBURSED'))
);