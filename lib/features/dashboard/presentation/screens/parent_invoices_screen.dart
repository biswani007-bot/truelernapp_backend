import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../core/router/route_paths.dart';
import '../widgets/parent_hamburger_drawer.dart';

/// Parent Invoices Screen — PURE FRONTEND ONLY.
///
/// Figma Source of Truth: `Parent(full app)_TreLern`, Frame: `Invoices` (Node 104:106).
/// Displays the exact Figma design:
/// - Top App Bar: Back button and centered title "Invoices" (Node 104:191)
/// - Background: Linear gradient (Lavender -> Sky Blue -> White)
/// - Top Summary Card: Outstanding balance ($299.00), Next payment box (Node 104:108)
/// - Filter Chips: All Children, Mia, Alex (Node 104:126)
/// - Invoice List (Node 104:134):
///   - Card 1 (DUE): Mia, Emotional Intelligence, $149.50, #TL-2026-0018, Due: Sep 15, 2026, View Invoice (Primary)
///   - Card 2 (PAID): Mia, Communication & Public Speaking, $299.00, #TL-2026-0012, Paid: Aug 15, 2026, View Invoice (Outlined)
///
/// STRICT RULES:
/// - Zero backend calls / Zero API calls / Pure static frontend
/// - No bottom navigation bar (matching Figma Node 104:106)
class ParentInvoicesScreen extends StatefulWidget {
  const ParentInvoicesScreen({super.key});

  @override
  State<ParentInvoicesScreen> createState() => _ParentInvoicesScreenState();
}

class _ParentInvoicesScreenState extends State<ParentInvoicesScreen> {
  static const _svgCalendar = 'assets/icons/inv_calendar.svg';
  static const _svgHeart = 'assets/icons/inv_heart.svg';
  static const _svgDueAlert = 'assets/icons/inv_due_alert.svg';
  static const _svgArrowWhite = 'assets/icons/inv_arrow_white.svg';
  static const _svgMic = 'assets/icons/inv_mic.svg';
  static const _svgPaidCheck = 'assets/icons/inv_paid_check.svg';
  static const _svgArrowBlue = 'assets/icons/inv_arrow_blue.svg';
  static const _svgBackArrow = 'assets/icons/inv_back_arrow.svg';

