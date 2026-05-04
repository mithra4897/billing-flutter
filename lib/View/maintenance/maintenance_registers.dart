import '../../screen.dart';
import '../hr/hr_workflow_dialogs.dart';
import '../purchase/purchase_register_page.dart';
import '../purchase/purchase_support.dart';

void _openMaintenanceShellRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

String _workOrderNoLabel(MaintenanceWorkOrderModel row) {
  final data = row.toJson();
  final no = stringValue(data, 'work_order_no');
  if (no.isNotEmpty) {
    return no;
  }
  final id = intValue(data, 'id');
  return id != null ? 'WO #$id' : '—';
}

String _workOrderAssetLabel(MaintenanceWorkOrderModel row) {
  final data = row.toJson();
  final nested = data['asset'];
  if (nested is Map<String, dynamic>) {
    final code = stringValue(nested, 'asset_code');
    final name = stringValue(nested, 'asset_name');
    if (code.isNotEmpty && name.isNotEmpty) {
      return '$code — $name';
    }
    return code.isNotEmpty ? code : name;
  }
  return '—';
}

class _MaintFilters extends StatelessWidget {
  const _MaintFilters({
    required this.searchController,
    required this.searchHint,
    required this.companyBanner,
  });

  final TextEditingController searchController;
  final String searchHint;
  final String? companyBanner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (companyBanner != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.apartment_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppUiConstants.spacingSm),
                Expanded(
                  child: Text(
                    'Session company: $companyBanner. Lists use company_id '
                    'when loading from the API.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: AppUiConstants.spacingSm),
                Expanded(
                  child: Text(
                    'No company in session. Select a company in the header '
                    'to scope maintenance work order lists.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        AppFormTextField(
          labelText: 'Search',
          controller: searchController,
          hintText: searchHint,
        ),
      ],
    );
  }
}

class MaintenanceWorkOrderRegisterPage extends StatefulWidget {
  const MaintenanceWorkOrderRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MaintenanceWorkOrderRegisterPage> createState() =>
      _MaintenanceWorkOrderRegisterPageState();
}

class _MaintenanceWorkOrderRegisterPageState
    extends State<MaintenanceWorkOrderRegisterPage> {
  final MaintenanceService _service = MaintenanceService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<MaintenanceWorkOrderModel> _rows = const <MaintenanceWorkOrderModel>[];

  @override
  void initState() {
    super.initState();
    WorkingContextService.version.addListener(_onContextChanged);
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    WorkingContextService.version.removeListener(_onContextChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onContextChanged() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await hrSessionCompanyInfo();
      final filters = <String, dynamic>{'per_page': 200};
      if (info.companyId != null) {
        filters['company_id'] = info.companyId;
      }
      final response = await _service.workOrders(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <MaintenanceWorkOrderModel>[];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<MaintenanceWorkOrderModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((MaintenanceWorkOrderModel row) {
          if (q.isEmpty) {
            return true;
          }
          final data = row.toJson();
          return [
            stringValue(data, 'work_order_no'),
            stringValue(data, 'work_order_status'),
            stringValue(data, 'work_order_type'),
            _workOrderAssetLabel(row),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<MaintenanceWorkOrderModel>(
      title: 'Work orders',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No work orders found.',
      actions: [
        AdaptiveShellActionButton(
          onPressed: () =>
              _openMaintenanceShellRoute(context, '/maintenance/work-orders/new'),
          icon: Icons.add_outlined,
          label: 'New work order',
        ),
      ],
      filters: _MaintFilters(
        searchController: _searchController,
        searchHint: 'Search WO no., asset, type, status',
        companyBanner: _companyBanner,
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<MaintenanceWorkOrderModel>(
          label: 'WO no.',
          valueBuilder: (MaintenanceWorkOrderModel row) => _workOrderNoLabel(row),
        ),
        PurchaseRegisterColumn<MaintenanceWorkOrderModel>(
          label: 'Date',
          valueBuilder: (MaintenanceWorkOrderModel row) => displayDate(
            nullableStringValue(row.toJson(), 'work_order_date'),
          ),
        ),
        PurchaseRegisterColumn<MaintenanceWorkOrderModel>(
          label: 'Asset',
          flex: 2,
          valueBuilder: (MaintenanceWorkOrderModel row) =>
              _workOrderAssetLabel(row),
        ),
        PurchaseRegisterColumn<MaintenanceWorkOrderModel>(
          label: 'Status',
          valueBuilder: (MaintenanceWorkOrderModel row) =>
              stringValue(row.toJson(), 'work_order_status'),
        ),
      ],
      onRowTap: (MaintenanceWorkOrderModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        _openMaintenanceShellRoute(
          context,
          '/maintenance/work-orders/$id',
        );
      },
    );
  }
}
