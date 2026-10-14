import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import 'demo_booking_confirmed_popup.dart';

/// Displays the Demo Booking Confirmation Popup (Figma Node 74:624)
/// as a modal dialog with blur overlay, matching Figma specs 100%.
Future<void> showDemoBookingConfirmationPopup(
  BuildContext context, {
  String selectedDemo = 'ACE Public Speaking',
  String dateTime = 'Today at 8:00 PM',
  String teacher = 'Ms. Sarah',
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss Confirmation Popup',
    barrierColor: const Color(0x66191C1E), // rgba(25, 28, 30, 0.4)
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (ctx, anim1, anim2) {
      return DemoBookingConfirmationPopup(
        selectedDemo: selectedDemo,
        dateTime: dateTime,
        teacher: teacher,
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

/// Exact Figma Node 74:624 implementation ("Demo Booking Confirmation Popup").
class DemoBookingConfirmationPopup extends StatelessWidget {
  const DemoBookingConfirmationPopup({
    super.key,
    this.selectedDemo = 'ACE Public Speaking',
    this.dateTime = 'Today at 8:00 PM',
    this.teacher = 'Ms. Sarah',
  });

  final String selectedDemo;
  final String dateTime;
  final String teacher;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 12.0,
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
                // Main Content (Node 74:630)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 1. Checkmark Badge (Node 74:631)
                        Container(
                          width: 80.0,
                          height: 80.0,
                          decoration: const BoxDecoration(
                            color: Color(0x1A0037B1), // rgba(0, 55, 177, 0.1)
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(34, 81, 218, 0.2),
                                blurRadius: 20.0,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: SvgPicture.asset(
                            'assets/icons/demo_popup_check.svg',
                            width: 40.0,
                            height: 40.0,
                          ),
                        ),

                        const SizedBox(height: 16.0),

                        // 2. Heading: "Ready to Start?" (Node 74:636)
                        Text(
                          'Ready to Start?',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 25.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF191C1E),
                            height: 32 / 24,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 4.0),

                        // 3. Subtitle Description (Node 74:638)
                        Text(
                          'Confirm your selection for the ACE Public\nSpeaking Program demo.',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 15.0,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF475569),
                            height: 20 / 14,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16.0),

                        // 4. Booking Summary Box (Node 74:641)
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
                                value: selectedDemo,
                              ),

                              const SizedBox(height: 8.0),

                              // Row 2: Date & Time
                              _buildDetailRow(
                                label: 'DATE & TIME',
                                value: dateTime,
                              ),

                              const SizedBox(height: 8.0),

                              // Row 3: Teacher
                              _buildDetailRow(label: 'TEACHER', value: teacher),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16.0),

                        // 5. Info Box (Node 74:655)
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
                                  'Secure meeting link and prep materials will be sent to your email immediately after confirmation.',
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

                        // 6. Confirm Booking Button (Node 74:661)
                        InkWell(
                          key: const Key('demo_popup_confirm_button'),
                          onTap: () {
                            Navigator.of(context).pop();
                            showDemoBookingConfirmedPopup(
                              context,
                              selectedDemo: selectedDemo,
                              dateTime: dateTime,
                              teacher: teacher,
                            );
                          },
                          borderRadius: BorderRadius.circular(8.0),
                          child: Container(
                            width: double.infinity,
                            height: 52.0,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0037B1),
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.1),
                                  blurRadius: 6.0,
                                  offset: Offset(0, 4),
                                  spreadRadius: -1.0,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Confirm Booking',
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.1,
                                    color: Colors.white,
                                    height: 20 / 14,
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                SvgPicture.asset(
                                  'assets/icons/demo_popup_arrow.svg',
                                  width: 16.0,
                                  height: 16.0,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16.0),

                        // 7. Security Trust Note (Node 74:670)
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
                      ],
                    ),
                  ),
                ),

                // Top-right Close Button (Node 74:627)
                Positioned(
                  top: 16.0,
                  right: 16.0,
                  child: InkWell(
                    key: const Key('demo_popup_close_button'),
                    onTap: () => Navigator.of(context).pop(),
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
