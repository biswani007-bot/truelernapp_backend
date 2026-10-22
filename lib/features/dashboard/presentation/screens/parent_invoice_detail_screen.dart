import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../presentation/controllers/children_controller.dart';
import '../../presentation/controllers/children_state.dart';
import '../../../finance/domain/entities/invoice_entity.dart';
import '../../../finance/domain/entities/stripe_checkout_entity.dart';
import '../../../finance/data/repositories/finance_repository_impl.dart';
import '../../../finance/presentation/controllers/finance_controller.dart';
import '../../../finance/presentation/services/stripe_checkout_launcher.dart';
import 'parent_payment_successful_screen.dart';

/// Parent Invoice Detail Screen displaying real invoice details and supporting
/// official Stripe Checkout payments with server-authoritative settlement confirmation.
///
/// Figma Source of Truth: `Parent(full app)_TreLern`, Frame: `Invoice Detail` (Node 104:198).
class ParentInvoiceDetailScreen extends ConsumerStatefulWidget {
  const ParentInvoiceDetailScreen({
    super.key,
    this.invoice,
    this.invoiceId,
    this.checkoutLauncher = const StripeCheckoutLauncher(),
  });

  final InvoiceEntity? invoice;
  final String? invoiceId;
  final StripeCheckoutLauncher checkoutLauncher;

  @override
  ConsumerState<ParentInvoiceDetailScreen> createState() =>
      _ParentInvoiceDetailScreenState();
}