  int _selectedFilterIndex = 0; // 0: All Children, 1: Mia, 2: Alex

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('parent_invoices_screen'),
      drawer: const ParentHamburgerDrawer(),
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
          child: Column(
            children: [
              // Top App Bar (Node 104:191)
              _buildTopHeader(context),

              // Main Content ScrollView (Node 104:107)
              Expanded(
                child: AppRefreshIndicator(
                  onRefresh: () async {
                    await Future<void>.delayed(
                      const Duration(milliseconds: 600),
                    );
                    if (mounted) setState(() {});
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 448),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),

                            // Top Summary Card (Node 104:108)
                            _buildTopSummaryCard(),

                            const SizedBox(height: 24),

                            // Child Filter Section (Node 104:126)
                            _buildChildFilterSection(),

                            const SizedBox(height: 24),

                            // Invoice List Section (Node 104:134)
                            _buildInvoiceListSection(context),

                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
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

  /// Top App Bar matching Figma Node 104:191 & 104:192
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
          // Back button (Node 104:193)
          InkWell(
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
              child: SvgPicture.asset(_svgBackArrow, width: 16, height: 16),
            ),
          ),

          // Centered Title "Invoices" (Node 104:197)
          Expanded(
            child: Center(
              child: Text(
                'Invoices',
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

  /// Section - Top Summary Card matching Figma Node 104:108
  Widget _buildTopSummaryCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xE6FFFFFF), // rgba(255, 255, 255, 0.9)
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0x80FFFFFF), // rgba(255, 255, 255, 0.5)
          width: 1,
        ),
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
        child: Stack(
          children: [
            // Decorative top-right blur circle (Node 104:109)
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFB7C4FF).withValues(alpha: 0.8),
                      const Color(0xFFB7C4FF).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Foreground Content (Node 104:110)
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Outstanding balance label (Node 104:112)
                  Text(
                    'OUTSTANDING BALANCE',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.6,
                      height: 16 / 12,
                      color: const Color(0xFF747686),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Amount $299.00 (Node 104:114)
                  Text(
                    '\$299.00',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.96,
                      height: 56 / 48,
                      color: const Color(0xFF0037B1),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Next payment box (Node 104:115)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F2FE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E1ED),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Next payment header row (Node 104:116)
                        Row(
                          children: [
                            SvgPicture.asset(
                              _svgCalendar,
                              width: 10.5,
                              height: 11.67,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'NEXT PAYMENT',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                                height: 16 / 12,
                                color: const Color(0xFF434655),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Sep 15 and ($149.50) row (Node 104:121)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Sep 15',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 21.5,
                                fontWeight: FontWeight.w600,
                                height: 28 / 20,
                                color: const Color(0xFF1A1B23),
                              ),
                            ),
                            Text(
                              '(\$149.50)',
                              style: GoogleFonts.hankenGrotesk(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                height: 24 / 16,
                                color: const Color(0xFF747686),
                              ),
                            ),
                          ],
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
    );
  }

  /// Section - Child Filter matching Figma Node 104:126
  Widget _buildChildFilterSection() {
    final filters = ['All Children', 'Mia', 'Alex'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          return Padding(
            padding: EdgeInsets.only(
              right: index < filters.length - 1 ? 12 : 0,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(9999),
              onTap: () {
                setState(() {
                  _selectedFilterIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF0037B1)
                      : const Color(0xFFFAF8FF),
                  borderRadius: BorderRadius.circular(9999),
                  border: isSelected
                      ? null
                      : Border.all(color: const Color(0xFFC4C5D7), width: 1),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 6,
                            offset: Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  filters[index],
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                    height: 20 / 14,
                    color: isSelected ? Colors.white : const Color(0xFF434655),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Section - Invoice List matching Figma Node 104:134
  Widget _buildInvoiceListSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: DUE (Node 104:135)
        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1) ...[
          _buildDueInvoiceCard(context),
          const SizedBox(height: 12),
        ],

        // Card 2: PAID (Node 104:163)
        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1) ...[
          _buildPaidInvoiceCard(context),
        ],
      ],
    );
  }

  /// Card 1: DUE matching Figma Node 104:135
  Widget _buildDueInvoiceCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 21, 21, 21),
      decoration: BoxDecoration(
        color: const Color(0xE6FFFFFF), // rgba(255, 255, 255, 0.9)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x80FFFFFF), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // rgba(0, 0, 0, 0.04)
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upper Row: Icon, Mia + DUE, Emotional Intelligence, $149.50 (Node 104:136)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container with soft red/rose overlay (Node 104:138)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0x1AFB7185), // rgba(251, 113, 133, 0.1)
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  _svgHeart,
                  width: 20,
                  height: 18.35,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),

              // Title and Subject column (Node 104:141)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Mia',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            height: 24 / 16,
                            color: const Color(0xFF1A1B23),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // DUE badge (Node 104:145)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFDAD6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'DUE',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.25,
                              height: 15 / 10,
                              color: const Color(0xFF93000A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Emotional Intelligence',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.normal,
                        height: 20 / 14,
                        color: const Color(0xFF434655),
                      ),
                    ),
                  ],
                ),
              ),

              // Price: $149.50 (Node 104:150)
              Text(
                '\$149.50',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 21.5,
                  fontWeight: FontWeight.w600,
                  height: 28 / 20,
                  color: const Color(0xFF1A1B23),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Bottom Details & Action Box (Node 104:151)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F2FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Invoice number (Node 104:154)
                Text(
                  'Invoice #TL-2026-0018',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 16 / 12,
                    color: const Color(0xFF747686),
                  ),
                ),
                const SizedBox(height: 4),

                // Due date row (Node 104:155)
                Row(
                  children: [
                    SvgPicture.asset(
                      _svgDueAlert,
                      width: 12.83,
                      height: 11.08,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due: Sep 15, 2026',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 16 / 12,
                        color: const Color(0xFFBA1A1A),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Primary Blue "View Invoice" Button (Node 104:159)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    context.push(
                      AppRoutePaths.invoiceDetails.replaceAll(
                        ':invoiceId',
                        'TL-2026-0018',
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0037B1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View Invoice',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                            height: 20 / 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        SvgPicture.asset(
                          _svgArrowWhite,
                          width: 9.33,
                          height: 9.33,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card 2: PAID matching Figma Node 104:163
  Widget _buildPaidInvoiceCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 21, 21, 21),
      decoration: BoxDecoration(
        color: const Color(0xE6FFFFFF), // rgba(255, 255, 255, 0.9)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x80FFFFFF), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // rgba(0, 0, 0, 0.04)
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upper Row: Icon, Mia + PAID, Communication & Public Speaking, $299.00 (Node 104:164)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container with soft cyan overlay (Node 104:166)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0x1A22D3EE), // rgba(34, 211, 238, 0.1)
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  _svgMic,
                  width: 14,
                  height: 19,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),

              // Title and Subject column (Node 104:169)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Mia',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            height: 24 / 16,
                            color: const Color(0xFF1A1B23),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // PAID badge (Node 104:173)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0x3310B981,
                            ), // rgba(16, 185, 129, 0.2)
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'PAID',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.25,
                              height: 15 / 10,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Communication & Public\nSpeaking',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.normal,
                        height: 20 / 14,
                        color: const Color(0xFF434655),
                      ),
                    ),
                  ],
                ),
              ),

              // Price: $299.00 (Node 104:178)
              Text(
                '\$299.00',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 21.5,
                  fontWeight: FontWeight.w600,
                  height: 28 / 20,
                  color: const Color(0xFF1A1B23),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Bottom Details & Action Box (Node 104:179)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F2FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Invoice number (Node 104:182)
                Text(
                  'Invoice #TL-2026-0012',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 16 / 12,
                    color: const Color(0xFF747686),
                  ),
                ),
                const SizedBox(height: 4),

                // Paid date row (Node 104:183)
                Row(
                  children: [
                    SvgPicture.asset(
                      _svgPaidCheck,
                      width: 11.67,
                      height: 11.67,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Paid: Aug 15, 2026',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 16 / 12,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Outlined "View Invoice" Button (Node 104:187)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    context.push(
                      AppRoutePaths.invoiceDetails.replaceAll(
                        ':invoiceId',
                        'TL-2026-0012',
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFC4C5D7),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View Invoice',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                            height: 20 / 14,
                            color: const Color(0xFF0037B1),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SvgPicture.asset(
                          _svgArrowBlue,
                          width: 9.33,
                          height: 9.33,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
