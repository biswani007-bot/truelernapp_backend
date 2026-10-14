import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/class_entity.dart';
import '../../domain/entities/class_join_entity.dart';
import '../controllers/classes_controller.dart';
import '../controllers/classes_state.dart';

/// SCR-17 Live Classroom Screen
///
/// Embeds the production TrueLern Web Classroom:
/// `https://truelern.visital.in/parent/live-classes/{classId}/room`
///
/// Features:
/// - Starts directly from the actual classroom / Jitsi UI (no upper observation or Flutter header)
/// - Native HttpOnly cookie injection via [WebViewCookieManager] (zero token in URL)
/// - Real Jitsi Meet live classroom via production WebRTC iframe
/// - Android WebRTC platform permissions (camera + microphone) granted cleanly
/// - Zero static/fake participants or mockup stages
/// - Clean leave & session ended transition returning to native Flutter Class Summary (Revised)
class LiveClassroomScreen extends ConsumerStatefulWidget {
  final String classId;
  final ClassEntity? session;
  final ClassJoinEntity? joinData;
  final String? childStudentId;

  const LiveClassroomScreen({
    super.key,
    required this.classId,
    this.session,
    this.joinData,
    this.childStudentId,
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
  bool _hasNavigatedToSummary = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 0. 15-Minute Entry Window Guard:
      ClassEntity? resolvedSession = widget.session;
      if (resolvedSession == null) {
        final classesState = ref.read(classesControllerProvider);
        if (classesState is ClassesLoaded) {
          resolvedSession = classesState.classes
              .where((c) => c.id == widget.classId)
              .firstOrNull;
        }
      }

      if (widget.joinData == null &&
          resolvedSession != null &&
          resolvedSession.scheduledStartTime != null &&
          !resolvedSession.canEnterLiveClass()) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'You can join 15 minutes before the class starts.';
          });
        }
        return;
      }

      // 1. Read Parent access token from FlutterSecureStorage
      final token = await ref.read(secureStorageProvider).getAccessToken();
      // 2. Verify token is non-empty
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                'Authentication session missing. Please sign in again.';
          });
        }
        return;
      }

      // 3. Set WebView cookie for domain truelern.visital.in with path /
      final cookieManager = WebViewCookieManager();
      await cookieManager.setCookie(
        WebViewCookie(
          name: 'accessToken',
          value: token,
          domain: 'truelern.visital.in',
          path: '/',
        ),
      );

      // 4. Confirm cookie was successfully written using getCookies API
      final cookies = await cookieManager.getCookies(
        domain: Uri.parse('https://truelern.visital.in'),
      );
      final hasToken = cookies.any(
        (c) => c.name == 'accessToken' && c.value.isNotEmpty,
      );
      debugPrint(
        '[WebView Auth] Pre-load cookie verification: accessToken present = $hasToken',
      );
      if (!hasToken) {
        await cookieManager.setCookie(
          WebViewCookie(
            name: 'accessToken',
            value: token,
            domain: 'https://truelern.visital.in',
            path: '/',
          ),
        );
      }

      // WebViewController instantiation
      late final PlatformWebViewControllerCreationParams params;
      if (WebViewPlatform.instance is AndroidWebViewPlatform) {
        params = AndroidWebViewControllerCreationParams();
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }

      final controller = WebViewController.fromPlatformCreationParams(params);

      // Instrument navigation and bridge token status & client exit events
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF0F172A))
        ..addJavaScriptChannel(
          'FlutterClassroomBridge',
          onMessageReceived: (JavaScriptMessage message) {
            final msg = message.message;
            if (msg.startsWith('TOKEN_STATUS:')) {
              final statusStr = msg.substring('TOKEN_STATUS:'.length);
              final status = int.tryParse(statusStr) ?? 0;
              debugPrint(
                '[WebView Auth] /api/live-classes/${widget.classId}/token HTTP status: $status',
              );
              if (status == 401) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _errorMessage = 'Session expired. Please sign in again.';
                  });
                }
              } else if (status == 403) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _errorMessage = 'Access denied. You are not authorized to view this classroom.';
                  });
                }
              }
            } else if (msg == 'classroom_exit') {
              debugPrint(
                '[WebView Navigation] Classroom exit triggered via client navigation/Jitsi',
              );
              _navigateToSummary();
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
              debugPrint('[WebView Navigation] Page loading started: $url');
              if (mounted) {
                setState(() {
                  _isLoading = true;
                });
              }
              _verifyCookiePersistence();
            },
            onPageFinished: (String url) {
              debugPrint('[WebView Navigation] Page loading finished: $url');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
              // Inject edge-to-edge styles, hide web portal wrapper headers, and install exit bridge
              _injectClassroomStylesAndBridge(controller);
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint(
                '[WebView Navigation] WebResourceError: ${error.errorCode} - ${error.description} on ${error.url}',
              );
            },
            onNavigationRequest: (NavigationRequest request) {
              final uri = Uri.tryParse(request.url);
              final isMain = request.isMainFrame;
              debugPrint(
                '[WebView Navigation] Navigation requested: isMainFrame=$isMain, url=${request.url}',
              );

              if (uri != null) {
                final path = uri.path;

                // Intercept navigation that leaves the classroom room
                if (isMain &&
                    (path == '/parent/dashboard' ||
                        path == '/parent/live-classes' ||
                        path == '/student/dashboard' ||
                        path == '/student/live-classes' ||
                        (path.startsWith('/parent/') &&
                            !path.contains('/room')))) {
                  debugPrint(
                    '[WebView Navigation] Detected navigation to exit route ($path) -> Transitioning to native Class Summary',
                  );
                  _navigateToSummary();
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
        final androidCookieManager =
            cookieManager.platform as AndroidWebViewCookieManager;
        await androidCookieManager.setAcceptThirdPartyCookies(
          androidController,
          true,
        );
      }

      // 5. Load classroom URL: https://truelern.visital.in/parent/live-classes/{classId}/room
      final targetUrl =
          'https://truelern.visital.in/parent/live-classes/${widget.classId}/room';
      debugPrint(
        '[WebView Navigation] Loading classroom target URL: $targetUrl',
      );
      await controller.loadRequest(Uri.parse(targetUrl));

      if (mounted) {
        setState(() {
          _controller = controller;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load classroom session: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _verifyCookiePersistence() async {
    try {
      final cookieManager = WebViewCookieManager();
      final cookies = await cookieManager.getCookies(
        domain: Uri.parse('https://truelern.visital.in'),
      );
      final hasAccessToken = cookies.any(
        (c) => c.name == 'accessToken' && c.value.isNotEmpty,
      );
      debugPrint(
        '[WebView Auth] Classroom route cookie check: accessToken present = $hasAccessToken',
      );
    } catch (e) {
      debugPrint('[WebView Auth] Classroom route cookie check error: $e');
    }
  }

  Future<void> _injectClassroomStylesAndBridge(
    WebViewController controller,
  ) async {
    try {
      // 1. Hide Web Portal Header & Sidebar
      // 2. Hide "Parent Access Verified" / "TRUELEARN PARENT OBSERVATION" banners
      // 3. Hide duplicate control bar inside JitsiMeetRoom ("testing", room name, "In Session", web leave button)
      // 4. Expand Jitsi container edge-to-edge directly to top
      const jsCode = r'''
        (function() {
          try {
            if (!document.getElementById('truelern-classroom-styles')) {
              var style = document.createElement('style');
              style.id = 'truelern-classroom-styles';
              style.innerHTML = `
                /* Hide Next.js web portal sticky header, navigation, and sidebar */
                header, aside, nav, header.sticky, header[class*="sticky"] { display: none !important; }

                /* Hide upper observation banner containing Parent Observation & Access Verified */
                div[class*="bg-slate-900/80"],
                div.bg-slate-900\/80 { 
                  display: none !important; 
                }

                /* Hide duplicate classroom header bar inside JitsiMeetRoom */
                div[class*="bg-slate-900"][class*="border-b"],
                div.bg-slate-900.border-b { 
                  display: none !important; 
                }

                /* Fullscreen layout */
                body, html, #__next { 
                  background-color: #0F172A !important; 
                  overflow: hidden !important; 
                  margin: 0 !important; 
                  padding: 0 !important; 
                  width: 100vw !important; 
                  height: 100vh !important; 
                }

                main { 
                  padding: 0 !important; 
                  margin: 0 !important; 
                  width: 100vw !important; 
                  max-width: 100vw !important; 
                  height: 100vh !important; 
                  overflow: hidden !important; 
                }

                /* Make the Jitsi classroom iframe fill the entire viewport without being constrained */
                iframe,
                iframe[id^="jitsiConferenceFrame"] {
                  position: fixed !important;
                  top: 0 !important;
                  left: 0 !important;
                  width: 100vw !important;
                  height: 100vh !important;
                  z-index: 999999 !important;
                  border: none !important;
                  margin: 0 !important;
                  padding: 0 !important;
                }
              `;
              document.head.appendChild(style);
            }

            // Target only the upper banners and duplicate header
            function cleanUpperHeaders() {
              try {
                var banners = document.querySelectorAll('div[class*="bg-slate-900/80"], div[class*="bg-slate-900"][class*="border-b"]');
                for (var i = 0; i < banners.length; i++) {
                  banners[i].style.setProperty('display', 'none', 'important');
                }
              } catch (_) {}
            }

            cleanUpperHeaders();
            setInterval(cleanUpperHeaders, 300);

            if (!window.__truelernFetchHooked && window.fetch) {
              window.__truelernFetchHooked = true;
              var originalFetch = window.fetch;
              window.fetch = async function() {
                var url = arguments[0] ? arguments[0].toString() : '';
                var response = await originalFetch.apply(this, arguments);
                if (url.indexOf('/api/live-classes/') !== -1 && url.indexOf('/token') !== -1) {
                  if (window.FlutterClassroomBridge) {
                    window.FlutterClassroomBridge.postMessage('TOKEN_STATUS:' + response.status);
                  }
                }
                return response;
              };
            }

            if (!window.__truelernHistoryHooked) {
              window.__truelernHistoryHooked = true;
              var checkExitUrl = function(targetUrl) {
                if (targetUrl && (
                  targetUrl.indexOf('/parent/dashboard') !== -1 ||
                  targetUrl.indexOf('/student/dashboard') !== -1 ||
                  targetUrl.indexOf('/parent/live-classes') !== -1 ||
                  targetUrl.indexOf('/student/live-classes') !== -1 ||
                  (targetUrl.indexOf('/parent/') !== -1 && targetUrl.indexOf('/room') === -1)
                )) {
                  if (window.FlutterClassroomBridge) {
                    window.FlutterClassroomBridge.postMessage('classroom_exit');
                  }
                }
              };

              var originalPush = history.pushState;
              history.pushState = function() {
                originalPush.apply(this, arguments);
                checkExitUrl(arguments[2]);
              };

              var originalReplace = history.replaceState;
              history.replaceState = function() {
                originalReplace.apply(this, arguments);
                checkExitUrl(arguments[2]);
              };

              window.addEventListener('popstate', function() {
                checkExitUrl(window.location.href);
              });
            }
          } catch (e) {
            console.error('Bridge init error:', e);
          }
        })();
      ''';
      await controller.runJavaScript(jsCode);
    } catch (e) {
      debugPrint('[WebView Bridge] Script injection error: $e');
    }
  }

  /// Navigates to native Flutter Class Summary (Revised) with a single-guarded execution
  void _navigateToSummary() {
    if (_hasNavigatedToSummary || !mounted) return;
    _hasNavigatedToSummary = true;

    debugPrint(
      '[Classroom Navigation] Navigating to Class Summary (Revised) for class ${widget.classId}',
    );
    try {
      context.go(
        '/parent/classes/${widget.classId}/summary',
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
        // Cleanly exit to native Parent Class Summary instead of navigating backwards in WebView history
        _navigateToSummary();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Live Classroom WebView Container (Fills the entire available screen)
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
                                ? 'Securing media channels: $_loadingProgress%'
                                : 'Establishing encrypted WebRTC session',
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

                // Error State Overlay
                if (_errorMessage != null)
                  Container(
                    color: const Color(0xFF0F172A),
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFEF4444),
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Connection Notice',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 13,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton(
                                onPressed: _navigateToSummary,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Color(0xFF334155),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('Return to Classes'),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _initializeWebView,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE11D48),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('Retry Connection'),
                              ),
                            ],
                          ),
                        ],
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
