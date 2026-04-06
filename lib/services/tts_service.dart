import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  String _lastSpoken = '';

  String get lastSpoken => _lastSpoken;

  Future<void> initialize() async {
    await _tts.setLanguage('en-US');
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.42);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> speak(String text, {bool interrupt = true}) async {
    if (text.trim().isEmpty) return;
    _lastSpoken = text;
    if (interrupt) {
      await _tts.stop();
    }
    await _tts.speak(text);
  }

  Future<void> repeatLast() async {
    if (_lastSpoken.isEmpty) return;
    await speak(_lastSpoken);
  }

  Future<void> stop() => _tts.stop();
}
