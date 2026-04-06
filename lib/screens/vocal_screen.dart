import 'package:flutter/material.dart';

import '../vocal_navigation.dart';
import '../widgets/feature_card.dart';
import '../widgets/vocal_bottom_navigation.dart';

/// Vocal Mode dashboard — blue gradient header, feature rows, mic + SOS FABs, bottom navigation.
const _vocalHeaderGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
);

class VocalScreen extends StatefulWidget {
  const VocalScreen({super.key});

  @override
  State<VocalScreen> createState() => _VocalScreenState();
}

class _VocalScreenState extends State<VocalScreen> {
  int _navIndex = 0;

  void _goToSection(int index) {
    setState(() => _navIndex = index);
    pushVocalSection(context, index);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final fabBottom = 72.0 + bottomPad;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _VocalHeader(
                onBack: () => Navigator.of(context).pop(),
                onHome: () => Navigator.of(context).pop(),
                onHistory: () {},
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                  children: [
                    FeatureCard(
                      gradientColors: const [
                        Color(0xFF9333EA),
                        Color(0xFF6D28D9),
                      ],
                      icon: Icons.menu_book_rounded,
                      title: 'Learn',
                      subtitle: 'Audio Courses & Podcasts',
                      onTap: () => _goToSection(0),
                    ),
                    FeatureCard(
                      gradientColors: const [
                        Color(0xFFEC4899),
                        Color(0xFFDB2777),
                      ],
                      icon: Icons.chat_bubble_rounded,
                      title: 'Communicate',
                      subtitle: 'Voice Chat & AI Assistant',
                      onTap: () => _goToSection(1),
                    ),
                    FeatureCard(
                      gradientColors: const [
                        Color(0xFF3B82F6),
                        Color(0xFF4F46E5),
                      ],
                      icon: Icons.sports_esports_rounded,
                      title: 'Games',
                      subtitle: 'Voice-Controlled Games',
                      onTap: () => _goToSection(2),
                    ),
                    FeatureCard(
                      gradientColors: const [
                        Color(0xFF14B8A6),
                        Color(0xFF0D9488),
                      ],
                      icon: Icons.tune_rounded,
                      title: 'Smart Control',
                      subtitle: 'Voice IoT Commands',
                      onTap: () => _goToSection(3),
                    ),
                    FeatureCard(
                      gradientColors: const [
                        Color(0xFFF97316),
                        Color(0xFFDC2626),
                      ],
                      icon: Icons.groups_rounded,
                      title: 'Community',
                      subtitle: 'Voice Rooms & Chat',
                      onTap: () => _goToSection(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 20,
            bottom: fabBottom,
            child: _MicAndEmergencyFab(),
          ),
        ],
      ),
      bottomNavigationBar: VocalBottomNavigation(
        currentIndex: _navIndex,
        onTap: _goToSection,
      ),
    );
  }
}

class _VocalHeader extends StatelessWidget {
  const _VocalHeader({
    required this.onBack,
    required this.onHome,
    required this.onHistory,
  });

  final VoidCallback onBack;
  final VoidCallback onHome;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: _vocalHeaderGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 28),
          child: Column(
            children: [
              Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: onBack,
                  ),
                  const Expanded(
                    child: Text(
                      'Vocal Mode',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _CircleIconButton(
                    icon: Icons.home_outlined,
                    onPressed: onHome,
                  ),
                  const SizedBox(width: 6),
                  _CircleIconButton(
                    icon: Icons.history_rounded,
                    onPressed: onHistory,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Icon(Icons.mic_rounded, size: 56, color: Colors.white),
              const SizedBox(height: 14),
              const Text(
                'Voice Navigation Ready',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Say "LEARN", "COMMUNICATE", "GAMES", "CONTROL", or "COMMUNITY"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _MicAndEmergencyFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Material(
            elevation: 6,
            shadowColor: Colors.black26,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {},
              child: Ink(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 30),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Material(
              elevation: 4,
              shadowColor: Colors.black26,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {},
                child: Ink(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE53935),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
