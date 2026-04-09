import 'dart:async';
import 'dart:math';

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:neuro_link/services/facemesh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:neuro_link/eye_tracking/gaze_blink_pipeline.dart';
import 'package:permission_handler/permission_handler.dart';

enum _EyePage { calibration, dashboard, communicate, learn, games, smart }

class EyeUnlockScreen extends StatefulWidget {
  const EyeUnlockScreen({super.key});

  @override
  State<EyeUnlockScreen> createState() => _EyeUnlockScreenState();
}

class _EyeUnlockScreenState extends State<EyeUnlockScreen>
    with SingleTickerProviderStateMixin {
  _EyePage _page = _EyePage.calibration;
  late final AnimationController _dotController;
  String _typedText = '';
  bool _lightOn = false;
  bool _fanOn = false;
  bool _sosArmed = false;
  int _targetHits = 0;
  int _reactionHits = 0;
  bool _reactionReady = false;
  Offset _targetPos = const Offset(0.35, 0.55);

    late final GazePipeline _gazePipeline;
    bool _faceDetected = false;
  String _blinkStatus = 'OPEN';
  double _lastGazeConfidence = 0;
  Offset _cursorNorm = const Offset(0.5, 0.5);
  int _focusIndex = 0;
  int _focusCount = 1;
  final Map<int, GlobalKey> _focusKeys = <int, GlobalKey>{};
  late final FlutterTts _tts;
  bool _isSpeaking = false;
  int _debugFrameCount = 0;
  int _lastLoggedFaceCount = -1;

  // Calibration baseline capture.
  final Map<String, Offset> _calibration = {};
  String _calibrationPrompt = 'Look LEFT and tap Start Calibration';
  static const List<String> _quickPhrases = [
    'I need water',
    'I am hungry',
    'Take me to washroom',
    'I need help',
    'Call doctor',
    'I am feeling pain',
    'Thank you',
    'Yes',
    'No',
  ];

  static const _bg = Color(0xFF0B1220);
  static const _panel = Color(0xFF111C30);
  static const _accent = Color(0xFF36C2FF);

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _gazePipeline = GazePipeline();
        _tts = FlutterTts();
    _tts.setSpeechRate(0.45);
    _tts.setVolume(1.0);
    _tts.awaitSpeakCompletion(true);
    _tts.setStartHandler(() {
      if (!mounted) return;
      setState(() => _isSpeaking = true);
    });
    _tts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() => _isSpeaking = false);
    });
    _tts.setErrorHandler((_) {
      if (!mounted) return;
      setState(() => _isSpeaking = false);
    });
    Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _page != _EyePage.games) return;
      setState(() => _reactionReady = !_reactionReady);
    });
    unawaited(_initCamera());
  }

  @override
  void dispose() {
    stopFaceMeshNative();
    _tts.stop();
    _dotController.dispose();
    super.dispose();
  }

  void _goTo(_EyePage page) {
    if (page != _page) {
      _focusKeys.clear();
    }
    setState(() => _page = page);
  }

  Future<void> _initCamera() async {
    if (!kIsWeb) {
      final permission = await Permission.camera.request();
      if (!permission.isGranted) return;
    }

    startFaceMeshNative((String data) {
      if (!mounted) return;
      try {
        final json = jsonDecode(data);
        final double x = json['x']?.toDouble() ?? 0.5;
        final double y = json['y']?.toDouble() ?? 0.5;
        final String blinkStr = json['blink'] ?? 'none';

        final gazeNorm = Offset(x, y);
        final mapped = GazePipeline.mapGazeToCursor(
          gazeNorm: gazeNorm,
          calibration: _calibration,
        );

        _gazePipeline.update(
          measuredNorm: gazeNorm,
          confidence: 1.0,
          mappedTargetNorm: mapped,
        );

        BlinkGesture gesture = BlinkGesture.none;
        if (blinkStr == 'single') gesture = BlinkGesture.singleClick;
        if (blinkStr == 'double') gesture = BlinkGesture.doubleBack;
        if (blinkStr == 'triple') gesture = BlinkGesture.tripleEmergency;

        setState(() {
          _faceDetected = true;
          _lastGazeConfidence = 1.0;
          _cursorNorm = _gazePipeline.cursorNorm;
          _blinkStatus = blinkStr.toUpperCase();
        });

        if (gesture != BlinkGesture.none) {
          _handleBlinkGesture(gesture);
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _syncFocusFromCursor();
        });
      } catch (e) {
        debugPrint('FaceMesh JSON Parse Error: $e');
      }
    });
  }

  void _handleBlinkGesture(BlinkGesture gesture) {
    switch (gesture) {
      case BlinkGesture.none:
        return;
      case BlinkGesture.singleClick:
        _activateFocused();
        return;
      case BlinkGesture.doubleBack:
        _goPrevModule();
        return;
      case BlinkGesture.tripleEmergency:
        unawaited(_triggerEmergency());
        return;
    }
  }

  Future<void> _triggerEmergency() async {
    if (!mounted) return;
    await _tts.stop();
    await _tts.speak('Emergency detected. Help is being called.');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency alert — help flow triggered'),
        duration: Duration(seconds: 4),
        backgroundColor: Color(0xFFB71C1C),
      ),
    );
  }

  void _syncFocusFromCursor() {
    if (_focusKeys.isEmpty) return;
    final size = MediaQuery.of(context).size;
    final cursorPx = Offset(
      _cursorNorm.dx * size.width,
      _cursorNorm.dy * size.height,
    );
    int? bestIdx;
    double best = double.infinity;
    for (final entry in _focusKeys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject();
      if (box is! RenderBox || !box.hasSize) continue;
      final topLeft = box.localToGlobal(Offset.zero);
      final rect = topLeft & box.size;
      if (rect.contains(cursorPx)) {
        bestIdx = entry.key;
        break;
      }
      final center = rect.center;
      final d2 =
          (center.dx - cursorPx.dx) * (center.dx - cursorPx.dx) +
          (center.dy - cursorPx.dy) * (center.dy - cursorPx.dy);
      if (d2 < best) {
        best = d2;
        bestIdx = entry.key;
      }
    }
    if (bestIdx != null && bestIdx != _focusIndex) {
      setState(() => _focusIndex = bestIdx!);
    }
  }

  void _activateFocused() {
    switch (_page) {
      case _EyePage.dashboard:
        if (_focusIndex == 0) _goTo(_EyePage.communicate);
        if (_focusIndex == 1) _goTo(_EyePage.learn);
        if (_focusIndex == 2) _goTo(_EyePage.games);
        if (_focusIndex == 3) _goTo(_EyePage.smart);
      case _EyePage.communicate:
        _activateCommunicate();
      case _EyePage.learn:
        if (_focusIndex >= 0 && _focusIndex <= 5) {
          _showHint('Opened video ${_focusIndex + 1}');
        }
        if (_focusIndex == _focusCount - 2) _goPrevModule();
        if (_focusIndex == _focusCount - 1) _goNextModule();
      case _EyePage.games:
        if (_focusIndex == 0) {
          _targetHits += 1;
          _targetPos = Offset(
            0.2 + (Random().nextDouble() * 0.6),
            0.25 + (Random().nextDouble() * 0.6),
          );
        }
        if (_focusIndex == 1 && _reactionReady) {
          _reactionHits += 1;
          _reactionReady = false;
        }
        if (_focusIndex == _focusCount - 2) _goPrevModule();
        if (_focusIndex == _focusCount - 1) _goNextModule();
      case _EyePage.smart:
        if (_focusIndex == 0) _lightOn = !_lightOn;
        if (_focusIndex == 1) _fanOn = !_fanOn;
        if (_focusIndex == 2) _sosArmed = true;
        if (_focusIndex == 3) _goPrevModule();
        if (_focusIndex == 4) _goNextModule();
        setState(() {});
      case _EyePage.calibration:
        _captureCalibrationStep();
    }
  }

  void _showHint(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  void _activateCommunicate() {
    const keyRows = ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'];
    final keys = <String>[];
    for (final row in keyRows) {
      keys.addAll(row.split(''));
    }
    keys.addAll(['Space', 'Back', 'Enter', 'Speak']);
    keys.addAll(_quickPhrases);
    keys.addAll(['Previous', 'Next']);
    if (_focusIndex >= keys.length) return;
    final key = keys[_focusIndex];
    setState(() {
      if (key == 'Space') _typedText += ' ';
      if (key == 'Back') {
        _typedText = _typedText.isEmpty
            ? ''
            : _typedText.substring(0, _typedText.length - 1);
      }
      if (key == 'Enter') {
        unawaited(_speakText(_typedText, clearAfterSpeak: true));
      }
      if (key == 'Speak') {
        unawaited(_speakText(_typedText, clearAfterSpeak: true));
      }
      if (key == 'Previous') _goPrevModule();
      if (key == 'Next') _goNextModule();
      if (_quickPhrases.contains(key)) {
        _typedText = key;
        unawaited(_speakText(key, clearAfterSpeak: false));
      }
      if (key.length == 1) _typedText += key;
    });
  }

  Future<void> _speakText(String text, {bool clearAfterSpeak = false}) async {
    final content = text.trim();
    if (content.isEmpty) return;
    await _tts.stop();
    await _tts.speak(content);
    if (clearAfterSpeak && mounted) {
      setState(() => _typedText = '');
    }
  }

  void _captureCalibrationStep() {
    if (!_faceDetected) return;
    if (!_calibration.containsKey('LEFT')) {
      _calibration['LEFT'] = _gazePipeline.raw;
      _calibrationPrompt = 'Look RIGHT and blink/tap Start';
    } else if (!_calibration.containsKey('RIGHT')) {
      _calibration['RIGHT'] = _gazePipeline.raw;
      _calibrationPrompt = 'Look UP and blink/tap Start';
    } else if (!_calibration.containsKey('UP')) {
      _calibration['UP'] = _gazePipeline.raw;
      _calibrationPrompt = 'Look DOWN and blink/tap Start';
    } else if (!_calibration.containsKey('DOWN')) {
      _calibration['DOWN'] = _gazePipeline.raw;
      _calibrationPrompt = 'Calibration complete. Start EyeUnlock';
    } else {
      _goTo(_EyePage.dashboard);
      _focusIndex = 0;
    }
    setState(() {});
  }

  void _goNextModule() {
    switch (_page) {
      case _EyePage.communicate:
        _goTo(_EyePage.learn);
        return;
      case _EyePage.learn:
        _goTo(_EyePage.games);
        return;
      case _EyePage.games:
        _goTo(_EyePage.smart);
        return;
      case _EyePage.smart:
        _goTo(_EyePage.communicate);
        return;
      case _EyePage.calibration:
      case _EyePage.dashboard:
        _goTo(_EyePage.dashboard);
        setState(() {
          _focusCount = 4;
          _focusIndex = 0;
        });
        return;
    }
  }

  void _goPrevModule() {
    switch (_page) {
      case _EyePage.communicate:
        _goTo(_EyePage.dashboard);
        return;
      case _EyePage.learn:
        _goTo(_EyePage.dashboard);
        return;
      case _EyePage.games:
        _goTo(_EyePage.dashboard);
        return;
      case _EyePage.smart:
        _goTo(_EyePage.dashboard);
        return;
      case _EyePage.calibration:
      case _EyePage.dashboard:
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: switch (_page) {
                _EyePage.calibration => _buildCalibration(),
                _EyePage.dashboard => _buildDashboard(),
                _EyePage.communicate => _buildCommunicate(),
                _EyePage.learn => _buildLearn(),
                _EyePage.games => _buildGames(),
                _EyePage.smart => _buildSmartControl(),
              },
            ),
          ),
          Positioned(right: 10, top: 44, child: _buildDebugOverlay()),
          Positioned(
            left: _cursorNorm.dx * MediaQuery.of(context).size.width - 11,
            top: _cursorNorm.dy * MediaQuery.of(context).size.height - 11,
            child: IgnorePointer(
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.92),
                  border: Border.all(color: _accent, width: 3),
                  boxShadow: const [
                    BoxShadow(color: _accent, blurRadius: 14, spreadRadius: 1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white, fontSize: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MediaPipe FaceMesh Active',
            ),
            Text('Face: ${_faceDetected ? "YES" : "NO"}'),
            Text('Gaze conf: ${_lastGazeConfidence.toStringAsFixed(2)}'),
            Text('Blink: $_blinkStatus'),
            Text(
              'Cursor: ${_cursorNorm.dx.toStringAsFixed(2)}, ${_cursorNorm.dy.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibration() {
    const points = <Alignment>[
      Alignment(0, -0.8),
      Alignment(-0.8, 0),
      Alignment(0.8, 0),
      Alignment(0, 0.8),
      Alignment.center,
    ];
    return Column(
      children: [
        const SizedBox(height: 6),
        const Text(
          'Eye Calibration',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Follow the dots with your eyes to calibrate',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFB8D5FF), fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          _calibrationPrompt,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2A3D61), width: 2),
            ),
            child: AnimatedBuilder(
              animation: _dotController,
              builder: (context, _) {
                final idx =
                    (_dotController.value * points.length).floor() %
                    points.length;
                return Stack(
                  children: [
                    for (final point in points)
                      Align(
                        alignment: point,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white30),
                          ),
                        ),
                      ),
                    Align(
                      alignment: points[idx],
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: _accent, blurRadius: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _focusable(
                index: 0,
                child: _largeButton(
                  label: 'Skip',
                  color: const Color(0xFF2B3F61),
                  onTap: () => _goTo(_EyePage.dashboard),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _focusable(
                index: 1,
                child: _largeButton(
                  label: 'Start Calibration',
                  color: _accent,
                  textColor: Colors.black,
                  onTap: _captureCalibrationStep,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDashboard() {
    _focusCount = 4;
    return Column(
      children: [
        const Text(
          'EyeUnlock Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 1.1,
            children: [
              _focusable(
                index: 0,
                child: _dashboardCard(
                  Icons.chat_bubble_outline,
                  'Communicate',
                  const Color(0xFF40C4FF),
                  () => _goTo(_EyePage.communicate),
                ),
              ),
              _focusable(
                index: 1,
                child: _dashboardCard(
                  Icons.menu_book_outlined,
                  'Learn',
                  const Color(0xFF80CBC4),
                  () => _goTo(_EyePage.learn),
                ),
              ),
              _focusable(
                index: 2,
                child: _dashboardCard(
                  Icons.sports_esports_outlined,
                  'Games',
                  const Color(0xFFFFCC80),
                  () => _goTo(_EyePage.games),
                ),
              ),
              _focusable(
                index: 3,
                child: _dashboardCard(
                  Icons.settings_remote_outlined,
                  'Smart Control',
                  const Color(0xFFCE93D8),
                  () => _goTo(_EyePage.smart),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommunicate() {
    _focusCount = 41;
    const rows = ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'];
    const chars = 'QWERTYUIOPASDFGHJKLZXCVBNM';
    int keyIndex = 0;
    return Column(
      children: [
        _sectionHeader('Communicate'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 96,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _panel,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2A3D61)),
                ),
                child: Text(
                  _typedText.isEmpty
                      ? 'Typed text appears here...'
                      : _typedText,
                  style: const TextStyle(color: Colors.white, fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 96,
              width: 106,
              child: _focusable(
                index: 29,
                child: _largeButton(
                  label: _isSpeaking ? 'Speaking...' : 'Speak',
                  color: _isSpeaking ? const Color(0xFF26A69A) : _accent,
                  textColor: Colors.black,
                  onTap: () =>
                      unawaited(_speakText(_typedText, clearAfterSpeak: true)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const rowGap = 8.0;
              final keyRowHeight = (constraints.maxHeight - (rowGap * 3)) / 4;
              return Column(
                children: [
                  for (final row in rows) ...[
                    SizedBox(
                      height: keyRowHeight,
                      child: Row(
                        children: [
                          for (var i = 0; i < row.length; i++) ...[
                            Expanded(
                              child: _focusable(
                                index: keyIndex++,
                                child: _keyButton(
                                  row[i],
                                  onTap: () =>
                                      setState(() => _typedText += row[i]),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ]..removeLast(),
                      ),
                    ),
                    const SizedBox(height: rowGap),
                  ],
                  SizedBox(
                    height: keyRowHeight,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _focusable(
                            index: chars.length,
                            child: _keyButton(
                              'Space',
                              onTap: () => setState(() => _typedText += ' '),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _focusable(
                            index: chars.length + 1,
                            child: _keyButton(
                              'Back',
                              onTap: () => setState(
                                () => _typedText = _typedText.isEmpty
                                    ? ''
                                    : _typedText.substring(
                                        0,
                                        _typedText.length - 1,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _focusable(
                            index: chars.length + 2,
                            child: _keyButton(
                              'Enter',
                              onTap: () => unawaited(
                                _speakText(_typedText, clearAfterSpeak: true),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2A3D61)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Phrases',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _quickPhrases.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      return SizedBox(
                        width: 182,
                        child: _focusable(
                          index: 30 + i,
                          child: _largeButton(
                            label: _quickPhrases[i],
                            color: const Color(0xFF2B3F61),
                            onTap: () {
                              setState(() => _typedText = _quickPhrases[i]);
                              unawaited(
                                _speakText(
                                  _quickPhrases[i],
                                  clearAfterSpeak: false,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _bottomNav(),
      ],
    );
  }

  Widget _buildLearn() {
    _focusCount = 8;
    return Column(
      children: [
        _sectionHeader('Learn'),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (context, index) {
              return _focusable(
                index: index,
                child: GestureDetector(
                  onTap: () => _showHint('Opened video ${index + 1}'),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _panel,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF2A3D61)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.play_circle_fill_rounded,
                          color: Color(0xFF40C4FF),
                          size: 44,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Video ${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _bottomNav(),
      ],
    );
  }

  Widget _buildGames() {
    _focusCount = 4;
    return Column(
      children: [
        _sectionHeader('Games'),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _focusable(
                  index: 0,
                  child: _gamePanel(
                    title: 'Tap Target',
                    color: const Color(0xFFFFB74D),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment(
                            (_targetPos.dx * 2) - 1,
                            (_targetPos.dy * 2) - 1,
                          ),
                          children: [
                            Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B2335),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _targetHits += 1;
                                  _targetPos = Offset(
                                    0.2 + (Random().nextDouble() * 0.6),
                                    0.2 + (Random().nextDouble() * 0.6),
                                  );
                                });
                              },
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF7043),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hits: $_targetHits',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _focusable(
                  index: 1,
                  child: _gamePanel(
                    title: 'Reaction',
                    color: const Color(0xFF81C784),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (!_reactionReady) return;
                            setState(() {
                              _reactionHits += 1;
                              _reactionReady = false;
                            });
                          },
                          child: Container(
                            width: 98,
                            height: 98,
                            decoration: BoxDecoration(
                              color: _reactionReady
                                  ? const Color(0xFF66BB6A)
                                  : const Color(0xFF455A64),
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Score: $_reactionHits',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _bottomNav(),
      ],
    );
  }

  Widget _buildSmartControl() {
    _focusCount = 5;
    return Column(
      children: [
        _sectionHeader('Smart Control'),
        const SizedBox(height: 10),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _focusable(
                        index: 0,
                        child: _toggleTile(
                          label: 'Light',
                          enabled: _lightOn,
                          onTap: () => setState(() => _lightOn = !_lightOn),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _focusable(
                        index: 1,
                        child: _toggleTile(
                          label: 'Fan',
                          enabled: _fanOn,
                          onTap: () => setState(() => _fanOn = !_fanOn),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _focusable(
                  index: 2,
                  child: _largeButton(
                    label: _sosArmed ? 'SOS Armed' : 'SOS Emergency',
                    color: const Color(0xFFE53935),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('SOS activated')),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _bottomNav(),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        IconButton(
          onPressed: () => _goTo(_EyePage.dashboard),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _dashboardCard(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2A3D61), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gamePanel({
    required String title,
    required Color color,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3D61)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _toggleTile({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF1B5E20) : _panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: enabled ? const Color(0xFF7CFF8A) : const Color(0xFF2A3D61),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '$label ${enabled ? 'ON' : 'OFF'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _keyButton(String label, {VoidCallback? onTap}) {
    return SizedBox(
      height: double.infinity,
      child: ElevatedButton(
        onPressed: onTap ?? () => setState(() => _typedText += label),
        style: ElevatedButton.styleFrom(
          backgroundColor: _panel,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF2A3D61), width: 1.4),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _largeButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
    Color textColor = Colors.white,
  }) {
    return SizedBox(
      height: 64,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _bottomNav() {
    final prevIndex = _page == _EyePage.communicate ? 39 : _focusCount - 2;
    final nextIndex = _page == _EyePage.communicate ? 40 : _focusCount - 1;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: _focusable(
              index: prevIndex,
              child: _largeButton(
                label: 'Previous',
                color: const Color(0xFF2B3F61),
                onTap: _goPrevModule,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _focusable(
              index: nextIndex,
              child: _largeButton(
                label: 'Next',
                color: _accent,
                textColor: Colors.black,
                onTap: _goNextModule,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _focusable({required int index, required Widget child}) {
    final key = _focusKeys.putIfAbsent(index, () => GlobalKey());
    final focused = _focusIndex == index;
    return AnimatedContainer(
      key: key,
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: focused
            ? Border.all(color: const Color(0xFFFFD54F), width: 2.4)
            : null,
      ),
      padding: focused ? const EdgeInsets.all(2) : EdgeInsets.zero,
      child: child,
    );
  }
}
