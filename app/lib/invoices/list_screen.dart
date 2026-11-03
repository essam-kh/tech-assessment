import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../currencies/currency_service.dart';
import 'invoice_model.dart';
import 'invoice_controller.dart';
import 'invoice_widgets.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => ref.read(invoiceFilterProvider.notifier).setSearch(value),
    );
  }

  Future<void> _open(String path) async {
    await context.push(path);
    if (mounted) ref.invalidate(invoiceListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(invoiceFilterProvider);
    final invoices = ref.watch(invoiceListProvider);
    final symbols = ref.watch(currencySymbolsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open('/invoices/new'),
        icon: const Icon(Icons.add),
        label: const Text('New invoice'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: TextField(
              onChanged: _onSearchChanged,
              autocorrect: false,
              decoration: const InputDecoration(
                hintText: 'Search number or customer',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: filter.status == null,
                  onTap: () =>
                      ref.read(invoiceFilterProvider.notifier).setStatus(null),
                ),
                for (final status in InvoiceStatus.values)
                  _FilterChip(
                    label: status.label,
                    selected: filter.status == status,
                    onTap: () => ref
                        .read(invoiceFilterProvider.notifier)
                        .setStatus(status),
                  ),
              ],
            ),
          ),
          Expanded(
            child: invoices.when(
              skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _Message(
                text: failureMessage(error),
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(invoiceListProvider),
              ),
              data: (list) => RefreshIndicator(
                onRefresh: () => ref.refresh(invoiceListProvider.future),
                child: list.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 80),
                          Center(
                            child: Text(
                              'No invoices match.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 90),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, index) => _InvoiceCard(
                          invoice: list[index],
                          symbol:
                              symbols[list[index].currencyCode] ??
                              list[index].currencyCode,
                          onTap: () => _open('/invoices/${list[index].id}'),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.ink,
        labelStyle: TextStyle(
          color: selected ? AppColors.background : AppColors.muted,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: selected ? AppColors.ink : AppColors.line),
        shape: const StadiumBorder(),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.invoice,
    required this.symbol,
    required this.onTap,
  });

  final Invoice invoice;
  final String symbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(invoice.invoiceNo, style: numberStyle),
                  StatusPill(invoice.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                invoice.customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatDate(invoice.date),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  Text(formatMoney(invoice.total, symbol), style: numberStyle),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
