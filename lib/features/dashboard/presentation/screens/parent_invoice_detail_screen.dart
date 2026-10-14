import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../core/router/route_paths.dart';
import 'parent_payment_successful_screen.dart';

/// Parent Invoice Detail Screen — PURE FRONTEND ONLY.
///
/// Figma Source of Truth: `Parent(full app)_TreLern`, Frame: `Invoice Detail` (Node 104:198).
/// Displays the exact Figma design:
/// - Top App Bar: Back button and centered title "Invoice Detail" (Node 104:209)
/// - Background: Linear gradient (Lavender -> Sky Blue -> White)
/// - Invoice Card (Node 104:217):
///   - Top decorative accent: Blue to rose horizontal gradient bar (Node 104:293)
///   - Header: "INVOICE NUMBER", "#TL-2026-0018", and "Unpaid" badge (Node 104:218)
///   - Dates: Issued Date (Aug 15, 2026), Due Date (Sep 15, 2026) (Node 104:228)
///   - Details: Billed To (Sarah Jenkins), Student & Program (Mia, Emotional Intelligence) (Node 104:237)
///   - Breakdown: Program Fee ($299.00), Discount (-$50.00), Tax ($0.00), Total ($249.00), Amount Paid (-$100.00) (Node 104:257)
///   - Total Due box: "Balance Due" & "$149.00" (Node 104:288)
/// - Bottom Action Buttons (Node 104:199):
///   - Primary Button: "Pay $149.00" with credit card icon
///   - Outlined Button: "Download Invoice" with download icon
///
/// STRICT RULES:
/// - Zero backend calls / Zero API calls / Pure static frontend
/// - No bottom navigation bar (matching Figma Node 104:198)
class ParentInvoiceDetailScreen extends StatelessWidget {
  const ParentInvoiceDetailScreen({super.key});

