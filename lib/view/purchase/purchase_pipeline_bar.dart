import '../../screen.dart';

void _openPurchaseModuleShellRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

class PurchasePipelineBar extends StatelessWidget {
  const PurchasePipelineBar({
    super.key,
    required this.data,
    this.title = 'Purchase pipeline',
    this.hideOrderChip = false,
    this.hideReceiptChip = false,
    this.hideInvoiceChip = false,
    this.hidePaymentChip = false,
    this.hideReturnChip = false,
  });

  final Map<String, dynamic>? data;
  final String title;
  final bool hideOrderChip;
  final bool hideReceiptChip;
  final bool hideInvoiceChip;
  final bool hidePaymentChip;
  final bool hideReturnChip;

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }

    return value
        .map((entry) => _asMap(entry))
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> _uniqueDocsById(
    List<Map<String, dynamic>> rows,
  ) {
    final seen = <int>{};
    final unique = <Map<String, dynamic>>[];
    for (final row in rows) {
      final id = intValue(row, 'id');
      if (id == null) {
        unique.add(row);
        continue;
      }
      if (seen.add(id)) {
        unique.add(row);
      }
    }
    return unique;
  }

  static String _docLabel(
    String prefix,
    Map<String, dynamic> row,
    String nameKey,
  ) {
    final name = stringValue(row, nameKey);
    final id = intValue(row, 'id');
    if (name.isNotEmpty) {
      return '$prefix · $name';
    }
    return '$prefix · #${id ?? '-'}';
  }

  @override
  Widget build(BuildContext context) {
    if (data == null || data!.isEmpty) {
      return const SizedBox.shrink();
    }

    final orders = _uniqueDocsById(_asMapList(data!['orders']));
    final receipts = _uniqueDocsById(_asMapList(data!['receipts']));
    final invoices = _uniqueDocsById(_asMapList(data!['invoices']));
    final payments = _uniqueDocsById(_asMapList(data!['payments']));
    final returns = _uniqueDocsById(_asMapList(data!['returns']));

    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;

    final chips = <Widget>[
      for (final order in orders)
        if (!hideOrderChip && intValue(order, 'id') != null)
          _PurchasePipelineChip(
            label: _docLabel('Order', order, 'order_no'),
            subtitle: purchaseStatusLabel(stringValue(order, 'order_status')),
            onTap: () => _openPurchaseModuleShellRoute(
              context,
              '/purchase/orders/${intValue(order, 'id')}',
            ),
          ),
      for (final receipt in receipts)
        if (!hideReceiptChip && intValue(receipt, 'id') != null)
          _PurchasePipelineChip(
            label: _docLabel('Receipt', receipt, 'receipt_no'),
            subtitle: purchaseStatusLabel(
              stringValue(receipt, 'receipt_status'),
            ),
            onTap: () => _openPurchaseModuleShellRoute(
              context,
              '/purchase/receipts/${intValue(receipt, 'id')}',
            ),
          ),
      for (final invoice in invoices)
        if (!hideInvoiceChip && intValue(invoice, 'id') != null)
          _PurchasePipelineChip(
            label: _docLabel('Invoice', invoice, 'invoice_no'),
            subtitle: purchaseStatusLabel(
              stringValue(invoice, 'invoice_status'),
            ),
            onTap: () => _openPurchaseModuleShellRoute(
              context,
              '/purchase/invoices/${intValue(invoice, 'id')}',
            ),
          ),
      for (final payment in payments)
        if (!hidePaymentChip && intValue(payment, 'id') != null)
          _PurchasePipelineChip(
            label: _docLabel('Payment', payment, 'payment_no'),
            subtitle: purchaseStatusLabel(
              stringValue(payment, 'payment_status'),
            ),
            onTap: () => _openPurchaseModuleShellRoute(
              context,
              '/purchase/payments/${intValue(payment, 'id')}',
            ),
          ),
      for (final row in returns)
        if (!hideReturnChip && intValue(row, 'id') != null)
          _PurchasePipelineChip(
            label: _docLabel('Return', row, 'return_no'),
            subtitle: purchaseStatusLabel(stringValue(row, 'return_status')),
            onTap: () => _openPurchaseModuleShellRoute(
              context,
              '/purchase/returns/${intValue(row, 'id')}',
            ),
          ),
    ];

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppUiConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: appTheme.mutedText,
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          Wrap(
            spacing: AppUiConstants.spacingSm,
            runSpacing: AppUiConstants.spacingSm,
            children: chips,
          ),
        ],
      ),
    );
  }
}

class _PurchasePipelineChip extends StatelessWidget {
  const _PurchasePipelineChip({
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;

    return Material(
      color: appTheme.subtleFill,
      borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppUiConstants.spacingSm,
            vertical: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: appTheme.mutedText,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
