import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'invoice_model.dart';
import 'invoice_service.dart';

class InvoiceFilter {
  const InvoiceFilter({this.status, this.search = ''});

  final InvoiceStatus? status;
  final String search;
}

class InvoiceFilterController extends Notifier<InvoiceFilter> {
  @override
  InvoiceFilter build() => const InvoiceFilter();

  void setStatus(InvoiceStatus? status) =>
      state = InvoiceFilter(status: status, search: state.search);

  void setSearch(String search) =>
      state = InvoiceFilter(status: state.status, search: search);
}

final invoiceFilterProvider =
    NotifierProvider.autoDispose<InvoiceFilterController, InvoiceFilter>(
      InvoiceFilterController.new,
    );

final invoiceListProvider = FutureProvider.autoDispose<List<Invoice>>((ref) {
  final filter = ref.watch(invoiceFilterProvider);
  return ref
      .watch(invoiceServiceProvider)
      .list(status: filter.status, search: filter.search.trim());
});

final invoiceProvider = FutureProvider.autoDispose.family<Invoice, String>(
  (ref, id) => ref.watch(invoiceServiceProvider).get(id),
);

final invoiceCountsProvider =
    FutureProvider.autoDispose<Map<InvoiceStatus, int>>(
      (ref) => ref.watch(invoiceServiceProvider).statusCounts(),
    );
