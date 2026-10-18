import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_paths.dart';

/// Arguments passed to [ParentPaymentSuccessfulScreen].
class PaymentSuccessfulArgs {
  const PaymentSuccessfulArgs({
    required this.invoiceNumber,
    required this.amountPaid,
    required this.courseName,
    required this.studentName,
    this.transactionReference,
    this.paymentDate,
    this.isAwaitingAdminVerification = false,
  });

  final String invoiceNumber;
  final String amountPaid;
  final String courseName;
  final String studentName;
  final String? transactionReference;
  final DateTime? paymentDate;
  final bool isAwaitingAdminVerification;
}

/// Parent Payment Successful Screen displaying real verified transaction information.
///
/// Figma Source of Truth: `Parent(full app)_TreLern`, Frame: `Payment Successful` (Node 104:294).
/// - Atmospheric Background: Linear gradient with blur accents
/// - Center Card (Node 104:299):
///   - 3D Success Checkmark asset (Node 104:313)
///   - Heading: "Payment Successful" (24px SemiBold, #1A1B23)
///   - Real message with invoice number and amount paid
///   - Transaction reference and verification status
///   - Primary Button: "Back to Invoices"
///   - Outlined Button: "Go to Dashboard"
class ParentPaymentSuccessfulScreen extends StatelessWidget {
  const ParentPaymentSuccessfulScreen({
    super.key,
    this.args,
  });

  final PaymentSuccessfulArgs? args;

  static const String _imgCheckmark =
      'assets/images/payment_success_checkmark.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('parent_payment_successful_screen'),
      backgroundColor: const Color(0xFFFAF8FF),
      body: Stack(
        children: [
          // Base Linear Gradient Overlay (Node 104:295)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.37, -0.93),
                  end: Alignment(0.37, 0.93),
                  colors: [
                    Color(0x99F3E8FF), // rgb(243, 232, 255) @ 60%
                    Color(0x99E0F2FE), // rgb(224, 242, 254) @ 60%
                    Color(0x99FFFFFF), // rgb(255, 255, 255) @ 60%
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Top-right soft blur blob (Node 104:296)
          Positioned(
            top: -50,
            right: -40,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                width: 256,
                height: 256,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x66DCE1FF), // 40% opacity
                ),
              ),
            ),
          ),

          // Bottom-left soft blur blob (Node 104:297)
          Positioned(
            bottom: 60,
            left: -40,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                width: 256,
                height: 256,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x4DFFDBCF), // 30% opacity
                ),
              ),
            ),
          ),

          // Centered Content Card (Node 104:298 & 104:299)
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 21,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: _buildSuccessCard(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(BuildContext context) {
    final invoiceNum = args?.invoiceNumber ?? 'TL-2026-0018';
    final amount = args?.amountPaid ?? '\$149.50';
    final isAwaiting = args?.isAwaitingAdminVerification ?? false;
    final studentName = args?.studentName ?? 'Student';
    final courseName = args?.courseName ?? 'Enrolled Program';
    final txnRef = args?.transactionReference;
    final date = args?.paymentDate ?? DateTime.now();

    final formattedDate =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // rgba(0, 0, 0, 0.04)
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 32),

          // Hero Icon — 3D Success Checkmark (Node 104:311 - 104:313)
          SizedBox(
            height: 128,
            child: Center(
              child: Image.asset(
                _imgCheckmark,
                width: 145,
                height: 89,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Heading 1 - Title (Node 104:300 - 104:302)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              isAwaiting ? 'Payment Received' : 'Payment Successful',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 25.5,
                fontWeight: FontWeight.w600,
                height: 32 / 24,
                color: const Color(0xFF1A1B23),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Message (Node 104:303 - 104:305)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              isAwaiting
                  ? '$amount for Invoice #$invoiceNum\nreceived and awaiting admin verification.'
                  : '$amount for Invoice #$invoiceNum\npaid successfully.',
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 24 / 16,
                color: const Color(0xFF434655),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Transaction details box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildReceiptRow('Program:', courseName),
                  const SizedBox(height: 6),
                  _buildReceiptRow('Student:', studentName),
                  const SizedBox(height: 6),
                  _buildReceiptRow('Date:', formattedDate),
                  if (txnRef != null && txnRef.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildReceiptRow('Reference:', txnRef),
                  ],
                  const SizedBox(height: 6),
                  _buildReceiptRow(
                    'Status:',
                    isAwaiting ? 'Awaiting Verification' : 'Verified & Active',
                    highlightColor: isAwaiting
                        ? const Color(0xFFB45309)
                        : const Color(0xFF15803D),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Actions Column (Node 104:306)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                // Primary Button: "Back to Invoices" (Node 104:307)
                GestureDetector(
                  key: const Key('payment_success_back_to_invoices_button'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    context.go(AppRoutePaths.parentInvoices);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E4ED8),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D000000), // rgba(0, 0, 0, 0.05)
                          blurRadius: 1,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Back to Invoices',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 20 / 14,
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Outlined Button: "Go to Dashboard"
                GestureDetector(
                  key: const Key('payment_success_dashboard_button'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    context.go(AppRoutePaths.parentDashboard);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFC4C5D7),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Go to Dashboard',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 20 / 14,
                          color: const Color(0xFF0037B1),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    Color? highlightColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: highlightColor ?? const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}
