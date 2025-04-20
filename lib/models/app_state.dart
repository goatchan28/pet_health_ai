import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'pet.dart';
import 'dart:convert';
import "package:shared_preferences/shared_preferences.dart";

class MyAppState extends ChangeNotifier {
  int currentPageIndex = 2;
  int enterAccountIndex = 0;
  int petIndex = 0;
  Map<String, dynamic> scannedFoodData = {};
  bool barcodeNotFound = false;
  String name = "Guest";
  bool needsToEnterName = false;
  final Pet defaultPet = Pet(name: "Buddy", breed: "Golden Retriever", weight: 29, age: 6, neutered_spayed: false);
  late SharedPreferencesWithCache prefs;
  bool hasLoadedData = false;
  List<Pet> pets = [];
  
  MyAppState() {
    pets = [defaultPet];
  }

  final Map<String, String> apiToAppNutrientMap = {
    // ---- Bare keys ----
    "proteins": "Crude Protein",
    "arginine": "Arginine",
    "histidine": "Histidine",
    "isoleucine": "Isoleucine",
    "leucine": "Leucine",
    "lysine": "Lysine",
    "methionine": "Methionine",
    "methionine-cystine": "Methionine-cystine",
    "phenylalanine": "Phenylalanine",
    "phenylalanine-tyrosine": "Phenylalanine-tyrosine",
    "threonine": "Threonine",
    "tryptophan": "Tryptophan",
    "valine": "Valine",
    "fat": "Crude Fat",
    "linoleic-acid": "Linoleic acid",
    "calcium": "Calcium",
    "phosphorus": "Phosphorus",
    "potassium": "Potassium",
    "sodium": "Sodium",
    "chloride": "Chloride",
    "magnesium": "Magnesium",
    "iron": "Iron",
    "copper": "Copper",
    "manganese": "Manganese",
    "zinc": "Zinc",
    "iodine": "Iodine",
    "selenium": "Selenium",
    "vitamin-a": "Vitamin A",
    "vitamin-d": "Vitamin D",
    "vitamin-e": "Vitamin E",
    "thiamin": "Thiamine",
    "riboflavin": "Riboflavin",
    "pantothenic-acid": "Pantothenic acid",
    "niacin": "Niacin",
    "vitamin-b6": "Pyridoxine",
    "folic-acid": "Folic acid",
    "vitamin-b12": "Vitamin B12",
    "choline": "Choline",
    "carbohydrates": "Carbohydrates",
    "energy-kcal": "Calories",

    // ---- _100g keys ----
    "proteins_100g": "Crude Protein",
    "arginine_100g": "Arginine",
    "histidine_100g": "Histidine",
    "isoleucine_100g": "Isoleucine",
    "leucine_100g": "Leucine",
    "lysine_100g": "Lysine",
    "methionine_100g": "Methionine",
    "methionine-cystine_100g": "Methionine-cystine",
    "phenylalanine_100g": "Phenylalanine",
    "phenylalanine-tyrosine_100g": "Phenylalanine-tyrosine",
    "threonine_100g": "Threonine",
    "tryptophan_100g": "Tryptophan",
    "valine_100g": "Valine",
    "fat_100g": "Crude Fat",
    "linoleic-acid_100g": "Linoleic acid",
    "calcium_100g": "Calcium",
    "phosphorus_100g": "Phosphorus",
    "potassium_100g": "Potassium",
    "sodium_100g": "Sodium",
    "chloride_100g": "Chloride",
    "magnesium_100g": "Magnesium",
    "iron_100g": "Iron",
    "copper_100g": "Copper",
    "manganese_100g": "Manganese",
    "zinc_100g": "Zinc",
    "iodine_100g": "Iodine",
    "selenium_100g": "Selenium",
    "vitamin-a_100g": "Vitamin A",
    "vitamin-d_100g": "Vitamin D",
    "vitamin-e_100g": "Vitamin E",
    "thiamin_100g": "Thiamine",
    "riboflavin_100g": "Riboflavin",
    "pantothenic-acid_100g": "Pantothenic acid",
    "niacin_100g": "Niacin",
    "vitamin-b6_100g": "Pyridoxine",
    "folic-acid_100g": "Folic acid",
    "vitamin-b12_100g": "Vitamin B12",
    "choline_100g": "Choline",
    "carbohydrates_100g": "Carbohydrates",
    "energy-kcal_100g": "Calories",
  };


