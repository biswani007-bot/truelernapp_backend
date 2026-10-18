import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../classes/presentation/widgets/classes_student_selector.dart';
import '../../../dashboard/domain/entities/child_entity.dart';
import '../../../dashboard/presentation/controllers/children_controller.dart';
import '../../../dashboard/presentation/controllers/children_state.dart';
import '../../../dashboard/presentation/widgets/parent_hamburger_drawer.dart';
import '../../../messages/presentation/controllers/messages_controller.dart';
import '../../../messages/presentation/controllers/messages_state.dart';
import '../../domain/entities/counseling_request_entity.dart';
import '../../domain/entities/counselor_entity.dart';
import '../controllers/counselor_controller.dart';
import '../controllers/counselor_state.dart';

/// Counselor Screen for TrueLern Mobile App.
///
/// Fully aligned with the Parent Web Portal Counselling Sessions experience:
/// - Header with back navigation and title 'Counselor'.
/// - Child selector using existing parent-child selection mechanism.
/// - Assigned Counselor card (name, role, specialization, Assigned Counselor status).
/// - Sessions & Requests section (parent note, session date, status badge, counselor info).
/// - Text chat-only functionality (Start Chat action opens counselor conversation).
/// - NO video calls, audio calls, join session buttons, or meeting links.
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
      final activeChildId = childrenState is ChildrenLoaded
          ? childrenState.activeChildId
          : null;
      ref
          .read(counselorControllerProvider.notifier)
          .loadCounselor(childStudentId: activeChildId);
    });
  }

  Future<void> _onRefresh() async {
    final childrenState = ref.read(childrenControllerProvider);
    final activeChildId = childrenState is ChildrenLoaded
        ? childrenState.activeChildId
        : null;
    await Future.wait([
      ref
          .read(counselorControllerProvider.notifier)
          .loadCounselor(childStudentId: activeChildId, isRefresh: true),
      ref
          .read(childrenControllerProvider.notifier)
          .loadChildren(isRefresh: true),
    ]);
  }

  void _openCounselorChat(
    BuildContext context,
    CounselorEntity counselor,
    CounselingRequestEntity request,
    String? studentId,
    String childName,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CounselorChatBottomSheet(
        counselor: counselor,
        request: request,
        studentId: studentId ?? '',
        childName: childName,
      ),
    );
  }

  void _openRequestSessionModal(
    BuildContext context,
    CounselorEntity counselor,
    List<ChildEntity> children,
    ChildEntity? activeChild,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RequestSessionBottomSheet(
        counselor: counselor,
        children: children,
        initialChild: activeChild,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final childrenState = ref.watch(childrenControllerProvider);
    final counselorState = ref.watch(counselorControllerProvider);

    final List<ChildEntity> children = childrenState is ChildrenLoaded
        ? childrenState.children
        : const [];
    final ChildEntity? activeChild = childrenState is ChildrenLoaded
        ? childrenState.activeChild
        : null;
    final String? activeChildId = activeChild?.studentId;

    // Listen for child switches
    ref.listen<ChildrenState>(childrenControllerProvider, (previous, next) {
      if (next is ChildrenLoaded) {
        final prevId = previous is ChildrenLoaded
            ? previous.activeChildId
            : null;
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
                              children,
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

  /// Top App Bar with back navigation and Counselor title
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

              // Title: Counselor
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
    List<ChildEntity> children,
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

      final assignedCounselor =
          state.assignedCounselor ?? state.primaryCounselor!;
      final availableCounselors = state.availableCounselors;

      // Filter requests for the active child if requests contain childId
      final displayedRequests = state.myRequests.where((req) {
        if (req.childId != null && activeChildId != null) {
          return req.childId == activeChildId;
        }
        return true;
      }).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Assigned Counselor Card
          _buildCounselorCard(
            context,
            assignedCounselor,
            children,
            activeChild,
          ),

          const SizedBox(height: 24),

          // 2. Available Counselors Section (e.g. Jack Sparrow, etc.)
          _buildAvailableCounselorsSection(
            context,
            availableCounselors,
            children,
            activeChild,
          ),

          const SizedBox(height: 24),

          // 3. Sessions & Requests Section
          _buildRequestsSection(
            context,
            assignedCounselor,
            displayedRequests,
            activeChild,
            activeChildId,
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  /// Assigned counselor card widget displaying real API fields
  Widget _buildCounselorCard(
    BuildContext context,
    CounselorEntity counselor,
    List<ChildEntity> children,
    ChildEntity? activeChild,
  ) {
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
                        border: Border.all(
                          color: const Color(0xFFDBEAFE),
                          width: 1.5,
                        ),
                      ),
                      child:
                          counselor.avatar != null &&
                              counselor.avatar!.isNotEmpty
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

                          // Assigned Counselor Status Badge
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

                // Specialization or department
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

                // Bio if available
                if (counselor.bio != null &&
                    counselor.bio!.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      counselor.bio!.trim(),
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12.5,
                        color: const Color(0xFF475569),
                        height: 1.45,
                      ),
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
                          const Icon(
                            Icons.email_outlined,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
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
                          const Icon(
                            Icons.phone_outlined,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
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

                // Request Session Button on Assigned Counselor Card
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: Key('request_session_button_${counselor.id}'),
                    icon: const Icon(Icons.calendar_month_rounded, size: 18),
                    label: const Text('Request Session'),
                    onPressed: () => _openRequestSessionModal(
                      context,
                      counselor,
                      children,
                      activeChild,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0037B1),
                      side: const BorderSide(
                        color: Color(0xFFBFDBFE),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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

  /// Available Counselors Section displaying all instructors/counselors returned by API
  Widget _buildAvailableCounselorsSection(
    BuildContext context,
    List<CounselorEntity> counselors,
    List<ChildEntity> children,
    ChildEntity? activeChild,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Other Available Counselors',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ),
            if (counselors.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
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
                  '${counselors.length}',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0037B1),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (counselors.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_search_rounded,
                  color: Color(0xFF94A3B8),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No other counselors are currently listed for booking.',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...counselors.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildAvailableCounselorCard(
                  context,
                  c,
                  children,
                  activeChild,
                ),
              )),
      ],
    );
  }

  /// Individual available counselor card with name, designation, specialization, bio, and Request Session button
  Widget _buildAvailableCounselorCard(
    BuildContext context,
    CounselorEntity counselor,
    List<ChildEntity> children,
    ChildEntity? activeChild,
  ) {
    return Container(
      key: Key('available_counselor_card_${counselor.id}'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar Circle
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child:
                      counselor.avatar != null && counselor.avatar!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                counselor.avatar!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFF475569),
                                  size: 28,
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                counselor.name.isNotEmpty
                                    ? counselor.name
                                        .substring(0, 1)
                                        .toUpperCase()
                                    : 'C',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0037B1),
                                ),
                              ),
                            ),
                ),
                const SizedBox(width: 14),

                // Name and Designation
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        counselor.name,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        counselor.displayDesignation,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Specialization chip
            if (counselor.specialization != null &&
                counselor.specialization!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.psychology_outlined,
                      size: 14,
                      color: Color(0xFF0037B1),
                    ),
                    const SizedBox(width: 6),
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

            // Bio if available
            if (counselor.bio != null && counselor.bio!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                counselor.bio!.trim(),
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 12.5,
                  color: const Color(0xFF475569),
                  height: 1.45,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Request Session Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: Key('request_session_button_${counselor.id}'),
                onPressed: () => _openRequestSessionModal(
                  context,
                  counselor,
                  children,
                  activeChild,
                ),
                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                label: const Text('Request Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0037B1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sessions & Requests Section matching Parent Web Portal
  Widget _buildRequestsSection(
    BuildContext context,
    CounselorEntity counselor,
    List<CounselingRequestEntity> requests,
    ChildEntity? activeChild,
    String? activeChildId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sessions & Requests',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            if (requests.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  '${requests.length}',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (requests.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.event_note_outlined,
                  size: 32,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 8),
                Text(
                  'No Counseling Requests Yet',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your scheduled counseling sessions and requests for ${activeChild?.firstName ?? 'your child'} will appear here.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          )
        else
          ...requests.map(
            (req) => _buildRequestCard(
              context,
              counselor,
              req,
              activeChild,
              activeChildId,
            ),
          ),
      ],
    );
  }

  /// Request card widget displaying parent note, date, status, counselor info,
  /// and Start Chat action (chat-only, absolutely no video/call options).
  Widget _buildRequestCard(
    BuildContext context,
    CounselorEntity counselor,
    CounselingRequestEntity req,
    ChildEntity? activeChild,
    String? activeChildId,
  ) {
    final statusUpper = req.statusLabel;
    final isAccepted = req.isAccepted;
    final isPending = req.isPending;
    final isRejected = req.isRejected;

    // Status chip colors
    final Color statusBg;
    final Color statusFg;
    final Color statusBorder;
    final IconData statusIcon;

    if (isAccepted) {
      statusBg = const Color(0xFFECFDF5);
      statusFg = const Color(0xFF065F46);
      statusBorder = const Color(0xFFA7F3D0);
      statusIcon = Icons.check_circle_rounded;
    } else if (isPending) {
      statusBg = const Color(0xFFFFFBEB);
      statusFg = const Color(0xFF92400E);
      statusBorder = const Color(0xFFFDE68A);
      statusIcon = Icons.hourglass_top_rounded;
    } else if (isRejected) {
      statusBg = const Color(0xFFFEF2F2);
      statusFg = const Color(0xFF991B1B);
      statusBorder = const Color(0xFFFECACA);
      statusIcon = Icons.cancel_rounded;
    } else {
      statusBg = const Color(0xFFF1F5F9);
      statusFg = const Color(0xFF475569);
      statusBorder = const Color(0xFFCBD5E1);
      statusIcon = Icons.info_outline_rounded;
    }

    final childName = req.childName ?? activeChild?.displayName ?? 'Student';
    final counselorName = req.counsellorName ?? counselor.name;
    final counselorRole =
        req.counsellorRole ?? counselor.displayDesignation;

    return Container(
      key: Key('counseling_request_card_${req.requestId}'),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Topic/Reason + Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    req.reason ?? req.notes ?? 'Counselling Session',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(color: statusBorder, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusFg),
                      const SizedBox(width: 4),
                      Text(
                        statusUpper,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusFg,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Parent's submitted note if provided
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notes_rounded,
                        size: 14,
                        color: Color(0xFF0037B1),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Parent Note',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    req.displayNote,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1E293B),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Metadata: Counselor info + Child associated + Session Date
            Row(
              children: [
                const Icon(
                  Icons.support_agent_rounded,
                  size: 15,
                  color: Color(0xFF0037B1),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$counselorName • $counselorRole',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                // Child Association
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.face_rounded,
                        size: 15,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Student: $childName',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Session Date
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      req.displayDate,
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

            const SizedBox(height: 14),

            // Action Row: Start Chat only when supported (chat-only, NO video call)
            if (req.canChat) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: Key('start_chat_button_${req.requestId}'),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: Text(
                    'Start Chat',
                    style: GoogleFonts.hankenGrotesk(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0037B1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    _openCounselorChat(
                      context,
                      counselor,
                      req,
                      activeChildId,
                      childName,
                    );
                  },
                ),
              ),
            ] else if (isPending) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Request is pending approval. Chat will unlock once accepted.',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (isRejected) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.highlight_off_rounded,
                      size: 14,
                      color: Color(0xFFB91C1C),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Request was declined. Please contact your academic advisor.',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF991B1B),
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

/// Dedicated Request Session Bottom Sheet matching the Parent Web Portal experience.
///
/// Features:
/// - Displays counselor name and designation
/// - Child dropdown populated from parent's linked children
/// - Preferred start date & time picker
/// - Preferred end date & time picker with end-after-start validation
/// - Required multiline reason / discussion topic text area
/// - Cancel and Submit Request actions with loading indicator and duplicate prevention
/// - Displays meaningful server/validation errors
class RequestSessionBottomSheet extends ConsumerStatefulWidget {
  const RequestSessionBottomSheet({
    super.key,
    required this.counselor,
    required this.children,
    this.initialChild,
    this.initialStart,
    this.initialEnd,
    this.initialReason,
  });

  final CounselorEntity counselor;
  final List<ChildEntity> children;
  final ChildEntity? initialChild;
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final String? initialReason;

  @override
  ConsumerState<RequestSessionBottomSheet> createState() =>
      _RequestSessionBottomSheetState();
}

class _RequestSessionBottomSheetState
    extends ConsumerState<RequestSessionBottomSheet> {
  String? _selectedChildId;
  DateTime? _proposedStart;
  DateTime? _proposedEnd;
  late final TextEditingController _reasonController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedChildId = widget.initialChild?.studentId ??
        (widget.children.isNotEmpty ? widget.children.first.studentId : null);
    _proposedStart = widget.initialStart;
    _proposedEnd = widget.initialEnd;
    _reasonController = TextEditingController(text: widget.initialReason ?? '');
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$day/$month/$year $hour:$minute $period';
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = DateTime.now();
    final initialDate = isStart
        ? (_proposedStart ?? now.add(const Duration(hours: 1)))
        : (_proposedEnd ??
            _proposedStart?.add(const Duration(hours: 1)) ??
            now.add(const Duration(hours: 2)));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      helpText: isStart ? 'Select Start Date' : 'Select End Date',
    );

    if (pickedDate == null || !mounted) return;

    final initialTime = TimeOfDay.fromDateTime(initialDate);
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: isStart ? 'Select Start Time' : 'Select End Time',
    );

    if (pickedTime == null || !mounted) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _errorMessage = null;
      if (isStart) {
        _proposedStart = combined;
        if (_proposedEnd != null && !_proposedEnd!.isAfter(_proposedStart!)) {
          _proposedEnd = _proposedStart!.add(const Duration(hours: 1));
        }
      } else {
        _proposedEnd = combined;
      }
    });
  }

  Future<void> _submit() async {
    if (_isLoading) return;

    if (_selectedChildId == null || _selectedChildId!.trim().isEmpty) {
      setState(
        () => _errorMessage =
            'Please select a child for the counselling session.',
      );
      return;
    }

    if (_proposedStart == null) {
      setState(
        () => _errorMessage = 'Please select a preferred start date and time.',
      );
      return;
    }

    if (_proposedEnd == null) {
      setState(
        () => _errorMessage = 'Please select a preferred end date and time.',
      );
      return;
    }

    if (!_proposedEnd!.isAfter(_proposedStart!)) {
      setState(
        () => _errorMessage =
            'Preferred end time must be after preferred start time.',
      );
      return;
    }

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(
        () => _errorMessage =
            'Please enter a reason or topic you would like to discuss.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(counselorControllerProvider.notifier).submitRequest(
        counsellorId: widget.counselor.id,
        studentId: _selectedChildId!,
        proposedStart: _proposedStart!,
        proposedEnd: _proposedEnd!,
        reason: reason,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Counselling session request submitted successfully!'),
          backgroundColor: Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e
            .toString()
            .replaceFirst('Exception: ', '')
            .replaceFirst('Failed to submit counselling request: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Request Session',
                  key: const Key('request_session_modal_title'),
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: const Color(0xFF64748B),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Form body
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: bottomInset + 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Counselor Info Preview
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              widget.counselor.name.isNotEmpty
                                  ? widget.counselor.name
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : 'C',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0037B1),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.counselor.name,
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                widget.counselor.displayDesignation,
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 1. Child Name Dropdown
                  Text(
                    'Child Name *',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: const Key('request_session_child_dropdown'),
                    initialValue: _selectedChildId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF0037B1),
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    hint: const Text('Select child'),
                    items: widget.children.map((child) {
                      final name = child.displayName;
                      return DropdownMenuItem<String>(
                        value: child.studentId,
                        child: Text(
                          name.isNotEmpty
                              ? name
                              : 'Student (${child.studentId})',
                          style: GoogleFonts.hankenGrotesk(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedChildId = val;
                        _errorMessage = null;
                      });
                    },
                  ),
                  const SizedBox(height: 18),

                  // 2. Preferred Start & End Pickers
                  Row(
                    children: [
                      // Preferred Start
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Preferred Start *',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              key: const Key('request_session_start_picker'),
                              onTap: () => _pickDateTime(isStart: true),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _proposedStart != null
                                        ? const Color(0xFF0037B1)
                                        : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 16,
                                      color: Color(0xFF0037B1),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _proposedStart != null
                                            ? _formatDateTime(_proposedStart!)
                                            : 'Select start',
                                        style: GoogleFonts.hankenGrotesk(
                                          fontSize: 12,
                                          fontWeight: _proposedStart != null
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: _proposedStart != null
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFF94A3B8),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Preferred End
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Preferred End *',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              key: const Key('request_session_end_picker'),
                              onTap: () => _pickDateTime(isStart: false),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _proposedEnd != null
                                        ? const Color(0xFF0037B1)
                                        : const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.schedule_rounded,
                                      size: 16,
                                      color: Color(0xFF0037B1),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _proposedEnd != null
                                            ? _formatDateTime(_proposedEnd!)
                                            : 'Select end',
                                        style: GoogleFonts.hankenGrotesk(
                                          fontSize: 12,
                                          fontWeight: _proposedEnd != null
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: _proposedEnd != null
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFF94A3B8),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 3. Reason / Topic
                  Text(
                    'Reason / What would you like to discuss? *',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    key: const Key('request_session_reason_input'),
                    controller: _reasonController,
                    minLines: 3,
                    maxLines: 5,
                    style: GoogleFonts.hankenGrotesk(fontSize: 14),
                    decoration: InputDecoration(
                      hintText:
                          'Please describe the topics, challenges, or academic guidance needed...',
                      hintStyle: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        color: const Color(0xFF94A3B8),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFF0037B1),
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Error Banner
                  if (_errorMessage != null) ...[
                    Container(
                      key: const Key('request_session_error_banner'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 18,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                color: const Color(0xFFDC2626),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: OutlinedButton(
                          key: const Key('request_session_cancel_button'),
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Submit Request Button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          key: const Key('request_session_submit_button'),
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0037B1),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF94A3B8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Submit Request',
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
            ),
          ),
        ],
      ),
    );
  }
}

/// Dedicated Chat-Only Conversation Bottom Sheet for Counseling Sessions.
///
/// Features:
/// - Connects to the existing TrueLern messaging repository / controller.
/// - Uses the actual counselor name, role, child association, and request note.
/// - Shows message history with loading, empty, and error states.
/// - Supports sending messages with subject context.
/// - Preserves authentication and chat history.
/// - Completely text chat-only: NO video calls, NO audio calls, NO join session.
class CounselorChatBottomSheet extends ConsumerStatefulWidget {
  const CounselorChatBottomSheet({
    super.key,
    required this.counselor,
    required this.request,
    required this.studentId,
    required this.childName,
  });

  final CounselorEntity counselor;
  final CounselingRequestEntity request;
  final String studentId;
  final String childName;

  @override
  ConsumerState<CounselorChatBottomSheet> createState() =>
      _CounselorChatBottomSheetState();
}

class _CounselorChatBottomSheetState
    extends ConsumerState<CounselorChatBottomSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSendingLocal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.studentId.isNotEmpty) {
        ref
            .read(messagesControllerProvider.notifier)
            .loadMessages(studentId: widget.studentId);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSendingLocal) return;

    setState(() => _isSendingLocal = true);
    try {
      final subject = 'Counseling Session: ${widget.request.displayNote}';
      final success = await ref
          .read(messagesControllerProvider.notifier)
          .sendMessage(message: text, subject: subject);

      if (success && mounted) {
        _textController.clear();
        // Scroll to bottom
        await Future.delayed(const Duration(milliseconds: 100));
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingLocal = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(messagesControllerProvider);
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final maxSheetHeight = mediaQuery.size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Top Drag Handle
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 2. Chat Header: Counselor Details + Close Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Counselor Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: widget.counselor.avatar != null &&
                          widget.counselor.avatar!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            widget.counselor.avatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.support_agent_rounded,
                              color: Color(0xFF0037B1),
                              size: 24,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.support_agent_rounded,
                          color: Color(0xFF0037B1),
                          size: 24,
                        ),
                ),
                const SizedBox(width: 12),

                // Counselor Name & Role
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.counselor.name,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: Color(0xFF0284C7),
                          ),
                        ],
                      ),
                      Text(
                        '${widget.counselor.displayDesignation} • ${widget.childName}',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Open Full Inbox Button
                IconButton(
                  key: const Key('counselor_chat_full_inbox_button'),
                  icon: const Icon(
                    Icons.open_in_new_rounded,
                    size: 20,
                    color: Color(0xFF0037B1),
                  ),
                  tooltip: 'Open Full Inbox',
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(AppRoutePaths.parentMessages);
                  },
                ),

                // Close Button
                IconButton(
                  key: const Key('counselor_chat_close_button'),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF64748B),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          // 3. Counseling Session Context Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 14,
                  color: Color(0xFF0037B1),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Topic: ${widget.request.displayNote}',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF334155),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'TEXT ONLY',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // 4. Message History View
          Expanded(child: _buildMessagesContent(messagesState)),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // 5. Message Input Composer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        key: const Key('counselor_chat_input_field'),
                        controller: _textController,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 14,
                          color: const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Message ${widget.counselor.name}...',
                          hintStyle: GoogleFonts.hankenGrotesk(
                            fontSize: 13,
                            color: const Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0037B1),
                      shape: BoxShape.circle,
                    ),
                    child: _isSendingLocal
                        ? const Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          )
                        : IconButton(
                            key: const Key('counselor_chat_send_button'),
                            icon: const Icon(
                              Icons.send_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            onPressed: _sendMessage,
                            tooltip: 'Send',
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesContent(MessagesState state) {
    if (state is MessagesLoading || state is MessagesInitial) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0037B1)),
        ),
      );
    }

    if (state is MessagesError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: Color(0xFFDC2626),
              ),
              const SizedBox(height: 8),
              Text(
                'Unable to load messages',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0037B1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                onPressed: () {
                  if (widget.studentId.isNotEmpty) {
                    ref
                        .read(messagesControllerProvider.notifier)
                        .loadMessages(
                          studentId: widget.studentId,
                          isRefresh: true,
                        );
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    if (state is MessagesLoaded) {
      final messages = state.data.messages;
      if (messages.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.forum_outlined,
                    color: Color(0xFF0037B1),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No Messages Yet',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Start your counseling conversation with ${widget.counselor.name} by sending a message below.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        key: const Key('counselor_messages_list'),
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = messages[index];
          final isParent = msg.isParent;

          return Align(
            alignment: isParent ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.76,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isParent
                    ? const Color(0xFF0037B1)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isParent ? 14 : 2),
                  bottomRight: Radius.circular(isParent ? 2 : 14),
                ),
              ),
              child: Column(
                crossAxisAlignment: isParent
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isParent) ...[
                    Text(
                      msg.senderName ?? widget.counselor.name,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0037B1),
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    msg.message,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      color: isParent ? Colors.white : const Color(0xFF0F172A),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(msg.createdAt),
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 10,
                      color: isParent
                          ? Colors.white.withValues(alpha: 0.7)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
