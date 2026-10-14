import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../classes/presentation/widgets/classes_student_selector.dart';
import '../../../dashboard/domain/entities/child_entity.dart';
import '../../../dashboard/presentation/controllers/children_controller.dart';
import '../../../dashboard/presentation/controllers/children_state.dart';
import '../../../dashboard/presentation/widgets/parent_hamburger_drawer.dart';
import '../../domain/entities/certificate_entity.dart';
import '../controllers/certificates_controller.dart';
import '../controllers/certificates_state.dart';

/// Certificates Screen for the Parent / Student mobile experience.
///
/// Fully aligned with TrueLern mobile design language (colors, typography, cards,
/// gradient, student selector, and pull-to-refresh).
class ParentCertificatesScreen extends ConsumerStatefulWidget {
  const ParentCertificatesScreen({super.key});

  @override
  ConsumerState<ParentCertificatesScreen> createState() =>
      _ParentCertificatesScreenState();
}

class _ParentCertificatesScreenState
    extends ConsumerState<ParentCertificatesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final childrenState = ref.read(childrenControllerProvider);
      final activeChildId =
          childrenState is ChildrenLoaded ? childrenState.activeChildId : null;
      ref
          .read(certificatesControllerProvider.notifier)
          .loadCertificates(childStudentId: activeChildId);
    });
  }

  Future<void> _onRefresh() async {
    final childrenState = ref.read(childrenControllerProvider);
    final activeChildId =
        childrenState is ChildrenLoaded ? childrenState.activeChildId : null;
    await Future.wait([
      ref
          .read(certificatesControllerProvider.notifier)
          .loadCertificates(childStudentId: activeChildId, isRefresh: true),
      ref.read(childrenControllerProvider.notifier).loadChildren(isRefresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final childrenState = ref.watch(childrenControllerProvider);
    final certificatesState = ref.watch(certificatesControllerProvider);

    final List<ChildEntity> children =
        childrenState is ChildrenLoaded ? childrenState.children : const [];
    final ChildEntity? activeChild =
        childrenState is ChildrenLoaded ? childrenState.activeChild : null;
    final String? activeChildId = activeChild?.studentId;

    // Synchronize active child changes
    ref.listen<ChildrenState>(childrenControllerProvider, (previous, next) {
      if (next is ChildrenLoaded) {
        final prevId = previous is ChildrenLoaded ? previous.activeChildId : null;
        if (prevId != next.activeChildId && next.activeChildId != null) {
          ref
              .read(certificatesControllerProvider.notifier)
              .loadCertificates(childStudentId: next.activeChildId);
        }
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      drawer: const ParentHamburgerDrawer(),
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.7, -0.7),
            end: Alignment(0.7, 0.7),
            colors: AppColors.canvasGradient,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top App Bar
              _buildTopAppBar(context),

              // Main Scrollable Area with Pull-to-Refresh
              Expanded(
                child: AppRefreshIndicator(
                  onRefresh: _onRefresh,
                  child: SingleChildScrollView(
                    key: const Key('certificates_scroll_view'),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 16,
                      bottom: 40,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 448),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Student Selector Pill
                            if (activeChild != null) ...[
                              ClassesStudentSelector(
                                activeChild: activeChild,
                                children: children,
                                onChildSelected: (newStudentId) {
                                  ref
                                      .read(childrenControllerProvider.notifier)
                                      .setActiveChild(newStudentId);
                                },
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Intro Header
                            _buildIntroHeader(activeChild),
                            const SizedBox(height: 16),

                            // State View (Loading, Error, Loaded/Empty)
                            _buildStateContent(
                              context,
                              certificatesState,
                              activeChild,
                              activeChildId,
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
        ),
      ),
    );
  }

  /// Top App Bar matching TrueLern header style
  Widget _buildTopAppBar(BuildContext context) {
    bool canPop = false;
    try {
      canPop = context.canPop();
    } catch (_) {
      canPop = false;
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: Color(0xCCFAF8FF),
            boxShadow: [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Back button or Drawer toggle
              canPop
                  ? IconButton(
                      key: const Key('certificates_back_button'),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF191C1E),
                        size: 20,
                      ),
                      onPressed: () => context.pop(),
                      tooltip: 'Back',
                    )
                  : IconButton(
                      key: const Key('certificates_drawer_button'),
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: Color(0xFF191C1E),
                        size: 24,
                      ),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      tooltip: 'Menu',
                    ),

              // Title
              Text(
                'Certificates',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF191C1E),
                ),
              ),

              // Right spacer or drawer trigger
              canPop
                  ? IconButton(
                      key: const Key('certificates_drawer_menu_button'),
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: Color(0xFF191C1E),
                        size: 22,
                      ),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      tooltip: 'Menu',
                    )
                  : const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  /// Header introducing certificates
  Widget _buildIntroHeader(ChildEntity? activeChild) {
    final name = activeChild?.firstName ?? 'Student';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Official Credentials',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1B23),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Verified certificates of course completion & academic achievements for $name.',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF64748B),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  /// State-based content builder
  Widget _buildStateContent(
    BuildContext context,
    CertificatesState state,
    ChildEntity? activeChild,
    String? activeChildId,
  ) {
    if (state is CertificatesLoading || state is CertificatesInitial) {
      return _buildLoadingSkeleton();
    }

    if (state is CertificatesError) {
      return _buildErrorCard(context, state.message, activeChildId);
    }

    if (state is CertificatesLoaded) {
      if (state.certificates.isEmpty) {
        return _buildEmptyState(activeChild?.firstName ?? 'your child');
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: state.certificates.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final cert = state.certificates[index];
          return _buildCertificateCard(context, cert, activeChild);
        },
      );
    }

    return const SizedBox.shrink();
  }

  /// Certificate card widget
  Widget _buildCertificateCard(
    BuildContext context,
    CertificateEntity cert,
    ChildEntity? child,
  ) {
    final formattedDate = cert.issueDate != null
        ? '${_monthName(cert.issueDate!.month)} ${cert.issueDate!.day}, ${cert.issueDate!.year}'
        : 'Date on record';

    return Container(
      key: Key('certificate_card_${cert.certificateId}'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top accent gradient bar
          Container(
            height: 4,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [Color(0xFF0037B1), Color(0xFF38BDF8)],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: Icon & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge icon container
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFBFDBFE),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Color(0xFF0037B1),
                        size: 26,
                      ),
                    ),

                    // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cert.status.toLowerCase() == 'issued'
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: cert.status.toLowerCase() == 'issued'
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFFDE68A),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cert.status.toLowerCase() == 'issued'
                                ? Icons.check_circle_rounded
                                : Icons.schedule_rounded,
                            size: 13,
                            color: cert.status.toLowerCase() == 'issued'
                                ? const Color(0xFF166534)
                                : const Color(0xFF92400E),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cert.statusLabel,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: cert.status.toLowerCase() == 'issued'
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF92400E),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Title
                Text(
                  cert.displayTitle,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),

                const SizedBox(height: 8),

                // Certificate Number & Issue Date Box
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_outlined,
                            size: 15,
                            color: Color(0xFF0037B1),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cert.certificateNumber,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            formattedDate,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action Button: Download if URL exists, else View Details
                SizedBox(
                  width: double.infinity,
                  child: cert.hasDownloadUrl
                      ? ElevatedButton.icon(
                          key: Key('btn_download_${cert.certificateId}'),
                          icon: const Icon(Icons.download_rounded, size: 18),
                          label: Text(
                            'Download Certificate',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0037B1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Downloading ${cert.certificateNumber}...'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        )
                      : OutlinedButton.icon(
                          key: Key('btn_view_details_${cert.certificateId}'),
                          icon: const Icon(
                            Icons.visibility_outlined,
                            size: 18,
                            color: Color(0xFF0037B1),
                          ),
                          label: Text(
                            'View Certificate Details',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0037B1),
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF0037B1)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            _showCertificateDetailsModal(
                              context,
                              cert,
                              child,
                              formattedDate,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Detail Modal Bottom Sheet
  void _showCertificateDetailsModal(
    BuildContext context,
    CertificateEntity cert,
    ChildEntity? child,
    String formattedDate,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grab handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Modal Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.military_tech_rounded,
                      color: Color(0xFF0037B1),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Certificate Credential',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'TrueLern Verified Academic Record',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 16),

              // Detail Key-Value Rows
              _buildModalRow('Certificate Number', cert.certificateNumber),
              _buildModalRow(
                'Student Recipient',
                child != null ? '${child.firstName} ${child.lastName}' : 'Student',
              ),
              _buildModalRow('Title', cert.displayTitle),
              _buildModalRow('Date Issued', formattedDate),
              _buildModalRow('Status', cert.statusLabel),
              _buildModalRow('Verification ID', cert.certificateId),

              const SizedBox(height: 16),

              // Informational alert note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This certificate has been officially registered and verified on the TrueLern academic ledger. Digital PDF will become downloadable once final approval stamp is applied.',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Close / Copy Button
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: cert.certificateNumber),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Certificate number copied to clipboard!'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Text(
                        'Copy Number',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0037B1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.of(modalContext).pop(),
                      child: Text(
                        'Close',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state when child has no certificates yet
  Widget _buildEmptyState(String childName) {
    return Container(
      key: const Key('certificates_empty_state'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFDBEAFE), width: 2),
            ),
            child: const Icon(
              Icons.workspace_premium_outlined,
              color: Color(0xFF0037B1),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Certificates Yet',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Official certificates earned by $childName for completed courses and milestones will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  /// Error state with retry
  Widget _buildErrorCard(
    BuildContext context,
    String message,
    String? activeChildId,
  ) {
    return Container(
      key: const Key('certificates_error_card'),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Unable to Load Certificates',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            key: const Key('certificates_retry_button'),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0037B1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            onPressed: () {
              ref
                  .read(certificatesControllerProvider.notifier)
                  .retry(childStudentId: activeChildId);
            },
          ),
        ],
      ),
    );
  }

  /// Skeleton loader
  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(2, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: 220,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }
}
