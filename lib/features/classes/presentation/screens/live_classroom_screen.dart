import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/router/route_names.dart';
import '../../../dashboard/domain/entities/demo_booking_entity.dart';
import '../../../dashboard/presentation/controllers/children_controller.dart';
import '../../../dashboard/presentation/controllers/children_state.dart';
import '../../data/repositories/classes_repository_impl.dart';
import '../../domain/entities/class_entity.dart';
import '../../domain/entities/class_join_entity.dart';
import '../controllers/classes_controller.dart';
import '../controllers/classes_state.dart';

/// Diagnostic categories for classroom connection & authorization failures.
enum ClassroomErrorCategory {
  tokenRequestFailure('Token Request Failure'),
  viewerAuthFailure('Viewer Authorization Failure'),
  tokenExpired('Token Expired'),
  networkFailure('Network Connection Failure'),
  roomMismatch('Room Configuration Mismatch'),
  entryWindowRestricted('Entry Window Restricted'),
  sessionNotFound('Session Not Found'),
  unknown('Connection Error');

  final String displayName;
  const ClassroomErrorCategory(this.displayName);
}

/// SCR-17 Live Classroom Screen
///
/// Embeds the authoritative TrueLern Live Classroom via Jitsi Meet:
/// Loads the authenticated WebRTC room directly on the authorized classroom domain
/// (`https://{jitsiDomain}/{roomName}?jwt={token}`) using the student's authorized credentials.
///
/// Key Architectural Guarantees:
/// - Authoritative student JWT token is passed directly through Jitsi's native `jwt` parameter.
/// - Zero reliance on unauthenticated URLs or external parent portal cookies.
/// - Never substitutes demo booking ID for actual live class or room identifier.
/// - Enforces token validity and expiration checks before attempting connection.
/// - Comprehensive in-app error handling with diagnostic categorization, Retry, and Back to Demo.
/// - Prevents duplicate join requests and automatic retry loops.
class LiveClassroomScreen extends ConsumerStatefulWidget {
  final String classId;
  final ClassEntity? session;
  final ClassJoinEntity? joinData;
  final String? childStudentId;
  final bool fromDemo;
  final DemoBookingEntity? booking;

  const LiveClassroomScreen({
    super.key,
    required this.classId,
    this.session,
    this.joinData,
    this.childStudentId,
    this.fromDemo = false,
    this.booking,
  });

  @override
  ConsumerState<LiveClassroomScreen> createState() =>
      _LiveClassroomScreenState();
}

