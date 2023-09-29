----Amazon India Q2 Sales Report

--Dataset used: https://www.kaggle.com/datasets/thedevastator/unlock-profits-with-e-commerce-sales-data?resource=download

--Use only Q2 data

--Clean and explore data for various insights on what drives sales

--Provide a Dashboard with the following:
---Show Total sales and provide a filter for months + comparison chart
---Who fullfilled the orders (%)
---Which category had the highest sales
---Which States had the highest sales + filled map

-----------------------------------------------------------------------------------------

--Clean DATA

Select * 
From 
SalesReport 

--Delete Unused Columns

Alter Table 
  SalesReport 
DROP 
  COLUMN [Unnamed: 22], 
  [fulfilled-by], 
  [ship-country], 
  [currency], 
  [Sales Channel ]

--Check for duplicates

WITH rownumcte
     AS (SELECT *,
                Row_number()
                  OVER (
                    partition BY [order id], [date], [sku], [asin]
                    ORDER BY [order id] ) row_num
         FROM   salesreport)
SELECT *
FROM   rownumcte
WHERE  row_num > 1
ORDER  BY date 

--Delete Duplicates

WITH rownumcte
     AS (SELECT *,
                Row_number()
                  OVER (
                    partition BY [order id], [date], [sku], [asin]
                    ORDER BY [order id] ) row_num
         FROM   salesreport)
DELETE FROM rownumcte
WHERE  row_num > 1 


-- Fill NULL values

UPDATE SalesReport
SET [promotion-ids] = 'No promotion'
WHERE [promotion-ids] IS NULL;

UPDATE SalesReport
SET [Courier Status] = 'Unknown'
WHERE [Courier Status] IS NULL;

UPDATE SalesReport
SET [Amount] = '0'
WHERE [Amount] IS NULL;

UPDATE SalesReport
SET [ship-city] = 'Unknown'
WHERE [ship-city] IS NULL;

UPDATE SalesReport
SET [ship-state] = 'Unknown'
WHERE [ship-state] IS NULL;

UPDATE SalesReport
SET [ship-postal-code] = '0'
WHERE [ship-postal-code] IS NULL;

--Add Month column and rename

ALTER TABLE SalesReport
ADD Month NVARCHAR(200)

UPDATE SalesReport
SET Month = MONTH(date)

	Update SalesReport
SET Month = CASE When Month = '3' THEN 'March'
	   When Month = '4' THEN 'April'
	   When Month = '5' THEN 'May'
	   When Month = '6' THEN 'June'
	   ELSE Month
	   End

Select (Month), count([Order ID])
from SalesReport
group by MONTH  

--Drop March as requested

DELETE FROM SalesReport
WHERE Month = 'March'

-- Rename columns

EXEC sp_Rename 'SalesReport.ship-service-level', 'ServiceLevel', 'COLUMN'
EXEC sp_Rename 'SalesReport.Courier Status', 'CourierStatus', 'COLUMN'
EXEC sp_Rename 'SalesReport.ship-city', 'City', 'COLUMN'
EXEC sp_Rename 'SalesReport.ship-state', 'State', 'COLUMN'
EXEC sp_Rename 'SalesReport.ship-postal-code', 'Zip', 'COLUMN'
EXEC sp_Rename 'SalesReport.promotion-ids', 'PromotionID', 'COLUMN'
EXEC sp_Rename 'SalesReport.B2B', 'CustomerType', 'COLUMN'

-- Convert CustomerType values

ALTER TABLE SalesReport
ALTER COLUMN CustomerType NVARCHAR(200)

	Update SalesReport
SET CustomerType = CASE When CustomerType = '0' THEN 'Consumer'
	   When CustomerType = '1' THEN 'Business'
	   ELSE CustomerType
	   End

-- Convert INR to USD

CREATE TABLE #ExchangeRates (
    Currency NVARCHAR(3),
    Rate DECIMAL(18, 6)
)

INSERT INTO #ExchangeRates (Currency, Rate)
VALUES ('INR', 0.012)

UPDATE SalesReport
SET Amount = Amount * (SELECT Rate FROM #ExchangeRates WHERE Currency = 'INR');

DROP TABLE #ExchangeRates


-----------------------------------------------------------------------------------------


select * 
From SalesReport


-----------------------------------------------------------------------------------------

--EDA

--What is the total revenue generated for each category

SELECT Category,
       Round(Sum(amount),2) AS TotalRevenue
FROM   salesreport
GROUP  BY Category


--What is the overall average order value?

SELECT Round(Avg(amount), 2) AS AverageAmountSpent
FROM   salesreport

--What is the average order amount per month?

SELECT Month,
       Round(Avg(amount), 2) AS AverageSpentPerMonth
FROM   salesreport
GROUP  BY Month
ORDER  BY averagespentpermonth 


--What are the peak sales periods (by month)?

SELECT Month,
       Round(Sum(amount), 2) AS TotalRevenue
FROM   salesreport
GROUP  BY Month
ORDER  BY totalrevenue DESC 


--What are the top 10 states for sales?

SELECT TOP 10 State,
              Round(Sum(amount), 2) AS TotalRevenue
FROM   salesreport
GROUP  BY State
ORDER  BY totalrevenue DESC 


--What percentage of orders are fulfilled by Amazon vs Merchant?

SELECT Fulfilment,
       Count([order id])                                             AS
       TotalOrders,
       Cast(Count([order id]) * 100.0 / Sum(Count([order id]))
                                          OVER () AS DECIMAL(10, 2)) AS
       PercentageOfTotalOrders
FROM   salesreport
GROUP  BY fulfilment; 

-----------------------------------------------------------------------------------------

select *
from SalesReport --export data for viz

--Dashboard

https://app.powerbi.com/view?r=eyJrIjoiYjk3NDIwNzctMTQxZS00MjE0LThjZWEtNGZjYTIxMjU3MGU2IiwidCI6ImRmODY3OWNkLWE4MGUtNDVkOC05OWFjLWM4M2VkN2ZmOTVhMCJ9
