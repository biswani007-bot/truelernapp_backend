import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/class_entity.dart';
import '../../domain/entities/class_summary_entity.dart';
import '../controllers/class_summary_controller.dart';
import '../controllers/class_summary_state.dart';

/// SCR-17 Class Summary Screen (Figma Node 76:2253 "Class Summary (Revised)")
///
/// Post-class session review screen for parents displaying:
/// - Fixed frosted glass TopAppBar with hamburger menu, TrueLern logo, notifications
/// - 3D Rocket & Gear celebration illustration
/// - "Class Completed" title
/// - Status chips: Attended, duration, dynamic teacher info
/// - "WHAT WE PRACTICED": Skills practiced during class (dynamic or neutral evaluation state)
/// - "NEXT STEPS": Next Live Class reminder & Assignment card with due date
/// - Primary CTA: "VIEW ASSIGNMENT →"
class ClassSummaryScreen extends ConsumerStatefulWidget {
  final String classId;
  final ClassEntity? session;
  final String? childStudentId;

  const ClassSummaryScreen({
    super.key,
    required this.classId,
    this.session,
    this.childStudentId,
  });

  @override
  ConsumerState<ClassSummaryScreen> createState() => _ClassSummaryScreenState();
}

class _ClassSummaryScreenState extends ConsumerState<ClassSummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(classSummaryControllerProvider.notifier).loadSummary(
        classId: widget.classId,
        childStudentId: widget.childStudentId,
        session: widget.session,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final summaryState = ref.watch(classSummaryControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Gradient matching Figma:
          // linear-gradient(109.34deg, #F3E8FF 0%, #E0F2FE 50%, #FFFFFF 100%)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.8, -0.6),
                end: Alignment(0.8, 0.6),
                colors: [
                  Color(0xFFF3E8FF), // rgb(243, 232, 255)
                  Color(0xFFE0F2FE), // rgb(224, 242, 254)
                  Color(0xFFFFFFFF), // rgb(255, 255, 255)
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Main Canvas Content according to state
          SafeArea(
            bottom: false,
            child: _buildBodyForState(summaryState),
          ),

          // Fixed TopAppBar (Figma Node 76:2342)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopAppBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyForState(ClassSummaryState state) {
    if (state is ClassSummaryLoaded) {
      return _buildLoadedState(context, state.summary);
    } else if (state is ClassSummaryError) {
      return _buildErrorState(context, state.message);
    } else {
      return _buildLoadingState();
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0037B1)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading session summary...',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF434655),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(
                'Unable to load summary',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1B23),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/parent/classes');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF434655),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Back to Classes'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(classSummaryControllerProvider.notifier).loadSummary(
                        classId: widget.classId,
                        childStudentId: widget.childStudentId,
                        session: widget.session,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0037B1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, ClassSummaryEntity summary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: 68, // Space for fixed TopAppBar
        bottom: 40, // Space below CTA button
        left: 16,
        right: 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Hero Section: 3D Illustration & Success Indicator
              _buildHeroSection(summary),
              const SizedBox(height: 32),

              // What We Practiced Section
              _buildWhatWePracticedSection(summary),
              const SizedBox(height: 32),

              // Next Steps Section
              _buildNextStepsSection(context, summary),
              const SizedBox(height: 32),

              // Primary CTA Button: VIEW ASSIGNMENT
              _buildViewAssignmentButton(context, summary),
            ],
          ),
        ),
      ),
    );
  }

  /// TopAppBar with Frosted Glass (Figma Node 76:2342)
  Widget _buildTopAppBar(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            bottom: 12,
            left: 16,
            right: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            border: const Border(
              bottom: BorderSide(
                color: Color(0x0D000000), // rgba(0,0,0,0.05)
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Hamburger Menu Button (Node 76:2343)
              InkWell(
                key: const Key('summary_menu_button'),
                borderRadius: BorderRadius.circular(9999),
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/parent/classes');
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(
                    Icons.menu_rounded,
                    color: Color(0xFF1A1B23),
                    size: 24,
                  ),
                ),
              ),

              // TrueLern Logo (Node 76:2346)
              SizedBox(
                height: 32,
                child: Image.asset(
                  'assets/images/truelern_logo_header.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Text(
                    'TrueLern',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 23.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0037B1),
                    ),
                  ),
                ),
              ),

              // Notification Bell (Node 76:2347)
              InkWell(
                key: const Key('summary_notifications_button'),
                borderRadius: BorderRadius.circular(9999),
                onTap: () {},
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFF1A1B23),
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Hero Section: 3D Rocket Illustration + Success Indicator + Status Chips
  Widget _buildHeroSection(ClassSummaryEntity summary) {
    // Format duration text dynamically from real backend values
    final String durationStr;
    if (summary.attendedDurationMinutes != null &&
        summary.scheduledDurationMinutes != null &&
        summary.attendedDurationMinutes! > 0) {
      durationStr = '${summary.attendedDurationMinutes} / ${summary.scheduledDurationMinutes} minutes';
    } else if (summary.scheduledDurationMinutes != null && summary.scheduledDurationMinutes! > 0) {
      durationStr = '${summary.scheduledDurationMinutes} minutes';
    } else if (summary.attendedDurationMinutes != null && summary.attendedDurationMinutes! > 0) {
      durationStr = '${summary.attendedDurationMinutes} minutes';
    } else {
      durationStr = '45 minutes';
    }

    // Format teacher name cleanly from real backend instructor
    final rawTeacher = summary.teacherName?.trim();
    final teacherLabel = (rawTeacher != null && rawTeacher.isNotEmpty)
        ? 'Teacher: $rawTeacher'
        : 'Teacher: Assigned Instructor';

    // Format attendance label cleanly
    final attStatus = summary.attendanceStatus?.toLowerCase();
    final String attendanceLabel;
    if (attStatus == 'late') {
      attendanceLabel = 'Attended (Late)';
    } else if (attStatus == 'half-day') {
      attendanceLabel = 'Attended (Partial)';
    } else if (attStatus == 'absent' || attStatus == 'missed') {
      attendanceLabel = 'Absent';
    } else {
      attendanceLabel = 'Attended';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 3D Rocket with Gear Illustration (Node 76:2278)
        SizedBox(
          width: 200,
          height: 176,
          child: Image.asset(
            'assets/images/rocket_illustration.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),

        // Heading 2: Class Completed (Node 76:2259)
        Text(
          'Class Completed',
          textAlign: TextAlign.center,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1B23),
            letterSpacing: -0.7,
            height: 36 / 28,
          ),
        ),
        const SizedBox(height: 16),

        // Key Details Chips (Node 76:2261)
        // Row 1: [Attended] [Duration]
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            // Chip 1: Attended (Node 76:2262)
            ClipRRect(
              borderRadius: BorderRadius.circular(9999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/check_circle.svg',
                        width: 14,
                        height: 14,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF4F46E5),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        attendanceLabel,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4F46E5),
                          letterSpacing: 0.1,
                          height: 20 / 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Chip 2: Duration (Node 76:2267)
            ClipRRect(
              borderRadius: BorderRadius.circular(9999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/time_clock.svg',
                        width: 14,
                        height: 14,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF434655),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        durationStr,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF434655),
                          letterSpacing: 0.1,
                          height: 20 / 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Row 2: Teacher: Name (Node 76:2273)
        SizedBox(
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/teacher_user.svg',
                      width: 14,
                      height: 14,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF434655),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      teacherLabel,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF434655),
                        letterSpacing: 0.1,
                        height: 20 / 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// What We Practiced Section (Node 76:2280)
  Widget _buildWhatWePracticedSection(ClassSummaryEntity summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title: WHAT WE PRACTICED (Node 76:2282)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'WHAT WE PRACTICED',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF434655),
              height: 24 / 16,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // If skills are available from API, show dynamic cards;
        // if empty, display neutral curriculum evaluation card preserving layout without inventing fake data.
        if (summary.skillsPracticed.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: summary.skillsPracticed.map((topic) {
                return Container(
                  width: 124,
                  height: 118,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000), // rgba(0,0,0,0.04)
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon Circle (48x48)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Color(topic.bgColorHex),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          topic.svgPath,
                          width: 22,
                          height: 22,
                          colorFilter: ColorFilter.mode(
                            Color(topic.colorHex),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Label
                      Text(
                        topic.title,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1A1B23),
                          letterSpacing: 0.1,
                          height: 18 / 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000), // rgba(0,0,0,0.04)
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0x1A0037B1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.school_outlined,
                    size: 24,
                    color: Color(0xFF0037B1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Curriculum Evaluation',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1B23),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Topic assessment & skills evaluation will appear once submitted by instructor.',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF434655),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Next Steps Section (Node 76:2306)
  Widget _buildNextStepsSection(BuildContext context, ClassSummaryEntity summary) {
    final nextClassTime = summary.nextClassTimeFormatted ?? 'No upcoming classes scheduled';
    final assignmentTitle = summary.assignmentTitle ?? 'Assignments';
    final assignmentDue = summary.assignmentDueDate ?? 'No pending assignments';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title: NEXT STEPS (Node 76:2308)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'NEXT STEPS',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF434655),
              height: 24 / 16,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Card 1: Next Live Class (Node 76:2310)
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.go('/parent/classes');
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000), // rgba(0,0,0,0.04)
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Calendar Icon Badge (48x48)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E1ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    'assets/icons/calendar_next_class.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF434655),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.nextClassTitle ?? 'Next Live Class',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1B23),
                          height: 24 / 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nextClassTime,
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

                // Chevron Right (Node 76:2319)
                SvgPicture.asset(
                  'assets/icons/chevron_right.svg',
                  width: 8,
                  height: 12,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF434655),
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Card 2: Assignment with Left Blue Accent Bar (Node 76:2321)
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.go('/parent/assignments');
          },
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000), // rgba(0,0,0,0.04)
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Blue Accent Container with Clipboard Assignment Icon (48x48)
                    Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x1A0037B1), // rgba(0, 55, 177, 0.1)
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        'assets/icons/assignment_clipboard.svg',
                        width: 20,
                        height: 20,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF0037B1),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Texts
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignmentTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1B23),
                              height: 24 / 16,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              SvgPicture.asset(
                                'assets/icons/alert_clock.svg',
                                width: 12,
                                height: 12,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFFBA1A1A),
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  assignmentDue,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFBA1A1A),
                                    height: 20 / 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Left Blue Accent Stripe (Node 76:2334)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0037B1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Primary CTA Button: VIEW ASSIGNMENT (Node 76:2337)
  Widget _buildViewAssignmentButton(BuildContext context, ClassSummaryEntity summary) {
    final hasAssignment = summary.assignmentId != null && summary.assignmentId!.isNotEmpty;
    final buttonText = hasAssignment ? 'VIEW ASSIGNMENT' : 'VIEW ALL ASSIGNMENTS';

    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF0037B1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330037B1), // rgba(0, 55, 177, 0.2)
            blurRadius: 15,
            offset: Offset(0, 10),
            spreadRadius: -3,
          ),
          BoxShadow(
            color: Color(0x330037B1),
            blurRadius: 6,
            offset: Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('view_assignment_button'),
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            context.go('/parent/assignments');
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                buttonText,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 19.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  height: 28 / 18,
                ),
              ),
              const SizedBox(width: 8),
              SvgPicture.asset(
                'assets/icons/arrow_right_btn.svg',
                width: 14,
                height: 14,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
