import 'dart:ui';
import 'package:flutter/material.dart';
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
import '../../domain/entities/counseling_request_entity.dart';
import '../../domain/entities/counselor_entity.dart';
import '../controllers/counselor_controller.dart';
import '../controllers/counselor_state.dart';

/// Counselor Screen for the TrueLern mobile app.
///
/// Designed cleanly to match TrueLern mobile aesthetics (frosted app bar, canvas gradient,
/// student selector pill, clean cards, status pills, and empty states).
class ParentCounselorScreen extends ConsumerStatefulWidget {
  const ParentCounselorScreen({super.key});

  @override
  ConsumerState<ParentCounselorScreen> createState() =>
      _ParentCounselorScreenState();
}

class _ParentCounselorScreenState extends ConsumerState<ParentCounselorScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final childrenState = ref.read(childrenControllerProvider);
      final activeChildId =
          childrenState is ChildrenLoaded ? childrenState.activeChildId : null;
      ref
          .read(counselorControllerProvider.notifier)
          .loadCounselor(childStudentId: activeChildId);
    });
  }

  Future<void> _onRefresh() async {
    final childrenState = ref.read(childrenControllerProvider);
    final activeChildId =
        childrenState is ChildrenLoaded ? childrenState.activeChildId : null;
    await Future.wait([
      ref
          .read(counselorControllerProvider.notifier)
          .loadCounselor(childStudentId: activeChildId, isRefresh: true),
      ref.read(childrenControllerProvider.notifier).loadChildren(isRefresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final childrenState = ref.watch(childrenControllerProvider);
    final counselorState = ref.watch(counselorControllerProvider);

    final List<ChildEntity> children =
        childrenState is ChildrenLoaded ? childrenState.children : const [];
    final ChildEntity? activeChild =
        childrenState is ChildrenLoaded ? childrenState.activeChild : null;
    final String? activeChildId = activeChild?.studentId;

    // Listen for child switches
    ref.listen<ChildrenState>(childrenControllerProvider, (previous, next) {
      if (next is ChildrenLoaded) {
        final prevId = previous is ChildrenLoaded ? previous.activeChildId : null;
        if (prevId != next.activeChildId && next.activeChildId != null) {
          ref
              .read(counselorControllerProvider.notifier)
              .loadCounselor(childStudentId: next.activeChildId);
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

              // Scrollable Body with Pull-to-Refresh
              Expanded(
                child: AppRefreshIndicator(
                  onRefresh: _onRefresh,
                  child: SingleChildScrollView(
                    key: const Key('counselor_scroll_view'),
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

                            // Intro Section Header
                            _buildIntroHeader(activeChild),
                            const SizedBox(height: 16),

                            // State View (Loading, Error, Loaded / Empty)
                            _buildStateContent(
                              context,
                              counselorState,
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

  /// Frosted glass top App Bar matching TrueLern style
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
                      key: const Key('counselor_back_button'),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF191C1E),
                        size: 20,
                      ),
                      onPressed: () => context.pop(),
                      tooltip: 'Back',
                    )
                  : IconButton(
                      key: const Key('counselor_drawer_button'),
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
                'Counselor',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF191C1E),
                ),
              ),

              // Right spacer or Drawer trigger
              canPop
                  ? IconButton(
                      key: const Key('counselor_drawer_menu_button'),
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

  Widget _buildIntroHeader(ChildEntity? activeChild) {
    final name = activeChild?.firstName ?? 'Student';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Academic Guidance',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1B23),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Personalized advising, program support, and academic guidance for $name.',
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

  Widget _buildStateContent(
    BuildContext context,
    CounselorState state,
    ChildEntity? activeChild,
    String? activeChildId,
  ) {
    if (state is CounselorLoading || state is CounselorInitial) {
      return _buildLoadingSkeleton();
    }

    if (state is CounselorError) {
      return _buildErrorCard(context, state.message, activeChildId);
    }

    if (state is CounselorLoaded) {
      if (!state.hasCounselor) {
        return _buildEmptyState(activeChild?.firstName ?? 'your child');
      }

      final counselor = state.primaryCounselor!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCounselorCard(context, counselor),
          if (state.myRequests.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Sessions & Requests',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            ...state.myRequests.map((req) => _buildRequestCard(context, req)),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }

  /// Counselor card widget displaying real API fields
  Widget _buildCounselorCard(BuildContext context, CounselorEntity counselor) {
    return Container(
      key: Key('counselor_card_${counselor.id}'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          // Accent gradient top bar
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar / Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
                      ),
                      child: counselor.avatar != null && counselor.avatar!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                counselor.avatar!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFF0037B1),
                                  size: 30,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.support_agent_rounded,
                              color: Color(0xFF0037B1),
                              size: 32,
                            ),
                    ),
                    const SizedBox(width: 16),

                    // Name and Designation
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  counselor.name,
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: Color(0xFF0284C7),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            counselor.displayDesignation,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Role / Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(9999),
                              border: Border.all(
                                color: const Color(0xFFBFDBFE),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              'Assigned Counselor',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0037B1),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (counselor.specialization != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.psychology_outlined,
                          size: 16,
                          color: Color(0xFF0037B1),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Specialization: ${counselor.specialization}',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Contact info if available from API
                if (counselor.hasContactInfo) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                  const SizedBox(height: 12),
                  if (counselor.email != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              counselor.email!,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (counselor.phone != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              counselor.phone!,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Request / session card widget
  Widget _buildRequestCard(BuildContext context, CounselingRequestEntity req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                req.reason ?? 'Counselling Session',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  req.statusLabel,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          if (req.proposedStart != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  '${req.proposedStart!.day}/${req.proposedStart!.month}/${req.proposedStart!.year}',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// TrueLern empty state when no counselor is currently assigned
  Widget _buildEmptyState(String childName) {
    return Container(
      key: const Key('counselor_empty_state'),
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
              Icons.support_agent_outlined,
              color: Color(0xFF0037B1),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Counselor Assigned',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Official academic counselor guidance for $childName will appear here once allocated by admissions or your academic mentor.',
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
      key: const Key('counselor_error_card'),
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
            'Unable to Load Counselor',
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
            key: const Key('counselor_retry_button'),
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
                  .read(counselorControllerProvider.notifier)
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
      children: List.generate(1, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 160,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
