import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'pet.dart';
import 'dart:convert';

class MyAppState extends ChangeNotifier {
  int currentPageIndex = 2;
  int petIndex = 0;
  Map<String, double> scannedFoodData = {};
  bool barcodeNotFound = false;

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

  final List<Pet> pets = [
    Pet(
      name: "Buddy",
      breed: "Golden Retriever",
      weight: 29, // Rounded from 29.48 kg
      age: 6, 
      neutered_spayed: false,
      nutritionalRequirements: {
        "Crude Protein": 64,
        "Arginine": 1.81,
        "Histidine": 0.68,
        "Isoleucine": 1.35,
        "Leucine": 2.41,
        "Lysine": 2.24,
        "Methionine": 1.18,
        "Methionine-cystine": 2.31,
        "Phenylalanine": 1.60,
        "Phenylalanine-tyrosine": 2.62,
        "Threonine": 1.70,
        "Tryptophan": 0.57,
        "Valine": 1.74,
        "Crude Fat": 20,
        "Linoleic acid": 4.00,
        "Calcium": 1.77,
        "Phosphorus": 1.42,
        "Potassium": 2.13,
        "Sodium": 0.28,
        "Chloride": 0.43,
        "Magnesium": 0.21,
        "Iron": 14.17,
        "Copper": 2.59,
        "Manganese": 1.77,
        "Zinc": 28.34,
        "Iodine": 0.35,
        "Selenium": 0.11,
        "Vitamin A": 1771.38,
        "Vitamin D": 177.14,
        "Vitamin E": 17.71,
        "Thiamine": 0.79,
        "Riboflavin": 1.84,
        "Pantothenic acid": 4.25,
        "Niacin": 4.82,
        "Pyridoxine": 0.54,
        "Folic acid": 0.08,
        "Vitamin B12": 0.01,
        "Choline": 481.81,
      },
      nutritionalIntake: {}, // Will be initialized dynamically in the class
    ),
    Pet(
      name: "Sigma",
      breed: "Alaskan Malamute",
      weight: 36, // Rounded from 36.29 kg
      age: 36,
      neutered_spayed: true,
      nutritionalRequirements: {
        "Crude Protein": 75,
        "Arginine": 2.12,
        "Histidine": 0.79,
        "Isoleucine": 1.57,
        "Leucine": 2.82,
        "Lysine": 2.62,
        "Methionine": 1.37,
        "Methionine-cystine": 2.70,
        "Phenylalanine": 1.87,
        "Phenylalanine-tyrosine": 3.06,
        "Threonine": 1.99,
        "Tryptophan": 0.66,
        "Valine": 2.04,
        "Crude Fat": 23,
        "Linoleic acid": 4.64,
        "Calcium": 2.07,
        "Phosphorus": 1.66,
        "Potassium": 2.48,
        "Sodium": 0.33,
        "Chloride": 0.50,
        "Magnesium": 0.25,
        "Iron": 16.56,
        "Copper": 3.03,
        "Manganese": 2.07,
        "Zinc": 33.12,
        "Iodine": 0.41,
        "Selenium": 0.13,
        "Vitamin A": 2069.88,
        "Vitamin D": 206.99,
        "Vitamin E": 20.70,
        "Thiamine": 0.93,
        "Riboflavin": 2.15,
        "Pantothenic acid": 4.97,
        "Niacin": 5.63,
        "Pyridoxine": 0.63,
        "Folic acid": 0.09,
        "Vitamin B12": 0.01,
        "Choline": 563.01,
      },
      nutritionalIntake: {}, // Will be initialized dynamically in the class
    ),
  ];

  Pet get selectedPet => pets[petIndex];

  void changeIndex(int idx){
    currentPageIndex = idx;
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

  void addPet(Pet pet) {
    pets.add(pet);
    notifyListeners();
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
    pet.addFood(updatedValues);
    scannedFoodData = {}; // Update the pet's intake
    notifyListeners(); // Notify UI about changes
  }

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