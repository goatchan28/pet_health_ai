import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_health_ai/main.dart';
import 'package:provider/provider.dart';
import 'package:pet_health_ai/models/app_state.dart';
import 'package:pet_health_ai/models/pet.dart';
import 'package:pet_health_ai/extras/settings_page.dart';

void _showOfflineMsg(BuildContext ctx) =>
  ScaffoldMessenger.of(ctx).showSnackBar(
    const SnackBar(
      content: Text('Connect to the internet to make changes.'),
    ),
  );


class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    final online = context.read<ConnectivityService>().isOnline;
    final bool showPhoto = online && appState.profileImageUrl != null;
    final double avatarR = (MediaQuery.sizeOf(context).width * 0.12).clamp(36.0, 64.0);
    final ts = MediaQuery.textScalerOf(context);
    final double w = (MediaQuery.sizeOf(context).width * 0.18)    // 18 % of width
                    .clamp(48.0, 90.0);   

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
            children: [
              Center(
                child: Column(
                  children: [
                    SizedBox(height: avatarR),
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: (MediaQuery.sizeOf(context).width * 0.12).clamp(36.0, 64.0),
                          backgroundColor: Colors.green,
                          foregroundImage: showPhoto
                              ? NetworkImage(appState.profileImageUrl!)
                              : null,
                          child: showPhoto 
                            ? null  
                            : Text(
                              appState.name.isNotEmpty ? appState.name[0].toUpperCase() : "?",
                              style: const TextStyle(fontSize: 30, color: Colors.white),
                            ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () async {
                              if (!context.read<ConnectivityService>().isOnline) {
                                _showOfflineMsg(context);
                                return;
                              }
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
                    const SizedBox(height: 8),
                    Text(
                      appState.name,
                      style: TextStyle(fontSize: ts.scale(24).clamp(16.0, 30.0), fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Member Since: ${appState.memberSince ?? "Unknown"}',
                      style: TextStyle(fontSize: ts.scale(14), color: Colors.grey),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  SizedBox(
                    width: w,
                    height: w,
                    child: LogoIcon()
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Your Pets',
                    style: TextStyle(fontSize: ts.scale(20).clamp(14.0, 24.0), fontWeight: FontWeight.bold),
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
                onTap: online ? () {
                  if (!context.read<ConnectivityService>().isOnline) {
                    _showOfflineMsg(context);              // just show the toast
                    return;                                // ← stop here when offline
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                } : () => _showOfflineMsg(context),
              ),
              ElevatedButton(
                onPressed: () {
                  final onlineNow = context.read<ConnectivityService>().isOnline;
                  if (!onlineNow) {
                    _showOfflineMsg(context);
                    return;
                  }
                  appState.signOut();
                }, 
                child: Text('Log Out', style: TextStyle(fontSize: 16))
              )
            ],
        ),
      ),
    );
  }
}

Future<void> showAddPetDialog(BuildContext context, {bool firstTime = false}) async {
  var appState = context.read<MyAppState>();
  final online   = context.read<ConnectivityService>().isOnline;
  if (!online) {                 // early exit
    _showOfflineMsg(context);
    return;
  }

  int mode = 0;

  String desiredPetID = "";
  TextEditingController petIDController = TextEditingController();

  Map<String, TextEditingController> controllers = {
    "Name": TextEditingController(),
    "Breed": TextEditingController(),
    "Weight (kg)": TextEditingController(),
    "Age (months)": TextEditingController(),
    "Neutered/Spayed (true/false)": TextEditingController(),
  };

  Map<String, String?> errors = {
    "Name": null,
    "Breed": null,
    "Weight (kg)": null,
    "Age (months)": null,
    "Neutered/Spayed (true/false)": null,
  };

  Future<void> validateAndSubmit() async {
    errors.updateAll((key, value) => null); // Reset errors

    String name = controllers["Name"]!.text.trim();
    String breed = controllers["Breed"]!.text.trim();
    double? weight = double.tryParse(controllers["Weight (kg)"]!.text); // Nullable double
    double? age = double.tryParse(controllers["Age (months)"]!.text);   // Nullable double
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

    await appState.run(
      context,                                   // use the long-lived page ctx
      () async {
        await appState.addPetManually(
          name: name,
          breed: breed,
          weight: weight!,
          age: age!,
          neuteredSpayed: neuteredSpayed!,
        );
        // if you want the spinner to be visible for at least
        // one frame, you can add a micro delay (optional):
        // await Future.delayed(const Duration(milliseconds: 150));
      },
      successMsg: '$name added sucessfully!',                   // or any custom text
    );
    final Pet newPet = appState.pets.last;
    if (!context.mounted) return;
    Navigator.pop(context);
    await showPetSummaryDialog(context, newPet);
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
                  if (firstTime)                 // ← show once
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        "👋  Welcome!  You can attach an **existing pet** with its ID, "
                        "or enter your pet’s details manually. "
                        "You can always add pets later from the Profile page.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  if (firstTime) const Divider(),
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
                          height: (MediaQuery.sizeOf(context).height * 0.50).clamp(280.0, 500.0),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                ...controllers.keys.map((key) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5),
                                  child: TextField(
                                    controller: controllers[key],
                                    keyboardType: (key.contains("Weight (kg)") || key.contains("Age (months)"))
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
                onPressed: () async {
                  if (!context.read<ConnectivityService>().isOnline) {
                    _showOfflineMsg(context);
                    return;
                  }
                  if (mode==0){
                    desiredPetID = petIDController.text.trim();
                    if (desiredPetID.isEmpty){
                      print("Please enter a Pet ID");
                      return;
                    }
                    await appState.run(
                      context,
                      () async => await appState.addPetID(desiredPetID),
                    );
                    final Pet linked = appState.pets.firstWhere((p) => p.id == desiredPetID);
                    showGlobalSnackBar('${linked.name} successfully linked!',
                      bg: Colors.green);

                    final doc = await FirebaseFirestore.instance
                        .collection('pets')
                        .doc(desiredPetID)
                        .get();

                    final List<String> ownerUids =
                        List<String>.from(doc['ownerUID'] ?? const []);

                    // remove *this* user’s UID before displaying
                    ownerUids.remove(FirebaseAuth.instance.currentUser!.uid);
                    final otherOwnerNames = await appState.fetchNames(ownerUids);
                    if (!context.mounted) return;
                    await showPetSummaryDialog(context, linked, otherOwners: otherOwnerNames);
                    if (!context.mounted) return;
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

      await appState.run(
        context,                                   // use the long-lived page ctx
        () async {
          await appState.updatePetProfile(
            originalPet: widget.pet,
            name: nameCtrl.text.trim(),
            breed: breedCtrl.text.trim(),
            weight: double.tryParse(weightCtrl.text.trim()) ?? widget.pet.weight,
            age: double.tryParse(ageCtrl.text.trim()) ?? widget.pet.age,
            neuteredSpayed: neutered,
            imageFile: newImageFile,
          );
          // if you want the spinner to be visible for at least
          // one frame, you can add a micro delay (optional):
          // await Future.delayed(const Duration(milliseconds: 150));
        },
        successMsg: '${nameCtrl.text.trim()}\'s information updated successfully!',                   // or any custom text
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      print("❌ Failed to save changes: $e");
      if (mounted) setState(() => uploading = false);
      // You can also show a SnackBar or dialog here
    }
  }

  Future<void> _removePet() async {
    final online = context.read<ConnectivityService>().isOnline;
    if (!online) {
      _showOfflineMsg(context);
      return;
    }
    final appState = context.read<MyAppState>();
    
    await appState.run(
        context,                                   // use the long-lived page ctx
        () async {
          await appState.removePet(widget.pet);
          // if you want the spinner to be visible for at least
          // one frame, you can add a micro delay (optional):
          // await Future.delayed(const Duration(milliseconds: 150));
        },
        successMsg: '${nameCtrl.text.trim()} removed successfully',                   // or any custom text
      );
    if (!mounted) return;
    Navigator.of(context).pop();
  }


  @override
  Widget build(BuildContext context) {
    final online = context.read<ConnectivityService>().isOnline;
    final bool showNetImage = online && widget.pet.imageUrl != null;
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
                  radius: (MediaQuery.sizeOf(context).width * 0.12).clamp(32.0, 56.0),
                  backgroundImage: newImageFile != null
                      ? FileImage(newImageFile!)
                      : showNetImage
                          ? NetworkImage(widget.pet.imageUrl!)
                          : const AssetImage("assets/images/sigmalogo.png") as ImageProvider,
                ),
              ),
            TextButton.icon(
              icon: const Icon(Icons.image),
              label: const Text("Change Pet Picture"),
              onPressed: () async {
                final onlineNow = context.read<ConnectivityService>().isOnline;
                if (!onlineNow) { _showOfflineMsg(context); return; }
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
            TextButton.icon(
              onPressed: _removePet,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text("Remove Pet", style: TextStyle(color: Colors.red)),
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
          onPressed: online ? _saveChanges : () => _showOfflineMsg(context),
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
    final bool online      = context.watch<ConnectivityService>().isOnline;
    final bool hasPhotoUrl = pet.imageUrl != null && online;
    final ts = MediaQuery.textScalerOf(context);


    return GestureDetector(
      onTap: onTap, // This will handle taps to show more details
      child: Container(
        padding: EdgeInsets.all(12),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: (MediaQuery.sizeOf(context).width * 0.10).clamp(24.0, 40.0),
              backgroundColor: Colors.grey[300],
              foregroundImage: hasPhotoUrl ? NetworkImage(pet.imageUrl!) : null,
              child: !hasPhotoUrl
                  ? Image.asset(
                      'assets/images/sigmalogo.png',
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${pet.name} - ${pet.breed}',
                    style: TextStyle(fontSize: ts.scale(16).clamp(12.0, 20.0), fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Weight (kg): ${pet.weight}, Age: ${pet.age} months',
                    style: TextStyle(fontSize: ts.scale(13), color: Colors.grey[700]),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pet ID: ${pet.id}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, size: 16, color: Colors.grey[600]),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: pet.id));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Pet ID copied to clipboard')),
                          );
                        },
                        tooltip: 'Copy Pet ID',
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showPetSummaryDialog(
  BuildContext ctx,
  Pet pet, {
  List<String>? otherOwners = const [],
}) async {
  final ts = MediaQuery.textScalerOf(ctx);

  // pull the three core macros
  final nr = pet.nutritionalRequirements;
  final kcal  = pet.calorieRequirement.round();
  final pro   = nr['Crude Protein']!.round();
  final fat   = nr['Crude Fat']!.round();
  final carbs = nr['Carbohydrates']!.round();

  await showDialog(
    context: ctx,
    builder: (dialogCtx) => AlertDialog(
      title: Text('🐾  ${pet.name} added!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily targets', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          _macroRow('Calories', '$kcal kcal', ts),
          _macroRow('Protein',  '$pro g',  ts),
          _macroRow('Fat',      '$fat g',  ts),
          _macroRow('Carbs',    '$carbs g',ts),
          if (otherOwners != null && otherOwners.isNotEmpty) ...[
            SizedBox(height: 16),
            Text('Also shared with', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            ...otherOwners.map((o) => Text('• $o')),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogCtx),
          child: const Text('Got it'),
        )
      ],
    ),
  );
}

Widget _macroRow(String label, String value, TextScaler ts) => Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(label, style: TextStyle(fontSize: ts.scale(14))),
    Text(value, style: TextStyle(fontSize: ts.scale(14), fontWeight: FontWeight.w600)),
  ],
);
