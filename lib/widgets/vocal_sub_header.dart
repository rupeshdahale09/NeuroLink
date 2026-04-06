import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/vocal_controller.dart';
import 'vocal_bottom_navigation.dart';

/// Blue gradient top bar with back, title, home, and refresh — used on Vocal sub-screens.
class VocalSubHeader extends StatelessWidget implements PreferredSizeWidget {
  const VocalSubHeader({
    super.key,
    required this.title,
  });

  final String title;

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
  );

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: _gradient),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
                icon: Icon(
                  Icons.home_outlined,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: 24,
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.refresh_rounded,
                  color: Colors.white.withValues(alpha: 0.95),
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Standard red SOS FAB used on Vocal sub-screens.
class VocalEmergencyFab extends StatelessWidget {
  const VocalEmergencyFab({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.read<VocalController>().emergencyAction(),
        child: Ink(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFE53935),
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

/// Scaffold with [VocalSubHeader] and [VocalBottomNavigation] for Vocal sub-flows.
class VocalSubScaffold extends StatefulWidget {
  const VocalSubScaffold({
    super.key,
    required this.title,
    required this.navIndex,
    required this.onNavTap,
    required this.body,
  });

  final String title;
  final int navIndex;
  final ValueChanged<int> onNavTap;
  final Widget body;

  @override
  State<VocalSubScaffold> createState() => _VocalSubScaffoldState();
}

class _VocalSubScaffoldState extends State<VocalSubScaffold> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final section = switch (widget.navIndex) {
        0 => VocalSection.learn,
        1 => VocalSection.communicate,
        2 => VocalSection.play,
        3 => VocalSection.control,
        4 => VocalSection.community,
        _ => VocalSection.home,
      };
      context.read<VocalController>().enterSection(section);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: VocalSubHeader(title: widget.title),
      body: widget.body,
      bottomNavigationBar: VocalBottomNavigation(
        currentIndex: widget.navIndex,
        onTap: widget.onNavTap,
      ),
    );
  }
}
