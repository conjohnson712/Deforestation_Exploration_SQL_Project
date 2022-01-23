/* 1. Create View called "forestation" that joins all three tables

   2: The forest_area and land_area tables join on both country_code 
      AND year. 

   3: The regions table joins these based on only country_code. 

   4: In the ‘forestation’ View, include the following: All of the 
      columns of the origin tables A new column that provides the percent 
      of the land area that is designated as forest 

   5: Keep in mind that the column forest_area_sqkm in the forest_area 
      table and the land_area_sqmi in the land_area table are in different 
      units (square kilometers and square miles, respectively), so an 
      adjustment will need to be made in the calculation you write 
      (1 sq mi = 2.59 sq km). */ 


CREATE VIEW forestation AS
SELECT  f.country_code AS country_code,
        f.country_name AS country_name, 
        f.year AS year,
        r.region AS region,
        r.income_group AS income_group,
        f.forest_area_sqkm AS forest_area_sqkm,
        l.total_area_sq_mi AS total_area_sq_mi,
        ROUND((SUM(forest_area_sqkm) / (SUM(total_area_sq_mi)*2.59) * 100):: numeric, 2) AS percent_forest
FROM forest_area f
FULL OUTER JOIN land_area l 
ON f.country_code = l.country_code AND f.year = l.year
FULL OUTER JOIN regions r 
ON f.country_code = r.country_code
GROUP BY 1,2,3,4,5,6,7
ORDER BY 3,4,5,6,7,8


                    --Part 1: Global Situation Queries --
/* a: What was the total forest area (in sq km) of the world in 1990?
      Keep in mind that you can use the country record denoted as "World"
      in the regions table */

SELECT  year, 
        SUM(forest_area_sqkm)
FROM forestation
WHERE year = '1990' and country_name = 'World'
GROUP BY 1
ORDER BY 2


/* b: What was the total forest area (in sq km) of the world in 2016? 
      Please keep in mind that you can use the country record in the 
      table is denoted as “World.” */

SELECT  year, 
        SUM(forest_area_sqkm)
FROM forestation
WHERE year = '2016' and country_name = 'World'
GROUP BY 1
ORDER BY 2



/* c: What was the change (in sq km) in the forest area of the world 
      from 1990 to 2016? */ 

WITH total_forest_1990 AS (
    SELECT  year, 
            country_name,
            SUM(forest_area_sqkm) AS total_forest_area
    FROM forestation
    WHERE year = '1990' and country_name = 'World'
    GROUP BY 1,2
    ORDER BY 3
), 
    total_forest_2016 AS ( 
    SELECT  year, 
            country_name,
            SUM(forest_area_sqkm) AS total_forest_area
    FROM forestation
    WHERE year = '2016' and country_name = 'World'
    GROUP BY 1,2
    ORDER BY 3 
    )
SELECT (x.total_forest_area - y.total_forest_area) AS global_change
FROM total_forest_1990 AS x
JOIN total_forest_2016 AS y 
ON x.country_name = y.country_name



/* d: What was the percent change in forest area of the world between 
      1990 and 2016? */

WITH total_forest_1990 AS (
    SELECT  year, 
            country_name,
            SUM(forest_area_sqkm) AS total_forest_area
    FROM forestation
    WHERE year = '1990' and country_name = 'World'
    GROUP BY 1,2
    ORDER BY 3
), 
    total_forest_2016 AS ( 
    SELECT  year, 
            country_name,
            SUM(forest_area_sqkm) AS total_forest_area
    FROM forestation
    WHERE year = '2016' and country_name = 'World'
    GROUP BY 1,2 
    ORDER BY 3 
    )
SELECT ((x.total_forest_area - y.total_forest_area)/x.total_forest_area * 100) AS percent_global_change
FROM total_forest_1990 AS x
JOIN total_forest_2016 AS y 
ON x.country_name = y.country_name



/*  e: If you compare the amount of forest area lost between 1990 and 2016,
    to which country's total area in 2016 is it closest to? */ 

SELECT country_name, 
	   (total_area_sq_mi * 2.59) AS total_area_sqkm
FROM forestation
WHERE year = 2016 AND (total_area_sq_mi * 2.59) < '1324449'
ORDER BY total_area_sqkm DESC
LIMIT 1;




            -- Part 2: REGIONAL OUTLOOK -- 
/* Create a table that shows the Regions and their percent forest area 
   (sum of forest area divided by sum of land area) in 1990 and 2016. 
   (Note that 1 sq mi = 2.59 sq km). */

CREATE TABLE regional_outlook AS 
            SELECT region, 
                   year,
                   ((SUM(forest_area_sqkm) / (SUM(total_area_sq_mi) * 2.59)) * 100) AS percent_forest
FROM forestation
WHERE year = '1990' OR year = '2016'
GROUP BY 1, 2 
ORDER BY 1, 2, 3 



