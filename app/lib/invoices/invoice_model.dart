import 'package:decimal/decimal.dart';

enum InvoiceStatus {
  draft,
  approved,
  cancelled;

  static InvoiceStatus fromName(String name) =>
      InvoiceStatus.values.firstWhere((s) => s.name == name);

  String get label => name[0].toUpperCase() + name.substring(1);
}

enum TaxMode {
  exclusive,
  inclusive;

  static TaxMode fromName(String name) =>
      TaxMode.values.firstWhere((m) => m.name == name);

  String get label => name[0].toUpperCase() + name.substring(1);
}

class InvoiceLine {
  const InvoiceLine({
    required this.itemName,
    required this.unitPrice,
    required this.qty,
    required this.net,
    required this.tax,
    required this.total,
  });

  final String itemName;
  final Decimal unitPrice;
  final int qty;
  final Decimal net;
  final Decimal tax;
  final Decimal total;
}

class Invoice {
  const Invoice({
    required this.id,
    required this.invoiceNo,
    required this.status,
    required this.date,
    required this.customerName,
    required this.currencyCode,
    required this.exchangeRate,
    required this.taxMode,
    required this.taxRate,
    required this.subtotal,
    required this.taxTotal,
    required this.total,
    required this.cancelReason,
    required this.lines,
  });

  final String id;
  final String invoiceNo;
  final InvoiceStatus status;
  final DateTime date;
  final String customerName;
  final String currencyCode;
  final Decimal exchangeRate;
  final TaxMode taxMode;
  final Decimal taxRate;
  final Decimal subtotal;
  final Decimal taxTotal;
  final Decimal total;
  final String? cancelReason;
  final List<InvoiceLine> lines;
}
