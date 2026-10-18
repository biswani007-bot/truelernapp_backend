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
    return InvoiceItemEntity(
      description: json['description']?.toString() ??
          json['name']?.toString() ??
          'Tuition Fee',
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
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

  bool get isPaid =>
      status.toLowerCase() == 'paid' ||
      status.toLowerCase() == 'settled' ||
      amountDue <= 0.01;

  bool get isDue => !isPaid;

  String get formattedTotal => '\$${totalAmount.toStringAsFixed(2)}';
  String get formattedDue => '\$${amountDue.toStringAsFixed(2)}';
  String get formattedPaid => '\$${amountPaid.toStringAsFixed(2)}';
  String get formattedBase => '\$${baseAmount.toStringAsFixed(2)}';
  String get formattedDiscount => '-\$${discountAmount.toStringAsFixed(2)}';
  String get formattedTax => '\$${taxAmount.toStringAsFixed(2)}';

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

    double parseDouble(dynamic val, double fallback) {
      if (val is num) return val.toDouble();
      if (val == null) return fallback;
      return double.tryParse(val.toString()) ?? fallback;
    }

    final now = DateTime.now();
    final total = parseDouble(json['totalAmount'], 0.0);
    final paid = parseDouble(json['amountPaid'], 0.0);
    final rawDue = json['amountDue'];
    final due = rawDue != null ? parseDouble(rawDue, 0.0) : (total - paid);

    return InvoiceEntity(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ??
          json['number']?.toString() ??
          '#INV-000000',
      issueDate: parseDate(json['issueDate'] ?? json['createdAt'], now),
      dueDate: parseDate(json['dueDate'], now.add(const Duration(days: 14))),
      baseAmount: parseDouble(json['baseAmount'], total),
      taxAmount: parseDouble(json['taxAmount'], 0.0),
      discountAmount: parseDouble(json['discountAmount'], 0.0),
      scholarshipAmount: parseDouble(json['scholarshipAmount'], 0.0),
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
  });

  final double totalInvoiced;
  final double totalPaid;
  final double totalDue;

  String get formattedDue => '\$${totalDue.toStringAsFixed(2)}';
  String get formattedInvoiced => '\$${totalInvoiced.toStringAsFixed(2)}';
  String get formattedPaid => '\$${totalPaid.toStringAsFixed(2)}';

  factory FinanceOverviewEntity.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val == null) return 0.0;
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return FinanceOverviewEntity(
      totalInvoiced: parseDouble(json['totalInvoiced']),
      totalPaid: parseDouble(json['totalPaid']),
      totalDue: parseDouble(json['totalDue']),
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

    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val == null) return 0.0;
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return PaymentRecordEntity(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      paymentNumber: json['paymentNumber']?.toString() ?? '',
      paymentDate: parseDate(json['paymentDate'] ?? json['createdAt']),
      amount: parseDouble(json['amount']),
      paymentMethod: json['paymentMethod']?.toString() ?? 'online-gateway',
      transactionReference: json['transactionReference']?.toString() ?? '',
      status: json['status']?.toString().toLowerCase() ?? 'success',
      receiptId: json['receipt'] is Map
          ? json['receipt']['id']?.toString()
          : json['receiptId']?.toString(),
    );
  }
}
