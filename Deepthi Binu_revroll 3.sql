/*
Question #1: 
Identify installers who have participated in at least one installer competition by name.
Expected column names: name
Hint- not all installers have participated.
*/
--q1 solution
WITH ins_combined AS(
		SELECT installer_one_id AS installer_id,installer_one_time AS install_time
        FROM install_derby
        UNION
        SELECT installer_two_id AS installer_id,installer_two_time AS install_time
        FROM install_derby)
SELECT DISTINCT i.name
FROM installers i
LEFT JOIN ins_combined ins ON i.installer_id = ins.installer_id
where ins.install_time IS NOT NULL;
/*
Question #2: 
Write a solution to find the third transaction of every customer, where the spending on the 
preceding two transactions is lower than the spending on the third transaction. Only consider 
transactions that include an installation, and return the result table by customer_id in 
ascending order.
Expected column names: customer_id, third_transaction_spend, third_transaction_date
Hint/s - not every customer has at least three transactions
	   - not every order includes installation
*/
--q2 solution
WITH main_table AS
(SELECT *, (quantity*price) AS "spend"
 FROM installs
    JOIN orders ON installs.order_id = orders.order_id
    JOIN parts ON orders.part_id = parts.part_id),
    
 get_prior_spend AS (
    SELECT
        *
        , RANK() OVER (PARTITION BY customer_id ORDER BY install_date, spend desc) AS rk
        , LAG(spend) OVER (PARTITION BY customer_id ORDER BY install_date,spend desc) AS second_transaction_spend
        , LAG(spend, 2) OVER (PARTITION BY customer_id ORDER BY install_date, spend desc) AS first_transaction_spend
    FROM main_table
)
SELECT customer_id, spend AS third_transaction_spend, install_date AS third_transaction_date
FROM get_prior_spend
WHERE
    rk = 3
    AND spend > second_transaction_spend
    AND spend > first_transaction_spend
ORDER BY customer_id;

/*Question #3: 
Write a solution to report the most expensive part in each order. Only include installed orders. 
In case of a tie, report all parts with the maximum price. Order by order_id and limit the output 
to 5 rows.
Expected column names: order_id, part_id

Hint/s -before limiting, the complete output should have 850 rows.
			 -In the RevRoll DB, each order corresponds to only one part. But it is possible to write
       a query that will work in the general case where each order can correspond to multiple parts.
       This is because we have also included the condition that we should restrict the query to 
       installed parts only, and the installs table has a record for every part in the order.*/
--q3 solution
SELECT i.order_id,o.part_id
FROM orders o
LEFT JOIN parts p ON o.part_id = p.part_id
INNER JOIN installs i ON o.order_id = i.order_id
WHERE o.part_id IN (SELECT p.part_id FROM orders o1
									LEFT JOIN parts p1 ON o1.part_id = p1.part_id 
                  GROUP BY o1.order_id
                  HAVING MAX(price) IN (SELECT MAX(price)
                                      FROM parts p2
                                      WHERE p2.part_id = o1.part_id ))
ORDER BY i.order_id
LIMIT 5;

/*
Question #4:
Write a query to find the installers who have completed installations for at least four
consecutive days. Include the installer_id, start date of the consecutive installations 
period and the end date of the consecutive installations period. 

Return the result table ordered by installer_id in ascending order.
Expected column names: installer_id, consecutive_start,consecutive_end
*/
--q4 solution
WITH RECURSIVE consec_days AS(
			SELECT installer_id,install_date as start_date,install_date AS end_date,
						ROW_NUMBER()OVER(PARTITION BY installer_id ORDER BY install_date) AS rnk
      FROM installs
  		UNION
  		SELECT cd.installer_id,
  					CASE WHEN i.install_date = cd.end_date + INTERVAL '1 day' THEN cd.start_date
  					ELSE i.install_date
  					END AS start_date,
  					i.install_date AS end_date,
  					ROW_NUMBER() OVER(PARTITION BY i.installer_id ORDER BY i.install_date)as rnk
  		FROM consec_days cd JOIN installs i
  		ON cd.installer_id = i.installer_id AND  i.install_date = cd.end_date + INTERVAL '1 day'
			)
SELECT installer_id,
				MIN(start_date) AS consecutive_start,
        MAX(end_date) AS consecutive_end
FROM consec_days
WHERE end_date - start_date >=3
GROUP BY installer_id
ORDER BY installer_id;

      
      

      














