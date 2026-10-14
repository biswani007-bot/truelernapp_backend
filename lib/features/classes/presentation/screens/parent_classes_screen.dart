import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../dashboard/domain/entities/child_entity.dart';
import '../../../dashboard/presentation/controllers/children_controller.dart';
import '../../../dashboard/presentation/controllers/children_state.dart';
import '../../domain/entities/class_entity.dart';
import '../controllers/classes_controller.dart';
import '../controllers/classes_state.dart';
import '../widgets/classes_date_navigator.dart';
import '../widgets/classes_event_card.dart';
import '../widgets/classes_filter_tabs.dart';
import '../widgets/classes_skeleton.dart';
import '../widgets/classes_student_selector.dart';
import '../widgets/empty_classes_widget.dart';
import '../widgets/error_classes_widget.dart';

/// Provider for current device date (defaults to DateTime.now() in local timezone; overrideable for testing).
final currentDeviceDateProvider = Provider<DateTime>((ref) {
  return DateTime.now();
});

/// Parent Classes Schedule Screen (SCR-13).
///
/// Figma Source of Truth: `Parent(full app)_TreLern`, Frame 76:1820 (`Classes Shedule`, 390 × 952).
/// Authoritative API: GET `/api/parent/children/{childStudentId}/live-classes`
/// Authentication: Bearer token (Parent role) attached via AuthInterceptor.
class ParentClassesScreen extends ConsumerStatefulWidget {
  const ParentClassesScreen({super.key});

  @override
  ConsumerState<ParentClassesScreen> createState() =>
      _ParentClassesScreenState();
}

class _ParentClassesScreenState extends ConsumerState<ParentClassesScreen> {
  late DateTime _selectedDate;
  String _selectedFilter = 'Upcoming';
  GoRouterDelegate? _routerDelegate;
  String? _lastObservedGlobalPath;

