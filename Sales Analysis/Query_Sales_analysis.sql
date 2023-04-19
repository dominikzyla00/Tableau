-- Inspecting Data

  select * from Sales_Analysis.dbo.Sales

  --- Lets add year,quarter and month column and extract them from order_date column
  ALTER TABLE Sales_Analysis.dbo.Sales
  ADD Year int

  UPDATE Sales_Analysis.dbo.Sales
  SET Year = YEAR(Order_Date)


  ALTER TABLE Sales_Analysis.dbo.Sales
  ADD Quarter int

  UPDATE Sales_Analysis.dbo.Sales
  SET Quarter = DATEPART(q,Order_Date)


  ALTER TABLE Sales_Analysis.dbo.Sales
  ADD Month int

  UPDATE Sales_Analysis.dbo.Sales
  SET Month = MONTH(Order_Date)


 -- Checking unique values
  SELECT distinct country from Sales_Analysis.dbo.Sales -- only US
  SELECT distinct city from Sales_Analysis.dbo.Sales --- 529 cities
  SELECT distinct State from Sales_Analysis.dbo.Sales -- 49 states
  SELECT distinct region from Sales_Analysis.dbo.Sales -- 4 regions
  SELECT distinct Category from Sales_Analysis.dbo.Sales -- 3 categories
  SELECT count(distinct product_name) from Sales_Analysis.dbo.Sales -- 1849 distinct products
  SELECT distinct sub_category from Sales_Analysis.dbo.Sales  -- 17 categories
  select distinct segment from Sales_Analysis.dbo.Sales -- 3 segments
  select distinct ship_mode from Sales_Analysis.dbo.Sales -- 4 ship modes

  -- ANALYSIS

  --- Let`s check best selling product categories
  SELECT category, 
  ROUND(sum(sales),2) as Sales 
  FROM Sales_Analysis.dbo.Sales
  GROUP BY category
  ORDER BY 2 DESC


  --- Let`s check in which state products sell the most
  SELECT State, 
  ROUND(sum(sales),2) as Sales 
  FROM Sales_Analysis.dbo.Sales
  GROUP BY state
  ORDER BY 2 DESC


  --- Let`s check in which year company sales were the highest
  SELECT YEAR, 
  ROUND(sum(sales),2) as Sales 
  FROM Sales_Analysis.dbo.Sales
  GROUP BY YEAR
  ORDER BY 2 DESC

  
  --- We can see company had pretty good sales growth let`s see how much is it exactly
 WITH cte1 as (
	  SELECT  sum(sales) as sales15
	  FROM Sales_Analysis.dbo.Sales
	  WHERE Year = 2015),
	  cte2 as (
	  SELECT sum(sales) as sales18
	  FROM Sales_Analysis.dbo.Sales
	  WHERE Year = 2018)

  SELECT (sales18 - sales15)/sales15*100 as sales_growth
  FROM cte1
  JOIN cte2
  ON 1 = 1


  --- What was the best selling month in a specific year? How many products were sold and how much was earned that month?
  SELECT MONTH, 
  sum(sales) as revenue, 
  count(order_id) as num_of_orders
  FROM Sales_Analysis.dbo.Sales
  WHERE Year = 2018
  GROUP BY month
  ORDER BY 2 DESC


  -- November sees to be the month, what product category was selling the most
  SELECT category, 
  sum(sales) as revenue
  FROM Sales_Analysis.dbo.Sales
  where year = 2018 
  and month = 11
  GROUP BY category
  ORDER BY 2 DESC


  //*Let`s group customers using RFM Analysis
  The “RFM” in RFM analysis stands for recency, frequency and monetary value. RFM analysis is a way to 
  use data based on existing customer behavior to predict how a new customer is likely to act in the future. 
  An RFM model is built using  three key factors: how recently a customer has transacted with a brand, 
  how frequently they’ve engaged with a brand how much money they’ve spent on a brand’s products and services *//


  DROP TABLE IF EXISTS #rfm 
  ;with rfm as
  (
	  SELECT Customer_name,
		  round(sum(sales),2) as monetary_value,
		  round(avg(sales),2) as average_monetary_value,
		  count(distinct order_id) as frequency,
		  max(order_date) as last_order_date,
		  (SELECT max(order_date) from Sales_Analysis.dbo.Sales) as last_customer_order_date,
		  DATEDIFF(DD,max(order_date),(SELECT max(order_date) from Sales_Analysis.dbo.Sales)) as recency -- How many days have passed since the last order for a customer compared to the date of the company's last order
	  FROM Sales_Analysis.dbo.Sales
	  GROUP BY Customer_Name 
 ),
 rfm_rank as 
 (

	 SELECT *,
	    NTILE(4) OVER (order by recency DESC) rfm_recency,
	    NTILE(4) OVER (order by monetary_value) rfm_monetary,
		NTILE(4) OVER (order by frequency) rfm_frequency
	FROM rfm
)

SELECT *, rfm_monetary+rfm_frequency+rfm_recency as rfm_sum,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar) as rfm_sum_string
into #rfm -- Lets`s create temp table so we don't have to run this whole query everytime
FROM rfm_rank 


-- Let`s group customers and finish our analysis
select customer_name,
rfm_recency,
rfm_frequency,
rfm_monetary,
rfm_sum_string,
	CASE
		WHEN rfm_sum_string in (111,112,113,114,121,122,123,124,131,132,141,142,211,212,213,214,221,222,231,232,241,242,223) then 'lost customer' -- lost customers
		WHEN rfm_sum_string in (133,134,143,144,233,234,243,244,244) then 'big customer, cannot lose' -- big customers that we can't lose
		WHEN rfm_sum_string in (311,411,412,413,414,312,313,314) then 'new customer'
		WHEN rfm_sum_string in (321,422,323,324,331,332,333,334,341,342,343,344,422,432,431,441,423,421) then 'active customer'
		When rfm_sum_string in (444,443,433,434,424,442) then 'loyal customer'
		end rfm_segment
from #rfm


  
