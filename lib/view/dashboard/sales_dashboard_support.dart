import '../../screen.dart';

const String salesOpenInvoiceStatusOverride = 'posted,overdue,partially_paid';

bool salesInvoiceIsOutstanding(SalesInvoiceModel invoice) {
  final status = (invoice.invoiceStatus ?? '').trim().toLowerCase();
  final balance = invoice.balanceAmount ?? 0;
  return status != 'draft' && status != 'cancelled' && balance > 0;
}

double totalSalesInvoiceOutstanding(Iterable<SalesInvoiceModel> invoices) {
  return invoices.fold<double>(
    0,
    (sum, invoice) => salesInvoiceIsOutstanding(invoice)
        ? sum + (invoice.balanceAmount ?? 0)
        : sum,
  );
}

String salesOpenInvoicesRoute() {
  return Uri(
    path: '/sales/invoices',
    queryParameters: const <String, String>{
      'dashboard_filter': 'open',
      'sort': 'balance_desc',
    },
  ).toString();
}
