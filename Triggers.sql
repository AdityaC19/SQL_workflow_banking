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
