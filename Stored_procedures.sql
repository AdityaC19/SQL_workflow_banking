----------------- S T O R E D   P R O C E D U R E S ----------------
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
