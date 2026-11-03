import 'package:decimal/decimal.dart';

import 'invoice_model.dart';

class LineAmounts {
  const LineAmounts({
    required this.unitPrice,
    required this.net,
    required this.tax,
    required this.total,
  });

  final Decimal unitPrice;
  final Decimal net;
  final Decimal tax;
  final Decimal total;
}

class InvoiceTotals {
  const InvoiceTotals({
    required this.subtotal,
    required this.taxTotal,
    required this.total,
  });

  final Decimal subtotal;
  final Decimal taxTotal;
  final Decimal total;
}

class TaxCalculator {
  TaxCalculator._();

  static final _hundred = Decimal.fromInt(100);

  static LineAmounts line({
    required Decimal basePrice,
    required Decimal exchangeRate,
    required int qty,
    required TaxMode mode,
    required Decimal taxRate,
  }) {
    final unitPrice = _divide(basePrice, exchangeRate).round(scale: 2);
    final quantity = Decimal.fromInt(qty);
    final rate = _divide(taxRate, _hundred);

    if (mode == TaxMode.exclusive) {
      final net = unitPrice * quantity;
      final tax = (net * rate).round(scale: 2);
      return LineAmounts(
        unitPrice: unitPrice,
        net: net,
        tax: tax,
        total: net + tax,
      );
    }

    final total = unitPrice * quantity;
    final net = _divide(total, Decimal.one + rate).round(scale: 2);
    return LineAmounts(
      unitPrice: unitPrice,
      net: net,
      tax: total - net,
      total: total,
    );
  }

  static InvoiceTotals totals(Iterable<LineAmounts> lines) {
    var subtotal = Decimal.zero;
    var tax = Decimal.zero;
    var total = Decimal.zero;
    for (final line in lines) {
      subtotal += line.net;
      tax += line.tax;
      total += line.total;
    }
    return InvoiceTotals(subtotal: subtotal, taxTotal: tax, total: total);
  }

  static Decimal _divide(Decimal a, Decimal b) =>
      (a / b).toDecimal(scaleOnInfinitePrecision: 20);
}
