import '../../screen.dart';

typedef ManufacturingRegisterLoader<T> =
    Future<ApiResponse<List<T>>> Function(
      ManufacturingService service,
      int? companyId,
    );
typedef ManufacturingRegisterMatcher<T> = bool Function(T row, String query);

void _openManufacturingShellRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

Map<String, dynamic>? _asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

String _outputItemLabel(Map<String, dynamic> data) {
  final item =
      _asJsonMap(data['outputItem']) ?? _asJsonMap(data['output_item']);
  if (item == null) {
    return '';
  }
  final code = stringValue(item, 'item_code');
  final name = stringValue(item, 'item_name');
  if (code.isEmpty) {
    return name;
  }
  if (name.isEmpty) {
    return code;
  }
  return '$code · $name';
}

String _productionOrderNo(Map<String, dynamic> data) {
  final po =
      _asJsonMap(data['productionOrder']) ??
      _asJsonMap(data['production_order']);
  if (po == null) {
    return '';
  }
  return stringValue(po, 'production_no');
}

class _MfgFilters extends StatelessWidget {
  const _MfgFilters({
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
                    'Session company: $companyBanner. Lists are filtered by '
                    'company when the API supports it.',
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
                    'to scope manufacturing lists.',
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

class ManufacturingRegisterController<T> extends GetxController {
  ManufacturingRegisterController({
    required this.loader,
    required this.matches,
  });

  final ManufacturingRegisterLoader<T> loader;
  final ManufacturingRegisterMatcher<T> matches;
  final ManufacturingService _service = ManufacturingService();
  final TextEditingController searchController = TextEditingController();

  bool loading = true;
  String? error;
  String? companyBanner;
  List<T> rows = <T>[];

  List<T> get filteredRows {
    final query = searchController.text.trim().toLowerCase();
    return rows
        .where((row) => query.isEmpty || matches(row, query))
        .toList(growable: false);
  }

  @override
  void onInit() {
    super.onInit();
    WorkingContextService.version.addListener(_onContextChanged);
    searchController.addListener(update);
    unawaited(load());
  }

  @override
  void onClose() {
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
      final response = await loader(_service, info.companyId);
      companyBanner = info.banner;
      rows = response.data ?? <T>[];
      loading = false;
      update();
    } catch (err) {
      error = err.toString();
      loading = false;
      update();
    }
  }
}

class _ManufacturingRegisterShell<T> extends StatefulWidget {
  const _ManufacturingRegisterShell({
    required this.controllerName,
    required this.title,
    required this.embedded,
    required this.loader,
    required this.matches,
    required this.emptyMessage,
    required this.newRoute,
    required this.newLabel,
    required this.searchHint,
    required this.columns,
    required this.rowRoute,
  });

  final String controllerName;
  final String title;
  final bool embedded;
  final ManufacturingRegisterLoader<T> loader;
  final ManufacturingRegisterMatcher<T> matches;
  final String emptyMessage;
  final String newRoute;
  final String newLabel;
  final String searchHint;
  final List<PurchaseRegisterColumn<T>> columns;
  final String Function(T row) rowRoute;

  @override
  State<_ManufacturingRegisterShell<T>> createState() =>
      _ManufacturingRegisterShellState<T>();
}

class _ManufacturingRegisterShellState<T>
    extends State<_ManufacturingRegisterShell<T>> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(widget.controllerName);
    if (!Get.isRegistered<ManufacturingRegisterController<T>>(
      tag: _controllerTag,
    )) {
      Get.put(
        ManufacturingRegisterController<T>(
          loader: widget.loader,
          matches: widget.matches,
        ),
        tag: _controllerTag,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ManufacturingRegisterController<T>>(
      tag: _controllerTag,
      builder: (controller) {
        return PurchaseRegisterPage<T>(
          title: widget.title,
          embedded: widget.embedded,
          loading: controller.loading,
          errorMessage: controller.error,
          onRetry: controller.load,
          emptyMessage: widget.emptyMessage,
          actions: [
            AdaptiveShellActionButton(
              onPressed: () =>
                  _openManufacturingShellRoute(context, widget.newRoute),
              icon: Icons.add_outlined,
              label: widget.newLabel,
            ),
          ],
          filters: _MfgFilters(
            searchController: controller.searchController,
            searchHint: widget.searchHint,
            companyBanner: controller.companyBanner,
          ),
          rows: controller.filteredRows,
          columns: widget.columns,
          onRowTap: (row) =>
              _openManufacturingShellRoute(context, widget.rowRoute(row)),
        );
      },
    );
  }
}

class BomRegisterPage extends StatelessWidget {
  const BomRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _ManufacturingRegisterShell<BomModel>(
      controllerName: 'BomRegisterController',
      title: 'Bills of material',
      embedded: embedded,
      loader: (service, companyId) {
        final filters = <String, dynamic>{'per_page': 200};
        if (companyId != null) {
          filters['company_id'] = companyId;
        }
        return service.boms(filters: filters);
      },
      matches: (row, query) {
        final data = row.toJson();
        return [
          stringValue(data, 'bom_code'),
          stringValue(data, 'bom_name'),
          stringValue(data, 'approval_status'),
          stringValue(data, 'version_no'),
          _outputItemLabel(data),
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No BOMs found.',
      newRoute: '/manufacturing/boms/new',
      newLabel: 'New BOM',
      searchHint: 'Search code, name, output item, status',
      columns: [
        PurchaseRegisterColumn<BomModel>(
          label: 'Code',
          valueBuilder: (row) => stringValue(row.toJson(), 'bom_code'),
        ),
        PurchaseRegisterColumn<BomModel>(
          label: 'Name',
          flex: 2,
          valueBuilder: (row) => stringValue(row.toJson(), 'bom_name'),
        ),
        PurchaseRegisterColumn<BomModel>(
          label: 'Output',
          flex: 2,
          valueBuilder: (row) => _outputItemLabel(row.toJson()),
        ),
        PurchaseRegisterColumn<BomModel>(
          label: 'Approval',
          valueBuilder: (row) => stringValue(row.toJson(), 'approval_status'),
        ),
      ],
      rowRoute: (row) => '/manufacturing/boms/${intValue(row.toJson(), 'id')}',
    );
  }
}

class ProductionOrderRegisterPage extends StatelessWidget {
  const ProductionOrderRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _ManufacturingRegisterShell<ProductionOrderModel>(
      controllerName: 'ProductionOrderRegisterController',
      title: 'Production orders',
      embedded: embedded,
      loader: (service, companyId) {
        final filters = <String, dynamic>{'per_page': 200};
        if (companyId != null) {
          filters['company_id'] = companyId;
        }
        return service.productionOrders(filters: filters);
      },
      matches: (row, query) {
        final data = row.toJson();
        return [
          stringValue(data, 'production_no'),
          stringValue(data, 'production_status'),
          _outputItemLabel(data),
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No production orders found.',
      newRoute: '/manufacturing/production-orders/new',
      newLabel: 'New production order',
      searchHint: 'Search document no., status, output item',
      columns: [
        PurchaseRegisterColumn<ProductionOrderModel>(
          label: 'No.',
          valueBuilder: (row) => stringValue(row.toJson(), 'production_no'),
        ),
        PurchaseRegisterColumn<ProductionOrderModel>(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'production_date')),
        ),
        PurchaseRegisterColumn<ProductionOrderModel>(
          label: 'Output',
          flex: 2,
          valueBuilder: (row) => _outputItemLabel(row.toJson()),
        ),
        PurchaseRegisterColumn<ProductionOrderModel>(
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'production_status'),
        ),
      ],
      rowRoute: (row) =>
          '/manufacturing/production-orders/${intValue(row.toJson(), 'id')}',
    );
  }
}

class ProductionMaterialIssueRegisterPage extends StatelessWidget {
  const ProductionMaterialIssueRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _ManufacturingRegisterShell<ProductionMaterialIssueModel>(
      controllerName: 'ProductionMaterialIssueRegisterController',
      title: 'Production material issues',
      embedded: embedded,
      loader: (service, companyId) {
        final filters = <String, dynamic>{'per_page': 200};
        if (companyId != null) {
          filters['company_id'] = companyId;
        }
        return service.productionMaterialIssues(filters: filters);
      },
      matches: (row, query) {
        final data = row.toJson();
        return [
          stringValue(data, 'issue_no'),
          stringValue(data, 'issue_status'),
          _productionOrderNo(data),
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No material issues found.',
      newRoute: '/manufacturing/production-material-issues/new',
      newLabel: 'New material issue',
      searchHint: 'Search issue no., status, production order',
      columns: [
        PurchaseRegisterColumn<ProductionMaterialIssueModel>(
          label: 'Issue no.',
          valueBuilder: (row) => stringValue(row.toJson(), 'issue_no'),
        ),
        PurchaseRegisterColumn<ProductionMaterialIssueModel>(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'issue_date')),
        ),
        PurchaseRegisterColumn<ProductionMaterialIssueModel>(
          label: 'Prod. order',
          flex: 2,
          valueBuilder: (row) => _productionOrderNo(row.toJson()),
        ),
        PurchaseRegisterColumn<ProductionMaterialIssueModel>(
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'issue_status'),
        ),
      ],
      rowRoute: (row) =>
          '/manufacturing/production-material-issues/${intValue(row.toJson(), 'id')}',
    );
  }
}

