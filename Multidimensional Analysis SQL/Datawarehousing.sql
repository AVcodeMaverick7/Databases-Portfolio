/******************************
Authors     : Vikranth Ale,Kentaro Kato
Create date : 7th June,2019
Description : USDA National Nutritional Data
Data Source : https://ndb.nal.usda.gov/ndb/

******************************/

-- QUERY 1 :  CHECKING THE CONNECTIVITY OF THE ENTIRE STAR AND SNOWFLAKES SCHEMA

SELECT TOP 1 *
FROM FACT_Nutrition AS FACT
INNER JOIN DIM_Ingredients AS DIM1 ON FACT.FoodCode = DIM1.IngredientFoodCode
INNER JOIN DIM_TotalNutrition AS DIM2 ON FACT.FoodCode = DIM2.FoodCode
INNER JOIN DIM_WWEIAInformation AS DIM3 ON FACT.WWEIACategoryCode = DIM3.WWEIACategorycode
INNER JOIN DIM_PortionsAndWeights AS DIM4 ON FACT.PAWFoodCode = DIM4.PAWFoodCode
INNER JOIN DIM2_Food              AS DIM5 ON DIM1.IngredientCode = DIM5.IngredientCode
INNER JOIN DIM2_WWEIAGroup AS DIM6  ON DIM3.WWEIAGroupID = DIM6.GroupID
INNER JOIN DIM2_IngredientNutrientValues AS DIM7 ON DIM5.IngredientCode = DIM7.IngredientCode


 -- QUERY 2 : NUTRITION INFORMATION IN FOOD THAT IS COOKED WITH CHICKEN AND CHEESE  [ BAD FOOD FOR HEALTH] 
 -- STAR SCHEMA WITH SINGLE DIMENSION

 SELECT DISTINCT TOP 5  DIM1.MainFoodDescription, COUNT(DIM1.MainFoodDescription) AS CHICKEN_COUNT,
 FACT.[Energy(kcal)],FACT.[Protein(g)],FACT.[Cholesterol(mg)],FACT.[Sodium(mg)]
 FROM FACT_Nutrition         AS  FACT 
 JOIN DIM_Ingredients        AS  DIM1 ON  FACT.FoodCode = DIM1.IngredientFoodCode  
WHERE MainFoodDescription LIKE '%CHICKEN%' AND MainFoodDescription LIKE '%CHEESE%'
GROUP BY MainFoodDescription,FACT.[Energy(kcal)],FACT.[Protein(g)],FACT.[Cholesterol(mg)],FACT.[Sodium(mg)]
ORDER BY FACT.[Protein(g)] DESC

SELECT DISTINCT * FROM DIM_Ingredients JOIN FACT_Nutrition ON DIM_Ingredients.IngredientFoodCode = FACT_Nutrition.FoodCode
WHERE MainFoodDescription = 'Chicken or turkey with cheese sauce'

-- QUERY 3 : USING AGGREGATION OPERATORS [ GOOD FOR BODY-BUILDING AND GYMNASTICS ] 

SELECT TOP 1 FACT.FoodCode, DIM1.MainFoodDescription,FACT.[Energy(kcal)],FACT.[Protein(g)],DIM1.IngredientWeight
FROM FACT_Nutrition as FACT 
INNER JOIN DIM_Ingredients AS DIM1 ON FACT.FoodCode = DIM1.IngredientFoodCode
WHERE [Protein(g)] =  (SELECT max([Protein(g)]) FROM FACT_Nutrition)

-- QUERY 4
-- FOODS THAT ARE RICH IN VITAMIN C & VITAMIN E  [  GOOD IN SUMMER ]

