import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../currencies/currency_model.dart';
import '../currencies/currency_picker.dart';
import '../currencies/currency_service.dart';
import '../items/item_picker.dart';
import '../settings/settings_model.dart';
import '../settings/settings_service.dart';
import 'invoice_draft.dart';
import 'tax_calculator.dart';
import 'invoice_model.dart';
import 'invoice_controller.dart';
import 'invoice_service.dart';
import 'invoice_widgets.dart';

class CreateInvoiceScreen extends ConsumerWidget {
  const CreateInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final currencies = ref.watch(currenciesProvider);

    final error = settings.error ?? currencies.error;
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('New invoice')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
          ),
        ),
      );
    }

    final settingsValue = settings.value;
    final currenciesValue = currencies.value;
    if (settingsValue == null || currenciesValue == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('New invoice')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return _InvoiceForm(settings: settingsValue, currencies: currenciesValue);
  }
}

class _InvoiceForm extends ConsumerStatefulWidget {
  const _InvoiceForm({required this.settings, required this.currencies});

  final UserSettings settings;
  final List<Currency> currencies;

  @override
  ConsumerState<_InvoiceForm> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends ConsumerState<_InvoiceForm> {
  late InvoiceDraft _draft;
  late final TextEditingController _rate;
  bool _showErrors = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    final rateText = s.defaultCurrency == baseCurrencyCode ? '1' : '';
    _rate = TextEditingController(text: rateText);
    _draft = InvoiceDraft(
      prefix: 'INV',
      customer: '',
      currencyCode: s.defaultCurrency,
      rateText: rateText,
      taxMode: s.defaultTaxMode,
      taxRateText: plainDecimal(s.defaultTaxRate),
    );
  }

  @override
  void dispose() {
    _rate.dispose();
    super.dispose();
  }

  String _symbolOf(String code) {
    for (final c in widget.currencies) {
      if (c.code == code) return c.symbol;
    }
    return code;
  }

  void _update(InvoiceDraft draft) => setState(() => _draft = draft);

  Future<void> _pickCurrency() async {
    final code = await showCurrencyPicker(
      context,
      currencies: widget.currencies,
      selected: _draft.currencyCode,
    );
    if (code == null || code == _draft.currencyCode) return;
    final rateText = code == baseCurrencyCode ? '1' : '';
    _rate.text = rateText;
    _update(_draft.copyWith(currencyCode: code, rateText: rateText));
  }

  Future<void> _addItem() async {
    final item = await showItemPicker(context);
    if (item != null) _update(_draft.addItem(item));
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_draft.validate().isNotEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() => _saving = true);
    try {
      final invoice = await ref
          .read(invoiceServiceProvider)
          .create(_draft.toNewInvoice());
      ref.invalidate(invoiceListProvider);
      if (!mounted) return;
      context.pushReplacement('/invoices/${invoice.id}');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureMessage(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final errors = _showErrors
        ? _draft.validate()
        : const <DraftField, String>{};
    final isBase = _draft.currencyCode == baseCurrencyCode;
    final symbol = _symbolOf(_draft.currencyCode);
    final amounts = _draft.amounts;
    final totals = amounts == null ? null : TaxCalculator.totals(amounts);
    final decimalInput = FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));

    return Scaffold(
      appBar: AppBar(title: const Text('New invoice')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: TextFormField(
                  initialValue: _draft.prefix,
                  maxLength: 6,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z]')),
                    const UpperCaseFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Prefix',
                    counterText: '',
                    errorText: errors[DraftField.prefix],
                  ),
                  onChanged: (v) => _update(_draft.copyWith(prefix: v)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: _draft.customer,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Customer',
                    errorText: errors[DraftField.customer],
                  ),
                  onChanged: (v) => _update(_draft.copyWith(customer: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _pickCurrency,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      suffixIcon: Icon(Icons.keyboard_arrow_down),
                    ),
                    child: Text(_draft.currencyCode),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _rate,
                  enabled: !isBase,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [decimalInput],
                  decoration: InputDecoration(
                    labelText: 'Rate to $baseCurrencyCode',
                    errorText: errors[DraftField.rate],
                  ),
                  onChanged: (v) => _update(_draft.copyWith(rateText: v)),
                ),
              ),
            ],
          ),
          if (!isBase)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '1 ${_draft.currencyCode} = '
                '${_draft.rateText.isEmpty ? '?' : _draft.rateText} '
                '$baseCurrencyCode',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TaxModeField(
                  value: _draft.taxMode,
                  onChanged: (mode) => _update(_draft.copyWith(taxMode: mode)),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 110,
                child: TextFormField(
                  initialValue: _draft.taxRateText,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [decimalInput],
                  decoration: InputDecoration(
                    labelText: 'Tax rate %',
                    errorText: errors[DraftField.taxRate],
                  ),
                  onChanged: (v) => _update(_draft.copyWith(taxRateText: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SectionLabel('Items'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
            label: const Text('Add item'),
          ),
          if (errors[DraftField.lines] != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                errors[DraftField.lines]!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 10),
          for (var i = 0; i < _draft.lines.length; i++) ...[
            _LineTile(
              line: _draft.lines[i],
              amounts: amounts?[i],
              symbol: symbol,
              onQty: (qty) => _update(_draft.withQty(i, qty)),
              onRemove: () => _update(_draft.removeAt(i)),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 6),
          TotalsCard(
            symbol: symbol,
            subtotal: totals?.subtotal ?? Decimal.zero,
            taxRate: _draft.taxRate ?? Decimal.zero,
            tax: totals?.taxTotal ?? Decimal.zero,
            total: totals?.total ?? Decimal.zero,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save as draft'),
          ),
        ),
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({
    required this.line,
    required this.amounts,
    required this.symbol,
    required this.onQty,
    required this.onRemove,
  });

  final DraftLine line;
  final LineAmounts? amounts;
  final String symbol;
  final ValueChanged<int> onQty;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final amounts = this.amounts;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  line.item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                amounts == null ? '—' : formatMoney(amounts.total, symbol),
                style: numberStyle.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                amounts == null
                    ? '—'
                    : '${formatMoney(amounts.unitPrice, symbol)} each',
                style: numberStyle.copyWith(
                  color: AppColors.muted,
                  fontSize: 12,
                ),
              ),
              Row(
                children: [
                  _StepButton(
                    icon: Icons.remove,
                    tooltip: 'Less',
                    onPressed: line.qty > 1 ? () => onQty(line.qty - 1) : null,
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${line.qty}',
                      textAlign: TextAlign.center,
                      style: numberStyle,
                    ),
                  ),
                  _StepButton(
                    icon: Icons.add,
                    tooltip: 'More',
                    onPressed: line.qty < maxLineQty
                        ? () => onQty(line.qty + 1)
                        : null,
                  ),
                  const SizedBox(width: 6),
                  _StepButton(
                    icon: Icons.close,
                    tooltip: 'Remove',
                    color: AppColors.cancelled,
                    onPressed: onRemove,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 18,
        tooltip: tooltip,
        color: color,
        style: IconButton.styleFrom(
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}

class _TaxModeField extends StatelessWidget {
  const _TaxModeField({required this.value, required this.onChanged});

  final TaxMode value;
  final ValueChanged<TaxMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Tax mode',
        contentPadding: EdgeInsets.all(5),
      ),
      child: Row(
        children: [
          for (final mode in TaxMode.values)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => onChanged(mode),
                child: Container(
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: mode == value ? AppColors.accent : null,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    mode.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: mode == value
                          ? AppColors.onAccent
                          : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
