---How many posts created per Year?
select YEAR(CreationDate),count(*) as Number_of_posts_per_year from Posts
group by Year(CreationDate)
---------------------------------------------------------------------------------------
select YEAR(CreationDate) as Year,Month(CreationDate) as Month,count(*) as Number_of_posts_per_year from Posts
group by Year(CreationDate),Month(CreationDate)
------------------------------------------------------------------------------------
---How many votes were made in each day of the week (Sunday, Monday, Tuesday, etc.) ?
/*
SELECT DATENAME(dw,GETDATE()) -- Friday
SELECT DATEPART(dw,GETDATE()) -- 6

*/

select DATENAME(dw,CreationDate) as Day_of_week ,
       count(*) as Number_of_votes
from Votes
group by DATENAME(dw,CreationDate)
------------------------------------------------------------------------------
----List all comments created on September 19th, 2012
----SELECT CONVERT(date, getdate()) -- get the data only from dateTime in sql
select * from Comments
where cast(CreationDate as Date)='2012-9-19'
--select cast(CreationDate as Date) from Comments
--select format(CreationDate,'dd-MM-yyyy') from Comments

select Text,PostId from Comments
where cast(CreationDate as DATE)='2012-9-19'

SELECT * 
FROM comments 
WHERE DATEDIFF(DAY, CreationDate, '2012-9-19') = 0

----------------------------------------------------------------------------------
--List all users under the age of 33, living in London

select * from Users
where Age < 33 and Age is not null and Location like '%London%'
----------------------------------------------------------------------------------
----Display the number of votes for each post title
select count(*) as Number_of_votes,posts.Id,Posts.Title
from Votes inner join posts
on Votes.PostId = posts.Id
group by posts.Id,posts.Title
order by count(*) DESC
-----------------------------------------------------------------------------
--Display posts with comments created by users living in the same location as the post creator
SELECT pst.Id AS 'post_id',
       pst.Title AS 'post_title',
       pst.OwnerUserID AS 'created_by_user',
       usr_p.Id AS 'user_id', 
       usr_p.DisplayName AS 'creator_user_name',
       usr_p.location AS 'creator_location',
       cmt.UserId AS 'commentor_id', 
       usr_c.DisplayName AS 'commentor_user_name',
       usr_c.location AS 'commentor_location'
FROM posts pst JOIN users usr_p 
ON   pst.OwnerUserID = usr_p.Id
               JOIN comments cmt
ON   cmt.postId = pst.Id
               JOIN users usr_c
ON   cmt.UserID = usr_c.Id
WHERE usr_c.location = usr_p.location
-----------------------------------------------------------------------
--How many users have never voted ?
with "Vote_Cte" as (
SELECT id FROM users
    EXCEPT
    SELECT userID FROM votes )


select count(*) from Vote_Cte	
---------------------------------------------------------------------------------
-- Display all posts having the highest amount of comments 
 SELECT  pst.Title, 
            COUNT(*) AS 'number_of_comments' , 
            DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS 'comment_count_ranking'
    FROM posts pst JOIN comments cmt
    ON   pst.id = cmt.postid
    GROUP BY pst.Title

----------------------------------------------------------------
WITH "TOP-COMMENT-POSTS"
AS
    (
    SELECT  pst.Title, 
            COUNT(*) AS 'number_of_comments' , 
            DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS 'comment_count_ranking'
    FROM posts pst JOIN comments cmt
    ON   pst.id = cmt.postid
    GROUP BY pst.Title
    )
SELECT Title 
FROM "TOP-COMMENT-POSTS"
WHERE comment_count_ranking = 1  
------------------------------------------------------------------------------------
--For each post, how many votes are coming from users living in Canada ? 
--What’s their percentage of the total number of votes

SELECT  pst.Title, 
        COUNT(*) number_of_votes, 
        SUM(CASE WHEN usr.location LIKE '%canada%' THEN 1 ELSE 0 END) AS 'votes_from_canada',
        CAST(SUM(CASE WHEN usr.location LIKE '%canada%' THEN 1 ELSE 0 END) AS FLOAT) /
		--CAST(EXPER AS DATATYPE)
        CAST(COUNT(*) AS FLOAT) AS 'votes_percentage'
FROM posts pst JOIN votes vt 
ON   pst.Id = vt.postID
               JOIN users usr
ON   vt.UserID = usr.id
GROUP BY pst.Title
ORDER BY COUNT(*) DESC 

---------------------------------------------------------------------------
-- 6. How many hours in average, it takes to the first comment to be posted after a creation of a new post
;WITH "COMMENTS-TIMING-CTE"
AS 
    (
    SELECT  pst.id AS 'post_id',
            pst.Title AS 'post_title',
            pst.creationDate AS 'post_creation_date',
            cmt.creationDate AS 'comment_creation_date',
            DENSE_RANK() OVER (PARTITION BY pst.id ORDER BY cmt.creationDate) AS 'comment_rank'
    FROM posts pst JOIN comments cmt 
    ON   pst.Id = cmt.postID
    )
SELECT AVG(DATEDIFF(HOUR, post_creation_date, comment_creation_date)) AS 'avg_num_of_hours'
FROM "COMMENTS-TIMING-CTE"
WHERE comment_rank = 1

-------------------------------------------------------------------------
--Whats the most common post tag ?
;WITH "CTE-TAGS-SEP" (Tags) AS
(
    SELECT CAST(Tags AS VARCHAR(MAX)) 
    FROM Posts
    UNION ALL
    SELECT STUFF(Tags, 1, CHARINDEX('><' , Tags), '') 
    FROM "CTE-TAGS-SEP"
    WHERE Tags  LIKE '%><%'
), "CTE-TAGS-COUNTER" AS 
(   
    SELECT CASE WHEN Tags LIKE '%><%' THEN LEFT(Tags, CHARINDEX('><' , Tags)) 
                ELSE Tags 
            END AS 'Tags'
    FROM "CTE-TAGS-SEP"
)
SELECT TOP 1 COUNT(*), Tags
FROM "CTE-TAGS-COUNTER"
GROUP BY Tags 
ORDER BY COUNT(*) DESC 
---------------------------------------------------------------------------------
---- 8. Create a pivot table displaying how many posts were 
-----created for each year (Y axis) and each month (X axis)

SELECT *   
FROM (  
    SELECT YEAR(CreationDate) AS 'Year', DATENAME(MONTH,CreationDate) AS 'Month', id 
    FROM posts
  ) AS S  
PIVOT   
     (   
    COUNT(id)
	--Month is a column 
    FOR  [Month] IN ([January], [February], [March], [April], [May], [June], [July], [August], [September], [October], [November], [December]) 
   ) AS PVT
ORDER BY [Year]

