import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../../finance/domain/entities/invoice_entity.dart';
import '../../../finance/presentation/controllers/finance_controller.dart';
import 'parent_payment_successful_screen.dart';

/// Parent Invoice Detail Screen displaying real invoice details and supporting payment.
///
/// Figma Source of Truth: `Parent(full app)_TreLern`, Frame: `Invoice Detail` (Node 104:198).
/// - Top App Bar: Back button and centered title "Invoice Detail" (Node 104:209)
/// - Background: Linear gradient (Lavender -> Sky Blue -> White)
/// - Invoice Card (Node 104:217):
///   - Top decorative accent: Blue to rose horizontal gradient bar (Node 104:293)
///   - Header: "INVOICE NUMBER", real number, and status badge (Node 104:218)
///   - Dates: Issued Date, Due Date (Node 104:228)
///   - Details: Billed To, Student & Program (Node 104:237)
///   - Breakdown: Program Fee, Discount, Tax, Total, Amount Paid (Node 104:257)
///   - Total Due box: "Balance Due" & real balance (Node 104:288)
/// - Bottom Action Buttons (Node 104:199):
///   - Primary Button: "Pay $X.XX" (or "Paid" if settled)
///   - Outlined Button: "Download Invoice"
class ParentInvoiceDetailScreen extends ConsumerStatefulWidget {
  const ParentInvoiceDetailScreen({
    super.key,
    this.invoice,
    this.invoiceId,
  });

  final InvoiceEntity? invoice;
  final String? invoiceId;

  @override
  ConsumerState<ParentInvoiceDetailScreen> createState() =>
      _ParentInvoiceDetailScreenState();
}