/* a: What was the percent forest of the entire world in 2016? Which 
      region had the HIGHEST percent forest in 2016, and which had the 
      LOWEST, to 2 decimal places? */

-- World-- 
SELECT region, 
       year,
       CAST((percent_forest) AS DECIMAL (5,2))
FROM forestation
WHERE year = '2016' AND region = 'World'
GROUP BY 1, 2, 3
ORDER BY 3

-- HIGHEST -- 
SELECT region, 
       year,
       CAST((percent_forest) AS DECIMAL (5,2))
FROM regional_outlook
WHERE year = '2016' AND percent_forest IS NOT NULL 
GROUP BY 1, 2, 3
ORDER BY 3 DESC
LIMIT 1 

--LOWEST
SELECT region, 
       year,
       CAST((percent_forest) AS DECIMAL (5,2))
FROM regional_outlook
WHERE year = '2016' AND percent_forest IS NOT NULL 
GROUP BY 1, 2, 3
ORDER BY 3 
LIMIT 1

/* b: What was the percent forest of the entire world in 1990? Which 
      region had the HIGHEST percent forest in 1990, and which had the 
      LOWEST, to 2 decimal places? */

-- World-- 
SELECT region, 
       year,
       CAST((percent_forest) AS DECIMAL (5,2))
FROM regional_outlook
WHERE year = '1990' AND region = 'World'
GROUP BY 1, 2, 3
ORDER BY 3

-- HIGHEST -- 
SELECT region, 
       year,
       CAST((percent_forest) AS DECIMAL (5,2))
FROM regional_outlook
WHERE year = '1990' AND percent_forest IS NOT NULL 
GROUP BY 1, 2, 3
ORDER BY 3 DESC
LIMIT 1 

--LOWEST
SELECT region, 
       year,
       CAST((percent_forest) AS DECIMAL (5,2))
FROM regional_outlook
WHERE year = '1990' AND percent_forest IS NOT NULL 
GROUP BY 1, 2, 3
ORDER BY 3 
LIMIT 1



/* c:  Based on the table you created, which regions of the world 
       DECREASED in forest area from 1990 to 2016? */ 

WITH total_forest_1990 AS (
    SELECT  region, 
            CAST((percent_forest) AS DECIMAL (5,2))
    FROM regional_outlook
    WHERE year = '1990'
), 

     total_forest_2016 AS (
        SELECT  region, 
                CAST((percent_forest) AS DECIMAL (5,2))
        FROM regional_outlook
        WHERE year = '2016'
     )
SELECT  x.region,
        x.percent_forest AS percent_1990,
        y.percent_forest AS percent_2016,
        CASE WHEN (x.percent_forest - y.percent_forest) > 0 THEN 'DECREASE'
        ELSE 'INCREASE' END
FROM total_forest_1990 AS x 
JOIN total_forest_2016 AS y
ON x.region = y.region
WHERE (x.percent_forest - y.percent_forest) > 0
GROUP BY 1, 2, 3, 4
ORDER BY 2, 3 




            -- Part 3: Country Level Detail -- 
/*  Unmarked Question: 
    1: Find the two countries that had the largest increase in forest 
       between 1990 and 2016*/
WITH  countries_1990 AS (
        SELECT  country_name, 
                region,
                year, 
                forest_area_sqkm 
        FROM    forestation
        WHERE   year = '1990' 
        GROUP BY 1, 2, 3, 4
        ORDER BY 4
), 

      countries_2016 AS ( 
        SELECT  country_name, 
                region,
                year, 
                forest_area_sqkm
        FROM    forestation
        WHERE   year = '2016' 
        GROUP BY 1, 2, 3, 4
        ORDER BY 4
    )
SELECT  x.country_name AS country_1990,
        x.region,
        (x.forest_area_sqkm - y.forest_area_sqkm) AS forest_difference
        
FROM countries_1990 AS x 
JOIN countries_2016 AS y
ON x.country_name = y.country_name
WHERE (x.forest_area_sqkm - y.forest_area_sqkm) IS NOT NULL 
  AND x.country_name != 'World' AND y.country_name != 'World'
GROUP BY 1, 2, 3
ORDER BY 3 
LIMIT 2;


/*  Unmarked Question:
    2:  Find the percentage of change for each country, then find the 
        country with the largest percentage: */

WITH  countries_1990 AS (
        SELECT  country_name, 
                region,
                year, 
                forest_area_sqkm
        FROM    forestation
        WHERE   year = '1990' 
        GROUP BY 1, 2, 3, 4
        ORDER BY 4
), 

      countries_2016 AS ( 
        SELECT  country_name, 
                region,
                year, 
                forest_area_sqkm
        FROM    forestation
        WHERE   year = '2016' 
        GROUP BY 1, 2, 3, 4
        ORDER BY 4
    )
SELECT  x.country_name AS country_1990,
        x.region,
        ABS((x.forest_area_sqkm - y.forest_area_sqkm)) AS forest_difference,
        ((x.forest_area_sqkm - y.forest_area_sqkm)/ x.forest_area_sqkm * 100) AS percentage_change