SELECT DISTINCT TOP 10 FACT.FoodCode,DIM2.MainFoodDescription, DIM1.[VitaminC(mg)]+DIM1.[VitaminE(mg)] AS VITAMIN_CE
FROM FACT_Nutrition as FACT 
INNER JOIN DIM_TotalNutrition AS DIM1 ON FACT.FoodCode = DIM1.FoodCode
INNER JOIN DIM_Ingredients AS DIM2 ON FACT.FoodCode = DIM2.IngredientFoodCode
ORDER BY VITAMIN_CE DESC


 -- QUERY 5 : NUTRITION INFORMATION IN FOOD THAT IS HIGH IN SODIUM LEVELS  [NO GOOD, MAY LEAD TO HIGHER BLOOD PRESSURE , RECOMMENDED 2300MG/ DAY]
 -- STAR SCHEMA WITH 3 DIMENSIONS
 SELECT DISTINCT TOP 3 DIM1.MainFoodDescription, DIM3.WWEIACategoryDescription,FACT.[Energy(kcal)],FACT.[Protein(g)],FACT.[Cholesterol(mg)],
                       FACT.[Sodium(mg)],DIM2.PortionDescription,DIM2.[PortionWeight(g)]
 FROM FACT_Nutrition         AS FACT 
 JOIN DIM_Ingredients        AS DIM1 ON  FACT.FoodCode = DIM1.IngredientFoodCode 
 JOIN DIM_PortionsAndWeights AS DIM2 ON FACT.PAWFoodCode = DIM2.PAWFoodCode      
 JOIN DIM_WWEIAInformation   AS DIM3 ON FACT.WWEIACategoryCode = DIM3.WWEIACategorycode
WHERE FACT.[Sodium(mg)] > 7000
ORDER BY DIM2.[PortionWeight(g)] DESC

-- VIEW WITH STAR SCHEMA 
-- QUERY 6:  RETURN VIEW WITH THE FOOD AND PREOTEIN PER WEIGHT

--1ST VIEW TO GET FOOD WEIGHT
DROP VIEW IF EXISTS Vfood_weight 
GO   
CREATE VIEW Vfood_weight
AS
	SELECT 	IngredientFoodCode, MainFoodDescription, sum(IngredientWeight) AS TotalWeight
	FROM    DIM_Ingredients
	GROUP BY IngredientFoodCode, MainFoodDescription
GO
SELECT TOP 10 * FROM Vfood_weight;

-- 2ND VIEW TO GET PROTEIN WEIGHT BASED ON WEIGHT
DROP VIEW IF EXISTS VProtein;
GO
CREATE VIEW VProtein 
AS
    SELECT FACT.FoodCode,WGT.MainFoodDescription,[Protein(g)],ROUND(FACT.[Protein(g)]/ TotalWeight,3) AS PROTEIN_AMOUNT
	FROM FACT_Nutrition FACT , Vfood_weight WGT 
	WHERE FACT.FoodCode = WGT.IngredientFoodCode
GO
SELECT * FROM VProtein
ORDER BY [Protein(g)] DESC

-- QUERY 7 : FROM THE ABOVE DATA CALCULATE TOTAL PROTEIN FOR EACH FOOD PER PORTION

SELECT DISTINCT TOP 10 VP.FoodCode, VP.MainFoodDescription ,PW.PortionDescription ,PW.[PortionWeight(g)] , VP.[Protein(g)],
                    ROUND(VP.[Protein(g)]/PW.[PortionWeight(g)],3)*100 AS TotalProteinPer100
FROM VProtein VP, DIM_PortionsAndWeights PW
WHERE VP.FoodCode = PW.PAWFoodCode
AND VP.[Protein(g)] > 1
AND PW.[PortionWeight(g)] > 1
ORDER BY pw.[PortionWeight(g)] DESC;

-- QUERY 8 : 

--  RETURN THE TOTAL ENERGY AND PROTEIN INFO FOR FOOD CODE "11100000"

SELECT FACT.PAWFoodCode,FACT.[Energy(kcal)],FACT.[Protein(g)],DIM1.PortionDescription,DIM1.[PortionWeight(g)],
       ROUND(FACT.[Energy(kcal)]/ DIM1.[PortionWeight(g)],3)*100 AS TotalEnergyPer100 , ROUND( FACT.[Protein(g)] / DIM1.[PortionWeight(g)],3)*100 AS TotalProteinPer100
