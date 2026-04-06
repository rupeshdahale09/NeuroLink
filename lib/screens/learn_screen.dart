import 'package:flutter/material.dart';

import '../vocal_navigation.dart';
import '../widgets/vocal_sub_header.dart';

/// Audio Learning — course list, voice banner, progress, bottom nav (Learn active).
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  static const _headerGrad = LinearGradient(
    colors: [Color(0xFF004AAD), Color(0xFF007AFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const _numGrad = LinearGradient(
    colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return VocalSubScaffold(
      title: 'Audio Learning',
      navIndex: 0,
      onNavTap: (i) => pushVocalSection(context, i),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            children: [
              const SizedBox(height: 12),
              _VoiceBanner(),
              const SizedBox(height: 20),
              _CourseCard(
                index: 1,
                title: 'Introduction to Technology',
                instructor: 'Dr. Sarah Johnson',
                duration: '45 min',
                progress: 0.65,
                numGradient: _numGrad,
              ),
              const SizedBox(height: 16),
              _CourseCard(
                index: 2,
                title: 'Digital Accessibility Basics',
                instructor: 'Prof. James Chen',
                duration: '38 min',
                progress: 0.3,
                numGradient: _numGrad,
              ),
            ],
          ),
          const Positioned(
            right: 18,
            bottom: 18,
            child: VocalEmergencyFab(),
          ),
        ],
      ),
    );
  }
}

class _VoiceBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mic_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Say "PLAY ONE", "PLAY TWO", "PAUSE", or "NEXT"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.98),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.index,
    required this.title,
    required this.instructor,
    required this.duration,
    required this.progress,
    required this.numGradient,
  });

  final int index;
  final String title;
  final String instructor;
  final String duration;
  final double progress;
  final Gradient numGradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: numGradient,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      instructor,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).round()}% Complete',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Material(
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(12),
                    child: Ink(
                      height: 48,
                      decoration: const BoxDecoration(
                        gradient: LearnScreen._headerGrad,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded,
                              color: Colors.white, size: 28),
                          SizedBox(width: 6),
                          Text(
                            'Play',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _SmallGreyButton(icon: Icons.skip_next_rounded, onTap: () {}),
              const SizedBox(width: 10),
              _SmallGreyButton(icon: Icons.volume_up_rounded, onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallGreyButton extends StatelessWidget {
  const _SmallGreyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE5E7EB),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: const Color(0xFF374151)),
        ),
      ),
    );
  }
}
