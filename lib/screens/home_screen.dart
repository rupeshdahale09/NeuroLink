import 'package:flutter/material.dart';

import 'eyeunlock_screen.dart';
import 'vocal_screen.dart';

/// Mode selection — NeuroLink home. Tapping Vocal Mode opens [VocalScreen].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _bgTop = Color(0xFFF8FAFC);
  static const _bgBottom = Color(0xFFEEF2FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              children: [
                _BrandHeader(),
                const SizedBox(height: 36),
                _ModeCard(
                  number: '1',
                  numberGradient: const [Color(0xFF2B65EC), Color(0xFF1547D1)],
                  title: 'Vocal Mode',
                  titleColor: const Color(0xFF1547D1),
                  description: 'Voice-Based Interaction for Visually Impaired',
                  trailingIcon: Icons.mic,
                  trailingColor: const Color(0xFF2563EB),
                  cardTint: const Color(0xFFF8FAFF),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const VocalScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _ModeCard(
                  number: '2',
                  numberGradient: const [Color(0xFF22C55E), Color(0xFF15803D)],
                  title: 'EyeUnlock Mode',
                  titleColor: const Color(0xFF15803D),
                  description:
                      'Eye Tracking & Pupil Movement for Physically Disabled',
                  trailingIcon: Icons.remove_red_eye_outlined,
                  trailingColor: const Color(0xFF16A34A),
                  cardTint: const Color(0xFFF0FDF4),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const EyeUnlockScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                _ModeCard(
                  number: '3',
                  numberGradient: const [Color(0xFFF97316), Color(0xFFC2410C)],
                  title: 'Deaf Mode',
                  titleColor: const Color(0xFFC2410C),
                  description: 'Visual & Text-Based Interaction for Deaf Users',
                  trailingIcon: Icons.back_hand_outlined,
                  trailingColor: const Color(0xFFEA580C),
                  cardTint: const Color(0xFFFFF7ED),
                  onTap: () => _showPlaceholder(context, 'Deaf Mode'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPlaceholder(BuildContext context, String title) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: const Center(
            child: Text(
              'This mode is outside the current scope.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            'NL',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'NeuroLink',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose Your Interaction Mode',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Say ONE, TWO, or THREE for voice control',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.number,
    required this.numberGradient,
    required this.title,
    required this.titleColor,
    required this.description,
    required this.trailingIcon,
    required this.trailingColor,
    required this.cardTint,
    required this.onTap,
  });

  final String number;
  final List<Color> numberGradient;
  final String title;
  final Color titleColor;
  final String description;
  final IconData trailingIcon;
  final Color trailingColor;
  final Color cardTint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 128,
          decoration: BoxDecoration(
            color: cardTint,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: numberGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: trailingColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(trailingIcon, color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
