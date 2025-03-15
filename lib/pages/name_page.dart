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
      await appState.setName(nameController.text);
      await showAddPetDialog(context);
      appState.setNeedsToEnterName(false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill out both fields")),
      );
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