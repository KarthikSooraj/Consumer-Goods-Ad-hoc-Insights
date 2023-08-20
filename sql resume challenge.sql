#1.Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

SELECT * FROM gdb023.dim_customer
where customer="Atliq Exclusive" and region = "APAC";

#2.What is the percentage of unique product increase in 2021 vs. 2020? 
#The final output contains these fields, unique_products_2020 unique_products_2021 percentage_chg

SELECT X.A AS unique_product_2020, Y.B AS unique_products_2021, ROUND((B-A)*100/A, 2) AS percentage_chg
FROM
     (
      (SELECT COUNT(DISTINCT(product_code)) AS A FROM fact_sales_monthly
      WHERE fiscal_year = 2020) X,
      (SELECT COUNT(DISTINCT(product_code)) AS B FROM fact_sales_monthly
      WHERE fiscal_year = 2021) Y 
	 );
     
#3.Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
 #The final output contains 2 fields, segment product_count
 
 select segment,count(distinct product_code) as product_count
 from dim_product
 group by segment
 order by product_count; 
 
 #4.Which segment had the most increase in unique products in 2021 vs 2020? 
 #The final output contains these fields; segment,product_count_2020,product_count_2021,difference

WITH CTE1 AS 
	(SELECT P.segment AS A , COUNT(DISTINCT(FS.product_code)) AS B 
    FROM dim_product P, fact_sales_monthly FS
    WHERE P.product_code = FS.product_code
    GROUP BY FS.fiscal_year, P.segment
    HAVING FS.fiscal_year = "2020"),
CTE2 AS
    (
	SELECT P.segment AS C , COUNT(DISTINCT(FS.product_code)) AS D 
    FROM dim_product P, fact_sales_monthly FS
    WHERE P.product_code = FS.product_code
    GROUP BY FS.fiscal_year, P.segment
    HAVING FS.fiscal_year = "2021"
    )     
    
SELECT CTE1.A AS segment, CTE1.B AS product_count_2020, CTE2.D AS product_count_2021, (CTE2.D-CTE1.B) AS difference  
FROM CTE1, CTE2
WHERE CTE1.A = CTE2.C ;

#5. Get the products that have the highest and lowest manufacturing costs. 
#The final output should contain these fields; product_code, product, manufacturing_cost

 SELECT F.product_code, P.product, F.manufacturing_cost 
FROM fact_manufacturing_cost F 
JOIN dim_product P
ON F.product_code = P.product_code
 WHERE manufacturing_cost
IN (
	SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost
    UNION
    SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost
    ) 
ORDER BY manufacturing_cost DESC ;

#6.Generate a report which contains the top 5 customers
#who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. 
#The final output contains these fields, customer_code customer average_discount_percentage

SELECT c.customer_code, c.customer, round(AVG(pre_invoice_discount_pct),4) AS average_discount_percentage
FROM fact_pre_invoice_deductions d
JOIN dim_customer c ON d.customer_code = c.customer_code
WHERE c.market = "India" AND fiscal_year = "2021"
GROUP BY c.customer_code
ORDER BY average_discount_percentage DESC
LIMIT 5;

#7.Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month.
#The final report contains these columns: Month, Year, Gross sales, Amount

WITH cte1 AS (
    SELECT customer,
    monthname(date) AS months ,
    month(date) AS month_number, 
    year(date) AS year,
    (sold_quantity * gross_price)  AS gross_sales
 FROM fact_sales_monthly s 
 JOIN fact_gross_price g ON s.product_code = g.product_code
 JOIN dim_customer c ON s.customer_code=c.customer_code
 WHERE customer="Atliq exclusive"
)
SELECT months,year, concat(round(sum(gross_sales)/1000000,2),"M") AS gross_sales FROM cte1
GROUP BY year,months
ORDER BY year,month_number;

#8.In which quarter of 2020, got the maximum total_sold_quantity? 
#The final output contains these fields; sorted by the total_sold_quantity, Quarter, total_sold_quantity

SELECT 
CASE
    WHEN date BETWEEN '2019-09-01' AND '2019-11-01' then "Q1"  
    WHEN date BETWEEN '2019-12-01' AND '2020-02-01' then "Q2"
    WHEN date BETWEEN '2020-03-01' AND '2020-05-01' then "Q3"
    WHEN date BETWEEN '2020-06-01' AND '2020-08-01' then "Q4"
    END AS Quarters,
	round(sum(sold_quantity)/1000000,2) as total_sold_quanity_in_millions
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarters
ORDER BY total_sold_quanity_in_millions DESC;

#9.Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? 
#The final output contains these fields, channel, gross_sales_mln, percentage

WITH temp_table AS (
      SELECT c.channel,sum(s.sold_quantity * g.gross_price) AS total_sales
  FROM
  fact_sales_monthly s 
  JOIN fact_gross_price g ON s.product_code = g.product_code
  JOIN dim_customer c ON s.customer_code = c.customer_code
  WHERE s.fiscal_year= 2021
  GROUP BY c.channel
  ORDER BY total_sales DESC
)
SELECT 
channel,
  round(total_sales/1000000,2) AS gross_sales_in_millions,
  round(total_sales/(sum(total_sales) OVER())*100,2) AS percentage 
FROM temp_table ;

#10.Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? 
#The final output contains these fields;division, product_code,product,total_sold_quantity,rank_order

WITH temp_table AS (
    select division, s.product_code, concat(p.product,"(",p.variant,")") AS product , 
    sum(sold_quantity) AS total_sold_quantity,
    rank() OVER (partition by division order by sum(sold_quantity) desc) AS rank_order
 FROM
 fact_sales_monthly s
 JOIN dim_product p
 ON s.product_code = p.product_code
 WHERE fiscal_year = 2021
 GROUP BY product_code
)
SELECT * FROM temp_table
WHERE rank_order IN (1,2,3);