  Future<void> scheduleDailyReset() async{
    final now = DateTime.now();
    final todayUtc = "${now.year}-${now.month}-${now.day}";

    try {
      // 🔥 Get last reset date from Firestore (System-wide)
      final resetDoc = await FirebaseFirestore.instance
          .collection("system")
          .doc("dailyReset")
          .get();

      final lastResetDate = resetDoc.exists ? resetDoc["lastResetDate"] : null;

      if (lastResetDate == todayUtc) {
        print("✅ Already reset today. Skipping reset.");
        return; // Prevent multiple resets in one day
      }

      print("🌙 Running daily reset...");
      await saveDailyNutrients();
      await resetAllPets(); // Reset for all users

      // 🔥 Save today's date (UTC) in Firestore
      await FirebaseFirestore.instance
          .collection("system")
          .doc("dailyReset")
          .set({"lastResetDate": todayUtc});

      print("✅ Daily reset completed.");
    } catch (e) {
      print("❌ Error in daily reset: $e");
    }
  }
  
  Future<void> resetAllPets() async {
    try {
      print("🌙 Resetting all pets' intake...");
    
      // 🔥 Fetch ALL pets from Firestore
      final petCollection = FirebaseFirestore.instance.collection("pets");
      final querySnapshot = await petCollection.get();

      // Loop through all pets and reset their intake
      for (var doc in querySnapshot.docs) {
        await doc.reference.update({
          "calorieIntake": 0,
          "nutritionalIntake": Pet.initializeIntake(),
          "mealLog":[],
          "exerciseLog":[] // Reset all nutrients to zero
        });
      }

      if (pets.isNotEmpty) {
        for (Pet pet in pets) {
          pet.calorieIntake = 0;
          pet.nutritionalIntake = Pet.initializeIntake();
          pet.mealLog = [];
          pet.exerciseLog = [];
        }
        await updateLocalPetData();
      }

      print("✅ All pets' intake reset successfully!");
    } catch (e) {
      print("❌ Error resetting pets: $e");
    }
  }