class ProductionReceiptRegisterPage extends StatelessWidget {
  const ProductionReceiptRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _ManufacturingRegisterShell<ProductionReceiptModel>(
      controllerName: 'ProductionReceiptRegisterController',
      title: 'Production receipts',
      embedded: embedded,
      loader: (service, companyId) {
        final filters = <String, dynamic>{'per_page': 200};
        if (companyId != null) {
          filters['company_id'] = companyId;
        }
        return service.productionReceipts(filters: filters);
      },
      matches: (row, query) {
        final data = row.toJson();
        return [
          stringValue(data, 'receipt_no'),
          stringValue(data, 'receipt_status'),
          _productionOrderNo(data),
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No production receipts found.',
      newRoute: '/manufacturing/production-receipts/new',
      newLabel: 'New production receipt',
      searchHint: 'Search receipt no., status, production order',
      columns: [
        PurchaseRegisterColumn<ProductionReceiptModel>(
          label: 'Receipt no.',
          valueBuilder: (row) => stringValue(row.toJson(), 'receipt_no'),
        ),
        PurchaseRegisterColumn<ProductionReceiptModel>(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'receipt_date')),
        ),
        PurchaseRegisterColumn<ProductionReceiptModel>(
          label: 'Prod. order',
          flex: 2,
          valueBuilder: (row) => _productionOrderNo(row.toJson()),
        ),
        PurchaseRegisterColumn<ProductionReceiptModel>(
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'receipt_status'),
        ),
      ],
      rowRoute: (row) =>
          '/manufacturing/production-receipts/${intValue(row.toJson(), 'id')}',
    );
  }
}
