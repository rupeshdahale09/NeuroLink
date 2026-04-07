import 'dart:math';

import 'package:flutter/foundation.dart';

import '../services/navigation_service.dart';
import '../services/tts_service.dart';
import '../services/voice_service.dart';
import 'neurobot_controller.dart';

enum VocalModeState {
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

  VocalModeState _mode = VocalModeState.activeConversation;
  VocalSection _currentSection = VocalSection.home;
  String _lastHeard = '';
  String _statusMessage = 'Initializing voice system...';
  bool _initialized = false;
  void Function(VocalSection section, String? payload)? _navigationCallback;

  // Learning state
  final List<String> _courses = const <String>[
    'English speaking',
    'Computer skills',
    'Coding basics',
    'Daily life skills',
    'Interview skills',
    'Communication skills',
    'Financial literacy',
    'Orientation and mobility',
  ];
  int _currentLesson = 0;
  final Map<int, double> _lessonProgress = <int, double>{};

  // Game state
  int _memoryLevel = 1;
  List<int> _memorySequence = <int>[];
  int _quizScore = 0;
  int _quizIndex = 0;
  bool _neurobotAwake = false;
  static final RegExp _wakeWordPattern = RegExp(
    r'\b(?:hello|hey|hi)?\s*neuro\s*bot\b',
    caseSensitive: false,
  );
  final List<Map<String, Object>> _quizQuestions = const <Map<String, Object>>[
    <String, Object>{'q': 'What planet is known as the Red Planet?', 'a': <String>['mars']},
    <String, Object>{'q': 'How many days are there in a week?', 'a': <String>['7', 'seven']},
    <String, Object>{'q': 'What is two plus two?', 'a': <String>['4', 'four']},
  ];

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

  String? _extractPromptAfterWakeWord(String speechText) {
    final text = speechText.trim();
    if (text.isEmpty) return null;
    final match = _wakeWordPattern.firstMatch(text);
    if (match == null) return null;
    final remainder = text.substring(match.end).replaceFirst(RegExp(r'^[,\s:.-]+'), '').trim();
    return remainder;
  }

  Future<void> _activateNeurobotConversation({String initialPrompt = ''}) async {
    _mode = VocalModeState.activeConversation;
    _neurobotAwake = true;
    final shouldNavigate = _currentSection != VocalSection.communicate;
    _currentSection = VocalSection.communicate;
    if (shouldNavigate) {
      _navigationCallback?.call(VocalSection.communicate, null);
    }
    notifyListeners();

    if (initialPrompt.isEmpty) {
      await _speakResponse('NeuroBot is ready. Opening communication section. Please speak your message.');
      return;
    }

    await _speakResponse('Opening communication section.');
    final reply = await _neurobotController.replyToUser(initialPrompt);
    await _speakResponse(reply);
  }

  Future<void> initializeVoiceMode() async {
    if (_initialized) return;
    await _ttsService.initialize();
    final ok = await _voiceService.initialize();
    final micPermissionGranted = await _voiceService.hasPermission;
    if (!ok || !micPermissionGranted) {
      _statusMessage =
          'Microphone permission is required. Please allow microphone access and reopen voice mode.';
      notifyListeners();
      await _ttsService.speak(_statusMessage);
      return;
    }
    _initialized = true;
    await _speakResponse(
      'Voice control is ready. Say NeuroBot to start conversation, or say Learn, Play, Communicate, Control, Community, Navigation, Back, or Help.',
      resumeListening: false,
    );
    await _voiceService.startConversationListening(_onVoiceText);
  }

  Future<void> enterSection(VocalSection section) async {
    _currentSection = section;
    notifyListeners();
    await _announceSectionOptions(section, resumeListening: false);
  }

  Future<void> handleManualCommand(String command) async {
    final raw = command.toLowerCase().trim();
    await _onCommand(normalizeCommand(raw), rawInput: raw);
  }

  Future<void> emergencyAction() async {
    await _speakResponse(
      'Emergency mode activated. Alert sent and your current location has been prepared for sharing.',
    );
  }

  Future<void> repeatInstruction() async {
    await _announceSectionOptions(_currentSection);
  }