  Future<void> init() async {
    prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: <String>{"name", "pets", "lastResetDate"}
      )
    );
    await loadData();
    await scheduleDailyReset();
  }

  Future<void> loadData() async {
    if (hasLoadedData) return;
    hasLoadedData = true;
    String? savedName = prefs.getString("name") ?? "Guest";

    name = savedName;
    notifyListeners();

    final String? petsData = prefs.getString("pets");
    if (petsData != null && petsData.isNotEmpty) {
      try {
        List<dynamic> decodedPets = jsonDecode(petsData);
        List<Pet> loadedPets = decodedPets.map((pet) => Pet.fromJson(pet)).toList();
        if (loadedPets != pets) { // Only update if pets actually changed
          pets = loadedPets;
          notifyListeners(); // 🔄 Only update UI if necessary
        }
      } catch (e) {
        print("Error loading pets: $e");
        pets = [defaultPet]; // Reset if there's an issue
        notifyListeners();
      }
    } else {
      pets = [defaultPet]; // Default if no pets saved
      notifyListeners();
    }
  }

  Pet get selectedPet => pets[petIndex];

  Future<void> setName(String newName) async {
    name = newName;

    await prefs.setString("name", name);

    // 🔥 Update FirebaseAuth display name if logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updateProfile(displayName: name);
    }
    notifyListeners();
  }

  void changeIndex(int idx){
    currentPageIndex = idx;
    notifyListeners();
  }

  void changeEnterAccountIndex(int idx){
    enterAccountIndex = idx;
    notifyListeners();
  }

  Future<void> saveDailyNutrients() async {
    try {
      final now = DateTime.now();
      final yesterday = now.subtract(Duration(days:1));
      final dayOfWeek = DateFormat('EEEE').format(yesterday);

      print("📅 Saving daily nutrients for $dayOfWeek (yesterday)...");

      final petCollection = FirebaseFirestore.instance.collection("pets");
      final querySnapshot = await petCollection.get();

      if (dayOfWeek == "Saturday"){
         for (var doc in querySnapshot.docs){
            final petDocRef = doc.reference;
            await petDocRef.set(
              {"weeklyNutrients": Pet.initializeWeeklyNutrients()}, SetOptions(merge:true)
            );
         }
         if (pets.isNotEmpty) {
          for (Pet pet in pets) {
            pet.weeklyNutrients = Pet.initializeWeeklyNutrients();
          } 
          await updateLocalPetData();
        }
        print("It is Saturday! Reset weekly nutrients!");
  
        return;
      }

      for (var doc in querySnapshot.docs){
        final petDocRef = doc.reference;
        final petData = doc.data();

        final intakeData = petData['nutritionalIntake'] as Map<String, dynamic>;

        final double carbohydrates = (intakeData["Carbohydrates"] ?? 0).toDouble();
        final double protein = (intakeData["Crude Protein"] ?? 0).toDouble();
        final double fat = (intakeData["Crude Fat"] ?? 0).toDouble();
        final double calorieIntake = petData["calorieIntake"].toDouble() ?? 0;

        // Save daily intake
        await petDocRef.update({
          "weeklyNutrients.$dayOfWeek.Carbohydrates": carbohydrates,
          "weeklyNutrients.$dayOfWeek.Crude Protein": protein,
          "weeklyNutrients.$dayOfWeek.Crude Fat": fat,
          "weeklyNutrients.$dayOfWeek.Calories": calorieIntake,
        });

        print("✅ Daily nutrients saved for pet ${doc.id} on $dayOfWeek!");
      }

      if (pets.isNotEmpty) {
        for (Pet pet in pets) {
          pet.weeklyNutrients![dayOfWeek]!["Carbohydrates"] = (pet.nutritionalIntake["Carbohydrates"] ?? 0).toDouble();
          pet.weeklyNutrients![dayOfWeek]!["Crude Protein"] = (pet.nutritionalIntake["Crude Protein"] ?? 0).toDouble();
          pet.weeklyNutrients![dayOfWeek]!["Crude Fat"] = (pet.nutritionalIntake["Crude Fat"] ?? 0).toDouble();
          pet.weeklyNutrients![dayOfWeek]!["Calories"] = (pet.calorieIntake).toDouble();
        } 
      }
      await updateLocalPetData();
      print("🎯 All pets' daily nutrients saved successfully!");
    }
    catch(e){
      print("❌ Error saving daily nutrients: $e");
    }
  }

  Future<void> addPetManually({
    required String name,
    required String breed,
    required double weight,
    required double age,
    required bool neuteredSpayed,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // 🔥 Directly push user-entered info to Firestore
        final docRef = await FirebaseFirestore.instance.collection('pets').add({
          'name': name,
          'breed': breed,
          'weight': weight,
          'age': age,
          'neuteredSpayed': neuteredSpayed,
          'ownerUID': [uid], 
          'calorieIntake':0,
          'nutritionalIntake':Pet.initializeIntake(),
          'weeklyNutrients':Pet.initializeWeeklyNutrients(),
          'vetStatistics': [],
          'exerciseLog': [],
          'mealLog':[],
          'favoriteFoods':[]
        });

        print("Pet added to Firestore with ID: ${docRef.id}");
      } else {
        print("User is not logged in!");
      }
      await getPets(true);
      notifyListeners();
    } catch (e) {
      print("Error adding pet to Firestore: $e");
    }
  }

  Future<void> addPetID(String desiredPetID) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid!= null){
      try {
        final docRef = FirebaseFirestore.instance.collection("pets").doc(desiredPetID);
        final docSnapshot = await docRef.get();

        // Check if the document exists
        if (docSnapshot.exists) {
          List<dynamic> ownerUIDs = docSnapshot.data()?["ownerUID"] ?? [];
          // If the document exists, update the ownerUID array
          if (!ownerUIDs.contains(uid)) {
            // If the uid is not already in the ownerUID array, add it
            await docRef.update({
              "ownerUID": FieldValue.arrayUnion([uid]),
            });
            print("✅ Owner UID added successfully to pet $desiredPetID");
          } else {
            print("❌ Owner UID is already in the list.");
          }
        } else {
          print("❌ Document with ID $desiredPetID does not exist.");
        }
        await getPets(true);
        notifyListeners();
      }
      catch(e){
        print("❌ Error adding owner UID to pet $desiredPetID: $e");
      }
    }
  }

  void selectPet(int index) {
    if (index >= 0 && index < pets.length) {
      petIndex = index;
      notifyListeners();
    }
  }

  void updatePetIntake(Pet pet, Map<String, double> updatedValues, String barcode, String amount) {
    pet.addFood(updatedValues, barcode, amount, this);
    scannedFoodData = {}; // Update the pet's intake
    notifyListeners(); // Notify UI about changes
  }

  void setNeedsToEnterName(bool value) {
    needsToEnterName = value;
    notifyListeners();
  }

  Future<void> getPets(bool petAdded) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final String? petsData = prefs.getString("pets");

      if (petsData != null && petsData.isNotEmpty && !petAdded) {
        List<dynamic> decodedPets = jsonDecode(petsData);
        pets = decodedPets.map((pet) => Pet.fromJson(pet)).toList();
        print("Pets loaded from SharedPreferences");
        notifyListeners();
        return;
      }

      if (uid != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('pets')
            .where("ownerUID", arrayContains: uid)  // Filter by user ID if needed
            .get();

        print(FirebaseAuth.instance.currentUser?.displayName);

        if (snapshot.docs.isNotEmpty){
          pets = snapshot.docs.map((doc) {
            final data = doc.data();

            // Create a Pet object for each document
            return Pet.fromJson(data);
          }).toList();
          await prefs.setString("pets", jsonEncode(pets.map((pet) => pet.toJson()).toList()));
          notifyListeners();
        }
        notifyListeners();   // Notify listeners to update UI
        print("Pets fetched successfully: ${pets.length} pets.");
      }
    } catch (e) {
      print("Error fetching pets: $e");
    }
  }

  Future<void> updateLocalPetData() async {
   try {
     await prefs.setString("pets", jsonEncode(pets.map((pet) => pet.toJson()).toList()));
     print("✅ SharedPreferences updated for modified pet!");
     notifyListeners();
   } catch (e) {
     print("❌ Error updating SharedPreferences: $e");
     notifyListeners();
   }
 }

  
  void signOut() async {
    await FirebaseAuth.instance.signOut();
    changeEnterAccountIndex(0);
    selectPet(0);
    await prefs.clear();
    printSharedPreferences();
    pets = [defaultPet];
    print(pets);
    setNeedsToEnterName(false);
    notifyListeners();
  }
  
