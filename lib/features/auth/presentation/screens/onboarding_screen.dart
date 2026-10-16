import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_paths.dart';

/// Data model representing each exact Figma Onboarding frame:
/// 1. Node 71:150 — "Onboarding: Learn with Fun" (390 x 902)
/// 2. Node 71:179 — "Onboarding: Grow Every Day" (390 x 902)
/// 3. Node 71:208 — "Onboarding: Learning Without Limits" (390 x 907)
class OnboardingStepData {
  final String figmaNodeId;
  final String title;
  final String description;
  final String illustrationPath;
  final int stepIndex; // 0, 1, 2
  final double titleTracking;
  final double subtitleFontSize;
  final double subtitleLineHeight;

  const OnboardingStepData({
    required this.figmaNodeId,
    required this.title,
    required this.description,
    required this.illustrationPath,
    required this.stepIndex,
    required this.titleTracking,
    required this.subtitleFontSize,
    required this.subtitleLineHeight,
  });
}

const List<OnboardingStepData> _kOnboardingSteps = [
  OnboardingStepData(
    figmaNodeId: '71:150',
    title: 'Learn with Fun',
    description:
        'Interactive games and activities\nthat make learning exciting.',
    illustrationPath: 'assets/images/onboarding_fun.png',
    stepIndex: 0,
    titleTracking: -0.65,
    subtitleFontSize: 18.0,
    subtitleLineHeight: 28.0 / 18.0,
  ),
  OnboardingStepData(
    figmaNodeId: '71:179',
    title: 'Grow Every Day',
    description: 'Build confidence and essential\nskills step by step.',
    illustrationPath: 'assets/images/onboarding_grow.png',
    stepIndex: 1,
    titleTracking: -0.26,
    subtitleFontSize: 16.0,
    subtitleLineHeight: 24.0 / 16.0,
  ),
  OnboardingStepData(
    figmaNodeId: '71:208',
    title: 'Learning Without Limits',
    description: 'Safe, easy, and available\nwherever your child is.',
    illustrationPath: 'assets/images/onboarding_limits.png',
    stepIndex: 2,
    titleTracking: -0.26,
    subtitleFontSize: 18.0,
    subtitleLineHeight: 28.0 / 18.0,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSkip() {
    context.go(AppRoutePaths.login);
  }

  void _onNext() {
    if (_currentIndex < _kOnboardingSteps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      context.go(AppRoutePaths.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex > 0) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FB),
        body: Stack(
          children: [
            // Background ambient glows for Screen 2 (Grow Every Day - Figma Nodes 71:193 & 71:194)
            if (_currentIndex == 1) ...[
              // Top-left soft blue/violet glow
              Positioned(
                left: -40.0,
                top: -20.0,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 32.0, sigmaY: 32.0),
                  child: Container(
                    width: 240.0,
                    height: 240.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFB7C4FF).withValues(alpha: 0.30),
                    ),
                  ),
                ),
              ),
              // Bottom-right warm amber glow
              Positioned(
                right: -40.0,
                bottom: 80.0,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 32.0, sigmaY: 32.0),
                  child: Container(
                    width: 250.0,
                    height: 250.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFDF9F).withValues(alpha: 0.20),
                    ),
                  ),
                ),
              ),
            ],

            // Main screen content inside SafeArea
            SafeArea(
              child: Column(
                children: [
                  // Top Header (Simplified for Onboarding - Nodes 71:152, 71:203, 71:210)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // TrueLern Logo with "LEARN • GROW • LEAD" tagline (Figma exact: 142.05 x 48)
                        Image.asset(
                          'assets/images/onboarding_logo.png',
                          width: 142.0,
                          height: 48.0,
                          fit: BoxFit.contain,
                        ),

                        // Skip Button
                        GestureDetector(
                          onTap: _onSkip,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.0,
                              vertical: 8.0,
                            ),
                            child: Text(
                              'Skip',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 15.0,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF434655),
                                letterSpacing: 0.28,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // PageView containing the 3 steps (0: Learn with Fun, 1: Grow Every Day, 2: Learning Without Limits)
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _kOnboardingSteps.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final step = _kOnboardingSteps[index];
                        return _buildStepContent(step);
                      },
                    ),
                  ),

                  // Bottom Actions & Progress (Nodes 71:169, 71:181, 71:224)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 28.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Progress Dots matching current page: 1 -> 2 -> 3
                        _buildProgressDots(),

                        const SizedBox(height: 24.0),

                        // Action Button (Next -> or Get Started)
                        _buildActionButton(),
                      ],
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

  Widget _buildStepContent(OnboardingStepData step) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        // Illustration sizing proportional to device width (Figma 390 -> ~340-360px)
        final illustrationSize = (screenWidth * 0.85).clamp(260.0, 360.0);

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 3D Illustration Area with exact Figma decorative blur blobs
                SizedBox(
                  width: illustrationSize,
                  height: illustrationSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Decorative background glow blob matching Figma nodes
                      if (step.stepIndex == 0)
                        ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: 32.0,
                            sigmaY: 32.0,
                          ),
                          child: Container(
                            width: illustrationSize * 0.85,
                            height: illustrationSize * 0.85,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                                colors: [
                                  const Color(0xFF818CF8)
                                      .withValues(alpha: 0.20),
                                  const Color(0xFF1E4ED8)
                                      .withValues(alpha: 0.20),
                                ],
                              ),
                            ),
                          ),
                        )
                      else if (step.stepIndex == 1)
                        ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: 16.0,
                            sigmaY: 16.0,
                          ),
                          child: Container(
                            width: illustrationSize * 0.85,
                            height: illustrationSize * 0.85,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                                colors: [
                                  const Color(0xFFDCE1FF)
                                      .withValues(alpha: 0.20),
                                  const Color(0xFFFFDF9F)
                                      .withValues(alpha: 0.20),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        ImageFiltered(
                          imageFilter: ImageFilter.blur(
                            sigmaX: 32.0,
                            sigmaY: 32.0,
                          ),
                          child: Container(
                            width: illustrationSize * 0.80,
                            height: illustrationSize * 0.80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFB7C4FF)
                                  .withValues(alpha: 0.30),
                            ),
                          ),
                        ),

                      // Illustration Image (Nodes 71:162, 71:180, 71:223)
                      Image.asset(
                        step.illustrationPath,
                        width: illustrationSize,
                        height: illustrationSize,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20.0),

                // Title (Be Vietnam Pro 26px Bold, #0F172A)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    step.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 28.0,
                      fontWeight: FontWeight.w700,
                      height: 34.0 / 26.0,
                      letterSpacing: step.titleTracking,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),

                const SizedBox(height: 14.0),

                // Description (Be Vietnam Pro Regular, #434655)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    step.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: step.subtitleFontSize,
                      fontWeight: FontWeight.w400,
                      height: step.subtitleLineHeight,
                      color: const Color(0xFF434655),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressDots() {
    // Screen 3 (Page Index 2): Indicator 3 active (Figma Node 71:226: 10px circles, gap 12px, dot 3 active pill 32x10)
    if (_currentIndex == 2) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 10.0,
            height: 10.0,
            decoration: const BoxDecoration(
              color: Color(0xFFE6E8EA),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12.0),
          Container(
            width: 10.0,
            height: 10.0,
            decoration: const BoxDecoration(
              color: Color(0xFFE6E8EA),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12.0),
          Container(
            width: 32.0,
            height: 10.0,
            decoration: BoxDecoration(
              color: const Color(0xFF0037B1),
              borderRadius: BorderRadius.circular(9999.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 2.0,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Screen 1 (Page Index 0): Indicator 1 active (Dot 1: 32x8 pill #0037B1, Dots 2 & 3: 8x8 circles #E0E3E5, gap 8px)
    if (_currentIndex == 0) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32.0,
            height: 8.0,
            decoration: BoxDecoration(
              color: const Color(0xFF0037B1),
              borderRadius: BorderRadius.circular(9999.0),
            ),
          ),
          const SizedBox(width: 8.0),
          Container(
            width: 8.0,
            height: 8.0,
            decoration: const BoxDecoration(
              color: Color(0xFFE0E3E5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8.0),
          Container(
            width: 8.0,
            height: 8.0,
            decoration: const BoxDecoration(
              color: Color(0xFFE0E3E5),
              shape: BoxShape.circle,
            ),
          ),
        ],
      );
    }

    // Screen 2 (Page Index 1): Indicator 2 active (Dot 1: 8x8 circle #E0E3E5, Dot 2: 32x8 pill #0037B1, Dot 3: 8x8 circle #E0E3E5, gap 8px)
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8.0,
          height: 8.0,
          decoration: const BoxDecoration(
            color: Color(0xFFE0E3E5),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8.0),
        Container(
          width: 32.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: const Color(0xFF0037B1),
            borderRadius: BorderRadius.circular(9999.0),
          ),
        ),
        const SizedBox(width: 8.0),
        Container(
          width: 8.0,
          height: 8.0,
          decoration: const BoxDecoration(
            color: Color(0xFFE0E3E5),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    final isLast = _currentIndex == 2;

    return Container(
      width: double.infinity,
      height: 56.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        gradient: isLast
            // Screen 3: vertical gradient #3B82F6 -> #1E4ED8 (Figma Node 71:230)
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3B82F6), Color(0xFF1E4ED8)],
              )
            // Screen 1 & 2: horizontal gradient #1E4ED8 -> #3B82F6 (Figma Nodes 71:174, 71:186)
            : const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF1E4ED8), Color(0xFF3B82F6)],
              ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E4ED8)
                .withValues(alpha: isLast ? 0.30 : 0.24),
            blurRadius: isLast ? 14.0 : 12.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _onNext,
          borderRadius: BorderRadius.circular(12.0),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  isLast ? 'Get Started' : 'Next',
                  style: GoogleFonts.beVietnamPro(
                    color: Colors.white,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.28,
                  ),
                ),
                if (!isLast) ...[
                  const SizedBox(width: 8.0),
                  SvgPicture.asset(
                    'assets/icons/onboarding_arrow_right.svg',
                    width: 16.96,
                    height: 16.96,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
