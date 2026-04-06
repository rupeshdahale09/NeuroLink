import 'package:flutter/material.dart';

import 'vocal_home.dart';

/// Backward-compatible entry point used by existing home flow.
class VocalScreen extends StatelessWidget {
  const VocalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const VocalHomeScreen();
  }
}
