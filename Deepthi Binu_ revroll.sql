/*
Question #1: 
Installers receive performance based year end bonuses. Bonuses are calculated by taking 10% of the
total value of parts installed by the installer.

Calculate the bonus earned by each installer rounded to a whole number. Sort the result by bonus in
increasing order.

Expected column names: name, bonus
*/
--q1 solution
SELECT installers.name AS name,
				ROUND((0.1 * SUM(orders.quantity * parts.price))) AS bonus
FROM  installs
LEFT JOIN orders ON installs.order_id = orders.order_id
LEFT JOIN parts ON orders.part_id = parts.part_id
LEFT JOIN installers ON installs.installer_id = installers.installer_id
GROUP BY installers.name
ORDER BY bonus ASC;

/* Question #2: 
RevRoll encourages healthy competition. The company holds a “Install Derby” where installers
face off to see who can change a part the fastest in a tournament style contest.
Derby points are awarded as follows:

An installer receives three points if they win a match (i.e., Took less time to install the part).
An installer receives one point if they draw a match (i.e., Took the same amount of time as their
opponent).
An installer receives no points if they lose a match (i.e., Took more time to install the part).

We need to calculate the scores of all installers after all matches. Return the result table 
ordered by num_points in decreasing order. In case of a tie, order the records by installer_id 
in increasing order.


Expected column names: installer_id, name, num_points */
--q2 solution

WITH matchpoints AS( (SELECT installer_one_id AS installer_id,
                    				(CASE 	WHEN installer_one_time > installer_two_time THEN 3
        													WHEN installer_one_time = installer_two_time THEN 1
        													ELSE 0 END )AS points
                    FROM install_derby
                    GROUP BY installer_one_id, installer_two_id,2)
                    UNION ALL
                   	(SELECT installer_two_id AS installer_id,
                    				(CASE 	WHEN installer_two_time > installer_one_time THEN 3
        													WHEN installer_one_time = installer_two_time THEN 1
        													ELSE 0 END )AS points
                    FROM install_derby
                   GROUP BY installer_two_id, installer_one_id,2))
SELECT installers.installer_id AS installer_id,
				installers.name AS name,
        COALESCE(SUM(matchpoints.points),0) AS num_points
FROM installers
LEFT JOIN matchpoints
ON installers.installer_id = matchpoints.installer_id
GROUP BY installers.installer_id,installers.name
ORDER BY num_points DESC, installer_id DESC;

/* 
Question #3:
Write a query to find the fastest install time with its corresponding derby_id for each installer.
In case of a tie, you should find the install with the smallest derby_id.

Return the result table ordered by installer_id in ascending order.


Expected column names: derby_id, installer_id, install_time */
--q3 solution

WITH installtime AS(SELECT derby_id, 
							installer_one_id AS installer_id, 
                    		installer_one_time AS install_time
					FROM install_derby
					GROUP BY installer_one_id, derby_id
					UNION ALL
					SELECT derby_id, installer_two_id AS installer_id, 
                    		installer_two_time AS install_time
					FROM install_derby
					GROUP BY installer_two_id, derby_id ),
    Fastestinstalls AS (SELECT derby_id,
                           		installer_id,
                           		install_time,
                           		ROW_NUMBER()OVER(partition by installer_id ORDER BY install_time,derby_id) AS row_num
                        FROM installtime)
SELECT derby_id, installer_id, install_time
FROM Fastestinstalls
WHERE row_num = 1
ORDER BY installer_id;

/*Question #4: 
Write a solution to calculate the total parts spending by customers paying for installs on each 
Friday of every week in November 2023. If there are no purchases on the Friday of a particular week,
the parts total should be set to 0.

Return the result table ordered by week of month in ascending order.


Expected column names: november_fridays, parts_total*/
--q4 solution

WITH nov_fridays AS(SELECT order_id , 
                      		CASE 
                              	WHEN EXTRACT(MONTH FROM install_date) = 11 AND  EXTRACT(DOW FROM install_date) = 5
                              	THEN install_date
                              	ELSE NULL 
                            END AS nov_friday
                      FROM installs),
  only_fridays AS(SELECT 	order_id,
                      		nov_friday,
                            ROW_NUMBER() OVER(PARTITION BY nov_friday ORDER BY nov_friday) AS row_num
                      FROM nov_fridays
                      WHERE nov_friday IS NOT NULL)
  SELECT o.nov_friday,
  			ROUND(COALESCE(SUM(parts.price * orders.quantity),0),1) AS parts_total
  FROM only_fridays o
  LEFT JOIN orders ON o.order_id = orders.order_id
  LEFT JOIN parts ON orders.part_id = parts.part_id
  GROUP BY o.nov_friday
  ORDER BY o.nov_friday;
  
--by Deepthi Binu

                    
                      																										

















