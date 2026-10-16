import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../../domain/entities/child_entity.dart';
import '../../domain/entities/demo_booking_entity.dart';
import '../../domain/entities/demo_slot_entity.dart';
import '../controllers/children_controller.dart';
import '../controllers/children_state.dart';
import '../controllers/demo_slots_controller.dart';
import '../../../onboarding/presentation/controllers/onboarding_controller.dart';
import '../widgets/demo_booking_confirmation_popup.dart';
import '../widgets/parent_hamburger_drawer.dart';

/// Screen recreating Demo Booking Dashboard (Node 72:477 in Figma).
/// Displays upcoming free demo slots and benefits with exact Figma styles.
class DemoBookingDashboardScreen extends ConsumerStatefulWidget {
  const DemoBookingDashboardScreen({super.key, this.courseId});

  final String? courseId;

  @override
  ConsumerState<DemoBookingDashboardScreen> createState() =>
      _DemoBookingDashboardScreenState();
}

class _DemoBookingDashboardScreenState
    extends ConsumerState<DemoBookingDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final onboardingState = ref.read(onboardingControllerProvider);
      if (onboardingState.availableCourses.isEmpty) {
        ref.read(onboardingControllerProvider.notifier).loadCourses();
      }
      final childrenState = ref.read(childrenControllerProvider);
      if (childrenState is ChildrenInitial) {
        ref.read(childrenControllerProvider.notifier).loadChildren();
      }
      final activeCourse =
          onboardingState.selectedCourse ??
          (onboardingState.availableCourses.isNotEmpty
              ? onboardingState.availableCourses.first
              : null);
      final effectiveCourseId = widget.courseId ?? activeCourse?.id;
      final slotsState = ref.read(demoSlotsControllerProvider);
      if (slotsState is DemoSlotsInitial) {
        final activeStudentId = childrenState is ChildrenLoaded
            ? childrenState.activeChildId
            : null;
        ref
            .read(demoSlotsControllerProvider.notifier)
            .loadSlots(courseId: effectiveCourseId, studentId: activeStudentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingControllerProvider);
    final childrenState = ref.watch(childrenControllerProvider);
    final slotsState = ref.watch(demoSlotsControllerProvider);

    // Listen for transient booking feedback
    ref.listen<DemoSlotsState>(demoSlotsControllerProvider, (prev, next) {
      if (next is DemoSlotsLoaded) {
        if (next.bookingSuccessMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.bookingSuccessMessage!),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          ref.read(demoSlotsControllerProvider.notifier).clearMessages();
        } else if (next.bookingErrorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.bookingErrorMessage!),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
          ref.read(demoSlotsControllerProvider.notifier).clearMessages();
        }
      }
    });

    return Scaffold(
      key: _scaffoldKey,
      drawer: const ParentHamburgerDrawer(activeItem: ''),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0E6FF), // rgb(240, 230, 255)
              Color(0xFFE6F0FF), // rgb(230, 240, 255)
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header - TopAppBar (Node 72:501)
              _buildTopAppBar(context),

              // Main Scrollable Area (Node 72:511)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 768.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Green status banner - Demo Request Received (Node 72:512)
                          _buildDemoRequestReceivedBanner(onboardingState),

                          const SizedBox(height: 16.0),

                          // Section - Hero Card (Node 72:512)
                          _buildHeroCard(onboardingState),

                          const SizedBox(height: 24.0),

                          // Slots Section (Node 72:522) with live slots & functional child dropdown
                          _buildSlotsSection(
                            context,
                            onboardingState,
                            childrenState,
                            slotsState,
                          ),

                          const SizedBox(height: 24.0),

                          // Benefits Section (Node 72:578)
                          _buildBenefitsSection(),

                          const SizedBox(height: 16.0),

                          // Footer Note (Node 72:597)
                          _buildFooterNote(),

                          const SizedBox(height: 56.0),
                        ],
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

  Widget _buildDemoRequestReceivedBanner(OnboardingState onboardingState) {
    final courseName =
        onboardingState.effectiveCourseName ??
        (onboardingState.availableCourses.isNotEmpty
            ? onboardingState.availableCourses.first.courseName
            : 'Selected Course');
    final leadRefText =
        (onboardingState.submissionLeadId != null &&
            onboardingState.submissionLeadId!.isNotEmpty)
        ? ' (Lead Ref: #${onboardingState.submissionLeadId})'
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF059669),
            size: 22.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demo Request Received',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Your request for $courseName has been registered with TrueLern.$leadRefText An academic counselor will contact you to verify and confirm your scheduled batch.',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13.0,
                    height: 1.4,
                    color: const Color(0xFF047857),
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
    return Container(
      height: 56.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left menu button (Node 72:502)
          InkWell(
            key: const Key('demo_dashboard_hamburger_button'),
            onTap: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            borderRadius: BorderRadius.circular(9999.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SvgPicture.asset(
                'assets/icons/demo_menu.svg',
                width: 18.0,
                height: 12.0,
              ),
            ),
          ),

          // Heading 1 - "Dashboard" (Node 72:505)
          Text(
            'Dashboard',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 25.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF191C1E),
              height: 32 / 24,
            ),
          ),

          // Right notification button (Node 72:507)
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(9999.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SvgPicture.asset(
                    'assets/icons/demo_bell.svg',
                    width: 16.0,
                    height: 20.0,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8.0,
                      height: 8.0,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
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

  Widget _buildHeroCard(OnboardingState state) {
    CourseEntity? activeCourse = state.selectedCourse;
    if (widget.courseId != null && state.availableCourses.isNotEmpty) {
      try {
        activeCourse = state.availableCourses.firstWhere(
          (c) => c.id == widget.courseId,
        );
      } catch (_) {}
    }
    if (activeCourse == null && state.availableCourses.isNotEmpty) {
      activeCourse = state.availableCourses.first;
    }

    final courseTitle =
        activeCourse?.courseName ??
        state.effectiveCourseName ??
        'TrueLern Programs';
    final courseLevel = activeCourse?.level != null
        ? '${activeCourse!.level[0].toUpperCase()}${activeCourse.level.substring(1)}'
        : 'Foundational';
    final durationText = activeCourse?.formattedDuration.isNotEmpty == true
        ? ' • ${activeCourse!.formattedDuration}'
        : '';
    final ageText = state.childAge != null
        ? 'Free Demo • Age ${state.childAge} Years$durationText'
        : 'Free Demo • $courseLevel$durationText';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 2.0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Image with FREE DEMO badge (Node 72:513)
          SizedBox(
            height: 192.0,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/demo_hero.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 192.0,
                ),
                Positioned(
                  left: 16.0,
                  top: 16.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(9999.0),
                    ),
                    child: Text(
                      'FREE DEMO',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.55,
                        color: const Color(0xFF191C1E),
                        height: 16 / 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Title and subtitle container (Node 72:517)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        courseTitle,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 21.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                          height: 28 / 20,
                        ),
                      ),
                    ),
                    if (state.availableCourses.length > 1) ...[
                      const SizedBox(width: 8.0),
                      InkWell(
                        key: const Key('demo_dashboard_change_course_button'),
                        onTap: () =>
                            _showCourseSelectorBottomSheet(context, state),
                        borderRadius: BorderRadius.circular(8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 5.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Change',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1D4ED8),
                                ),
                              ),
                              const SizedBox(width: 4.0),
                              const Icon(
                                Icons.swap_horiz_rounded,
                                size: 14.0,
                                color: Color(0xFF1D4ED8),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4.0),
                Text(
                  ageText,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF475569),
                    height: 20 / 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCourseSelectorBottomSheet(
    BuildContext context,
    OnboardingState state,
  ) {
    final activeCourseId =
        state.selectedCourseId ??
        (state.availableCourses.isNotEmpty
            ? state.availableCourses.first.id
            : null);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Select Demo Course',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12.0),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: state.availableCourses.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (ctx, index) {
                      final course = state.availableCourses[index];
                      final isSelected = course.id == activeCourseId;

                      return ListTile(
                        key: Key('course_option_${course.id}'),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        title: Text(
                          course.courseName,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 15.0,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        subtitle: Text(
                          '${course.courseCode}${course.formattedDuration.isNotEmpty ? " • ${course.formattedDuration}" : ""}',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 12.0,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                                size: 20.0,
                              )
                            : null,
                        onTap: () {
                          ref
                              .read(onboardingControllerProvider.notifier)
                              .selectCourse(course);
                          final childrenState = ref.read(
                            childrenControllerProvider,
                          );
                          final activeStudentId =
                              childrenState is ChildrenLoaded
                              ? childrenState.activeChildId
                              : null;
                          ref
                              .read(demoSlotsControllerProvider.notifier)
                              .loadSlots(
                                courseId: course.id,
                                studentId: activeStudentId,
                              );
                          Navigator.of(sheetContext).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlotsSection(
    BuildContext context,
    OnboardingState onboardingState,
    ChildrenState childrenState,
    DemoSlotsState slotsState,
  ) {
    final activeCourse =
        onboardingState.selectedCourse ??
        (onboardingState.availableCourses.isNotEmpty
            ? onboardingState.availableCourses.first
            : null);
    final effectiveCourseId = widget.courseId ?? activeCourse?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading & Child Selector Row (Node 72:523)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Next Available Slots',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 21.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF191C1E),
                height: 28 / 20,
              ),
            ),
            _buildChildSelector(context, childrenState, onboardingState),
          ],
        ),

        const SizedBox(height: 16.0),

        if (slotsState is DemoSlotsLoading)
          _buildSlotsLoadingCard()
        else if (slotsState is DemoSlotsError)
          _buildSlotsErrorCard(
            slotsState.message,
            effectiveCourseId,
            childrenState,
          )
        else if (slotsState is DemoSlotsLoaded)
          if (slotsState.slots.isEmpty)
            _buildSlotsEmptyCard(effectiveCourseId, childrenState)
          else
            for (final slot in slotsState.slots) ...[
              _buildRealSlotCard(
                context,
                slot,
                onboardingState,
                childrenState,
                slotsState,
              ),
              const SizedBox(height: 16.0),
            ]
        else
          _buildSlotsLoadingCard(),
      ],
    );
  }

  Widget _buildChildSelector(
    BuildContext context,
    ChildrenState childrenState,
    OnboardingState onboardingState,
  ) {
    String childName = 'Select Child';
    String childInitial = 'C';

    if (childrenState is ChildrenLoading) {
      childName = 'Loading...';
      childInitial = '..';
    } else if (childrenState is ChildrenLoaded) {
      final active = childrenState.activeChild;
      if (active != null) {
        childName = active.displayName;
        childInitial = childName.trim().isNotEmpty
            ? (childName.trim().length >= 2
                  ? childName.trim().substring(0, 2).toUpperCase()
                  : childName.trim().toUpperCase())
            : 'C';
      } else if (childrenState.children.isNotEmpty) {
        childName = childrenState.children.first.displayName;
        childInitial = childName.trim().isNotEmpty
            ? (childName.trim().length >= 2
                  ? childName.trim().substring(0, 2).toUpperCase()
                  : childName.trim().toUpperCase())
            : 'C';
      } else {
        childName = onboardingState.childName.isNotEmpty
            ? onboardingState.childName
            : 'No Child Linked';
        childInitial = childName.trim().isNotEmpty
            ? (childName.trim().length >= 2
                  ? childName.trim().substring(0, 2).toUpperCase()
                  : childName.trim().toUpperCase())
            : 'NC';
      }
    } else if (childrenState is ChildrenError) {
      childName = 'Select Child';
      childInitial = '!';
    }

    return InkWell(
      key: const Key('demo_dashboard_child_selector'),
      onTap: () => _showChildSelectionSheet(context),
      borderRadius: BorderRadius.circular(9999.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 17.0, vertical: 9.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9999.0),
          border: Border.all(color: const Color.fromRGBO(196, 197, 215, 0.3)),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 1.0,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24.0,
              height: 24.0,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF747686)),
              ),
              alignment: Alignment.center,
              child: Text(
                childInitial,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: const Color(0xFF0037B1),
                  height: 16 / 11,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120.0),
              child: Text(
                childName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: const Color(0xFF191C1E),
                  height: 16 / 12,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            SvgPicture.asset(
              'assets/icons/demo_chevron_down.svg',
              width: 9.0,
              height: 5.55,
            ),
          ],
        ),
      ),
    );
  }

  void _showChildSelectionSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, child) {
            final childrenState = ref.watch(childrenControllerProvider);

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.1),
                    blurRadius: 20.0,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle pill
                    const SizedBox(height: 12.0),
                    Container(
                      width: 36.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Header row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Child',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF191C1E),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 20.0,
                              color: Color(0xFF64748B),
                            ),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            splashRadius: 20.0,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1.0, color: Color(0xFFF1F5F9)),

                    // Body according to state
                    Flexible(
                      child: SingleChildScrollView(
                        child: _buildChildSheetBody(
                          sheetContext,
                          childrenState,
                        ),
                      ),
                    ),

                    const Divider(height: 1.0, color: Color(0xFFF1F5F9)),

                    // Add Child action at the bottom
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48.0,
                        child: OutlinedButton(
                          key: const Key('demo_dashboard_add_child_button'),
                          onPressed: () async {
                            Navigator.of(sheetContext).pop();
                            // Navigate to existing child onboarding flow honestly
                            await context.push(AppRoutePaths.onboardingChild);
                            // Refresh linked children after returning
                            ref
                                .read(childrenControllerProvider.notifier)
                                .loadChildren(isRefresh: true);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF0037B1),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_rounded,
                                size: 20.0,
                                color: Color(0xFF0037B1),
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                'Add Child',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0037B1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChildSheetBody(BuildContext context, ChildrenState state) {
    if (state is ChildrenLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 36.0),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: Color(0xFF0037B1)),
              SizedBox(height: 12.0),
              Text(
                'Loading linked children...',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13.0),
              ),
            ],
          ),
        ),
      );
    }

    if (state is ChildrenError) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 36.0,
              ),
              const SizedBox(height: 8.0),
              Text(
                'Unable to load children: ${state.message}',
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13.0,
                  color: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 12.0),
              TextButton.icon(
                onPressed: () {
                  ref.read(childrenControllerProvider.notifier).loadChildren();
                },
                icon: const Icon(Icons.refresh_rounded, size: 16.0),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is ChildrenLoaded) {
      if (state.children.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
          child: Center(
            child: Column(
              children: [
                const Icon(
                  Icons.people_outline_rounded,
                  size: 40.0,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'No Linked Children Found',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'No child profiles are currently linked to this parent account. Tap Add Child below to register.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13.0,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        children: [
          for (final child in state.children) ...[
            _buildChildTile(
              context,
              child,
              child.studentId == state.activeChildId,
            ),
            const Divider(height: 1.0, indent: 64.0, color: Color(0xFFF1F5F9)),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildChildTile(
    BuildContext context,
    ChildEntity child,
    bool isSelected,
  ) {
    final initials = child.displayName.trim().isNotEmpty
        ? (child.displayName.trim().length >= 2
              ? child.displayName.trim().substring(0, 2).toUpperCase()
              : child.displayName.trim().toUpperCase())
        : 'C';

    final List<String> details = [];
    if (child.grade != null && child.grade!.isNotEmpty) {
      details.add('Grade: ${child.grade}');
    }
    if (child.age != null) {
      details.add('Age: ${child.age}');
    }
    if (child.studentCode != null && child.studentCode!.isNotEmpty) {
      details.add('Code: ${child.studentCode}');
    }
    final subtitle = details.join(' • ');

    return InkWell(
      key: Key('child_option_${child.studentId}'),
      onTap: () {
        final onboardingState = ref.read(onboardingControllerProvider);
        final activeCourse =
            onboardingState.selectedCourse ??
            (onboardingState.availableCourses.isNotEmpty
                ? onboardingState.availableCourses.first
                : null);
        final effectiveCourseId = widget.courseId ?? activeCourse?.id;

        ref
            .read(childrenControllerProvider.notifier)
            .setActiveChild(child.studentId);
        ref
            .read(demoSlotsControllerProvider.notifier)
            .loadSlots(courseId: effectiveCourseId, studentId: child.studentId);
        Navigator.of(context).pop();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 40.0,
              height: 40.0,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE0E7FF)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? const Color(0xFF0037B1)
                      : const Color(0xFF475569),
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.displayName,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15.0,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2.0),
                    Text(
                      subtitle,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 12.0,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected
                  ? const Color(0xFF0037B1)
                  : const Color(0xFFCBD5E1),
              size: 22.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotsLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color.fromRGBO(196, 197, 215, 0.1)),
      ),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: Color(0xFF0037B1)),
            SizedBox(height: 12.0),
            Text(
              'Checking available demo slots...',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotsErrorCard(
    String message,
    String? courseId,
    ChildrenState childrenState,
  ) {
    final activeChildId = childrenState is ChildrenLoaded
        ? childrenState.activeChildId
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 32.0,
          ),
          const SizedBox(height: 8.0),
          Text(
            'Unable to load demo slots',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 15.0,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFB91C1C),
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13.0,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12.0),
          TextButton.icon(
            onPressed: () {
              ref
                  .read(demoSlotsControllerProvider.notifier)
                  .loadSlots(courseId: courseId, studentId: activeChildId);
            },
            icon: const Icon(Icons.refresh_rounded, size: 16.0),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsEmptyCard(String? courseId, ChildrenState childrenState) {
    final activeChildId = childrenState is ChildrenLoaded
        ? childrenState.activeChildId
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color.fromRGBO(196, 197, 215, 0.2)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 2.0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52.0,
            height: 52.0,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.event_busy_rounded,
              color: Color(0xFF64748B),
              size: 26.0,
            ),
          ),
          const SizedBox(height: 14.0),
          Text(
            'No Demo Slots Available',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 17.0,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'There are currently no free demo slots scheduled for this course. Please refresh or contact academic support.',
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13.0,
              height: 1.4,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16.0),
          InkWell(
            key: const Key('refresh_demo_slots_button'),
            onTap: () {
              ref
                  .read(demoSlotsControllerProvider.notifier)
                  .loadSlots(courseId: courseId, studentId: activeChildId);
            },
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0037B1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    size: 16.0,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'Refresh Availability',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  Widget _buildRealSlotCard(
    BuildContext context,
    DemoSlotEntity slot,
    OnboardingState onboardingState,
    ChildrenState childrenState,
    DemoSlotsLoaded slotsState,
  ) {
    final isThisBooking =
        slotsState.isBooking && slotsState.bookingSlotId == slot.id;
    final activeCourse =
        onboardingState.selectedCourse ??
        (onboardingState.availableCourses.isNotEmpty
            ? onboardingState.availableCourses.first
            : null);
    final courseName =
        activeCourse?.courseName ??
        onboardingState.effectiveCourseName ??
        'TrueLern Course';
    final courseId =
        activeCourse?.id ?? onboardingState.selectedCourseId ?? slot.courseId;
    final isToday = slot.displayDayLabel.toUpperCase() == 'TODAY';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color.fromRGBO(196, 197, 215, 0.1)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 1.0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day label (e.g. TODAY / TOMORROW / 24 OCT)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                slot.displayDayLabel,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.55,
                  color: const Color(0xFF0037B1),
                  height: 16 / 11,
                ),
              ),
              if (slot.instructorName != null &&
                  slot.instructorName!.isNotEmpty)
                Text(
                  'Instructor: ${slot.instructorName}',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8.0),

          // Time value + PM/AM
          SizedBox(
            height: 56.0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  slot.formattedTime,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 48.0,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.96,
                    color: const Color(0xFF191C1E),
                    height: 56 / 48,
                  ),
                ),
                const SizedBox(width: 4.0),
                Text(
                  slot.period,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 17.0,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF434655),
                    height: 24 / 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8.0),

          // CTA: Book this demo
          InkWell(
            key: isToday
                ? const Key('book_demo_button_today')
                : Key('book_demo_button_${slot.id}'),
            onTap: slotsState.isBooking
                ? null
                : () {
                    final studentId = childrenState is ChildrenLoaded
                        ? childrenState.activeChildId ?? ''
                        : '';
                    final studentName = childrenState is ChildrenLoaded
                        ? childrenState.activeChild?.displayName
                        : null;

                    showDemoBookingConfirmationPopup(
                      context,
                      selectedDemo: courseName,
                      dateTime:
                          '${slot.displayDayLabel} at ${slot.formattedTime} ${slot.period}',
                      teacher: slot.instructorName ?? 'Assigned Instructor',
                      onConfirm: () async {
                        return await ref
                            .read(demoSlotsControllerProvider.notifier)
                            .bookSlot(
                              slot: slot,
                              studentId: studentId,
                              courseId: courseId,
                              courseName: courseName,
                              studentName: studentName,
                            );
                      },
                      onConfirmBooking: () async {
                        final success = await ref
                            .read(demoSlotsControllerProvider.notifier)
                            .bookSlot(
                              slot: slot,
                              studentId: studentId,
                              courseId: courseId,
                              courseName: courseName,
                              studentName: studentName,
                            );
                        if (!success) return null;
                        final currentState = ref.read(
                          demoSlotsControllerProvider,
                        );
                        if (currentState is DemoSlotsLoaded &&
                            currentState.lastConfirmedBooking != null) {
                          return currentState.lastConfirmedBooking;
                        }
                        return DemoBookingEntity(
                          bookingId: slot.id,
                          courseName: courseName,
                          studentName: studentName,
                          startDateTime: slot.startDateTime,
                          endDateTime: slot.endDateTime,
                          teacherName: slot.instructorName,
                          teacherStatus: slot.instructorName != null
                              ? 'Assigned'
                              : 'Finalizing',
                          status: 'scheduled',
                        );
                      },
                    );
                  },
            borderRadius: BorderRadius.circular(8.0),
            child: Container(
              width: double.infinity,
              height: 44.0,
              decoration: BoxDecoration(
                color: isThisBooking
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFF1E4ED8),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isThisBooking) ...[
                    const SizedBox(
                      width: 18.0,
                      height: 18.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Text(
                      'Booking...',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Book this demo',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                        color: const Color(0xFFCAD3FF),
                        height: 20 / 14,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    SvgPicture.asset(
                      'assets/icons/demo_arrow_right.svg',
                      width: 13.33,
                      height: 13.33,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Column(
      children: [
        // 1. Free live demo (Node 72:579)
        _buildBenefitCard(
          bgColor: const Color(0x336CF8BB), // rgba(108, 248, 187, 0.2)
          borderColor: const Color(0x4D6CF8BB), // rgba(108, 248, 187, 0.3)
          circleBgColor: const Color(0x666CF8BB), // rgba(108, 248, 187, 0.4)
          iconAsset: 'assets/icons/demo_video.svg',
          iconWidth: 20.0,
          iconHeight: 16.0,
          title: 'Free live demo',
        ),

        const SizedBox(height: 8.0),

        // 2. Expert faculty (Node 72:585)
        _buildBenefitCard(
          bgColor: const Color(0x1AF59E0B), // rgba(245, 158, 11, 0.1)
          borderColor: const Color(0x33F59E0B), // rgba(245, 158, 11, 0.2)
          circleBgColor: const Color(0x33F59E0B), // rgba(245, 158, 11, 0.2)
          iconAsset: 'assets/icons/demo_graduation.svg',
          iconWidth: 22.0,
          iconHeight: 18.0,
          title: 'Expert faculty',
        ),

        const SizedBox(height: 8.0),

        // 3. 45-minute session (Node 72:591)
        _buildBenefitCard(
          bgColor: const Color(0x0D0037B1), // rgba(0, 55, 177, 0.05)
          borderColor: const Color(0x1A0037B1), // rgba(0, 55, 177, 0.1)
          circleBgColor: const Color(0x1A0037B1), // rgba(0, 55, 177, 0.1)
          iconAsset: 'assets/icons/demo_clock.svg',
          iconWidth: 20.0,
          iconHeight: 20.0,
          title: '45-minute session',
        ),
      ],
    );
  }

  Widget _buildBenefitCard({
    required Color bgColor,
    required Color borderColor,
    required Color circleBgColor,
    required String iconAsset,
    required double iconWidth,
    required double iconHeight,
    required String title,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              color: circleBgColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              iconAsset,
              width: iconWidth,
              height: iconHeight,
            ),
          ),
          const SizedBox(width: 16.0),
          Text(
            title,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 17.0,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF191C1E),
              height: 24 / 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterNote() {
    return Center(
      child: Text(
        'FREE DEMO • 45 MINS • EXPERT INSTRUCTOR\n• NO COMMITMENT',
        textAlign: TextAlign.center,
        style: GoogleFonts.hankenGrotesk(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.1,
          color: const Color(0xFF475569),
          height: 22 / 11,
        ),
      ),
    );
  }
}
