import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/parent_hamburger_drawer.dart';

/// Parent Shell Screen — persistent bottom navigation + drawer affordance.
///
/// Governance (18-PARENT-FLUTTER-IMPLEMENTATION-BLUEPRINT.md §5.1):
/// Tab 1: /parent/dashboard  → ParentDashboardScreen [IMPLEMENTED]
/// Tab 2: /parent/classes    → Placeholder [NOT YET AUTHORIZED]
/// Tab 3: /parent/assignments → Placeholder [NOT YET AUTHORIZED]
/// Tab 4: /parent/invoices   → Placeholder [NOT YET AUTHORIZED]
/// Tab 5: /parent/profile    → Placeholder [NOT YET AUTHORIZED]
///
/// The Drawer opens but non-dashboard items are non-functional placeholders.
/// Drawer logout IS wired to AuthController.logout().
class ParentShellScreen extends ConsumerStatefulWidget {
  const ParentShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ParentShellScreen> createState() => _ParentShellScreenState();
}

class _ParentShellScreenState extends ConsumerState<ParentShellScreen> {
  static const _tabs = [
    _TabItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      key: 'home_tab',
    ),
    _TabItem(
      label: 'My Classes',
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
      key: 'classes_tab',
    ),
    _TabItem(
      label: 'Assignment',
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment_rounded,
      key: 'assignment_tab',
    ),
    _TabItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      key: 'profile_tab',
    ),
  ];

  void _onTabTapped(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      key: const Key('parent_shell_screen'),
      backgroundColor: AppColors.background,
      appBar: null,
      drawer: ParentHamburgerDrawer(
        onTabSelected: _onTabTapped,
        onLogout: () async {
          await ref.read(authControllerProvider.notifier).logout();
        },
      ),
      body: widget.navigationShell,
      bottomNavigationBar: _buildBottomNav(currentIndex),
    );
  }

  Widget _buildBottomNav(int currentIndex) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(
          0xCCFAF8FF,
        ), // rgba(250, 248, 255, 0.8) Figma Node 190:2 & 76:3054
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000), // rgba(0, 0, 0, 0.04)
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_tabs.length, (index) {
              final tab = _tabs[index];
              final isActive = currentIndex == index;
              final color = isActive
                  ? const Color(0xFF0037B1)
                  : const Color(0xFF747686);

              return Expanded(
                child: InkWell(
                  key: Key(tab.key),
                  onTap: () => _onTabTapped(index),
                  splashColor: const Color(0xFF0037B1).withValues(alpha: 0.08),
                  highlightColor: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? tab.activeIcon : tab.icon,
                        size: 22,
                        color: color,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tab.label,
                        style: GoogleFonts.hankenGrotesk(
                          color: color,
                          fontSize: 14,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                          height: 16 / 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Tab descriptor model.
class _TabItem {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.key,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String key;
}
