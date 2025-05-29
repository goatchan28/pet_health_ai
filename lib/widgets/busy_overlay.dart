import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';

class BusyOverlay extends StatelessWidget {
  final Widget child;
  const BusyOverlay({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<MyAppState>().isBusy;
    return Stack(
      children: [
        child,
        if (busy) ...[
          const Positioned.fill(
            child: ModalBarrier(color: Colors.black45, dismissible: false),
          ),
          const Center(child: CircularProgressIndicator()),
        ]
      ],
    );
  }
}
