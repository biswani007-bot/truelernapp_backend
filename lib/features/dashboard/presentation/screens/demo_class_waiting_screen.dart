import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_paths.dart';
import '../../domain/entities/child_entity.dart';
import '../../domain/entities/demo_booking_entity.dart';
import '../../domain/entities/demo_session_eligibility.dart';
import '../controllers/children_controller.dart';
import '../controllers/children_state.dart';
import '../controllers/demo_slots_controller.dart';

/// Native Flutter Waiting Screen for demo class sessions.
///
/// Displayed when a student/parent attempts to access the demo classroom
/// more than 15 minutes prior to the scheduled session start time (now < T - 15m).
///
/// Features:
/// - TrueLern brand visual styling with responsive centered card.
/// - Authoritative program title, student identity, scheduled date & time range.
/// - Explicit status message:
///   "Your demo class isn't open yet."
///   "You can join 15 minutes before your scheduled session starts."
/// - Live 1-second interval countdown timer counting down to window opening (W = T - 15m).
/// - Disabled "Join Classroom" button while entry is not permitted.
/// - Automatic revalidation & transition to [DemoClassPreJoinScreen] when countdown reaches zero.
/// - App lifecycle observer: revalidates eligibility immediately upon resuming from background.
/// - Handles loading, expired, cancelled, and error states gracefully with Back button.
class DemoClassWaitingScreen extends ConsumerStatefulWidget {
  const DemoClassWaitingScreen({
    super.key,
    this.booking,
    this.bookingId,
  });

  final DemoBookingEntity? booking;
  final String? bookingId;

  @override
  ConsumerState<DemoClassWaitingScreen> createState() =>
      _DemoClassWaitingScreenState();
}

