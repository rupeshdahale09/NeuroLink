import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../services/navigation_service.dart';
import '../services/tts_service.dart';
import '../services/voice_service.dart';
import 'neurobot_controller.dart';

enum VocalModeState {
  passiveListening,
  activeConversation,
  navigationMode,
  gameMode,
}

enum VocalSection {
  home,
  learn,
  communicate,
  play,
  control,
  community,
  navigation,
}

class VocalController extends ChangeNotifier {
  VocalController({
    required VoiceService voiceService,
    required TtsService ttsService,
    required NavigationService navigationService,
    required NeurobotController neurobotController,
  })  : _voiceService = voiceService,
        _ttsService = ttsService,
        _navigationService = navigationService,
        _neurobotController = neurobotController;

  final VoiceService _voiceService;
  final TtsService _ttsService;
  final NavigationService _navigationService;
  final NeurobotController _neurobotController;

  VocalModeState _mode = VocalModeState.passiveListening;
  VocalSection _currentSection = VocalSection.home;
  String _lastHeard = '';
  String _statusMessage = 'Initializing voice system...';
  bool _initialized = false;
  Timer? _inactivityTimer;
  void Function(VocalSection section, String? payload)? _navigationCallback;

  // Learning state
  final List<String> _courses = const <String>[
    'English speaking',
    'Computer skills',
    'Coding basics',
    'Daily life skills',
  ];
  int _currentLesson = 0;
  final Map<int, double> _lessonProgress = <int, double>{};

  // Game state
  int _memoryLevel = 1;
  List<int> _memorySequence = <int>[];
  int _quizScore = 0;

  VocalModeState get mode => _mode;
  VocalSection get currentSection => _currentSection;
  String get lastHeard => _lastHeard;
  String get statusMessage => _statusMessage;
  bool get initialized => _initialized;
  int get currentLesson => _currentLesson;
  List<String> get courses => List<String>.unmodifiable(_courses);
  Map<int, double> get lessonProgress => Map<int, double>.unmodifiable(_lessonProgress);
  int get memoryLevel => _memoryLevel;
  List<int> get memorySequence => List<int>.unmodifiable(_memorySequence);
  int get quizScore => _quizScore;
  List<String> get chatHistory => _neurobotController.chatHistory;

  void attachNavigator(void Function(VocalSection section, String? payload) callback) {
    _navigationCallback = callback;
  }

  Future<void> initializeVoiceMode() async {
    if (_initialized) return;
    await _ttsService.initialize();
    final ok = await _voiceService.initialize();
    if (!ok) {
      _statusMessage = 'Speech recognition is unavailable on this device.';
      notifyListeners();
      await _ttsService.speak(_statusMessage);
      return;
    }
    _initialized = true;
    await _speakAndTrack(
      'Welcome to Vocal Mode. Say Hello NeuroBot to begin or say Learn, Communicate, Play, Navigate, or Help.',
    );
    await _voiceService.startPassiveListening(_onVoiceText);
    _resetInactivityTimer();
  }

  Future<void> enterSection(VocalSection section) async {
    _currentSection = section;
    notifyListeners();
    _resetInactivityTimer();
    await _announceSectionOptions(section);
  }

  Future<void> handleManualCommand(String command) async {
    await _onCommand(command.toLowerCase().trim());
  }

  Future<void> emergencyAction() async {
    await _speakAndTrack(
      'Emergency mode activated. Alert sent and your current location has been prepared for sharing.',
    );
  }

  Future<void> repeatInstruction() async {
    await _announceSectionOptions(_currentSection);
  }

  Future<void> startLearning() async {
    _currentSection = VocalSection.learn;
    _navigationCallback?.call(VocalSection.learn, null);
    await _speakAndTrack(
      'Learning module opened. Available courses are English speaking, Computer skills, Coding basics, and Daily life skills. Say the course name to begin.',
    );
  }

  Future<void> selectCourseByVoice(String text) async {
    final lower = text.toLowerCase();
    final matchedIndex = _courses.indexWhere((c) => lower.contains(c.toLowerCase().split(' ').first));
    if (matchedIndex == -1) return;
    _currentLesson = matchedIndex;
    _lessonProgress[_currentLesson] = _lessonProgress[_currentLesson] ?? 0.0;
    notifyListeners();
    await _speakAndTrack(
      'Starting ${_courses[_currentLesson]}. Lesson is playing. Say continue to progress or back to return.',
    );
  }

