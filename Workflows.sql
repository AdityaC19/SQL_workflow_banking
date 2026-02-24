-------------------T R I G G E R S -------------------

--enforce “Sanction only after underwriting APPROVE” and create a new record in sanction table
select * from UnderwritingReview
select * from Sanction

Go
CREATE OR ALTER TRIGGER trg_UWapprove_crtSanction ON UnderwritingReview
AFTER INSERT, UPDATE
AS 
BEGIN 
	with approved as (
		select *
		from inserted
		where decision = 'APPROVE'
	)
	insert into Sanction (application_id, approver_id, sanctioned_amount, sanctioned_tenor_months, secured_flag)
	select a.application_id, a.underwriter_id, a.recommended_amount, a.recommended_tenor_months, 
	CASE lp.loan_type WHEN 'SECURED' THEN 1 ELSE 0 END
	from approved a
	JOIN LoanApplication la ON la.application_id = a.application_id
	JOIN dbo.LoanProduct lp ON lp.loan_product_id = la.loan_product_id
END;
Go

INSERT INTO dbo.UnderwritingReview
(application_id, underwriter_id, decision, recommended_amount, recommended_tenor_months, comments)
VALUES
(4, 7, 'APPROVE', 210000.00, 180, 'Approved with slightly reduced amount');

select * from LoanApplication where application_id = 4
select * from UnderwritingReview
select * from Sanction	


--When an application is sanctioned, auto-create a LoanAccount
/*
Event: a row is inserted into Sanction
Action: create a LoanAccount automatically (if one doesn’t exist)
*/

CREATE OR ALTER TRIGGER dbo.trg_Sanction_CreateLoanAccount
ON dbo.Sanction
AFTER INSERT
AS
BEGIN
    INSERT INTO dbo.LoanAccount (application_id, account_number, booked_date)
    SELECT
        i.application_id,
        CONCAT('LN', RIGHT(CONCAT('00000000', CAST(i.application_id AS VARCHAR(20))), 8)) AS account_number,
        CAST(GETDATE() AS DATE) AS booked_date
    FROM inserted i
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.LoanAccount la
        WHERE la.application_id = i.application_id
    );
END;
GO

--When application is rejected, auto-clean downstream records
/*
Event: LoanApplication updated to REJECTED
Action: delete sanction + loan account + disbursements if they exist (or mark as cancelled)
*/

CREATE OR ALTER TRIGGER dbo.trg_ApplicationRejected_Cleanup
ON dbo.LoanApplication
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH rejected AS (
        SELECT i.application_id
        FROM inserted i
        JOIN deleted d ON d.application_id = i.application_id
        WHERE d.status <> 'REJECTED'
          AND i.status = 'REJECTED'
    )
    DELETE d
    FROM dbo.Disbursement d
    JOIN dbo.LoanAccount la ON la.loan_account_id = d.loan_account_id
    JOIN rejected r ON r.application_id = la.application_id;

    DELETE la
    FROM dbo.LoanAccount la
    JOIN rejected r ON r.application_id = la.application_id;

    DELETE s
    FROM dbo.Sanction s
    JOIN rejected r ON r.application_id = s.application_id;
END;
GO


--When a LoanAccount is created, auto-create a disbursement schedule (N tranches)
/*
Event: LoanAccount inserted
Action: create “scheduled” disbursement tranches
*/

----------------- S T O R E D   P R O C E D U R E S ----------------

--Creates a new row in LoanApplication
Go
CREATE or ALTER proc usp_createLoanApp(
	@customer_id BIGINT,
	@loan_product_id BIGINT,
	@requested_amount BIGINT,
	@requested_tenor_months INT,
	@interest_mode VARCHAR(50),
	@application_id BIGINT OUTPUT

) AS 
BEGIN
	BEGIN TRY
		IF NOT EXISTS(select 1 from Customer where customer_id = @customer_id)
			THROW 50003, 'Invalid customer id', 1;
		IF @requested_amount IS NULL OR @requested_amount <= 0
			THROW 50004, 'requested_amount must be > 0', 1;

		BEGIN transaction
			Insert into LoanApplication (
			customer_id, loan_product_id, requested_amount, requested_tenor_months, interest_mode, status)
			VALUES (@customer_id, @loan_product_id, @requested_amount, @requested_tenor_months, @interest_mode, 'SUBMITTED')

		SET @application_id = CONVERT(BIGINT, SCOPE_IDENTITY());
		
		COMMIT

	SELECT @application_id AS application_id;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK;
        THROW 
	END CATCH

END;

declare @new_application_id BIGINT
exec usp_createLoanApp @customer_id = 1, @loan_product_id = 1, @requested_amount = 500000, @requested_tenor_months = 240,
    @interest_mode = 'EMI', @application_id = @new_application_id OUTPUT;

SELECT @new_application_id AS new_application_id;
Go

select * from LoanApplication

--Fetch tranche schedule with running totals and remaining amount.
GO
CREATE OR ALTER PROC dbo.usp_GetDisbursementSchedule
    @account_number VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH base AS (
        SELECT
            acc.loan_account_id,
            acc.account_number,
            s.sanctioned_amount,
            d.tranche_no,
            d.amount,
            d.disbursement_date,
            d.status
        FROM dbo.LoanAccount acc
        JOIN dbo.Sanction s ON s.application_id = acc.application_id
        LEFT JOIN dbo.Disbursement d ON d.loan_account_id = acc.loan_account_id
        WHERE acc.account_number = @account_number
    )
    SELECT
        loan_account_id,
        account_number,
        tranche_no,
        amount,
        disbursement_date,
        status,
        SUM(COALESCE(amount,0)) OVER (PARTITION BY loan_account_id ORDER BY tranche_no) AS running_total,
        sanctioned_amount - SUM(COALESCE(amount,0)) OVER (PARTITION BY loan_account_id ORDER BY tranche_no) AS remaining_to_sanction
    FROM base
    ORDER BY tranche_no;
END;
GO

EXEC dbo.usp_GetDisbursementSchedule @account_number = 'LN00000003';
select * from dbo.LoanAccount
select * from Disbursement


