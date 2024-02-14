/*
Question #1: 
Installers receive performance based year end bonuses. Bonuses are calculated by taking 10% of the
total value of parts installed by the installer.

Calculate the bonus earned by each installer rounded to a whole number. Sort the result by bonus in
increasing order.

Expected column names: name, bonus
*/
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
