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

/// Parent Classes Schedule Screen (SCR-13).
///
/// Figma Source of Truth: `Parent(full app)_TreLern`, Frame 76:1820 (`Classes Shedule`, 390 × 952).
/// Authoritative API: GET `/api/parent/children/{childStudentId}/live-classes`
/// Authentication: Bearer token (Parent role) attached via AuthInterceptor.
class ParentClassesScreen extends ConsumerStatefulWidget {
  const ParentClassesScreen({super.key});

  @override
  ConsumerState<ParentClassesScreen> createState() => _ParentClassesScreenState();
}

class _ParentClassesScreenState extends ConsumerState<ParentClassesScreen> {
  DateTime _selectedDate = DateTime(2026, 8, 26);
  bool _isDateFilterActive = false;
  String _selectedFilter = 'Upcoming';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final childrenState = ref.read(childrenControllerProvider);
      if (childrenState is! ChildrenLoaded) {
        ref.read(childrenControllerProvider.notifier).loadChildren();
      } else if (childrenState.activeChildId != null) {
        final classesState = ref.read(classesControllerProvider);
        if (classesState is! ClassesLoaded && classesState is! ClassesLoading) {
          ref.read(classesControllerProvider.notifier).loadClasses(
            childStudentId: childrenState.activeChildId,
          );
        }
      }
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _onRefresh() async {
    final childrenState = ref.read(childrenControllerProvider);
    final childId = childrenState is ChildrenLoaded ? childrenState.activeChildId : null;
    await Future.wait([
      ref.read(classesControllerProvider.notifier).loadClasses(childStudentId: childId),
      ref.read(childrenControllerProvider.notifier).loadChildren(isRefresh: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final childrenState = ref.watch(childrenControllerProvider);
    final classesState = ref.watch(classesControllerProvider);

    // Synchronize active child changes with ClassesController
    ref.listen<ChildrenState>(childrenControllerProvider, (previous, next) {
      if (next is ChildrenLoaded) {
        final prevId = previous is ChildrenLoaded ? previous.activeChildId : null;
        if (prevId != next.activeChildId && next.activeChildId != null) {
          ref.read(classesControllerProvider.notifier).loadClasses(
            childStudentId: next.activeChildId,
          );
        }
      }
    });

    final List<ChildEntity> children = childrenState is ChildrenLoaded ? childrenState.children : [];
    final ChildEntity? activeChild = childrenState is ChildrenLoaded ? childrenState.activeChild : null;

    // Filter classes based on selected filter tab and optional date selection
    List<ClassEntity> filteredClasses = [];
    if (classesState is ClassesLoaded) {
      final allClasses = classesState.classes;

      // 1. Filter by status tab
      List<ClassEntity> statusFiltered;
      switch (_selectedFilter.toLowerCase()) {
        case 'completed':
          statusFiltered = allClasses.where((c) => c.isCompleted).toList();
          break;
        case 'missed':
          statusFiltered = allClasses.where((c) => c.isMissed).toList();
          break;
        case 'cancelled':
          statusFiltered = allClasses.where((c) => c.isCancelled).toList();
          break;
        case 'upcoming':
        default:
          statusFiltered = allClasses
              .where((c) => c.isUpcoming && !c.isCompleted && !c.isMissed && !c.isCancelled)
              .toList();
          break;
      }

      // 2. Filter by date if active
      if (_isDateFilterActive) {
        filteredClasses = statusFiltered.where((c) {
          final start = c.scheduledStartTime;
          if (start == null) return false;
          return _isSameDay(start, _selectedDate);
        }).toList();
      } else {
        filteredClasses = statusFiltered;
      }
    }

    return Scaffold(
      key: const Key('parent_classes_screen'),
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
          // Left: Hamburger Menu Button (Node 76:1822)
          IconButton(
            key: const Key('classes_menu_button'),
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF191C1E), size: 24),
            onPressed: () {
              Scaffold.maybeOf(context)?.openDrawer();
            },
            tooltip: 'Menu',
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
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF191C1E), size: 22),
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
                        ref.read(childrenControllerProvider.notifier).setActiveChild(newStudentId);
                      },
                    ),
                  const SizedBox(height: 16),

                  // 2. Date Navigator Strip (Node 76:1837)
                  ClassesDateNavigator(
                    selectedDate: _selectedDate,
                    onDateSelected: (date) {
                      setState(() {
                        if (_isDateFilterActive && _isSameDay(_selectedDate, date)) {
                          // Tap same day again to show all events for the filter
                          _isDateFilterActive = false;
                        } else {
                          _selectedDate = date;
                          _isDateFilterActive = true;
                        }
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
          if (classesState is ClassesLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ClassesSkeleton(),
              ),
            )
          else if (classesState is ClassesError)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: ErrorClassesWidget(
                  message: classesState.message,
                  onRetry: () => ref.read(classesControllerProvider.notifier).retry(),
                ),
              ),
            )
          else if (classes.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
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
                  },
                  childCount: classes.length,
                ),
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
                    try {
                      context.push('/parent/classes/program');
                    } catch (_) {}
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0037B1),
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: Color(0xFF0037B1),
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
