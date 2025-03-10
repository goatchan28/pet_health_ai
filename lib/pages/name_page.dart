import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pet_health_ai/models/app_state.dart';
import 'package:pet_health_ai/pages/profile_page.dart';
import 'package:provider/provider.dart';

class EnterNamePage extends StatefulWidget {
  const EnterNamePage({super.key});

  @override
  State<EnterNamePage> createState() => _EnterNamePageState();
}

class _EnterNamePageState extends State<EnterNamePage> {
  final nameController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _submitName() async {
    var appState = context.read<MyAppState>();
    if (nameController.text.isNotEmpty) {
      await setName();
      await fetchAndSetName(context);
      await showAddPetDialog(context);
      appState.setNeedsToEnterName(false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill out both fields")),
      );
    }
  }

  Future<void> setName() async {
    try{
      final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updateProfile(displayName: nameController.text);
        }
    } catch (e){
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Enter Your Name")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Name"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: (){_submitName();},
              child: Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> fetchAndSetName(BuildContext context) async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      var appState = context.read<MyAppState>();
      appState.name = FirebaseAuth.instance.currentUser!.displayName!;
      print("Fetched name: ${appState.name}");
      }
    }
 catch (e) {
    print("Error fetching name: $e");
  }
}