void printSharedPreferences() {
  print("📂 Checking SharedPreferences Content...");

  // ✅ Manually check and print each known key
  if (prefs.containsKey("name")) {
    print("🔹 Name: ${prefs.getString("name")}");
  } else {
    print("⚠️ Name key not found in SharedPreferences.");
  }

  if (prefs.containsKey("pets")) {
    print("🔹 Pets: ${prefs.getString("pets")}");
  } else {
    print("⚠️ Pets key not found in SharedPreferences.");
  }

  // ✅ If you store additional keys, add them here
  print("✅ Finished checking SharedPreferences.");
}



// Call this function inside notifyListeners() or anywhere in the UI where you want to debug
  Future<void> fetchBarcodeData(String barcode) async {
    final url = 'https://world.openpetfoodfacts.org/api/v3/product/$barcode.json';

    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('foods')
        .doc(barcode)
        .get();

      if (doc.exists) {
        print("✅ Found in Firestore");
        scannedFoodData = doc.data() as Map<String, dynamic>;// Get first matching document
        scannedFoodData["barcode"] = barcode;
        barcodeNotFound = false;
        return;
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print("Full API Response: $data"); // Debugging

        if (data['result']['id'] == "product_found") { // ✅ New v3 API response check
          final product = data['product'];
          String brandName = product.containsKey('brands') ? product['brands'] : "Unknown Brand";
          String productName = product.containsKey('product_name') ? product['product_name'] : "Unknown Product";
          
          String nutritionDataPer = product['nutrition_data_per'] ?? "Unknown"; // "100g" or "serving"
          String servingSizeStr = product['serving_size'] ?? "Unknown";
          double? servingSizeGrams = _extractServingSize(servingSizeStr);

          if (product.containsKey('nutriments')) { // ✅ Ensure nutriments exist
            final nutriments = product['nutriments'] as Map<String, dynamic>;
            Map<String, double> extractedNutrients = {};
            
            nutriments.forEach((key, value) {
              if (value is num){
                String? mappedKey = apiToAppNutrientMap[key];
                if (mappedKey == null && key.endsWith("_100g")) {
                  String base = key.substring(0, key.length - 5);
                  mappedKey = apiToAppNutrientMap[base];
                }
                if (mappedKey != null) {
                  String baseKey = key.endsWith("_100g")
                      ? key.substring(0, key.length - 5)
                      : key;
                  double? bestVal = _pickBestPer100gValue(baseKey, nutriments);
                  
                  if (bestVal != null) {
                    // Now handle the difference if "nutritionDataPer" == "serving"
                    double finalVal;
                    if (nutritionDataPer == "serving"
                        && servingSizeGrams != null
                        && servingSizeGrams > 0) {
                      // Convert from per serving to per 100g
                      finalVal = (bestVal / servingSizeGrams) * 100;
                    } else {
                      // If "100g" or unknown, just store bestVal
                      finalVal = bestVal;
                    }

                    // Store in the extractedNutrients map
                    extractedNutrients[mappedKey] = finalVal;
                  }
                }
              }
            });

            if (extractedNutrients.isEmpty && product.containsKey('nutriments_estimated')) {
              final nutrimentsEstimated = product['nutriments_estimated'] as Map<String, dynamic>;

              nutrimentsEstimated.forEach((key, dynamic value) {
                if (value is num) {  // Ensure it's a number before adding
                  String? mappedKey = apiToAppNutrientMap[key];
                  if (mappedKey == null && key.endsWith("_100g")) {
                    String base = key.substring(0, key.length - 5);
                    mappedKey = apiToAppNutrientMap[base];
                  }
                  if (mappedKey != null) {
                    String baseKey = key.endsWith("_100g")
                        ? key.substring(0, key.length - 5)
                        : key;
                    double? bestVal = _pickBestPer100gValue(baseKey, nutrimentsEstimated);
                    if (bestVal != null) {
                      double finalVal;
                      if (nutritionDataPer == "serving"
                          && servingSizeGrams != null
                          && servingSizeGrams > 0) {
                        finalVal = (bestVal / servingSizeGrams) * 100;
                      } else {
                        finalVal = bestVal;
                      }
                      extractedNutrients[mappedKey] = finalVal;
                    }
                  }
                }
              });
            }

            scannedFoodData = {
              "productName": productName,
              "brandName": brandName,
              "nutritionalInfo": extractedNutrients,
              "barcode": barcode,
            };
            barcodeNotFound = extractedNutrients.isEmpty;
          } else {
            print("Error: 'nutriments' missing from product data.");
            barcodeNotFound = true;
            scannedFoodData.clear();
          }
        }
        else {
          print("Error: Product not found.");
          barcodeNotFound = true;
          scannedFoodData.clear();
        }
      } else {
        print("HTTP Error: ${response.statusCode}");
        barcodeNotFound = true;
        scannedFoodData.clear();
      }
    } catch (error) {
      print("Exception: $error");
      barcodeNotFound = true;
      scannedFoodData.clear();
    }

    notifyListeners(); // Update UI
  }

  double? _extractServingSize(String servingSizeStr) {
    if (servingSizeStr.toLowerCase().contains("g")) {
      return double.tryParse(servingSizeStr.replaceAll(RegExp(r'[^0-9.]'), ''));
    } else if (servingSizeStr.toLowerCase().contains("oz")) {
      return double.tryParse(servingSizeStr.replaceAll(RegExp(r'[^0-9.]'), ''))! * 28.3495;
    }
    return null; // Return null if we can't extract a valid serving size
  }

  double? _pickBestPer100gValue(String key, Map<String, dynamic> nutriments){
    final rawVal = nutriments[key];
    final per100gVal = nutriments["${key}_100g"];

    double? rawDouble = (rawVal is num) ? rawVal.toDouble() : null;
    double? p100gDouble = (per100gVal is num) ? per100gVal.toDouble() : null;

    if (rawDouble == null && p100gDouble == null) return null;
    if (rawDouble == null) return p100gDouble;
    if (p100gDouble == null) return rawDouble;

    bool isCalories = key.contains("energy-kcal");

    double lowerBound = isCalories ? 50 : 1;   
    double upperBound = isCalories ? 1500 : 100;

    bool rawInRange = (rawDouble >= lowerBound && rawDouble <= upperBound);
    bool p100gInRange = (p100gDouble >= lowerBound && p100gDouble <= upperBound);

    if (rawInRange && !p100gInRange) {
      return rawDouble;
    }
    else if (!rawInRange && p100gInRange) {
      return p100gDouble;
    }

    return p100gDouble;
  }

  Future<Map<String, dynamic>?> getFoodIntakeFromBarcode(String barcode, String unit, double amount) async {
    Map<String, dynamic>? finalData;
    bool isFavorite = selectedPet.favoriteFoods!
      .any((food) => food["barcode"] == barcode);
    if (!isFavorite){
      await fetchBarcodeData(barcode);
    }
    else{
      final foundFood = selectedPet.favoriteFoods!.firstWhere(
        (food) => food["barcode"] == barcode,
        orElse: () => <String, dynamic>{}, // empty map
      );

      // 2) Make a defensive copy so we don't mutate the favorite's data
      scannedFoodData = Map<String, dynamic>.from(foundFood);
    }

    if (barcodeNotFound == true){
      return null;
    }
    else if (scannedFoodData.isNotEmpty){
      double conversionRate = 1;
      if (unit == "Cups"){
        conversionRate = 108;
        if (scannedFoodData.containsKey("cupToGramConversion") 
          && scannedFoodData["cupToGramConversion"] is num 
          && scannedFoodData["cupToGramConversion"] > 0){
            conversionRate = scannedFoodData["cupToGramConversion"];
        }
      }
      else if (unit == "Ounces"){
        conversionRate = 28.3495;
          if (scannedFoodData.containsKey("ozToGramConversion") 
          && scannedFoodData["ozToGramConversion"] is num 
          && scannedFoodData["ozToGramConversion"] > 0){
            conversionRate = scannedFoodData["ozToGramConversion"];
          }
      }
      else if (unit == "Grams"){
        conversionRate = 1;
      }
    
      if (scannedFoodData['nutritionalInfo'] != null && scannedFoodData['nutritionalInfo'].isNotEmpty){
        Map<String, double> newNutrients = {};

          scannedFoodData['nutritionalInfo'].forEach((key, value) {
            newNutrients[key] = (value * amount * conversionRate) / 100; // ✅ Scale nutrients based on amount
          });
          
        finalData = {
          "productName": scannedFoodData["productName"],
          "brandName": scannedFoodData["brandName"],
          "nutritionalInfo": newNutrients,
          "amount": amount,
          "barcode":barcode,
        };
      }
      else if (scannedFoodData.containsKey("guaranteedAnalysis") 
      && scannedFoodData["guaranteedAnalysis"] !=null
      && scannedFoodData["guaranteedAnalysis"].isNotEmpty){
        Map<String, double> newNutrients = {};
        double moistureContent = 0;
        if (scannedFoodData['guaranteedAnalysis'].containsKey('Moisture') &&
        scannedFoodData['guaranteedAnalysis']['Moisture'] is num){
          final m = scannedFoodData['guaranteedAnalysis']['Moisture'] as num;
          if (m >= 0 && m <= 100)  moistureContent = m.toDouble();
          double dryMatterPercent = 100 - moistureContent;  // Dry matter is the complement of moisture content
          
          // Adjust the nutrient percentages based on the dry matter percentage
          scannedFoodData['guaranteedAnalysis'].forEach((key, value) {
            double adjustedPercentage = value / dryMatterPercent * 100;  // Adjust nutrient based on dry matter
            newNutrients[key] = (adjustedPercentage * amount * conversionRate) / 100;  // Calculate actual grams for the given amount
          });
        }
        else{
          scannedFoodData['guaranteedAnalysis'].forEach((key, value) {
            newNutrients[key] = (value * amount * conversionRate) / 100;  // Scale nutrients based on amount
          });
        }
        if (scannedFoodData.containsKey('kcalPer100g') 
        && scannedFoodData['kcalPer100g'] is num) {
          final kcalPer100g = (scannedFoodData['kcalPer100g'] as num).toDouble();
          newNutrients['Calories'] =
              (kcalPer100g * amount * conversionRate) / 100;
        }
        finalData = {
          "productName": scannedFoodData["productName"],
          "brandName": scannedFoodData["brandName"],
          "nutritionalInfo": newNutrients,
          "amount": amount,
          "barcode":barcode,
        };
      }
    }
    return finalData;
  }

  Future<void> writeFoodDatabase(String barcode, Map<String, dynamic> food) async {
    try {
      await FirebaseFirestore.instance
          .collection('foods')
          .doc(barcode) // Store under barcode
          .set(food, SetOptions(merge: true)); // Merge prevents overwriting existing fields

      print("✅ Food data saved under barcode: $barcode");
    } catch (e) {
      print("❌ Error writing to Firestore: $e");
    }
  }
}