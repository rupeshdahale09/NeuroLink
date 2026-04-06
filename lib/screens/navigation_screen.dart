import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/vocal_controller.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final TextEditingController _destinationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VocalController>().enterSection(VocalSection.navigation);
    });
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VocalController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Navigation')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(controller.statusMessage),
            const SizedBox(height: 12),
            TextField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Destination e.g. hospital, ATM',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                final destination = _destinationController.text.trim();
                if (destination.isEmpty) return;
                await controller.navigateToDestination(destination);
              },
              child: const Text('Start Voice Navigation'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: controller.stopNavigation,
              child: const Text('Stop Navigation'),
            ),
          ],
        ),
      ),
    );
  }
}
