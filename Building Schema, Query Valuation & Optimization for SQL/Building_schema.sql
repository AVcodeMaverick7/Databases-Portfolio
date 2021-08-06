/******************************

Authors     : Vikranth Ale
Create date : 27th March,2019
Description : USDA National Nutritional Data
Data Source : https://ndb.nal.usda.gov/ndb/
Data Source : https://courses.edx.org/courses/course-v1:MITx+15.071x+3T2018/courseware/e0d9ca1c350d42e5a8d6fd6a8162c1ab/01d6043d18d14f23a59c190490be27f9/1?activate_block_id=block-v1%3AMITx%2B15.071x%2B3T2018%2Btype%40vertical%2Bblock%4020b892d0279d4eea8d378f4d2d4a0a01

**************************
** Change History
**************************
** PR     Date        Author       Description 
** --   --------     --------   -------------------
** 1    27/03/2019   Vikranth    added  Primary & Foreign Keys
** 2    28/03/2019   Vikranth    added  Selections, expression and Joins
** 3    29/03/2019   Vik/Ken     added  AGGREGATE Operators , NESTED QUERIES
** 4    31/03/2019   Kentaro     added  Like Operators
** 5    31/03/2019   Vik/Ken     added  BETWEEN,GROUP BY,Having Conditions
** 6    31/03/2019   Vik/Ken     added  Views
*******************************/
-- SETTING UP ENVIRONMENT 
-- DEFINING PRIMARY AND FOREIGN KEYS

ALTER TABLE Food 
ADD PRIMARY KEY (ID)

ALTER TABLE Carbohydrates
ADD FOREIGN KEY (ID) REFERENCES Food (ID)

ALTER TABLE Fat
ADD FOREIGN KEY (ID) REFERENCES Food (ID)

ALTER TABLE Protein
ADD FOREIGN KEY (ID) REFERENCES Food (ID)

ALTER TABLE Vitamins
ADD FOREIGN KEY (ID) REFERENCES Food (ID)

-- DATA ANALYSIS USING SQL
-- EXECUTING THE QUERIES 

-- QUERY 1 : TO IDENTIFY THE FOOD WHICH HAS HIGH SODIUM LEVELS MORE THAN AVERAGE CONSUMPTION
-- TOPIC : SELECTIONS & PROJECTIONS, EXPRESSIONS AND ORDER BY 

SET STATISTICS TIME ON
SELECT TOP 5 ID,Description ,Sodium as HighSodiumFood
FROM Food
WHERE Sodium > 10000
ORDER BY Sodium DESC
SET STATISTICS TIME OFF

SELECT TOP 5 F.ID, Description , Cholesterol as HighCholestralFood
FROM Food F, Fat FT
WHERE F.ID = FT.ID
ORDER BY Cholesterol DESC

-- QUERY 2 : FOOD THAT IS VERY RICH IN VITAMINS AND PROTEINS
-- TOPIC: INNER JOIN

-- FOODS WHICH ARE RICH IN PROTEINS AND VITAMINS BASED ON ABOVE AVERAGE CONSUMPTION

SELECT TOP 10 F.ID,Description , P.Protein , V.VitaminC , V.VitaminD , V.VitaminE 
FROM Food F inner join Protein P on F.ID = F.ID inner join Vitamins V on F.ID = V.ID
WHERE P.Protein > 56 and V.VitaminC > 90 and V.VitaminD > 0.1 and V.VitaminE > 15
order by Protein DESC

-- QUERY 3
-- TOPIC : OPERATIONS ON EXPRESSIONS/ATTRIBUTES

SELECT  Vitamins.ID, Description, VitaminC, VitaminD, VitaminE, VitaminC+VitaminD+VitaminE AS total
FROM Vitamins, food
	WHERE food.ID = Vitamins.ID
	AND VitaminC > 0
	AND VitaminD > 0
	AND VitaminE > 0
	ORDER BY total DESC

-- QUERY 4  
-- TOPIC : AGGREGATE OPERATORS 

-- FOODS with Average Protein Levels

SELECT AVG(Potassium) as AverageProtein
FROM  Food 

SELECT MAX(Carbohydrate) AS LowCarbs
FROM Carbohydrates

SELECT COUNT(Protein) as ProteinCount
FROM Protein
WHERE Protein > 50

-- QUERY 5 
-- TOP 1 FOOD with Maximum No of Calories
SELECT TOP 10 ID,Description ,Calories
FROM Food
WHERE Calories IN ( SELECT MAX(Calories) AS HighCalories FROM Food)

-- ALTERNATIVE APPROACH
SELECT food.ID, Description, Iron
FROM food
WHERE Iron = (SELECT MAX(Iron)
			  FROM food);

-- QUERY 6
-- FOODS THAT ARE HIGH IN BOTH CALORIES AND PROTEINS 

