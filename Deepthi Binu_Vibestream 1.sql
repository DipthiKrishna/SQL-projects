/*
Question #1: 
Return the percentage of users who have posted more than 10 times rounded to 3 decimals.

Expected column names: more_than_10_posts */
--q1 solution : 
WITH user_posts AS 	(SELECT u.user_id , COUNT(p.post_id) AS post_counts
										FROM users u
                    LEFT JOIN posts p
                    ON p.user_id = u.user_id
										GROUP BY u.user_id)
SELECT
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM users)/100.0 ,3) AS more_than_10_posts
FROM
    user_posts
WHERE
    post_counts > 10;

/*
Question  2
Recommend posts to user 888 by finding posts liked by users who have liked a post user 888 has also 
liked more than one time. 
The output should adhere to the following requirements: 
User 888 should not be recommend posts that they have already liked.
Of the posts that meet the criteria above, return only the three most popular posts (by number of likes).
Return the post_ids in descending order.

Expected column names: post_id
*/
--q2 solution
WITH likedposts AS  (SELECT post_id
                     FROM likes WHERE user_id = 888), 
similarlike_users AS 
					(SELECT user_id ,COUNT(like_id) AS no_of_likes
                    FROM likes
                    WHERE post_id IN (SELECT post_id
                     									FROM likedposts) AND user_id != 888
                    GROUP BY user_id
                    HAVING COUNT(like_id) > 1 ),
recommended_posts AS (SELECT post_id ,COUNT(likes.user_id) AS like_count
                      FROM likes
                      WHERE post_id NOT IN (SELECT post_id FROM likedposts)
                      AND
                      user_id IN (SELECT user_id FROM similarlike_users)
                      GROUP BY post_id
                      ORDER BY like_count DESC
                      LIMIT 3)
SELECT post_id
FROM recommended_posts;
               
/*
Question #3: 
Vibestream wants to track engagement at the user level. When a user makes their first post, 
the team wants to begin tracking the cumulative sum of posts over time for the user.

Return a table showing the date and the total number of posts user 888 has made to date. 
The time series should begin at the date of 888’s first post and end at the last available
date in the posts table.
Hint/s:
it’s important to include the days that user 888 did not make a post, to avoid gaps in the time series.
you’ll need to generate a series of dates that cover the date range of interest. there are a couple ways of doing this - look it up!
what kind of function pattern lets us take a cumulative sum in SQL?

Expected column names: post_date, posts_made
*/
--q3 solution
WITH date_series AS (SELECT generate_series((SELECT MIN(post_date) FROM posts WHERE user_id = 888),
                     															(SELECT MAX(post_date) FROM posts),
                                           				interval '1 day'):: DATE AS post_date),
       user_posts AS( SELECT date_series.post_date, COUNT(posts.post_id) AS posts_made
                      FROM date_series
                      LEFT JOIN posts ON date_series.post_date = posts.post_date AND posts.user_id = 888
                      GROUP BY date_series.post_date
                      ORDER BY date_series.post_date),
	cumulative_series AS(SELECT post_date,
                       SUM(posts_made) OVER (ORDER BY post_date) AS posts_made
                       FROM user_posts)
SELECT post_date,posts_made
FROM cumulative_series;

/*
Question #4: 
The Vibestream feed algorithm updates with user preferences every day. Every update is independent
of the previous update. Sometimes the update fails because Vibestreams systems are unreliable. 
Write a query to return the update state for each continuous interval of days in the period from 
2023-01-01 to 2023-12-30.

the algo_update is 'failed' if tasks in a date interval failed and 'succeeded' if tasks in a date 
interval succeeded. every interval has a  start_dateand an end_date.
Return the result in ascending order by start_date.
Expected column names: algo_update, start_date, end_date
*/
--q4 solution
WITH combine AS(SELECT 'failed' AS status,fail_date AS start_date
                FROM algo_update_failure
                WHERE fail_date BETWEEN '2023-01-01' AND '2023-12-30'
                UNION ALL
                SELECT 'succeeded' AS status,success_date AS start_date
                FROM algo_update_success
                WHERE success_date BETWEEN '2023-01-01' AND '2023-12-30')
SELECT status,
	MIN(start_date) AS start_date,
    MAX(start_date) AS end_date
FROM (SELECT *,
    ROW_NUMBER()OVER(ORDER BY start_date) - ROW_NUMBER() OVER(PARTITION BY status ORDER BY start_date) AS grp
	FROM combine) AS Combine_fin
GROUP BY status,grp
ORDER BY start_date;

---Queries by Deepthi Binu 
               	

      
                
                









                         









                                                                           









