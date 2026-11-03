import 'package:decimal/decimal.dart';
import 'package:decimal/intl.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

String failureMessage(Object error) =>
    error is AppFailure ? error.message : 'Something went wrong. Try again.';

Future<T> guardRequest<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on PostgrestException catch (e) {
    throw AppFailure(e.message);
  } on Exception {
    throw const AppFailure(
      'Could not reach the server. Check your connection.',
    );
  }
}

final _moneyFormat = DecimalFormatter(NumberFormat('#,##0.00', 'en_US'));

Decimal decimalFromJson(Object? value) => Decimal.parse(value.toString());

String formatMoney(Decimal amount, String symbol) =>
    '$symbol ${_moneyFormat.format(amount)}';

String plainDecimal(Decimal value) =>
    value.isInteger ? value.toBigInt().toString() : value.toString();

String formatDate(DateTime date) => DateFormat('d MMM yyyy').format(date);

class UpperCaseFormatter extends TextInputFormatter {
  const UpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
