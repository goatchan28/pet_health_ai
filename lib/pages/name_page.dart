import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pet_health_ai/main.dart';
import 'package:pet_health_ai/models/app_state.dart';
import 'package:pet_health_ai/pages/profile_page.dart';
import 'package:provider/provider.dart';

void _showOfflineMsg(BuildContext ctx) =>
  ScaffoldMessenger.of(ctx).showSnackBar(
    const SnackBar(
      content: Text('Connect to the internet to make changes.'),
    ),
  );

class EnterNamePage extends StatefulWidget {
  const EnterNamePage({super.key});

  @override
  State<EnterNamePage> createState() => _EnterNamePageState();
}

class _EnterNamePageState extends State<EnterNamePage> {
  final nameController = TextEditingController();
  bool _saving = false; 

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _submitName() async {
    final online = context.read<ConnectivityService>().isOnline;
    var appState = context.read<MyAppState>();
    if (!online) {
      _showOfflineMsg(context);
      return;
    }
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please enter a name')));
      return;
    }

    setState(() => _saving = true);                     // lock UI

    try {
      await appState.setName(name);                     // <-- network write
      if (!mounted) return;
      await showAddPetDialog(context);                  // has its own guard
      appState.setNeedsToEnterName(false);
    } on FirebaseException catch (e) {
      // lost connection or other Firebase error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Network error; try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);     // unlock UI
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = context.read<ConnectivityService>().isOnline;
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
              onPressed: (!isOnline || _saving) ? null : _submitName,
              child: _saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}