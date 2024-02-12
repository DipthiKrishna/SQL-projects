/* 
Question 1
Calculate the proportion of sessions abandoned in summer months (June, July, August) and 
compare it to the proportion of sessions abandoned in non-summer months. Round the output to 
3 decimal places. The definition of session abandonment is “a browsing session that does not 
result in booked flight or hotel”

Expected column names: summer_abandon_rate, other_abandon_rate*/

--q1 solution

WITH summer_abandon AS (SELECT COUNT(*) AS total_summer_sessions,
			COUNT(CASE WHEN (flight_booked OR hotel_booked) THEN NULL ELSE 1 END) AS summer_abandon_sessions			
			FROM sessions
			WHERE EXTRACT(MONTH FROM session_start) IN (6,7,8)),
     other_abandon AS(SELECT COUNT(*) AS total_other_sessions,
  			COUNT(CASE WHEN (flight_booked OR hotel_booked) THEN NULL ELSE 1 END) AS other_abandon_sessions			
			FROM sessions
			WHERE EXTRACT(MONTH FROM session_start) NOT IN (6,7,8))

SELECT ROUND((summer_abandon.summer_abandon_sessions/NULLIF(summer_abandon.total_summer_sessions,0.0)),3) AS summer_abandon_rate,
		ROUND((other_abandon.other_abandon_sessions/NULLIF(other_abandon.total_other_sessions,0.0)),3) AS other_abandon_rate
FROM summer_abandon,other_abandon ;



/*
Question 2 
Bin customers according to their place in the session abandonment distribution as follows: 

1. number of abandonments greater than one standard deviation more than the mean. Call these customers “gt”.
2. number of abandonments fewer than one standard deviation less than the mean. Call these customers “lt”.
3. everyone else (the middle of the distribution). Call these customers “middle”.

calculate the number of customers in each group, the mean number of abandonments in each group, 
and the range of abandonments in each group.The definition of session abandonment is “a browsing session that does not 
result in booked flight or hotel
Expected column names: distribution_loc, abandon_n, abandon_avg, abandon_range*/
--q2 solution 

WITH cust_abandonments AS 	(SELECT user_id,
       				COUNT(*) AS abandon_n,
                           	STDDEV(COUNT(*)) OVER () AS standdev_abands,
                           	AVG(COUNT(*)) OVER () AS mean_abands
                           	FROM sessions
                           	WHERE flight_booked IS FALSE AND hotel_booked IS FALSE
                           	GROUP BY user_id),
           	abandon_bins AS(SELECT user_id,
                           	CASE WHEN abandon_n > (standdev_abands + mean_abands) THEN 'gt'
                           	     WHEN abandon_n < (mean_abands - standdev_abands) THEN 'lt'
                           	     ELSE 'middle' END AS distribution_loc,
                           	abandon_n
                          	 FROM cust_abandonments)
SELECT distribution_loc,
	COUNT(DISTINCT user_id) AS customer_count, 
        AVG(abandon_n) AS abandon_avg, 
        (MAX(abandon_n)-MIN(abandon_n)) AS abandon_range
FROM abandon_bins
GROUP BY distribution_loc;
                           

/*
Question 3
Calculate the total number of abandoned sessions and the total number of sessions that resulted in a 
booking per day, but only for customers who reside in one of the top 5 cities (top 5 in terms of total 
number of users from city). Also calculate the ratio of booked to abandoned for each day. Return only 

the 5 most recent days in the dataset.

Expected column names: session_date, abandoned,booked, book_abandon_ratio 
new york, los angeles, toronto, chicago, houston */

--q3 solution

WITH top_cities AS	(SELECT home_city,
			  			COUNT(*) AS users
		   			FROM users
		   			GROUP BY home_city
		   			ORDER BY users DESC
		   			LIMIT 5),
   
     date_status AS (SELECT DATE(session_start) AS session_date,
  							COUNT(CASE WHEN flight_booked IS FALSE AND hotel_booked IS FALSE THEN 1 END) AS abandoned,
        					COUNT(CASE WHEN flight_booked IS TRUE OR hotel_booked IS TRUE THEN 1 END) AS booked
		     		FROM sessions
                    WHERE user_id IN (SELECT user_id FROM users WHERE home_city IN (SELECT home_city FROM top_cities))
    				GROUP BY session_date
   					ORDER BY session_date DESC)
                            
SELECT session_date,
    	abandoned,
    	booked,
    	ROUND(CASE WHEN abandoned > 0 THEN booked::numeric / abandoned END,3) AS book_abandon_ratio
FROM date_status
WHERE ROUND(CASE WHEN abandoned > 0 THEN booked::numeric / abandoned END,3) IS NOT NULL
LIMIT 5;


/*
Question 4
Densely rank users from Saskatoon based on their ratio of successful bookings to abandoned bookings.
then count how many users share each rank, with the most common ranks listed first.The definition of session abandonment
is “a browsing session that does not result in booked flight or hotel.

note: if the ratio of bookings to abandons is null for a user, use the average bookings/abandons ratio of all Saskatoon users.
Expected column names: ba_rank, rank_count */
--q4 solution:

WITH saskatoon_users AS(SELECT user_id,
							COUNT(CASE WHEN flight_booked IS FALSE AND hotel_booked IS FALSE THEN 1 END) AS abandon_n,
      						COUNT(CASE WHEN flight_booked IS TRUE OR hotel_booked IS TRUE THEN 1 END) AS success_n
						FROM sessions
                        GROUP BY user_id
                        HAVING user_id IN (SELECT user_id
                                           FROM users
                                           WHERE home_city = 'saskatoon')),
                                           
    succes_abandon_ratio AS( SELECT NULLIF(COALESCE(ROUND(success_n/NULLIF(abandon_n,0),3),AVG(success_n/NULLIF(abandon_n,0)) OVER()),0.0) AS succ_aban_ratio
                            FROM saskatoon_users
                           )
                            
SELECT RANK() OVER (ORDER BY succ_aban_ratio DESC) AS ba_rank, COUNT(*) AS rank_count
FROM succes_abandon_ratio
GROUP BY succ_aban_ratio
ORDER BY rank_count DESC;


              










