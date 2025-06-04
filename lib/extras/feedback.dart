import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pet_health_ai/models/app_state.dart';
import 'package:provider/provider.dart';

Future<void> showFeedbackDialog(BuildContext ctx) async {
  final appState = ctx.read<MyAppState>();
  final controller = TextEditingController();
  await showDialog(
    context: ctx,
    builder: (_) => AlertDialog(
      title: const Text('Send feedback'),
      content: TextField(
        controller: controller,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'What’s working well? What can we improve or add? Share your experience!',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(_), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final msg = controller.text.trim();
            if (msg.isEmpty) return;                       // ignore empty
            await appState.run(
              ctx,
              () async {
                // 🔥 1️⃣  Drop it in Firestore so it’s stored immediately …
                await FirebaseFirestore.instance
                    .collection('feedback')
                    .add({
                      'uid'      : FirebaseAuth.instance.currentUser?.uid,
                      'message'  : msg,
                      'platform' : Platform.operatingSystem,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                // 2️⃣ (Optional) also trigger a Cloud Function that
                //    e-mails you – no UI work needed here.
              },
              successMsg: 'Thanks for the feedback!',
            );
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Send'),
        ),
      ],
    ),
  );
}
