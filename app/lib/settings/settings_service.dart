import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils.dart';
import '../invoices/invoice_model.dart';
import 'settings_model.dart';

abstract class SettingsService {
  Future<UserSettings> get();

  Future<void> updateDefaults({
    required String currency,
    required TaxMode taxMode,
    required Decimal taxRate,
  });
}

class SupabaseSettingsService implements SettingsService {
  SupabaseSettingsService(this._client);

  final SupabaseClient _client;

  @override
  Future<UserSettings> get() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AppFailure('Not signed in');

    final row = await guardRequest(
      () => _client.from('users').select().eq('id', userId).maybeSingle(),
    );
    if (row == null) throw const AppFailure('User profile not found');

    return UserSettings(
      username: row['username'] as String,
      defaultCurrency: row['default_currency'] as String,
      defaultTaxMode: TaxMode.fromName(row['default_tax_mode'] as String),
      defaultTaxRate: decimalFromJson(row['default_tax_rate']),
    );
  }

  @override
  Future<void> updateDefaults({
    required String currency,
    required TaxMode taxMode,
    required Decimal taxRate,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AppFailure('Not signed in');

    final rows = await guardRequest(
      () => _client
          .from('users')
          .update({
            'default_currency': currency,
            'default_tax_mode': taxMode.name,
            'default_tax_rate': taxRate.toString(),
          })
          .eq('id', userId)
          .select(),
    );
    if (rows.isEmpty) throw const AppFailure('User profile not found');
  }
}

final settingsServiceProvider = Provider<SettingsService>(
  (_) => SupabaseSettingsService(Supabase.instance.client),
);

final userSettingsProvider = FutureProvider.autoDispose<UserSettings>(
  (ref) => ref.watch(settingsServiceProvider).get(),
);