  Future<void> startLearning() async {
    _currentSection = VocalSection.learn;
    _navigationCallback?.call(VocalSection.learn, null);
    notifyListeners();
    await _speakResponse(
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
    await _speakResponse(
      'Starting ${_courses[_currentLesson]}. Lesson is playing. Say continue to progress or back to return.',
    );
  }

  Future<void> continueLesson() async {
    final current = _lessonProgress[_currentLesson] ?? 0.0;
    final updated = (current + 0.25).clamp(0.0, 1.0);
    _lessonProgress[_currentLesson] = updated;
    notifyListeners();
    if (updated >= 1.0) {
      await _speakResponse(
        '${_courses[_currentLesson]} completed. Do you want to continue with another lesson or go back?',
      );
      return;
    }
    await _speakResponse(
      '${_courses[_currentLesson]} is now ${(updated * 100).round()} percent complete. Say continue or go back.',
    );
  }

  Future<void> startMemoryGame() async {
    _mode = VocalModeState.gameMode;
    final random = Random();
    _memorySequence = List<int>.generate(_memoryLevel + 2, (_) => random.nextInt(9) + 1);
    notifyListeners();
    await _speakResponse('Memory game started. Repeat this sequence: ${_memorySequence.join(', ')}');
  }

  Future<void> checkMemoryAnswer(String input) async {
    final spoken = input
        .split(RegExp(r'[^0-9]+'))
        .where((s) => s.isNotEmpty)
        .map(int.parse)
        .toList();
    if (listEquals(spoken, _memorySequence)) {
      _memoryLevel++;
      await _speakResponse('Correct. Great job. Moving to level $_memoryLevel.');
      await startMemoryGame();
      return;
    }
    await _speakResponse('Try again. Say the sequence again or say back to exit game mode.');
  }

  Future<void> startQuizGame() async {
    _mode = VocalModeState.gameMode;
    _quizIndex = 0;
    notifyListeners();
    final firstQuestion = _quizQuestions[_quizIndex]['q'] as String;
    await _speakResponse('Quiz started. Question 1. $firstQuestion');
  }

  Future<void> submitQuizAnswer(String answer) async {
    final answerText = answer.toLowerCase().trim();
    final expected = _quizQuestions[_quizIndex]['a'] as List<String>;
    final isCorrect = expected.any((token) => answerText.contains(token));
    if (isCorrect) {
      _quizScore += 10;
      notifyListeners();
      _quizIndex++;
      if (_quizIndex >= _quizQuestions.length) {
        _mode = VocalModeState.activeConversation;
        await _speakResponse('Correct. Quiz completed. Your final score is $_quizScore points.');
        return;
      }
      final nextQuestion = _quizQuestions[_quizIndex]['q'] as String;
      await _speakResponse('Correct. Next question ${_quizIndex + 1}. $nextQuestion');
      return;
    }
    await _speakResponse('That is not correct. Please try again.');
  }

  Future<void> navigateToDestination(String destination) async {
    _mode = VocalModeState.navigationMode;
    _currentSection = VocalSection.navigation;
    _navigationCallback?.call(VocalSection.navigation, destination);
    notifyListeners();
    try {
      final steps = await _navigationService.buildVoiceGuidance(destinationLabel: destination);
      for (final step in steps) {
        await _speakResponse(step);
      }
      await _speakResponse('Say repeat to hear directions again, or stop navigation.');
    } catch (e) {
      await _speakResponse('Navigation failed: $e');
    }
  }

  Future<void> stopNavigation() async {
    if (_mode == VocalModeState.navigationMode) {
      _mode = VocalModeState.activeConversation;
      notifyListeners();
      await _speakResponse('Navigation stopped. You are back in conversation mode.');
    }
  }

  Future<void> _onVoiceText(String text, bool isFinal) async {
    _lastHeard = text;
    // ignore: avoid_print
    print('User said: $text');
    notifyListeners();
    if (!isFinal) return;
    final raw = text.toLowerCase().trim();
    final command = normalizeCommand(raw);
    // ignore: avoid_print
    print('Command detected: $command');
    await _onCommand(command, rawInput: raw);
  }

  String normalizeCommand(String input) {
    final original = input.toLowerCase();
    if (original.contains('stop navigation')) {
      return 'stop navigation';
    }
    if (original.contains('memory game')) {
      return 'memory game';
    }
    if (original.contains('quiz game')) {
      return 'quiz game';
    }
    if (original.contains('sound game')) {
      return 'sound game';
    }
    if (original.contains('turn on light')) {
      return 'turn on light';
    }
    if (original.contains('turn off fan')) {
      return 'turn off fan';
    }

    var text = input.toLowerCase().trim();
    text = text.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    text = text.replaceAll(
      RegExp(r'\b(navigate|navigation|go|to|open|please|section|module|screen|i|want|would|like|me|the|a)\b'),
      ' ',
    );
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (text.contains('learn') || text.contains('learning') || text.contains('course')) {
      return 'learn';
    }
    if (_wakeWordPattern.hasMatch(original)) {
      return 'wake neurobot';
    }
    if (text.contains('hello neurobot') || text.contains('hey neurobot') || text.contains('talk neurobot')) {
      return 'hello neurobot';
    }
    if (text.contains('communicate') || text.contains('communication') || text.contains('chat')) {
      return 'communicate';
    }
    if (text.contains('open games') || text.contains('start game') || text.contains('play') || text.contains('game')) {
      return 'play';
    }
    if (text.contains('control')) {
      return 'control';
    }
    if (text.contains('community')) {
      return 'community';
    }
    if (text.contains('help') || text.contains('option')) {
      return 'help';
    }
    if (text.contains('back')) {
      return 'back';
    }
    if (text.contains('repeat')) {
      return 'repeat';
    }
    if (text.contains('emergency')) {
      return 'emergency';
    }
    if (text.contains('navigation') || text.contains('navigate')) {
      return 'navigate';
    }
    if (text.contains('start chat') || text.contains('open chat')) {
      return 'communicate';
    }
    if (text.contains('continue')) {
      return 'continue';
    }
    if (original.contains('navigate') || original.contains('navigation') || original.contains('take me to')) {
      return 'navigate';
    }
    return text;
  }

  Future<void> _onCommand(String command, {String rawInput = ''}) async {
    if (command.isEmpty) return;

    if (command.contains('repeat')) {
      final last = _ttsService.lastSpoken;
      if (last.isNotEmpty) {
        await _speakResponse(last);
      }
      return;
    }
    final spokenText = rawInput.isEmpty ? command : rawInput;
    final wakePrompt = _extractPromptAfterWakeWord(spokenText);
    if (wakePrompt != null) {
      await _activateNeurobotConversation(initialPrompt: wakePrompt);
      return;
    }
    if (command.contains('hello neurobot')) {
      _neurobotAwake = true;
      await _speakResponse('Hello, I am NeuroBot. How can I assist you?');
      return;
    }
    if (command.contains('clear chat') || command.contains('clear conversation')) {
      _neurobotController.clearChat();
      await _speakResponse('Chat cleared.');
      return;
    }
    if (command.contains('help') || command == 'options') {
      await _announceSectionOptions(_currentSection);
      return;
    }
    if (command.contains('back')) {
      _mode = VocalModeState.activeConversation;
      _neurobotAwake = false;
      _currentSection = VocalSection.home;
      _navigationCallback?.call(VocalSection.home, null);
      notifyListeners();
      await _speakResponse('Going back to Vocal home. Say Learn, Communicate, Play, Navigate, or Control.');
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
      final shouldNavigate = _currentSection != VocalSection.communicate;
      _currentSection = VocalSection.communicate;
      if (shouldNavigate) {
        _navigationCallback?.call(VocalSection.communicate, null);
      }
      _neurobotAwake = true;
      notifyListeners();
      await _speakResponse('Opening communication module. NeuroBot is ready to listen.');
      return;
    }
    if (command.contains('play') || command.contains('game')) {
      _currentSection = VocalSection.play;
      _navigationCallback?.call(VocalSection.play, null);
      notifyListeners();
      await _speakResponse('Opening game module. Say memory game or quiz game to start.');
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
      await _speakResponse('Sound recognition game. This is a bell sound. What do you think it is?');
      return;
    }
    if (command.contains('correct')) {
      await _speakResponse('Correct.');
      return;
    }
    if (command.contains('control')) {
      _currentSection = VocalSection.control;
      _navigationCallback?.call(VocalSection.control, null);
      notifyListeners();
      await _speakResponse('Opening control module.');
      return;
    }
    if (command.contains('turn on light')) {
      await _speakResponse('Light turned on.');
      return;
    }
    if (command.contains('turn off fan')) {
      await _speakResponse('Fan turned off.');
      return;
    }
    if (command.contains('community')) {
      _currentSection = VocalSection.community;
      _navigationCallback?.call(VocalSection.community, null);
      notifyListeners();
      await _speakResponse('Opening community module.');
      return;
    }
    if (command.contains('navigate') || rawInput.contains('take me to')) {
      final destination = _extractDestination(rawInput.isEmpty ? command : rawInput);
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

    if (_neurobotAwake || _currentSection == VocalSection.communicate) {
      final prompt = rawInput.isEmpty ? command : rawInput;
      final reply = await _neurobotController.replyToUser(prompt);
      await _speakResponse(reply);
      return;
    }

    await _speakResponse('Sorry, I did not understand. Please say Learn, Play, Communicate, or Help.');
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

  Future<void> _announceSectionOptions(VocalSection section, {bool resumeListening = true}) async {
    final message = switch (section) {
      VocalSection.home =>
        'Available commands are Learn, Communicate, Play, Navigate, Control, Community, Help, and Emergency.',
      VocalSection.learn =>
        'You are in Learn. Say English speaking, Computer skills, Coding basics, Daily life skills, Interview skills, Communication skills, Financial literacy, or Orientation and mobility.',
      VocalSection.communicate =>
        'You are in Communicate. Say NeuroBot and then speak naturally. You can say repeat to hear my last response, or clear chat.',
      VocalSection.play =>
        'You are in Play. Say memory game to repeat number sequences, or quiz game for spoken questions.',
      VocalSection.control =>
        'You are in Control. Say turn on light, turn off fan, or back.',
      VocalSection.community =>
        'You are in Community. Say create room, join room, or back.',
      VocalSection.navigation =>
        'You are in Navigation mode. Say repeat to hear guidance again, or stop navigation.',
    };
    await _speakResponse(message, resumeListening: resumeListening);
  }

  Future<void> _speakResponse(String text, {bool resumeListening = true}) async {
    _statusMessage = text;
    notifyListeners();
    if (resumeListening) {
      await _voiceService.stopListening();
    }
    await _ttsService.speak(text);
    if (resumeListening) {
      await _voiceService.restartContinuousListening(_onVoiceText);
    }
  }

  @override
  void dispose() {
    _voiceService.stopListening();
    _ttsService.stop();
    super.dispose();
  }
}
