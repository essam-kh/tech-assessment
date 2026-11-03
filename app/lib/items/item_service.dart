import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils.dart';
import 'item_model.dart';

abstract class ItemService {
  Future<List<Item>> list();
}

class SupabaseItemService implements ItemService {
  SupabaseItemService(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Item>> list() async {
    final rows = await guardRequest(
      () => _client.from('items').select().order('name'),
    );
    return [
      for (final row in rows)
        Item(
          id: row['id'] as String,
          barcode: row['barcode'] as String,
          name: row['name'] as String,
          unitPrice: decimalFromJson(row['unit_price']),
        ),
    ];
  }
}

final itemServiceProvider = Provider<ItemService>(
  (_) => SupabaseItemService(Supabase.instance.client),
);

final itemsProvider = FutureProvider.autoDispose<List<Item>>(
  (ref) => ref.watch(itemServiceProvider).list(),
);