  static const _svgCard = 'assets/icons/inv_detail_card.svg';
  static const _svgDownload = 'assets/icons/inv_detail_download.svg';
  static const _svgBackArrow = 'assets/icons/inv_detail_back.svg';
  static const _svgUnpaid = 'assets/icons/inv_detail_unpaid.svg';
  static const _svgHeart = 'assets/icons/inv_detail_heart.svg';
  static const _svgDiscount = 'assets/icons/inv_detail_discount.svg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('parent_invoice_detail_screen'),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
          child: Stack(
            children: [
              // Scrollable Main Content Column (Node 104:216)
              Column(
                children: [
                  // Top App Bar (Node 104:209)
                  _buildTopHeader(context),

                  // Main Content ScrollView
                  Expanded(
                    child: AppRefreshIndicator(
                      onRefresh: () async {
                        await Future<void>.delayed(
                          const Duration(milliseconds: 600),
                        );
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 160),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 448),
                            child: _buildInvoiceCard(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Fixed Bottom Action Buttons (Node 104:199)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomActionButtons(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Top App Bar matching Figma Node 104:209 & 104:210
  Widget _buildTopHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xCCFFFFFF), // rgba(255, 255, 255, 0.8)
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000), // rgba(0, 0, 0, 0.05)
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button (Node 104:211)
          InkWell(
            borderRadius: BorderRadius.circular(9999),
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutePaths.parentInvoices);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: SvgPicture.asset(_svgBackArrow, width: 16, height: 16),
            ),
          ),

          // Centered Title "Invoice Detail" (Node 104:215)
          Expanded(
            child: Center(
              child: Text(
                'Invoice Detail',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 25.5,
                  fontWeight: FontWeight.w700,
                  height: 32 / 24,
                  color: const Color(0xFF191C1E),
                ),
              ),
            ),
          ),

          // Symmetry balancing box matching back button width
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  /// Main Invoice Card matching Figma Node 104:217
  Widget _buildInvoiceCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // rgba(0, 0, 0, 0.04)
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Decorative accent bar (Node 104:293): 8px height, gradient #0037B1 to #FB7185
            Container(
              height: 8,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0037B1), Color(0xFFFB7185)],
                ),
              ),
            ),

            // Card body padding 24px
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Invoice Header Row (Node 104:218)
                  _buildInvoiceHeader(),

                  const SizedBox(height: 24),

                  // Dates Row (Node 104:228)
                  _buildDatesRow(),

                  const SizedBox(height: 24),

                  // Details Box (Node 104:237)
                  _buildDetailsBox(),

                  const SizedBox(height: 24),

                  // Breakdown Section (Node 104:257)
                  _buildBreakdownSection(),

                  const SizedBox(height: 24),

                  // Total Due Box (Node 104:288)
                  _buildTotalDueBox(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header with Invoice Number and Status Badge (Node 104:218)
  Widget _buildInvoiceHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 25),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E1ED), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Invoice Number column (Node 104:219)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INVOICE NUMBER',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 17,
                  fontWeight: FontWeight.normal,
                  letterSpacing: 0.8,
                  height: 24 / 16,
                  color: const Color(0xFF747686),
                ),
              ),
              const SizedBox(height: 4.5),
              Text(
                '#TL-2026-0018',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 17,
                  fontWeight: FontWeight.normal,
                  height: 24 / 16,
                  color: const Color(0xFF1A1B23),
                ),
              ),
            ],
          ),

          // Unpaid status pill badge (Node 104:224)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8E7F3),
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  _svgUnpaid,
                  width: 12.67,
                  height: 14,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 4),
                Text(
                  'Unpaid',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.normal,
                    height: 24 / 16,
                    color: const Color(0xFF1A1B23),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Dates Row matching Figma Node 104:228
  Widget _buildDatesRow() {
    return Row(
      children: [
        // Issued Date (Node 104:229)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Issued Date',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 17,
                  fontWeight: FontWeight.normal,
                  height: 24 / 16,
                  color: const Color(0xFF747686),
                ),
              ),
              Text(
                'Aug 15, 2026',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  height: 24 / 16,
                  color: const Color(0xFF434655),
                ),
              ),
            ],
          ),
        ),

        // Due Date (Node 104:233)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Due Date',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 17,
                  fontWeight: FontWeight.normal,
                  height: 24 / 16,
                  color: const Color(0xFF747686),
                ),
              ),
              Text(
                'Sep 15, 2026',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  height: 24 / 16,
                  color: const Color(0xFF434655),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Details Box matching Figma Node 104:237
  Widget _buildDetailsBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0x80E2E1ED), // rgba(226, 225, 237, 0.5)
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Billed To section (Node 104:238)
          Text(
            'Billed To',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.normal,
              height: 24 / 16,
              color: const Color(0xFF747686),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sarah Jenkins',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.normal,
              height: 24 / 16,
              color: const Color(0xFF1A1B23),
            ),
          ),

          const SizedBox(height: 16),

          // Horizontal Divider (Node 104:243)
          Container(
            height: 1,
            width: double.infinity,
            color: const Color(0x80E2E1ED),
          ),

          const SizedBox(height: 16),

          // Student & Program section (Node 104:244)
          Text(
            'Student & Program',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.normal,
              height: 24 / 16,
              color: const Color(0xFF747686),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              // Purple circle avatar with 'M' (Node 104:248)
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF8A4CFC),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  'M',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Student name and program tag column (Node 104:250)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mia',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 17,
                      fontWeight: FontWeight.normal,
                      height: 20 / 16,
                      color: const Color(0xFF1A1B23),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Tag: Emotional Intelligence (Node 104:253)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0x1AFB7185,
                      ), // rgba(251, 113, 133, 0.1)
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          _svgHeart,
                          width: 11.67,
                          height: 10.7,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Emotional Intelligence',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 17,
                            fontWeight: FontWeight.normal,
                            height: 24 / 16,
                            color: const Color(0xFFFB7185),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Breakdown Section matching Figma Node 104:257
  Widget _buildBreakdownSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Program Fee
        _buildBreakdownRow(
          label: 'Program Fee',
          value: '\$299.00',
          labelColor: const Color(0xFF434655),
          valueColor: const Color(0xFF434655),
        ),

        const SizedBox(height: 11.5),

        // Discount with icon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SvgPicture.asset(
                  _svgDiscount,
                  width: 13.32,
                  height: 13.33,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 4),
                Text(
                  'Discount',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.normal,
                    height: 24 / 16,
                    color: const Color(0xFFFB7185),
                  ),
                ),
              ],
            ),
            Text(
              '-\$50.00',
              style: GoogleFonts.hankenGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.normal,
                height: 24 / 16,
                color: const Color(0xFFFB7185),
              ),
            ),
          ],
        ),

        const SizedBox(height: 11.5),

        // Tax
        _buildBreakdownRow(
          label: 'Tax',
          value: '\$0.00',
          labelColor: const Color(0xFF434655),
          valueColor: const Color(0xFF434655),
        ),

        const SizedBox(height: 8),

        // Divider
        Container(
          height: 1,
          width: double.infinity,
          color: const Color(0xFFE2E1ED),
        ),

        const SizedBox(height: 8),

        // Total
        _buildBreakdownRow(
          label: 'Total',
          value: '\$249.00',
          labelColor: const Color(0xFF1A1B23),
          valueColor: const Color(0xFF1A1B23),
        ),

        const SizedBox(height: 11.5),

        // Amount Paid
        _buildBreakdownRow(
          label: 'Amount Paid',
          value: '-\$100.00',
          labelColor: const Color(0xFF434655),
          valueColor: const Color(0xFF434655),
        ),
      ],
    );
  }

  /// Single Breakdown Row helper
  Widget _buildBreakdownRow({
    required String label,
    required String value,
    required Color labelColor,
    required Color valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 17,
            fontWeight: FontWeight.normal,
            height: 24 / 16,
            color: labelColor,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 17,
            fontWeight: FontWeight.normal,
            height: 24 / 16,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  /// Total Due Box matching Figma Node 104:288
  Widget _buildTotalDueBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0x1A1E4ED8), // rgba(30, 78, 216, 0.1)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0x331E4ED8), // rgba(30, 78, 216, 0.2)
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Balance Due',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.normal,
              height: 24 / 16,
              color: const Color(0xFF0037B1),
            ),
          ),
          Text(
            '\$149.00',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              height: 24 / 16,
              color: const Color(0xFF0037B1),
            ),
          ),
        ],
      ),
    );
  }

  /// Fixed Bottom Action Buttons matching Figma Node 104:199
  Widget _buildBottomActionButtons(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xE6FFFFFF), // rgba(255, 255, 255, 0.9)
        border: Border(
          top: BorderSide(
            color: Color(0x80E2E1ED), // rgba(226, 225, 237, 0.5)
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000), // rgba(0, 0, 0, 0.04)
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Primary "Pay $149.00" Button (Node 104:201)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  try {
                    context.push(AppRoutePaths.paymentSuccessful);
                  } catch (_) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ParentPaymentSuccessfulScreen(),
                      ),
                    );
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0037B1),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000), // rgba(0, 0, 0, 0.05)
                        blurRadius: 1,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        _svgCard,
                        width: 16.67,
                        height: 13.33,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pay \$149.00',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          height: 24 / 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Outlined "Download Invoice" Button (Node 104:205)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // Frontend-only action
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF747686),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        _svgDownload,
                        width: 13.33,
                        height: 13.33,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Download Invoice',
                        style: GoogleFonts.hankenGrotesk(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          height: 24 / 16,
                          color: const Color(0xFF434655),
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
}
