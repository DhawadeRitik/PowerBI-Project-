
-- Business problems 
-- 1. Find the total loan applications
SELECT 
	COUNT(id) AS total_loan_application 
FROM financial_loan;

-- 2. Find the month to date total loan applications 
SELECT 
	DISTINCT(YEAR(issue_date)) AS unique_year 
FROM financial_loan;

SELECT 
	COUNT(id) AS mtd_total_loan_applications
FROM financial_loan 
WHERE MONTH(issue_date) = 12;

-- 3. find the total loan application month on month compare the current month to previous month
-- Month-over-Month loan applications (single year)
WITH previous_month_application AS (	
	SELECT 
		MONTH(issue_date) AS month_num,
		COUNT(id) AS loan_application
	FROM financial_loan 
	GROUP BY MONTH(issue_date) 
)
SELECT 
	month_num,
	loan_application,
	LAG(loan_application) OVER(ORDER BY month_num) AS pm_loan_application,
	ROUND(
		(loan_application - LAG(loan_application) OVER(ORDER BY month_num)) * 100.0 
		/ NULLIF(LAG(loan_application) OVER(ORDER BY month_num), 0), 2
	) AS pct_change 
FROM previous_month_application
ORDER BY month_num;

--3. Calculate the total funded amount (loan amount which is given to the loan applicant)
SELECT 
	SUM(loan_amount) AS total_funded_amount 
FROM financial_loan;

-- What is the total amount funded to the customer in each month
SELECT 
   MONTH(issue_date) AS months,
   SUM(loan_amount) funded_amount
FROM financial_loan
GROUP BY MONTH(issue_date)
ORDER BY MONTH(issue_date);

-- Previous Month o Date Funded Amount 
WITH previous_mtd_funded_amount AS (
	SELECT 
	   MONTH(issue_date) AS months,
	   SUM(loan_amount) AS funded_amount
	FROM financial_loan
	GROUP BY MONTH(issue_date)
)
SELECT 
	months,
	funded_amount,
	LAG(funded_amount) OVER(ORDER BY months) AS previous_month_funded_amount,
	ROUND(
		(funded_amount - LAG(funded_amount) OVER(ORDER BY months)) * 100.0 
		/ NULLIF(LAG(funded_amount) OVER(ORDER BY months), 0), 2
	) AS pct_change
FROM previous_mtd_funded_amount
ORDER BY months;

-- ===============================================================

-- Total Amount Received 
-- Calculate the total amount received --> The amount received by the customers 
-- The amount received back from the customer by Bank
SELECT 
	SUM(total_payment) total_amount_received
FROM financial_loan;

-- Total amount received for each month 
SELECT 
	MONTH(issue_date) AS months ,
	SUM(total_payment) total_amount_received
FROM  financial_loan 
GROUP BY MONTH(issue_date)
ORDER BY MONTH(issue_date);

-- Previous month to date 
WITH previous_month_amount_received AS
(
	SELECT 
	MONTH(issue_date) AS months ,
	SUM(total_payment) total_amount_received
FROM  financial_loan 
GROUP BY MONTH(issue_date)

)
SELECT 
   months,
   total_amount_received,
   LAG(total_amount_received) OVER(ORDER BY months) AS previous_month_received_amount
FROM previous_month_amount_received


-- ===============================================================

-- Average Interest Rate 
-- What is the average interest rate?
-- What is the average intereset rate by each month?
SELECT 
	MONTH(issue_date) AS months,
	CONCAT(ROUND(AVG(int_rate),4) * 100,'%') AS average_interest_rate 
FROM financial_loan
GROUP BY MONTH(issue_date)
ORDER BY MONTH(issue_date);

-- ===========================================================================================

-- Average Debt-to_Income Ratio (DTI)
-- By Month-to-Date 

SELECT 
	MONTH(issue_date) AS months ,
	YEAR(issue_date) AS years ,
	CONCAT(ROUND(AVG(dti) * 100,2),'%') AS average_dept_to_income_ration
FROM financial_loan
GROUP BY MONTH(issue_date), YEAR(issue_date)
ORDER BY MONTH(issue_date);


-- =======================================================================================
--								SECOND -- Business Problem Queries
-- Application Loan Status 
-- Good Loan --> Current and Fully Paid areGood Loans 
-- Bad Loans --> Charged Off --> Those Customer who are not repaying the loan properly
SELECT 
	CASE 
	    WHEN loan_status IN ('Fully Paid', 'Current') THEN 'Good Loan'
	    ELSE 'Bad Loan'
	END AS loan_category,
	COUNT(*) AS application_count,
	SUM(COUNT(*)) OVER() AS total_applications,
	CAST(ROUND((COUNT(*) * 100.0) / SUM(COUNT(*)) OVER(), 2) AS DECIMAL(10,2)) AS pct_application
FROM financial_loan
GROUP BY 
	CASE 
	    WHEN loan_status IN ('Fully Paid', 'Current') THEN 'Good Loan'
	    ELSE 'Bad Loan'
	END;

-- Good loan applications
SELECT 
   COUNT(*) AS application_count
FROM financial_loan 
WHERE loan_status IN ('Fully Paid', 'Current')


-- Good Loan funded amount 
SELECT 
   SUM(loan_amount) AS good_loan_funded_amount
FROM financial_loan 
WHERE loan_status IN ('Fully Paid', 'Current');

