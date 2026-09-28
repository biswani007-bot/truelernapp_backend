import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_paths.dart';
import '../../data/models/add_child_request_dto.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/child_entity.dart';
import '../controllers/children_controller.dart';
import '../controllers/children_state.dart';

/// Parent My Child Screen — Integrated with real Authoritative Children APIs.
///
/// Figma Source of Truth: `Parent(full app)_TreLern`, Frame: `My children` (Node 76:962).
/// Features:
/// - Fetches real children list from GET /api/parent/children via [childrenControllerProvider].
/// - Renders every child returned by the backend (never hardcoded, never limited to 2).
/// - Enriches each child card with verified metrics from GET /api/parent/children/{id}/dashboard.
/// - Selecting "VIEW CHILD" sets active child context and navigates to Dashboard.
/// - "ADD CHILD" card opens a modal to submit POST /api/parent/children to live backend.
/// - Preserves exact Figma typography, colors, layout, and dashed add card design.
class ParentMyChildScreen extends ConsumerStatefulWidget {
  const ParentMyChildScreen({super.key});

  @override
  ConsumerState<ParentMyChildScreen> createState() => _ParentMyChildScreenState();
}

class _ParentMyChildScreenState extends ConsumerState<ParentMyChildScreen> {
  static const _imgTrueLernLogo = 'assets/images/truelern_logo.png';
  static const _svgAddChild = 'assets/icons/ic_add_child.svg';
  static const _svgBackArrow = 'assets/icons/ic_back_arrow.svg';
  static const _svgGroupProfile = 'assets/icons/ic_group_profile.svg';

  @override
  void initState() {
    super.initState();
    // Always force a fresh fetch every time this screen opens.
    // The ChildrenInitial guard was causing stale/cached data (e.g. only 2
    // children) to persist when the provider was already ChildrenLoaded from
    // a prior navigation. Using isRefresh: true keeps the existing list
    // visible during the reload instead of blanking the screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(childrenControllerProvider.notifier).loadChildren(isRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final childrenState = ref.watch(childrenControllerProvider);

    return Scaffold(
      key: const Key('parent_my_child_screen'),
      body: Container(
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
              // Header - TopAppBar (Node 76:1046)
              _buildTopAppBar(context),

              // Scrollable content (Node 76:963)
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFF0037B1),
                  onRefresh: () => ref.read(childrenControllerProvider.notifier).loadChildren(isRefresh: true),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),

                        // Title & Subtitle Container (Node 76:964)
                        Text(
                          'My Child',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            height: 36 / 28,
                            color: const Color(0xFF1A1B23),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select a profile to view their learning journey.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            height: 24 / 16,
                            color: const Color(0xFF434655),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // State-driven Children List
                        _buildChildrenSection(context, childrenState),

                        const SizedBox(height: 24),

                        // Button - Add Child Card (Node 76:1040)
                        _buildAddChildCard(context),

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

  /// TopAppBar matching Figma Node 76:1046
  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000), // rgba(0, 0, 0, 0.05)
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left back button (Node 101:50)
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(9999),
              onTap: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutePaths.parentProfile);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: SvgPicture.asset(
                  _svgBackArrow,
                  width: 16,
                  height: 16,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF0037B1),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),

          // Center logo (Node 76:1807)
          Image.asset(
            _imgTrueLernLogo,
            width: 120,
            height: 41,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Text(
              'TrueLern',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 23.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0037B1),
              ),
            ),
          ),

          // Right trailing icon (Node 76:1049)
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              borderRadius: BorderRadius.circular(9999),
              onTap: () {
                _openAddChildModal(context);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: SvgPicture.asset(
                  _svgGroupProfile,
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF0037B1),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the stateful list of child cards
  Widget _buildChildrenSection(BuildContext context, ChildrenState state) {
    if (state is ChildrenLoading || state is ChildrenInitial) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0037B1)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading linked children...',
              style: TextStyle(
                color: Color(0xFF434655),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (state is ChildrenError) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECDD3)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFE11D48), size: 36),
            const SizedBox(height: 12),
            Text(
              'Failed to load children',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF9F1239),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF4C0519)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.read(childrenControllerProvider.notifier).loadChildren(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0037B1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (state is ChildrenLoaded) {
      final children = state.children;
      if (children.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEFF6FF),
                ),
                child: const Icon(Icons.family_restroom_rounded, size: 32, color: Color(0xFF0037B1)),
              ),
              const SizedBox(height: 16),
              Text(
                'No Children Linked Yet',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your child to start tracking their classes, attendance, and learning progress.',
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        );
      }

      // Render all authoritative children returned by the backend
      return Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            _ChildCardItem(
              key: Key('my_child_card_${children[i].studentId}'),
              child: children[i],
              index: i,
              isActive: children[i].studentId == state.activeChildId,
              onSelect: () {
                ref.read(childrenControllerProvider.notifier).setActiveChild(children[i].studentId);
                context.go(AppRoutePaths.parentDashboard);
              },
            ),
            if (i < children.length - 1) const SizedBox(height: 24),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }

  /// Button - Add Child Card matching Figma Node 76:1040
  Widget _buildAddChildCard(BuildContext context) {
    return CustomPaint(
      painter: _DashedRRectPainter(
        color: const Color(0xFFC4C5D7),
        strokeWidth: 2,
        radius: 16,
        dashWidth: 6,
        dashSpace: 4,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openAddChildModal(context),
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Circle with + icon (Node 76:1041)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE8E7F3),
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        _svgAddChild,
                        width: 19,
                        height: 19,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF434655),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ADD CHILD',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      height: 24 / 16,
                      color: const Color(0xFF434655),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Opens the Add Child bottom modal sheet
  void _openAddChildModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AddChildBottomSheet(),
    );
  }
}

