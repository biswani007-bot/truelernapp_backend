import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../core/router/route_paths.dart';
import '../../../finance/domain/entities/invoice_entity.dart';
import '../../../finance/presentation/controllers/finance_controller.dart';
import '../controllers/children_controller.dart';
import '../controllers/children_state.dart';
import '../widgets/parent_hamburger_drawer.dart';

/// Parent Invoices Screen connected to real backend finance data.
///
/// Figma Source of Truth: `Parent(full app)_TreLern`, Frame: `Invoices` (Node 104:106).
/// - Top App Bar: Back button and centered title "Invoices" (Node 104:191)
/// - Background: Linear gradient (Lavender -> Sky Blue -> White)
/// - Top Summary Card: Real outstanding balance, Next payment box (Node 104:108)
/// - Dynamic Filter Chips: All Children + real linked children (Node 104:126)
/// - Real Invoice List (Node 104:134):
///   - DUE / PAID cards displaying real persisted data
///   - Loading, empty, and error/retry states
class ParentInvoicesScreen extends ConsumerStatefulWidget {
  const ParentInvoicesScreen({super.key});

  @override
  ConsumerState<ParentInvoicesScreen> createState() =>
      _ParentInvoicesScreenState();
}

class _ParentInvoicesScreenState extends ConsumerState<ParentInvoicesScreen> {
  static const _svgCalendar = 'assets/icons/inv_calendar.svg';
  static const _svgHeart = 'assets/icons/inv_heart.svg';
  static const _svgDueAlert = 'assets/icons/inv_due_alert.svg';
  static const _svgArrowWhite = 'assets/icons/inv_arrow_white.svg';
  static const _svgMic = 'assets/icons/inv_mic.svg';
  static const _svgPaidCheck = 'assets/icons/inv_paid_check.svg';
  static const _svgArrowBlue = 'assets/icons/inv_arrow_blue.svg';
  static const _svgBackArrow = 'assets/icons/inv_back_arrow.svg';

  int _selectedFilterIndex = 0; // 0: All Children
  bool _isNavigating = false;

