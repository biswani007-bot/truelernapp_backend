import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../notifications/domain/entities/parent_notification_entity.dart';
import '../../../notifications/presentation/controllers/parent_notifications_controller.dart';
import '../../../notifications/presentation/controllers/parent_notifications_state.dart';
import '../../domain/entities/child_entity.dart';
import '../controllers/children_controller.dart';
import '../controllers/children_state.dart';
import '../widgets/parent_hamburger_drawer.dart';

/// Parent Notifications Screen — 100% visual match to Figma Frame `Notifications` (Node 76:1378)
/// connected to real TrueLern Backend API.
class ParentNotificationsScreen extends ConsumerStatefulWidget {
  const ParentNotificationsScreen({super.key});

  @override
  ConsumerState<ParentNotificationsScreen> createState() =>
      _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState
    extends ConsumerState<ParentNotificationsScreen> {
  // Asset paths
  static const String _imgClassGridIcon =
      'assets/images/notif_class_grid_icon.png';
  static const String _imgTeacherAvatar =
      'assets/images/notif_teacher_avatar.png';
  static const String _svgCalendar = 'assets/icons/notif_calendar.svg';
  static const String _svgBack = 'assets/icons/notif_back.svg';
  static const String _svgMore = 'assets/icons/notif_more.svg';

  final List<String> _tabs = const ['All', 'Classes', 'Assignments', 'Updates'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final childrenState = ref.read(childrenControllerProvider);
      if (childrenState is! ChildrenLoaded) {
        ref.read(childrenControllerProvider.notifier).loadChildren();
      } else if (childrenState.activeChild != null) {
        ref
            .read(parentNotificationsControllerProvider.notifier)
            .loadNotifications(
              activeChild: childrenState.activeChild,
              allChildren: childrenState.children,
            );
      } else {
        ref
            .read(parentNotificationsControllerProvider.notifier)
            .loadNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parentNotificationsControllerProvider);
    final childrenState = ref.watch(childrenControllerProvider);
    final ChildEntity? activeChild =
        childrenState is ChildrenLoaded ? childrenState.activeChild : null;
    final List<ChildEntity> allChildren =
        childrenState is ChildrenLoaded ? childrenState.children : const [];

    final selectedTab = state is ParentNotificationsLoaded
        ? state.selectedTab
        : 'All';

    // Synchronize active child changes with ParentNotificationsController
    ref.listen<ChildrenState>(childrenControllerProvider, (previous, next) {
      if (next is ChildrenLoaded && next.activeChild != null) {
        final prevId =
            previous is ChildrenLoaded ? previous.activeChildId : null;
        if (prevId != next.activeChildId) {
          ref
              .read(parentNotificationsControllerProvider.notifier)
              .loadNotifications(
                activeChild: next.activeChild,
                allChildren: next.children,
              );
        }
      }
    });

    // Automatically load when activeChild becomes available or mismatches loaded child
    if (activeChild != null && activeChild.studentId.isNotEmpty) {
      final needsLoad = state is ParentNotificationsInitial ||
          (state is ParentNotificationsLoaded &&
              state.childStudentId != activeChild.studentId) ||
          (state is ParentNotificationsError &&
              state.childStudentId != activeChild.studentId);
      if (needsLoad && state is! ParentNotificationsLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref
                .read(parentNotificationsControllerProvider.notifier)
                .loadNotifications(
                  activeChild: activeChild,
                  allChildren: allChildren,
                );
          }
        });
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutePaths.parentDashboard);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        drawer: const ParentHamburgerDrawer(),
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Scrollable Notification Content
              Positioned.fill(
                child: AppRefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(parentNotificationsControllerProvider.notifier)
                        .loadNotifications(
                          activeChild: activeChild,
                          allChildren: allChildren,
                          isRefresh: true,
                        );
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(
                      top: 80, // Clearance for top app bar (64px + 16px)
                      bottom: 100, // Clearance for bottom navigation bar
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 768),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Filter Tabs (Node 76:1380)
                              _buildFilterTabs(selectedTab),

                              const SizedBox(height: 16),

                              // Notification Content Dispatcher (Node 76:1392)
                              _buildNotificationBody(state),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Header — TopAppBar (Node 76:1450)
              Positioned(top: 0, left: 0, right: 0, child: _buildTopAppBar()),

              // BottomNavBar (Node 76:1461)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomNavBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Top App Bar — Node 76:1450
  Widget _buildTopAppBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
              // Button - Back (Node 76:1452)
              InkWell(
                key: const Key('notifications_back_button'),
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutePaths.parentDashboard);
                  }
                },
                borderRadius: BorderRadius.circular(9999),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  child: SvgPicture.asset(_svgBack, width: 16, height: 16),
                ),
              ),

              // Title: Notifications (Node 76:1456)
              Text(
                'Notifications',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 25.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF191C1E),
                  height: 32 / 24,
                ),
              ),

              // Button - More Options (Node 76:1458)
              PopupMenuButton<String>(
                key: const Key('notifications_more_button'),
                icon: SvgPicture.asset(_svgMore, width: 4, height: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'preferences') {
                    context.push(AppRoutePaths.parentCommunicationPreferences);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'preferences',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: Color(0xFF0037B1),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Notification Preferences',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Filter Tabs Row (Node 76:1380)
  Widget _buildFilterTabs(String selectedTab) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _tabs.map((tab) {
          final isSelected = selectedTab == tab;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                ref
                    .read(parentNotificationsControllerProvider.notifier)
                    .setTab(tab);
              },
              borderRadius: BorderRadius.circular(9999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1E4ED8)
                      : const Color(0xFFE8E7F3),
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 1,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tab,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFFCAD3FF)
                        : const Color(0xFF434655),
                    letterSpacing: 0.1,
                    height: 20 / 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationBody(ParentNotificationsState state) {
    if (state is ParentNotificationsLoading ||
        state is ParentNotificationsInitial) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Color(0xFF1E4ED8),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading notifications...',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF747686),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state is ParentNotificationsError) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFD8D8)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFBA1A1A),
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load notifications',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1B23),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                color: const Color(0xFF747686),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref
                    .read(parentNotificationsControllerProvider.notifier)
                    .loadNotifications(isRefresh: true);
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E4ED8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state is ParentNotificationsLoaded) {
      final items = state.filteredNotifications;

      if (items.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF8FF),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: Color(0xFF747686),
              ),
              const SizedBox(height: 16),
              Text(
                'No notifications in ${state.selectedTab}',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1B23),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You will see new updates and alerts here.',
                textAlign: TextAlign.center,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildNotificationCard(items[i]),
            const SizedBox(height: 16),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildNotificationCard(ParentNotificationItemEntity item) {
    switch (item.category) {
      case NotificationCategory.classes:
        return _buildLiveClassCard(item);
      case NotificationCategory.assignments:
        return _buildAssignmentCard(item);
      case NotificationCategory.updates:
        return _buildFeedbackCard(item);
    }
  }

  /// Card: LIVE CLASS (Node 76:1393)
  Widget _buildLiveClassCard(ParentNotificationItemEntity item) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FF),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: Color(0xFF22D3EE), width: 4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Container (Node 76:1395)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0x1A22D3EE),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              _imgClassGridIcon,
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.school_rounded,
                color: Color(0xFF22D3EE),
                size: 24,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Content Column (Node 76:1397)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag & Time Row (Node 76:1398)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        'LIVE CLASS',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1D4ED8),
                          letterSpacing: 0.5,
                          height: 15 / 10,
                        ),
                      ),
                    ),
                    Text(
                      item.timeAgo,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF434655),
                        height: 16 / 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Heading 3 (Node 76:1403)
                Text(
                  item.title,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1B23),
                    height: 24 / 16,
                  ),
                ),

                const SizedBox(height: 4),

                // Body text (Node 76:1405)
                Text(
                  item.content,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF434655),
                    height: 20 / 14,
                  ),
                ),

                const SizedBox(height: 12),

                // Action Button (Node 76:1406)
                InkWell(
                  onTap: () {
                    context.go(AppRoutePaths.parentClasses);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0037B1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'View Classes',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 0.1,
                        height: 20 / 14,
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

  /// Card: ASSIGNMENT (Node 76:1408)
  Widget _buildAssignmentCard(ParentNotificationItemEntity item) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FF),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: Color(0xFFA855F7), width: 4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Container (Node 76:1410)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0x1AA855F7),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              _svgCalendar,
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(
                Color(0xFFA855F7),
                BlendMode.srcIn,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Content Column (Node 76:1412)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag & Time Row (Node 76:1413)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDD5),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        'ASSIGNMENT',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFC2410C),
                          letterSpacing: 0.5,
                          height: 15 / 10,
                        ),
                      ),
                    ),
                    Text(
                      item.timeAgo,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF434655),
                        height: 16 / 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Heading 3 (Node 76:1418)
                Text(
                  item.title,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1B23),
                    height: 24 / 16,
                  ),
                ),

                const SizedBox(height: 4),

                // Body text (Node 76:1420)
                Text(
                  item.content,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF434655),
                    height: 20 / 14,
                  ),
                ),

                const SizedBox(height: 12),

                // Action Button
                InkWell(
                  onTap: () {
                    context.go(AppRoutePaths.parentAssignments);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0037B1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'View Assignments',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        letterSpacing: 0.1,
                        height: 20 / 14,
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

  /// Card: TEACHER UPDATE / FEEDBACK (Node 76:1421)
  Widget _buildFeedbackCard(ParentNotificationItemEntity item) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FF),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: Color(0xFF0037B1), width: 4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teacher Avatar Circle (Node 76:1423)
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x330037B1), width: 2),
            ),
            child: ClipOval(
              child: Image.asset(
                _imgTeacherAvatar,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.person_rounded,
                  color: Color(0xFF0037B1),
                  size: 24,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Content Column (Node 76:1425)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag & Time Row (Node 76:1426)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        'UPDATE',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF15803D),
                          letterSpacing: 0.5,
                          height: 15 / 10,
                        ),
                      ),
                    ),
                    Text(
                      item.timeAgo,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF434655),
                        height: 16 / 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Heading 3 (Node 76:1431)
                Text(
                  item.title,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1B23),
                    height: 24 / 16,
                  ),
                ),

                const SizedBox(height: 4),

                // Body text (Node 76:1433)
                Text(
                  item.content,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF434655),
                    height: 20 / 14,
                  ),
                ),

                const SizedBox(height: 12),

                // Action Button: View Feedback or Messages (Node 76:1434)
                InkWell(
                  onTap: () {
                    context.go(AppRoutePaths.parentMessages);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF747686),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'View Messages',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0037B1),
                        letterSpacing: 0.1,
                        height: 20 / 14,
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

  /// Bottom Navigation Bar — Node 76:1461
  Widget _buildBottomNavBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xCCFAF8FF),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  _buildNavItem(
                    label: 'Home',
                    icon: Icons.home_outlined,
                    isActive: false,
                    onTap: () => context.go(AppRoutePaths.parentDashboard),
                  ),
                  _buildNavItem(
                    label: 'My Classes',
                    icon: Icons.school_outlined,
                    isActive: false,
                    onTap: () => context.go(AppRoutePaths.parentClasses),
                  ),
                  _buildNavItem(
                    label: 'Assignments',
                    icon: Icons.assignment_outlined,
                    isActive: false,
                    onTap: () => context.go(AppRoutePaths.parentAssignments),
                  ),
                  _buildNavItem(
                    label: 'Profile',
                    icon: Icons.person_rounded,
                    isActive: false,
                    onTap: () => context.go(AppRoutePaths.parentProfile),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final color = isActive ? const Color(0xFF0037B1) : const Color(0xFF434655);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: const Color(0xFF0037B1).withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.hankenGrotesk(
                color: color,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                height: 16 / 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
