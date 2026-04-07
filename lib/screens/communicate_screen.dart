import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/neurobot_controller.dart';
import '../controllers/vocal_controller.dart';
import '../vocal_navigation.dart';
import '../widgets/vocal_sub_header.dart';

const _communicateBubbleBlue = LinearGradient(
  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Voice Chat — assistant bubbles, user bubble, hold-to-speak, bottom nav (Communicate active).
class CommunicateScreen extends StatefulWidget {
  const CommunicateScreen({super.key});

  @override
  State<CommunicateScreen> createState() => _CommunicateScreenState();
}

class _CommunicateScreenState extends State<CommunicateScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<NeurobotController>().chatHistory;
    return VocalSubScaffold(
      title: 'Voice Chat',
      navIndex: 1,
      onNavTap: (i) => pushVocalSection(context, i),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                const _AssistantBubble(
                  text: 'Say "Hello NeuroBot" and then speak naturally. You can also type below.',
                ),
                const SizedBox(height: 14),
                ...chat.map((entry) {
                  if (entry.startsWith('User: ')) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _UserBubble(text: entry.replaceFirst('User: ', '')),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AssistantBubble(text: entry.replaceFirst('NeuroBot: ', '')),
                  );
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    borderRadius: BorderRadius.circular(28),
                    child: InkWell(
                      onTap: () async {
                        final text = _textController.text.trim();
                        if (text.isEmpty) return;
                        _textController.clear();
                        await context.read<VocalController>().handleManualCommand(text);
                      },
                      borderRadius: BorderRadius.circular(28),
                      child: Ink(
                        height: 54,
                        decoration: const BoxDecoration(
                          gradient: _communicateBubbleBlue,
                          borderRadius: BorderRadius.all(Radius.circular(28)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              _textController.text.trim().isEmpty ? 'Say Hello NeuroBot' : 'Send Message',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  elevation: 3,
                  shadowColor: Colors.black26,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      context.read<NeurobotController>().clearChat();
                    },
                    child: Ink(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE53935),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type or speak your message',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.replay_rounded),
                  onPressed: () => context.read<VocalController>().repeatInstruction(),
                ),
              ),
              onSubmitted: (value) async {
                final text = value.trim();
                if (text.isEmpty) return;
                _textController.clear();
                await context.read<VocalController>().handleManualCommand(text);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  const _AssistantBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.88,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy_outlined,
                    size: 20, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                const Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF000000),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.45,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: _communicateBubbleBlue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
