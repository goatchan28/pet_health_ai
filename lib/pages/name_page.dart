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

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _submitName() async {
    final online = context.read<ConnectivityService>().isOnline;
    if (!online) {
      _showOfflineMsg(context);
      return;
    }
    final appState = context.read<MyAppState>();
    final name = nameController.text.trim();
    if (name.isEmpty) {
      showGlobalSnackBar('Please enter a name', bg: Colors.red);
      return;
    }

    await appState.run(
      context,
      () async {
        await appState.setName(name);  
        if (!mounted) return;              
        await showAddPetDialog(context, firstTime: true);                
        appState.setNeedsToEnterName(false);
      },
      successMsg: 'Nice to meet you, $name!'
    );
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
              onPressed: (!isOnline) ? null : _submitName,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}