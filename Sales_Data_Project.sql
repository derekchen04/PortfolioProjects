-- Inspecting Data

SELECT * FROM dbo.sales_data_sample;

-- Alter data type of 'orderdate' column from DATETIME to DATE

ALTER TABLE dbo.sales_data_sample
ALTER COLUMN orderdate DATE;

-- Renaming Columns

SP_RENAME 'dbo.sales_data_sample.ordernumber', 'order_number', 'COLUMN'
SP_RENAME 'dbo.sales_data_sample.quantityordered', 'quantity_ordered', 'COLUMN'
SP_RENAME 'dbo.sales_data_sample.priceeach', 'price_each', 'COLUMN'
SP_RENAME 'dbo.sales_data_sample.orderlinenumber', 'order_line_number', 'COLUMN'
SP_RENAME 'dbo.sales_data_sample.sales', 'sales', 'COLUMN'
SP_RENAME 'dbo.sales_data_sample.qtr_id', 'qtr', 'COLUMN'
SP_RENAME 'dbo.sales_data_sample.month_id', 'month', 'COLUMN'
SP_RENAME 'dbo.sales_data_sample.year_id', 'year', 'COLUMN'
SP_RENAME 'dbo.sales_data_sample.orderdate', 'order_date', 'COLUMN'
SP_RENAME 'dbo.sales_data_sample.status', 'status', 'COLUMN'
SP_RENAME 'dbo.sales_data_sample.productline', 'product_line', 'COLUMN'
SP_RENAME 'dbo.sales_data_sample.productcode', 'product_code', 'COLUMN'
SP_RENAME 'dbo.sales_data_sample.customername', 'company_name', 'COLUMN'
SP_RENAME 'dbo.sales_data_sample.phone', 'phone_no', 'COLUMN'
SP_RENAME 'dbo.sales_data_sample.addressline1', 'address_line_1', 'COLUMN'
SP_RENAME 'dbo.sales_data_sample.addressline2', 'address_line_2', 'COLUMN'
SP_RENAME 'dbo.sales_data_sample.city', 'city', 'COLUMN'
SP_RENAME 'dbo.sales_data_sample.state', 'state', 'COLUMN'
SP_RENAME 'dbo.sales_data_sample.postalcode', 'postal_code', 'COLUMN'
SP_RENAME 'dbo.sales_data_sample.country', 'country', 'COLUMN'
SP_RENAME 'dbo.sales_data_sample.territory', 'territory', 'COLUMN'
SP_RENAME 'dbo.sales_data_sample.contactlastname', 'contact_last_name', 'COLUMN'
SP_RENAME 'dbo.sales_data_sample.contactfirstname', 'contact_first_name', 'COLUMN'
SP_RENAME 'dbo.sales_data_sample.dealsize', 'deal_size', 'COLUMN';

-- Checking unique values

SELECT DISTINCT status FROM dbo.sales_data_sample 
SELECT DISTINCT year FROM dbo.sales_data_sample
SELECT DISTINCT productline FROM dbo.sales_data_sample 
SELECT DISTINCT country FROM dbo.sales_data_sample 
SELECT DISTINCT dealsize FROM dbo.sales_data_sample 
SELECT DISTINCT territory FROM dbo.sales_data_sample 
SELECT DISTINCT territory FROM dbo.sales_data_sample

-- ANALYSIS 

-- Grouping Sales by Product Line

SELECT product_line, SUM(sales) revenue
FROM dbo.sales_data_sample
GROUP BY product_line
ORDER BY 2 DESC;

SELECT year, SUM(sales) revenue
FROM dbo.sales_data_sample
GROUP BY year
ORDER BY 2 DESC; -- Noticed that sales in 2005 were much lower than 2003 and 2004

SELECT DISTINCT month FROM dbo.sales_data_sample
WHERE year_id = 2005; -- Discovered that sales were only recorded for five months

