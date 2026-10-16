import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_paths.dart';
import '../../domain/entities/demo_booking_entity.dart';
import '../controllers/children_controller.dart';
import '../controllers/children_state.dart';
import '../controllers/demo_slots_controller.dart';

/// Screen displayed after demo booking confirmation.
///
/// TrueLern Visual Language & Specification:
/// - Atmospheric Background: Linear gradient with subtle blur accents.
/// - Centered responsive card (max width 448px) with rounded corners and soft shadow.
/// - Success checkmark hero icon.
/// - Heading: "Demo Session Booked".
/// - Supporting confirmation message.
/// - Verified booking details: Program/Course, Scheduled Date & Time, Assigned Teacher,
///   Student Name, and Join Link eligibility.
/// - Back to Dashboard action button.
class DemoSessionBookedScreen extends ConsumerStatefulWidget {
  const DemoSessionBookedScreen({super.key, this.booking});

  final DemoBookingEntity? booking;

  @override
  ConsumerState<DemoSessionBookedScreen> createState() =>
      _DemoSessionBookedScreenState();
}

class _DemoSessionBookedScreenState
    extends ConsumerState<DemoSessionBookedScreen> {
  DemoBookingEntity? _booking;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_booking == null) {
        _resolveBookingData();
      }
    });
  }

  Future<void> _resolveBookingData() async {
    // 1. Check if controller already has a cached confirmed booking
    final slotsState = ref.read(demoSlotsControllerProvider);
    if (slotsState is DemoSlotsLoaded &&
        slotsState.lastConfirmedBooking != null) {
      if (mounted) {
        setState(() {
          _booking = slotsState.lastConfirmedBooking;
        });
      }
      return;
    }

    // 2. Fetch authoritative booking data from GET /api/parent/demo
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final childrenState = ref.read(childrenControllerProvider);
    final studentId = childrenState is ChildrenLoaded
        ? childrenState.activeChildId
        : null;

    final fetched = await ref
        .read(demoSlotsControllerProvider.notifier)
        .fetchConfirmedDemo(studentId: studentId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (fetched != null) {
          _booking = fetched;
        } else {
          _errorMessage = 'No active demo session found on your account.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('demo_session_booked_screen'),
      backgroundColor: const Color(0xFFFAF8FF),
      body: Stack(
        children: [
          // 1. Atmospheric Gradient Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.37, -0.93),
                  end: Alignment(0.37, 0.93),
                  colors: [
                    Color(0x99F3E8FF), // rgb(243, 232, 255) @ 60%
                    Color(0x99E0F2FE), // rgb(224, 242, 254) @ 60%
                    Color(0x99FFFFFF), // rgb(255, 255, 255) @ 60%
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 2. Soft Ambient Blur Accents
          Positioned(
            top: -50,
            right: -40,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                width: 256,
                height: 256,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x66DCE1FF),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -40,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                width: 256,
                height: 256,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x4DFFDBCF),
                ),
              ),
            ),
          ),

          // 3. Main Centered Responsive Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448.0),
                  child: _buildMainContent(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF1E4ED8),
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 20.0),
            Text(
              'Loading verified booking details...',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 15.0,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF475569),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_booking == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.0,
              height: 64.0,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline,
                color: Color(0xFFEF4444),
                size: 32.0,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Booking Status',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 22.0,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF191C1E),
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              _errorMessage ??
                  'No confirmed booking details are currently available.',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14.0,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF475569),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            _buildPrimaryButton(
              label: 'Go to Dashboard',
              onTap: () => context.go(AppRoutePaths.parentDashboard),
            ),
          ],
        ),
      );
    }

    final booking = _booking!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0x1AC4C5D7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 15.0,
            offset: Offset(0, 6),
            spreadRadius: -2.0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 28.0),

          // 1. Success Hero Icon
          SizedBox(
            height: 100.0,
            child: Center(
              child: Image.asset(
                'assets/images/demo_confirmed_check.png',
                width: 110.0,
                height: 100.0,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 72.0,
                    height: 72.0,
                    decoration: const BoxDecoration(
                      color: Color(0x1A0037B1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Color(0xFF0037B1),
                      size: 36.0,
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16.0),

          // 2. Heading
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'Demo Session Booked',
              key: const Key('demo_booked_heading'),
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 24.0,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF191C1E),
                height: 32 / 24,
              ),
            ),
          ),

          const SizedBox(height: 8.0),

          // 3. Supporting confirmation text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Your free 1-on-1 demo session has been scheduled successfully. Confirmation details have been sent to your registered email.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF475569),
                height: 20 / 13.5,
              ),
            ),
          ),

          const SizedBox(height: 20.0),

          // 4. Booking Details Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: const Color(0x33C4C5D7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Program / Session Name
                  _buildDetailItem(
                    label: 'PROGRAM / SESSION',
                    value: booking.courseName,
                    icon: Icons.school_outlined,
                    isHighlight: true,
                  ),

                  const Divider(height: 20.0, color: Color(0x1AC4C5D7)),

                  // Scheduled Date & Time
                  _buildDetailItem(
                    label: 'SCHEDULED DATE & TIME',
                    value: booking.formattedDate,
                    subValue: booking.formattedTimeRange,
                    icon: Icons.calendar_today_outlined,
                  ),

                  const Divider(height: 20.0, color: Color(0x1AC4C5D7)),

                  // Student / Child
                  if (booking.studentName != null &&
                      booking.studentName!.isNotEmpty) ...[
                    _buildDetailItem(
                      label: 'STUDENT',
                      value: booking.studentName!,
                      icon: Icons.person_outline,
                    ),
                    const Divider(height: 20.0, color: Color(0x1AC4C5D7)),
                  ],

                  // Assigned Teacher
                  _buildTeacherDetailItem(booking),

                  // Booking Reference / Code
                  if (booking.demoCode != null &&
                      booking.demoCode!.isNotEmpty) ...[
                    const Divider(height: 20.0, color: Color(0x1AC4C5D7)),
                    _buildDetailItem(
                      label: 'BOOKING REFERENCE',
                      value: booking.demoCode!,
                      icon: Icons.confirmation_number_outlined,
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16.0),

          // 5. Join Link / Live Status Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: _buildJoinStatusBox(booking),
          ),

          const SizedBox(height: 24.0),

          // 6. Action Button: Return to Dashboard
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: _buildPrimaryButton(
              label: 'Go to Dashboard',
              onTap: () {
                context.go(AppRoutePaths.parentDashboard);
              },
            ),
          ),

          const SizedBox(height: 24.0),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    String? subValue,
    required IconData icon,
    bool isHighlight = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32.0,
          height: 32.0,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2F6),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(icon, size: 16.0, color: const Color(0xFF1E4ED8)),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                value,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: isHighlight ? 15.0 : 14.0,
                  fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w600,
                  color: const Color(0xFF191C1E),
                ),
              ),
              if (subValue != null) ...[
                const SizedBox(height: 2.0),
                Text(
                  subValue,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E4ED8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherDetailItem(DemoBookingEntity booking) {
    final hasTeacher = booking.hasTeacher;
    final teacherText = booking.displayTeacher;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32.0,
          height: 32.0,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2F6),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: const Icon(
            Icons.record_voice_over_outlined,
            size: 16.0,
            color: Color(0xFF1E4ED8),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ASSIGNED TEACHER',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: hasTeacher
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(9999.0),
                    ),
                    child: Text(
                      booking.displayTeacherStatus,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: hasTeacher
                            ? const Color(0xFF166534)
                            : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2.0),
              Text(
                teacherText,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF191C1E),
                ),
              ),
              if (!hasTeacher) ...[
                const SizedBox(height: 2.0),
                Text(
                  'A specialized mentor will be confirmed before your session.',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJoinStatusBox(DemoBookingEntity booking) {
    final canJoinNow =
        booking.joinEligible &&
        booking.meetingUrl != null &&
        booking.meetingUrl!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: canJoinNow ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: canJoinNow ? const Color(0xFFBFDBFE) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            canJoinNow ? Icons.videocam : Icons.info_outline,
            size: 18.0,
            color: canJoinNow
                ? const Color(0xFF1E4ED8)
                : const Color(0xFF64748B),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              canJoinNow
                  ? 'Your classroom is live! You can join the session now.'
                  : 'Meeting link activates 15 minutes before the session starts. All access links are verified and protected.',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                color: canJoinNow
                    ? const Color(0xFF1E4ED8)
                    : const Color(0xFF475569),
                height: 16 / 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: const Key('demo_booked_dashboard_button'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48.0,
        decoration: BoxDecoration(
          color: const Color(0xFF1E4ED8),
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F1E4ED8),
              blurRadius: 10.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 15.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
