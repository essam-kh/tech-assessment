import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_service.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../currencies/currency_model.dart';
import '../currencies/currency_picker.dart';
import '../currencies/currency_service.dart';
import '../invoices/invoice_controller.dart';
import '../invoices/invoice_draft.dart';
import '../invoices/invoice_model.dart';
import '../invoices/invoice_widgets.dart';
import 'settings_model.dart';
import 'settings_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final currencies = ref.watch(currenciesProvider);

    final error = settings.error ?? currencies.error;
    final settingsValue = settings.value;
    final currenciesValue = currencies.value;

    if (error == null && settingsValue != null && currenciesValue != null) {
      return _SettingsForm(
        settings: settingsValue,
        currencies: currenciesValue,
      );
    }

    final Widget content;
    if (error != null) {
      content = Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(failureMessage(error), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                ref.invalidate(userSettingsProvider);
                ref.invalidate(currenciesProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else {
      content = const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(14), children: [content]),
      bottomNavigationBar: const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: _ButtonRow(children: [_LogoutButton()]),
        ),
      ),
    );
  }
}

class _ButtonRow extends StatelessWidget {
  const _ButtonRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton(
      onPressed: () => ref.read(authServiceProvider).signOut(),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.cancelled,
        side: const BorderSide(color: AppColors.cancelled),
      ),
      child: const Text('Log out'),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({required this.settings, required this.currencies});

  final UserSettings settings;
  final List<Currency> currencies;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  late String _currency;
  late TaxMode _taxMode;
  late String _taxRateText;
  late String _savedCurrency;
  late TaxMode _savedTaxMode;
  late Decimal _savedTaxRate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _currency = _savedCurrency = s.defaultCurrency;
    _taxMode = _savedTaxMode = s.defaultTaxMode;
    _taxRateText = plainDecimal(s.defaultTaxRate);
    _savedTaxRate = s.defaultTaxRate;
  }

  bool get _dirty =>
      _currency != _savedCurrency ||
      _taxMode != _savedTaxMode ||
      Decimal.tryParse(_taxRateText.trim()) != _savedTaxRate;

  String? get _taxRateError => validateTaxRate(_taxRateText);

  bool get _canSave => _dirty && _taxRateError == null && !_saving;

  Future<void> _pickCurrency() async {
    final code = await showCurrencyPicker(
      context,
      currencies: widget.currencies,
      selected: _currency,
    );
    if (code != null) setState(() => _currency = code);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final taxRate = Decimal.parse(_taxRateText.trim());
      await ref
          .read(settingsServiceProvider)
          .updateDefaults(
            currency: _currency,
            taxMode: _taxMode,
            taxRate: taxRate,
          );
      ref.invalidate(userSettingsProvider);
      if (!mounted) return;
      setState(() {
        _savedCurrency = _currency;
        _savedTaxMode = _taxMode;
        _savedTaxRate = taxRate;
        _taxRateText = plainDecimal(taxRate);
      });
      messenger.showSnackBar(const SnackBar(content: Text('Defaults saved')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(failureMessage(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _ProfileCard(username: widget.settings.username),
          const SizedBox(height: 14),
          const _SummaryCard(),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('New invoice defaults'),
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _pickCurrency,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        suffixIcon: Icon(Icons.keyboard_arrow_down),
                      ),
                      child: Text(_currency),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TaxModeField(
                          value: _taxMode,
                          onChanged: (mode) => setState(() => _taxMode = mode),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 110,
                        child: TextFormField(
                          initialValue: _taxRateText,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Tax rate %',
                            errorText: _taxRateError,
                            errorMaxLines: 2,
                          ),
                          onChanged: (value) =>
                              setState(() => _taxRateText = value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: _ButtonRow(
            children: [
              const _LogoutButton(),
              FilledButton(
                onPressed: _canSave ? _save : null,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save defaults'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    final initial = username.trim().isEmpty
        ? '?'
        : username.trim().characters.first.toUpperCase();

    return Card(
      color: AppColors.surfaceAlt,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Username',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(invoiceCountsProvider);
    final values = counts.value;
    final total = values?.values.fold<int>(0, (sum, n) => sum + n);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: SectionLabel('Your invoices')),
                if (total != null)
                  Text(
                    '$total total',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (counts.hasError && values == null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      failureMessage(counts.error!),
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(invoiceCountsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              )
            else
              Row(
                children: [
                  for (final status in InvoiceStatus.values) ...[
                    if (status != InvoiceStatus.values.first)
                      const SizedBox(width: 10),
                    Expanded(
                      child: _CountTile(status: status, count: values?[status]),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.status, required this.count});

  final InvoiceStatus status;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      InvoiceStatus.draft => AppColors.draft,
      InvoiceStatus.approved => AppColors.approved,
      InvoiceStatus.cancelled => AppColors.cancelled,
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(
            count?.toString() ?? '–',
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status.label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
