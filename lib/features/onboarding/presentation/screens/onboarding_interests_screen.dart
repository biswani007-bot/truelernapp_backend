import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../controllers/onboarding_controller.dart';

/// Screen D / Step 2: Interests (Figma Node 382:605)
/// STEP 2 OF 4 in Parent onboarding flow.
///
/// Features:
/// - Fetches real database-backed courses from GET /api/public/courses.
/// - Does not use mock data or fallback hardcoded courses.
/// - Dropdown with real courses and timezone selection.
/// - Preserves course selection and course ID in [OnboardingController].
class OnboardingInterestsScreen extends ConsumerStatefulWidget {
  const OnboardingInterestsScreen({super.key});

  @override
  ConsumerState<OnboardingInterestsScreen> createState() =>
      _OnboardingInterestsScreenState();
}

class _OnboardingInterestsScreenState
    extends ConsumerState<OnboardingInterestsScreen> {
  String? _selectedCourseId;
  String? _selectedTimeZone;
  String? _error;

  static const List<String> _kTimeZones = [
    'Asia/Kolkata (IST +5:30)',
    'America/New_York (EST -5:00)',
    'America/Los_Angeles (PST -8:00)',
    'America/Chicago (CST -6:00)',
    'Europe/London (GMT +0:00)',
    'Asia/Dubai (GST +4:00)',
    'Asia/Singapore (SGT +8:00)',
    'Australia/Sydney (AEST +10:00)',
  ];

  @override
  void initState() {
    super.initState();
    final current = ref.read(onboardingControllerProvider);
    _selectedCourseId = current.selectedCourseId;
    _selectedTimeZone = current.timeZone ?? _kTimeZones.first;

    if (current.availableCourses.isEmpty) {
      Future.microtask(() {
        if (mounted) {
          ref.read(onboardingControllerProvider.notifier).loadCourses();
        }
      });
    }
  }

  void _onContinue() {
    final onboardingState = ref.read(onboardingControllerProvider);
    final courses = onboardingState.availableCourses;
    if (courses.isEmpty) {
      setState(() => _error = "Please wait for courses to load or tap retry.");
      return;
    }

    final targetId = _selectedCourseId ?? onboardingState.selectedCourseId;
    final effectiveCourse = courses.cast<CourseEntity?>().firstWhere(
      (c) => c?.id == targetId,
      orElse: () => courses.first,
    );

    if (effectiveCourse == null) {
      setState(() => _error = "Please select a course you're interested in.");
      return;
    }

    ref
        .read(onboardingControllerProvider.notifier)
        .updateInterests(
          course: effectiveCourse,
          timeZone: _selectedTimeZone ?? _kTimeZones.first,
        );

    final authState = ref.read(authControllerProvider);
    if (authState is Authenticated) {
      context.push(
        AppRoutePaths.demoBookingDashboard,
        extra: effectiveCourse.id,
      );
    } else {
      context.push(AppRoutePaths.onboardingAccount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingControllerProvider);
    final availableCourses = onboardingState.availableCourses;
    final isLoadingCourses = onboardingState.isLoadingCourses;
    final courseError = onboardingState.courseErrorMessage;

    // Deduplicate available courses by id
    final seenIds = <String>{};
    final uniqueCourses = availableCourses.where((c) {
      final key = c.id.isNotEmpty ? c.id : c.courseName;
      if (key.isEmpty || seenIds.contains(key)) return false;
      seenIds.add(key);
      return true;
    }).toList();

    // Resolve effective selected course ID
    final candidateId = _selectedCourseId ?? onboardingState.selectedCourseId;
    final effectiveCourseId = uniqueCourses.any((c) => c.id == candidateId)
        ? candidateId
        : (uniqueCourses.isNotEmpty ? uniqueCourses.first.id : null);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background decorative gradient blob (Node 382:606)
          Positioned(
            top: -22.0,
            left: -22.0,
            width: 256.0,
            height: 256.0,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x334F46E5), Color(0x004F46E5)],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420.0),
                  child: Container(
                    padding: const EdgeInsets.all(28.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.06),
                          blurRadius: 24.0,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back to login button
                        Row(
                          children: [
                            InkWell(
                              onTap: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go(AppRoutePaths.login);
                                }
                              },
                              borderRadius: BorderRadius.circular(8.0),
                              child: Container(
                                padding: const EdgeInsets.all(6.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 16.0,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Logo Section (Node 382:610)
                            Image.asset(
                              'assets/images/truelern_brand_logo.png',
                              height: 38.0,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Text(
                                    'TrueLern',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                            ),
                            const Spacer(),
                            const SizedBox(
                              width: 28.0,
                            ), // balances the back button
                          ],
                        ),

                        const SizedBox(height: 28.0),

                        // Heading 1 (Node 382:614)
                        Text(
                          'Interests',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 24.0,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF191C1E),
                          ),
                        ),

                        const SizedBox(height: 8.0),

                        // Subtitle (Node 382:617)
                        Text(
                          "Tell us what you'd like to learn so we can personalize your experience.",
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14.0,
                            height: 1.45,
                            color: const Color(0xFF64748B),
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 14.0),
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              _error!,
                              style: GoogleFonts.hankenGrotesk(
                                color: const Color(0xFFDC2626),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],

                        if (courseError != null) ...[
                          const SizedBox(height: 14.0),
                          Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color: const Color(0xFFFECACA),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFDC2626),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    courseError,
                                    style: GoogleFonts.hankenGrotesk(
                                      color: const Color(0xFF991B1B),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ref
                                        .read(
                                          onboardingControllerProvider.notifier,
                                        )
                                        .loadCourses();
                                  },
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24.0),

                        // Course Interest Field (Node 382:619)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "Course You're Interested In *",
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ),
                            if (isLoadingCourses) ...[
                              const SizedBox(width: 8),
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8.0),

                        if (isLoadingCourses && availableCourses.isEmpty)
                          Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Loading courses from TrueLern catalog...',
                                  style: GoogleFonts.hankenGrotesk(
                                    color: const Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (availableCourses.isEmpty)
                          Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'No courses available at this time.',
                              style: GoogleFonts.hankenGrotesk(
                                color: const Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            key: ValueKey(effectiveCourseId),
                            initialValue: effectiveCourseId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 14.0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: const BorderSide(
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.8,
                                ),
                              ),
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF64748B),
                            ),
                            items: uniqueCourses.map((c) {
                              return DropdownMenuItem<String>(
                                value: c.id,
                                child: Text(
                                  c.courseName,
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 14.0,
                                    color: const Color(0xFF1E293B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              setState(() {
                                _selectedCourseId = val;
                                _error = null;
                              });
                              final selected = uniqueCourses
                                  .cast<CourseEntity?>()
                                  .firstWhere(
                                    (c) => c?.id == val,
                                    orElse: () => null,
                                  );
                              if (selected != null) {
                                ref
                                    .read(onboardingControllerProvider.notifier)
                                    .selectCourse(selected);
                              }
                            },
                          ),

                        const SizedBox(height: 20.0),

                        // Time Zone Field (Node 382:632)
                        Text(
                          'Time Zone *',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 8.0),

                        DropdownButtonFormField<String>(
                          initialValue: _selectedTimeZone,
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 14.0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.8,
                              ),
                            ),
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFF64748B),
                          ),
                          items: _kTimeZones.map((tz) {
                            return DropdownMenuItem<String>(
                              value: tz,
                              child: Text(
                                tz,
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 14.0,
                                  color: const Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedTimeZone = val;
                              _error = null;
                            });
                          },
                        ),

                        const SizedBox(height: 28.0),

                        // STEP 2 OF 4 indicator (Node 382:645)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2F6),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            'STEP 2 OF 4',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16.0),

                        // Continue Button (Node 382:646)
                        SizedBox(
                          width: double.infinity,
                          height: 50.0,
                          child: ElevatedButton(
                            onPressed: _onContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Continue',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
