import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../domain/entities/demo_booking_entity.dart';
import '../controllers/child_demo_status_controller.dart';
import '../controllers/children_controller.dart';
import '../controllers/children_state.dart';
import '../controllers/demo_slots_controller.dart';

/// Screen displayed after a demo session has ended.
///
/// Follows Figma Parent design system (`Parent(full app)_Trelern`):
/// - Informs the parent that the demo session has completed.
/// - Clarifies that academic review & admin enrollment decision are pending.
/// - Displays real program, student, booking ref, and scheduled demo details.
/// - Listens for app resume and pull-to-refresh to detect admin enrollment & invoice generation.
/// - Once approved / invoice ready, offers direct navigation to Invoices.
class DemoWaitingForAdminScreen extends ConsumerStatefulWidget {
  const DemoWaitingForAdminScreen({
    super.key,
    this.booking,
    this.bookingId,
  });

  final DemoBookingEntity? booking;
  final String? bookingId;

  @override
  ConsumerState<DemoWaitingForAdminScreen> createState() =>
      _DemoWaitingForAdminScreenState();
}

class _DemoWaitingForAdminScreenState
    extends ConsumerState<DemoWaitingForAdminScreen>
    with WidgetsBindingObserver {
  DemoBookingEntity? _booking;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _statusPollTimer;
  bool _hasNavigatedAway = false;

  // Status flags resolved from backend
  bool _isEnrollmentApproved = false;
  bool _isEnrollmentActive = false;
  String? _resolvedCourseName;
  String? _resolvedStudentName;
  String? _resolvedDemoCode;
  String? _resolvedFormattedDate;
  String? _resolvedTimeRange;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreenData();
    });

    _startPolling();
  }

  void _startPolling() {
    _statusPollTimer?.cancel();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (mounted && !_isEnrollmentActive && !_hasNavigatedAway) {
        _checkEnrollmentStatus();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkEnrollmentStatus();
    }
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    _statusPollTimer = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeScreenData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final childrenState = ref.read(childrenControllerProvider);
      final studentId = (childrenState is ChildrenLoaded
              ? childrenState.activeChildId
              : null) ??
          _booking?.studentId ??
          widget.booking?.studentId;

      if (_booking == null) {
        final fetched = await ref
            .read(demoSlotsControllerProvider.notifier)
            .fetchConfirmedDemo(studentId: studentId);
        if (mounted && fetched != null) {
          _booking = fetched;
        }
      }

      if (childrenState is ChildrenLoaded &&
          studentId != null &&
          childrenState.activeChildId != studentId) {
        final hasChild =
            childrenState.children.any((c) => c.studentId == studentId);
        if (hasChild) {
          ref.read(childrenControllerProvider.notifier).setActiveChild(studentId);
        }
      }

      await _checkEnrollmentStatus();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load demo session details: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkEnrollmentStatus() async {
    final childrenState = ref.read(childrenControllerProvider);
    final studentId = (childrenState is ChildrenLoaded
            ? childrenState.activeChildId
            : null) ??
        _booking?.studentId ??
        widget.booking?.studentId;

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final statusMap = await authRepo.getParentStatus(studentId: studentId);

      if (mounted && statusMap != null) {
        final stateCode = statusMap['state']?.toString().toUpperCase();
        final action = statusMap['action']?.toString().toLowerCase();

        if (stateCode == 'STATE_5' || action == 'dashboard') {
          _statusPollTimer?.cancel();
          setState(() {
            _isEnrollmentActive = true;
            _isEnrollmentApproved = true;
          });

          // Invalidate finished demo-session state so ended classroom does not reopen
          ref.read(childDemoStatusControllerProvider.notifier).reset();
          ref.read(demoSlotsControllerProvider.notifier).reset();

          if (!_hasNavigatedAway && mounted) {
            _hasNavigatedAway = true;
            context.go(AppRoutePaths.parentDashboard);
          }
          return;
        } else if (stateCode == 'STATE_4' || action == 'payment') {
          setState(() {
            _isEnrollmentApproved = true;
          });
        }
      }
    } catch (_) {
      // Non-blocking status probe fallback: remain on waiting screen on temporary network errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final childrenState = ref.watch(childrenControllerProvider);
    final activeChild =
        childrenState is ChildrenLoaded ? childrenState.activeChild : null;

    final courseName = _booking?.courseName ??
        _resolvedCourseName ??
        'Selected Course Program';
    final studentName = _booking?.studentName ??
        activeChild?.displayName ??
        _resolvedStudentName ??
        'Student';
    final bookingRef = _booking?.demoCode ??
        _booking?.bookingId ??
        widget.bookingId ??
        _resolvedDemoCode ??
        'DEMO-SESSION';
    final scheduleDetails = _booking != null
        ? '${_booking!.formattedDate} • ${_booking!.formattedTimeRange}'
        : (_resolvedFormattedDate != null && _resolvedTimeRange != null
            ? '$_resolvedFormattedDate • $_resolvedTimeRange'
            : 'Scheduled Session Completed');

    return Scaffold(
      key: const Key('demo_waiting_for_admin_screen'),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF3E8FF), // rgb(243, 232, 255)
              Color(0xFFE0F2FE), // rgb(224, 242, 254)
              Color(0xFFFFFFFF), // rgb(255, 255, 255)
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopHeader(context),
              Expanded(
                child: AppRefreshIndicator(
                  onRefresh: () async {
                    await _initializeScreenData();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 12),
                            if (_isLoading)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 40),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (_errorMessage != null)
                              _buildErrorCard()
                            else
                              _buildMainContentCard(
                                courseName: courseName,
                                studentName: studentName,
                                bookingRef: bookingRef,
                                scheduleDetails: scheduleDetails,
                              ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xCCFFFFFF),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            key: const Key('waiting_admin_back_button'),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: Color(0xFF191C1E),
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutePaths.parentDashboard);
              }
            },
          ),
          Expanded(
            child: Text(
              'Waiting for Admin Enrollment',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF191C1E),
              ),
            ),
          ),
          IconButton(
            key: const Key('waiting_admin_refresh_button'),
            icon: const Icon(
              Icons.refresh_rounded,
              size: 22,
              color: Color(0xFF1E4ED8),
            ),
            onPressed: _initializeScreenData,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContentCard({
    required String courseName,
    required String studentName,
    required String bookingRef,
    required String scheduleDetails,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xE6FFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0x80FFFFFF),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 24,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isEnrollmentApproved
                        ? const Color(0xFFDCFCE7) // green-100
                        : const Color(0xFFEFF6FF), // blue-50
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _isEnrollmentApproved
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isEnrollmentApproved
                            ? Icons.check_circle_rounded
                            : Icons.hourglass_top_rounded,
                        size: 15,
                        color: _isEnrollmentApproved
                            ? const Color(0xFF166534)
                            : const Color(0xFF1E4ED8),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _isEnrollmentActive
                              ? 'Enrollment Confirmed'
                              : (_isEnrollmentApproved
                                  ? 'Enrollment Approved — Invoice Ready'
                                  : 'Demo Completed — Awaiting Review'),
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _isEnrollmentApproved
                                ? const Color(0xFF166534)
                                : const Color(0xFF1E4ED8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Hero Illustration / Icon
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _isEnrollmentApproved
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFEEF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isEnrollmentApproved
                        ? Icons.receipt_long_rounded
                        : Icons.assignment_turned_in_rounded,
                    size: 38,
                    color: _isEnrollmentApproved
                        ? const Color(0xFF15803D)
                        : const Color(0xFF1E4ED8),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Center(
                child: Text(
                  _isEnrollmentActive
                      ? 'Welcome to the Program!'
                      : (_isEnrollmentApproved
                          ? 'Enrollment Approved!'
                          : 'Demo Session Completed'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1B23),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Explanatory Message
              Text(
                _isEnrollmentActive
                    ? 'Your child has been successfully enrolled into the class cohort. Tap below to access your dashboard and schedule.'
                    : (_isEnrollmentApproved
                        ? 'Great news! Our academic team has approved the enrollment. Your tuition invoice is now ready for payment to activate the class cohort.'
                        : 'Your demo session has ended. Our academic team will review the session and update your enrollment status. Please wait while the admin reviews your demo and confirms enrollment. Your invoice will become available once enrollment is approved.'),
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF434655),
                ),
              ),
              const SizedBox(height: 24),

              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 16),

              // Details List
              _buildDetailRow(
                icon: Icons.school_outlined,
                label: 'PROGRAM / COURSE',
                value: courseName,
              ),
              const SizedBox(height: 14),

              _buildDetailRow(
                icon: Icons.person_outline_rounded,
                label: 'STUDENT NAME',
                value: studentName,
              ),
              const SizedBox(height: 14),

              _buildDetailRow(
                icon: Icons.confirmation_number_outlined,
                label: 'BOOKING REFERENCE',
                value: bookingRef,
              ),
              const SizedBox(height: 14),

              _buildDetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'SCHEDULED DETAILS',
                value: scheduleDetails,
              ),
              const SizedBox(height: 28),

              // Action Buttons
              if (_isEnrollmentActive) ...[
                ElevatedButton(
                  key: const Key('waiting_admin_dashboard_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E4ED8),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    context.go(AppRoutePaths.parentDashboard);
                  },
                  child: Text(
                    'Go to Dashboard',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ] else if (_isEnrollmentApproved) ...[
                ElevatedButton(
                  key: const Key('waiting_admin_view_invoice_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E4ED8),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    context.go(AppRoutePaths.parentInvoices);
                  },
                  child: Text(
                    'View Invoices & Pay',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  key: const Key('waiting_admin_dashboard_secondary_button'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: Color(0xFF1E4ED8), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    context.go(AppRoutePaths.parentDashboard);
                  },
                  child: Text(
                    'Back to Dashboard',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E4ED8),
                    ),
                  ),
                ),
              ] else ...[
                OutlinedButton.icon(
                  key: const Key('waiting_admin_check_status_button'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(color: Color(0xFF1E4ED8), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _initializeScreenData,
                  icon: const Icon(
                    Icons.sync_rounded,
                    size: 20,
                    color: Color(0xFF1E4ED8),
                  ),
                  label: Text(
                    'Check Status',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E4ED8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  key: const Key('waiting_admin_return_dashboard_button'),
                  onPressed: () {
                    context.go(AppRoutePaths.parentDashboard);
                  },
                  child: Text(
                    'Return to Dashboard',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF747686),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 44,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'An error occurred',
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _initializeScreenData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E4ED8),
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
