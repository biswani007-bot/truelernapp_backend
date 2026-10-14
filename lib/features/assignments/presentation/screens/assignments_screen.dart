import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../dashboard/domain/entities/child_entity.dart';
import '../../../dashboard/presentation/controllers/children_controller.dart';
import '../../../dashboard/presentation/controllers/children_state.dart';
import '../../../classes/presentation/widgets/classes_student_selector.dart';
import '../../domain/entities/assignment_entity.dart';
import '../controllers/assignments_controller.dart';
import '../controllers/assignments_state.dart';
import '../widgets/assignment_card.dart';
import '../widgets/assignments_skeleton.dart';
import '../widgets/competitions_banner.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';

/// SCR-18 My Assignments Screen (Figma Node 76:1943 "Assignments").
///
/// Governance & Fidelity:
/// - Background gradient matching Figma: linear-gradient(134.58deg, #F3E8FF 0%, #E0F2FE 50%, #FFFFFF 100%).
/// - TopAppBar with hamburger drawer trigger, centered title "My Assignments" (24px Bold #191C1E), and notification bell button.
/// - Centered Student Selector pill (ClassesStudentSelector) when multiple children are present.
/// - Filter Tabs: All, Pending, Overdue, Completed pills.
/// - Strict child isolation:
///   - Always uses currently selected child's studentId.
///   - Immediately clears previous child's assignments and displays skeleton on child switch.
///   - Empty state when active child has no assignments in the selected filter.
/// - Upcoming Competitions banner (Deep blue #0037B1 card with trophy watermark and Register Now pill).
class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  static const _filters = ['All', 'Pending', 'Overdue', 'Completed'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        _initialize();
      }
    });
  }

  void _initialize() {
    final childrenState = ref.read(childrenControllerProvider);
    String? activeChildId;
    if (childrenState is ChildrenLoaded) {
      activeChildId = childrenState.activeChildId;
    }
    final currentState = ref.read(assignmentsControllerProvider);
    if (currentState is! AssignmentsLoaded ||
        currentState.childStudentId != activeChildId) {
      ref
          .read(assignmentsControllerProvider.notifier)
          .loadAssignments(childStudentId: activeChildId, isRefresh: true);
    }
  }

  void _retry() {
    final childrenState = ref.read(childrenControllerProvider);
    String? activeChildId;
    if (childrenState is ChildrenLoaded) {
      activeChildId = childrenState.activeChildId;
    }
    ref
        .read(assignmentsControllerProvider.notifier)
        .loadAssignments(childStudentId: activeChildId, isRefresh: true);
  }

  Future<void> _onRefresh() async {
    final childrenState = ref.read(childrenControllerProvider);
    String? activeChildId;
    if (childrenState is ChildrenLoaded) {
      activeChildId = childrenState.activeChildId;
    }
    await Future.wait([
      ref
          .read(assignmentsControllerProvider.notifier)
          .loadAssignments(childStudentId: activeChildId, isRefresh: true),
      ref
          .read(childrenControllerProvider.notifier)
          .loadChildren(isRefresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // Listen to ChildrenController to trigger instant load on child switch
    ref.listen<ChildrenState>(childrenControllerProvider, (previous, next) {
      if (next is ChildrenLoaded) {
        final prevId = previous is ChildrenLoaded
            ? previous.activeChildId
            : null;
        if (next.activeChildId != prevId) {
          ref
              .read(assignmentsControllerProvider.notifier)
              .loadAssignments(
                childStudentId: next.activeChildId,
                isRefresh: true,
              );
        }
      }
    });

    final childrenState = ref.watch(childrenControllerProvider);
    final ChildEntity? activeChild = childrenState is ChildrenLoaded
        ? childrenState.activeChild
        : null;
    final List<ChildEntity> children = childrenState is ChildrenLoaded
        ? childrenState.children
        : const [];
    final String? activeChildId = childrenState is ChildrenLoaded
        ? childrenState.activeChildId
        : null;

    final assignmentsState = ref.watch(assignmentsControllerProvider);

    return Scaffold(
      key: const Key('assignments_screen'),
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background Gradient matching Figma:
          // linear-gradient(134.58deg, #F3E8FF 0%, #E0F2FE 50%, #FFFFFF 100%)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.7, -0.7),
                  end: Alignment(0.7, 0.7),
                  colors: [
                    Color(0xFFF3E8FF), // 0%
                    Color(0xFFE0F2FE), // 50%
                    Color(0xFFFFFFFF), // 100%
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Main Scrollable Area
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top App Bar matching Figma Node 76:1967
                _buildTopAppBar(context),

                // Content
                Expanded(
                  child: AppRefreshIndicator(
                    onRefresh: _onRefresh,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom:
                            96, // extra clearance above persistent bottom bar
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 448),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Student Selector (Node 76:1831) when parent has multiple wards
                              if (activeChild != null &&
                                  children.length > 1) ...[
                                ClassesStudentSelector(
                                  activeChild: activeChild,
                                  children: children,
                                  onChildSelected: (newStudentId) {
                                    ref
                                        .read(
                                          childrenControllerProvider.notifier,
                                        )
                                        .setActiveChild(newStudentId);
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Horizontal Filter Tabs (Node 76:1977)
                              _buildFilterTabs(assignmentsState),
                              const SizedBox(height: 24),

                              // Assignment Cards List (Node 76:1987)
                              _buildCardsList(assignmentsState, activeChildId),
                              const SizedBox(height: 32),

                              // Upcoming Competitions Section (Node 76:2045)
                              CompetitionsBanner(
                                onRegisterTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Registration confirmed for Grandmaster Quiz!',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
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
        ],
      ),
    );
  }

  /// Top App Bar matching Figma Node 76:1967
  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Menu Hamburger Button (Node 76:1968)
          IconButton(
            key: const Key('assignments_menu_button'),
            icon: const Icon(
              Icons.menu_rounded,
              color: Color(0xFF191C1E),
              size: 24,
            ),
            onPressed: () {
              Scaffold.maybeOf(context)?.openDrawer();
            },
            tooltip: 'Menu',
          ),

          // Center: Title "My Assignments" (Node 76:1972)
          Text(
            'My Assignments',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 25.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF191C1E),
              height: 32 / 24,
            ),
          ),

          // Right: Notification Bell Button (Node 76:1973)
          IconButton(
            key: const Key('assignments_notifications_button'),
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF191C1E),
              size: 24,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new notifications'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
    );
  }

  /// Horizontal scrollable filter pills (Node 76:1977)
  Widget _buildFilterTabs(AssignmentsState state) {
    final currentFilter = state is AssignmentsLoaded
        ? state.selectedFilter
        : 'All';

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == currentFilter;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              key: Key('filter_tab_$filter'),
              borderRadius: BorderRadius.circular(9999),
              onTap: () {
                ref
                    .read(assignmentsControllerProvider.notifier)
                    .setFilter(filter);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0037B1) : Colors.white,
                  borderRadius: BorderRadius.circular(9999),
                  border: isSelected
                      ? null
                      : Border.all(color: const Color(0xFFC4C5D7), width: 1),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x1A000000), // rgba(0, 0, 0, 0.1)
                            blurRadius: 6,
                            offset: Offset(0, 4),
                            spreadRadius: -1,
                          ),
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                            spreadRadius: -2,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF434655),
                      letterSpacing: 0.1,
                      height: 20 / 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Cards list rendering the filtered assignments or skeletons
  Widget _buildCardsList(AssignmentsState state, String? activeChildId) {
    if (state is AssignmentsInitial || state is AssignmentsLoading) {
      return const AssignmentsSkeleton();
    }

    // Guard: if state was loaded for a different child, show skeleton immediately
    if (state is AssignmentsLoaded &&
        activeChildId != null &&
        state.childStudentId != null &&
        state.childStudentId != activeChildId) {
      return const AssignmentsSkeleton();
    }

    if (state is AssignmentsError) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Color(0xFFBA1A1A),
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load assignments',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1B23),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                color: const Color(0xFF747686),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                key: const Key('assignments_retry_button'),
                onPressed: _retry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0037B1),
                  foregroundColor: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Retry',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Filter assignments strictly by active child ID (defense-in-depth)
    final assignments = state is AssignmentsLoaded
        ? state.filteredAssignments
              .where(
                (a) =>
                    activeChildId == null ||
                    a.childStudentId == null ||
                    a.childStudentId == activeChildId,
              )
              .toList()
        : const <AssignmentEntity>[];

    if (assignments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.assignment_turned_in_outlined,
              size: 48,
              color: Color(0xFF747686),
            ),
            const SizedBox(height: 12),
            Text(
              'No assignments found',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1B23),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'There are no assignments in this category.',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                color: const Color(0xFF747686),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: assignments.map((assignment) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: AssignmentCard(
            assignment: assignment,
            onActionTap: () {
              if (assignment.status == AssignmentStatus.completed) {
                context.go(
                  '/parent/assignments/${assignment.id}/submitted',
                  extra: assignment,
                );
              } else {
                context.go(
                  '/parent/assignments/${assignment.id}/submission',
                  extra: assignment,
                );
              }
            },
          ),
        );
      }).toList(),
    );
  }
}
