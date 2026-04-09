import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Blink gesture enum
enum BlinkGesture {
  none,
  singleClick,
  doubleBack,
  tripleEmergency,
}

/// =======================
/// GAZE PIPELINE
/// =======================
class GazePipeline {
  GazePipeline({
    this.rawAlpha = 0.42,
    this.cursorAlpha = 0.38,
    this.minConfidence = 0.28,
    this.lowConfidenceAlpha = 0.12,
  });

  final double rawAlpha;
  final double cursorAlpha;
  final double minConfidence;
  final double lowConfidenceAlpha;

  Offset _raw = const Offset(0.5, 0.5);
  Offset cursorNorm = const Offset(0.5, 0.5);

  Offset get raw => _raw;

  void update({
    required Offset measuredNorm,
    required double confidence,
    required Offset mappedTargetNorm,
  }) {
    // Always update raw (never freeze)
    _raw = Offset(
      _raw.dx + (measuredNorm.dx - _raw.dx) * rawAlpha,
      _raw.dy + (measuredNorm.dy - _raw.dy) * rawAlpha,
    );

    // Slow movement if confidence is low (NO FREEZE)
    final alpha = confidence < minConfidence
        ? lowConfidenceAlpha
        : cursorAlpha;

    cursorNorm = Offset(
      cursorNorm.dx + (mappedTargetNorm.dx - cursorNorm.dx) * alpha,
      cursorNorm.dy + (mappedTargetNorm.dy - cursorNorm.dy) * alpha,
    );
  }

  void resetCursor(Offset norm) {
    _raw = norm;
    cursorNorm = norm;
  }

  static Offset mapGazeToCursor({
    required Offset gazeNorm,
    required Map<String, Offset> calibration,
    Offset fallbackCenter = const Offset(0.5, 0.5),
  }) {
    final left = calibration['LEFT'];
    final right = calibration['RIGHT'];
    final up = calibration['UP'];
    final down = calibration['DOWN'];

    final center = (left != null && right != null && up != null && down != null)
        ? Offset((left.dx + right.dx) / 2, (up.dy + down.dy) / 2)
        : fallbackCenter;

    double spanX = 0.2;
    double spanY = 0.2;

    if (left != null && right != null) {
      spanX = math.max((right.dx - left.dx).abs() / 2, 0.07);
    }
    if (up != null && down != null) {
      spanY = math.max((down.dy - up.dy).abs() / 2, 0.07);
    }

    final dx = (gazeNorm.dx - center.dx) / spanX;
    final dy = (gazeNorm.dy - center.dy) / spanY;

    return Offset(
      (0.5 + dx * 0.32).clamp(0.03, 0.97),
      (0.5 + dy * 0.32).clamp(0.04, 0.96),
    );
  }
}