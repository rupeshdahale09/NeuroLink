import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

typedef VoiceTextCallback = void Function(String text, bool isFinal);

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  VoiceTextCallback? _onText;
  bool _continuous = false;
  bool _active = false;
  bool _initialized = false;

  bool get isListening => _speech.isListening;
  bool get isInitialized => _initialized;

  Future<bool> initialize() async {
    _initialized = await _speech.initialize(
      onStatus: _handleStatus,
      onError: (_) {},
    );
    return _initialized;
  }

  Future<void> startPassiveListening(VoiceTextCallback onText) async {
    _onText = onText;
    _continuous = true;
    _active = true;
    await _listen();
  }

  Future<void> startConversationListening(VoiceTextCallback onText) async {
    _onText = onText;
    _continuous = true;
    _active = true;
    await _listen();
  }

  Future<void> stopListening() async {
    _active = false;
    _continuous = false;
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> _listen() async {
    if (!_initialized || _speech.isListening || !_active) return;
    await _speech.listen(
      onResult: _handleResult,
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 5),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  void _handleResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords.trim();
    if (text.isEmpty) return;
    _onText?.call(text, result.finalResult);
  }

  void _handleStatus(String status) {
    final shouldRestart =
        _active && _continuous && (status == 'done' || status == 'notListening');
    if (shouldRestart) {
      Future<void>.delayed(const Duration(milliseconds: 250), _listen);
    }
  }
}
