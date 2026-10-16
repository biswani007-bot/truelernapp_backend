import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_paths.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../domain/entities/demo_booking_entity.dart';

/// Displays the Demo Booking Confirmed Popup (Figma Node 75:793)
/// as a modal dialog with blur overlay, matching Figma specs 100%.
Future<void> showDemoBookingConfirmedPopup(
  BuildContext context, {
  String selectedDemo = 'Selected Demo Course',
  String dateTime = 'Today at 8:00 PM',
  String teacher = 'Ms. Sarah',
  Duration redirectDelay = const Duration(milliseconds: 2000),
  VoidCallback? onDismissToDashboard,
  DemoBookingEntity? booking,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Dismiss Confirmed Popup',
    barrierColor: const Color(0x66191C1E), // rgba(25, 28, 30, 0.4)
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, anim1, anim2) {
      return DemoBookingConfirmedPopup(
        selectedDemo: selectedDemo,
        dateTime: dateTime,
        teacher: teacher,
        redirectDelay: redirectDelay,
        onDismissToDashboard: onDismissToDashboard,
        booking: booking,
      );
    },
    transitionBuilder: (ctx, anim1, anim2, child) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
        child: FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
            child: child,
          ),
        ),
      );
    },
  );
}

/// Exact Figma Node 75:793 implementation ("Demo Booking Confirmed Popup").
class DemoBookingConfirmedPopup extends ConsumerStatefulWidget {
  const DemoBookingConfirmedPopup({
    super.key,
    this.selectedDemo = 'Selected Demo Course',
    this.dateTime = 'Today at 8:00 PM',
    this.teacher = 'Ms. Sarah',
    this.redirectDelay = const Duration(milliseconds: 2000),
    this.onDismissToDashboard,
    this.booking,
  });

  final String selectedDemo;
  final String dateTime;
  final String teacher;
  final Duration redirectDelay;
  final VoidCallback? onDismissToDashboard;
  final DemoBookingEntity? booking;

  @override
  ConsumerState<DemoBookingConfirmedPopup> createState() =>
      _DemoBookingConfirmedPopupState();
}

class _DemoBookingConfirmedPopupState
    extends ConsumerState<DemoBookingConfirmedPopup> {
  Timer? _redirectTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    if (widget.redirectDelay > Duration.zero) {
      _redirectTimer = Timer(widget.redirectDelay, _proceedToDashboard);
    }
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  void _proceedToDashboard() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _redirectTimer?.cancel();

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    if (widget.onDismissToDashboard != null) {
      widget.onDismissToDashboard!();
    } else {
      try {
        final authState = ref.read(authControllerProvider);
        if (authState is Authenticated) {
          context.go(AppRoutePaths.demoSessionBooked, extra: widget.booking);
        } else {
          context.go(AppRoutePaths.login);
        }
      } catch (_) {
        // Fallback for isolated widget tests without GoRouter
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      elevation: 0,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448.0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.1),
                  blurRadius: 15.0,
                  offset: Offset(0, 10),
                  spreadRadius: -3.0,
                ),
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.1),
                  blurRadius: 6.0,
                  offset: Offset(0, 4),
                  spreadRadius: -4.0,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Main Content (Node 75:799)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. Hero 3D Glossy Checkmark (Node 107:132 / 107:133)
                        SizedBox(
                          height: 128.0,
                          child: Center(
                            child: Image.asset(
                              'assets/images/demo_confirmed_check.png',
                              width: 145.0,
                              height: 128.0,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80.0,
                                  height: 80.0,
                                  decoration: const BoxDecoration(
                                    color: Color(0x1A0037B1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Color(0xFF0037B1),
                                    size: 40.0,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 16.0),

                        // 2. Booking Summary Box (Node 75:810)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(17.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F4F7),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: const Color.fromRGBO(196, 197, 215, 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Row 1: Selected Demo
                              _buildDetailRow(
                                label: 'SELECTED DEMO',
                                value: widget.selectedDemo,
                              ),

                              const SizedBox(height: 8.0),

                              // Row 2: Date & Time
                              _buildDetailRow(
                                label: 'DATE & TIME',
                                value: widget.dateTime,
                              ),

                              const SizedBox(height: 8.0),

                              // Row 3: Teacher
                              _buildDetailRow(
                                label: 'TEACHER',
                                value: widget.teacher,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16.0),

                        // 3. Heading: "Booking Confirmed.." (Node 75:805 / 75:806)
                        Text(
                          'Booking Confirmed..',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 25.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF191C1E),
                            height: 32 / 24,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16.0),

                        // 4. Info Box (Node 75:824)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(13.0),
                          decoration: BoxDecoration(
                            color: const Color(
                              0x0D0037B1,
                            ), // rgba(0, 55, 177, 0.05)
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: const Color(
                                0x1A0037B1,
                              ), // rgba(0, 55, 177, 0.1)
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SvgPicture.asset(
                                'assets/icons/demo_popup_info.svg',
                                width: 15.0,
                                height: 17.0,
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Text(
                                  'Booking details and meeting link will be sent to your email or WhatsApp immediately after confirmation.',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                    color: const Color(0xFF434655),
                                    height: 16 / 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16.0),

                        // 5. Security Trust Note (Node 75:839)
                        Text(
                          'SECURE RESERVATION • 100% FREE SESSION',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.1,
                            color: const Color(0xFF475569),
                            height: 16 / 11,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 8.0),
                      ],
                    ),
                  ),
                ),

                // Top-right Close Button (Node 75:796)
                Positioned(
                  top: 16.0,
                  right: 16.0,
                  child: InkWell(
                    key: const Key('demo_confirmed_popup_close_button'),
                    onTap: _proceedToDashboard,
                    borderRadius: BorderRadius.circular(9999.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SvgPicture.asset(
                        'assets/icons/demo_popup_close.svg',
                        width: 14.0,
                        height: 14.0,
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

  Widget _buildDetailRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: const Color(0xFF475569),
            height: 16 / 11,
          ),
        ),
        const SizedBox(width: 8.0),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 15.0,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF191C1E),
              height: 20 / 14,
            ),
          ),
        ),
      ],
    );
  }
}
