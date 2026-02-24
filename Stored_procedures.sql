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


