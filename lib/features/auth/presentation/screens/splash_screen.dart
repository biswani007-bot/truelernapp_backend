import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';
import '../../../onboarding/presentation/controllers/onboarding_controller.dart';

/// SCR-01: Splash Screen (Production) — Node ID: 71:128
/// Exact Figma Dimensions: 390 × 907
/// Single visual source of truth: Figma MCP node 71:128
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    final sessionFuture = ref
        .read(authControllerProvider.notifier)
        .checkSession();
    final minSplashFuture = Future.delayed(const Duration(milliseconds: 2000));

    try {
      await Future.wait([sessionFuture, minSplashFuture])
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Session check timeout fallback
    }

    if (!mounted) return;

    final authState = ref.read(authControllerProvider);
    if (authState is Authenticated) {
      switch (authState.destination) {
        case AuthDestination.passwordSetup:
          context.go(AppRoutePaths.passwordSetup);
          break;
        case AuthDestination.onboardingChild:
          context.go(AppRoutePaths.onboardingChild);
          break;
        case AuthDestination.onboardingInterests:
          context.go(AppRoutePaths.onboardingInterests);
          break;
        case AuthDestination.demoBookingDashboard:
          if (authState.demoData != null) {
            ref
                .read(onboardingControllerProvider.notifier)
                .restoreDemoBookingState(
                  leadId: authState.resolvedLeadId,
                  courseName: authState.resolvedCourseName,
                );
          }
          context.go(AppRoutePaths.demoBookingDashboard);
          break;
        case AuthDestination.studentDashboard:
          context.go(AppRoutePaths.parentDashboard);
          break;
      }
    } else if (authState is AuthFailureState) {
      context.go(AppRoutePaths.login);
    } else {
      context.go(AppRoutePaths.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Scale relative to Figma base canvas (390 x 907)
          final scaleX = constraints.maxWidth / 390.0;
          final scaleY = constraints.maxHeight / 907.0;
          final scale = math.min(scaleX, scaleY);

          return Container(
            width: double.infinity,
            height: double.infinity,
            // Figma exact gradient: linear-gradient(-54.54deg, #FFFFFF 0%, #E0E7FF 33.333%, rgba(30,78,216,0.2) 66.667%, #FFFFFF 100%)
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(1.0, 0.7122),
                end: Alignment(-1.0, -0.7122),
                stops: [0.0, 0.3333, 0.6667, 1.0],
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFE0E7FF),
                  Color(0x331E4ED8),
                  Color(0xFFFFFFFF),
                ],
              ),
            ),
            child: Stack(
              children: [
                // 1. Ghosted Floating Icons Background (Node 71:129)
                // Icon 1 (Node 71:130) Cap: top: 57, left: 35, w: 66, h: 54
                Positioned(
                  top: 57.0 * scaleY,
                  left: 35.0 * scaleX,
                  width: 66.0 * scale,
                  height: 54.0 * scale,
                  child: SvgPicture.asset(
                    'assets/icons/imgIcon.svg',
                    fit: BoxFit.contain,
                  ),
                ),

                // Icon 2 (Node 71:131) Book: top: 128, right: 48, w: 55, h: 40
                Positioned(
                  top: 128.0 * scaleY,
                  right: 48.0 * scaleX,
                  width: 55.0 * scale,
                  height: 40.0 * scale,
                  child: SvgPicture.asset(
                    'assets/icons/imgContainer.svg',
                    fit: BoxFit.contain,
                  ),
                ),

                // Icon 3 (Node 71:138) Ribbon Star: top: 215.33, right: 97.5, w: 72.02, h: 72
                Positioned(
                  top: 215.33 * scaleY,
                  right: 97.5 * scaleX,
                  width: 72.02 * scale,
                  height: 72.0 * scale,
                  child: SvgPicture.asset(
                    'assets/icons/imgContainer3.svg',
                    fit: BoxFit.contain,
                  ),
                ),

                // Icon 4 (Node 71:137) Headphones / Bulb: top: 333.67, left: 113.5, w: 101.4, h: 106.67
                Positioned(
                  top: 333.67 * scaleY,
                  left: 113.5 * scaleX,
                  width: 101.4 * scale,
                  height: 106.67 * scale,
                  child: SvgPicture.asset(
                    'assets/icons/imgIcon1.svg',
                    fit: BoxFit.contain,
                  ),
                ),

                // Icon 5 (Node 71:133) Flask: bottom: 160, left: 64, w: 72.23, h: 72
                Positioned(
                  bottom: 160.0 * scaleY,
                  left: 64.0 * scaleX,
                  width: 72.23 * scale,
                  height: 72.0 * scale,
                  child: SvgPicture.asset(
                    'assets/icons/imgContainer1.svg',
                    fit: BoxFit.contain,
                  ),
                ),

                // Icon 6 (Node 71:140) Artist Palette: bottom: 160, left: 165, w: 60, h: 60
                Positioned(
                  bottom: 160.0 * scaleY,
                  left: 165.0 * scaleX,
                  width: 60.0 * scale,
                  height: 60.0 * scale,
                  child: SvgPicture.asset(
                    'assets/icons/imgContainer4.svg',
                    fit: BoxFit.contain,
                  ),
                ),

                // Icon 7 (Node 71:135) Calculator: bottom: 96, right: 64, w: 45, h: 45
                Positioned(
                  bottom: 96.0 * scaleY,
                  right: 64.0 * scaleX,
                  width: 45.0 * scale,
                  height: 45.0 * scale,
                  child: SvgPicture.asset(
                    'assets/icons/imgContainer2.svg',
                    fit: BoxFit.contain,
                  ),
                ),

                // 2. TrueLern Logo (Node 71:144)
                // Centered slightly above vertical midpoint, single crisp composite logo
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 28.0 * scaleY),
                    child: Image.asset(
                      'assets/images/splash_truelern_logo.png',
                      width: 312.0 * scale,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // 3. Version text: bottom: 32px (Node 71:148)
                Positioned(
                  bottom: math.max(
                    32.0 * scaleY,
                    MediaQuery.of(context).padding.bottom + 12.0,
                  ),
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'v1.0.0',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                        color: const Color(0x660037B1), // rgba(0, 55, 177, 0.4)
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
