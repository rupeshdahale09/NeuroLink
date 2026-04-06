import 'package:flutter/material.dart';

import 'screens/communicate_screen.dart';
import 'screens/community_screen.dart';
import 'screens/control_screen.dart';
import 'screens/learn_screen.dart';
import 'screens/play_screen.dart';

/// Pushes the Vocal Mode section that matches [index] (0–4).
void pushVocalSection(BuildContext context, int index) {
  final Widget page = switch (index) {
    0 => const LearnScreen(),
    1 => const CommunicateScreen(),
    2 => const PlayScreen(),
    3 => const ControlScreen(),
    4 => const CommunityScreen(),
    _ => const LearnScreen(),
  };
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}
