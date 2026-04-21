import '../../model/sales/sales_quotation_model.dart';
import '../../screen.dart';
import '../purchase/purchase_register_page.dart';
import '../purchase/purchase_support.dart';

void _openSalesShellRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

class SalesQuotationRegisterPage extends StatefulWidget {
  const SalesQuotationRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<SalesQuotationRegisterPage> createState() =>
      _SalesQuotationRegisterPageState();
}

class _SalesQuotationRegisterPageState extends State<SalesQuotationRegisterPage> {
  static const _statusItems = <AppDropdownItem<String>>[
    AppDropdownItem(value: '', label: 'All status'),
    AppDropdownItem(value: 'draft', label: 'Draft'),
    AppDropdownItem(value: 'sent', label: 'Sent'),
    AppDropdownItem(value: 'accepted', label: 'Accepted'),
    AppDropdownItem(value: 'rejected', label: 'Rejected'),
    AppDropdownItem(value: 'expired', label: 'Expired'),
    AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
  ];

  final SalesService _service = SalesService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String _status = '';
  List<SalesQuotationModel> _rows = const <SalesQuotationModel>[];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _service.quotations(
        filters: const {'per_page': 200, 'sort_by': 'quotation_date'},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _rows = response.data ?? const <SalesQuotationModel>[];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  List<SalesQuotationModel> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _rows
        .where((row) {
          final data = row.toJson();
          final statusOk = _status.isEmpty ||
              stringValue(data, 'quotation_status') == _status;
          final customer = data['customer'];
          final custName = customer is Map
              ? stringValue(Map<String, dynamic>.from(customer), 'party_name')
              : '';
          final searchOk = query.isEmpty ||
              [
                stringValue(data, 'quotation_no'),
                stringValue(data, 'quotation_status'),
                custName,
              ].join(' ').toLowerCase().contains(query);
          return statusOk && searchOk;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<SalesQuotationModel>(
      title: 'Quotations',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No quotations yet. Create a quote for your customer.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () => _openSalesShellRoute(context, '/sales/quotations/new'),
          icon: Icons.add_outlined,
          label: 'New quotation',
        ),
      ],
      filters: _SalesRegisterFilters(
        searchController: _searchController,
        searchHint: 'Search number or customer',
        status: _status,
        statusItems: _statusItems,
        onStatusChanged: (value) => setState(() => _status = value ?? ''),
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn(
          label: 'No',
          valueBuilder: (row) => stringValue(row.toJson(), 'quotation_no'),
        ),
        PurchaseRegisterColumn(
          label: 'Date',
          valueBuilder: (row) => displayDate(
            nullableStringValue(row.toJson(), 'quotation_date'),
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Customer',
          flex: 3,
          valueBuilder: (row) {
            final data = row.toJson();
            final c = data['customer'];
            if (c is Map) {
              return stringValue(Map<String, dynamic>.from(c), 'party_name');
            }
            return '';
          },
        ),
        PurchaseRegisterColumn(
          label: 'Valid until',
          valueBuilder: (row) => displayDate(
            nullableStringValue(row.toJson(), 'valid_until'),
          ),
        ),
        PurchaseRegisterColumn(
          label: 'Status',
          valueBuilder: (row) =>
              stringValue(row.toJson(), 'quotation_status'),
        ),
        PurchaseRegisterColumn(
          label: 'Total',
          valueBuilder: (row) => stringValue(row.toJson(), 'total_amount'),
        ),
      ],
      onRowTap: (row) => _openSalesShellRoute(
        context,
        '/sales/quotations/${intValue(row.toJson(), 'id')}',
      ),
    );
  }
}

class _SalesRegisterFilters extends StatelessWidget {
  const _SalesRegisterFilters({
    required this.searchController,
    required this.searchHint,
    required this.status,
    required this.statusItems,
    required this.onStatusChanged,
  });

  final TextEditingController searchController;
  final String searchHint;
  final String status;
  final List<AppDropdownItem<String>> statusItems;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsFormWrap(
      children: [
        AppFormTextField(
          labelText: 'Search',
          controller: searchController,
          hintText: searchHint,
        ),
        AppDropdownField<String>.fromMapped(
          labelText: 'Status',
          mappedItems: statusItems,
          initialValue: status,
          onChanged: onStatusChanged,
        ),
      ],
    );
  }
}
