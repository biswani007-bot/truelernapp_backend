import 'package:flutter/foundation.dart';

/// Distinct UI states for the payment and checkout lifecycle.
enum CheckoutUiState {
  /// Default state: user is viewing invoice details.
  idle,

  /// Calling POST /api/finance/stripe/create-checkout.
  creatingCheckout,

  /// External browser or in-app payment presentation is opened.
  checkoutOpened,

  /// App resumed or return intercepted; polling invoice status.
  pendingVerification,

  /// Backend has confirmed invoice settlement (status == 'paid').
  paymentConfirmed,

  /// User cancelled payment in checkout return flow.
  paymentCancelled,

  /// Error occurred during checkout initialization or network error.
  paymentFailed,

  /// Verification failed or timed out while payment remains unsettled.
  verificationUnavailable,
}

/// Result of returning from checkout presentation.
enum CheckoutReturnResult {
  /// User finished checkout (intercepted successUrl or returned from browser).
  completed,

  /// User explicitly tapped cancel in checkout (intercepted cancelUrl).
  cancelled,

  /// Presentation closed/dismissed without explicit success or cancel parameter.
  closed,

  /// Failed to open checkout destination.
  error,
}

/// Validates whether a checkout destination URL is an official HTTPS Stripe checkout URL.
bool isValidStripeCheckoutUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return false;
  if (!uri.isScheme('https')) return false;

  final host = uri.host.toLowerCase();
  return host == 'checkout.stripe.com' ||
      host.endsWith('.stripe.com') ||
      host == 'pay.stripe.com';
}

/// Domain entity representing a server-created Stripe Checkout Session.
@immutable
class StripeCheckoutSessionEntity {
  const StripeCheckoutSessionEntity({
    required this.sessionId,
    required this.url,
  });

  final String sessionId;
  final String url;

  bool get isValid => isValidStripeCheckoutUrl(url);

  factory StripeCheckoutSessionEntity.fromJson(Map<String, dynamic> json) {
    // Accommodate standard envelope {"success": true, "data": {"sessionId": "...", "url": "..."}}
    final Map<String, dynamic> data;
    if (json['data'] is Map<String, dynamic>) {
      data = json['data'] as Map<String, dynamic>;
    } else {
      data = json;
    }

    final rawUrl = data['url']?.toString() ??
        data['checkoutUrl']?.toString() ??
        json['url']?.toString() ??
        '';

    final rawSessionId = data['sessionId']?.toString() ??
        data['id']?.toString() ??
        json['sessionId']?.toString() ??
        '';

    return StripeCheckoutSessionEntity(
      sessionId: rawSessionId,
      url: rawUrl,
    );
  }
}

/// Receipt record from GET /api/finance/receipts.
@immutable
class ReceiptEntity {
  const ReceiptEntity({
    required this.id,
    required this.receiptNumber,
    required this.invoiceId,
    required this.amount,
    required this.issueDate,
    this.downloadUrl,
    this.paymentMethod,
    this.transactionReference,
    this.studentName,
    this.courseName,
  });

  final String id;
  final String receiptNumber;
  final String invoiceId;
  final double amount;
  final DateTime issueDate;
  final String? downloadUrl;
  final String? paymentMethod;
  final String? transactionReference;
  final String? studentName;
  final String? courseName;

  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';

  factory ReceiptEntity.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic val) {
      if (val == null) return 0.0;
      final num? n = (val is num) ? val : num.tryParse(val.toString());
      if (n == null) return 0.0;
      return (n / 100.0).toDouble();
    }

    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return ReceiptEntity(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      receiptNumber: json['receiptNumber']?.toString() ??
          json['number']?.toString() ??
          '#REC-000000',
      invoiceId: json['invoiceId']?.toString() ??
          (json['invoice'] is Map ? json['invoice']['id']?.toString() : null) ??
          '',
      amount: parseAmount(json['amount'] ?? json['total']),
      issueDate: parseDate(json['issueDate'] ?? json['createdAt']),
      downloadUrl: json['downloadUrl']?.toString() ?? json['pdfUrl']?.toString(),
      paymentMethod: json['paymentMethod']?.toString(),
      transactionReference: json['transactionReference']?.toString(),
      studentName: json['studentName']?.toString() ??
          (json['student'] is Map ? json['student']['name']?.toString() : null),
      courseName: json['courseName']?.toString() ??
          (json['course'] is Map ? json['course']['name']?.toString() : null),
    );
  }
}
