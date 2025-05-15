import "dart:math";
import 'dart:convert';
import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:firebase_storage/firebase_storage.dart";
import "package:intl/intl.dart";
import "package:pet_health_ai/models/app_state.dart";

class Pet {
  final String name;
  final String breed;
  double weight; // Now mutable for recalculating calorie needs
  final double age;
  final bool neutered_spayed;
  final String? imageUrl;
  double calorieIntake;
  Map<String, double> nutritionalRequirements;
  Map<String, double> nutritionalIntake;
  Map<String, dynamic>? weeklyNutrients;
  List<Map<String, dynamic>>? vetStatistics;
  List<Map<String, dynamic>>? exerciseLog;
  List<Map<String, dynamic>>? mealLog;
  List<Map<String, dynamic>>? favoriteFoods;
  late double calorieRequirement; // Auto-calculated based on weight

  Pet({
    required this.name,
    required this.breed,
    required this.weight,
    required this.age,
    required this.neutered_spayed,
    this.imageUrl,
    this.calorieIntake = 0,
    List<Map<String, dynamic>>? vetStatistics,
    List<Map<String, dynamic>>? exerciseLog,
    List<Map<String, dynamic>>? mealLog,
    List<Map<String, dynamic>>? favoriteFoods,
    Map<String, double>? nutritionalRequirements, // Optional parameter
    Map<String, double>? nutritionalIntake,
    Map<String, dynamic>? weeklyNutrients,
  }) : calorieRequirement = _calculateCalories(weight), // Step 1: Compute calorie requirement
       nutritionalRequirements = nutritionalRequirements ?? {}, // Initialize empty map first
       nutritionalIntake = nutritionalIntake ?? initializeIntake(), 
       weeklyNutrients = weeklyNutrients ?? initializeWeeklyNutrients(),
       vetStatistics = vetStatistics ?? [], 
       exerciseLog = exerciseLog ?? [],
       mealLog = mealLog ?? [],
       favoriteFoods = favoriteFoods ?? []{
    _calculateNutritionalRequirements(); // Step 2: Compute nutritional requirements based on calorieRequirement
    updateCarbohydrateRequirement(); // Step 3: Adjust carbohydrates dynamically
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'breed': breed,
      'weight': weight,
      'age': age,
      'neuteredSpayed': neutered_spayed,
      'imageUrl': imageUrl,
      'calorieIntake': calorieIntake,
      'nutritionalIntake': nutritionalIntake,
      'weeklyNutrients': weeklyNutrients,
      'vetStatistics': vetStatistics,
      'exerciseLog': exerciseLog,
      'mealLog': mealLog,
      'favoriteFoods':favoriteFoods
    };
  }

  // ✅ Create Pet object from JSON
  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      name: json['name'],
      breed: json['breed'],
      weight: (json['weight'] as num).toDouble(),
      age: (json['age'] as num).toDouble(),
      neutered_spayed: json['neuteredSpayed'],
      imageUrl: json.containsKey('imageUrl') ? json['imageUrl'] : null,
      calorieIntake: (json['calorieIntake'] ?? 0).toDouble(),
      nutritionalIntake: Map<String, double>.from(json['nutritionalIntake'] ?? initializeIntake()),
      weeklyNutrients: Map<String, dynamic>.from(json['weeklyNutrients'] ?? initializeWeeklyNutrients()),
      vetStatistics: List<Map<String, dynamic>>.from(json['vetStatistics']),
      exerciseLog: List<Map<String, dynamic>>.from(json['exerciseLog']),
      mealLog: List<Map<String, dynamic>>.from(json['mealLog']),
      favoriteFoods: List<Map<String, dynamic>>.from(json['favoriteFoods'])
    );
  }

  Pet copyWith({
    String? name,
    String? breed,
    double? weight,
    double? age,
    bool? neutered_spayed,
    String? imageUrl
  }) {
    return Pet(
      name: name ?? this.name,
      breed: breed ?? this.breed,
      weight: weight ?? this.weight,
      age: age ?? this.age,
      neutered_spayed: neutered_spayed ?? this.neutered_spayed,
      imageUrl: imageUrl ?? this.imageUrl,
      calorieIntake: calorieIntake,
      nutritionalIntake: Map<String, double>.from(nutritionalIntake),
      nutritionalRequirements: Map<String, double>.from(nutritionalRequirements),
      weeklyNutrients: Map<String, dynamic>.from(weeklyNutrients ?? {}),
      vetStatistics: List<Map<String, dynamic>>.from(vetStatistics ?? []),
      exerciseLog: List<Map<String, dynamic>>.from(exerciseLog ?? []),
      mealLog: List<Map<String, dynamic>>.from(mealLog ?? []),
      favoriteFoods: List<Map<String, dynamic>>.from(favoriteFoods ?? []),
    );
  }


  // Function to calculate calorie requirements based on weight
  static double _calculateCalories(double weight) {
    try {// Extract number
      return 70 * pow(weight, 0.75).toDouble(); // Standard RER formula
    } catch (e) {
      return 0; // Fallback in case of parsing error
    }
  }

  // Function to initialize empty nutritional intake
  static Map<String, double> initializeIntake() {
    return {
    "Carbohydrates":0,
    "Crude Protein": 0,
    "Arginine": 0,
    "Histidine": 0,
    "Isoleucine": 0,
    "Leucine": 0,
    "Lysine": 0,
    "Methionine": 0,
    "Methionine-cystine": 0,
    "Phenylalanine": 0,
    "Phenylalanine-tyrosine": 0,
    "Threonine": 0,
    "Tryptophan": 0,
    "Valine": 0,
    "Crude Fat": 0,
    "Linoleic acid": 0,
    "Calcium": 0,
    "Phosphorus": 0,
    "Potassium": 0,
    "Sodium": 0,
    "Chloride": 0,
    "Magnesium": 0,
    "Iron": 0,
    "Copper": 0,
    "Manganese": 0,
    "Zinc": 0,
    "Iodine": 0,
    "Selenium": 0,
    "Vitamin A": 0,
    "Vitamin D": 0,
    "Vitamin E": 0,
    "Thiamine": 0,
    "Riboflavin": 0,
    "Pantothenic acid": 0,
    "Niacin": 0,
    "Pyridoxine": 0,
    "Folic acid": 0,
    "Vitamin B12": 0,
    "Choline": 0
    };
  }

  static Map<String, dynamic> initializeWeeklyNutrients() {
    return {
      "Monday": {
        "Calories": 0,
        "Carbohydrates": 0,
        "Crude Fat": 0,
        "Crude Protein": 0
      },
      "Tuesday": {
        "Calories": 0,
        "Carbohydrates": 0,
        "Crude Fat": 0,
        "Crude Protein": 0
      },
      "Wednesday": {
        "Calories": 0,
        "Carbohydrates": 0,
        "Crude Fat": 0,
        "Crude Protein": 0
      },
      "Thursday": {
        "Calories": 0,
        "Carbohydrates": 0,
        "Crude Fat": 0,
        "Crude Protein": 0
      },
      "Friday": {
        "Calories": 0,
        "Carbohydrates": 0,
        "Crude Fat": 0,
        "Crude Protein": 0
      },
      "Saturday": {
        "Calories": 0,
        "Carbohydrates": 0,
        "Crude Fat": 0,
        "Crude Protein": 0
      },
      "Sunday": {
        "Calories": 0,
        "Carbohydrates": 0,
        "Crude Fat": 0,
        "Crude Protein": 0
      },
    };
  }

  // Function to calculate nutritional requirements dynamically based on calorieRequirement
  void _calculateNutritionalRequirements() {
    // Mapping from Python's nutrient_profile_data (Adult_Maintenance_Minimum)
    final Map<String, double> growthNutrientProfile = {
    "Crude Protein": 56.3,
    "Arginine": 2.50,
    "Histidine": 1.10,
    "Isoleucine": 1.78,
    "Leucine": 3.23,
    "Lysine": 2.25,
    "Methionine": 0.88,
    "Methionine-cystine": 1.75,
    "Phenylalanine": 2.08,
    "Phenylalanine-tyrosine": 3.25,
    "Threonine": 2.60,
    "Tryptophan": 0.50,
    "Valine": 1.70,
    "Crude Fat": 21.3,
    "Linoleic acid": 3.3,
    "Calcium": 3.0,
    "Phosphorus": 2.5,
    "Potassium": 1.5,
    "Sodium": 0.80,
    "Chloride": 1.10,
    "Magnesium": 0.15,
    "Iron": 22.0,
    "Copper": 3.1,
    "Manganese": 1.8,
    "Zinc": 25.0,
    "Iodine": 0.25,
    "Selenium": 0.09,
    "Vitamin A": 1250.0,
    "Vitamin D": 125.0,
    "Vitamin E": 12.5,
    "Thiamine": 0.56,
    "Riboflavin": 1.3,
    "Pantothenic acid": 3.0,
    "Niacin": 3.4,
    "Pyridoxine": 0.38,
    "Folic acid": 0.054,
    "Vitamin B12": 0.007,
    "Choline": 340.0,
  };
    final Map<String, double> adultNutrientProfile = {
      "Crude Protein": 45.0,
      "Arginine": 1.28,
      "Histidine": 0.48,
      "Isoleucine": 0.95,
      "Leucine": 1.70,
      "Lysine": 1.58,
      "Methionine": 0.83,
      "Methionine-cystine": 1.63,
      "Phenylalanine": 1.13,
      "Phenylalanine-tyrosine": 1.85,
      "Threonine": 1.20,
      "Tryptophan": 0.40,
      "Valine": 1.23,
      "Crude Fat": 13.8,
      "Linoleic acid": 2.8,
      "Calcium": 1.25,
      "Phosphorus": 1.00,
      "Potassium": 1.5,
      "Sodium": 0.20,
      "Chloride": 0.30,
      "Magnesium": 0.15,
      "Iron": 10.0,
      "Copper": 1.83,
      "Manganese": 1.25,
      "Zinc": 20.0,
      "Iodine": 0.25,
      "Selenium": 0.08,
      "Vitamin A": 1250.0,
      "Vitamin D": 125.0,
      "Vitamin E": 12.5,
      "Thiamine": 0.56,
      "Riboflavin": 1.3,
      "Pantothenic acid": 3.0,
      "Niacin": 3.4,
      "Pyridoxine": 0.38,
      "Folic acid": 0.054,
      "Vitamin B12": 0.007,
      "Choline": 340.0,
    };

    // Calculate based on calorie requirement (MER kcal)
    bool isGrowthStage = age < 12;
    final Map<String, double> nutrientProfile = isGrowthStage ? growthNutrientProfile: adultNutrientProfile;

    nutrientProfile.forEach((nutrient, value) {
      nutritionalRequirements[nutrient] = (value * calorieRequirement) / 1000;
    });
    updateCarbohydrateRequirement(); // Adjust carbohydrates dynamically
  }

  // Function to calculate carbohydrate requirement dynamically
  void updateCarbohydrateRequirement() {
    double proteinCalories = (nutritionalRequirements["Crude Protein"] ?? 0) * 4;
    double fatCalories = (nutritionalRequirements["Crude Fat"] ?? 0) * 9;
    double carbCalories = calorieRequirement - (proteinCalories + fatCalories);
    nutritionalRequirements["Carbohydrates"] = carbCalories / 4; // Convert to grams
  }

  Future<void> addFood(Map<String, double> foodNutrition, String barcode, String amount, MyAppState appState) async {
   try{
    print("🔍 Scanned Food Data: ${appState.scannedFoodData}");
     String? petID = await getCurrentPetID();
     if (petID == null) {
       print("❌ Cannot update food intake - Pet not found!");
       return;
     }
     final petRef = FirebaseFirestore.instance.collection("pets").doc(petID);
     Map<String, dynamic> updateData = {};
    
     foodNutrition.forEach((key, value) {
       if (key == "Calories") {
         calorieIntake += value;
         updateData["calorieIntake"] = calorieIntake;
       } else {
         nutritionalIntake[key] = (nutritionalIntake[key] ?? 0) + value;
         updateData["nutritionalIntake.$key"] = nutritionalIntake[key]; // 🔥 Update nested field
       }
     });
     await petRef.update(updateData);
     print("✅ Nutritional intake updated for pet: $name (ID: $petID)");

     await logMeal(appState, barcode, amount);
     await appState.updateLocalPetData();
   }
   catch(e){
     print("❌ Cannot update food intake");
   }
 }

  Future<String?> getCurrentPetID() async {
   try{
     final uid = FirebaseAuth.instance.currentUser?.uid;
     final petRef = await FirebaseFirestore.instance
       .collection("pets")
       .where("ownerUID", arrayContains: uid)
       .where("name", isEqualTo: name)
       .limit(1)
       .get();


     if (petRef.docs.isEmpty) {
       print("❌ No pet found with name '$name' for user '$uid'");
       return null;
     }

     return petRef.docs.first.id;
   }
   catch(e){
     print("❌ Error updating nutritional intake: $e");
     return null;
   }
 }
 
  // Update pet’s weight and recalculate calorie requirements + nutrition
  void updateWeight(double newWeight) {
    weight = newWeight;
    calorieRequirement = _calculateCalories(newWeight);
    updateNutritionalRequirements();
  }

  // Dynamically update nutritional requirements based on weight change
  void updateNutritionalRequirements() {
    _calculateNutritionalRequirements();
    updateCarbohydrateRequirement();
  }
  
  Future<void> recordVetVisit({
    required String date,
    double? weight,
    double? height,
    double? bcs,
    String? notes,     
    required MyAppState appState,   // Default to empty string if not provided
    }) async {
      try{
        String? petID = await getCurrentPetID();
        if (petID == null) {
          print("❌ Cannot record vet visit - Pet not found!");
          return;
        }
        final petRef = FirebaseFirestore.instance.collection("pets").doc(petID);
        Map<String, dynamic> visitVisitEntry = {
          "date":date,  // Store date as a string (YYYY-MM-DD format recommended)
          "weight": weight,
          "height": height,
          "bcs": bcs,
          "notes": notes,
        };
        double? validWeight = double.tryParse(weight.toString());
        if(validWeight != null){
          updateWeight(validWeight);
          await petRef.update({
            "weight": weight,
            "vetStatistics": FieldValue.arrayUnion([visitVisitEntry]),
          });
        }
        else{
          await petRef.update({
            "vetStatistics": FieldValue.arrayUnion([visitVisitEntry]),
          });
        }

        vetStatistics!.add({
          "date":date,  // Store date as a string (YYYY-MM-DD format recommended)
          "weight": weight,
          "height": height,
          "bcs": bcs,
          "notes": notes,
        });
      
        print("✅ Vet visit recorded successfully for $date!");
        
        await appState.updateLocalPetData();
        print(vetStatistics);
      }
      catch(e){print(e);}
    }

  Future<void> logExercise({ 
    required String exerciseType,
    required double minutes,
    required MyAppState appState, 
  }) async{
    final now = DateTime.now();
    final formattedTime = DateFormat.Hm().format(now);
    try{
      String? petID = await getCurrentPetID();
      if (petID == null) {
        print("❌ Cannot log exercise - Pet not found!");
        return;
      }
      double caloriesBurnt = 0; //will do the function later
      final petRef = FirebaseFirestore.instance.collection("pets").doc(petID);
      Map<String, dynamic> exerciseLogEntry = {
        "date_time":formattedTime,  // Store date as a string (YYYY-MM-DD format recommended)
        "exerciseType": exerciseType,
        "minutes": minutes,
        "caloriesBurnt": caloriesBurnt,
      };
        
      await petRef.update({
        "exerciseLog": FieldValue.arrayUnion([exerciseLogEntry])
      });

      exerciseLog!.add({
        "date_time":formattedTime,  // Store date as a string (YYYY-MM-DD format recommended)
        "exerciseType": exerciseType,
        "minutes": minutes,
        "caloriesBurnt": caloriesBurnt,
      });
    
      print("✅ Exercise recorded successfully for $formattedTime!");
      
      await appState.updateLocalPetData();
      print(exerciseLog);
    }
    catch(e){print(e);}
  }

  Future<void> logMeal( 
    MyAppState appState,
    String barcode,
    String amount
  ) async{
    final now = DateTime.now();
    final formattedTime = DateFormat.Hm().format(now);

    try{
      String? petID = await getCurrentPetID();
      if (petID == null) {
        print("❌ Cannot log meal - Pet not found!");
        return;
      }
      final petRef = FirebaseFirestore.instance.collection("pets").doc(petID);
      Map<String, dynamic> mealLogEntry = {
        "date_time":formattedTime,  // Store date as a string (YYYY-MM-DD format recommended)
        "barcode": barcode,
        "amount":amount
      };
        
      await petRef.update({
        "mealLog": FieldValue.arrayUnion([mealLogEntry])
      });

      mealLog!.add(
        mealLogEntry
      );
    
      print("✅ Meal recorded successfully for $formattedTime!");
      print(mealLog);
    }
    catch(e){print(e);}
  }

  Future<void> changeFavorites(String barcode, MyAppState appState)async{
    try {
      String? petID = await getCurrentPetID();
      if (petID == null) {
        print("❌ Cannot log meal - Pet not found!");
        return;
      }
      if (barcode == "No Barcode") {
        print("❌ Cannot favorite - no barcode!");
        return;
      }
      final petRef = FirebaseFirestore.instance.collection("pets").doc(petID);

      Map<String, dynamic>? existingFavorite = favoriteFoods!.firstWhere(
        (food) => food["barcode"] == barcode,
        orElse: () => {},
      );

      bool add = existingFavorite.isEmpty;

      if (add == true){
        await appState.fetchBarcodeData(barcode);
        Map<String, dynamic> cleanedData = Map<String, dynamic>.from(appState.scannedFoodData)
          ..remove('updatedAt');

        final rawFrontImage = cleanedData["frontImage"];
        if (rawFrontImage is String && !rawFrontImage.startsWith("http")) {
          try {
            final ref = FirebaseStorage.instance.ref(rawFrontImage);
            final resolvedUrl = await ref.getDownloadURL();
            cleanedData["frontImage"] = resolvedUrl;
          } catch (e) {
            print("⚠️ Could not resolve frontImage: $e");
            // Optional: remove it if resolution fails
            cleanedData.remove("frontImage");
          }
        }

        Map<String, dynamic> newFavorite = jsonDecode(jsonEncode(cleanedData));

        await petRef.update({
          "favoriteFoods": FieldValue.arrayUnion([newFavorite])
        });
        favoriteFoods!.add(newFavorite);
        appState.scannedFoodData = {};

        print("✅ New favorite added successfully for $barcode!");
        print(favoriteFoods);
      }
      else{
        await petRef.update({
          "favoriteFoods": FieldValue.arrayRemove([existingFavorite])
        });
        favoriteFoods!.remove(existingFavorite);
        print("❌ Favorite removed for $barcode!");
      }
      await appState.updateLocalPetData();
    }
    catch(e){
      print(e);
    }
  }
}