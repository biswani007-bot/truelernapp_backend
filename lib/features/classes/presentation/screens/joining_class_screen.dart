import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/error/failures.dart';
import '../../../dashboard/presentation/controllers/children_controller.dart';
import '../../../dashboard/presentation/controllers/children_state.dart';
import '../../data/repositories/classes_repository_impl.dart';
import '../../domain/entities/class_entity.dart';
import '../../domain/entities/class_join_entity.dart';
import '../controllers/classes_controller.dart';
import '../controllers/classes_state.dart';

/// Explicit deterministic joining states as per SCR-16 specification:
/// INITIALIZING -> CONNECTING -> CONNECTED -> LIVE CLASS
/// Failure: INITIALIZING -> CONNECTING -> ERROR
enum JoiningState { initializing, connecting, connected, error }

/// SCR-16 Joining Class Screen (Figma Node 76:3263 "Joining Class (Revised)")
///
/// Linear transactional loading state transitioning from Class Preview into the
/// live classroom observation room.
/// Suppressed TopAppBar and BottomNavBar as specified in Figma design specs.
class JoiningClassScreen extends ConsumerStatefulWidget {
  final String classId;
  final ClassEntity? session;
  final String? childStudentId;

  const JoiningClassScreen({
    super.key,
    required this.classId,
    this.session,
    this.childStudentId,
  });

  @override
  ConsumerState<JoiningClassScreen> createState() => _JoiningClassScreenState();
}

