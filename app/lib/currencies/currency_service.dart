import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils.dart';
import 'currency_model.dart';

abstract class CurrencyService {
  Future<List<Currency>> list();
}

class SupabaseCurrencyService implements CurrencyService {
  SupabaseCurrencyService(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Currency>> list() async {
    final rows = await guardRequest(
      () => _client.from('currencies').select().order('code'),
    );
    return [
      for (final row in rows)
        Currency(
          code: row['code'] as String,
          name: row['name'] as String,
          symbol: row['symbol'] as String,
        ),
    ];
  }
}

final currencyServiceProvider = Provider<CurrencyService>(
  (_) => SupabaseCurrencyService(Supabase.instance.client),
);

final currenciesProvider = FutureProvider<List<Currency>>(
  (ref) => ref.watch(currencyServiceProvider).list(),
);

final currencySymbolsProvider = Provider<Map<String, String>>((ref) {
  final currencies = ref.watch(currenciesProvider).value ?? const [];
  return {for (final c in currencies) c.code: c.symbol};
});
