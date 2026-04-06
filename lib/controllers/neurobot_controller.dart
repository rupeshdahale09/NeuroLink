import 'package:flutter/foundation.dart';

import '../services/ai_service.dart';
import '../services/tts_service.dart';

class NeurobotController extends ChangeNotifier {
  NeurobotController({
    required AiService aiService,
    required TtsService ttsService,
  })  : _aiService = aiService,
        _ttsService = ttsService;

  final AiService _aiService;
  final TtsService _ttsService;
  final List<String> _chatHistory = <String>[];
  String _lastReply = '';

  List<String> get chatHistory => List<String>.unmodifiable(_chatHistory);
  String get lastReply => _lastReply;

  void clearChat() {
    _chatHistory.clear();
    notifyListeners();
  }

  Future<String> replyToUser(String userText) async {
    _chatHistory.add('User: $userText');
    final reply = await _aiService.generateReply(userText);
    _chatHistory.add('NeuroBot: $reply');
    _lastReply = reply;
    notifyListeners();
    await _ttsService.speak(reply);
    return reply;
  }
}