class _JoiningClassScreenState extends ConsumerState<JoiningClassScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _progressAnimation;

  JoiningState _state = JoiningState.initializing;
  ClassJoinEntity? _joinData;
  String _statusMessage = 'Connecting to virtual classroom...';
  String? _errorMessage;
  late final String? _immutableChildId;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _progressAnimation = Tween<double>(begin: 0.25, end: 0.85).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutCubic),
    );

    // Freeze child context immutably at screen creation to prevent mid-join state drift
    final childrenState = ref.read(childrenControllerProvider);
    _immutableChildId =
        widget.childStudentId ??
        (childrenState is ChildrenLoaded ? childrenState.activeChildId : null);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initiateJoin();
    });
  }

  Future<void> _initiateJoin() async {
    // Guard against duplicate in-flight requests
    if (_state == JoiningState.connecting) {
      return;
    }

    final childId = _immutableChildId;

    if (childId == null || childId.isEmpty || widget.classId.isEmpty) {
      if (mounted) {
        setState(() {
          _state = JoiningState.error;
          _errorMessage = 'Active child student ID or class ID is missing. Cannot connect to class.';
          _statusMessage = 'Connection failed';
        });
      }
      return;
    }

    // Child Ownership Safety:
    // Verify class belongs to active child using loaded classes where available
    final classesState = ref.read(classesControllerProvider);
    if (classesState is ClassesLoaded && classesState.classes.isNotEmpty) {
      final matchesClass = classesState.classes.any(
        (c) => c.id == widget.classId,
      );
      if (!matchesClass && widget.session == null) {
        if (mounted) {
          setState(() {
            _state = JoiningState.error;
            _errorMessage = 'This class does not belong to the selected child.';
            _statusMessage = 'Unauthorized child';
          });
        }
        return;
      }
    }

    // 15-Minute Entry Window Guard:
    ClassEntity? resolvedSession = widget.session;
    if (resolvedSession == null && classesState is ClassesLoaded) {
      resolvedSession = classesState.classes
          .where((c) => c.id == widget.classId)
          .firstOrNull;
    }

    if (resolvedSession != null && !resolvedSession.canEnterLiveClass()) {
      if (mounted) {
        setState(() {
          _state = JoiningState.error;
          _errorMessage = 'You can join 15 minutes before the class starts.';
          _statusMessage = 'Entry window closed';
        });
      }
      return;
    }

    setState(() {
      _state = JoiningState.connecting;
      _errorMessage = null;
      _statusMessage = 'Connecting to virtual classroom...';
    });

    try {
      final joinData = await ref
          .read(classesRepositoryProvider)
          .joinLiveClass(childStudentId: childId, classId: widget.classId);

      // Prevent entering classroom if returned credentials are invalid/empty
      if (joinData.token.isEmpty ||
          joinData.roomName.isEmpty ||
          joinData.jitsiDomain.isEmpty) {
        if (mounted) {
          setState(() {
            _state = JoiningState.error;
            _errorMessage =
                'Incomplete classroom credentials received from server.';
            _statusMessage = 'Connection failed';
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _state = JoiningState.connected;
          _joinData = joinData;
          _statusMessage = 'Connection established! Ready to enter.';
        });
        _enterClassroom();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _state = JoiningState.error;
          _errorMessage = _messageFrom(error);
          _statusMessage = 'Connection failed';
        });
      }
    }
  }

  String _messageFrom(Object error) {
    if (error is Failure) {
      if (error.statusCode == 403) {
        return 'Access denied. You do not have permission to join this class session.';
      }
      if (error is AuthFailure || error.statusCode == 401) {
        return 'Your session has expired. Please sign in again.';
      }
      if (error.statusCode == 404) {
        final msg = error.message.toLowerCase();
        // If the error message contains raw HTML or missing route signature, treat as connection error
        if (msg.contains('<!doctype') ||
            msg.contains('<html') ||
            msg.contains('page not found')) {
          return 'Unable to connect to the live classroom. Please try again.';
        }
        return 'This class is no longer available or does not exist.';
      }
      if (error.statusCode == 409) {
        return 'This class has been cancelled, archived, or cannot currently be joined.';
      }
      if (error is NetworkFailure || error is TimeoutFailure) {
        return 'Network connection issue. Please check your internet connection and retry.';
      }
      final msg = error.message.toLowerCase();
      if (msg.contains('<!doctype') || msg.contains('<html')) {
        return 'Unable to connect to the live classroom. Please try again.';
      }
      return error.message;
    }
    final s = error.toString().toLowerCase();
    if (s.contains('<!doctype') ||
        s.contains('<html') ||
        s.contains('page not found')) {
      return 'Unable to connect to the live classroom. Please try again.';
    }
    if (s.contains('403')) {
      return 'Access denied. You do not have permission to join this class session.';
    }
    if (s.contains('401')) {
      return 'Your session has expired. Please sign in again.';
    }
    if (s.contains('404')) {
      return 'This class is no longer available or does not exist.';
    }
    if (s.contains('409')) {
      return 'This class has been cancelled, archived, or cannot currently be joined.';
    }
    final match = RegExp(r'message: (.+?)(,|$)').firstMatch(error.toString());
    return match?.group(1) ??
        'Unable to connect to the live classroom. Please try again.';
  }

  void _enterClassroom() {
    if (_state != JoiningState.connected || _joinData == null) return;
    if (_joinData!.token.isEmpty ||
        _joinData!.roomName.isEmpty ||
        _joinData!.jitsiDomain.isEmpty) {
      return;
    }

    final s = widget.session;
    final resolvedSession = ClassEntity(
      id: widget.classId,
      title: _joinData?.classTitle ?? s?.title ?? 'Live Class',
      classCode: s?.classCode,
      subject: s?.subject,
      scheduledStartTime: s?.scheduledStartTime,
      scheduledEndTime: s?.scheduledEndTime,
      duration: s?.duration,
      status: s?.status ?? 'LIVE',
      teacherName: s?.teacherName,
      teacherAvatar: s?.teacherAvatar,
      meetingUrl: _joinData?.meetingUrl ?? s?.meetingUrl,
      roomName: _joinData?.roomName ?? s?.roomName,
    );

    try {
      context.go(
        '/parent/classes/${widget.classId}/live',
        extra: {
          'session': resolvedSession,
          'joinData': _joinData,
          'childStudentId': widget.childStudentId,
        },
      );
    } catch (_) {
      // In isolated test environments where GoRouter is not mounted
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title =
        _joinData?.classTitle ??
        widget.session?.title ??
        'Public Speaking Fundamentals';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.8, -0.6),
            end: Alignment(0.8, 0.6),
            colors: [
              Color(0xFFF3E8FF), // rgb(243, 232, 255)
              Color(0xFFE0F2FE), // rgb(224, 242, 254)
              Color(0xFFFFFFFF), // rgb(255, 255, 255)
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Subtle back/close button in top corner for parent convenience
              Positioned(
                top: 12,
                left: 16,
                child: IconButton(
                  key: const Key('joining_class_back_button'),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF434655),
                    size: 20,
                  ),
                  tooltip: 'Cancel & Return',
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      try {
                        context.go('/parent/classes/${widget.classId}');
                      } catch (_) {}
                    }
                  },
                ),
              ),

              // Main Centered Content (Figma Frame 76:3264)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 35),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Large 3D Icon Container (Figma Nodes 76:3276 -> 76:3282)
                        _buildClayMicIcon(),
                        const SizedBox(height: 32),

                        // Heading 1 (Figma Nodes 76:3266, 76:3267)
                        Text(
                          _errorMessage != null
                              ? 'Unable to Join'
                              : 'Joining your class...',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1B23),
                            height: 36 / 28,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle - Class Title (Figma Nodes 76:3269, 76:3270)
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 17,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF434655),
                            height: 24 / 16,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Progress Indicator (Figma Nodes 76:3271 -> 76:3275)
                        _buildProgressIndicator(),
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

  /// Builds the 3D simulated clay icon card for Communication/Public Speaking (Figma 76:3276)
  Widget _buildClayMicIcon() {
    return Container(
      width: 192,
      height: 192,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(34, 211, 238, 0.1), // rgba(34, 211, 238, 0.1)
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 128,
        height: 128,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.1),
              offset: Offset(0, 20),
              blurRadius: 25,
              spreadRadius: -5,
            ),
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.1),
              offset: Offset(0, 8),
              blurRadius: 10,
              spreadRadius: -6,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Diagonal soft cyan gradient (Figma 76:3281)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: [
                        Color.fromRGBO(
                          34,
                          211,
                          238,
                          0.2,
                        ), // rgba(34, 211, 238, 0.2)
                        Color.fromRGBO(
                          34,
                          211,
                          238,
                          0.0,
                        ), // rgba(34, 211, 238, 0)
                      ],
                    ),
                  ),
                ),
              ),

              // Decorative 3D highlight bubble in top right (Figma 76:3282)
              Positioned(
                top: 8,
                right: 8,
                width: 32,
                height: 32,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.8),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

              // Centered Mic Vector Icon (Figma 76:3280)
              Center(
                child: SvgPicture.asset(
                  'assets/icons/mic_joining.svg',
                  width: 35,
                  height: 47.5,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the Progress Bar & Status Text (Figma 76:3271)
  Widget _buildProgressIndicator() {
    if (_errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFB91C1C),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/parent/classes/${widget.classId}');
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFDCE1FF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Go Back'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _initiateJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0037B1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Track + Indicator (Figma 76:3272, 76:3273)
        Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E1ED),
            borderRadius: BorderRadius.circular(9999),
          ),
          clipBehavior: Clip.antiAlias,
          child: AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF22D3EE), // Figma cyan #22D3EE
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Text (Figma 76:3275)
        Text(
          _statusMessage,
          textAlign: TextAlign.center,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF434655),
            height: 16 / 12,
          ),
        ),
        const SizedBox(height: 32),

        // Enter Virtual Classroom Trigger (SCR Live Classroom New)
        TextButton.icon(
          key: const Key('enter_live_classroom_trigger_button'),
          icon: const Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: Color(0xFF0037B1),
          ),
          label: Text(
            'Enter Classroom →',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0037B1),
            ),
          ),
          onPressed: _enterClassroom,
        ),
      ],
    );
  }
}
