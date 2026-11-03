import 'package:decimal/decimal.dart';

import '../core/utils.dart';
import '../items/item_model.dart';
import 'invoice_model.dart';
import 'tax_calculator.dart';

enum DraftField { prefix, customer, rate, taxRate, lines }

const maxLineQty = 9999;

String? validateTaxRate(String text) {
  final rate = Decimal.tryParse(text.trim());
  if (rate == null) return 'Enter a number';
  if (rate < Decimal.zero || rate > Decimal.fromInt(100)) {
    return 'Between 0 and 100';
  }
  if (rate.round(scale: 2) != rate) return 'Up to 2 decimals';
  return null;
}

class DraftLine {
  const DraftLine({required this.item, required this.qty});

  final Item item;
  final int qty;
}

class NewInvoiceLine {
  const NewInvoiceLine({required this.itemId, required this.qty});

  final String itemId;
  final int qty;
}

class NewInvoice {
  const NewInvoice({
    required this.prefix,
    required this.customerName,
    required this.currencyCode,
    required this.exchangeRate,
    required this.taxMode,
    required this.taxRate,
    required this.lines,
  });

  final String prefix;
  final String customerName;
  final String currencyCode;
  final Decimal exchangeRate;
  final TaxMode taxMode;
  final Decimal taxRate;
  final List<NewInvoiceLine> lines;
}

class InvoiceDraft {
  const InvoiceDraft({
    required this.prefix,
    required this.customer,
    required this.currencyCode,
    required this.rateText,
    required this.taxMode,
    required this.taxRateText,
    this.lines = const [],
  });

  factory InvoiceDraft.fromInvoice(Invoice invoice, List<Item> items) {
    return InvoiceDraft(
      prefix: invoice.invoiceNo.split('-').first,
      customer: invoice.customerName,
      currencyCode: invoice.currencyCode,
      rateText: plainDecimal(invoice.exchangeRate),
      taxMode: invoice.taxMode,
      taxRateText: plainDecimal(invoice.taxRate),
      lines: [
        for (final line in invoice.lines)
          DraftLine(
            item: items.firstWhere(
              (item) => item.id == line.itemId,
              orElse: () =>
                  throw const AppFailure('An item on this invoice is missing'),
            ),
            qty: line.qty,
          ),
      ],
    );
  }

  final String prefix;
  final String customer;
  final String currencyCode;
  final String rateText;
  final TaxMode taxMode;
  final String taxRateText;
  final List<DraftLine> lines;

  static final _prefixPattern = RegExp(r'^[A-Z]{1,6}$');
  static final _maxRate = Decimal.fromInt(100000000);

  InvoiceDraft copyWith({
    String? prefix,
    String? customer,
    String? currencyCode,
    String? rateText,
    TaxMode? taxMode,
    String? taxRateText,
    List<DraftLine>? lines,
  }) {
    return InvoiceDraft(
      prefix: prefix ?? this.prefix,
      customer: customer ?? this.customer,
      currencyCode: currencyCode ?? this.currencyCode,
      rateText: rateText ?? this.rateText,
      taxMode: taxMode ?? this.taxMode,
      taxRateText: taxRateText ?? this.taxRateText,
      lines: lines ?? this.lines,
    );
  }

  InvoiceDraft addItem(Item item) {
    final index = lines.indexWhere((l) => l.item.id == item.id);
    if (index == -1) {
      return copyWith(
        lines: [
          ...lines,
          DraftLine(item: item, qty: 1),
        ],
      );
    }
    return withQty(index, lines[index].qty + 1);
  }

  InvoiceDraft withQty(int index, int qty) {
    final next = [...lines];
    next[index] = DraftLine(
      item: next[index].item,
      qty: qty.clamp(1, maxLineQty).toInt(),
    );
    return copyWith(lines: next);
  }

  InvoiceDraft removeAt(int index) {
    final next = [...lines]..removeAt(index);
    return copyWith(lines: next);
  }

  Decimal? get rate => Decimal.tryParse(rateText.trim());

  Decimal? get taxRate => Decimal.tryParse(taxRateText.trim());

  Map<DraftField, String> validate() {
    final errors = <DraftField, String>{};

    if (!_prefixPattern.hasMatch(prefix)) {
      errors[DraftField.prefix] = '1–6 letters';
    }
    if (customer.trim().isEmpty) {
      errors[DraftField.customer] = 'Enter the customer name';
    }

    final rate = this.rate;
    if (rate == null) {
      errors[DraftField.rate] = 'Enter a number';
    } else if (rate <= Decimal.zero) {
      errors[DraftField.rate] = 'Must be above 0';
    } else if (rate.round(scale: 4) != rate) {
      errors[DraftField.rate] = 'Up to 4 decimals';
    } else if (rate >= _maxRate) {
      errors[DraftField.rate] = 'Too large';
    }

    final taxRateError = validateTaxRate(taxRateText);
    if (taxRateError != null) errors[DraftField.taxRate] = taxRateError;

    if (lines.isEmpty) {
      errors[DraftField.lines] = 'Add at least one item';
    }

    return errors;
  }

  List<LineAmounts>? get amounts {
    final errors = validate();
    if (errors.containsKey(DraftField.rate) ||
        errors.containsKey(DraftField.taxRate)) {
      return null;
    }
    return [
      for (final line in lines)
        TaxCalculator.line(
          basePrice: line.item.unitPrice,
          exchangeRate: rate!,
          qty: line.qty,
          mode: taxMode,
          taxRate: taxRate!,
        ),
    ];
  }

  NewInvoice toNewInvoice() {
    assert(validate().isEmpty, 'Draft must be valid before it is submitted');
    return NewInvoice(
      prefix: prefix,
      customerName: customer.trim(),
      currencyCode: currencyCode,
      exchangeRate: rate!,
      taxMode: taxMode,
      taxRate: taxRate!,
      lines: [
        for (final line in lines)
          NewInvoiceLine(itemId: line.item.id, qty: line.qty),
      ],
    );
  }
}
