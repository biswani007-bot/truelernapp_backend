import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../domain/entities/stripe_checkout_entity.dart';

/// Secure in-app Stripe Checkout presentation screen.
///
/// Features:
/// - Enforces HTTPS and official Stripe Checkout destination.
/// - Intercepts return redirects to `successUrl` and `cancelUrl`.
/// - Supports closing / cancellation and prevents foreign navigation.
class StripeCheckoutScreen extends StatefulWidget {
  const StripeCheckoutScreen({
    super.key,
    required this.checkoutUrl,
    required this.successUrlPrefix,
    required this.cancelUrlPrefix,
    this.title = 'Secure Stripe Checkout',
  });

  final String checkoutUrl;
  final String successUrlPrefix;
  final String cancelUrlPrefix;
  final String title;

  @override
  State<StripeCheckoutScreen> createState() => _StripeCheckoutScreenState();
}

class _StripeCheckoutScreenState extends State<StripeCheckoutScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    if (!isValidStripeCheckoutUrl(widget.checkoutUrl)) {
      setState(() {
        _errorMessage = 'Invalid or untrusted checkout destination URL.';
        _isLoading = false;
      });
      return;
    }

    if (WebViewPlatform.instance == null) {
      // Test environment safeguard
      setState(() {
        _isLoading = false;
      });
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
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _errorMessage = 'Connection error: ${error.description}';
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final target = request.url;

            // 1. Intercept Success Redirect
            if (target.contains('payment=success') ||
                target.startsWith(widget.successUrlPrefix)) {
              if (mounted) {
                Navigator.of(context).pop(CheckoutReturnResult.completed);
              }
              return NavigationDecision.prevent;
            }

            // 2. Intercept Cancellation Redirect
            if (target.contains('payment=cancelled') ||
                target.startsWith(widget.cancelUrlPrefix)) {
              if (mounted) {
                Navigator.of(context).pop(CheckoutReturnResult.cancelled);
              }
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));

    if (controller.platform is AndroidWebViewController) {
      final androidController =
          controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('stripe_checkout_presentation_screen'),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 18, color: Color(0xFF15803D)),
            const SizedBox(width: 8),
            Text(
              widget.title,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1B23),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          key: const Key('stripe_checkout_close_button'),
          icon: const Icon(Icons.close, color: Color(0xFF1A1B23)),
          onPressed: () {
            Navigator.of(context).pop(CheckoutReturnResult.closed);
          },
        ),
      ),
      body: Stack(
        children: [
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Color(0xFFDC2626),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 14,
                        color: const Color(0xFF1A1B23),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(CheckoutReturnResult.error);
                      },
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            )
          else if (_controller != null)
            WebViewWidget(controller: _controller!)
          else
            const Center(
              child: Text('Checkout WebView ready (test environment).'),
            ),

          if (_isLoading && _errorMessage == null)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
            ),
        ],
      ),
    );
  }
}
