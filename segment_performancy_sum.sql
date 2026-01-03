/*  This project aims to identify distinct customer segments within a comprehensive e-commerce transactional dataset spanning from 2020 to 2023.
  	By applying RFM (Recency, Frequency, Monetary), this study provides actionable insights to optimize marketing spend and improve customer retention.
	  Skills used: Joins, CTEs (Common Table Expressions), Table Creation, Window Functions (NTILE), Aggregate Functions, Creating Views, Converting Data Types, and Handling Missing Values.
*/
-- Steps:
-- 1. Audit for missing values in all 13 columns
SELECT 
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(`Customer ID`) AS null_id,
    COUNT(*) - COUNT(`Purchase Date`) AS null_date,
    COUNT(*) - COUNT(`Product Category`) AS null_category,
    COUNT(*) - COUNT(`Product Price`) AS null_price,
    COUNT(*) - COUNT(`Quantity`) AS null_qty,
    COUNT(*) - COUNT(`Total Purchase Amount`) AS null_total_amount,
    COUNT(*) - COUNT(`Payment Method`) AS null_payment,
    COUNT(*) - COUNT(`Customer Age`) AS null_cust_age,
    COUNT(*) - COUNT(`Returns`) AS null_returns,
    COUNT(*) - COUNT(`Customer Name`) AS null_name,
    COUNT(*) - COUNT(`Age`) AS null_age,
    COUNT(*) - COUNT(`Gender`) AS null_gender,
    COUNT(*) - COUNT(`Churn`) AS null_churn
FROM ecom_cust_data;


-- 2. Create a cleaned view
CREATE OR REPLACE VIEW cleaned_data AS
SELECT 
    `Customer ID`,
    CAST(`Purchase Date` AS DATETIME) AS purchase_date,
    `Product Category`,
    `Total Purchase Amount`,
    `Payment Method`,
    `Age`, 
    `Gender`,
    `Churn`,
    COALESCE(`Returns`, 0) AS is_returned
FROM ecom_cust_data;


-- 3. Core Segmentation
-- Drop table first if you want to re-run the process
DROP TABLE IF EXISTS final_segmentation_result;

CREATE TABLE final_segmentation_result AS
WITH rfm_metrics AS (
    -- Step 3.1: Calculate raw RFM values
    SELECT 
        `Customer ID`,
        -- MySQL DATEDIFF(date1, date2) returns date1 - date2 in days
        DATEDIFF((SELECT MAX(purchase_date) FROM cleaned_data), MAX(purchase_date)) AS recency,
        COUNT(*) AS frequency,
        SUM(`Total Purchase Amount`) AS monetary
    FROM cleaned_data
    GROUP BY `Customer ID`
),
rfm_scores AS (
    -- 3.1 Assign scores 1-4
    SELECT *,
        NTILE(4) OVER (ORDER BY recency DESC) AS r_score,
        NTILE(4) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(4) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_metrics
)
	-- 3.2 Final Labeling
SELECT *,
    CASE 
        WHEN r_score = 4 AND f_score = 4 AND m_score = 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 2 AND f_score <= 2 THEN 'New/Promising'
        WHEN r_score = 1 THEN 'At Risk / Churn'
        ELSE 'Potential Loyalist'
    END AS customer_segment
FROM rfm_scores;


-- 4.1 Segment Performance Summary
SELECT 
    customer_segment,
    COUNT(*) AS total_customers,
    ROUND(AVG(recency), 2) AS avg_recency_days,
    ROUND(AVG(frequency), 2) AS avg_frequency,
    SUM(monetary) AS total_revenue
FROM final_segmentation_result
GROUP BY customer_segment
ORDER BY total_revenue DESC;

-- 4.2 Segment Behavior (Product Preference)
SELECT 
    s.customer_segment,
    c.`Product Category`,
    COUNT(*) AS purchase_count
FROM final_segmentation_result s
JOIN cleaned_data c ON s.`Customer ID` = c.`Customer ID`
GROUP BY s.customer_segment, c.`Product Category`
ORDER BY s.customer_segment, purchase_count DESC;


-- Query to generate the Customer Scoring Table
-- This table shows individual scores for each customer
SELECT 
    `Customer ID` AS customer_id,
    r_score AS recency_score,
    f_score AS frequency_score,
    m_score AS monetary_score
FROM final_segmentation_result
ORDER BY
	recency_score DESC,
	frequency_score DESC,
    monetary_score DESC;
