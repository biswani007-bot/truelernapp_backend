import 'package:flutter/foundation.dart';

/// Itemized fee line item in an invoice.
@immutable
class InvoiceItemEntity {
  const InvoiceItemEntity({
    required this.description,
    required this.amount,
    this.quantity = 1,
  });

  final String description;
  final double amount;
  final int quantity;

  factory InvoiceItemEntity.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic val) {
      if (val == null) return 0.0;
      final num? n = (val is num) ? val : num.tryParse(val.toString());
      if (n == null) return 0.0;
      return (n / 100.0).toDouble();
    }

    return InvoiceItemEntity(
      description: json['description']?.toString() ??
          json['name']?.toString() ??
          'Tuition Fee',
      amount: parseAmount(json['amount']),
      quantity: (json['quantity'] is num)
          ? (json['quantity'] as num).toInt()
          : int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
    );
  }
}

/// Domain entity representing a TrueLern invoice.
@immutable
class InvoiceEntity {
  const InvoiceEntity({
    required this.id,
    required this.invoiceNumber,
    required this.issueDate,
    required this.dueDate,
    required this.baseAmount,
    required this.taxAmount,
    required this.discountAmount,
    required this.scholarshipAmount,
    required this.totalAmount,
    required this.amountPaid,
    required this.amountDue,
    required this.status,
    required this.courseName,
    required this.courseCode,
    this.studentName,
    this.studentId,
    this.items = const [],
    this.paymentMethod,
    this.transactionReference,
    this.paidAt,
    this.currency,
  });

  final String id;
  final String invoiceNumber;
  final DateTime issueDate;
  final DateTime dueDate;
  final double baseAmount;
  final double taxAmount;
  final double discountAmount;
  final double scholarshipAmount;
  final double totalAmount;
  final double amountPaid;
  final double amountDue;
  final String status;
  final String courseName;
  final String courseCode;
  final String? studentName;
  final String? studentId;
  final List<InvoiceItemEntity> items;
  final String? paymentMethod;
  final String? transactionReference;
  final DateTime? paidAt;
  final String? currency;

  bool get isPaid =>
      status.toLowerCase() == 'paid' ||
      status.toLowerCase() == 'settled' ||
      amountDue <= 0.01;

  bool get isDue => !isPaid;

  String get currencySymbol {
    final c = (currency ?? '').toUpperCase();
    if (c == 'INR' || c == '₹') return '₹';
    if (c == 'EUR' || c == '€') return '€';
    if (c == 'GBP' || c == '£') return '£';
    if (c == 'CAD') return 'CA\$';
    if (c == 'AUD') return 'AU\$';
    if (c.isNotEmpty && c != 'USD' && c != '\$') return '$c ';
    return '\$';
  }

  static String _formatNumber(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedInt = intPart.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '$formattedInt.$decPart';
  }

  String get formattedTotal => '$currencySymbol${_formatNumber(totalAmount)}';
  String get formattedDue => '$currencySymbol${_formatNumber(amountDue)}';
  String get formattedPaid => '$currencySymbol${_formatNumber(amountPaid)}';
  String get formattedBase => '$currencySymbol${_formatNumber(baseAmount)}';
  String get formattedDiscount => '-$currencySymbol${_formatNumber(discountAmount)}';
  String get formattedTax => '$currencySymbol${_formatNumber(taxAmount)}';

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String get formattedIssueDate {
    final local = issueDate.toLocal();
    final m = _months[local.month - 1];
    return '$m ${local.day}, ${local.year}';
  }

  String get formattedDueDate {
    final local = dueDate.toLocal();
    final m = _months[local.month - 1];
    return '$m ${local.day}, ${local.year}';
  }