SELECT DISTINCT top 10 food.ID, Description, Calories, Protein
FROM food, protein
WHERE protein.ID = food.ID
AND protein.ID = any(SELECT food.ID 
					 FROM food
					 WHERE Calories > 300)
ORDER BY Protein DESC

-- QUERY 7
-- TOPIC : LIKE & BETWEEN OPERATORS 

--RETURNING FOODS THAT ARE CHICKEN AND RICH IN PROTEINS WITH THEIR CHOLESTEROL AND ENERGY LEVELS

SELECT TOP 10 F.ID, Description, Protein, Calories, Cholesterol
FROM Food F, protein P, fat FT
WHERE F.ID = P.ID
AND F.ID  = FT.ID
AND Description LIKE 'CHICKEN%'
ORDER BY Protein DESC

SELECT TOP 10 F.ID, F.Description, Calories, Sugar , Cholesterol 
FROM Food F JOIN Carbohydrates ON F.ID = Carbohydrates.ID
          JOIN Fat ON F.ID = Fat.ID
WHERE Description LIKE '%MOZZARELLA%'
ORDER BY Cholesterol DESC

-- RECOMMENDED FOODS TO FULFILL INTAKE OF AVERAGE NO OF CALORIES AND SUGAR FOR MEN AND WOMEN

SELECT DISTINCT TOP 10 F.ID, F.Description, Calories, SUGAR FROM FOOD F JOIN Carbohydrates C ON F.ID = C.ID
WHERE Sugar BETWEEN 25 AND 40
ORDER BY Sugar DESC

-- QUERY 8
-- TOPIC : VIEWS

-- QUERY WITHOUT VIEW 
-- TIME : 122 ms

-- GETTING THE TOTAL NUTRITION INFORMATION FOR EVERY FOOD IN THE DATABASE

SET STATISTICS TIME ON
GO
SELECT F.ID , F.Description,F.Calories AS TotalEnergy,F.Calcium + F.Iron + F.Potassium + F.Sodium +
       V.VitaminC + V.VitaminD + V.VitaminE AS TotalVitamins ,
       C.Carbohydrate + C.Sugar AS TotalCarbs , FT.TotalFat , P.Protein AS TotalProtein
INTO dbo.TotalNutrition_TABLE
FROM Food F JOIN Vitamins V ON F.ID = V.ID JOIN  Carbohydrates C ON F.ID = C.ID JOIN Fat FT ON F.ID = FT.ID
     JOIN Protein P ON F.ID = P.ID
GO
SET STATISTICS TIME OFF
GO

-- VERIFYING THE ABOVE CREATED TABLE
SELECT * FROM TotalNutrition_TABLE

-- SAME QUERY WITH VIEW 
-- TIME : 4 ms

SET STATISTICS TIME ON
GO
CREATE VIEW TotalNutrition
AS
SELECT F.ID , F.Description,F.Calories AS TotalEnergy,F.Calcium + F.Iron + F.Potassium + F.Sodium +
       V.VitaminC + V.VitaminD + V.VitaminE AS TotalVitamins ,
       C.Carbohydrate + C.Sugar AS TotalCarbs , FT.TotalFat , P.Protein AS TotalProtein
FROM Food F JOIN Vitamins V ON F.ID = V.ID JOIN  Carbohydrates C ON F.ID = C.ID JOIN Fat FT ON F.ID = FT.ID
     JOIN Protein P ON F.ID = P.ID
GO
SET STATISTICS TIME OFF
GO

-- VERIFYING THE ABOVE CREATED VIEW
SELECT * FROM TotalNutrition

-- QUERY 9

-- QUERY WITHOUT VIEW 
-- TIME : 56 ms
-- DIVIDE THE MAIN FOOD WITH PROTEIN AND CALORIES INFORMATION

SET STATISTICS TIME ON
GO
SELECT food.ID, SUBSTRING(Description,1,ABS(CHARINDEX(',', Description)-1)) AS Main, Protein, Calories
INTO MainIngredient
FROM Food, Protein
WHERE Food.ID = Protein.ID;
SET STATISTICS TIME OFF
GO
SELECT * FROM MainIngredient
GO

-- DROP TABLE MainIngredient

-- QUERY WITH VIEW
-- TIME : 3 ms 

SET STATISTICS TIME ON 
GO
CREATE VIEW MainFood --3ms
AS
	SELECT food.ID, SUBSTRING(Description,1,ABS(CHARINDEX(',', Description)-1)) AS Main, Protein, Calories
	FROM food, protein
	WHERE food.ID = protein.ID;
GO            
SELECT * FROM MainFood;  --200ms
SET STATISTICS TIME OFF
GO

-- QUERY 10
-- TOPIC : GROUP BY & HAVING

SELECT Main, ROUND(AVG(Protein),2) AS AVGProtein
FROM MainFood
GROUP BY Main
HAVING AVG(Protein) > 40
ORDER BY AVGProtein DESC;

            
