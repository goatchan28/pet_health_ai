import 'package:flutter/material.dart';
import 'package:pet_health_ai/main.dart';
import 'package:pet_health_ai/models/app_state.dart';
import 'package:provider/provider.dart';

const kDisclaimer = '''
Furiva is in limited beta testing and provides general wellness tracking for pets.
It is **not** a substitute for veterinary care or professional medical advice.
Always consult a licensed veterinarian before making decisions about your pet's health.
''';


class SettingsPage extends StatelessWidget{
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    final isOnline = context.watch<ConnectivityService>().isOnline;
    final ts = MediaQuery.textScalerOf(context); 
    final double baseFs = ts.scale(16).clamp(12.0, 22.0);

    void offlineToast() => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connect to the internet to make changes.')),
    );
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings',
          style: TextStyle(fontSize: ts.scale(20).clamp(14.0, 26.0)),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.person, size: baseFs*1.3,),
            title: const Text('Change Display Name'),
            enabled: isOnline,
            onTap: () {
              if (!isOnline) {
                offlineToast();
                return;
              }
              showDialog(
                context: context,
                builder: (_) => _ChangeNameDialog(outerCtx: context, currentName: appState.name),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.info_outline, size: baseFs * 1.3),
            title: const Text('Disclaimer'),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('Disclaimer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: ts.scale(24))),
                  content: Text(
                    kDisclaimer,
                    style: TextStyle(fontSize: ts.scale(18)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            enabled: isOnline,
            onTap: () async {
              if (!isOnline) {
                offlineToast();
                return;
              }
              appState.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }
}

class _ChangeNameDialog extends StatefulWidget {
  final BuildContext outerCtx;
  final String currentName;

  const _ChangeNameDialog({required this.currentName, required this.outerCtx});

  @override
  State<_ChangeNameDialog> createState() => _ChangeNameDialogState();
}

class _ChangeNameDialogState extends State<_ChangeNameDialog> {
  late TextEditingController _controller;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.read<MyAppState>();
    final isOnline = context.watch<ConnectivityService>().isOnline;
    final ts = MediaQuery.textScalerOf(context);

    void offlineToast() => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connect to the internet to make changes.')),
    );

    return AlertDialog(
      title: Text('Change Display Name', style: TextStyle(fontSize: ts.scale(18).clamp(14.0 , 24.0)),),
      content: uploading
        ? const SizedBox(
            height: 90,
            child: Center(child: CircularProgressIndicator()),
          )
        : TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'New Name'),
            style: TextStyle(fontSize: ts.scale(16).clamp(12.0, 20.0)),
          ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isOnline ? () async {
            final newName = _controller.text.trim();
            if (newName.isEmpty) return;
            setState(() => uploading = true);
            appState.run(
              widget.outerCtx,
              () async {
              await appState.setName(newName);
              },
              successMsg: 'Name has been changed to $newName!'
            );
            if (!context.mounted) return;
            Navigator.pop(context);
          } : offlineToast, 
          child: const Text('Save'),
        ),
      ],
    );
  }
}