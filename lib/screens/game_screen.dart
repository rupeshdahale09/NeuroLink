import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/vocal_controller.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final TextEditingController _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VocalController>().enterSection(VocalSection.play);
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VocalController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Games')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              controller.statusMessage,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: controller.startMemoryGame,
              child: const Text('Start Memory Game'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: controller.startQuizGame,
              child: const Text('Start Quiz Game'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _answerController,
              decoration: const InputDecoration(
                labelText: 'Voice answer transcript',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                final text = _answerController.text.trim();
                if (text.isEmpty) return;
                await controller.handleManualCommand(text);
                _answerController.clear();
              },
              child: const Text('Submit Answer'),
            ),
          ],
        ),
      ),
    );
  }
}
