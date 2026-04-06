import 'package:flutter/material.dart';

import '../vocal_navigation.dart';
import '../widgets/vocal_sub_header.dart';

/// Smart Control — voice hints, device toggles, bottom nav (Control active).
class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  bool _lightOn = true;
  bool _fanOn = false;
  bool _tvOn = true;
  bool _coffeeOn = false;

  @override
  Widget build(BuildContext context) {
    return VocalSubScaffold(
      title: 'Smart Control',
      navIndex: 3,
      onNavTap: (i) => pushVocalSection(context, i),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '🎤',
                          style: TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Try these voice commands:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _bullet('Turn on the lights'),
                    _bullet('Start the fan'),
                    _bullet('Switch off TV'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _DeviceRow(
                name: 'Living Room Light',
                statusOn: _lightOn,
                onChanged: (v) => setState(() => _lightOn = v),
                icon: Icons.lightbulb_rounded,
                iconBg: const Color(0xFF14B8A6),
              ),
              const SizedBox(height: 12),
              _DeviceRow(
                name: 'Ceiling Fan',
                statusOn: _fanOn,
                onChanged: (v) => setState(() => _fanOn = v),
                icon: Icons.air_rounded,
                iconBg: const Color(0xFFE5E7EB),
                iconColor: const Color(0xFF6B7280),
              ),
              const SizedBox(height: 12),
              _DeviceRow(
                name: 'Smart TV',
                statusOn: _tvOn,
                onChanged: (v) => setState(() => _tvOn = v),
                icon: Icons.tv_rounded,
                iconBg: const Color(0xFF2563EB),
              ),
              const SizedBox(height: 12),
              _DeviceRow(
                name: 'Coffee Maker',
                statusOn: _coffeeOn,
                onChanged: (v) => setState(() => _coffeeOn = v),
                icon: Icons.coffee_rounded,
                iconBg: const Color(0xFFE5E7EB),
                iconColor: const Color(0xFF6B7280),
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

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white, fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.name,
    required this.statusOn,
    required this.onChanged,
    required this.icon,
    required this.iconBg,
    this.iconColor = Colors.white,
  });

  final String name;
  final bool statusOn;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusOn ? 'ON' : 'OFF',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: statusOn,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF2563EB),
            activeTrackColor: const Color(0xFF93C5FD),
          ),
        ],
      ),
    );
  }
}
