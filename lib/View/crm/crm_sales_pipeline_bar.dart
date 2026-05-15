import '../../screen.dart';

void openModuleShellRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

/// Shows linked CRM + sales documents from [salesChain] API payload.
class CrmSalesPipelineBar extends StatelessWidget {
  const CrmSalesPipelineBar({
    super.key,
    required this.data,
    this.title = 'Sales pipeline',
    this.hideLeadChip = false,
    this.hideEnquiryChip = false,
    this.hideOpportunityChip = false,
    this.hideQuotationChip = false,
    this.hideOrderChip = false,
    this.hideInvoiceChip = false,
    this.hideReceiptChip = false,
  });

  final Map<String, dynamic>? data;
  final String title;
  final bool hideLeadChip;
  final bool hideEnquiryChip;
  final bool hideOpportunityChip;
  final bool hideQuotationChip;
  final bool hideOrderChip;
  final bool hideInvoiceChip;
  final bool hideReceiptChip;

  static Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map<String, dynamic>) {
      return v;
    }
    if (v is Map) {
      return Map<String, dynamic>.from(v);
    }
    return null;
  }

  static List<Map<String, dynamic>> _asMapList(dynamic v) {
    if (v is! List) {
      return const <Map<String, dynamic>>[];
    }
    return v
        .map((e) => _asMap(e))
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
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

    final lead = _asMap(data!['lead']);
    final enquiry = _asMap(data!['enquiry']);
    final opportunity = _asMap(data!['opportunity']);
    final quotations = _asMapList(data!['quotations']);
    final orders = _asMapList(data!['orders']);
    final invoices = _asMapList(data!['invoices']);
    final receipts = _asMapList(data!['receipts']);

    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;

    final chips = <Widget>[
      if (!hideLeadChip && lead != null && intValue(lead, 'id') != null)
        _PipelineChip(
          label: _docLabel('Lead', lead, 'lead_name'),
          subtitle: stringValue(lead, 'lead_status'),
          onTap: () => openModuleShellRoute(context, '/crm/leads'),
        ),
      if (!hideEnquiryChip &&
          enquiry != null &&
          intValue(enquiry, 'id') != null)
        _PipelineChip(
          label: _docLabel('Enquiry', enquiry, 'enquiry_no'),
          subtitle: stringValue(enquiry, 'enquiry_status'),
          onTap: () => openModuleShellRoute(
            context,
            '/crm/enquiries?select_id=${intValue(enquiry, 'id')}',
          ),
        ),
      if (!hideOpportunityChip &&
          opportunity != null &&
          intValue(opportunity, 'id') != null)
        _PipelineChip(
          label: _docLabel('Opportunity', opportunity, 'opportunity_name'),
          subtitle: stringValue(opportunity, 'status'),
          onTap: () => openModuleShellRoute(
            context,
            '/crm/opportunities?select_id=${intValue(opportunity, 'id')}',
          ),
        ),
      for (final q in quotations)
        if (!hideQuotationChip && intValue(q, 'id') != null)
          _PipelineChip(
            label: _docLabel('Quote', q, 'quotation_no'),
            subtitle: stringValue(q, 'quotation_status'),
            onTap: () => openModuleShellRoute(
              context,
              '/sales/quotations/${intValue(q, 'id')}',
            ),
          ),
      for (final o in orders)
        if (!hideOrderChip && intValue(o, 'id') != null)
          _PipelineChip(
            label: _docLabel('Order', o, 'order_no'),
            subtitle: stringValue(o, 'order_status'),
            onTap: () => openModuleShellRoute(
              context,
              '/sales/orders/${intValue(o, 'id')}',
            ),
          ),
      for (final inv in invoices)
        if (!hideInvoiceChip && intValue(inv, 'id') != null)
          _PipelineChip(
            label: _docLabel('Invoice', inv, 'invoice_no'),
            subtitle: stringValue(inv, 'invoice_status'),
            onTap: () => openModuleShellRoute(
              context,
              '/sales/invoices/${intValue(inv, 'id')}',
            ),
          ),
      for (final r in receipts)
        if (!hideReceiptChip && intValue(r, 'id') != null)
          _PipelineChip(
            label: _docLabel('Receipt', r, 'receipt_no'),
            subtitle: stringValue(r, 'receipt_status'),
            onTap: () => openModuleShellRoute(
              context,
              '/sales/receipts/${intValue(r, 'id')}',
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

class _PipelineChip extends StatelessWidget {
  const _PipelineChip({
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
