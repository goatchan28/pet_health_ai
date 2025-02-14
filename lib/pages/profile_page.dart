import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pet_health_ai/models/app_state.dart';
import 'package:pet_health_ai/models/pet.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
            children: [
              Center(
                child: Column(
                  children: [
                    SizedBox(height: 70),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.green,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Iain Fulnecky',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Member Since: Jan 2025',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Image.asset("assets/sigmalogo.png", width: 75, height: 75,fit: BoxFit.contain),
                  SizedBox(width: 8),
                  Text(
                    'Your Pets',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                children: appState.pets.map((pet) {
                  return Column(
                    children: [
                      PetProfileCard(
                        pet: pet, 
                        onTap: (){},
                        ),
                      SizedBox(height:5),
                    ],
                  );
                }).toList(),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _showAddPetDialog(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('Add Another Pet'),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    'Subscription Plan: Free Plan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(width: 30),
                  Text(
                    'Upgrade to Premium for Exclusive Features',
                    style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                  ),
                ],
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {},
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_upward),
                    SizedBox(width: 8),
                    Text('Upgrade Plan'),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
        ),
      ),
    );
  }
}

void _showAddPetDialog(BuildContext context){
  var appState = context.read<MyAppState>();

  Map<String, TextEditingController> controllers = {
    "Name": TextEditingController(),
    "Breed": TextEditingController(),
    "Weight": TextEditingController(),
    "Age": TextEditingController(),
    "Neutered/Spayed (true/false)": TextEditingController(),
  };

  Map<String, String?> errors = {
    "Name": null,
    "Breed": null,
    "Weight": null,
    "Age": null,
    "Neutered/Spayed (true/false)": null,
  };

  void validateAndSubmit() {
    errors.updateAll((key, value) => null); // Reset errors

    String name = controllers["Name"]!.text.trim();
    String breed = controllers["Breed"]!.text.trim();
    double? weight = double.tryParse(controllers["Weight"]!.text); // Nullable double
    double? age = double.tryParse(controllers["Age"]!.text);   // Nullable double
    String neuteredText = controllers["Neutered/Spayed (true/false)"]!.text.trim().toLowerCase();
    bool? neuteredSpayed = (neuteredText == "true") ? true : (neuteredText == "false") ? false : null;

    bool hasErrors = false;

    if (name.isEmpty) {
      errors["Name"] = "Enter a valid name.";
      hasErrors = true;
    }
    if (breed.isEmpty) {
      errors["Breed"] = "Enter a valid breed.";
      hasErrors = true;
    }
    if (weight == null || weight <= 0) { // Ensure valid weight
      errors["Weight (kg)"] = "Enter a valid weight (kg).";
      hasErrors = true;
    }
    if (age == null || age <= 0) { // Ensure valid age
      errors["Age (months)"] = "Enter a valid age (months).";
      hasErrors = true;
    }
    if (neuteredSpayed == null) { // Ensure valid boolean value
      errors["Neutered/Spayed (true/false)"] = "Enter 'true' or 'false'.";
      hasErrors = true;
    }

    if (hasErrors) {
      (context as Element).markNeedsBuild(); // Refresh UI to show errors
      return;
    }

    // ✅ Now we are sure `weight`, `age`, and `neutered_spayed` are NOT null.
    Pet newPet = Pet(
      name: name,
      breed: breed,
      weight: weight!,  // ✅ Guaranteed to be a `double`
      age: age!,        // ✅ Guaranteed to be a `double`
      neutered_spayed: neuteredSpayed!, // ✅ Guaranteed to be a `bool`
    );

    appState.addPet(newPet);
    Navigator.pop(context);
  }

  showDialog(
    context: context, 
    builder: (context) {
      return AlertDialog(
        title: Text("Add Pet"),
        content: SizedBox(
          width: double.maxFinite,
          height:400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Enter Your Dog's Information", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                height: 350,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: controllers.length,
                  itemBuilder: (context, index) {
                    String key = controllers.keys.elementAt(index);
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: TextField(
                        controller: controllers[key],
                        keyboardType: (key.contains("Weight") || key.contains("Age"))
                            ? TextInputType.number
                            : TextInputType.text,
                        decoration: InputDecoration(
                          labelText: key,
                          errorText: errors[key], // Shows error message if invalid
                        ),
                      )
                    );
                  }
                )
              )
            ],
          )
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              validateAndSubmit();
            },
            child: Text("Enter"),
          )  
        ],
      );
    },
  );
} 

class PetProfileCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onTap;

  const PetProfileCard({ 
    required this.pet,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // This will handle taps to show more details
      child: Container(
        padding: EdgeInsets.all(12),
        width: 369,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${pet.name} - ${pet.breed}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Weight: ${pet.weight}, Age: ${pet.age} months',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}