class _ParentInvoiceDetailScreenState
    extends ConsumerState<ParentInvoiceDetailScreen>
    with WidgetsBindingObserver {
  static const _svgDownload = 'assets/icons/inv_detail_download.svg';
  static const _svgBackArrow = 'assets/icons/inv_detail_back.svg';
  static const _svgUnpaid = 'assets/icons/inv_detail_unpaid.svg';
  static const _svgHeart = 'assets/icons/inv_detail_heart.svg';

  InvoiceEntity? _invoice;
  CheckoutUiState _checkoutState = CheckoutUiState.idle;
  String? _statusBannerMessage;
  bool _isAwaitingExternalReturn = false;
  String? _activeStudentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _invoice = widget.invoice;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLatestInvoice();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// App lifecycle listener to detect return from external browser checkout.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isAwaitingExternalReturn) {
        _isAwaitingExternalReturn = false;
        final currentInvoice = _invoice ?? widget.invoice;
        if (currentInvoice != null && mounted) {
          _verifyPaymentWithPolling(currentInvoice.id);
        }
      } else {
        final currentInvoice = _invoice ?? widget.invoice;
        if (currentInvoice != null && mounted) {
          _fetchLatestInvoice();
        }
      }
    }
  }

  Future<void> _fetchLatestInvoice() async {
    final targetId = _invoice?.id ?? widget.invoiceId ?? widget.invoice?.id;
    if (targetId == null || targetId.isEmpty) {
      _resolveInvoice();
      return;
    }

    try {
      final repo = ref.read(financeRepositoryProvider);
      final fresh = await repo.getInvoiceDetail(
        targetId,
        studentId: _invoice?.studentId ?? _activeStudentId,
      );

      if (fresh != null && mounted) {
        setState(() {
          _invoice = fresh;
        });
      } else if (mounted) {
        _resolveInvoice();
      }
    } catch (_) {
      if (mounted) {
        _resolveInvoice();
      }
    }
  }

  void _resolveInvoice() {
    final financeState = ref.read(financeControllerProvider);
    if (financeState is FinanceLoaded) {
      final targetId = widget.invoiceId ?? widget.invoice?.id;
      final found = financeState.invoices
          .where(
            (i) =>
                i.id == targetId || i.invoiceNumber == targetId,
          )
          .firstOrNull;
      if (found != null && mounted) {
        setState(() {
          _invoice = found;
        });
      }
    }
  }

  bool _isProcessingPayment = false;

  /// Initiates official Stripe Checkout creation and presentation.
  Future<void> _handlePayment(InvoiceEntity invoice) async {
    // 1. Check if already settled
    if (invoice.isPaid || invoice.amountDue <= 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This invoice is already paid in full.'),
          backgroundColor: Color(0xFF15803D),
        ),
      );
      return;
    }

    // 2. Prevent duplicate taps while a session is creating, opened, or verifying
    if (_isProcessingPayment ||
        _checkoutState == CheckoutUiState.creatingCheckout ||
        _checkoutState == CheckoutUiState.pendingVerification ||
        _checkoutState == CheckoutUiState.checkoutOpened) {
      return;
    }
    _isProcessingPayment = true;

    // 3. Resolve and authorize student identifier from linked children context
    final childrenState = ref.read(childrenControllerProvider);
    String? resolvedStudentId = invoice.studentId;

    if (resolvedStudentId == null || resolvedStudentId.isEmpty) {
      if (childrenState is ChildrenLoaded) {
        resolvedStudentId = childrenState.activeChildId ??
            (childrenState.children.isNotEmpty
                ? childrenState.children.first.studentId
                : null);
      }
    }

    if (resolvedStudentId == null || resolvedStudentId.isEmpty) {
      setState(() {
        _checkoutState = CheckoutUiState.paymentFailed;
        _statusBannerMessage =
            'Linked student context is missing. Please select a child before proceeding.';
      });
      return;
    }

    // Ownership verification: ensure parent owns this child
    if (childrenState is ChildrenLoaded && childrenState.children.isNotEmpty) {
      final isLinked =
          childrenState.children.any((c) => c.studentId == resolvedStudentId);
      if (!isLinked) {
        setState(() {
          _checkoutState = CheckoutUiState.paymentFailed;
          _statusBannerMessage =
              'Unauthorized: Student is not linked to your parent account.';
        });
        return;
      }
    }

    _activeStudentId = resolvedStudentId;

    setState(() {
      _checkoutState = CheckoutUiState.creatingCheckout;
      _statusBannerMessage = null;
    });

    try {
      final config = ref.read(appConfigProvider);
      final serverOrigin = config.serverOrigin;
      final successUrl = '$serverOrigin/checkout?payment=success';
      final cancelUrl = '$serverOrigin/checkout?payment=cancelled';

      // 4. Create Stripe Checkout Session through backend API
      final session = await ref
          .read(financeControllerProvider.notifier)
          .createCheckoutSession(
            invoice: invoice,
            studentId: resolvedStudentId,
            successUrl: successUrl,
            cancelUrl: cancelUrl,
          );

      if (!session.isValid) {
        throw ArgumentError(
          'Untrusted checkout URL returned from server: ${session.url}',
        );
      }

      if (!mounted) return;

      setState(() {
        _checkoutState = CheckoutUiState.checkoutOpened;
      });

      // 5. Open Checkout: attempt external browser launch, fallback to in-app presentation
      bool launchedExternal = false;
      try {
        launchedExternal =
            await widget.checkoutLauncher.launchExternalBrowser(session.url);
      } catch (_) {
        launchedExternal = false;
      }

      if (launchedExternal) {
        _isAwaitingExternalReturn = true;
      } else {
        // Fallback to approved in-app presentation screen
        if (!mounted) return;
        final result = await widget.checkoutLauncher.launchInAppPresentation(
          context,
          checkoutUrl: session.url,
          successUrlPrefix: '$serverOrigin/checkout',
          cancelUrlPrefix: '$serverOrigin/checkout',
        );

        if (!mounted) return;

        switch (result) {
          case CheckoutReturnResult.completed:
          case CheckoutReturnResult.closed:
            await _verifyPaymentWithPolling(invoice.id);
            break;
          case CheckoutReturnResult.cancelled:
            await _fetchLatestInvoice();
            if (!mounted) return;
            setState(() {
              _checkoutState = CheckoutUiState.paymentCancelled;
              _statusBannerMessage =
                  'Payment was cancelled. Your invoice balance of ${_invoice?.formattedDue ?? invoice.formattedDue} remains outstanding.';
            });
            break;
          case CheckoutReturnResult.error:
            setState(() {
              _checkoutState = CheckoutUiState.paymentFailed;
              _statusBannerMessage =
                  'Unable to open payment checkout. Please verify your internet connection and retry.';
            });
            break;
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checkoutState = CheckoutUiState.paymentFailed;
        _statusBannerMessage = 'Checkout initialization failed: $e';
      });
    } finally {
      if (mounted) {
        _isProcessingPayment = false;
      }
    }
  }

  /// Authoritative bounded polling of GET /api/finance/invoices/{invoiceId}.
  ///
  /// Never confirms payment unless the backend reports status == 'paid' or settled.
  Future<void> _verifyPaymentWithPolling(String invoiceId) async {
    if (!mounted) return;

    setState(() {
      _checkoutState = CheckoutUiState.pendingVerification;
      _statusBannerMessage =
          'Verifying payment settlement with TrueLern server...';
    });

    try {
      final verifiedInvoice = await ref
          .read(financeControllerProvider.notifier)
          .verifyAndPollInvoicePayment(
            invoiceId,
            maxAttempts: 5,
            pollInterval: const Duration(seconds: 2),
            studentId: _activeStudentId,
          );

      if (!mounted) return;

      if (verifiedInvoice.isPaid) {
        setState(() {
          _invoice = verifiedInvoice;
          _checkoutState = CheckoutUiState.paymentConfirmed;
          _statusBannerMessage = null;
        });

        // Navigate to existing Payment Successful screen with server-verified transaction details
        context.push(
          AppRoutePaths.paymentSuccessful,
          extra: PaymentSuccessfulArgs(
            invoiceNumber: verifiedInvoice.invoiceNumber,
            amountPaid: verifiedInvoice.formattedPaid.isNotEmpty &&
                    verifiedInvoice.amountPaid > 0
                ? verifiedInvoice.formattedPaid
                : verifiedInvoice.formattedTotal,
            courseName: verifiedInvoice.courseName,
            studentName: verifiedInvoice.studentName ?? 'Ward',
            transactionReference: verifiedInvoice.transactionReference,
            paymentDate: verifiedInvoice.paidAt ?? DateTime.now(),
            isAwaitingAdminVerification: false,
          ),
        );
      } else {
        // Invoice is still unpaid, pending, or cancelled
        setState(() {
          _invoice = verifiedInvoice;
          _checkoutState = CheckoutUiState.verificationUnavailable;
          _statusBannerMessage =
              'Payment settlement confirmation is still pending with your payment provider. Your balance remains ${verifiedInvoice.formattedDue}.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checkoutState = CheckoutUiState.verificationUnavailable;
        _statusBannerMessage =
            'Unable to reach TrueLern server for payment confirmation ($e). Please tap "Verify Payment" to check again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Color(0xFFF3E8FF),
              Color(0xFFE0F2FE),
              Color(0xFFFFFFFF),
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
                        if (widget.invoiceId != null) {
                          try {
                            final refreshed = await ref
                                .read(financeRepositoryProvider)
                                .verifyInvoiceStatus(widget.invoiceId!);
                            if (mounted) {
                              setState(() {
                                _invoice = refreshed;
                              });
                            }
                          } catch (_) {}
                        }
                        _resolveInvoice();
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 170),
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

              // Fixed Bottom Action Area (Node 104:199)
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
              padding: const EdgeInsets.all(25),
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

                  // Dynamic Checkout Status Banner
                  if (_checkoutState != CheckoutUiState.idle &&
                      _checkoutState != CheckoutUiState.paymentConfirmed) ...[
                    const SizedBox(height: 16),
                    _buildCheckoutStatusBanner(invoice),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dynamic banner reflecting the exact payment / checkout UI state
  Widget _buildCheckoutStatusBanner(InvoiceEntity invoice) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData iconData;
    String title;
    String subtitle;
    Widget? actionWidget;

    switch (_checkoutState) {
      case CheckoutUiState.creatingCheckout:
        bgColor = const Color(0xFFEFF6FF);
        borderColor = const Color(0xFFBFDBFE);
        textColor = const Color(0xFF1E40AF);
        iconData = Icons.hourglass_top_rounded;
        title = 'Connecting to Stripe Checkout';
        subtitle =
            'Generating secure payment session. Please do not close the app.';
        break;

      case CheckoutUiState.checkoutOpened:
        bgColor = const Color(0xFFF0FDF4);
        borderColor = const Color(0xFFBBF7D0);
        textColor = const Color(0xFF166534);
        iconData = Icons.open_in_browser_rounded;
        title = 'Stripe Checkout Opened';
        subtitle =
            'Complete your payment in the browser, then return here to verify settlement.';
        actionWidget = TextButton.icon(
          key: const Key('checkout_banner_verify_button'),
          onPressed: () => _verifyPaymentWithPolling(invoice.id),
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Verify Payment Now'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF15803D),
            visualDensity: VisualDensity.compact,
          ),
        );
        break;

      case CheckoutUiState.pendingVerification:
        bgColor = const Color(0xFFEFF6FF);
        borderColor = const Color(0xFF93C5FD);
        textColor = const Color(0xFF1D4ED8);
        iconData = Icons.sync_rounded;
        title = 'Verifying Settlement';
        subtitle = _statusBannerMessage ??
            'Polling TrueLern backend for signed payment confirmation...';
        actionWidget = const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
        break;

      case CheckoutUiState.paymentCancelled:
        bgColor = const Color(0xFFFEF3C7);
        borderColor = const Color(0xFFFDE68A);
        textColor = const Color(0xFF92400E);
        iconData = Icons.info_outline_rounded;
        title = 'Payment Cancelled';
        subtitle = _statusBannerMessage ??
            'Payment session was cancelled. Your balance remains outstanding.';
        break;

      case CheckoutUiState.paymentFailed:
        bgColor = const Color(0xFFFEE2E2);
        borderColor = const Color(0xFFFECACA);
        textColor = const Color(0xFF991B1B);
        iconData = Icons.error_outline_rounded;
        title = 'Payment Initialization Failed';
        subtitle = _statusBannerMessage ??
            'An error occurred while connecting to the payment service. Please try again.';
        break;

      case CheckoutUiState.verificationUnavailable:
        bgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFDE68A);
        textColor = const Color(0xFFB45309);
        iconData = Icons.pending_actions_rounded;
        title = 'Settlement Awaiting Confirmation';
        subtitle = _statusBannerMessage ??
            'The backend has not confirmed receipt of funds yet. Tap below to check again.';
        actionWidget = TextButton.icon(
          key: const Key('checkout_retry_verification_button'),
          onPressed: () => _verifyPaymentWithPolling(invoice.id),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Check Status Again'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFB45309),
            visualDensity: VisualDensity.compact,
          ),
        );
        break;

      case CheckoutUiState.idle:
      case CheckoutUiState.paymentConfirmed:
        return const SizedBox.shrink();
    }

    return Container(
      key: const Key('checkout_status_banner'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconData, color: textColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.hankenGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              ?actionWidget,
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: textColor.withValues(alpha: 0.9),
            ),
          ),
        ],
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
                  fontWeight: FontWeight.w600,
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
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1B23),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Details Section: Billed To, Student & Program (Node 104:237)
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
          _buildBreakdownRow('Tax', invoice.formattedTax),
        ],
        const SizedBox(height: 8),
        _buildBreakdownRow('Total Invoiced', invoice.formattedTotal,
            isBold: true),
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
            color: textColor ?? const Color(0xFF1A1B23),
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
              color:
                  isPaid ? const Color(0xFF166534) : const Color(0xFF1E4ED8),
            ),
          ),
          Text(
            isPaid ? 'Paid in Full' : invoice.formattedDue,
            style: GoogleFonts.hankenGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color:
                  isPaid ? const Color(0xFF166534) : const Color(0xFF1E4ED8),
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
    final isBusy = _checkoutState == CheckoutUiState.creatingCheckout ||
        _checkoutState == CheckoutUiState.pendingVerification;

    String buttonLabel;
    IconData buttonIcon;
    VoidCallback? buttonAction;

    if (isPaid) {
      buttonLabel = 'Invoice Paid';
      buttonIcon = Icons.check_circle_outline;
      buttonAction = null;
    } else if (isBusy) {
      buttonLabel = _checkoutState == CheckoutUiState.creatingCheckout
          ? 'Connecting to Checkout...'
          : 'Verifying Payment...';
      buttonIcon = Icons.hourglass_top;
      buttonAction = null;
    } else if (_checkoutState == CheckoutUiState.checkoutOpened ||
        _checkoutState == CheckoutUiState.verificationUnavailable) {
      buttonLabel = 'Verify Payment Status';
      buttonIcon = Icons.refresh_rounded;
      buttonAction = () => _verifyPaymentWithPolling(invoice.id);
    } else {
      buttonLabel = 'Pay ${invoice.formattedDue}';
      buttonIcon = Icons.credit_card_outlined;
      buttonAction = () => _handlePayment(invoice);
    }

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
          // Primary Action Button
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
              onPressed: buttonAction,
              child: isBusy
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
                        Icon(buttonIcon, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          buttonLabel,
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