class _ParentInvoiceDetailScreenState
    extends ConsumerState<ParentInvoiceDetailScreen> {
  static const _svgDownload = 'assets/icons/inv_detail_download.svg';
  static const _svgBackArrow = 'assets/icons/inv_detail_back.svg';
  static const _svgUnpaid = 'assets/icons/inv_detail_unpaid.svg';
  static const _svgHeart = 'assets/icons/inv_detail_heart.svg';

  InvoiceEntity? _invoice;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_invoice == null) {
        _resolveInvoice();
      }
    });
  }

  void _resolveInvoice() {
    final financeState = ref.read(financeControllerProvider);
    if (financeState is FinanceLoaded) {
      final found = financeState.invoices
          .where(
            (i) => i.id == widget.invoiceId || i.invoiceNumber == widget.invoiceId,
          )
          .firstOrNull;
      if (found != null && mounted) {
        setState(() {
          _invoice = found;
        });
      }
    }
  }

  Future<void> _handlePayment(InvoiceEntity invoice) async {
    if (invoice.isPaid || invoice.amountDue <= 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This invoice is already paid in full.'),
          backgroundColor: Color(0xFF15803D),
        ),
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final payment = await ref
          .read(financeControllerProvider.notifier)
          .processPayment(invoice);

      if (!mounted) return;

      setState(() {
        _isProcessingPayment = false;
      });

      // Navigate to Payment Successful screen with verified transaction details
      context.push(
        AppRoutePaths.paymentSuccessful,
        extra: PaymentSuccessfulArgs(
          invoiceNumber: invoice.invoiceNumber,
          amountPaid: invoice.formattedDue,
          courseName: invoice.courseName,
          studentName: invoice.studentName ?? 'Ward',
          transactionReference: payment?.transactionReference,
          paymentDate: payment?.paymentDate ?? DateTime.now(),
          isAwaitingAdminVerification: false,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessingPayment = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Current invoice resolution
    final invoice = _invoice ?? widget.invoice;
    final authState = ref.watch(authControllerProvider);
    final parentName = (authState is Authenticated && authState.user != null)
        ? (authState.user!.name ?? 'Parent / Guardian')
        : 'Parent / Guardian';

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
              Column(
                children: [
                  // Top App Bar (Node 104:209)
                  _buildTopHeader(context),

                  // Main Content ScrollView
                  Expanded(
                    child: AppRefreshIndicator(
                      onRefresh: () async {
                        await ref
                            .read(financeControllerProvider.notifier)
                            .loadFinance();
                        _resolveInvoice();
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 160),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 448),
                            child: invoice != null
                                ? _buildInvoiceCard(invoice, parentName)
                                : _buildLoadingOrFallbackCard(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Fixed Bottom Action Buttons (Node 104:199)
              if (invoice != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildBottomActionButtons(context, invoice),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Top App Bar matching Figma Node 104:209
  Widget _buildTopHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xCCFFFFFF),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            key: const Key('invoice_detail_back_button'),
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
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  /// Main Invoice Card matching Figma Node 104:217
  Widget _buildInvoiceCard(InvoiceEntity invoice, String parentName) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xE6FFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0x80FFFFFF),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
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
            // Top Accent Horizontal Gradient Bar (Node 104:293)
            Container(
              width: double.infinity,
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF2563EB),
                    Color(0xFFF43F5E),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(25, 25, 25, 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInvoiceHeader(invoice),
                  const SizedBox(height: 24),
                  _buildDatesRow(invoice),
                  const SizedBox(height: 24),
                  _buildDetailsSection(invoice, parentName),
                  const SizedBox(height: 24),
                  _buildBreakdownSection(invoice),
                  const SizedBox(height: 24),
                  _buildTotalDueBox(invoice),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header with Invoice Number and Status Badge (Node 104:218)
  Widget _buildInvoiceHeader(InvoiceEntity invoice) {
    final isPaid = invoice.isPaid;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INVOICE NUMBER',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.6,
                  color: const Color(0xFF747686),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                invoice.invoiceNumber,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 21.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1B23),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Status Badge (Paid vs Unpaid)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isPaid
                ? const Color(0x3310B981)
                : const Color(0x1AF59E0B),
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                isPaid ? 'assets/icons/inv_paid_check.svg' : _svgUnpaid,
                width: 14,
                height: 14,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 4),
              Text(
                isPaid ? 'Paid' : 'Unpaid',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isPaid
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Dates Row: Issued Date & Due Date (Node 104:228)
  Widget _buildDatesRow(InvoiceEntity invoice) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ISSUED DATE',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.6,
                  color: const Color(0xFF747686),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                invoice.formattedIssueDate,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A1B23),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DUE DATE',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.6,
                  color: const Color(0xFF747686),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                invoice.formattedDueDate,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: invoice.isPaid
                      ? const Color(0xFF1A1B23)
                      : const Color(0xFFBA1A1A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Details: Billed To, Student & Program (Node 104:237)
  Widget _buildDetailsSection(InvoiceEntity invoice, String parentName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BILLED TO',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.6,
            color: const Color(0xFF747686),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          parentName,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1B23),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'STUDENT & PROGRAM',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.6,
            color: const Color(0xFF747686),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0x1AFB7185),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                _svgHeart,
                width: 14,
                height: 13,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.studentName ?? 'Ward',
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1B23),
                    ),
                  ),
                  Text(
                    invoice.courseName,
                    style: GoogleFonts.hankenGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: const Color(0xFF434655),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Breakdown Section (Node 104:257)
  Widget _buildBreakdownSection(InvoiceEntity invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BREAKDOWN',
          style: GoogleFonts.hankenGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.6,
            color: const Color(0xFF747686),
          ),
        ),
        const SizedBox(height: 12),
        _buildBreakdownRow('Program Fee', invoice.formattedBase),
        if (invoice.discountAmount > 0) ...[
          const SizedBox(height: 8),
          _buildBreakdownRow(
            'Discount',
            invoice.formattedDiscount,
            textColor: const Color(0xFF15803D),
          ),
        ],
        if (invoice.taxAmount > 0) ...[
          const SizedBox(height: 8),
          _buildBreakdownRow('Tax (5%)', invoice.formattedTax),
        ],
        const SizedBox(height: 8),
        _buildBreakdownRow('Total Invoiced', invoice.formattedTotal, isBold: true),
        if (invoice.amountPaid > 0) ...[
          const SizedBox(height: 8),
          _buildBreakdownRow(
            'Amount Paid',
            '-${invoice.formattedPaid}',
            textColor: const Color(0xFF15803D),
          ),
        ],
      ],
    );
  }

  Widget _buildBreakdownRow(
    String label,
    String amount, {
    Color? textColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: isBold ? const Color(0xFF1A1B23) : const Color(0xFF434655),
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.hankenGrotesk(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: textColor ??
                (isBold ? const Color(0xFF1A1B23) : const Color(0xFF1A1B23)),
          ),
        ),
      ],
    );
  }

  /// Total Due Box (Node 104:288)
  Widget _buildTotalDueBox(InvoiceEntity invoice) {
    final isPaid = invoice.isPaid;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPaid ? const Color(0xFF86EFAC) : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isPaid ? 'STATUS' : 'BALANCE DUE',
            style: GoogleFonts.hankenGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isPaid ? const Color(0xFF166534) : const Color(0xFF1E4ED8),
            ),
          ),
          Text(
            isPaid ? 'Paid in Full' : invoice.formattedDue,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isPaid ? const Color(0xFF166534) : const Color(0xFF1E4ED8),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Action Buttons matching Figma Node 104:199
  Widget _buildBottomActionButtons(
    BuildContext context,
    InvoiceEntity invoice,
  ) {
    final isPaid = invoice.isPaid;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xCCFFFFFF),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary Pay / Paid Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              key: const Key('invoice_detail_pay_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPaid
                    ? const Color(0xFF15803D)
                    : const Color(0xFF1E4ED8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: _isProcessingPayment || isPaid
                  ? null
                  : () => _handlePayment(invoice),
              child: _isProcessingPayment
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPaid
                              ? Icons.check_circle_outline
                              : Icons.credit_card_outlined,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isPaid ? 'Invoice Paid' : 'Pay ${invoice.formattedDue}',
                          style: GoogleFonts.hankenGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 10),

          // Outlined "Download Invoice" Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              key: const Key('invoice_detail_download_button'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFC4C5D7), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Downloading invoice #${invoice.invoiceNumber}...',
                    ),
                  ),
                );
              },
              icon: SvgPicture.asset(
                _svgDownload,
                width: 16,
                height: 16,
                fit: BoxFit.contain,
              ),
              label: Text(
                'Download Invoice',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0037B1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOrFallbackCard() {
    final financeState = ref.watch(financeControllerProvider);
    final isLoaded = financeState is FinanceLoaded;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          children: [
            if (!isLoaded) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading invoice details...',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 15,
                  color: const Color(0xFF64748B),
                ),
              ),
            ] else ...[
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Color(0xFFDC2626),
              ),
              const SizedBox(height: 16),
              Text(
                'Invoice Not Found',
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unable to retrieve the requested billing record.',
                textAlign: TextAlign.center,
                style: GoogleFonts.hankenGrotesk(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                key: const Key('invoice_detail_return_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E4ED8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutePaths.parentInvoices);
                  }
                },
                child: const Text('Return to Invoices'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