class _LiveClassroomScreenState extends ConsumerState<LiveClassroomScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  int _loadingProgress = 0;
  String? _errorMessage;
  ClassroomErrorCategory? _errorCategory;
  ClassJoinEntity? _activeJoinData;
  bool _hasNavigatedToSummary = false;
  bool _hasExitedClassroom = false;
  bool _isRetrying = false;
  DateTime? _lastRetryTime;

  bool get _isDemoSession =>
      widget.fromDemo ||
      widget.booking != null ||
      widget.classId.startsWith('DEMO-') ||
      (widget.session?.title.toLowerCase().contains('demo') ?? false);

  @override
  void initState() {
    super.initState();
    _activeJoinData = widget.joinData;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeClassroom();
      }
    });
  }

  @override
  void dispose() {
    _hasExitedClassroom = true;
    try {
      _controller?.loadRequest(Uri.parse('about:blank'));
    } catch (_) {}
    super.dispose();
  }

  Future<void> _initializeClassroom({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _errorCategory = null;
    });

    try {
      // 1. Entry Window Guard:
      ClassEntity? resolvedSession = widget.session;
      if (resolvedSession == null) {
        final classesState = ref.read(classesControllerProvider);
        if (classesState is ClassesLoaded) {
          resolvedSession = classesState.classes
              .where((c) => c.id == widget.classId)
              .firstOrNull;
        }
      }

      if (_activeJoinData == null &&
          resolvedSession != null &&
          resolvedSession.scheduledStartTime != null &&
          !resolvedSession.canEnterLiveClass()) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorCategory = ClassroomErrorCategory.entryWindowRestricted;
            _errorMessage =
                'You can join 15 minutes before the class starts.';
          });
        }
        return;
      }

      // 2. Authoritative Participant Token Resolution:
      // If joinData was not passed or fresh token is explicitly requested via Retry
      if (_activeJoinData == null || forceRefresh) {
        final childId = widget.childStudentId ??
            (ref.read(childrenControllerProvider) is ChildrenLoaded
                ? (ref.read(childrenControllerProvider) as ChildrenLoaded)
                    .activeChildId
                : null);

        if (childId == null || childId.trim().isEmpty) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorCategory = ClassroomErrorCategory.tokenRequestFailure;
              _errorMessage =
                  'Child student identity is missing. Cannot authorize classroom participant.';
            });
          }
          return;
        }

        try {
          final fetchedJoinData = await ref
              .read(classesRepositoryProvider)
              .joinLiveClass(
                childStudentId: childId,
                classId: widget.classId,
              );
          _activeJoinData = fetchedJoinData;
        } catch (e) {
          _handleJoinError(e);
          return;
        }
      }

      final joinData = _activeJoinData;

      // 3. Strict Validation of Returned Credentials:
      if (joinData == null || joinData.token.trim().isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorCategory = ClassroomErrorCategory.tokenRequestFailure;
            _errorMessage =
                'Incomplete classroom authorization credentials received from server.';
          });
        }
        return;
      }

      if (joinData.roomName.trim().isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorCategory = ClassroomErrorCategory.roomMismatch;
            _errorMessage =
                'Classroom room identifier is missing. Cannot connect to unauthorized session.';
          });
        }
        return;
      }

      if (joinData.isExpired) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorCategory = ClassroomErrorCategory.tokenExpired;
            _errorMessage =
                'Classroom authorization token has expired. Please retry to request a fresh token.';
          });
        }
        return;
      }

      // 4. Resolve Authenticated Meeting URI with JWT parameter:
      final targetUri = joinData.authenticatedMeetingUri;
      final jwtParam = targetUri.queryParameters['jwt'];

      if (jwtParam == null || jwtParam.trim().isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorCategory = ClassroomErrorCategory.viewerAuthFailure;
            _errorMessage =
                'Cannot open unauthenticated classroom URL without participant token.';
          });
        }
        return;
      }

      // Safe diagnostic logging without exposing sensitive tokens
      debugPrint(
        '[Classroom Viewer] Connecting to host: ${targetUri.host}, room: ${joinData.roomName}, isModerator: ${joinData.isModerator}',
      );

      // 5. Setup WebViewController for WebRTC Classroom:
      if (WebViewPlatform.instance == null) {
        debugPrint(
          '[Classroom Viewer] WebViewPlatform.instance is null (test environment). Skipping native controller instantiation.',
        );
        return;
      }

      late final PlatformWebViewControllerCreationParams params;
      if (WebViewPlatform.instance is AndroidWebViewPlatform) {
        params = AndroidWebViewControllerCreationParams();
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }

      final controller = WebViewController.fromPlatformCreationParams(params);

      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent(
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
        )
        ..setBackgroundColor(const Color(0xFF0F172A))
        ..addJavaScriptChannel(
          'FlutterClassroomBridge',
          onMessageReceived: (JavaScriptMessage message) {
            final msg = message.message;
            if (msg == 'classroom_exit' || msg == 'hangup') {
              debugPrint('[Classroom Viewer] Hangup received from viewer bridge');
              _handleClassroomExit();
            } else if (msg.startsWith('AUTH_ERROR:')) {
              debugPrint('[Classroom Viewer] Viewer authorization error reported by Jitsi');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorCategory = ClassroomErrorCategory.viewerAuthFailure;
                  _errorMessage =
                      'Classroom server rejected the participant authorization credentials.';
                });
              }
            }
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              if (mounted) {
                setState(() {
                  _loadingProgress = progress;
                });
              }
            },
            onPageStarted: (String url) {
              debugPrint('[Classroom Viewer] Viewer loading started');
              if (mounted) {
                setState(() {
                  _isLoading = true;
                });
              }
            },
            onPageFinished: (String url) {
              debugPrint('[Classroom Viewer] Viewer loading finished');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
              _injectClassroomBridge(controller);
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint(
                '[Classroom Viewer] WebResourceError: ${error.errorCode} - ${error.description}',
              );
              // Handle fatal connection/network failures on the main frame
              if (error.isForMainFrame ?? true) {
                final isNetError = error.errorCode == -2 || // ERROR_HOST_LOOKUP
                    error.errorCode == -6 || // ERROR_CONNECT
                    error.errorCode == -8 || // ERROR_TIMEOUT
                    error.description.toLowerCase().contains('net::err') ||
                    error.description.toLowerCase().contains('failed to connect');

                if (isNetError && mounted) {
                  setState(() {
                    _isLoading = false;
                    _errorCategory = ClassroomErrorCategory.networkFailure;
                    _errorMessage =
                        'Unable to reach classroom server. Please check your internet connection.';
                  });
                }
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              final uri = Uri.tryParse(request.url);
              if (uri != null && request.isMainFrame) {
                final path = uri.path.toLowerCase();
                // If Jitsi redirects to goodbye or static exit page, transition to exit handler
                if (path.contains('/static/close') ||
                    path.contains('/close') ||
                    path.contains('/goodbye') ||
                    path.contains('/feedback')) {
                  debugPrint(
                    '[Classroom Viewer] Detected terminal conference URL ($path) -> Transitioning to exit handler',
                  );
                  _handleClassroomExit();
                  return NavigationDecision.prevent;
                }
              }
              return NavigationDecision.navigate;
            },
          ),
        );

      if (controller.platform is AndroidWebViewController) {
        final androidController =
            controller.platform as AndroidWebViewController;
        androidController.setMediaPlaybackRequiresUserGesture(false);
        androidController.setOnPlatformPermissionRequest((request) {
          request.grant();
        });
      }

      await controller.loadRequest(targetUri);

      if (mounted) {
        setState(() {
          _controller = controller;
        });
      }
    } catch (e) {
      _handleJoinError(e);
    }
  }

  void _handleJoinError(Object e) {
    debugPrint('[Classroom Viewer] Catch error in _initializeClassroom: $e');
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (e is Failure) {
        if (e.statusCode == 401 || e is AuthFailure) {
          _errorCategory = ClassroomErrorCategory.viewerAuthFailure;
          _errorMessage =
              'Session expired or unauthorized. Please sign in again.';
        } else if (e.statusCode == 403) {
          _errorCategory = ClassroomErrorCategory.viewerAuthFailure;
          _errorMessage =
              'Access denied. You are not authorized to view this classroom.';
        } else if (e.statusCode == 404) {
          _errorCategory = ClassroomErrorCategory.sessionNotFound;
          _errorMessage =
              'This live classroom session was not found or has concluded.';
        } else if (e is NetworkFailure || e is TimeoutFailure) {
          _errorCategory = ClassroomErrorCategory.networkFailure;
          _errorMessage =
              'Network connection failed. Please check your internet connection.';
        } else {
          _errorCategory = ClassroomErrorCategory.tokenRequestFailure;
          _errorMessage = e.message;
        }
      } else {
        final str = e.toString().toLowerCase();
        if (str.contains('403') || str.contains('denied') || str.contains('unauthorized')) {
          _errorCategory = ClassroomErrorCategory.viewerAuthFailure;
          _errorMessage =
              'Access denied. You are not authorized to view this classroom.';
        } else if (str.contains('401') || str.contains('expired')) {
          _errorCategory = ClassroomErrorCategory.tokenExpired;
          _errorMessage =
              'Classroom authorization token has expired. Please retry.';
        } else if (str.contains('socket') || str.contains('network') || str.contains('timeout')) {
          _errorCategory = ClassroomErrorCategory.networkFailure;
          _errorMessage =
              'Network connection failure. Please check your connection and retry.';
        } else {
          _errorCategory = ClassroomErrorCategory.tokenRequestFailure;
          _errorMessage =
              'Failed to connect to classroom session. Please try again.';
        }
      }
    });
  }

  Future<void> _injectClassroomBridge(WebViewController controller) async {
    try {
      const jsCode = r'''
        (function() {
          try {
            // Fullscreen container styles
            if (!document.getElementById('truelern-classroom-styles')) {
              var style = document.createElement('style');
              style.id = 'truelern-classroom-styles';
              style.innerHTML = `
                body, html { 
                  background-color: #0F172A !important; 
                  overflow: hidden !important; 
                  margin: 0 !important; 
                  padding: 0 !important; 
                  width: 100vw !important; 
                  height: 100vh !important; 
                }
              `;
              document.head.appendChild(style);
            }

            function notifyExit() {
              if (window.FlutterClassroomBridge) {
                window.FlutterClassroomBridge.postMessage('classroom_exit');
              }
            }

            // 1. Listen for window unload or pagehide
            window.addEventListener('unload', notifyExit);
            window.addEventListener('beforeunload', notifyExit);
            window.addEventListener('pagehide', notifyExit);

            // 2. Poll for Jitsi APP.conference to attach event listeners
            var pollCount = 0;
            var checkInterval = setInterval(function() {
              pollCount++;
              if (window.APP && window.APP.conference) {
                clearInterval(checkInterval);
                try {
                  window.APP.conference.addConferenceListener('CONFERENCE_LEFT', function() {
                    notifyExit();
                  });
                  window.APP.conference.addConferenceListener('CONFERENCE_FAILED', function(err) {
                    if (window.FlutterClassroomBridge) {
                      window.FlutterClassroomBridge.postMessage('AUTH_ERROR:' + (err || 'FAILED'));
                    }
                  });
                } catch (e) {}
              }
              if (pollCount > 60) {
                clearInterval(checkInterval);
              }
            }, 500);

            // 3. Intercept clicks on any hangup / leave / end call buttons in the DOM
            document.addEventListener('click', function(e) {
              var target = e.target;
              while (target && target !== document.body && target !== document.documentElement) {
                var ariaLabel = (target.getAttribute && target.getAttribute('aria-label')) || '';
                var testId = (target.getAttribute && target.getAttribute('data-testid')) || '';
                var className = (target.className && typeof target.className === 'string') ? target.className : '';
                var lowerAria = ariaLabel.toLowerCase();
                var lowerTestId = testId.toLowerCase();
                var lowerClass = className.toLowerCase();

                if (
                  lowerAria.includes('leave') ||
                  lowerAria.includes('hang up') ||
                  lowerAria.includes('hangup') ||
                  lowerAria.includes('end call') ||
                  lowerTestId.includes('hangup') ||
                  lowerClass.includes('hangup-button')
                ) {
                  setTimeout(notifyExit, 250);
                  break;
                }
                target = target.parentElement;
              }
            }, true);
          } catch (e) {
            console.error('Classroom bridge error:', e);
          }
        })();
      ''';
      await controller.runJavaScript(jsCode);
    } catch (e) {
      debugPrint('[Classroom Viewer] Script injection error: $e');
    }
  }

  /// Handles user-initiated retry with debounce & in-flight guard to prevent duplicate token requests
  Future<void> _retryConnection() async {
    if (_isRetrying) return;
    final now = DateTime.now();
    if (_lastRetryTime != null &&
        now.difference(_lastRetryTime!) < const Duration(seconds: 2)) {
      return; // Debounce rapid repeated taps
    }
    _lastRetryTime = now;

    setState(() {
      _isRetrying = true;
    });

    try {
      await _initializeClassroom(forceRefresh: true);
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  /// Unified exit handler for the classroom session.
  /// Cleans up WebRTC and controller resources and navigates to the
  /// appropriate destination (Wait for Admin to Enroll for demo classes,
  /// or Class Summary for regular cohort classes).
  void _handleClassroomExit() {
    if (_hasExitedClassroom || !mounted) return;
    _hasExitedClassroom = true;

    // Clean up WebRTC / audio / video resources immediately to stop media playback
    try {
      _controller?.loadRequest(Uri.parse('about:blank'));
    } catch (_) {}

    if (_isDemoSession) {
      final effectiveBookingId = widget.booking?.bookingId ??
          widget.booking?.effectiveClassId ??
          widget.classId;

      debugPrint(
        '[Classroom Navigation] Demo call ended. Navigating to waiting screen for booking $effectiveBookingId',
      );

      // Preserve authenticated session, selected child identity, and demo booking info
      try {
        context.go(
          '${AppRoutePaths.demoWaitingForAdmin}?bookingId=$effectiveBookingId',
          extra: widget.booking,
        );
      } catch (e) {
        debugPrint('[Classroom Navigation] Navigation to waiting screen failed: $e');
      }
    } else {
      _navigateToSummary();
    }
  }

  /// Cleanly returns to the demo flow or previous screen when user cancels or error occurs before joining
  void _onBackToDemo() {
    if (_hasExitedClassroom || !mounted) return;
    _hasExitedClassroom = true;

    try {
      _controller?.loadRequest(Uri.parse('about:blank'));
    } catch (_) {}

    if (context.canPop()) {
      context.pop();
    } else if (widget.booking != null) {
      context.go(AppRoutePaths.demoClassPreJoin, extra: widget.booking);
    } else if (widget.fromDemo || widget.classId.startsWith('DEMO-')) {
      context.go('${AppRoutePaths.demoClassPreJoin}?bookingId=${widget.classId}');
    } else {
      _handleClassroomExit();
    }
  }

  /// Navigates to native Flutter Class Summary with single-guarded execution
  void _navigateToSummary() {
    if (_hasNavigatedToSummary || !mounted) return;
    _hasNavigatedToSummary = true;

    final effectiveClassId = _activeJoinData?.classId ?? widget.classId;
    debugPrint(
      '[Classroom Navigation] Navigating to Class Summary for class $effectiveClassId',
    );
    try {
      context.go(
        '/parent/classes/$effectiveClassId/summary',
        extra: {
          'session': widget.session,
          'childStudentId': widget.childStudentId,
        },
      );
    } catch (e) {
      debugPrint('[Classroom Navigation] GoRouter navigation error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _handleClassroomExit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Live Classroom WebView Container
                if (_controller != null)
                  Positioned.fill(
                    child: WebViewWidget(
                      key: const Key('live_classroom_webview'),
                      controller: _controller!,
                    ),
                  ),

                // Loading Overlay
                if (_isLoading)
                  Container(
                    color: const Color(0xFF0F172A),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF334155),
                              ),
                            ),
                            padding: const EdgeInsets.all(14),
                            child: const CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFE11D48),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Connecting to TrueLern Live Classroom...',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _loadingProgress > 0
                                ? 'Securing WebRTC stream: $_loadingProgress%'
                                : 'Authenticating child participant session',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Top floating exit button (accessible overlay - always on top of loading & classroom)
                if (_errorMessage == null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const Key('classroom_floating_leave_button'),
                        onTap: _handleClassroomExit,
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF334155),
                            ),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),

                // In-App Diagnostic Error State Overlay
                if (_errorMessage != null)
                  Container(
                    color: const Color(0xFF0F172A),
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF334155),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.videocam_off_rounded,
                                color: Color(0xFFEF4444),
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Classroom Connection Error',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Diagnostic Category Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF334155),
                                ),
                              ),
                              child: Text(
                                _errorCategory?.displayName ??
                                    ClassroomErrorCategory.unknown.displayName,
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF93C5FD),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                height: 1.45,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                OutlinedButton(
                                  key: const Key('classroom_back_to_demo_button'),
                                  onPressed: _isDemoSession ? _onBackToDemo : _navigateToSummary,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: Color(0xFF334155),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    _isDemoSession ? 'Back to Demo' : 'Return to Classes',
                                    style: GoogleFonts.hankenGrotesk(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  key: const Key('classroom_retry_button'),
                                  onPressed: _isRetrying ? null : _retryConnection,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE11D48),
                                    disabledBackgroundColor:
                                        const Color(0xFFE11D48).withValues(alpha: 0.5),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: _isRetrying
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          'Retry Connection',
                                          style: GoogleFonts.hankenGrotesk(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
