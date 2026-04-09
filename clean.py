import re

file_path = r"c:\NeuroLink\lib\screens\eyeunlock_screen.dart"
with open(file_path, "r", encoding="utf-8") as f:
    code = f.read()

# 1. Imports
code = re.sub(
    r"import 'package:camera/camera\.dart';\nimport 'package:flutter/foundation\.dart';",
    r"import 'dart:convert';\nimport 'package:flutter/foundation.dart';\nimport 'package:neuro_link/services/facemesh.dart';",
    code
)
code = re.sub(r"import 'package:google_mlkit_face_detection/google_mlkit_face_detection\.dart';\n", "", code)

# 2. State variables
code = re.sub(r"CameraController\? _cameraController;\n\s*late final FaceDetector _faceDetector;\n", "", code)
code = re.sub(r"late final BlinkGestureResolver _blinkResolver;\n\s*bool _processingFrame = false;\n", "", code)

# 3. InitState
init_state_re = r"_blinkResolver = BlinkGestureResolver\(\);.*?_faceDetector = FaceDetector\(.*?\);.*?\n"
code = re.sub(init_state_re, "", code, flags=re.DOTALL)
code = code.replace("if (!kIsWeb) {\n      unawaited(_initCamera());\n    }", "unawaited(_initCamera());")

# 4. Dispose
code = code.replace("_cameraController?.dispose();\n    _faceDetector.close();\n    _blinkResolver.reset();", "stopFaceMeshNative();")

# 5. _initCamera and _processImage
camera_func_re = r"Future<void> _initCamera\(\) async \{.*?(?=void _handleBlinkGesture)"
replacement = """Future<void> _initCamera() async {
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

  """
code = re.sub(camera_func_re, replacement, code, flags=re.DOTALL)

# 6. Web Alert message
web_alert_re = r"if \(kIsWeb\)\s*Positioned\([\s\S]*?\),(\s*)SafeArea\("
code = re.sub(web_alert_re, r"SafeArea(", code)

# 7. Debug overlay ML kit text
code = code.replace("kIsWeb\n                  ? 'ML Kit: unavailable (web)'\n                  : 'ML Kit: ${defaultTargetPlatform.name}',", "'MediaPipe FaceMesh Active',")

# 8. CameraPreview overlay
camera_preview_re = r"if \(_cameraController != null &&[\s\S]*?CameraPreview\(_cameraController!\)[\s\S]*?\),"
code = re.sub(camera_preview_re, "", code)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(code)

print("done")
