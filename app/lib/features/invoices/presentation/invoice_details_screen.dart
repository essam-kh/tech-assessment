import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class InvoiceDetailsScreen extends StatelessWidget {
  const InvoiceDetailsScreen({super.key, required this.invoiceId});

  final String invoiceId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(title: 'Invoice $invoiceId');
  }
}
