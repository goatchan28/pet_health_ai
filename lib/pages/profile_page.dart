import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:pet_health_ai/models/app_state.dart';
import 'package:pet_health_ai/models/pet.dart';
import 'package:pet_health_ai/extras/settings_page.dart';

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
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.green,
                          foregroundImage: (appState.profileImageUrl != null)
                              ? NetworkImage(appState.profileImageUrl!)
                              : null,
                          child: Text(
                            appState.name.isNotEmpty ? appState.name[0].toUpperCase() : "?",
                            style: const TextStyle(fontSize: 30, color: Colors.white),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(source: ImageSource.gallery);
                              if (picked == null) return;

                              final croppedFile = await ImageCropper().cropImage(
                                sourcePath: picked.path,
                                compressFormat: ImageCompressFormat.jpg,
                                compressQuality: 90,
                                uiSettings: [
                                  AndroidUiSettings(
                                    toolbarTitle: 'Crop Profile Picture',
                                    toolbarColor: Colors.red,
                                    hideBottomControls: true,
                                    lockAspectRatio: true,
                                    cropStyle: CropStyle.circle,
                                    aspectRatioPresets: [CropAspectRatioPreset.square],
                                  ),
                                  IOSUiSettings(
                                    title: 'Crop Profile Picture',
                                    aspectRatioLockEnabled: true,
                                    cropStyle: CropStyle.circle,
                                    aspectRatioPresets: [CropAspectRatioPreset.square],
                                  ),
                                ],
                              );

                              if (croppedFile != null) {
                                await appState.updateProfileImage(File(croppedFile.path));
                              }
                            },

                            child: const CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.add, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      appState.name,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Member Since: ${appState.memberSince ?? "Unknown"}',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Image.asset("assets/images/sigmalogo.png", width: 75, height: 75,fit: BoxFit.contain),
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
                        onTap: (){
                          showDialog(
                            context: context,
                            builder: (_) => EditPetDialog(pet:pet),
                          );
                        },
                        ),
                      SizedBox(height:5),
                    ],
                  );
                }).toList(),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => showAddPetDialog(context),
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
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
              ),
              ElevatedButton(
                onPressed: () {appState.signOut();}, 
                child: Text('Log Out', style: TextStyle(fontSize: 16))
              )
            ],
        ),
      ),
    );
  }
}

Future<void> showAddPetDialog(BuildContext context) async {
  var appState = context.read<MyAppState>();

  int mode = 0;

  String desiredPetID = "";
  TextEditingController petIDController = TextEditingController();

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

    appState.addPetManually(
      name: name,
      breed: breed,
      weight: weight!,
      age: age!,
      neuteredSpayed: neuteredSpayed!,
    );
    Navigator.pop(context);
  }

  await showDialog(
    context: context, 
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState){
          return AlertDialog(
            title: Text("Add Pet"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => mode = 0),
                        child: Text(
                          "Barcode Scan",
                          style: TextStyle(
                            fontWeight: mode == 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => mode = 1),
                        child: Text(
                          "Manual Entry",
                          style: TextStyle(
                            fontWeight: mode == 1 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),

                  Divider(), 

                  if (mode == 0)
                  Column(
                    children: [
                      TextField(
                        controller: petIDController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: "Pet ID",
                        ),
                      )
                    ],
                  )
                  else if (mode == 1)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Enter Your Dog's Information", style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(
                          height: 400,
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                ...controllers.keys.map((key) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5),
                                  child: TextField(
                                    controller: controllers[key],
                                    keyboardType: (key.contains("Weight") || key.contains("Age"))
                                        ? TextInputType.number
                                        : TextInputType.text,
                                    decoration: InputDecoration(
                                      labelText: key,
                                      errorText: errors[key],
                                    ),
                                  ),
                                );
                              }),
                            ]
                          )
                        )
                        )
                      ],
                    ),
                  ],
                )
              ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); 
                },
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (mode==0){
                    desiredPetID = petIDController.text.trim();
                    if (desiredPetID.isEmpty){
                      print("Please enter a Pet ID");
                      return;
                    }
                    appState.addPetID(desiredPetID);
                    Navigator.pop(context);
                  }
                  if (mode==1){
                    validateAndSubmit();
                  }
                },
                child: Text("Enter"),
              )  
            ],
          );
        },
      );
    },
  );
} 

