import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils.dart';
import 'invoice_draft.dart';
import 'invoice_model.dart';

abstract class InvoiceService {
  Future<List<Invoice>> list({InvoiceStatus? status, String? search});

  Future<Invoice> get(String id);

  Future<Invoice> create(NewInvoice invoice);

  Future<Invoice> approve(String id);

  Future<Invoice> cancel(String id, String reason);
}

class SupabaseInvoiceService implements InvoiceService {
  SupabaseInvoiceService(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Invoice>> list({InvoiceStatus? status, String? search}) async {
    final rows = await guardRequest(
      () => _client.rpc(
        'list_invoices',
        params: {'p_status': status?.name, 'p_search': search},
      ),
    );
    return [
      for (final row in rows as List<dynamic>)
        _invoiceFromJson(row as Map<String, dynamic>),
    ];
  }

  @override
  Future<Invoice> get(String id) async {
    final json = await guardRequest(
      () => _client.rpc('get_invoice', params: {'p_id': id}),
    );
    if (json == null) throw const AppFailure('Invoice not found');
    return _invoiceFromJson(json as Map<String, dynamic>);
  }

  @override
  Future<Invoice> create(NewInvoice invoice) async {
    final json = await guardRequest(
      () => _client.rpc(
        'create_invoice',
        params: {
          'p_prefix': invoice.prefix,
          'p_customer_name': invoice.customerName,
          'p_currency_code': invoice.currencyCode,
          'p_exchange_rate': invoice.exchangeRate.toString(),
          'p_tax_mode': invoice.taxMode.name,
          'p_tax_rate': invoice.taxRate.toString(),
          'p_lines': [
            for (final line in invoice.lines)
              {'item_id': line.itemId, 'qty': line.qty},
          ],
        },
      ),
    );
    return _invoiceFromJson(json as Map<String, dynamic>);
  }

  @override
  Future<Invoice> approve(String id) async {
    final json = await guardRequest(
      () => _client.rpc('approve_invoice', params: {'p_id': id}),
    );
    return _invoiceFromJson(json as Map<String, dynamic>);
  }

  @override
  Future<Invoice> cancel(String id, String reason) async {
    final json = await guardRequest(
      () => _client.rpc(
        'cancel_invoice',
        params: {'p_id': id, 'p_reason': reason},
      ),
    );
    return _invoiceFromJson(json as Map<String, dynamic>);
  }
}

Invoice _invoiceFromJson(Map<String, dynamic> json) {
  final items = json['items'] as List<dynamic>? ?? const [];
  return Invoice(
    id: json['id'] as String,
    invoiceNo: json['invoice_no'] as String,
    status: InvoiceStatus.fromName(json['status'] as String),
    date: DateTime.parse(json['invoice_date'] as String),
    customerName: json['customer_name'] as String,
    currencyCode: json['currency_code'] as String,
    exchangeRate: decimalFromJson(json['exchange_rate']),
    taxMode: TaxMode.fromName(json['tax_mode'] as String),
    taxRate: decimalFromJson(json['tax_rate']),
    subtotal: decimalFromJson(json['subtotal']),
    taxTotal: decimalFromJson(json['tax_total']),
    total: decimalFromJson(json['total']),
    cancelReason: json['cancel_reason'] as String?,
    lines: [
      for (final line in items) _lineFromJson(line as Map<String, dynamic>),
    ],
  );
}

InvoiceLine _lineFromJson(Map<String, dynamic> json) {
  return InvoiceLine(
    itemName: json['item_name'] as String,
    unitPrice: decimalFromJson(json['unit_price']),
    qty: json['qty'] as int,
    net: decimalFromJson(json['line_net']),
    tax: decimalFromJson(json['line_tax']),
    total: decimalFromJson(json['line_total']),
  );
}

final invoiceServiceProvider = Provider<InvoiceService>(
  (_) => SupabaseInvoiceService(Supabase.instance.client),
);
