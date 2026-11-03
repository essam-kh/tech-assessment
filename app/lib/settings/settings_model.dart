import 'package:decimal/decimal.dart';

import '../invoices/invoice_model.dart';

class UserSettings {
  const UserSettings({
    required this.username,
    required this.defaultCurrency,
    required this.defaultTaxMode,
    required this.defaultTaxRate,
  });

  final String username;
  final String defaultCurrency;
  final TaxMode defaultTaxMode;
  final Decimal defaultTaxRate;
}
