
// QUERY 1 : CRUD OPERATIONS  [CREATE,INSERT,UPDATE,DELETE]
// A : INSERTING A NEW RECORD INTO COLLECTION 
// B : TO IDENTIFY THE NUTRITION IN FOOD WHICH HAS HIGH VITAMIN LEVELS

// INITIAL CHECK
db.Food.find()
    .sort({ID:-1})
    .limit(1)

// INSERT
db.Food.insert(
    {   ID: 93601,
        Description:"Sample Food",
        Calories: 100,
        Sodium: 100,
        Sugar: 100,
        // Calcium: 200,
        Iron: 100,
        Potassium: 100
})

// POST CHECKS
db.Food.find()
    .sort({ID:-1})
    .limit(1)

// UPDATE
db.Food.update(
    {   Description:"Sample Food"},
    {   $set:   {Calories: 200},
        $inc:   {Sodium: 10}
    }
)

// CHECK
db.Food.find({Description:"Sample Food"})

// UNDO UPDATE
db.Food.remove({Description:"Sample Food"}, {justOne: true})
db.Food.find({Description:"Sample Food"})

// DELETE DOCUMENT
db.Food.remove({Description:"Sample Food"}, {justOne: True})
db.Food.find({Description:"Sample Food"})


// QUERY 2 : CRUD USING OR & AND  [QUERY DOCUMENTS]
// A : TO IDENTIFY THE NUTRITION IN FOOD THAT IS CHICKEN AND ENERGY & PROTEIN LEVELS WITH & WITHOUT SKIN  
// B : TO IDENTIFY THE NUTRITION IN FOOD WHICH HAS HIGH VITAMIN LEVELS

db.NutrientValues.find(
 {"WWEIA Category code":2202,
 $or: [{"Food code":24100010},{"Food code":24100020}]})
.project({_id:0,ID:1,"Main food description":1,"WWEIA Category code":1,"Energy (kcal)":1,"Protein (g)":1})
.sort({"Energy (kcal)":-1})


