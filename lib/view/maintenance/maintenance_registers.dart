import '../../screen.dart';
import '../../view_model/maintenance/maintenance_module_refresh_controller.dart';

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
  return id != null ? 'WO #$id' : '-';
}

String _workOrderAssetLabel(MaintenanceWorkOrderModel row) {
  final data = row.toJson();
  final nested = data['asset'];
  if (nested is Map<String, dynamic>) {
    final code = stringValue(nested, 'asset_code');
    final name = stringValue(nested, 'asset_name');
    if (code.isNotEmpty && name.isNotEmpty) {
      return '$code - $name';
    }
    return code.isNotEmpty ? code : name;
  }
  return '-';
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

class MaintenanceWorkOrderRegisterController extends GetxController {
  final MaintenanceService _service = MaintenanceService();
  final MaintenanceModuleRefreshController _refreshController =
      MaintenanceModuleRefreshController.ensureRegistered();
  final TextEditingController searchController = TextEditingController();

  bool loading = true;
  String? error;
  String? companyBanner;
  List<MaintenanceWorkOrderModel> rows = const <MaintenanceWorkOrderModel>[];
  Worker? _refreshWorker;

  @override
  void onInit() {
    super.onInit();
    WorkingContextService.version.addListener(_onContextChanged);
    searchController.addListener(update);
    _refreshWorker = ever<MaintenanceModuleRefreshEvent?>(
      _refreshController.lastEvent,
      (event) {
        if (event == null) {
          return;
        }
        unawaited(load());
      },
    );
    unawaited(load());
  }

  @override
  void onClose() {
    _refreshWorker?.dispose();
    WorkingContextService.version.removeListener(_onContextChanged);
    searchController
      ..removeListener(update)
      ..dispose();
    super.onClose();
  }

  void _onContextChanged() {
    unawaited(load());
  }

  Future<void> load() async {
    loading = true;
    error = null;
    update();
    try {
      final info = await hrSessionCompanyInfo();
      final filters = <String, dynamic>{'per_page': 200};
      if (info.companyId != null) {
        filters['company_id'] = info.companyId;
      }
      final response = await _service.workOrders(filters: filters);
      companyBanner = info.banner;
      rows = response.data ?? const <MaintenanceWorkOrderModel>[];
      loading = false;
      update();
    } catch (err) {
      error = err.toString();
      loading = false;
      update();
    }
  }

  List<MaintenanceWorkOrderModel> get filteredRows {
    final query = searchController.text.trim().toLowerCase();
    return rows
        .where((row) {
          if (query.isEmpty) {
            return true;
          }
          final data = row.toJson();
          return [
            stringValue(data, 'work_order_no'),
            stringValue(data, 'work_order_status'),
            stringValue(data, 'work_order_type'),
            _workOrderAssetLabel(row),
          ].join(' ').toLowerCase().contains(query);
        })
        .toList(growable: false);
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
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'MaintenanceWorkOrderRegisterController',
    );
    if (!Get.isRegistered<MaintenanceWorkOrderRegisterController>(
      tag: _controllerTag,
    )) {
      Get.put(MaintenanceWorkOrderRegisterController(), tag: _controllerTag);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MaintenanceWorkOrderRegisterController>(
      tag: _controllerTag,
      builder: (controller) {
        return PurchaseRegisterPage<MaintenanceWorkOrderModel>(
          title: 'Work orders',
          embedded: widget.embedded,
          loading: controller.loading,
          errorMessage: controller.error,
          onRetry: controller.load,
          emptyMessage: 'No work orders found.',
          actions: [
            AdaptiveShellActionButton(
              onPressed: () => _openMaintenanceShellRoute(
                context,
                '/maintenance/work-orders/new',
              ),
              icon: Icons.add_outlined,
              label: 'New work order',
            ),
          ],
          filters: _MaintFilters(
            searchController: controller.searchController,
            searchHint: 'Search WO no., asset, type, status',
            companyBanner: controller.companyBanner,
          ),
          rows: controller.filteredRows,
          columns: [
            PurchaseRegisterColumn<MaintenanceWorkOrderModel>(
              label: 'WO no.',
              valueBuilder: (row) => _workOrderNoLabel(row),
            ),
            PurchaseRegisterColumn<MaintenanceWorkOrderModel>(
              label: 'Date',
              valueBuilder: (row) => displayDate(
                nullableStringValue(row.toJson(), 'work_order_date'),
              ),
            ),
            PurchaseRegisterColumn<MaintenanceWorkOrderModel>(
              label: 'Asset',
              flex: 2,
              valueBuilder: (row) => _workOrderAssetLabel(row),
            ),
            PurchaseRegisterColumn<MaintenanceWorkOrderModel>(
              label: 'Status',
              valueBuilder: (row) =>
                  stringValue(row.toJson(), 'work_order_status'),
            ),
          ],
          onRowTap: (row) {
            final id = intValue(row.toJson(), 'id');
            if (id == null) {
              return;
            }
            _openMaintenanceShellRoute(context, '/maintenance/work-orders/$id');
          },
        );
      },
    );
  }
}
