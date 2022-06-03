-- I used MySQL to run these queries. Sheets from the pre-cleaned Excel file
--  "Ramen Full List 2022.06.03" were imported through MySQL Workbench as the following:

    -- ramenreviewed: "Reviewed" sheet
    -- ramenranking: "Ranking" sheet
    -- ramencountry: "Country Info" sheet
    -- ramenconsumption: "Instant Noodle Consumption" sheet
    -- ramenurl: "URL" sheet

-- Alternatively, you can create the tables and upload the data in csv format without using the workbench.
-- To do this, run the following code, replacing "filename.csv" with the appropriate file name and path:

-- CREATE TABLE `ramenreviewed` (
--   `Review_ID` smallint NOT NULL AUTO_INCREMENT,
--   `Review_Date` date DEFAULT NULL,
--   `Brand` varchar(50) DEFAULT NULL,
--   `Variety` varchar(100) DEFAULT NULL,
--   `Style` varchar(20) DEFAULT NULL,
--   `Country_ID` tinyint DEFAULT NULL,
--   `Stars` float DEFAULT NULL,
--   PRIMARY KEY (`Review_ID`)
-- ) ENGINE=InnoDB AUTO_INCREMENT=4122 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
-- LOAD DATA INFILE 'filename.csv' 
-- INTO TABLE ramenreviewed 
-- FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;

