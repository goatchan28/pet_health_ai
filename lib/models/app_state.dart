import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'pet.dart';
import 'dart:convert';
import "package:shared_preferences/shared_preferences.dart";

class MyAppState extends ChangeNotifier {
  int currentPageIndex = 2;
  int enterAccountIndex = 0;
  int petIndex = 0;
  Map<String, double> scannedFoodData = {};
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

  final List<Map<String, dynamic>> favorites = [
      {
        "imageUrl": "https://image.chewy.com/is/image/catalog/48856_MAIN._AC_SL1200_V1723228820_.jpg",
        "name": "Adult Sensitive Stomach Dog Food",
        "brand": "Hill’s Science Diet",
        "rating": "Good",
        "ratingColor": Colors.green,
      },
    ];

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
          "nutritionalIntake": Pet.initializeIntake(), // Reset all nutrients to zero
        });
      }

      if (pets.isNotEmpty) {
        for (Pet pet in pets) {
          pet.calorieIntake = 0;
          pet.nutritionalIntake = Pet.initializeIntake();
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

    if (savedName != name) { // Only update if different
      name = savedName;
      notifyListeners();
    }

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
    if (name != newName) {
      name = newName;

      await prefs.setString("name", name);

      // 🔥 Update FirebaseAuth display name if logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateProfile(displayName: name);
      }
      notifyListeners();
    }
  }



  void changeIndex(int idx){
    currentPageIndex = idx;
    notifyListeners();
  }

  void changeEnterAccountIndex(int idx){
    enterAccountIndex = idx;
    notifyListeners();
  }

  void addFavorite(Map<String, dynamic> item) {
    favorites.add(item);
    notifyListeners();
  }

  void removeFavorite(int index) {
    if (index >= 0 && index < favorites.length) {
      favorites.removeAt(index);
      notifyListeners();
    }
  }

  Future<void> addPet({
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
          'ownerUID': uid, 
          'calorieIntake':0,
          'nutritionalIntake': Pet.initializeIntake(),
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

  void removePet(int index) {
    if (index >= 0 && index < favorites.length) {
      pets.removeAt(index);
      notifyListeners();
    }
  }

  void selectPet(int index) {
    if (index >= 0 && index < pets.length) {
      petIndex = index;
      notifyListeners();
    }
  }

  void updatePetIntake(Pet pet, Map<String, double> updatedValues) {
    pet.addFood(updatedValues, this);
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
            .where("ownerUID", isEqualTo: uid)  // Filter by user ID if needed
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
    final url = 'https://world.openfoodfacts.org/api/v3/product/$barcode.json';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print("Full API Response: $data"); // Debugging

        if (data['result']['id'] == "product_found") { // ✅ New v3 API response check
          final product = data['product'];

          if (product.containsKey('nutriments')) { // ✅ Ensure nutriments exist
            final nutriments = product['nutriments'] as Map<String, dynamic>;

            Map<String, double> extractedNutrients = {};
            
            nutriments.forEach((key, value) {
              if (value is num) {  // Ensure it's a number before adding
                String? mappedKey = apiToAppNutrientMap[key];
                if (mappedKey != null) {
                  extractedNutrients[mappedKey] = value.toDouble();
                }
              }
            });

            scannedFoodData = extractedNutrients;
            barcodeNotFound = extractedNutrients.isEmpty;
          } else {
            print("Error: 'nutriments' missing from product data.");
            barcodeNotFound = true;
            scannedFoodData.clear();
          }
        } else {
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
}