import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class InvoiceListScreen extends StatelessWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: 'Invoices',
      links: [
        PlaceholderLink('New invoice', '/invoices/new'),
        PlaceholderLink('Open an invoice', '/invoices/sample'),
        PlaceholderLink('Settings', '/settings'),
      ],
    );
  }
}
