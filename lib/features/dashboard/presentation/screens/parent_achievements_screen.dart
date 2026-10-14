import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../core/router/route_paths.dart';
import '../widgets/parent_hamburger_drawer.dart';

/// Parent Achievements Screen — PURE STATIC FRONTEND ONLY.
///
/// Figma Source of Truth: `Parent(full app)_TreLern`
/// Frame Name: `Achievements` (Node `76:1621`, 390x844)
///
/// Complete Figma Reproductions:
/// - Exact multi-stop linear gradient: linear-gradient(109.8deg, #F3E8FF, #E0F2FE, #FFFFFF)
/// - Top App Bar with back button (40x40 circle) and centered "Achievements" title (24px Bold #191C1E)
/// - Child Selector pill ("TL Alex" with chevron)
/// - Leaderboard Rank Card ("Your Standing", "RANK 12" royal blue badge, "450 XP", progress bar)
/// - Section header "Premium Badges"
/// - 2x2 Badge Grid:
///   1. Confident Speaker (Golden microphone with cyan aura)
///   2. Consistent Learner (Calendar with indigo aura)
///   3. Problem Solver (Golden trophy, locked state with lock icon in top-right, muted text)
///   4. Team Communicator (Speech bubbles with pink aura)
/// - Single Bottom Navigation Bar per Figma design (Home, My Classes, Assignments, Profile active)
///
/// STRICT RULES:
/// - Zero backend calls / Zero API calls / Zero network requests
/// - Static frontend only
class ParentAchievementsScreen extends StatelessWidget {
  const ParentAchievementsScreen({super.key});

  // Assets extracted directly from Figma Node 76:1621
  static const _badgeSpeaker = 'assets/images/achieve_badge_speaker.png';
  static const _badgeLearner = 'assets/images/achieve_badge_learner.png';
  static const _badgeSolver = 'assets/images/achieve_badge_solver.png';
  static const _badgeCommunicator =
      'assets/images/achieve_badge_communicator.png';

