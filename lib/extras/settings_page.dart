import 'package:flutter/material.dart';
import 'package:pet_health_ai/main.dart';
import 'package:pet_health_ai/models/app_state.dart';
import 'package:provider/provider.dart';


class SettingsPage extends StatelessWidget{
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    final isOnline = context.watch<ConnectivityService>().isOnline;

    void offlineToast() => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connect to the internet to make changes.')),
    );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
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

    void offlineToast() => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connect to the internet to make changes.')),
    );

    return AlertDialog(
      title: const Text('Change Display Name'),
      content: uploading
        ? const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          )
        : TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'New Name'),
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