db.Vitamins.find({VitaminC:{$gt:90},VitaminD:{$gt: 0.1},VitaminE:{$gt:15})
   .project({_id:0,ID:1,VitaminC:1,VitaminD:1,VitaminE:1})
   .sort({_id:-1})
   .limit(5)


// QUERY 3 : USING GREATER THAN ($gt) & ACCUMULATORS
// A : TO IDENTIFY THE NUTRITION IN FOOD WHICH HAS TOTAL VITAMINS LEVELS 
// B : TO GET AVERAGE POTASSIUM AMONG THE USDA FOOD COMPOSITION
// C : TO GET MAXIMUM AMOUNT OF CARBOHYDRATES PRESENT IN USDA FOOD FOODS

db.Vitamins.aggregate([
    {   $project:   {   _id:0, ID:1,VitaminC:1, VitaminD:1, VitaminE:1, 
                        Total_Vitamin:{ "$add": ["$VitaminC","$VitaminD","$VitaminE"]}}},
    {   $match: { "VitaminC": {$gt: 0 }, "VitaminD": {$gt: 0 }, "VitaminE": {$gt: 0 }}},
    {   $sort:  {Total_Vitamin:-1}},
    {   $limit: 5}
]);

db.Food.aggregate([
   {    $group: {_id: '', AveragePotassium: { $avg: "$Potassium"}}}])

db.Carbohydrates.aggregate([
    {   $group: {_id: '', maxCarbohydrate: {$max: "$Carbohydrate"}}}
])

// QUERY 4 : USING AGGREGATORS PIPELINE (MATCH & GROUBY) ALONG WITH WILD CARDS
// A : TO IDENTIFY THE NUTRITION IN FOOD WHICH IS CHEESE AND HAS HIGH CALORIES 
// B : TO IDENTIFY THE GROUP WHICH HAS AVERAGE AMOUNT OF PROTEIN MORE THAN 40
// C : TO IDENTIFY FOODS THAT ARE HIGHLY RICH IN FATS BY CHOLESTEROL

// A
db.Food.aggregate([{$match: {Description:/^CHEESE/}}])
    .project({_id:0,Description:1,Calories :1 ,Sodium : 1 , Calcium :1, Potassium :1})
    .sort({Calories:-1})
    .limit(5)
    
// B
db.Food.aggregate([
    {   $project:   {   _id:0, ID:1,
                        Main:   {"$arrayElemAt": [{"$split" : ["$Description", ","]}, 0]}}},
    {   $lookup:    {
           from: "Protein",
           localField: "ID",
           foreignField: "ID",
           as: "p"    }},
    {   $project:   {   Main:1, "p.Protein":1}},
    {   $unwind: '$p' },
    {   $group: {_id: "$Main", average_protein:  {$avg:"$p.Protein"}}},
    {   $sort:  {"average_protein":-1}}
]);
    
// C (1) : LOOKUP IN AGGREGATION PIPELINE AS MEANS OF JOIN 

db.Fat.aggregate([
    {   $sort:  {Cholesterol:-1}},
    {   $limit: 5},
    {   $lookup:    {
           from: "Food",
           localField: "ID",
           foreignField: "ID",
           as: "food"    }},
    {   $project:   {_id:0,ID:1, Cholesterol:1, "food.Description":1}}
]);

// C (2) :   LOOKUP IN AGGREGATION PIPELINE AS MEANS OF DOUBLE JOIN
         
db.Food.aggregate([
    {   $lookup:
        {  from: "Protein",
           localField: "ID",
           foreignField: "ID",
           as: "p"    
        }},
    {   $sort:  {"p.Protein":-1}},
    {   $lookup:    
        {  from: "Vitamins",
           localField: "ID",
           foreignField: "ID",
           as: "v"    
        }},
    {   $match:   {"p.Protein" : {$gt: 10}}},
    {   $match:   {"v.VitaminC": {$gt: 10}, "v.VitaminD": {$gt: 0.1}, "v.VitaminE": {$gt: 15}}},
    {   $project: {_id:0,ID:1, Description:1, "p.Protein":1, "v.VitaminC":1, "v.VitaminD":1, "v.VitaminE":1}}
]);


// QUERY 5 : USING AGGREGATORS -- SINGLE PURPOSE AGGREGATION OPERATIONS
// A : RETURN THE COUNT OF PROTEINS THAT IS GREATER THAN 50
// B : TO GET AVERAGE POTASSIUM AMONG THE USDA FOOD COMPOSITION
// C : JOINING TWO COLLECTION FOOD AND CARBOHYDRATES USING LOOKUP

db.Protein.count({Protein:{$gt:50}})

db.Carbohydrates.distinct("Sugar")

// USING ITERATIONS LIKE FOREACH STATEMENT

db.Food.find()
.sort({Sodium:-1})
.limit(10)
.forEach(function(item){print("The Food Item is : "+item.Description)});

// QUERY 6 : AGGREGATION : MAP REDUCE
// A : CALCULATING THE AGGREGATED VALUES OF IRON USING MAP REDUCE -- SIMPLE VERSION 
// B : CALCULATING THE AGGREGATED PORTION WEIGHT USING MAP REDUCE -- ELABORATED VERSION

// A 
db.Food.mapReduce(
function() { emit(this.ID, this.Iron); },
function(key, values) { return Array.sum(values); },
{
query: { Calories:367},
out: "IronContent"
}
)

// B 
// CALCULTING PORTION WEIGHT BASED ON FOOD CODE AND WWEIA CODE

var mapFunction = function() {
                       emit(this.Foodcode, this.Portionweight);
                   };
                   
var reduceFunction = function(keyFoodCode, PortionWeightValues) {
                          return Array.sum(PortionWeightValues);
                      };


db.PortionsAndWeights.mapReduce(
  mapFunction, 
reduceFunction,
      {
          query:{ WWEIACategorycode: 5502 },
          out: "Calc_weight"
      })


// QUERY 7 : INDEXES
// A : CREATING COMPOUND INDEX USING COLLATION [LANGUAGE SPECIFIC REQUIREMENTS]
// B : GETTING THE STATISTICS FOR INDEXES


//USER DEFINED COMPOUND INDEX 

db.Food.createIndex(
   { ID: 1, Description: 1},
   { collation: { locale: "en" } } )

db.Food.dropIndex({ID:1, Description: 1}, { collation: { locale: "en" } })

   
db.getCollectionNames().forEach(function(item) {
   indexes = db[item].getIndexes();
   print("Indexes for " + item + ":");
   printjson(indexes);
});

//db.Food.aggregate( [ { $indexStats: { } } ] )




         

         
         
         