  static const _svgChevronDown = 'assets/icons/achieve_chevron_down.svg';
  static const _svgLock = 'assets/icons/achieve_lock.svg';
  static const _svgBack = 'assets/icons/achieve_back.svg';
  static const _svgNavHome = 'assets/icons/achieve_nav_home.svg';
  static const _svgNavClasses = 'assets/icons/achieve_nav_classes.svg';
  static const _svgNavAssignments = 'assets/icons/achieve_nav_assignments.svg';
  static const _svgNavProfile = 'assets/icons/achieve_nav_profile.svg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('parent_achievements_screen'),
      backgroundColor: Colors.white,
      drawer: const ParentHamburgerDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.6, -0.8),
            end: Alignment(0.6, 0.8),
            colors: [
              Color(0xFFF3E8FF), // rgb(243, 232, 255) - lavender
              Color(0xFFE0F2FE), // rgb(224, 242, 254) - light sky blue
              Color(0xFFFFFFFF), // rgb(255, 255, 255) - white
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Top App Bar (Node 76:1679) ─────────────────────────
              _buildTopAppBar(context),

              // ── Scrollable Body ─────────────────────────────────────
              Expanded(
                child: AppRefreshIndicator(
                  onRefresh: () async {
                    await Future<void>.delayed(
                      const Duration(milliseconds: 600),
                    );
                  },
                  child: SingleChildScrollView(
                    key: const Key('achievements_scroll_view'),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 672),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),

                              // ── Child Selector Pill (Node 76:1809) ─────────
                              _buildChildSelector(context),

                              const SizedBox(height: 24),

                              // ── Leaderboard Rank Card (Node 76:1623) ───────
                              _buildStandingCard(),

                              const SizedBox(height: 24),

                              // ── Section Title: Premium Badges (Node 76:1646) ─
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  'Premium Badges',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1B23),
                                    height: 24 / 16,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // ── Badges 2x2 Grid (Node 101:3) ───────────────
                              _buildBadgesGrid(),

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Bottom Navigation Bar (Node 76:1686) ───────────────
              _buildBottomNavBar(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Top App Bar (Node 76:1679)
  /// Height 64px, rgba(250,248,255,0.8), back button, centered title.
  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xCCFAF8FF), // rgba(250, 248, 255, 0.8)
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000), // 0px 1px 2px rgba(0,0,0,0.05)
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered Title (Node 76:1683/76:1684)
          Center(
            child: Text(
              'Achievements',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 25.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF191C1E),
                height: 32 / 24,
              ),
            ),
          ),

          // Left Back Button (Node 76:1680/76:1681)
          Positioned(
            left: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: const Key('achievements_back_button'),
                borderRadius: BorderRadius.circular(9999),
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutePaths.parentDashboard);
                  }
                },
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: SvgPicture.asset(_svgBack, width: 16, height: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Child Selector Pill (Node 76:1809)
  Widget _buildChildSelector(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: const Color(0x4DC4C5D7), // rgba(196, 197, 215, 0.3)
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000), // 0px 1px 1px rgba(0,0,0,0.05)
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular Avatar (Node 76:1810)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF747686), width: 1),
            ),
            child: Center(
              child: Text(
                'TL',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0037B1),
                  letterSpacing: 0.5,
                  height: 16 / 11,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Name (Node 76:1814/76:1815)
          Text(
            'Alex',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF191C1E),
              letterSpacing: 0.5,
              height: 16 / 12,
            ),
          ),

          const SizedBox(width: 8),

          // Chevron Down (Node 76:1816/76:1817)
          SvgPicture.asset(_svgChevronDown, width: 9, height: 5.55),
        ],
      ),
    );
  }

  /// Leaderboard Rank Card (Node 76:1623)
  /// "Your Standing", "Keep learning to climb higher!", "RANK 12" badge, "450 XP", progress bar.
  Widget _buildStandingCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xB3FFFFFF), // rgba(255, 255, 255, 0.7)
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0x80FFFFFF), // rgba(255, 255, 255, 0.5)
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000), // 0px 4px 24px rgba(0, 0, 0, 0.06)
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Top-Right Radial Glow (Node 76:1635)
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x1A0037B1), // rgba(0, 55, 177, 0.1)
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A0037B1),
                      blurRadius: 20,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Title + Rank Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Standing Title + Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Standing',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 21.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1B23),
                                height: 28 / 20,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Keep learning to climb higher!',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF434655),
                                height: 20 / 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Rank Badge (Node 76:1630)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E4ED8), // Royal blue
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0D000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'RANK',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFCAD3FF),
                                letterSpacing: 0.6,
                                height: 16 / 12,
                              ),
                            ),
                            Text(
                              '12',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFCAD3FF),
                                height: 32 / 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // XP Header Row (Node 76:1637)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '450 XP',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0037B1),
                          letterSpacing: 0.1,
                          height: 20 / 14,
                        ),
                      ),
                      Text(
                        '50 XP to Rank 11',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF434655),
                          height: 16 / 12,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Progress Bar (Node 76:1642)
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E7F3),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: 0.90, // 450/500 = 90%
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0037B1),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Badges 2x2 Grid (Node 101:3)
  Widget _buildBadgesGrid() {
    return Column(
      children: [
        // Row 1: Confident Speaker & Consistent Learner
        Row(
          children: [
            Expanded(
              child: _buildBadgeCard(
                title: 'Confident\nSpeaker',
                imagePath: _badgeSpeaker,
                auraColor: const Color(0x3322D3EE), // rgba(34, 211, 238, 0.2)
                isLocked: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBadgeCard(
                title: 'Consistent\nLearner',
                imagePath: _badgeLearner,
                auraColor: const Color(0x334F46E5), // rgba(79, 70, 229, 0.2)
                isLocked: false,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Row 2: Problem Solver (Locked) & Team Communicator
        Row(
          children: [
            Expanded(
              child: _buildBadgeCard(
                title: 'Problem\nSolver',
                imagePath: _badgeSolver,
                auraColor: Colors.transparent,
                isLocked: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBadgeCard(
                title: 'Team\nCommunicator',
                imagePath: _badgeCommunicator,
                auraColor: const Color(0x33FB7185), // rgba(251, 113, 133, 0.2)
                isLocked: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Individual Badge Card matching Neumorphic styling in Figma
  /// Solid white, rounded 24px, 8px 8px 16px #E6E5EB and -8px -8px 16px white shadow
  Widget _buildBadgeCard({
    required String title,
    required String imagePath,
    required Color auraColor,
    required bool isLocked,
  }) {
    return Container(
      height: 173,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 23),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFFE6E5EB),
            blurRadius: 16,
            offset: Offset(8, 8),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 16,
            offset: Offset(-8, -8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lock Icon in Top-Right for Locked badge (Node 101:22)
          if (isLocked)
            Positioned(
              right: 0,
              top: 0,
              child: SvgPicture.asset(_svgLock, width: 12, height: 22.75),
            ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge Icon with Soft Aura Glow
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Aura Glow (Node 101:7, 101:14, 101:29)
                    if (auraColor != Colors.transparent)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: auraColor,
                          boxShadow: [
                            BoxShadow(
                              color: auraColor,
                              blurRadius: 12,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),

                    // Badge 3D Illustration (Node 101:8, 101:15, 101:21, 101:30)
                    Opacity(
                      opacity: isLocked ? 0.70 : 1.0,
                      child: Image.asset(
                        imagePath,
                        width: 64,
                        height: 64,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Title (Node 101:10, 101:17, 101:25, 101:32)
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isLocked
                      ? const Color(0xFF434655)
                      : const Color(0xFF1A1B23),
                  letterSpacing: 0.1,
                  height: 17.5 / 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bottom Navigation Bar (Node 76:1686)
  /// Mobile navbar with rounded top 24px, 4 tabs: Home, My Classes, Assignments, Profile (Active).
  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xCCFAF8FF), // rgba(250, 248, 255, 0.8)
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000), // 0px -4px 20px rgba(0, 0, 0, 0.04)
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Home Tab (Node 76:1687)
            _buildNavBarItem(
              iconSvg: _svgNavHome,
              iconWidth: 16,
              iconHeight: 18,
              label: 'Home',
              isActive: false,
              onTap: () => context.go(AppRoutePaths.parentDashboard),
            ),

            // My Classes Tab (Node 76:1693)
            _buildNavBarItem(
              iconSvg: _svgNavClasses,
              iconWidth: 22,
              iconHeight: 18,
              label: 'My Classes',
              isActive: false,
              onTap: () => context.go(AppRoutePaths.parentClasses),
            ),

            // Assignments Tab (Node 76:1699)
            _buildNavBarItem(
              iconSvg: _svgNavAssignments,
              iconWidth: 18,
              iconHeight: 20,
              label: 'Assignments',
              isActive: false,
              onTap: () => context.go(AppRoutePaths.parentAssignments),
            ),

            // Profile Tab (Active) (Node 76:1705)
            _buildNavBarItem(
              iconSvg: _svgNavProfile,
              iconWidth: 16,
              iconHeight: 16,
              label: 'Profile',
              isActive: true,
              onTap: () => context.go(AppRoutePaths.parentProfile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBarItem({
    required String iconSvg,
    required double iconWidth,
    required double iconHeight,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final activeColor = const Color(0xFF0037B1);
    final inactiveColor = const Color(0xFF434655);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconSvg,
              width: iconWidth,
              height: iconHeight,
              colorFilter: ColorFilter.mode(
                isActive ? activeColor : inactiveColor,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
                letterSpacing: 0.5,
                height: 16 / 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