  void _navigateToInvoiceDetail(InvoiceEntity invoice) async {
    if (_isNavigating) {
      return; // Prevent rapid duplicate pushes
    }
    _isNavigating = true;

    try {
      await context.push(
        AppRoutePaths.invoiceDetails.replaceAll(
          ':invoiceId',
          invoice.id,
        ),
        extra: invoice,
      );
    } finally {
      if (mounted) {
        _isNavigating = false;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(childrenControllerProvider.notifier).loadChildren();
      ref.read(financeControllerProvider.notifier).loadFinance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final financeState = ref.watch(financeControllerProvider);
    final childrenState = ref.watch(childrenControllerProvider);

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
                    await ref
                        .read(financeControllerProvider.notifier)
                        .loadFinance();
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
                            _buildTopSummaryCard(financeState),

                            const SizedBox(height: 24),

                            // Child Filter Section (Node 104:126)
                            _buildChildFilterSection(childrenState),

                            const SizedBox(height: 24),

                            // Invoice List Section (Node 104:134)
                            _buildInvoiceListContent(context, financeState),

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
            key: const Key('invoices_back_button'),
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
  Widget _buildTopSummaryCard(FinanceState state) {
    final overview = state is FinanceLoaded
        ? state.overview
        : FinanceOverviewEntity.zero;

    // Resolve next payment info from due invoices
    InvoiceEntity? nextDueInvoice;
    if (state is FinanceLoaded) {
      final dueInvoices = state.filteredInvoices.where((i) => i.isDue).toList();
      if (dueInvoices.isNotEmpty) {
        dueInvoices.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        nextDueInvoice = dueInvoices.first;
      }
    }

    final hasDue = overview.totalDue > 0.01;

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

                  // Amount $XXX.XX (Node 104:114)
                  Text(
                    overview.formattedDue,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.96,
                      height: 56 / 48,
                      color: hasDue
                          ? const Color(0xFF0037B1)
                          : const Color(0xFF15803D),
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
                              hasDue ? 'NEXT PAYMENT' : 'PAYMENT STATUS',
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

                        if (nextDueInvoice != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  nextDueInvoice.formattedDueDate,
                                  style: GoogleFonts.hankenGrotesk(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    height: 28 / 20,
                                    color: const Color(0xFF1A1B23),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(${nextDueInvoice.formattedDue})',
                                style: GoogleFonts.hankenGrotesk(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  height: 24 / 16,
                                  color: const Color(0xFF747686),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            'All payments up to date',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                        ],
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
  Widget _buildChildFilterSection(ChildrenState childrenState) {
    final filterLabels = <String>['All Children'];
    final childIds = <String?>[null];

    if (childrenState is ChildrenLoaded) {
      for (final c in childrenState.children) {
        filterLabels.add(c.displayName);
        childIds.add(c.studentId);
      }
    }

    if (_selectedFilterIndex >= filterLabels.length) {
      _selectedFilterIndex = 0;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filterLabels.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          return Padding(
            padding: EdgeInsets.only(
              right: index < filterLabels.length - 1 ? 12 : 0,
            ),
            child: InkWell(
              key: Key('invoice_filter_chip_$index'),
              borderRadius: BorderRadius.circular(9999),
              onTap: () {
                setState(() {
                  _selectedFilterIndex = index;
                });
                final targetChildId = childIds[index];
                ref
                    .read(financeControllerProvider.notifier)
                    .selectChildFilter(targetChildId);
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
                  filterLabels[index],
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

  /// Section - Invoice List content handling states
  Widget _buildInvoiceListContent(
    BuildContext context,
    FinanceState state,
  ) {
    if (state is FinanceLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state is FinanceError) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFDC2626),
              size: 36,
            ),
            const SizedBox(height: 12),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: GoogleFonts.hankenGrotesk(
                fontSize: 14,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(financeControllerProvider.notifier).loadFinance();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0037B1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is FinanceLoaded) {
      final invoices = state.filteredInvoices;

      if (invoices.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(height: 12),
              Text(
                'No Invoices Found',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'There are no billing records for the selected child.',
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        );
      }

      final seenIds = <String>{};
      final uniqueInvoices =
          invoices.where((inv) => seenIds.add(inv.id)).toList();

      return Column(
        children: uniqueInvoices.map((inv) {
          return Padding(
            key: ValueKey('invoice_item_${inv.id}'),
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildDynamicInvoiceCard(context, inv),
          );
        }).toList(),
      );
    }

    return const SizedBox.shrink();
  }

  /// Dynamic Invoice Card rendering real persisted invoice data with Figma aesthetics
  Widget _buildDynamicInvoiceCard(
    BuildContext context,
    InvoiceEntity invoice,
  ) {
    final isPaid = invoice.isPaid;
    final isPublicSpeaking =
        invoice.courseName.toLowerCase().contains('speaking') ||
        invoice.courseName.toLowerCase().contains('communication');

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
          // Upper Row: Icon, Student + Status Badge, Course Name, Amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container with thematic colors
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isPaid
                      ? const Color(0x1A22D3EE) // rgba(34, 211, 238, 0.1)
                      : const Color(0x1AFB7185), // rgba(251, 113, 133, 0.1)
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  isPublicSpeaking ? _svgMic : _svgHeart,
                  width: 20,
                  height: 19,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),

              // Title and Subject column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            invoice.studentName ?? 'Ward',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              height: 24 / 16,
                              color: const Color(0xFF1A1B23),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Status badge (DUE vs PAID)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? const Color(0x3310B981)
                                : const Color(0xFFFFDAD6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isPaid ? 'PAID' : 'DUE',
                            style: GoogleFonts.hankenGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.25,
                              height: 15 / 10,
                              color: isPaid
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF93000A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      invoice.courseName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

              const SizedBox(width: 8),

              // Price
              Text(
                invoice.formattedTotal,
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

          // Bottom Details & Action Box
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
                // Invoice number
                Text(
                  'Invoice #${invoice.invoiceNumber}',
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 16 / 12,
                    color: const Color(0xFF747686),
                  ),
                ),
                const SizedBox(height: 4),

                // Due date or Paid date row
                Row(
                  children: [
                    SvgPicture.asset(
                      isPaid ? _svgPaidCheck : _svgDueAlert,
                      width: 12,
                      height: 12,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPaid
                          ? 'Paid: ${invoice.formattedDueDate}'
                          : 'Due: ${invoice.formattedDueDate}',
                      style: GoogleFonts.hankenGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 16 / 12,
                        color: isPaid
                            ? const Color(0xFF15803D)
                            : const Color(0xFFBA1A1A),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Button: Primary Blue for Due, Outlined for Paid
                InkWell(
                  key: Key('view_invoice_${invoice.id}'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _navigateToInvoiceDetail(invoice),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isPaid ? Colors.transparent : const Color(0xFF0037B1),
                      borderRadius: BorderRadius.circular(8),
                      border: isPaid
                          ? Border.all(color: const Color(0xFFC4C5D7), width: 1)
                          : null,
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
                            color: isPaid
                                ? const Color(0xFF0037B1)
                                : Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        SvgPicture.asset(
                          isPaid ? _svgArrowBlue : _svgArrowWhite,
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