FROM countries_1990 AS x 
JOIN countries_2016 AS y
ON x.country_name = y.country_name
WHERE (x.forest_area_sqkm - y.forest_area_sqkm) IS NOT NULL 
  AND x.country_name != 'World' AND y.country_name != 'World'
GROUP BY 1, 2, 3, 4
ORDER BY 4 
LIMIT 1;




/* a. Which 5 countries saw the largest amount decrease in forest area 
      from 1990 to 2016? What was the difference in forest area for each? */

WITH  countries_1990 AS (
        SELECT  country_name, 
                region,
                year, 
                forest_area_sqkm
        FROM    forestation
        WHERE   year = '1990' 
        GROUP BY 1, 2, 3, 4
        ORDER BY 4
), 

      countries_2016 AS ( 
        SELECT  country_name, 
                region,
                year, 
                forest_area_sqkm
        FROM    forestation
        WHERE   year = '2016' 
        GROUP BY 1, 2, 3, 4
        ORDER BY 4
    )
SELECT  x.country_name AS country_1990,
        x.region,
        ABS((x.forest_area_sqkm - y.forest_area_sqkm)) AS forest_difference,
        ((x.forest_area_sqkm - y.forest_area_sqkm)/ x.forest_area_sqkm * 100) AS percentage_change
FROM countries_1990 AS x 
JOIN countries_2016 AS y
ON x.country_name = y.country_name
WHERE (x.forest_area_sqkm - y.forest_area_sqkm) IS NOT NULL 
  AND x.country_name != 'World' AND y.country_name != 'World'
GROUP BY 1, 2, 3, 4 
ORDER BY 3, 4 DESC
LIMIT 5;




/* b: Which 5 countries saw the largest percent decrease in forest area 
      from 1990 to 2016? What was the percent change to 2 decimal places 
      for each? */


WITH  countries_1990 AS (
        SELECT  country_name, 
                region,
                year, 
                forest_area_sqkm
        FROM    forestation
        WHERE   year = '1990' 
        GROUP BY 1, 2, 3, 4
        ORDER BY 4
), 

      countries_2016 AS ( 
        SELECT  country_name, 
                region,
                year, 
                forest_area_sqkm
        FROM    forestation
        WHERE   year = '2016' 
        GROUP BY 1, 2, 3, 4
        ORDER BY 4
    )
SELECT  x.country_name AS country_1990,
        x.region,
        ABS((x.forest_area_sqkm - y.forest_area_sqkm)) AS forest_difference,
        ((x.forest_area_sqkm - y.forest_area_sqkm)/ x.forest_area_sqkm * 100) AS percentage_change
FROM countries_1990 AS x 
JOIN countries_2016 AS y
ON x.country_name = y.country_name
WHERE (x.forest_area_sqkm - y.forest_area_sqkm) IS NOT NULL 
  AND x.country_name != 'World' AND y.country_name != 'World'
GROUP BY 1, 2, 3, 4 
ORDER BY 4 DESC
LIMIT 5;




/* c. If countries were grouped by percent forestation in quartiles, 
      which group had the most countries in it in 2016? */

WITH countries_2016 AS (
    SELECT  country_name,
            percent_forest,
            CASE
                WHEN percent_forest >= 0 AND percent_forest <= 25 THEN 1
                WHEN percent_forest >= 25 AND percent_forest <= 50 THEN 2
                WHEN percent_forest >= 50 AND percent_forest <= 75 THEN 3
                ELSE 4 
            END AS quartile
    FROM forestation
    WHERE year ='2016' AND country_name != 'World' AND percent_forest IS NOT NULL)
SELECT  quartile,
        COUNT(quartile) count
FROM countries_2016
GROUP BY 1 
ORDER BY 2;



/* d.  List all of the countries that were in the 4th quartile 
       (percent forest > 75%) in 2016. */

WITH countries_2016 AS (
    SELECT  country_name,
            percent_forest,
            CASE
                WHEN percent_forest >= 0 AND percent_forest <= 25 THEN 1
                WHEN percent_forest >= 25 AND percent_forest <= 50 THEN 2
                WHEN percent_forest >= 50 AND percent_forest <= 75 THEN 3
                ELSE 4 
            END AS quartile
    FROM forestation
    WHERE year ='2016' AND country_name != 'World' AND percent_forest IS NOT NULL)
SELECT  country_name,
		quartile,
        percent_forest
FROM countries_2016
WHERE quartile = 4
GROUP BY 1, 2, 3 
ORDER BY 3 DESC;




/* e. How many countries had a percent forestation higher than the 
      United States in 2016? */

SELECT COUNT (*)
FROM forestation 
WHERE percent_forest > (SELECT percent_forest
                        FROM forestation
                        WHERE year = '2016'
                        AND country_name = 'United States')