-- CREATE TABLE `ramenranking` (
--   `Review_ID` int DEFAULT NULL,
--   `Rank_Year` int DEFAULT NULL,
--   `Rank_Category` text,
--   `Rank` int DEFAULT NULL
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
-- LOAD DATA INFILE 'filename.csv' 
-- INTO TABLE ramenranking 
-- FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;

-- CREATE TABLE `ramencountry` (
--   `Country_ID` int NOT NULL,
--   `Country` text,
--   `Subregion` text,
--   `Region` text,
--   `2016_Population` bigint DEFAULT NULL,
--   `2017_Population` bigint DEFAULT NULL,
--   `2018_Population` bigint DEFAULT NULL,
--   `2019_Population` bigint DEFAULT NULL,
--   `2020_Population` bigint DEFAULT NULL,
--   `Avg_Population` bigint DEFAULT NULL,
--   PRIMARY KEY (`Country_ID`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
-- LOAD DATA INFILE 'filename.csv' 
-- INTO TABLE ramencountry 
-- FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;

-- CREATE TABLE `ramenconsumption` (
--   `Country` varchar(20) NOT NULL,
--   `2016_Consumption` bigint DEFAULT NULL,
--   `2017_Consumption` bigint DEFAULT NULL,
--   `2018_Consumption` bigint DEFAULT NULL,
--   `2019_Consumption` bigint DEFAULT NULL,
--   `2020_Consumption` bigint DEFAULT NULL,
--   `Avg_Consumption` bigint DEFAULT NULL,
--   PRIMARY KEY (`Country`)
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
-- LOAD DATA INFILE 'filename.csv' 
-- INTO TABLE ramenconsumption
-- FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;

-- CREATE TABLE `ramenurl` (
--   `Review_ID` smallint NOT NULL AUTO_INCREMENT,
--   `URL` varchar(250) DEFAULT NULL,
--   PRIMARY KEY (`Review_ID`)
-- ) ENGINE=InnoDB AUTO_INCREMENT=4122 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
-- LOAD DATA INFILE 'filename.csv' 
-- INTO TABLE ramenurl 
-- FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;



-- With that out of the way, let's get to analyzing! 
-- First thing's first, let's calculate instant noodle consumption per capita per region using the noodle
-- consumption and population data from the ramenconsumption and ramencountry tables. Let's include the 
-- region population as well for some added context.

SELECT Region, FORMAT(SUM(Avg_Population),0) AS Region_Population,
ROUND(AVG(Avg_Consumption / Avg_Population),2) AS Yearly_Consumption_Per_Capita
FROM ramenconsumption con, ramencountry ctr
WHERE con.Country = ctr.Country
GROUP BY Region
ORDER BY Yearly_Consumption_Per_Capita DESC;

-- Yep, Asia is first, no surprises there. They sure do like their noodles (and boy is there
-- a lot of people in Asia!). Let's get a little more granular and see per subregion instead of region. 

SELECT Subregion, FORMAT(SUM(Avg_Population),0) AS Subregional_Population,
ROUND(AVG(Avg_Consumption / Avg_Population),2) AS Yearly_Consumption_Per_Capita
FROM ramenconsumption con, ramencountry ctr
WHERE con.Country = ctr.Country
GROUP BY Subregion
ORDER BY Yearly_Consumption_Per_Capita DESC;

-- A little bit of a closer fight within the Asian subregions, with East Asia and Southeast Asia carrying
-- most of the weight. It makes sense; South Asian countries like India and Pakistan don't come across as
-- particularly hot markets for instant noodles, for example, and the data seems to support that. Okay, let's
-- get even more granular and look at countries next. Since there will be tons more rows this time, let's
-- add row numbers to make the results easier to interpret.

SELECT ROW_NUMBER() OVER(
	ORDER BY ROUND(Avg_Consumption / Avg_Population, 2) DESC
) AS Consumption_Ranking, con.Country, FORMAT(Avg_Population,0) AS Population,
ROUND(Avg_Consumption / Avg_Population, 2) AS Yearly_Consumption_Per_Capita
FROM ramenconsumption con, ramencountry ctr
WHERE con.Country = ctr.Country;

-- There we have it, South Korea reigns supreme. Interestingly, the first country out of Asia to rank is
-- Guatemala, coming in at 17th. 

-- Let's change gears a bit and look at the star ratings from The Ramen Rater's data now.
-- What does the distribution look like? Let's see the percent total of each star rating.

SELECT Stars, COUNT(Stars) AS Total_Count, 
ROUND(100*COUNT(Stars)/(
	SELECT COUNT(*) 
    FROM ramenreviewed),2) AS Percent_of_Total
FROM ramenreviewed
GROUP BY Stars
ORDER BY Stars;

-- There are so many different star ratings that it's kind of difficult to make sense of this...
-- Let's try that again, but this time binning the star values and adding a rolling count on the percentage
-- as well. For the rolling count we need to use a CTE, referencing a temporary table (that bins values 
-- through unions) to get the percentage sum with "OVER (ORDER BY...)".

WITH starinfo AS(
SELECT "0 - 0.99" AS Star_Range, COUNT(Stars) AS Total_Count, ROUND(100*COUNT(Stars)/
(
	SELECT COUNT(*) 
    FROM ramenreviewed)
,2) AS Percent_of_Total FROM ramenreviewed
WHERE Stars BETWEEN 0 AND 0.99
UNION (
	SELECT "1.5 - 1.99" AS Star_Range, COUNT(Stars) AS Total_Count, ROUND(100*COUNT(Stars)/
    (
		SELECT COUNT(*) 
		FROM ramenreviewed)
	,2) AS Percent__of_Total FROM ramenreviewed
	WHERE Stars BETWEEN 1.0 AND 1.99
)
UNION (
	SELECT "2.0 - 2.99" AS Star_Range, COUNT(Stars) AS Total_Count, ROUND(100*COUNT(Stars)/
    (
		SELECT COUNT(*) 
		FROM ramenreviewed)
	,2) AS Percent_of_Total FROM ramenreviewed
	WHERE Stars BETWEEN 2.0 AND 2.99
)
UNION (
	SELECT "3.0 - 3.99" AS Star_Range, COUNT(Stars) AS Total_Count, ROUND(100*COUNT(Stars)/
    (
		SELECT COUNT(*) 
		FROM ramenreviewed)
	,2) AS Percent_of_Total FROM ramenreviewed
	WHERE Stars BETWEEN 3.0 AND 3.99
)
UNION (
	SELECT "4.0 - 4.99" AS Star_Range, COUNT(Stars) AS Total_Count, ROUND(100*COUNT(Stars)/
    (
		SELECT COUNT(*) 
		FROM ramenreviewed)
	,2) AS Percent_of_Total FROM ramenreviewed
	WHERE Stars BETWEEN 4.0 AND 4.99
)
UNION (
	SELECT "5" AS Star_Range, COUNT(Stars) AS Total_Count, ROUND(
    100*COUNT(Stars)/
    (
		SELECT COUNT(*) 
		FROM ramenreviewed)
	,2) AS Percent_of_Total FROM ramenreviewed
	WHERE Stars = 5.00
))
SELECT *, SUM(Percent_of_Total) OVER (ORDER BY Star_Range DESC) AS Rolling_Percent
FROM starinfo
ORDER BY Star_Range DESC;

-- That's better. Well, looks like most of the reviews are within the 3~3.99 star range. But more surprising is
-- that less than 15% of the reviews score less than 3 stars. Either Hans is a fairly lenient grader (hey, you
-- have to really like ramen to review so many) or the vast majority of noodles he's reviewed just happens to be
-- at least "alright". How has Hans' ratings changed over the years? Has it been consistent or were some years 
-- better "noodle years" than others? Along with the average rating, this time let's also track the difference
-- year over year on the review count.

SELECT YEAR(Review_Date) AS Review_Year,
COUNT(Review_ID) AS Review_Count,
COUNT(Review_ID) - (LAG(COUNT(Review_ID),1) OVER (
    ORDER BY YEAR(Review_Date)
)) AS Count_Diff_YOY,
ROUND(AVG(Stars),2) AS Avg_Stars
FROM RamenReviewed 
GROUP BY YEAR(Review_Date)
ORDER BY YEAR(Review_Date);

-- There seems to be a slow but steady increase in the average star rating until its peak in 2020 with an average
-- score of 3.93 (almost 4 stars average with a sample size of 327 reviews!), and then a bit of a decline in the
-- past year and a bit. The review count difference is a little hard to read though. Let's change that to percent
-- difference year over year instead.

WITH StarsPerYear AS(
SELECT YEAR(Review_Date) AS Review_Year,
COUNT(Review_ID) AS Review_Count,
COUNT(Review_ID) - (LAG(COUNT(Review_ID),1) OVER (
    ORDER BY YEAR(Review_Date)
)) AS Count_Diff_YOY,
ROUND(AVG(Stars),2) AS Avg_Stars
FROM RamenReviewed 
GROUP BY YEAR(Review_Date)
)
SELECT Review_Year, Review_Count, 
ROUND(Count_Diff_YOY/(LAG(Review_Count,1) OVER(
ORDER BY Review_Year)) * 100,2) AS Percent_Diff_YOY, 
Avg_Stars
FROM StarsPerYear;

-- It seems the site really took off in 2010, when Hans added more than double as many new reviews as he had
-- until then. Disregarding the large drop in 2022 (as the year isn't over yet), the biggest dip in review
-- count occurred in 2019, with 17.19% less new reviews than the previous year. According to Hans' "About Me"
-- page from the Ramen Rater webiste, in late 2018 he was told by his doctor to improve his diet. After a couple
-- of radical lifestyle changes, he has been slowly increasing the number of reviews again while maintaining a
-- healthier way of living. Out of curiosity, let's further divide this data into months and see what that looks like.

WITH StarsPerDate AS(
SELECT DATE_FORMAT(Review_Date, '%Y/%m') AS Review_Date,
COUNT(Review_ID) AS Review_Count,
COUNT(Review_ID) - (LAG(COUNT(Review_ID),1) OVER (
    ORDER BY DATE_FORMAT(Review_Date, '%Y/%m')
)) AS Count_Diff_YOY,
ROUND(AVG(Stars),2) AS Avg_Stars
FROM RamenReviewed 
GROUP BY DATE_FORMAT(Review_Date, '%Y/%m')
)
SELECT Review_Date, Review_Count, 
ROUND(Count_Diff_YOY/(LAG(Review_Count,1) OVER(
ORDER BY Review_Date)) * 100,2) AS Percent_Diff_YOY, 
Avg_Stars
FROM StarsPerDate;

-- That's... a lot to take in. Still, I think there may be something of value here. Let's keep this in mind and
-- graph later. For now, let's move on and look at the relationship between country and average noodle star rating
-- next. Let's include the review count as well for context.

SELECT Region, ROUND(AVG(Stars),2) AS Avg_Rating, COUNT(*) AS Review_Count
FROM RamenReviewed rr
JOIN ramencountry rc ON 
rr.Country_ID = rc.Country_ID
GROUP BY Region;

-- Again, Asia is first. Again, no surprise. Let's now look at countries instead of regions. Since there are
-- quite a few countries with single digit reviews, let's filter the results to countries with at least 10
-- reviews. And just like we did when we looked at consumption per capita, let's add row numbers to make it
-- easier to interpret.

SELECT ROW_NUMBER() OVER(
    ORDER BY ROUND(AVG(Stars),2) DESC
) AS `Rank`, Country, ROUND(AVG(Stars),2) AS Avg_Rating, COUNT(*) AS Review_Count
FROM RamenReviewed rr
JOIN ramencountry rc ON 
rr.Country_ID = rc.Country_ID
GROUP BY Country
HAVING COUNT(*) >= 10;

-- Malaysia seems to produce the best noodles! This isn't all that surprising to me personally, as I've taken
-- a look at some of Hans' Top 10 Lists and Malaysian noodles are frequently featured. We'll see this in more
-- detail later when we work with the Top 10 table. Moving on, does there seem to be any obvious correlation
-- between ramen consumption per capita per country and noodle quality? Are top noodle consumers also top noodle
-- producers?

WITH countrystar AS(
	SELECT ctr.Country, ROUND(AVG(rev.Stars),2) AS Avg_Stars
	FROM ramencountry ctr
    JOIN RamenReviewed rev ON ctr.Country_ID = rev.Country_ID
	GROUP BY ctr.Country
    HAVING COUNT(*) >= 10
)
SELECT ROW_NUMBER() OVER(
    ORDER BY ROUND(con.Avg_Consumption / ctr.Avg_Population, 2) DESC
) AS `Rank`, countrystar.Country,
ROUND(con.Avg_Consumption / ctr.Avg_Population, 2) AS Yearly_Consumption_Per_Capita,
countrystar.Avg_Stars
FROM countrystar, ramenconsumption con, ramencountry ctr
WHERE con.Country = ctr.Country AND countrystar.Country = ctr.Country;

-- Hmm, no obvious correlation (the average star rating seems to jump all over the place), but we can try
-- graphing this later. Maybe we'll notice something after making it into a visualizaion. What about best
-- brands then? Let's order brands by average noodle star rating. Since there are so many brands, let's
-- limit to only those with at least 15 reviews. 

SELECT ROW_NUMBER() OVER(
    ORDER BY ROUND(AVG(Stars),2) DESC
) AS `Rank`, Brand, ROUND(AVG(Stars),2) AS Avg_Rating, COUNT(*) AS Review_Count
FROM RamenReviewed rr
GROUP BY Brand
HAVING Review_Count >= 15;

-- MyKuali is top. For someone that's looked at the Top 10 Lists before, this is as expected. It's a Malaysian
-- company by the way. Speaking of which, this time let's group by both brand and country. This will be interesting
-- as many large manufacturers have local subsidiaries, so we will get to see how they stack against each other.
-- Any difference?

SELECT ROW_NUMBER() OVER(
    ORDER BY ROUND(AVG(Stars),2) DESC
) AS `Rank`, Brand, Country, ROUND(AVG(Stars),2) AS Avg_Rating, COUNT(*) AS Review_Count
FROM RamenReviewed rr
JOIN ramencountry ctr ON rr.Country_ID = ctr.Country_ID
GROUP BY Brand, Country
HAVING Review_Count >= 15;

-- Surprisingly, the American branch of Myojo has been doing pretty well for itself, coming in at number 3! Seems
-- like the Singaporean and Japanese branches were dragging it down in the brand-only rankings, which is definitely
-- unexpected. You'd think it'd be the Asian subsidiaries that would be doing the heavy-lifting. Now I'm curious;
-- what does the brand rank look like among American-made noodles only?

SELECT ROW_NUMBER() OVER(
    ORDER BY ROUND(AVG(Stars),2) DESC
) AS `Rank`, Brand, ROUND(AVG(Stars),2) AS Avg_Rating, COUNT(*) AS Review_Count
FROM RamenReviewed rr
JOIN ramencountry ctr ON rr.Country_ID = ctr.Country_ID
WHERE ctr.Country = 'United States'
GROUP BY Brand
HAVING Review_Count >= 15;

-- After seeing the American Myojo branch come 3rd in overall best reviewed brand, I am not shocked to see them as
-- the top American brand as well. Still, looking at the review count discrepancy, they had much fewer reviews
-- than most other American noodles (like Vite Ramen in second). That is to say, the small sample size may be
-- swinging the result in their favor. Something to keep in mind. This is one unfortunate limitation of a small sample...

-- Let's move on to the ramenranking table now to see which countries have the most distinct noodles in Top 10 
-- lists over the years. Note that not all list types will be included in this query. For one, some are country-specific
-- (Top South Korea, Top Thai, etc.), and including those would obviously skew the results. Moreover, a few focus on a
-- particular, not necessarily positive aspect of the noodles, like the Top Spicy or Top Anomaly lists. For this query I
-- will only focus on the "overall best", all-inclusive lists: the Top Pack, Top Boxed, Top Cup, Top Tray, and Top Of All Time
-- lists, and the Reader's Choice Top 10.

SELECT ROW_NUMBER() OVER(
    ORDER BY COUNT(DISTINCT ran.Review_ID) DESC
) AS `Rank`, Country, COUNT(DISTINCT ran.Review_ID) AS Top_10_Appearances FROM ramenranking ran
JOIN RamenReviewed rev ON rev.Review_ID = ran.Review_ID
JOIN ramencountry ctr ON rev.Country_ID = ctr.Country_ID
WHERE Rank_Category IN ('Top Pack', 'Top Boxed', 'Top Bowl', 'Top Cup', 'Top Of All Time', 'Reader\'s Choice')
GROUP BY Country;

-- The majority are from Asia, again... I'm curious about those three European outliers though. Let's check them out.

SELECT Country, Brand, Variety, Rank_Category, `Rank`, Rank_Year, URL
FROM RamenReviewed rev
JOIN ramenranking ran ON rev.Review_ID = ran.Review_ID
JOIN RamenURL url ON rev.Review_ID = url.Review_ID
JOIN ramencountry ctr ON rev.Country_ID = ctr.Country_ID
WHERE Region = "Europe" AND rev.Review_ID IN (
	SELECT DISTINCT Review_ID FROM ramenranking
	WHERE Rank_Category IN ('Top Pack', 'Top Boxed', 'Top Bowl', 'Top Cup', 'Reader\'s Choice')
);
    
-- Weird that they all featured in the Top Cup rank category. Maybe there's less competition in that sector?
-- Anyway, we saw which countries produced the most quality noodles, but what about the most "noteworthy" noodles?
-- This is it, all Top 10 lists are fair game (except country-specific ones). Will the results look any different?

SELECT ROW_NUMBER() OVER(
    ORDER BY COUNT(DISTINCT ran.Review_ID) DESC
) AS `Rank`, Country, COUNT(DISTINCT ran.Review_ID) AS Top_10_Appearances FROM ramenranking ran
JOIN RamenReviewed rev ON rev.Review_ID = ran.Review_ID
JOIN ramencountry ctr ON rev.Country_ID = ctr.Country_ID
WHERE Rank_Category NOT LIKE CONCAT('%', ctr.Country ,'%')
AND Rank_Category NOT LIKE '%USA' AND Rank_Category NOT LIKE '%Thai%'
GROUP BY Country;

-- Right, we got the all-inclusive "Top All" list, but it's kind of hard to compare to the "Top Best" list from the 
-- previous query without looking at them side by side... Let's combine both queries using CTEs. While we're at it,
-- let's see their difference as well, to have an idea of which country benefits most from including non-"Top Best" results.

WITH TopBest AS(
	SELECT Country, COUNT(DISTINCT ran.Review_ID) AS Top_10_Best FROM ramenranking ran
	JOIN RamenReviewed rev ON rev.Review_ID = ran.Review_ID
	JOIN ramencountry ctr ON rev.Country_ID = ctr.Country_ID
	WHERE Rank_Category IN ('Top Pack', 'Top Boxed', 'Top Bowl', 'Top Cup', 'Top Of All Time', 'Reader\'s Choice')
	GROUP BY Country
),
TopAll AS (
	SELECT Country, COUNT(DISTINCT ran.Review_ID) AS Top_10_All FROM ramenranking ran
	JOIN RamenReviewed rev ON rev.Review_ID = ran.Review_ID
	JOIN ramencountry ctr ON rev.Country_ID = ctr.Country_ID
	WHERE Rank_Category NOT LIKE CONCAT('%', ctr.Country ,'%')
	AND Rank_Category NOT LIKE '%USA' AND Rank_Category NOT LIKE '%Thai%'
	GROUP BY Country
)
SELECT ROW_NUMBER() OVER(
    ORDER BY Top_10_All DESC
) AS `Rank`,TopAll.Country, Top_10_All, Top_10_Best, (Top_10_All - Top_10_Best) AS Difference 
FROM TopAll
LEFT JOIN TopBest ON TopAll.Country = TopBest.Country;

-- Looks like Japan produced the most remarkable noodles, and the United States the most outside of the Top
-- Best! But there's a lot more American and Japanese noodle reviews in the database than some other countries',
-- so the results may be deceiving. Let's look at the proportion between the "Top 10 All" count and the total
-- number of all reviews per country to get a better look at the data.

WITH TopAll AS (
	SELECT Country, COUNT(DISTINCT ran.Review_ID) AS Top_10_All FROM ramenranking ran
	JOIN RamenReviewed rev ON rev.Review_ID = ran.Review_ID
	JOIN ramencountry ctr ON rev.Country_ID = ctr.Country_ID
	WHERE Rank_Category NOT LIKE CONCAT('%', ctr.Country ,'%')
	AND Rank_Category NOT LIKE '%USA' AND Rank_Category NOT LIKE '%Thai%'
	GROUP BY Country
),
AllReviews AS (
	SELECT Country, COUNT(Review_ID) AS All_Reviews FROM RamenReviewed rev
    JOIN ramencountry ctr ON rev.Country_ID = ctr.Country_ID
    GROUP BY Country
)
SELECT ROW_NUMBER() OVER(
    ORDER BY ROUND((Top_10_All/All_Reviews)*100,2) DESC
) AS `Rank`, TopAll.Country, All_Reviews, Top_10_All, ROUND((Top_10_All/All_Reviews)*100,2) AS Percent_Noteworthy
FROM TopAll, AllReviews
WHERE TopAll.Country = AllReviews.Country;

-- Well well, not so remarkable after all, eh Japan and USA? Sure, some countries with very few reviews skew the
-- results a bit, but look at Malaysia: even with a sizeable 231 (count as of June 3rd, 2022) noodles in the database, 
-- almost 1 in 5 made it on a Top 10 list. Impressive! In fact, if we look at only noodles that rank number 1
-- across all lists (barring the country-specific ones)... 

SELECT ROW_NUMBER() OVER(
    ORDER BY COUNT(DISTINCT ran.Review_ID) DESC
) AS `Rank`, Country, COUNT(DISTINCT ran.Review_ID) AS Rank_Leader_Appearances FROM ramenranking ran
JOIN RamenReviewed rev ON rev.Review_ID = ran.Review_ID
JOIN ramencountry ctr ON rev.Country_ID = ctr.Country_ID
WHERE Rank_Category NOT LIKE CONCAT('%', ctr.Country ,'%')
AND Rank_Category NOT LIKE '%USA' AND Rank_Category NOT LIKE '%Thai%'
AND `Rank` = 1
GROUP BY Country;

-- ...Malaysia is king. By the way, in case you're curious about that sole New Zealand noodle that also happens
-- to be ranked, run the query below. (Without JOIN statements this time, just to mix it up).

SELECT Brand, Variety, Rank_Category, Rank_Year, `Rank`, URL
FROM RamenReviewed rev, ramenranking ran, ramencountry ctr, RamenURL url
WHERE rev.Review_ID = ran.Review_ID
AND rev.Country_ID = ctr.Country_ID
AND rev.Review_ID = url.Review_ID
AND Country = 'New Zealand';

-- That is none other than Culley's World's Hottest Ramen Noodles, topping the Top Spicy Category for
-- three years running!

-- This has been data analysis with SQL. I hope you found the data as interesting as I did!