/// Child Card widget with live backend metrics integration
class _ChildCardItem extends ConsumerWidget {
  const _ChildCardItem({
    super.key,
    required this.child,
    required this.index,
    required this.isActive,
    required this.onSelect,
  });

  final ChildEntity child;
  final int index;
  final bool isActive;
  final VoidCallback onSelect;

  static const _imgAvatarMia = 'assets/images/avatar_mia.png';
  static const _imgAvatarAlex = 'assets/images/avatar_alex.png';
  static const _svgSpeaking = 'assets/icons/ic_speaking.svg';
  static const _svgThinking = 'assets/icons/ic_thinking.svg';
  static const _svgArrowRight = 'assets/icons/ic_arrow_right.svg';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rotating accent color palette matching Figma aesthetics
    final palettes = [
      (
        accentColor: const Color(0xFF22D3EE), // Cyan (Mia)
        skillPillBgColor: const Color(0x1A22D3EE),
        defaultAvatar: _imgAvatarMia,
        skillIcon: _svgSpeaking,
      ),
      (
        accentColor: const Color(0xFFA855F7), // Purple (Alex)
        skillPillBgColor: const Color(0x1AA855F7),
        defaultAvatar: _imgAvatarAlex,
        skillIcon: _svgThinking,
      ),
      (
        accentColor: const Color(0xFF3B82F6), // Blue
        skillPillBgColor: const Color(0x1A3B82F6),
        defaultAvatar: _imgAvatarAlex,
        skillIcon: _svgSpeaking,
      ),
      (
        accentColor: const Color(0xFF10B981), // Emerald
        skillPillBgColor: const Color(0x1A10B981),
        defaultAvatar: _imgAvatarMia,
        skillIcon: _svgThinking,
      ),
      (
        accentColor: const Color(0xFFF59E0B), // Amber
        skillPillBgColor: const Color(0x1AF59E0B),
        defaultAvatar: _imgAvatarAlex,
        skillIcon: _svgSpeaking,
      ),
    ];

    final theme = palettes[index % palettes.length];

    // Read real child dashboard metrics if available from GET /parent/children/{id}/dashboard
    final dashboardAsync = ref.watch(childDashboardMetricsProvider(child.studentId));

    String skill = child.grade ?? 'General Curriculum';
    String attendanceText = '--';
    double attendanceValue = 0.0;
    String progressText = '--';
    double progressValue = 0.0;

    dashboardAsync.whenData((dashboard) {
      if (dashboard.enrolledBatches.isNotEmpty) {
        skill = dashboard.enrolledBatches.first.courseName ??
            dashboard.enrolledBatches.first.batchName;
      } else if (dashboard.activeTopic != null && dashboard.activeTopic!.isNotEmpty) {
        skill = dashboard.activeTopic!;
      }

      if (dashboard.attendanceRate != null) {
        final rate = dashboard.attendanceRate!;
        attendanceText = '${rate.toInt()}%';
        attendanceValue = (rate / 100.0).clamp(0.0, 1.0);
        // Overall progress reflects academic participation
        progressValue = attendanceValue;
        progressText = attendanceText;
      }
    });

    // Determine age or identifier badge
    final tagText = child.grade != null && child.grade!.isNotEmpty
        ? child.grade!
        : (child.studentCode != null && child.studentCode!.isNotEmpty
            ? child.studentCode!
            : (child.status != null ? child.status!.toUpperCase() : 'Student'));

