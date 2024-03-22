/*
Question #1: 
Write a query to find the customer(s) with the most orders. Return only the preferred name.
Expected column names: preferred_name
*/
--q1 solution
WITH order_count AS(SELECT customer_id,COUNT(order_id) AS num_orders
                  FROM orders
                  GROUP BY customer_id)
SELECT c.preferred_name AS preferred_name
FROM customers c
JOIN order_count oc ON c.customer_id = oc.customer_id
WHERE oc.num_orders= (SELECT MAX(num_orders) FROM order_count);

/*
Question #2: 
RevRoll does not install every part that is purchased. Some customers prefer to install parts 
themselves. This is a valuable line of business RevRoll wants to encourage by finding valuable 
self-install customers and sending them offers.
Return the customer_id and preferred name of customers who have made at least $2000 of purchases 
in parts that RevRoll did not install. 
Expected column names: customer_id, preferred_name
*/
--q2 solution
SELECT o.customer_id, c.preferred_name
FROM orders o
JOIN parts p ON o.part_id = p.part_id
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN installs i ON o.order_id = i.order_id
WHERE i.order_id IS NULL
GROUP BY o.customer_id, c.preferred_name
HAVING SUM(p.price*o.quantity) >=2000
ORDER BY o.customer_id;

/*
Question #3: 
Report the id and preferred name of customers who bought an Oil Filter and Engine Oil but did not 
buy an Air Filter since we want to recommend these customers buy an Air Filter.
Return the result table ordered by customer_id.

Expected column names: customer_id, preferred_name
*/
--q3 solution
SELECT o.customer_id, c.preferred_name
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN parts p ON o.part_id = p.part_id
WHERE LOWER(p.name) IN ('oil filter','engine oil','air filter')
GROUP BY o.customer_id,c.preferred_name
HAVING COUNT(DISTINCT CASE WHEN LOWER(p.name)='oil filter' THEN p.part_id END)>0
	 AND COUNT(DISTINCT CASE WHEN LOWER(p.name)='engine oil' THEN p.part_id END)>0
   AND COUNT(DISTINCT CASE WHEN LOWER(p.name)='air filter' THEN p.part_id END)=0
ORDER BY o.customer_id;
/*
Write a solution to calculate the cumulative part summary for every part that the RevRoll team has
installed.

The cumulative part summary for an part can be calculated as follows:

-For each month that the part was installed, sum up the price*quantity in that month and the previous
two months. This is the 3-month sum for that month. If a part was not installed in previous months, 
the effective price*quantity for those months is 0.
-Do not include the 3-month sum for the most recent month that the part was installed.
-Do not include the 3-month sum for any month the part was not installed.

Return the result table ordered by part_id in ascending order. In case of a tie, order it by month 
in descending order. Limit the output to the first 10 rows.

Expected column names: part_id, month, part_summary
*/
--q4 solution
WITH monthly_totals AS (
    SELECT
        o.part_id,
        EXTRACT(MONTH FROM i.install_date) AS install_month,
        SUM(o.quantity * p.price) AS monthly_total
    FROM
        installs i
    JOIN
        orders o ON i.order_id = o.order_id
    JOIN
        parts p ON o.part_id = p.part_id
    GROUP BY
        o.part_id,
        EXTRACT(MONTH FROM i.install_date)
    HAVING
        EXTRACT(MONTH FROM i.install_date) <> (SELECT EXTRACT(MONTH FROM MAX(install_date)) FROM installs) 
   ),
cumulative_summary AS (
    SELECT
        m1.part_id,
        m1.install_month,
        COALESCE(SUM(m2.monthly_total), 0) AS part_summary
    FROM
        monthly_totals m1
    LEFT JOIN
        monthly_totals m2 ON m1.part_id = m2.part_id
                           AND m1.install_month >= m2.install_month
                           AND m1.install_month - m2.install_month <= 2
    GROUP BY
        m1.part_id,
        m1.install_month
)
SELECT
    part_id,
    install_month,
    ROUND(part_summary, 2) AS part_summary
FROM
    cumulative_summary
ORDER BY
    part_id,
    install_month DESC
LIMIT 10;
----Query By Deepthi Binu