  factory InvoiceEntity.fromJson(
    Map<String, dynamic> json, {
    String? fallbackStudentName,
    String? fallbackStudentId,
  }) {
    final rawItems = json['items'];
    final itemsList = <InvoiceItemEntity>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          itemsList.add(InvoiceItemEntity.fromJson(item));
        }
      }
    }

    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val == null) return fallback;
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return fallback;
      }
    }

    double parseAmount(dynamic val, [double fallback = 0.0]) {
      if (val == null) return fallback;
      final num? n = (val is num) ? val : num.tryParse(val.toString());
      if (n == null) return fallback;
      // TrueLern backend API authoritatively represents monetary figures
      // in minor currency units (cents / paise) matching Stripe.
      return (n / 100.0).toDouble();
    }

    final now = DateTime.now();
    final total = parseAmount(json['totalAmount'] ?? json['total'], 0.0);
    final paid = parseAmount(json['amountPaid'] ?? json['paidAmount'], 0.0);
    final rawDue = json['amountDue'] ?? json['outstandingAmount'];
    final due = rawDue != null ? parseAmount(rawDue, 0.0) : (total - paid);

    return InvoiceEntity(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ??
          json['number']?.toString() ??
          '#INV-000000',
      issueDate: parseDate(json['issueDate'] ?? json['createdAt'], now),
      dueDate: parseDate(json['dueDate'], now.add(const Duration(days: 14))),
      baseAmount: parseAmount(json['baseAmount'], total),
      taxAmount: parseAmount(json['taxAmount'], 0.0),
      discountAmount: parseAmount(json['discountAmount'], 0.0),
      scholarshipAmount: parseAmount(json['scholarshipAmount'], 0.0),
      totalAmount: total,
      amountPaid: paid,
      amountDue: due > 0 ? due : 0.0,
      status: json['status']?.toString().toLowerCase() ?? 'unpaid',
      courseName: json['courseName']?.toString() ??
          (json['course'] is Map ? json['course']['name']?.toString() : null) ??
          'Tuition Program',
      courseCode: json['courseCode']?.toString() ??
          (json['course'] is Map ? json['course']['code']?.toString() : null) ??
          'TL-PROG',
      studentName: json['studentName']?.toString() ?? fallbackStudentName,
      studentId: json['studentId']?.toString() ?? fallbackStudentId,
      items: itemsList,
      paymentMethod: json['paymentMethod']?.toString(),
      transactionReference: json['transactionReference']?.toString(),
      paidAt: json['paidAt'] != null ? parseDate(json['paidAt'], now) : null,
      currency: json['currency']?.toString(),
    );
  }
}

/// Aggregate financial overview for a parent or child.
@immutable
class FinanceOverviewEntity {
  const FinanceOverviewEntity({
    required this.totalInvoiced,
    required this.totalPaid,
    required this.totalDue,
    this.currency,
  });

  final double totalInvoiced;
  final double totalPaid;
  final double totalDue;
  final String? currency;

  String get currencySymbol {
    final c = (currency ?? '').toUpperCase();
    if (c == 'INR' || c == '₹') return '₹';
    if (c == 'EUR' || c == '€') return '€';
    if (c == 'GBP' || c == '£') return '£';
    if (c == 'CAD') return 'CA\$';
    if (c == 'AUD') return 'AU\$';
    if (c.isNotEmpty && c != 'USD' && c != '\$') return '$c ';
    return '\$';
  }

  static String _formatNumber(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formattedInt = intPart.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '$formattedInt.$decPart';
  }

  String get formattedDue => '$currencySymbol${_formatNumber(totalDue)}';
  String get formattedInvoiced => '$currencySymbol${_formatNumber(totalInvoiced)}';
  String get formattedPaid => '$currencySymbol${_formatNumber(totalPaid)}';

  factory FinanceOverviewEntity.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic val) {
      if (val == null) return 0.0;
      final num? n = (val is num) ? val : num.tryParse(val.toString());
      if (n == null) return 0.0;
      return (n / 100.0).toDouble();
    }

    return FinanceOverviewEntity(
      totalInvoiced: parseAmount(json['totalInvoiced']),
      totalPaid: parseAmount(json['totalPaid']),
      totalDue: parseAmount(json['totalDue'] ?? json['outstandingBalance']),
      currency: json['currency']?.toString(),
    );
  }

  static const FinanceOverviewEntity zero = FinanceOverviewEntity(
    totalInvoiced: 0,
    totalPaid: 0,
    totalDue: 0,
  );
}

/// Payment record for an invoice.
@immutable
class PaymentRecordEntity {
  const PaymentRecordEntity({
    required this.id,
    required this.paymentNumber,
    required this.paymentDate,
    required this.amount,
    required this.paymentMethod,
    required this.transactionReference,
    required this.status,
    this.receiptId,
  });

  final String id;
  final String paymentNumber;
  final DateTime paymentDate;
  final double amount;
  final String paymentMethod;
  final String transactionReference;
  final String status;
  final String? receiptId;

  factory PaymentRecordEntity.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    double parseAmount(dynamic val) {
      if (val == null) return 0.0;
      final num? n = (val is num) ? val : num.tryParse(val.toString());
      if (n == null) return 0.0;
      return (n / 100.0).toDouble();
    }

    return PaymentRecordEntity(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      paymentNumber: json['paymentNumber']?.toString() ?? '',
      paymentDate: parseDate(json['paymentDate'] ?? json['createdAt']),
      amount: parseAmount(json['amount']),
      paymentMethod: json['paymentMethod']?.toString() ?? 'online-gateway',
      transactionReference: json['transactionReference']?.toString() ?? '',
      status: json['status']?.toString().toLowerCase() ?? 'success',
      receiptId: json['receipt'] is Map
          ? json['receipt']['id']?.toString()
          : json['receiptId']?.toString(),
    );
  }
}
