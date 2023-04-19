--- Cleaning Data

--- Total Records = 541909
--- Records where customerID IS NULL = 135080
; with online_retail as 
(
	SELECT *
	  FROM [Online Retail].[dbo].[Online_retail]
	  WHERE customerID IS NOT NULL
),
--- Total records 406 826
online_retail_1 as
(
	select *
	from online_retail
	where Quantity > 0 and UnitPrice > 0
)
--- Total Records 397 884

--- Duplicate check
,dup_check as
(
	select *,
	ROW_NUMBER() over (partition by InvoiceNo, StockCode, Quantity order by InvoiceDate) as dup_pos
	from online_retail_1
)

--- Let`s create temporary table
SELECT * 
INTO #tp_online_retail 
FROM dup_check
Where dup_pos = 1
--- Total Records 392 669
--- Duplicated records 5215

--- CLEAN DATA
--- COHORT ANALYSIS
SELECT * 
FROM #tp_online_retail 

-- Unique Identifier (CustomerID)
-- Initial Start Date (First Invoice Date)
-- Revenue Data

SELECT customerID,
min(InvoiceDate) as first_purchase_date,
DATEFROMPARTS(year(min(InvoiceDate)),month(min(InvoiceDate)),1) as Cohort_date
into #tp_cohort_date
FROM #tp_online_retail
GROUP BY CustomerID

select *
from #tp_cohort_date

-- Create Cohort Index
SELECT aa.*,
(year_diff * 12 + month_diff + 1) as cohort_index
INTO #cohort_retention
FROM
	(
		SELECT a.*,
		(invoice_year - cohort_year) as year_diff,
		(invoice_month - cohort_month) as month_diff
		FROM
			(
				SELECT o.*,
				c.cohort_date,
				YEAR(o.invoiceDate) as invoice_year,
				MONTH(o.invoiceDate) as invoice_month,
				YEAR(c.cohort_date) as cohort_year,
				MONTH(c.cohort_date) as cohort_month
				FROM #tp_online_retail as o
				LEFT JOIN #tp_cohort_date as c
				ON c.CustomerID = o.CustomerID
			) as a
	) as aa

	SELECT DISTINCT
	customerID,
	Cohort_date,
	cohort_index
	FROM #cohort_retention
--- 13 054 Records

---Pivot Data to see the cohort table

SELECT *
INTO #cohort_pivot
FROM (
	SELECT DISTINCT
		customerID,
		Cohort_date,
		cohort_index
	FROM #cohort_retention
) AS b
pivot(
	COUNT(CustomerID)
	for Cohort_Index IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13])
)	AS pivot_table;

SELECT *
FROM #cohort_pivot
ORDER BY cohort_date


SELECT cohort_date,
1.0*[1]/[1]* 100 as [1], 
1.0*[2]/[1]* 100 as [2],
1.0*[3]/[1]* 100 as [3],
1.0*[4]/[1]* 100 as [4],
1.0*[5]/[1]* 100 as [5],
1.0*[6]/[1]* 100 as [6],
1.0*[7]/[1]* 100 as [7],
1.0*[8]/[1]* 100 as [8],
1.0*[9]/[1]* 100 as [9],
1.0*[10]/[1]* 100 as [10],
1.0*[11]/[1]* 100 as [11],
1.0*[12]/[1]* 100 as [12],
1.0*[13]/[1]* 100 as [13]
FROM #cohort_pivot
ORDER BY cohort_date