SELECT deal_size, SUM(sales) revenue
FROM dbo.sales_data_sample
GROUP BY deal_size
ORDER BY 2 DESC;

-- What was the best month for sales in a specific year? How much was earned?

SELECT month, SUM(sales) revenue, COUNT(order_number) frequency
FROM dbo.sales_data_sample
WHERE year = 2004
GROUP BY month
ORDER BY 2 DESC;

-- November seems to be the month, what product do they sell in November, classic I believe

SELECT month, product_line, SUM(sales) revenue, COUNT(order_number)
FROM dbo.sales_data_sample
WHERE year = 2004 and month = 11 -- Change year to see the rest
GROUP BY month, product_line
ORDER BY 3 DESC; 

-- Who is our best customer (this could be best answered with Recency-Frequency-Monetary (RFM))

DROP TABLE IF EXISTS #rfm
;WITH rfm AS
(
    SELECT
        company_name,
        SUM(sales) monetary_value,
        AVG(sales) avg_monetary_value,
        COUNT(order_number) frequency,
        MAX(order_date) last_order_date,
        (SELECT MAX(order_date) FROM dbo.sales_data_sample) max_order_date,
        DATEDIFF(DD, MAX(order_date), (SELECT MAX(order_date) FROM dbo.sales_data_sample)) recency
    FROM dbo.sales_data_sample
    GROUP BY company_name
),
rfm_calc AS
(
SELECT r.*,
    NTILE(4) OVER (ORDER BY recency DESC) rfm_recency,
    NTILE(4) OVER (ORDER BY frequency) rfm_frequency,
    NTILE(4) OVER (ORDER BY monetary_value) rfm_monetary
FROM rfm r
)
SELECT
    c.*, rfm_recency + rfm_frequency + rfm_monetary rfm_cell,
    CAST(rfm_recency AS VARCHAR) + CAST(rfm_frequency AS VARCHAR) + CAST(rfm_monetary AS VARCHAR) rfm_cell_string
INTO #rfm
FROM rfm_calc c;

SELECT company_name, rfm_recency, rfm_frequency, rfm_monetary,
    CASE 
        WHEN rfm_cell_string in (111, 112, 121, 122, 123, 132, 211, 212, 114, 141) THEN 'lost_customers' -- lost cutomers
        WHEN rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) THEN 'slipping away, cannot lose' -- Big spenders who haven't purchased recently - at risk to lose
        WHEN rfm_cell_string in (311, 411, 331) THEN 'new_customers'
        WHEN rfm_cell_string in (222, 223, 233, 322) THEN 'potential_churners'
        WHEN rfm_cell_string in (323, 333, 321, 422, 332, 432) THEN 'active' -- cutomers who buy often & recently but at low price points
        WHEN rfm_cell_string in (433, 434, 443, 444) THEN 'loyal'
    END rfm_segment
FROM #rfm

-- What products are sold together most often?
-- SELECT * FROM dbo.sales_data_sample WHERE order_number = 10411

SELECT DISTINCT order_number, STUFF(
    (SELECT ', ' + product_code
    FROM dbo.sales_data_sample p
    WHERE order_number IN
        (
            SELECT order_number
            FROM (
                SELECT order_number, COUNT(*) rn
                FROM dbo.sales_data_sample
                WHERE status = 'Shipped'
                GROUP BY order_number
            )m
            WHERE rn = 3
        )
        AND p.order_number = s.order_number
        FOR XML PATH (''))
        , 1, 1, '') product_codes
FROM dbo.sales_data_sample s
ORDER BY 2 DESC

-- EXTRA -- 

-- What city has the highest number of sales in a specific country?

SELECT city, SUM(sales) revenue
FROM dbo.sales_data_sample
WHERE country = 'France'
GROUP BY city
ORDER BY 2 DESC

-- What is the best product in the United States?

SELECT country, year, product_line, SUM(sales) revenue
FROM dbo.sales_data_sample
WHERE country = 'USA'
GROUP BY country, year, product_line
ORDER BY 4 DESC