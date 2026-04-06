import 'package:flutter/material.dart';

import '../vocal_navigation.dart';
import '../widgets/vocal_sub_header.dart';

/// Voice Community — quick actions and active rooms, bottom nav (Community active).
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return VocalSubScaffold(
      title: 'Voice Community',
      navIndex: 4,
      onNavTap: (i) => pushVocalSection(context, i),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _TopActionCard(
                      icon: Icons.podcasts_rounded,
                      iconColor: const Color(0xFFF97316),
                      label: 'Create Room',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _TopActionCard(
                      icon: Icons.calendar_month_rounded,
                      iconColor: const Color(0xFF2563EB),
                      label: 'Schedule',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Active Rooms',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),
              _RoomCard(
                title: 'Tech Talk',
                subtitle: 'Latest gadgets discussion',
                members: 24,
              ),
              const SizedBox(height: 14),
              _RoomCard(
                title: 'Book Club',
                subtitle: 'Monthly reads & voice chat',
                members: 18,
              ),
              const SizedBox(height: 14),
              _RoomCard(
                title: 'Music Lounge',
                subtitle: 'Share tracks and sing-along',
                members: 31,
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

class _TopActionCard extends StatelessWidget {
  const _TopActionCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, size: 36, color: iconColor),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.title,
    required this.subtitle,
    required this.members,
  });

  final String title;
  final String subtitle;
  final int members;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Live',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE02424),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                '$members members',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              Material(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF2563EB),
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    child: Text(
                      'Join',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