FROM FACT_Nutrition FACT 
INNER JOIN DIM_PortionsAndWeights AS DIM1 ON FACT.PAWFoodCode = DIM1.PAWFoodCode
WHERE FACT.PAWFoodCode = 11100000


-- SNOWFLAKE SCHEMA - SECONDARY DIMENSIONS
-- QUERY 9 : TOTAL NUMBER OF FOODS IN THE DATABASE FOR EACH CATEGORY AS PER WWEIA

SELECT  DIM2.FoodType, count(*) AS Number_food
FROM FACT_Nutrition as FACT 
INNER JOIN DIM_WWEIAInformation AS DIM1 ON FACT.WWEIACategoryCode = DIM1.WWEIACategorycode
INNER JOIN DIM2_WWEIAGroup AS DIM2 ON DIM1.WWEIAGroupID = DIM2.GroupID
GROUP BY FoodType
ORDER BY Number_food DESC

-- QUERY 10 :  FOOD THAT IS HIGH IN CALORIES AND POTASSIUM LEVELS  
-- SNOWFLAKE WITH 2 SECONDARY DIMENSIONS
 SELECT DISTINCT TOP 1 DIM2.IngredientCode,DIM2.Description,FACT.[Energy(kcal)],FACT.[Sodium(mg)],DIM2.Potassium,DIM3.NutrientCode,
        DIM3.NutrientValue
 FROM FACT_Nutrition AS FACT
 INNER JOIN DIM_Ingredients AS DIM1 ON FACT.FoodCode = DIM1.IngredientFoodCode
 INNER JOIN DIM2_Food AS DIM2       ON DIM1.IngredientCode = DIM2.IngredientCode
 INNER JOIN DIM2_IngredientNutrientValues AS DIM3   ON DIM2.IngredientCode = DIM3.IngredientCode
WHERE DIM2.Calories >700
ORDER BY DIM2.Potassium DESC

 -- QUERY 11 : NUTRITION INFORMATION IN FOOD THAT IS HIGH IN SODIUM LEVELS
 -- SNOWFLAKE SCHEMA WITH 7 DIMENSIONS

SELECT TOP 10 DIM1.MainFoodDescription,DIM6.FoodType, FACT.[Cholesterol(mg)], AVG(FACT.[Energy(kcal)]) as TotalEnergy
FROM FACT_Nutrition AS FACT
INNER JOIN DIM_Ingredients AS DIM1 ON FACT.FoodCode = DIM1.IngredientFoodCode
INNER JOIN DIM_TotalNutrition AS DIM2 ON FACT.FoodCode = DIM2.FoodCode
INNER JOIN DIM_WWEIAInformation AS DIM3 ON FACT.WWEIACategoryCode = DIM3.WWEIACategorycode
INNER JOIN DIM_PortionsAndWeights AS DIM4 ON FACT.PAWFoodCode = DIM4.PAWFoodCode
INNER JOIN DIM2_Food              AS DIM5 ON DIM1.IngredientCode = DIM5.IngredientCode
INNER JOIN DIM2_WWEIAGroup AS DIM6  ON DIM3.WWEIAGroupID = DIM6.GroupID
INNER JOIN DIM2_IngredientNutrientValues AS DIM7 ON DIM5.IngredientCode = DIM7.IngredientCode
WHERE DIM6.GroupID between 1 AND 7
GROUP BY DIM1.MainFoodDescription,DIM6.FoodType,FACT.[Cholesterol(mg)]
ORDER BY TotalEnergy DESC

SELECT * FROM FACT_Nutrition JOIN DIM_Ingredients ON FACT_Nutrition.FoodCode=DIM_Ingredients.IngredientFoodCode
  WHERE [Energy(kcal)] = 902



