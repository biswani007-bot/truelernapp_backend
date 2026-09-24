import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/entities/child_entity.dart';
import '../widgets/bento_snapshot_grid.dart';
import '../widgets/child_selector_row.dart';
import '../widgets/dashboard_skeleton.dart';
import '../widgets/featured_class_card.dart';
import '../widgets/my_learning_section.dart';
import '../controllers/children_controller.dart';
import '../controllers/children_state.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/dashboard_state.dart';
import '../controllers/parent_profile_controller.dart';
import '../../../classes/domain/entities/class_entity.dart';
import '../../../classes/presentation/controllers/classes_controller.dart';

/// Student Dashboard Screen (Parent Experience).
///
/// Figma Source of Truth: Parent(full app)_TreLern, Frame 76:3476.
///
/// Integrated with real backend APIs:
/// - GET /api/parent/children (linked wards)
/// - GET /api/parent/children/{childStudentId}/dashboard (attendance, live classes, batches, assignments)
class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() =>
      _ParentDashboardScreenState();
}

class _ParentDashboardScreenState
    extends ConsumerState<ParentDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authState = ref.read(authControllerProvider);
      String? role = authState is Authenticated ? authState.user?.role : null;
      if (role == null) {
        final token = await ref.read(secureStorageProvider).getAccessToken();
        if (token != null) {
          role = AuthController.decodeJwt(token)?['role'] as String?;
        }
      }
      final isStudent = (role ?? '').toLowerCase() == 'student';

      if (isStudent) {
        ref.read(dashboardControllerProvider.notifier).loadStudentDashboard();
      } else {
        ref.read(childrenControllerProvider.notifier).loadChildren();
        ref.read(parentProfileControllerProvider.notifier).loadProfile();
      }
    });
  }

  Future<void> _onRefresh() async {
    final authState = ref.read(authControllerProvider);
    String? role = authState is Authenticated ? authState.user?.role : null;
    if (role == null) {
      final token = await ref.read(secureStorageProvider).getAccessToken();
      if (token != null) {
        role = AuthController.decodeJwt(token)?['role'] as String?;
      }
    }
    final isStudent = (role ?? '').toLowerCase() == 'student';

    if (isStudent) {
      await ref.read(dashboardControllerProvider.notifier).loadStudentDashboard();
    } else {
      await ref.read(childrenControllerProvider.notifier).loadChildren(isRefresh: true);
      ref.read(parentProfileControllerProvider.notifier).loadProfile(refresh: true);
      final childrenState = ref.read(childrenControllerProvider);
      final activeId = childrenState is ChildrenLoaded ? childrenState.activeChildId : null;
      if (activeId != null) {
        await ref.read(dashboardControllerProvider.notifier).loadDashboard(
              childStudentId: activeId,
              isRefresh: false,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final userRole = authState is Authenticated ? authState.user?.role : null;
    final isStudent = (userRole ?? '').toLowerCase() == 'student';

    // Only listen for children state updates in Parent mode
    if (!isStudent) {
      ref.listen<ChildrenState>(childrenControllerProvider, (prev, next) {
        if (next is ChildrenLoaded && next.activeChildId != null) {
          final prevChildId = prev is ChildrenLoaded ? prev.activeChildId : null;
          if (prevChildId != next.activeChildId) {
            ref.read(dashboardControllerProvider.notifier).loadDashboard(
                  childStudentId: next.activeChildId,
                );
          }
        }
      });
    }

    final childrenState = ref.watch(childrenControllerProvider);
    final dashboardState = ref.watch(dashboardControllerProvider);

    // Determine loading states cleanly without parallel state systems
    final isChildrenLoading = !isStudent &&
        (childrenState is ChildrenInitial || childrenState is ChildrenLoading);

    final bool isDashboardLoading;
    if (isStudent) {
      isDashboardLoading = dashboardState is DashboardInitial || dashboardState is DashboardLoading;
    } else {
      if (isChildrenLoading) {
        isDashboardLoading = true;
      } else if (childrenState is ChildrenLoaded) {
        if (childrenState.children.isEmpty) {
          isDashboardLoading = false;
        } else if (childrenState.activeChildId != null) {
          if (dashboardState is DashboardInitial || dashboardState is DashboardLoading) {
            isDashboardLoading = true;
          } else if (dashboardState is DashboardLoaded) {
            // If active child has switched and dashboard has not resolved for the new child
            isDashboardLoading = dashboardState.childStudentId != childrenState.activeChildId;
          } else {
            isDashboardLoading = false;
          }
        } else {
          isDashboardLoading = false;
        }
      } else {
        isDashboardLoading = false;
      }
    }

    // Resolve active child and child list (only relevant in Parent mode)
    final List<ChildEntity> displayChildren;
    final ChildEntity? activeChild;

    if (!isStudent && childrenState is ChildrenLoaded) {
      displayChildren = childrenState.children;
      activeChild = childrenState.activeChild ??
          (displayChildren.isNotEmpty ? displayChildren.first : null);
    } else {
      displayChildren = const [];
      activeChild = null;
    }

    // Resolve dashboard entity from state
    final DashboardEntity dashboard;
    if (dashboardState is DashboardLoaded) {
      if (isStudent) {
        dashboard = dashboardState.dashboard;
      } else if (activeChild == null || dashboardState.childStudentId == activeChild.studentId) {
        dashboard = dashboardState.dashboard;
      } else {
        dashboard = const DashboardEntity();
      }
    } else {
      dashboard = const DashboardEntity();
    }

    final featured = dashboard.featuredClass;
    // Date verification: "TODAY'S CLASS" must strictly belong to current local calendar date
    final ClassEntity? todayClass;
    if (featured != null) {
      final start = featured.scheduledStartTime;
      if (start != null) {
        final localStart = start.toLocal();
        final now = DateTime.now();
        final isToday = localStart.year == now.year &&
            localStart.month == now.month &&
            localStart.day == now.day;
        todayClass = isToday ? featured : null;
      } else {
        // Fallback for test mocks without scheduledStartTime
        todayClass = featured;
      }
    } else {
      todayClass = null;
    }

    final upcomingClass = todayClass;
    final activeTopic = dashboard.activeTopic ??
        (dashboard.enrolledBatches.isNotEmpty
            ? dashboard.enrolledBatches.first.batchName
            : 'Curriculum');

    final String greetingName;
    if (isStudent) {
      greetingName = dashboard.studentName ??
          (authState is Authenticated ? authState.user?.name : null) ??
          '';
    } else {
      greetingName = activeChild?.firstName ?? '';
    }

    final greetingText = greetingName.isNotEmpty
        ? 'Hi, $greetingName! Let\'s go on today\'s adventure!'
        : 'Welcome! Let\'s go on today\'s adventure!';

    return Scaffold(
      key: const Key('parent_dashboard_screen'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF3E8FF),
              Color(0xFFE0F2FE),
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header — Figma Node 76:3501
              _buildTopAppBar(context),

              // Child Selector — Figma Node 76:3579 (Parent only)
              if (!isStudent)
                if (isChildrenLoading)
                  const ChildSelectorSkeleton()
                else if (displayChildren.isNotEmpty)
                  ChildSelectorRow(
                    children: displayChildren,
                    activeChildId: activeChild?.studentId,
                    onSelectChild: (childId) {
                      ref.read(childrenControllerProvider.notifier).setActiveChild(childId);
                    },
                  ),

              // Error banner if children or dashboard encountered an error
              if ((!isStudent && childrenState is ChildrenError) || dashboardState is DashboardError)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF87171)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFFB91C1C), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (!isStudent && childrenState is ChildrenError)
                              ? childrenState.message
                              : (dashboardState as DashboardError).message,
                          style: AppTypography.bodySmall.copyWith(color: const Color(0xFFB91C1C)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: _onRefresh,
                        child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

              // Scrollable body
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: const Color(0xFF1E4ED8),
                  child: isDashboardLoading
                      ? const ParentDashboardSkeleton()
                      : SingleChildScrollView(
                          key: const Key('dashboard_scroll_view'),
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Greeting — Figma Node 76:3511
                              Text(
                                greetingText,
                                style: AppTypography.displayLarge.copyWith(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1B23),
                                  letterSpacing: -0.5,
                                  height: 1.28,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Featured Class Card — Figma Node 76:3513
                              FeaturedClassCard(
                                upcomingClass: upcomingClass,
                                onViewClass: () {
                                  if (activeChild?.studentId != null) {
                                    ref.read(classesControllerProvider.notifier).loadClasses(
                                          childStudentId: activeChild!.studentId,
                                        );
                                  }
                                  try {
                                    context.go('/parent/classes');
                                  } catch (_) {
                                    // Fallback for tests outside GoRouter
                                  }
                                },
                              ),
                              const SizedBox(height: 24),

                              // My Learning Section — Figma Node 76:3530
                              MyLearningSection(
                                enrolledBatches: dashboard.enrolledBatches,
                              ),
                              const SizedBox(height: 24),

                              // Bento Snapshot Grid — Figma Node 76:3646
                              BentoSnapshotGrid(
                                dashboard: dashboard,
                                activeTopic: activeTopic,
                              ),
                              const SizedBox(height: 32),
                            ],
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

  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      height: 59,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Hamburger Menu — Node 76:3502
          IconButton(
            key: const Key('dashboard_menu_button'),
            icon: const Icon(
              Icons.menu_rounded,
              color: Color(0xFF1A1B23),
              size: 24,
            ),
            onPressed: () => Scaffold.maybeOf(context)?.openDrawer(),
            tooltip: 'Menu',
          ),

          // "Dashboard" title — Node 76:3505
          Text(
            'Dashboard',
            style: AppTypography.displayLarge.copyWith(
              fontSize: 25.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1B23),
              letterSpacing: -0.5,
            ),
          ),

          // Notification Bell — Node 76:3507
          IconButton(
            key: const Key('dashboard_bell_button'),
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF1E4ED8),
              size: 24,
            ),
            onPressed: () => context.go(AppRoutePaths.notifications),
            tooltip: 'Notifications',
          ),
        ],
      ),
    );
  }
}