  DateTime _getToday() {
    final now = ref.read(currentDeviceDateProvider);
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = _getToday();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final childrenState = ref.read(childrenControllerProvider);
      if (childrenState is! ChildrenLoaded) {
        ref.read(childrenControllerProvider.notifier).loadChildren();
      } else if (childrenState.activeChildId != null) {
        final classesState = ref.read(classesControllerProvider);
        final shouldLoad =
            classesState is! ClassesLoaded ||
            classesState.childStudentId != childrenState.activeChildId;
        if (shouldLoad && classesState is! ClassesLoading) {
          ref
              .read(classesControllerProvider.notifier)
              .loadClasses(childStudentId: childrenState.activeChildId);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribeToRouter();
  }

  void _subscribeToRouter() {
    try {
      final router = GoRouter.of(context);
      if (_routerDelegate != router.routerDelegate) {
        _routerDelegate?.removeListener(_onRouteChanged);
        _routerDelegate = router.routerDelegate;
        _routerDelegate?.addListener(_onRouteChanged);
        _lastObservedGlobalPath =
            _routerDelegate?.currentConfiguration.uri.path;
      }
    } catch (_) {}
  }

  void _onRouteChanged() {
    try {
      final currentPath = _routerDelegate?.currentConfiguration.uri.path ?? '';
      if (_lastObservedGlobalPath != null &&
          _lastObservedGlobalPath != currentPath) {
        if (!_lastObservedGlobalPath!.startsWith('/parent/classes') &&
            currentPath.startsWith('/parent/classes')) {
          final today = _getToday();
          if (!_isSameDay(_selectedDate, today)) {
            setState(() {
              _selectedDate = today;
            });
          }
        }
      }
      _lastObservedGlobalPath = currentPath;
    } catch (_) {}
  }

  @override
  void dispose() {
    _routerDelegate?.removeListener(_onRouteChanged);
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _onRefresh() async {
    final today = _getToday();
    if (mounted && !_isSameDay(_selectedDate, today)) {
      setState(() {
        _selectedDate = today;
      });
    }
    final childrenState = ref.read(childrenControllerProvider);
    final childId = childrenState is ChildrenLoaded
        ? childrenState.activeChildId
        : null;
    await Future.wait([
      ref
          .read(classesControllerProvider.notifier)
          .loadClasses(childStudentId: childId, isRefresh: true),
      ref
          .read(childrenControllerProvider.notifier)
          .loadChildren(isRefresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final childrenState = ref.watch(childrenControllerProvider);
    final classesState = ref.watch(classesControllerProvider);

    // Re-entry detection: whenever user navigates into /parent/classes from outside
    // (e.g. from Dashboard, Profile, or Assignment tabs), reset selected viewing date
    // to current device date.
    try {
      final currentGlobalPath = GoRouter.of(context)
          .routerDelegate
          .currentConfiguration
          .uri
          .path;
      if (_lastObservedGlobalPath != null &&
          _lastObservedGlobalPath != currentGlobalPath) {
        if (!_lastObservedGlobalPath!.startsWith('/parent/classes') &&
            currentGlobalPath.startsWith('/parent/classes')) {
          _selectedDate = _getToday();
        }
      }
      _lastObservedGlobalPath = currentGlobalPath;
    } catch (_) {
      // Safe fallback when rendered without GoRouter in isolated widget tests
    }

    final List<ChildEntity> children = childrenState is ChildrenLoaded
        ? childrenState.children
        : [];
    final ChildEntity? activeChild = childrenState is ChildrenLoaded
        ? childrenState.activeChild
        : null;

    // Check if classes need to be loaded for the active child context
    if (activeChild != null && activeChild.studentId.isNotEmpty) {
      final needsLoad =
          classesState is ClassesInitial ||
          (classesState is ClassesLoaded &&
              classesState.childStudentId != activeChild.studentId) ||
          (classesState is ClassesError &&
              classesState.childStudentId != activeChild.studentId);
      if (needsLoad && classesState is! ClassesLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref
                .read(classesControllerProvider.notifier)
                .loadClasses(childStudentId: activeChild.studentId);
          }
        });
      }
    }

    // Synchronize active child changes with ClassesController and DashboardController
    ref.listen<ChildrenState>(childrenControllerProvider, (previous, next) {
      if (next is ChildrenLoaded) {
        final prevId = previous is ChildrenLoaded
            ? previous.activeChildId
            : null;
        if (prevId != next.activeChildId && next.activeChildId != null) {
          ref
              .read(classesControllerProvider.notifier)
              .loadClasses(childStudentId: next.activeChildId);
        }
      }
    });

    // Filter classes based on selected filter tab and selected calendar date
    // strictly ensuring classes belong to the currently active child.
    List<ClassEntity> filteredClasses = [];
    final bool isChildMatch =
        activeChild == null ||
        classesState is! ClassesLoaded ||
        classesState.childStudentId == null ||
        classesState.childStudentId == activeChild.studentId;

    if (classesState is ClassesLoaded && isChildMatch) {
      final allClasses = classesState.classes;

      final now = ref.watch(currentDeviceDateProvider);

      // 1. Filter by status tab
      List<ClassEntity> statusFiltered;
      switch (_selectedFilter.toLowerCase()) {
        case 'completed':
          statusFiltered = allClasses
              .where((c) => c.isCompletedAt(now))
              .toList();
          break;
        case 'missed':
          statusFiltered = allClasses.where((c) => c.isMissedAt(now)).toList();
          break;
        case 'cancelled':
          statusFiltered = allClasses.where((c) => c.isCancelled).toList();
          break;
        case 'upcoming':
        default:
          statusFiltered = allClasses
              .where(
                (c) =>
                    (c.isUpcomingAt(now) || c.isLive) &&
                    !c.isCompletedAt(now) &&
                    !c.isMissedAt(now) &&
                    !c.isCancelled,
              )
              .toList();
          break;
      }

      // 2. Filter strictly by selected calendar date (converting to device local timezone)
      filteredClasses = statusFiltered.where((c) {
        final start = c.scheduledStartTime;
        if (start == null) return false;
        return _isSameDay(start.toLocal(), _selectedDate);
      }).toList();

      // 3. Sort chronologically by start time
      filteredClasses.sort((a, b) {
        final aTime = a.scheduledStartTime?.toLocal() ?? DateTime(0);
        final bTime = b.scheduledStartTime?.toLocal() ?? DateTime(0);
        return aTime.compareTo(bTime);
      });
    }

    return Scaffold(
      key: const Key('parent_classes_screen'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3E8FF), Color(0xFFE0F2FE), Color(0xFFFFFFFF)],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopAppBar(context),
              Expanded(
                child: _buildScheduleView(
                  context,
                  classesState: classesState,
                  classes: filteredClasses,
                  activeChild: activeChild,
                  children: children,
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
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Hamburger Menu or Back Button
          IconButton(
            key: const Key('classes_menu_button'),
            icon: Icon(
              Navigator.of(context).canPop()
                  ? Icons.arrow_back_rounded
                  : Icons.menu_rounded,
              color: const Color(0xFF191C1E),
              size: 24,
            ),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Scaffold.maybeOf(context)?.openDrawer();
              }
            },
            tooltip: Navigator.of(context).canPop() ? 'Back' : 'Menu',
          ),

          // Center: My Classes Title (Node 76:1825 / 76:1826)
          Text(
            'My Classes',
            style: AppTypography.displayLarge.copyWith(
              fontSize: 25.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF191C1E),
              letterSpacing: -0.5,
            ),
          ),

          // Right: Filter / Preferences Icon Button (Node 76:1827)
          IconButton(
            key: const Key('classes_filter_icon_button'),
            icon: const Icon(
              Icons.tune_rounded,
              color: Color(0xFF191C1E),
              size: 22,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Filter settings coming soon.'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Filter',
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleView(
    BuildContext context, {
    required ClassesState classesState,
    required List<ClassEntity> classes,
    required ChildEntity? activeChild,
    required List<ChildEntity> children,
  }) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFF0037B1),
      child: CustomScrollView(
        key: const Key('classes_scroll_view'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. Student Selector (Node 76:1831)
                  if (activeChild != null)
                    ClassesStudentSelector(
                      activeChild: activeChild,
                      children: children,
                      onChildSelected: (newStudentId) {
                        ref
                            .read(childrenControllerProvider.notifier)
                            .setActiveChild(newStudentId);
                      },
                    ),
                  const SizedBox(height: 16),

                  // 2. Date Navigator Strip (Node 76:1837)
                  ClassesDateNavigator(
                    selectedDate: _selectedDate,
                    initialAnchorDate: _getToday(),
                    onDateSelected: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3. Filter Tabs (Node 76:1880)
                  ClassesFilterTabs(
                    selectedFilter: _selectedFilter,
                    onFilterChanged: (filter) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // 4. Illustration Header (Node 76:1890)
                  SizedBox(
                    width: 128,
                    height: 128,
                    child: Image.asset(
                      'assets/images/figma_cal_single.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.calendar_month_rounded,
                        size: 96,
                        color: Color(0xFF0037B1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Heading: Upcoming Events (Node 76:1894 / 76:1895)
                  Text(
                    _selectedFilter.toLowerCase() == 'upcoming'
                        ? 'Upcoming Events'
                        : '$_selectedFilter Events',
                    style: AppTypography.displayLarge.copyWith(
                      fontSize: 25.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // 5. Events List / Loading / Error / Empty (Node 76:1896)
          if (classesState is ClassesLoading ||
              classesState is ClassesInitial ||
              (classesState is ClassesLoaded &&
                  activeChild != null &&
                  classesState.childStudentId != null &&
                  classesState.childStudentId != activeChild.studentId))
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ClassesSkeleton(),
              ),
            )
          else if (classesState is ClassesError)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: ErrorClassesWidget(
                  message: classesState.message,
                  onRetry: () =>
                      ref.read(classesControllerProvider.notifier).retry(),
                ),
              ),
            )
          else if (classes.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: EmptyClassesWidget(
                  childName: activeChild?.firstName,
                  onRefresh: _onRefresh,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final session = classes[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ClassesEventCard(
                      session: session,
                      useThinkingIcon: index.isOdd,
                      onTap: () {
                        try {
                          GoRouter.of(context).push(
                            '/parent/classes/${session.id}',
                            extra: session,
                          );
                        } catch (_) {
                          // Fallback if rendered outside GoRouter in isolated tests
                        }
                      },
                    ),
                  );
                }, childCount: classes.length),
              ),
            ),

          // 6. Explore Programs Button (Node 76:1918)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Center(
                child: OutlinedButton(
                  key: const Key('explore_programs_button'),
                  onPressed: () {
                    context.go('/parent/classes/program');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0037B1),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF0037B1), width: 1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 1,
                    shadowColor: Colors.black.withValues(alpha: 0.05),
                  ),
                  child: Text(
                    'Explore Programs',
                    style: AppTypography.labelLarge.copyWith(
                      color: const Color(0xFF0037B1),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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