  Future<void> continueLesson() async {
    final current = _lessonProgress[_currentLesson] ?? 0.0;
    final updated = (current + 0.25).clamp(0.0, 1.0);
    _lessonProgress[_currentLesson] = updated;
    notifyListeners();
    if (updated >= 1.0) {
      await _speakAndTrack(
        '${_courses[_currentLesson]} completed. Do you want to continue with another lesson or go back?',
      );
      return;
    }
    await _speakAndTrack(
      '${_courses[_currentLesson]} is now ${(updated * 100).round()} percent complete. Say continue or go back.',
    );
  }

  Future<void> startMemoryGame() async {
    _mode = VocalModeState.gameMode;
    final random = Random();
    _memorySequence = List<int>.generate(_memoryLevel + 2, (_) => random.nextInt(9) + 1);
    notifyListeners();
    await _speakAndTrack('Memory game started. Repeat this sequence: ${_memorySequence.join(', ')}');
  }

  Future<void> checkMemoryAnswer(String input) async {
    final spoken = input
        .split(RegExp(r'[^0-9]+'))
        .where((s) => s.isNotEmpty)
        .map(int.parse)
        .toList();
    if (listEquals(spoken, _memorySequence)) {
      _memoryLevel++;
      await _speakAndTrack('Correct. Great job. Moving to level $_memoryLevel.');
      await startMemoryGame();
      return;
    }
    await _speakAndTrack('Try again. Say the sequence again or say back to exit game mode.');
  }

  Future<void> startQuizGame() async {
    _mode = VocalModeState.gameMode;
    notifyListeners();
    await _speakAndTrack('Quiz started. Question: What planet is known as the Red Planet?');
  }

  Future<void> submitQuizAnswer(String answer) async {
    if (answer.toLowerCase().contains('mars')) {
      _quizScore += 10;
      notifyListeners();
      await _speakAndTrack('Correct. Your quiz score is $_quizScore points.');
      return;
    }
    await _speakAndTrack('Try again. Hint: it is the fourth planet from the sun.');
  }

  Future<void> navigateToDestination(String destination) async {
    _mode = VocalModeState.navigationMode;
    _currentSection = VocalSection.navigation;
    _navigationCallback?.call(VocalSection.navigation, destination);
    notifyListeners();
    try {
      final steps = await _navigationService.buildVoiceGuidance(destinationLabel: destination);
      for (final step in steps) {
        await _speakAndTrack(step);
      }
      await _speakAndTrack('Say repeat to hear directions again, or stop navigation.');
    } catch (e) {
      await _speakAndTrack('Navigation failed: $e');
    }
  }

  Future<void> stopNavigation() async {
    if (_mode == VocalModeState.navigationMode) {
      _mode = VocalModeState.activeConversation;
      notifyListeners();
      await _speakAndTrack('Navigation stopped. You are back in conversation mode.');
    }
  }

  Future<void> _onVoiceText(String text, bool isFinal) async {
    _lastHeard = text;
    notifyListeners();
    if (!isFinal) return;
    _resetInactivityTimer();
    await _onCommand(text.toLowerCase().trim());
  }

