--------------- Q U E R I E S ------------------

--Product funnel: counts and requested totals by product and status, plus percent shares (windows)

WITH base AS (
    SELECT bu.business_unit_code, bu.business_unit_name, lp.product_code, lp.product_name, la.status, la.requested_amount
    FROM LoanApplication la
    JOIN LoanProduct lp ON lp.loan_product_id = la.loan_product_id
    JOIN BusinessUnit bu ON bu.business_unit_id = lp.business_unit_id
)
SELECT
    business_unit_code, product_code, status,
    COUNT(*) AS application_cnt,
    SUM(requested_amount) AS total_requested_amount,
    -- total apps per product
    COUNT(*) * 1.0 / NULLIF(SUM(COUNT(*)) OVER (PARTITION BY business_unit_code, product_code), 0) AS pct_within_product,
    -- share of all apps in system
    COUNT(*) * 1.0 / NULLIF(SUM(COUNT(*)) OVER (), 0) AS pct_of_all_apps
FROM base
GROUP BY business_unit_code, product_code, status
ORDER BY business_unit_code, product_code, status;

--Customer exposure leaderboard: ranks customers by total sanctioned amount within each BU (windows)

--Disbursement progress vs sanction: per-loan totals disbursed/scheduled and a flag if tranches exceed sanction (windows)

--Latest application per customer plus the previous status (ROW_NUMBER + LAG)

--Sales officer leaderboard: rank by total requested amount and share of total (windows)

--Above-average applications: filter via subquery (overall AVG) and show percent-rank within product (windows)