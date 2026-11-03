import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import 'invoice_model.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});

  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      InvoiceStatus.draft => (AppColors.draftBg, AppColors.draft),
      InvoiceStatus.approved => (AppColors.approvedBg, AppColors.approved),
      InvoiceStatus.cancelled => (AppColors.cancelledBg, AppColors.cancelled),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

const numberStyle = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);

class TotalsCard extends StatelessWidget {
  const TotalsCard({
    super.key,
    required this.symbol,
    required this.subtotal,
    required this.taxRate,
    required this.tax,
    required this.total,
  });

  final String symbol;
  final Decimal subtotal;
  final Decimal taxRate;
  final Decimal tax;
  final Decimal total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _row('Subtotal', formatMoney(subtotal, symbol)),
          const SizedBox(height: 6),
          _row('Tax ${plainDecimal(taxRate)}%', formatMoney(tax, symbol)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: AppColors.line),
          ),
          _row('Total', formatMoney(total, symbol), bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontSize: bold ? 17 : 14,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style.merge(numberStyle)),
      ],
    );
  }
}
