import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../messages/domain/entities/message_entity.dart';
import '../../../messages/presentation/controllers/messages_controller.dart';
import '../../../messages/presentation/controllers/messages_state.dart';
import '../controllers/children_controller.dart';
import '../controllers/children_state.dart';
import '../widgets/parent_hamburger_drawer.dart';

/// Parent Messages Screen — 100% visual match to Figma Frame `Messages` (Node 76:1150)
/// with real TrueLern API backend integration.
class ParentMessagesScreen extends ConsumerStatefulWidget {
  const ParentMessagesScreen({super.key});

  @override
  ConsumerState<ParentMessagesScreen> createState() =>
      _ParentMessagesScreenState();
}

class _ParentMessagesScreenState extends ConsumerState<ParentMessagesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _replyController = TextEditingController();

  // Asset constants
  static const String _imgMsSarahAvatar = 'assets/images/ms_sarah_avatar.png';
  static const String _imgLogo = 'assets/images/truelern_top_logo.png';

  static const String _svgMarkRead = 'assets/icons/msg_mark_read.svg';
  static const String _svgBadgeMic = 'assets/icons/msg_badge_mic.svg';
  static const String _svgSupportHeadset =
      'assets/icons/msg_support_headset.svg';
  static const String _svgAllCaughtUp = 'assets/icons/msg_all_caught_up.svg';
  static const String _svgHamburger = 'assets/icons/msg_top_hamburger.svg';
  static const String _svgBell = 'assets/icons/msg_top_bell.svg';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialMessages();
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _loadInitialMessages() {
    final childrenState = ref.read(childrenControllerProvider);
    if (childrenState is ChildrenLoaded &&
        childrenState.activeChildId != null) {
      ref
          .read(messagesControllerProvider.notifier)
          .loadMessages(studentId: childrenState.activeChildId!);
    }
  }

  String _formatRelativeTime(DateTime? dt) {
    if (dt == null) return 'Recent';
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Listen for child switching from childrenControllerProvider
    ref.listen<ChildrenState>(childrenControllerProvider, (prev, next) {
      if (next is ChildrenLoaded && next.activeChildId != null) {
        final prevChildId = prev is ChildrenLoaded ? prev.activeChildId : null;
        if (prevChildId != next.activeChildId) {
          ref
              .read(messagesControllerProvider.notifier)
              .loadMessages(studentId: next.activeChildId!);
        }
      }
    });

    final childrenState = ref.watch(childrenControllerProvider);
    final messagesState = ref.watch(messagesControllerProvider);
    final activeChild = childrenState is ChildrenLoaded
        ? childrenState.activeChild
        : null;
    final activeChildId = activeChild?.studentId;

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
        key: _scaffoldKey,
        drawer: const ParentHamburgerDrawer(),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.8, -0.9),
              end: Alignment(0.8, 0.9),
              colors: [
                Color(0xFFF3E8FF), // rgb(243, 232, 255)
                Color(0xFFE0F2FE), // rgb(224, 242, 254)
                Color(0xFFFFFFFF), // rgb(255, 255, 255)
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // Scrollable Main Content
                Positioned.fill(
                  child: AppRefreshIndicator(
                    onRefresh: () async {
                      if (activeChildId != null) {
                        await ref
                            .read(messagesControllerProvider.notifier)
                            .loadMessages(
                              studentId: activeChildId,
                              isRefresh: true,
                            );
                      }
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.only(
                        top: 80, // Clearance for top app bar (64px + 16px)
                        bottom: 120, // Clearance for bottom navigation bar + composer
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 768),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),

                                // Page Title & Mark all read button (Node 76:1152)
                                _buildHeaderRow(messagesState),

                                const SizedBox(height: 16),

                                // Active Child Indicator Banner
                                if (activeChild != null)
                                  _buildActiveChildBanner(
                                    activeChild.firstName,
                                  ),

                                const SizedBox(height: 16),

                                // Message list state dispatcher
                                _buildMessagesBody(
                                  messagesState,
                                  activeChildId,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Header — TopAppBar (Node 76:1216)
                Positioned(top: 0, left: 0, right: 0, child: _buildTopAppBar()),

                // Bottom Composer Bar if messages loaded
                if (messagesState is MessagesLoaded)
                  Positioned(
                    bottom: 64, // Positioned right above bottom navigation bar
                    left: 0,
                    right: 0,
                    child: _buildMessageComposer(messagesState),
                  ),

                // BottomNavBar (Node 76:1225)
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
      ),
    );
  }

  Widget _buildActiveChildBanner(String childName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1F0037B1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.face_rounded, size: 16, color: Color(0xFF0037B1)),
          const SizedBox(width: 8),
          Text(
            'Showing messages for $childName',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0037B1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesBody(MessagesState state, String? activeChildId) {
    if (state is MessagesLoading || state is MessagesInitial) {
      return _buildLoadingState();
    }

    if (state is MessagesError) {
      return _buildErrorState(state.message, activeChildId);
    }

    if (state is MessagesLoaded) {
      final messages = state.data.messages;

      if (messages.isEmpty) {
        return _buildEmptyState(state.data.studentName);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < messages.length; i++) ...[
            _buildMessageCard(messages[i], state.data.activeTeacher),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          _buildEndOfListState(),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoadingState() {
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
                color: Color(0xFF0037B1),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading conversation...',
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

  Widget _buildErrorState(String error, String? activeChildId) {
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
            'Failed to load messages',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1B23),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            error,
            textAlign: TextAlign.center,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              color: const Color(0xFF747686),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              if (activeChildId != null) {
                ref
                    .read(messagesControllerProvider.notifier)
                    .loadMessages(studentId: activeChildId, isRefresh: true);
              }
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0037B1),
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

  Widget _buildEmptyState(String studentName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
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
          SvgPicture.asset(_svgAllCaughtUp, width: 48, height: 48),
          const SizedBox(height: 16),
          Text(
            'No messages yet for $studentName',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1B23),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reach out to the instructor below to start a conversation.',
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

  /// Top App Bar — Node 76:1216
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
              // Button - Menu (Node 76:1217)
              InkWell(
                key: const Key('messages_menu_button'),
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                borderRadius: BorderRadius.circular(9999),
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: SvgPicture.asset(
                    _svgHamburger,
                    width: 18,
                    height: 12,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF1A1B23),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),

              // Brand Logo (Node 76:1220)
              Image.asset(
                _imgLogo,
                width: 120,
                height: 41,
                fit: BoxFit.contain,
              ),

              // Button - Notifications (Node 76:1221)
              InkWell(
                key: const Key('messages_notification_button'),
                onTap: () => context.go(AppRoutePaths.notifications),
                borderRadius: BorderRadius.circular(9999),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SvgPicture.asset(
                        _svgBell,
                        width: 16,
                        height: 20,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF0037B1),
                          BlendMode.srcIn,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFBA1A1A),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Page Title Row (Node 76:1152)
  Widget _buildHeaderRow(MessagesState state) {
    final hasUnread = state is MessagesLoaded && state.data.unreadCount > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Title "Messages" (Node 76:1154)
        Text(
          'Messages',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1B23),
            height: 36 / 28,
          ),
        ),

        // "Mark all read" button (Node 76:1155)
        InkWell(
          key: const Key('mark_all_read_button'),
          onTap: hasUnread
              ? () {
                  ref.read(messagesControllerProvider.notifier).markAllAsRead();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All messages marked as read'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  _svgMarkRead,
                  width: 16.4,
                  height: 9,
                  colorFilter: ColorFilter.mode(
                    hasUnread
                        ? const Color(0xFF0037B1)
                        : const Color(0xFF9E9E9E),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Mark all read',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: hasUnread
                        ? const Color(0xFF0037B1)
                        : const Color(0xFF9E9E9E),
                    letterSpacing: 0.1,
                    height: 20 / 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Message Card (Styled exactly to Node 76:1160, 76:1179, 76:1192)
  Widget _buildMessageCard(
    MessageItemEntity message,
    TeacherContactEntity? teacher,
  ) {
    final isUnread = !message.isRead;
    final isTeacher = message.isTeacher;
    final isSystem = message.isSystem;

    // Resolve tag text and color
    final String tagText;
    final Color tagBg;
    final Color tagFg;

    if (isTeacher) {
      tagText = (teacher?.department?.toUpperCase().isNotEmpty == true)
          ? teacher!.department!.toUpperCase()
          : (teacher?.batchName?.toUpperCase().isNotEmpty == true
                ? teacher!.batchName!.toUpperCase()
                : 'COMMUNICATION');
      tagBg = const Color(0x1A22D3EE);
      tagFg = const Color(0xFF0891B2);
    } else if (isSystem) {
      tagText = 'SYSTEM SUPPORT';
      tagBg = const Color(0x1A14B8A6);
      tagFg = const Color(0xFF0D9488);
    } else {
      tagText = message.subject.isNotEmpty
          ? message.subject.toUpperCase()
          : 'PARENT INQUIRY';
      tagBg = const Color(0x1A6366F1);
      tagFg = const Color(0xFF4F46E5);
    }

    final senderDisplayName =
        message.senderName ??
        (isTeacher
            ? (teacher?.fullName.isNotEmpty == true
                  ? teacher!.fullName
                  : 'Instructor')
            : isSystem
            ? 'TrueLern Support'
            : 'You');

    return InkWell(
      onTap: isUnread
          ? () {
              ref
                  .read(messagesControllerProvider.notifier)
                  .markAsRead(messageId: message.id);
            }
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Left blue unread accent indicator (Node 76:1161)
              if (isUnread)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 4,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0037B1),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(9999),
                          bottomRight: Radius.circular(9999),
                        ),
                      ),
                    ),
                  ),
                ),

              // Inner card content
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    _buildAvatar(message, teacher),

                    const SizedBox(width: 16),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Name & Relative Time
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  senderDisplayName,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1A1B23),
                                    height: 24 / 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatRelativeTime(message.createdAt),
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isUnread
                                      ? const Color(0xFF0037B1)
                                      : const Color(0xFF747686),
                                  height: 16 / 12,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // Track/Subject Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: tagBg,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Text(
                              tagText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: tagFg,
                                letterSpacing: 0.5,
                                height: 16 / 10,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Message Text
                          Text(
                            message.message,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 15,
                              fontWeight: isUnread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isUnread
                                  ? const Color(0xFF1A1B23)
                                  : const Color(0xFF434655),
                              height: 20 / 14,
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
        ),
      ),
    );
  }

  Widget _buildAvatar(
    MessageItemEntity message,
    TeacherContactEntity? teacher,
  ) {
    if (message.isSystem) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFE8E7F3),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x4DE2E1ED), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 1,
              offset: Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(_svgSupportHeadset, width: 20, height: 18),
      );
    }

    if (message.isParent) {
      return Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE0E7FF),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.person_rounded,
          color: Color(0xFF4338CA),
          size: 26,
        ),
      );
    }

    // Teacher avatar
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE2E1ED),
            ),
            child: ClipOval(
              child: Image.asset(
                _imgMsSarahAvatar,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(
                    teacher?.firstName.isNotEmpty == true
                        ? teacher!.firstName[0]
                        : 'T',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0037B1),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF22D3EE),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(_svgBadgeMic, width: 7, height: 9.5),
            ),
          ),
        ],
      ),
    );
  }

  /// Message composer input bar for sending a message
  Widget _buildMessageComposer(MessagesLoaded state) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFAF8FFFD),
            border: const Border(top: BorderSide(color: Color(0x1F000000))),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFD4D4D8)),
                  ),
                  child: TextField(
                    controller: _replyController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: state.data.activeTeacher != null
                          ? 'Message ${state.data.activeTeacher!.fullName}...'
                          : 'Type a message to instructor...',
                      hintStyle: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        color: const Color(0xFF9E9E9E),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: state.isSending
                    ? null
                    : () async {
                        final text = _replyController.text.trim();
                        if (text.isEmpty) return;

                        try {
                          final success = await ref
                              .read(messagesControllerProvider.notifier)
                              .sendMessage(message: text);
                          if (!mounted) return;
                          if (success) {
                            _replyController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Message sent to instructor'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to send: $e'),
                              backgroundColor: const Color(0xFFBA1A1A),
                              duration: const Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0037B1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: state.isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// End of List State — Node 76:1210
  Widget _buildEndOfListState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            SvgPicture.asset(_svgAllCaughtUp, width: 36, height: 36),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up!',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF747686),
                letterSpacing: 0.1,
                height: 20 / 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom Navigation Bar — Node 76:1225
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
                    isActive: true,
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
