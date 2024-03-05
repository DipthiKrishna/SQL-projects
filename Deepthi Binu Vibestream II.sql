/*
Question #1: 
Vibestream is designed for users to share brief updates about how they are feeling,
as such the platform enforces a character limit of 25. How many posts are exactly 25 
characters long?
Expected column names: char_limit_posts
*/
--q1 solution

SELECT COUNT(CHAR_LENGTH(content)) As char_limit_posts
FROM posts
WHERE CHAR_LENGTH(content) = 25;

/*Question #2: 
Users JamesTiger8285 and RobertMermaid7605 are Vibestream’s most active posters.

Find the difference in the number of posts these two users made on each day that at least
one of them made a post. Return dates where the absolute value of the difference between 
posts made is greater than 2 (i.e dates where JamesTiger8285 made at least 3 more posts than
RobertMermaid7605 or vice versa).
HINT: There are some dates where only one of these users makes a post, 
			how do we make sure these dates are not lost?

Expected column names: post_date*/
--q2 solution

WITH James_posts AS(SELECT posts.post_date, COUNT(*)
                    FROM posts
                    LEFT JOIN users ON posts.user_id = users.user_id
                    GROUP BY posts.post_date, users.user_name
                    HAVING users.user_name = 'JamesTiger8285'
                    ORDER BY posts.post_date),
      Robert_posts AS (SELECT posts.post_date, COUNT(*)
                    FROM posts
                    LEFT JOIN users ON posts.user_id = users.user_id
                    GROUP BY posts.post_date, users.user_name
                    HAVING users.user_name = 'RobertMermaid7605'
                    ORDER BY posts.post_date)
SELECT COALESCE(j.post_date,r.post_date) AS post_date
FROM James_posts j
FULL OUTER JOIN Robert_posts r USING(post_date)
WHERE ABS(COALESCE(j.count,0) - COALESCE(r.count,0)) > 2;

/*
Question #3: 
Most users have relatively low engagement and few connections. User WilliamEagle6815, for example,
has only 2 followers. 
Network Analysts would say this user has two 1-step path relationships. Having 2 followers doesn’t 
mean WilliamEagle6815 is isolated, however. Through his followers, he is indirectly connected to the 
larger Vibestream network.  
Consider all users up to 3 steps away from this user:

1-step path (X → WilliamEagle6815)
2-step path (Y → X → WilliamEagle6815)
3-step path (Z → Y → X → WilliamEagle6815)

Write a query to find follower_id of all users within 4 steps of WilliamEagle6815. Order by 
follower_id and return the top 10 records.

Expected column names: follower_id
*/
--q3 solution
--RECURSIVE CTE starts by selecting the followers who directly follow WilliamEagle6815
WITH RECURSIVE follower1 AS(SELECT 0 AS step1,follower_id
                            FROM follows
                            LEFT JOIN users ON follows.follower_id = users.user_id
                            WHERE followee_id  = (SELECT user_id FROM users WHERE user_name ='WilliamEagle6815')
  							UNION ALL
-- it recursively selects followers of followers, increasing the step count by 1 each time until it 
-- reaches 3 steps away from WilliamEagle6815.
                            SELECT f1.step1+1,f.follower_id
                            FROM follower1 f1
                            LEFT JOIN follows f
                            ON f1.follower_id = f.followee_id
                            WHERE step1 < 3)
      
   
SELECT DISTINCT f1.follower_id
                    FROM follower1 f1
--ensures that WilliamEagle6815's own user ID is not included in the result.
                    WHERE f1.follower_id != (SELECT user_id FROM users WHERE user_name ='WilliamEagle6815')
      				ORDER BY 1
                    LIMIT 10;
                    
/*
Question #4: 
Return top posters for 2023-11-30 and 2023-12-01. A top poster is a user who has the most OR 
second most number of posts in a given day. Include the number of posts in the result and order
the result by post_date and user_id.
Expected column names: post_date, user_id, posts
*/
--q4 solution
WITH postbyrank AS(SELECT post_date,
                   user_id,
                   COUNT(*) AS posts,
                   RANK() OVER(partition by post_date ORDER BY COUNT(*) DESC)AS post_rank
                   FROM posts
                   WHERE post_date BETWEEN '2023-11-30' AND '2023-12-01'
                   GROUP BY post_date,user_id
                   ORDER BY post_date,COUNT(*)DESC,user_id)

SELECT post_date,user_id,posts
FROM postbyrank
WHERE post_rank <=2
ORDER BY post_date,user_id;








  									


