    // Select avatar based on gender/asset
    final avatarAsset = (child.gender?.toLowerCase() == 'female')
        ? _imgAvatarMia
        : ((child.gender?.toLowerCase() == 'male') ? _imgAvatarAlex : theme.defaultAvatar);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: theme.accentColor,
            width: 4,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // rgba(0, 0, 0, 0.04)
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 24, right: 20, top: 20, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Avatar + Name/Age + Skill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF3F2FE),
                  border: Border.all(
                    color: isActive ? const Color(0xFF0037B1) : Colors.white,
                    width: 2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: (child.avatar != null && child.avatar!.startsWith('http'))
                      ? Image.network(
                          child.avatar!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            avatarAsset,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          avatarAsset,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person_rounded,
                            size: 36,
                            color: theme.accentColor,
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 16),

              // Name, Tag, Skill Overlay
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name & Tag Row
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            child.displayName.isNotEmpty ? child.displayName : 'Student',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 21.5,
                              fontWeight: FontWeight.w600,
                              height: 28 / 20,
                              color: const Color(0xFF1A1B23),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDEDF9),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            tagText,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 16 / 12,
                              color: const Color(0xFF434655),
                            ),
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ACTIVE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Skill Overlay Pill (Node 76:979 / 76:1014)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.skillPillBgColor,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            theme.skillIcon,
                            width: 14,
                            height: 14,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              skill,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 16 / 12,
                                color: const Color(0xFF1A1B23),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Two Bento Metric Boxes (Node 76:984 / 76:1019)
          Row(
            children: [
              // Box 1: Overall Progress (Node 76:985 / 76:1020)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Progress',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 16 / 12,
                          color: const Color(0xFF434655),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        progressText,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 21.5,
                          fontWeight: FontWeight.w600,
                          height: 28 / 20,
                          color: const Color(0xFF0037B1),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9999),
                        child: LinearProgressIndicator(
                          value: progressValue,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(theme.accentColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Box 2: Attendance (Node 76:993 / 76:1028)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 16 / 12,
                          color: const Color(0xFF434655),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        attendanceText,
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 21.5,
                          fontWeight: FontWeight.w600,
                          height: 28 / 20,
                          color: const Color(0xFF1A1B23),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9999),
                        child: LinearProgressIndicator(
                          value: attendanceValue,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0037B1)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Button - VIEW CHILD (Node 76:1001 / 76:1036)
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              key: Key('view_child_button_${child.studentId}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E4ED8),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: onSelect,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'VIEW CHILD',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 20 / 14,
                      color: Colors.white,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SvgPicture.asset(
                    _svgArrowRight,
                    width: 12,
                    height: 12,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
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
}

/// Modal bottom sheet for adding a new child via POST /api/parent/children
class _AddChildBottomSheet extends ConsumerStatefulWidget {
  const _AddChildBottomSheet();

  @override
  ConsumerState<_AddChildBottomSheet> createState() => _AddChildBottomSheetState();
}

class _AddChildBottomSheetState extends ConsumerState<_AddChildBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _gradeController = TextEditingController();

  String _gender = 'male';
  String _relationship = 'father';
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final req = AddChildRequestDto(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        gender: _gender,
        grade: _gradeController.text.trim().isNotEmpty ? _gradeController.text.trim() : null,
        relationshipType: _relationship,
      );

      final newChild = await ref.read(addChildRepositoryProvider).addChild(req);
      await ref.read(childrenControllerProvider.notifier).loadChildren(isRefresh: true);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newChild.displayName} has been added successfully!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
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
              const SizedBox(height: 16),

              // Title
              Text(
                'Add New Child',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Enter child details to link them to your parent account.',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFE11D48), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF9F1239)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // First Name
              Text(
                'First Name *',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _firstNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Enter first name',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF0037B1), width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Last Name
              Text(
                'Last Name *',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _lastNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Enter last name',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF0037B1), width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Last name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Gender & Relationship in a row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gender',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _gender,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'male', child: Text('Male')),
                            DropdownMenuItem(value: 'female', child: Text('Female')),
                            DropdownMenuItem(value: 'other', child: Text('Other')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _gender = v);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Relationship',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _relationship,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'father', child: Text('Father')),
                            DropdownMenuItem(value: 'mother', child: Text('Mother')),
                            DropdownMenuItem(value: 'guardian', child: Text('Guardian')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _relationship = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Grade / Class
              Text(
                'Grade / Class',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _gradeController,
                decoration: InputDecoration(
                  hintText: 'e.g. Grade 4, Junior Foundation',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF0037B1), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit & Cancel Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0037B1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Add Child', style: TextStyle(fontWeight: FontWeight.w600)),
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
}

/// Custom painter to render exact dashed border around rounded rectangle
class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashWidth;
  final double dashSpace;

  _DashedRRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final dashedPath = Path();

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        dashedPath.addPath(
          metric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.radius != radius;
}