class EditPetDialog extends StatefulWidget{
  final Pet pet;

  const EditPetDialog({super.key, required this.pet});
  @override
  State<EditPetDialog> createState() => _EditPetDialogState();
}

class _EditPetDialogState extends State<EditPetDialog> {
  late TextEditingController nameCtrl;
  late TextEditingController breedCtrl;
  late TextEditingController weightCtrl;
  late TextEditingController ageCtrl;
  late bool neutered;
  File? newImageFile;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.pet.name);
    breedCtrl = TextEditingController(text: widget.pet.breed);
    weightCtrl = TextEditingController(text: widget.pet.weight.toString());
    ageCtrl = TextEditingController(text: widget.pet.age.toString());
    neutered = widget.pet.neutered_spayed;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    breedCtrl.dispose();
    weightCtrl.dispose();
    ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    try {
      final appState = context.read<MyAppState>();

      if (mounted) setState(() => uploading = true);

      await appState.updatePetProfile(
        originalPet: widget.pet,
        name: nameCtrl.text.trim(),
        breed: breedCtrl.text.trim(),
        weight: double.tryParse(weightCtrl.text.trim()) ?? widget.pet.weight,
        age: double.tryParse(ageCtrl.text.trim()) ?? widget.pet.age,
        neuteredSpayed: neutered,
        imageFile: newImageFile,
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      print("❌ Failed to save changes: $e");
      if (mounted) setState(() => uploading = false);
      // You can also show a SnackBar or dialog here
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Pet'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: breedCtrl, decoration: const InputDecoration(labelText: 'Breed')),
            TextField(
              controller: weightCtrl,
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: ageCtrl,
              decoration: const InputDecoration(labelText: 'Age (months)'),
              keyboardType: TextInputType.number,
            ),
            Row(
              children: [
                const Text('Neutered/Spayed'),
                Switch(
                  value: neutered,
                  onChanged: (val) => setState(() => neutered = val),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.pet.imageUrl != null || newImageFile != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: newImageFile != null
                      ? FileImage(newImageFile!)
                      : widget.pet.imageUrl != null
                          ? NetworkImage(widget.pet.imageUrl!)
                          : const AssetImage("assets/images/sigmalogo.png"),
                ),
              ),
            TextButton.icon(
              icon: const Icon(Icons.image),
              label: const Text("Change Profile Picture"),
              onPressed: () async {
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.gallery);
                if (picked == null) return;

                final cropped = await ImageCropper().cropImage(
                  sourcePath: picked.path,
                  aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
                  compressFormat: ImageCompressFormat.jpg,
                  compressQuality: 90,
                  uiSettings: [
                    AndroidUiSettings(toolbarTitle: "Crop Pet Image", lockAspectRatio: true),
                    IOSUiSettings(title: "Crop Pet Image"),
                  ],
                );
                
                if (cropped != null) {
                  setState(() => newImageFile = File(cropped.path));
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('Save'),
        ),
      ],
    );
  }


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
    final bool showImage = pet.imageUrl != null;

    return GestureDetector(
      onTap: onTap, // This will handle taps to show more details
      child: Container(
        padding: EdgeInsets.all(12),
        width: 369,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[300],
              foregroundImage: showImage
                  ? NetworkImage(pet.imageUrl!)
                  : null,
              child: Center(
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: Image.asset("assets/images/sigmalogo.png", fit: BoxFit.contain),
                ),
              )
            ),
            const SizedBox(width: 12),
            Expanded(
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
          ],
        ),
      ),
    );
  }
}