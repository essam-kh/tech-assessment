import 'package:decimal/decimal.dart';

class Item {
  const Item({
    required this.id,
    required this.barcode,
    required this.name,
    required this.unitPrice,
  });

  final String id;
  final String barcode;
  final String name;
  final Decimal unitPrice;
}