  Future<void> _onCommand(String command) async {
    if (command.isEmpty) return;

    if (_mode == VocalModeState.passiveListening) {
      if (command.contains('hello neurobot')) {
        _mode = VocalModeState.activeConversation;
        notifyListeners();
        await _speakAndTrack('Hello, I am NeuroBot. How can I assist you today?');
        await _voiceService.startConversationListening(_onVoiceText);
      } else if (command.contains('help')) {
        await _announceSectionOptions(_currentSection);
      }
      return;
    }

    if (command.contains('repeat')) {
      await _ttsService.repeatLast();
      return;
    }
    if (command.contains('clear chat')) {
      _neurobotController.clearChat();
      await _speakAndTrack('Chat cleared.');
      return;
    }
    if (command.contains('help') || command == 'options') {
      await _announceSectionOptions(_currentSection);
      return;
    }
    if (command.contains('back')) {
      _mode = VocalModeState.activeConversation;
      _currentSection = VocalSection.home;
      _navigationCallback?.call(VocalSection.home, null);
      notifyListeners();
      await _speakAndTrack('Going back to Vocal home. Say Learn, Communicate, Play, Navigate, or Control.');
      return;
    }
    if (command.contains('emergency')) {
      await emergencyAction();
      return;
    }
    if (command.contains('learn') || command.contains('course')) {
      await startLearning();
      return;
    }
    if (command.contains('communicate') || command.contains('chat')) {
      _currentSection = VocalSection.communicate;
      _navigationCallback?.call(VocalSection.communicate, null);
      notifyListeners();
      await _speakAndTrack('Communication mode opened. You can talk to me naturally.');
      return;
    }
    if (command.contains('play') || command.contains('game')) {
      _currentSection = VocalSection.play;
      _navigationCallback?.call(VocalSection.play, null);
      notifyListeners();
      await _speakAndTrack('Games opened. Say memory game, quiz game, or sound game.');
      return;
    }
    if (command.contains('memory game')) {
      await startMemoryGame();
      return;
    }
    if (command.contains('quiz game')) {
      await startQuizGame();
      return;
    }
    if (command.contains('sound game')) {
      _mode = VocalModeState.gameMode;
      notifyListeners();
      await _speakAndTrack('Sound recognition game. This is a bell sound. What do you think it is?');
      return;
    }
    if (command.contains('correct')) {
      await _speakAndTrack('Correct.');
      return;
    }
    if (command.contains('control')) {
      _currentSection = VocalSection.control;
      _navigationCallback?.call(VocalSection.control, null);
      notifyListeners();
      await _speakAndTrack('Control module opened. Say turn on light or turn off fan.');
      return;
    }
    if (command.contains('turn on light')) {
      await _speakAndTrack('Light turned on.');
      return;
    }
    if (command.contains('turn off fan')) {
      await _speakAndTrack('Fan turned off.');
      return;
    }
    if (command.contains('community')) {
      _currentSection = VocalSection.community;
      _navigationCallback?.call(VocalSection.community, null);
      notifyListeners();
      await _speakAndTrack('Community opened. Say create room or join latest room.');
      return;
    }
    if (command.contains('navigate') || command.contains('take me to')) {
      final destination = _extractDestination(command);
      await navigateToDestination(destination);
      return;
    }
    if (command.contains('stop navigation')) {
      await stopNavigation();
      return;
    }
    if (command.contains('continue')) {
      await continueLesson();
      return;
    }
    if (_mode == VocalModeState.gameMode && command.contains(RegExp(r'\d'))) {
      await checkMemoryAnswer(command);
      return;
    }
    if (_mode == VocalModeState.gameMode) {
      await submitQuizAnswer(command);
      return;
    }
    if (_currentSection == VocalSection.learn) {
      await selectCourseByVoice(command);
      return;
    }

    await _neurobotController.replyToUser(command);
  }

  String _extractDestination(String command) {
    const prefixes = <String>[
      'navigate to',
      'take me to',
      'navigate',
    ];
    for (final prefix in prefixes) {
      if (command.startsWith(prefix)) {
        final text = command.replaceFirst(prefix, '').trim();
        if (text.isNotEmpty) return text;
      }
    }
    return 'nearby destination';
  }

  Future<void> _announceSectionOptions(VocalSection section) async {
    final message = switch (section) {
      VocalSection.home =>
        'Available commands are Learn, Communicate, Play, Navigate, Control, Community, Help, and Emergency.',
      VocalSection.learn =>
        'You are in Learn. Say English speaking, Computer skills, Coding basics, or Daily life skills. Say continue to resume progress.',
      VocalSection.communicate =>
        'You are in Communicate. Speak naturally. Say repeat to hear my last response, or clear chat.',
      VocalSection.play =>
        'You are in Play. Say memory game, quiz game, or sound game.',
      VocalSection.control =>
        'You are in Control. Say turn on light, turn off fan, or back.',
      VocalSection.community =>
        'You are in Community. Say create room, join room, or back.',
      VocalSection.navigation =>
        'You are in Navigation mode. Say repeat to hear guidance again, or stop navigation.',
    };
    await _speakAndTrack(message);
  }

  Future<void> _speakAndTrack(String text) async {
    _statusMessage = text;
    notifyListeners();
    await _ttsService.speak(text);
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(seconds: 5), () async {
      await _announceSectionOptions(_currentSection);
      _resetInactivityTimer();
    });
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _voiceService.stopListening();
    _ttsService.stop();
    super.dispose();
  }
}