class _DemoClassWaitingScreenState extends ConsumerState<DemoClassWaitingScreen>
    with WidgetsBindingObserver {
  DemoBookingEntity? _booking;
  Timer? _countdownTimer;
  Duration _remainingUntilOpen = Duration.zero;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasAutoTransitioned = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_booking == null) {
        _loadBookingDetails();
      } else {
        _initializeCountdown();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-evaluate session eligibility immediately when returning from background
      _refreshSessionEligibility();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBookingDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final childrenState = ref.read(childrenControllerProvider);
    final studentId =
        childrenState is ChildrenLoaded ? childrenState.activeChildId : null;

    final fetched = await ref
        .read(demoSlotsControllerProvider.notifier)
        .fetchConfirmedDemo(studentId: studentId);

    if (!mounted) return;

    if (fetched != null) {
      final linkedChildren = childrenState is ChildrenLoaded
          ? childrenState.children
          : <ChildEntity>[];
      final authoritativeChild = resolveAuthoritativeStudent(
        booking: fetched,
        linkedChildren: linkedChildren,
      );
      final resolvedBooking = authoritativeChild != null
          ? DemoBookingEntity(
              bookingId: fetched.bookingId,
              liveClassId: fetched.liveClassId,
              demoCode: fetched.demoCode,
              courseName: fetched.courseName,
              studentName: authoritativeChild.displayName,
              studentId: authoritativeChild.studentId,
              studentCode: authoritativeChild.studentCode,
              startDateTime: fetched.startDateTime,
              endDateTime: fetched.endDateTime,
              teacherName: fetched.teacherName,
              teacherStatus: fetched.teacherStatus,
              status: fetched.status,
              meetingUrl: fetched.meetingUrl,
              joinEligible: fetched.joinEligible,
              duration: fetched.duration,
            )
          : fetched;

      setState(() {
        _booking = resolvedBooking;
        _isLoading = false;
      });
      _initializeCountdown();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load demo booking schedule. Please try again.';
      });
    }
  }

  void _initializeCountdown() {
    _countdownTimer?.cancel();
    _tickCountdown();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickCountdown();
    });
  }

  void _tickCountdown() {
    if (_booking == null || !mounted) return;

    final now = DateTime.now();
    final booking = _booking!;
    final gateStatus = booking.evaluateEligibility(now);

    if (gateStatus == DemoSessionTimeGateStatus.eligible) {
      // Joining window has opened!
      _countdownTimer?.cancel();
      _remainingUntilOpen = Duration.zero;

      if (!_hasAutoTransitioned) {
        _hasAutoTransitioned = true;
        _transitionToPreJoin(booking);
      }
      return;
    }

    if (gateStatus == DemoSessionTimeGateStatus.tooEarly) {
      final rem = booking.remainingUntilWindowOpen(now);
      if (mounted) {
        setState(() {
          _remainingUntilOpen = rem;
        });
      }
    } else {
      // Expired, cancelled, etc.
      _countdownTimer?.cancel();
      if (gateStatus == DemoSessionTimeGateStatus.expired ||
          booking.status.toLowerCase() == 'completed') {
        if (!_hasAutoTransitioned) {
          _hasAutoTransitioned = true;
          try {
            context.pushReplacement(
              AppRoutePaths.demoWaitingForAdmin,
              extra: booking,
            );
          } catch (_) {}
        }
        return;
      }
      if (mounted) {
        setState(() {
          _remainingUntilOpen = Duration.zero;
        });
      }
    }
  }

  Future<void> _refreshSessionEligibility() async {
    if (_booking == null) {
      await _loadBookingDetails();
      return;
    }

    _tickCountdown();
  }

  void _transitionToPreJoin(DemoBookingEntity booking) {
    if (!mounted) return;

    try {
      final bookingId = booking.effectiveClassId;
      context.pushReplacement(
        '${AppRoutePaths.demoClassPreJoin}?bookingId=$bookingId',
        extra: booking,
      );
    } catch (_) {
      // In isolated tests without GoRouter
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('demo_class_waiting_screen'),
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
                    Color(0x99F3E8FF),
                    Color(0x99E0F2FE),
                    Color(0x99FFFFFF),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 2. Ambient Blur Orbs
          Positioned(
            top: -60,
            right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                width: 240,
                height: 240,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x66DCE1FF),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -40,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                width: 240,
                height: 240,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x4DFFDBCF),
                ),
              ),
            ),
          ),

          // 3. Main Content
          SafeArea(
            child: Column(
              children: [
                _buildTopAppBar(context),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 16.0,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460.0),
                        child: _buildCardContent(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4.0,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: IconButton(
              key: const Key('demo_waiting_back_button'),
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF191C1E),
                size: 20.0,
              ),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go(AppRoutePaths.demoSessionBooked, extra: _booking);
                }
              },
              tooltip: 'Back',
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              'Demo Class Waiting Room',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF191C1E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 12.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF0037B1),
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 16.0),
            Text(
              'Verifying demo session schedule...',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14.0,
                color: const Color(0xFF475569),
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null || _booking == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 12.0,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56.0,
              height: 56.0,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 28.0,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Session Unavailable',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 20.0,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF191C1E),
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              _errorMessage ?? 'No confirmed demo booking found.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14.0,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20.0),
            SizedBox(
              width: double.infinity,
              height: 48.0,
              child: ElevatedButton(
                onPressed: _loadBookingDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0037B1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.hankenGrotesk(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final booking = _booking!;
    final now = DateTime.now();
    final status = booking.evaluateEligibility(now);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0x1AC4C5D7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 16.0,
            offset: Offset(0, 6),
            spreadRadius: -2.0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Waiting Clock Hero Icon
          Container(
            width: 76.0,
            height: 76.0,
            decoration: BoxDecoration(
              color: status == DemoSessionTimeGateStatus.cancelled
                  ? const Color(0xFFFEE2E2)
                  : (status == DemoSessionTimeGateStatus.expired
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFFEFF6FF)),
              shape: BoxShape.circle,
              border: Border.all(
                color: status == DemoSessionTimeGateStatus.cancelled
                    ? const Color(0xFFFCA5A5)
                    : (status == DemoSessionTimeGateStatus.expired
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFFBFDBFE)),
                width: 2.0,
              ),
            ),
            child: Icon(
              status == DemoSessionTimeGateStatus.cancelled
                  ? Icons.cancel_outlined
                  : (status == DemoSessionTimeGateStatus.expired
                      ? Icons.timer_off_outlined
                      : Icons.hourglass_top_rounded),
              size: 36.0,
              color: status == DemoSessionTimeGateStatus.cancelled
                  ? const Color(0xFFDC2626)
                  : (status == DemoSessionTimeGateStatus.expired
                      ? const Color(0xFF64748B)
                      : const Color(0xFF0037B1)),
            ),
          ),

          const SizedBox(height: 18.0),

          // 2. Primary Heading
          Text(
            status == DemoSessionTimeGateStatus.cancelled
                ? 'Demo Session Cancelled'
                : (status == DemoSessionTimeGateStatus.expired
                    ? 'Demo Session Ended'
                    : "Your demo class isn't open yet."),
            key: const Key('demo_waiting_heading'),
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 22.0,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF191C1E),
              height: 28 / 22,
            ),
          ),

          const SizedBox(height: 8.0),

          // 3. Explanatory Rule Text
          Text(
            status == DemoSessionTimeGateStatus.cancelled
                ? 'This demo session has been cancelled. Please book another available slot.'
                : (status == DemoSessionTimeGateStatus.expired
                    ? 'This scheduled demo session has already concluded and is no longer accessible.'
                    : 'You can join 15 minutes before your scheduled session starts.'),
            key: const Key('demo_waiting_rule_text'),
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14.0,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF475569),
              height: 20 / 14,
            ),
          ),

          const SizedBox(height: 24.0),

          // 4. Live Countdown Badge (Active when too early)
          if (status == DemoSessionTimeGateStatus.tooEarly) ...[
            Container(
              key: const Key('demo_waiting_countdown_container'),
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 14.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0037B1).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(
                  color: const Color(0xFF0037B1).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 16.0,
                        color: Color(0xFF0037B1),
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        'Classroom opens in',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0037B1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    DemoSessionEligibility.formatCountdown(_remainingUntilOpen),
                    key: const Key('demo_waiting_countdown_text'),
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 32.0,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0037B1),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
          ],

          // 5. Booking Details Snapshot Card
          Container(
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
                _buildInfoRow(
                  label: 'PROGRAM / SESSION',
                  value: booking.courseName,
                  icon: Icons.school_outlined,
                  isBold: true,
                ),
                const Divider(height: 18.0, color: Color(0x1AC4C5D7)),
                _buildInfoRow(
                  label: 'STUDENT',
                  value: booking.studentName ?? 'Student',
                  icon: Icons.person_outline_rounded,
                ),
                const Divider(height: 18.0, color: Color(0x1AC4C5D7)),
                _buildInfoRow(
                  label: 'SCHEDULED TIME',
                  value: '${booking.formattedShortDate} • ${booking.formattedTimeRange}',
                  icon: Icons.calendar_today_outlined,
                ),
                if (booking.hasTeacher) ...[
                  const Divider(height: 18.0, color: Color(0x1AC4C5D7)),
                  _buildInfoRow(
                    label: 'TEACHER',
                    value: booking.teacherName!,
                    icon: Icons.badge_outlined,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24.0),

          // 6. Disabled Join Classroom Button (Disabled while early / expired)
          SizedBox(
            width: double.infinity,
            height: 50.0,
            child: ElevatedButton.icon(
              key: const Key('demo_waiting_join_button'),
              onPressed: (status == DemoSessionTimeGateStatus.eligible)
                  ? () => _transitionToPreJoin(booking)
                  : null,
              icon: Icon(
                status == DemoSessionTimeGateStatus.eligible
                    ? Icons.videocam_rounded
                    : Icons.lock_clock_rounded,
                size: 18.0,
              ),
              label: Text(
                status == DemoSessionTimeGateStatus.eligible
                    ? 'Join Classroom'
                    : 'Join Classroom (Opens 15m Before)',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0037B1),
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                disabledForegroundColor: const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: (status == DemoSessionTimeGateStatus.eligible) ? 2.0 : 0.0,
              ),
            ),
          ),

          const SizedBox(height: 12.0),

          // 7. Secondary Back Action
          TextButton(
            key: const Key('demo_waiting_back_text_button'),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go(AppRoutePaths.parentDashboard);
              }
            },
            child: Text(
              'Back to Dashboard',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28.0,
          height: 28.0,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2F6),
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Icon(icon, size: 14.0, color: const Color(0xFF0037B1)),
        ),
        const SizedBox(width: 10.0),
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
                  fontSize: 14.0,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  color: const Color(0xFF191C1E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