-- Good Loan Total Received Amount
SELECT 
   SUM(total_payment) AS good_loan_received_amount
FROM financial_loan 
WHERE loan_status IN ('Fully Paid', 'Current');

-- Both in once
-- Good Loan funded amount vs received amount
SELECT 
   SUM(loan_amount) AS good_loan_funded_amount,
   SUM(total_payment) AS good_loan_received_amount,
   SUM(total_payment) - SUM(loan_amount) AS profit_loss_amount
FROM financial_loan 
WHERE loan_status IN ('Fully Paid', 'Current');

-- Bad Loans
-- Total percentage of Bad Loans 
SELECT 
  (COUNT(CASE WHEN loan_status = 'Charged Off' THEN id END) * 100 )
  / COUNT(id) AS bad_loan_pct_count
FROM financial_loan ;

-- Total Application Of Bad Loans
SELECT 
 COUNT(id) AS total_bad_loan_application 
FROM financial_loan 
WHERE loan_status = 'Charged Off';

-- Bad Loan funded amount 
SELECT 
 SUM(loan_amount) AS total_bad_loan_funded_amount
FROM financial_loan 
WHERE loan_status = 'Charged Off';

-- Total Bad Loan Amount Received 
SELECT 
 SUM(total_payment) AS total_bad_loan_received_amount
FROM financial_loan 
WHERE loan_status = 'Charged Off';

-- Bad Loan funded amount vs Received amount and profit and loss 
SELECT 
    SUM(loan_amount) AS total_bad_loan_funded_amount,
    SUM(total_payment) AS total_bad_loan_received_amount,
    SUM(total_payment) - SUM(loan_amount)  AS profit_loss_amount
FROM financial_loan 
WHERE loan_status = 'Charged Off';

-- Loan Status Grid view 
SELECT 
    loan_status ,
	COUNT(id) AS LoanCount, 
	SUM(total_payment) AS Received_Amount,
	SUM(loan_amount) AS Funded_Amount,
	ROUND(AVG(int_rate)* 100,2) AS Intrest_Rate,
	ROUND(AVG(dti) * 100,2) AS Debt_to_Income_Ratio
FROM financial_loan 
GROUP BY loan_status;

-- Overall Funded Amount and Received Amount 
SELECT 
    SUM(loan_amount) AS Total_Funded_Amount,
	SUM(total_payment) AS Total_Received_Amount,
	SUM(total_payment) - SUM(loan_amount) AS profit_loss_amount
FROM financial_loan;

-- Funded Amount VS Received Amount By Month for loan status
SELECT
	loan_status,
	MONTH(issue_date) AS funded_received_amount_month,
	SUM(loan_amount) AS funded_amount,
	SUM(total_payment) AS received_amount
FROM financial_loan
GROUP BY loan_status, MONTH(issue_date)
ORDER BY MONTH(issue_date);


-- =======================================================================================================================================
-- =======================================================================================================================================
--                                    THIRD -- DASHBORD QUERY 

-- 1. Monthly trends by issue date 
SELECT 
	 MONTH(issue_date) AS Month_Num,
	 DATENAME(MONTH, issue_date) AS Month_Name,
	 COUNT(id) AS Total_Loan_Application,
	 SUM(loan_amount) AS Total_Funded_Amount,
	 SUM(total_payment) AS Total_Received_Amount
FROM financial_loan 
GROUP BY DATENAME(MONTH, issue_date),MONTH(issue_date)
ORDER BY MONTH(issue_date) 


-- Regional Analysis 
SELECT 
	 address_state,
	 COUNT(id) AS Total_Loan_Application,
	 SUM(loan_amount) AS Total_Funded_Amount,
	 SUM(total_payment) AS Total_Received_Amount
FROM financial_loan 
GROUP BY address_state
ORDER BY Total_Funded_Amount DESC;

-- Loan Term Analysis --> Help to understand the distribution of the loans 
SELECT 
	 term AS Term_In_Month,
	 CAST(LEFT(term, 2) AS INT) / 12 AS Term_In_Years,
	 COUNT(id) AS Total_Loan_Application,
	 SUM(loan_amount) AS Total_Funded_Amount,
	 SUM(total_payment) AS Total_Received_Amount
FROM financial_loan 
GROUP BY term
ORDER BY Total_Funded_Amount DESC;

-- Employee length Analysis 
SELECT 
	 emp_length,
	 COUNT(id) AS Total_Loan_Application,
	 SUM(loan_amount) AS Total_Funded_Amount,
	 SUM(total_payment) AS Total_Received_Amount
FROM financial_loan 
GROUP BY emp_length
ORDER BY emp_length ;

-- Loan Purpose Breakdown 
SELECT 
	 purpose,
	 COUNT(id) AS Total_Loan_Application,
	 SUM(loan_amount) AS Total_Funded_Amount,
	 SUM(total_payment) AS Total_Received_Amount
FROM financial_loan 
GROUP BY purpose
ORDER BY Total_Loan_Application DESC;


-- Home Ownership 
SELECT 
	 home_ownership,
	 COUNT(id) AS Total_Loan_Application,
	 SUM(loan_amount) AS Total_Funded_Amount,
	 SUM(total_payment) AS Total_Received_Amount
FROM financial_loan 
GROUP BY home_ownership
ORDER BY Total_Loan_Application DESC;

SELECT  * FROM financial_loan

SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'financial_loan'
ORDER BY ORDINAL_POSITION;
