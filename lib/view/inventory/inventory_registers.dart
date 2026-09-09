import '../../screen.dart';
import '../../model/inventory/opening_stock_item_model.dart';
import '../../view_model/inventory/inventory_module_refresh_controller.dart';

typedef InventoryRegisterLoader<T> =
    Future<PaginatedResponse<T>> Function(
      InventoryService service,
      Map<String, dynamic> filters,
    );
typedef InventoryRegisterMatcher<T> = bool Function(T row, String query);
typedef InventoryRegisterValueGetter<T> = String? Function(T row);
typedef InventoryRegisterValuesGetter<T> = List<String> Function(T row);
typedef InventoryRegisterDropdownLoader =
    Future<List<AppDropdownItem<String>>> Function(InventoryService service);
typedef InventoryRegisterFilterOptionsLoader =
    Future<InventoryRegisterFilterOptions> Function();
typedef InventoryRegisterFooterBuilder<T> =
    Widget? Function(
      BuildContext context,
      InventoryRegisterController<T> controller,
      int currentPage,
    );

class InventoryRegisterFilterOptions {
  const InventoryRegisterFilterOptions({
    this.customerItems = const <AppDropdownItem<int>>[],
    this.supplierItems = const <AppDropdownItem<int>>[],
    this.itemItems = const <AppDropdownItem<int>>[],
    this.typeItems = const <AppDropdownItem<String>>[],
  });

  final List<AppDropdownItem<int>> customerItems;
  final List<AppDropdownItem<int>> supplierItems;
  final List<AppDropdownItem<int>> itemItems;
  final List<AppDropdownItem<String>> typeItems;
}

const List<AppDropdownItem<String>> _stockMovementTypeFilterItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'opening', label: 'Opening'),
      AppDropdownItem(value: 'purchase_receipt', label: 'Purchase receipt'),
      AppDropdownItem(value: 'purchase_return', label: 'Purchase return'),
      AppDropdownItem(value: 'sales_delivery', label: 'Sales / delivery'),
      AppDropdownItem(value: 'sales_return', label: 'Sales return'),
      AppDropdownItem(value: 'stock_transfer_in', label: 'Transfer in'),
      AppDropdownItem(value: 'stock_transfer_out', label: 'Transfer out'),
      AppDropdownItem(value: 'stock_adjustment_in', label: 'Adjustment in'),
      AppDropdownItem(value: 'stock_adjustment_out', label: 'Adjustment out'),
      AppDropdownItem(value: 'production_issue', label: 'Production issue'),
      AppDropdownItem(value: 'production_receipt', label: 'Production receipt'),
      AppDropdownItem(value: 'jobwork_issue', label: 'Jobwork issue'),
      AppDropdownItem(value: 'jobwork_receipt', label: 'Jobwork receipt'),
      AppDropdownItem(value: 'damage', label: 'Damage'),
      AppDropdownItem(value: 'expiry', label: 'Expiry'),
      AppDropdownItem(value: 'sample_issue', label: 'Sample issue'),
      AppDropdownItem(value: 'sample_receipt', label: 'Sample receipt'),
      AppDropdownItem(value: 'internal_issue', label: 'Internal issue'),
      AppDropdownItem(value: 'internal_receipt', label: 'Internal receipt'),
    ];

Future<InventoryRegisterFilterOptions> _loadStockMovementFilterOptions() async {
  await MasterDataCache.to.ensureLoaded();
  final cache = MasterDataCache.to;
  final customers = salesCustomers(
    parties: cache.activeParties,
    partyTypes: cache.activePartyTypes,
  );
  final suppliers = purchaseSuppliers(
    parties: cache.activeParties,
    partyTypes: cache.activePartyTypes,
  );

  List<AppDropdownItem<int>> partyItems(List<PartyModel> parties) => parties
      .where((party) => party.id != null)
      .map(
        (party) =>
            AppDropdownItem<int>(value: party.id!, label: party.toString()),
      )
      .toList(growable: false);

  return InventoryRegisterFilterOptions(
    customerItems: partyItems(customers),
    supplierItems: partyItems(suppliers),
    itemItems: cache.activeItems
        .where((item) => item.id != null)
        .map(
          (item) => AppDropdownItem<int>(
            value: item.id!,
            label: JsonModel.combineValues(
              <dynamic>[
                item.itemName,
                if (item.itemCode.trim().isNotEmpty) '(${item.itemCode})',
              ],
              separator: ' ',
              defaultValue: 'Item',
            ),
          ),
        )
        .toList(growable: false),
    typeItems: _stockMovementTypeFilterItems,
  );
}

Future<InventoryRegisterFilterOptions> _loadStockBalanceFilterOptions() async {
  await MasterDataCache.to.ensureLoaded();
  return InventoryRegisterFilterOptions(
    itemItems: _inventoryItemFilterItems(MasterDataCache.to.activeItems),
  );
}

List<AppDropdownItem<int>> _inventoryItemFilterItems(List<ItemModel> source) =>
    source
        .where((item) => item.id != null)
        .map(
          (item) => AppDropdownItem<int>(
            value: item.id!,
            label: JsonModel.combineValues(
              <dynamic>[
                item.itemName,
                if (item.itemCode.trim().isNotEmpty) '(${item.itemCode})',
              ],
              separator: ' ',
              defaultValue: 'Item',
            ),
          ),
        )
        .toList(growable: false);

Future<InventoryRegisterFilterOptions>
_loadDefaultInventoryFilterOptions() async {
  await MasterDataCache.to.ensureLoaded();
  return InventoryRegisterFilterOptions(
    itemItems: _inventoryItemFilterItems(MasterDataCache.to.activeItems),
  );
}

List<AppDropdownItem<String>> _inventoryStatusItems(List<String> values) =>
    values
        .map(
          (value) => AppDropdownItem<String>(
            value: value,
            label: value.replaceAll('_', ' ').titleCase,
          ),
        )
        .toList(growable: false);

String _openingStockProductSummary(OpeningStockModel row) {
  final seen = <String>{};
  final values = <String>[];
  for (final line in row.items ?? const <OpeningStockItemModel>[]) {
    final label = JsonModel.combineValues(
      <dynamic>[
        line.itemName,
        if ((line.itemCode ?? '').trim().isNotEmpty) '(${line.itemCode})',
      ],
      separator: ' ',
      defaultValue: '',
    ).trim();
    final normalized = label.toLowerCase();
    if (label.isEmpty || !seen.add(normalized)) {
      continue;
    }
    values.add(label);
  }
  return values.join(', ');
}

String _openingStockSearchText(OpeningStockModel row) {
  final values = <String>[
    stringValue(row.toJson(), 'opening_no'),
    stringValue(row.toJson(), 'opening_status'),
    stringValue(row.toJson(), 'remarks'),
    _openingStockProductSummary(row),
  ];
  for (final line in row.items ?? const <OpeningStockItemModel>[]) {
    values.addAll(<String>[
      line.itemCode ?? '',
      line.itemName ?? '',
      line.categoryCode ?? '',
      line.categoryName ?? '',
    ]);
  }
  return values.join(' ').toLowerCase();
}

List<String> _openingStockCategoryValues(OpeningStockModel row) {
  final seen = <String>{};
  final values = <String>[];
  for (final line in row.items ?? const <OpeningStockItemModel>[]) {
    final value = (line.categoryName ?? '').trim();
    final normalized = value.toLowerCase();
    if (value.isEmpty || !seen.add(normalized)) {
      continue;
    }
    values.add(value);
  }
  return values;
}

Future<PaginatedResponse<OpeningStockModel>> _loadOpeningStocksWithItems(
  InventoryService service,
  Map<String, dynamic> filters,
) {
  return service.openingStocks(
    filters:
        <String, dynamic>{
            ...filters,
            'sort_by': 'opening_date',
            if (filters['status'] != null) 'opening_status': filters['status'],
            if (filters['statuses'] != null)
              'opening_statuses': filters['statuses'],
          }
          ..remove('status')
          ..remove('statuses'),
  );
}

Future<PaginatedResponse<T>>
_loadEnrichedInventoryRegister<T extends JsonModel>({
  required Future<PaginatedResponse<T>> Function() listLoader,
}) => listLoader();

List<String> _genericCategoryValues<T extends JsonModel>(T row) {
  final seen = <String>{};
  final values = <String>[];
  final rawItems = row.toJson()['items'];
  if (rawItems is List) {
    for (final item in rawItems) {
      if (item is Map) {
        final value = stringValue(
          item as Map<String, dynamic>,
          'category_name',
        ).trim();
        final normalized = value.toLowerCase();
        if (value.isNotEmpty && seen.add(normalized)) {
          values.add(value);
        }
      }
    }
  }
  return values;
}

String _inventoryProductSummary<T extends JsonModel>(T row) {
  final rawItems = row.toJson()['items'];
  if (rawItems is! List) {
    return '';
  }
  final labels = <String>[];
  for (final rawItem in rawItems) {
    if (rawItem is! Map) {
      continue;
    }
    final item = rawItem.cast<String, dynamic>();
    final name = stringValue(item, 'item_name').trim();
    final code = stringValue(item, 'item_code').trim();
    final label = [
      if (name.isNotEmpty) name,
      if (code.isNotEmpty && code != name) '($code)',
    ].join(' ');
    if (label.isNotEmpty && !labels.contains(label)) {
      labels.add(label);
    }
  }
  if (labels.length <= 2) {
    return labels.join(', ');
  }
  return '${labels.take(2).join(', ')} +${labels.length - 2} more';
}

String _inventoryMovementProductLabel(StockMovementModel row) {
  final name = (row.itemName ?? '').trim();
  final code = (row.itemCode ?? '').trim();
  return [
    if (name.isNotEmpty) name,
    if (code.isNotEmpty && code != name) '($code)',
  ].join(' ');
}

String _inventoryWarehouseLabel<T extends JsonModel>(T row) {
  final data = row.toJson();
  return stringValue(
    data,
    'warehouse_name',
    stringValue(data, 'warehouse_code', stringValue(data, 'warehouse_id')),
  );
}

String _inventoryTransferWarehouseLabel<T extends JsonModel>(
  T row,
  String nameKey,
  String codeKey,
  String idKey,
) {
  final data = row.toJson();
  return stringValue(
    data,
    nameKey,
    stringValue(data, codeKey, stringValue(data, idKey)),
  );
}

String _inventoryQuantitySummary<T extends JsonModel>(T row, String key) {
  final rawItems = row.toJson()['items'];
  if (rawItems is! List) {
    return '';
  }
  var total = 0.0;
  var hasQuantity = false;
  for (final rawItem in rawItems) {
    if (rawItem is! Map) {
      continue;
    }
    final value = JsonModel.nullableDouble(
      rawItem.cast<String, dynamic>()[key],
    );
    if (value != null) {
      total += value;
      hasQuantity = true;
    }
  }
  if (!hasQuantity) {
    return '';
  }
  return total == total.roundToDouble()
      ? total.toInt().toString()
      : total.toStringAsFixed(2);
}

String _inventoryLineWarehouseSummary<T extends JsonModel>(T row) {
  final rawItems = row.toJson()['items'];
  if (rawItems is! List) {
    return '';
  }
  final labels = <String>[];
  for (final rawItem in rawItems) {
    if (rawItem is! Map) {
      continue;
    }
    final item = rawItem.cast<String, dynamic>();
    final label = stringValue(
      item,
      'warehouse_name',
      stringValue(item, 'warehouse_code', stringValue(item, 'warehouse_id')),
    );
    if (label.isNotEmpty && !labels.contains(label)) {
      labels.add(label);
    }
  }
  return labels.join(', ');
}

Future<List<AppDropdownItem<String>>> _loadOpeningStockCategoryItems(
  InventoryService service,
) async {
  final response = await service.itemCategories(
    filters: const {'per_page': 500, 'sort_by': 'category_name'},
  );
  final rows = response.data ?? const <ItemCategoryModel>[];
  return <AppDropdownItem<String>>[
    const AppDropdownItem<String>(value: '', label: 'All'),
    ...rows
        .where((row) => row.isActive && row.categoryName.trim().isNotEmpty)
        .map(
          (row) => AppDropdownItem<String>(
            value: row.categoryName.trim().toLowerCase(),
            label: row.categoryName.trim(),
          ),
        ),
  ];
}

void _openInventoryShellRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

class InventoryRegisterController<T> extends GetxController {
  InventoryRegisterController({
    required this.loader,
    required this.matches,
    this.statusValue,
    this.statusFilterItems,
    this.dateValue,
    this.categoryValues,
    this.categoryItemsLoader,
    this.filterOptionsLoader,
    this.initialDashboardFilter,
    this.onDashboardFilter,
  });

  final String? initialDashboardFilter;
  final void Function(InventoryRegisterController<T> controller, String filter)?
  onDashboardFilter;

  final InventoryRegisterLoader<T> loader;
  final InventoryRegisterMatcher<T> matches;
  final InventoryRegisterValueGetter<T>? statusValue;
  final List<AppDropdownItem<String>>? statusFilterItems;
  final InventoryRegisterValueGetter<T>? dateValue;
  final InventoryRegisterValuesGetter<T>? categoryValues;
  final InventoryRegisterDropdownLoader? categoryItemsLoader;
  final InventoryRegisterFilterOptionsLoader? filterOptionsLoader;
  final InventoryService _service = InventoryService();
  final InventoryModuleRefreshController _refreshController =
      InventoryModuleRefreshController.ensureRegistered();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();

  bool loading = true;
  String? error;
  List<T> rows = <T>[];
  Set<String> statuses = <String>{};
  Set<String> categories = <String>{};
  Set<int> customerIds = <int>{};
  Set<int> supplierIds = <int>{};
  Set<int> itemIds = <int>{};
  Set<String> movementTypes = <String>{};
  InventoryRegisterFilterOptions filterOptions =
      const InventoryRegisterFilterOptions();
  List<AppDropdownItem<String>> loadedCategoryItems =
      const <AppDropdownItem<String>>[];
  Worker? _refreshWorker;
  PaginationMeta? pagination;
  Timer? _filterDebounce;
  int _loadSequence = 0;
  bool _categoryItemsRequested = false;
  bool _filterOptionsRequested = false;
  String dashboardFilter = '';

  List<T> get filteredRows => rows;

  List<AppDropdownItem<String>> get statusItems {
    if (statusFilterItems != null) {
      return statusFilterItems!;
    }
    if (statusValue == null) {
      return const <AppDropdownItem<String>>[];
    }
    final seen = <String>{};
    final items = <AppDropdownItem<String>>[
      const AppDropdownItem<String>(value: '', label: 'All'),
    ];
    for (final row in rows) {
      final value = (statusValue?.call(row) ?? '').trim();
      if (value.isEmpty) {
        continue;
      }
      final normalized = value.toLowerCase();
      if (!seen.add(normalized)) {
        continue;
      }
      items.add(
        AppDropdownItem<String>(
          value: normalized,
          label: value.replaceAll('_', ' ').titleCase,
        ),
      );
    }
    return items;
  }

  List<AppDropdownItem<String>> get categoryItems {
    if (loadedCategoryItems.isNotEmpty) {
      return loadedCategoryItems;
    }
    if (categoryValues == null) {
      return const <AppDropdownItem<String>>[];
    }
    final seen = <String>{};
    final items = <AppDropdownItem<String>>[
      const AppDropdownItem<String>(value: '', label: 'All'),
    ];
    for (final row in rows) {
      for (final raw in categoryValues?.call(row) ?? const <String>[]) {
        final value = raw.trim();
        if (value.isEmpty) {
          continue;
        }
        final normalized = value.toLowerCase();
        if (!seen.add(normalized)) {
          continue;
        }
        items.add(AppDropdownItem<String>(value: normalized, label: value));
      }
    }
    return items;
  }

  bool get supportsDateFilter => dateValue != null;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_scheduleReload);
    dateFromController.addListener(_scheduleReload);
    dateToController.addListener(_scheduleReload);
    _refreshWorker = ever<InventoryModuleRefreshEvent?>(
      _refreshController.lastEvent,
      (event) {
        if (event == null) {
          return;
        }
        unawaited(load());
      },
    );
    unawaited(_loadCategoryItemsOnce());
    unawaited(_loadFilterOptionsOnce());
    if (initialDashboardFilter != null &&
        initialDashboardFilter!.isNotEmpty &&
        onDashboardFilter != null) {
      dashboardFilter = initialDashboardFilter!;
      onDashboardFilter!(this, initialDashboardFilter!);
      _filterDebounce?.cancel();
    }
    unawaited(load());
  }

  void applyDashboardFilter(String filter) {
    if (onDashboardFilter != null) {
      dashboardFilter = filter.trim();
      onDashboardFilter!(this, filter);
      _filterDebounce?.cancel();
      unawaited(load(page: 1));
    }
  }

  @override
  void onClose() {
    _refreshWorker?.dispose();
    _filterDebounce?.cancel();
    searchController
      ..removeListener(_scheduleReload)
      ..dispose();
    dateFromController
      ..removeListener(_scheduleReload)
      ..dispose();
    dateToController
      ..removeListener(_scheduleReload)
      ..dispose();
    super.onClose();
  }

  void setStatuses(Set<String> values) {
    statuses = values
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();
    update();
    _scheduleReload();
  }

  void setCategories(Set<String> values) {
    categories = values
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();
    update();
    _scheduleReload();
  }

  void setCustomerIds(Set<int> values) {
    customerIds = Set<int>.from(values);
    update();
    _scheduleReload();
  }

  void setSupplierIds(Set<int> values) {
    supplierIds = Set<int>.from(values);
    update();
    _scheduleReload();
  }

  void setItemIds(Set<int> values) {
    itemIds = Set<int>.from(values);
    update();
    _scheduleReload();
  }

  void setMovementTypes(Set<String> values) {
    movementTypes = values
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();
    update();
    _scheduleReload();
  }

  void clearFilters() {
    searchController.clear();
    dateFromController.clear();
    dateToController.clear();
    statuses = <String>{};
    categories = <String>{};
    customerIds = <int>{};
    supplierIds = <int>{};
    itemIds = <int>{};
    movementTypes = <String>{};
    update();
    unawaited(load(page: 1));
  }

  void _scheduleReload() {
    _filterDebounce?.cancel();
    _filterDebounce = Timer(
      const Duration(milliseconds: 450),
      () => unawaited(load(page: 1)),
    );
  }

  void goToPage(int page) {
    if (page >= 1 && page != pagination?.currentPage) {
      unawaited(load(page: page));
    }
  }

  Future<void> load({int page = 1}) async {
    _filterDebounce?.cancel();
    final loadSequence = ++_loadSequence;
    loading = true;
    error = null;
    update();
    try {
      final filters = <String, dynamic>{
        'page': page,
        'per_page': 50,
        'sort_order': 'desc',
        if (searchController.text.trim().isNotEmpty)
          'search': searchController.text.trim(),
        if (dateFromController.text.trim().isNotEmpty)
          'date_from': dateFromController.text.trim(),
        if (dateToController.text.trim().isNotEmpty)
          'date_to': dateToController.text.trim(),
        if (statuses.length == 1) 'status': statuses.single,
        if (statuses.length > 1) 'statuses': statuses.join(','),
        if (categories.isNotEmpty) 'categories': categories.join(','),
        if (customerIds.isNotEmpty) 'customer_ids': customerIds.join(','),
        if (supplierIds.isNotEmpty) 'supplier_ids': supplierIds.join(','),
        if (itemIds.isNotEmpty) 'item_ids': itemIds.join(','),
        if (movementTypes.isNotEmpty) 'movement_types': movementTypes.join(','),
        if (dashboardFilter.isNotEmpty) 'dashboard_filter': dashboardFilter,
      };
      final response = await loader(_service, filters);
      if (loadSequence != _loadSequence) {
        return;
      }
      rows = response.data ?? <T>[];
      pagination = response.meta;
      loading = false;
      update();
    } catch (err) {
      if (loadSequence != _loadSequence) {
        return;
      }
      error = err.toString();
      loading = false;
      update();
    }
  }

  Future<void> _loadCategoryItemsOnce() async {
    if (categoryItemsLoader == null || _categoryItemsRequested) {
      return;
    }
    _categoryItemsRequested = true;
    try {
      loadedCategoryItems = await categoryItemsLoader!(_service);
      update();
    } catch (_) {
      // Category lookup is optional; list loading and other filters still work.
    }
  }

  Future<void> _loadFilterOptionsOnce() async {
    if (_filterOptionsRequested) {
      return;
    }
    _filterOptionsRequested = true;
    try {
      filterOptions = filterOptionsLoader == null
          ? await _loadDefaultInventoryFilterOptions()
          : await filterOptionsLoader!();
      update();
    } catch (_) {
      // Optional filter lookups must not prevent the register from loading.
    }
  }
}

class _InventoryRegisterShell<T> extends StatefulWidget {
  const _InventoryRegisterShell({
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
    this.showNewAction = true,
    this.statusValue,
    this.statusFilterItems,
    this.dateValue,
    this.categoryValues,
    this.categoryItemsLoader,
    this.filterOptionsLoader,
    this.footerBuilder,
    this.queryParameters = const <String, String>{},
    this.onDashboardFilter,
  });

  final String controllerName;
  final String title;
  final bool embedded;
  final InventoryRegisterLoader<T> loader;
  final InventoryRegisterMatcher<T> matches;
  final String emptyMessage;
  final String newRoute;
  final String newLabel;
  final String searchHint;
  final List<PurchaseRegisterColumn<T>> columns;
  final String Function(T row) rowRoute;
  final bool showNewAction;
  final InventoryRegisterValueGetter<T>? statusValue;
  final List<AppDropdownItem<String>>? statusFilterItems;
  final InventoryRegisterValueGetter<T>? dateValue;
  final InventoryRegisterValuesGetter<T>? categoryValues;
  final InventoryRegisterDropdownLoader? categoryItemsLoader;
  final InventoryRegisterFilterOptionsLoader? filterOptionsLoader;
  final InventoryRegisterFooterBuilder<T>? footerBuilder;
  final Map<String, String> queryParameters;
  final void Function(
    InventoryRegisterController<T> controller,
    String dashboardFilter,
  )?
  onDashboardFilter;

  @override
  State<_InventoryRegisterShell<T>> createState() =>
      _InventoryRegisterShellState<T>();
}

class _InventoryRegisterShellState<T>
    extends State<_InventoryRegisterShell<T>> {
  late final String _controllerTag;
  bool _filtersVisible = false;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(widget.controllerName);
    bool isNew = false;
    if (!Get.isRegistered<InventoryRegisterController<T>>(
      tag: _controllerTag,
    )) {
      Get.put(
        InventoryRegisterController<T>(
          loader: widget.loader,
          matches: widget.matches,
          statusValue: widget.statusValue,
          statusFilterItems: widget.statusFilterItems,
          dateValue: widget.dateValue,
          categoryValues: widget.categoryValues,
          categoryItemsLoader: widget.categoryItemsLoader,
          filterOptionsLoader: widget.filterOptionsLoader,
          initialDashboardFilter:
              (widget.queryParameters['dashboard_filter'] ?? '').trim(),
          onDashboardFilter: widget.onDashboardFilter,
        ),
        tag: _controllerTag,
      );
      isNew = true;
    }
    if (!isNew) {
      _applyDashboardFilter();
    }
  }

  void _applyDashboardFilter() {
    if (!mounted ||
        !Get.isRegistered<InventoryRegisterController<T>>(
          tag: _controllerTag,
        )) {
      return;
    }
    final dashboardFilter = (widget.queryParameters['dashboard_filter'] ?? '')
        .trim();
    final controller = Get.find<InventoryRegisterController<T>>(
      tag: _controllerTag,
    );
    controller.applyDashboardFilter(dashboardFilter);
  }

  @override
  void didUpdateWidget(covariant _InventoryRegisterShell<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.queryParameters, widget.queryParameters)) {
      _applyDashboardFilter();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<InventoryRegisterController<T>>(
      tag: _controllerTag,
      builder: (controller) {
        return SharedRegisterList<T>(
          title: widget.title,
          embedded: widget.embedded,
          loading: controller.loading,
          errorMessage: controller.error,
          onRetry: controller.load,
          emptyMessage: widget.emptyMessage,
          actions: [
            AdaptiveShellSearchField(
              controller: controller.searchController,
              hintText: widget.searchHint,
            ),
            AdaptiveShellActionButton(
              onPressed: () {
                setState(() {
                  _filtersVisible = !_filtersVisible;
                });
              },
              icon: Icons.filter_alt_outlined,
              label: 'Filter',
              filled: _filtersVisible,
            ),
            if (widget.showNewAction)
              AdaptiveShellActionButton(
                onPressed: () =>
                    _openInventoryShellRoute(context, widget.newRoute),
                icon: Icons.add_outlined,
                label: widget.newLabel,
              ),
          ],
          filters: _filtersVisible
              ? SharedFilterBar(
                  dateFromController: controller.supportsDateFilter
                      ? controller.dateFromController
                      : null,
                  dateToController: controller.supportsDateFilter
                      ? controller.dateToController
                      : null,
                  showDateFilters: controller.supportsDateFilter,
                  statusItems: controller.statusItems,
                  selectedStatuses: controller.statuses,
                  onStatusesChanged: controller.setStatuses,
                  categoryItems: controller.categoryItems,
                  selectedCategories: controller.categories,
                  onCategoriesChanged: controller.setCategories,
                  partyLabel: 'Customer',
                  partyItems: controller.filterOptions.customerItems,
                  selectedPartyIds: controller.customerIds,
                  onPartyChanged: controller.setCustomerIds,
                  secondaryPartyLabel: 'Supplier',
                  secondaryPartyItems: controller.filterOptions.supplierItems,
                  selectedSecondaryPartyIds: controller.supplierIds,
                  onSecondaryPartyChanged: controller.setSupplierIds,
                  itemItems: controller.filterOptions.itemItems,
                  selectedItemIds: controller.itemIds,
                  onItemsChanged: controller.setItemIds,
                  typeItems: controller.filterOptions.typeItems,
                  selectedTypes: controller.movementTypes,
                  onTypesChanged: controller.setMovementTypes,
                  suggestions: controller.filterOptions.typeItems.isEmpty
                      ? const <AppRegisterFilterSuggestion>[]
                      : <AppRegisterFilterSuggestion>[
                          AppRegisterFilterSuggestion(
                            label: 'Customer movements',
                            onSelected: () => controller.setMovementTypes(
                              <String>{'sales_delivery', 'sales_return'},
                            ),
                          ),
                          AppRegisterFilterSuggestion(
                            label: 'Supplier movements',
                            onSelected: () =>
                                controller.setMovementTypes(<String>{
                                  'purchase_receipt',
                                  'purchase_return',
                                  'jobwork_issue',
                                  'jobwork_receipt',
                                }),
                          ),
                          AppRegisterFilterSuggestion(
                            label: 'Transfers',
                            onSelected: () =>
                                controller.setMovementTypes(<String>{
                                  'stock_transfer_in',
                                  'stock_transfer_out',
                                }),
                          ),
                        ],
                  onClear: controller.clearFilters,
                )
              : null,
          rows: controller.filteredRows,
          columns: widget.columns,
          onRowTap: (row) =>
              _openInventoryShellRoute(context, widget.rowRoute(row)),
          remoteTotalItems: controller.pagination?.total,
          remoteCurrentPage: controller.pagination?.currentPage,
          remotePerPage: controller.pagination?.perPage,
          onRemotePageChanged: controller.goToPage,
          footerBuilder: (context, currentPage) =>
              widget.footerBuilder?.call(context, controller, currentPage),
        );
      },
    );
  }
}

class OpeningStockRegisterPage extends StatelessWidget {
  const OpeningStockRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _InventoryRegisterShell<OpeningStockModel>(
      controllerName: 'OpeningStockRegisterController',
      title: 'Opening stock',
      embedded: embedded,
      loader: _loadOpeningStocksWithItems,
      matches: (row, query) {
        return _openingStockSearchText(row).contains(query);
      },
      emptyMessage: 'No opening stock documents found.',
      newRoute: '/inventory/opening-stocks/new',
      newLabel: 'New Opening Stock',
      searchHint: 'Search opening stock, product, category',
      statusValue: (row) => stringValue(row.toJson(), 'opening_status'),
      statusFilterItems: _inventoryStatusItems(const [
        'draft',
        'posted',
        'cancelled',
      ]),
      dateValue: (row) => nullableStringValue(row.toJson(), 'opening_date'),
      categoryValues: _openingStockCategoryValues,
      categoryItemsLoader: _loadOpeningStockCategoryItems,
      columns: [
        PurchaseRegisterColumn<OpeningStockModel>(
          label: 'No',
          valueBuilder: (row) => stringValue(row.toJson(), 'opening_no'),
        ),
        PurchaseRegisterColumn<OpeningStockModel>(
          label: 'Product',
          flex: 4,
          valueBuilder: _openingStockProductSummary,
        ),
        PurchaseRegisterColumn<OpeningStockModel>(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'opening_date')),
        ),
        PurchaseRegisterColumn<OpeningStockModel>(
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'opening_status'),
          widgetBuilder: (context, row) => purchaseStatusBadge(
            context,
            stringValue(row.toJson(), 'opening_status'),
          ),
        ),
      ],
      rowRoute: (row) =>
          '/inventory/opening-stocks/${intValue(row.toJson(), 'id')}',
    );
  }
}

class StockBalanceRegisterPage extends StatelessWidget {
  const StockBalanceRegisterPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  @override
  Widget build(BuildContext context) {
    return _InventoryRegisterShell<StockBalanceModel>(
      controllerName: 'StockBalanceRegisterController',
      title: 'Stock balances',
      embedded: embedded,
      queryParameters: queryParameters,
      onDashboardFilter: (controller, filter) {
        controller.setMovementTypes({});
        controller.setItemIds(
          {
            if (queryParameters['item_id'] != null)
              int.tryParse(queryParameters['item_id']!) ?? -1,
          }..remove(-1),
        );
      },
      loader: (service, filters) => service.stockBalances(
        filters:
            <String, dynamic>{
              ...filters,
              'sort_by': 'qty_available',
              if (filters['date_from'] != null)
                'last_movement_from': filters['date_from'],
              if (filters['date_to'] != null)
                'last_movement_to': filters['date_to'],
              if (filters['dashboard_filter'] == 'low_stock') 'low_stock': 1,
              if (queryParameters['item_id'] != null)
                'item_id': queryParameters['item_id'],
              if (queryParameters['warehouse_id'] != null)
                'warehouse_id': queryParameters['warehouse_id'],
            }..removeWhere(
              (key, value) =>
                  key == 'date_from' ||
                  key == 'date_to' ||
                  key == 'dashboard_filter' ||
                  key == 'movement_types' ||
                  key == 'customer_ids' ||
                  key == 'supplier_ids',
            ),
      ),
      matches: (row, query) => [
        row.itemCode,
        row.itemName,
        row.categoryCode ?? '',
        row.categoryName ?? '',
        row.warehouseCode ?? '',
        row.warehouseName ?? '',
        row.batchNo ?? '',
        row.serialNo ?? '',
      ].join(' ').toLowerCase().contains(query),
      emptyMessage: 'No stock balance records found.',
      newRoute: '/inventory/stock-balances',
      newLabel: 'Stock Balances',
      showNewAction: false,
      searchHint: 'Search item, warehouse, batch, or serial',
      categoryValues: (row) => [
        if ((row.categoryName ?? '').trim().isNotEmpty) row.categoryName!,
      ],
      filterOptionsLoader: _loadStockBalanceFilterOptions,
      columns: [
        PurchaseRegisterColumn<StockBalanceModel>(
          label: 'Product',
          flex: 3,
          valueBuilder: (row) => JsonModel.combineValues(
            <dynamic>[
              row.itemName,
              if (row.itemCode.trim().isNotEmpty) '(${row.itemCode})',
            ],
            separator: ' ',
            defaultValue: row.itemCode,
          ),
        ),
        PurchaseRegisterColumn<StockBalanceModel>(
          label: 'Warehouse',
          flex: 2,
          valueBuilder: (row) => row.warehouseName ?? row.warehouseCode ?? '',
        ),
        PurchaseRegisterColumn<StockBalanceModel>(
          label: 'Batch',
          valueBuilder: (row) => row.batchNo ?? '',
        ),
        PurchaseRegisterColumn<StockBalanceModel>(
          label: 'Serial',
          valueBuilder: (row) => row.serialNo ?? '',
        ),
        PurchaseRegisterColumn<StockBalanceModel>(
          label: 'On Hand',
          valueBuilder: (row) => formatQuantity(row.qtyOnHand ?? 0),
        ),
        PurchaseRegisterColumn<StockBalanceModel>(
          label: 'Reserved',
          valueBuilder: (row) => formatQuantity(row.qtyReserved ?? 0),
        ),
        PurchaseRegisterColumn<StockBalanceModel>(
          label: 'Available',
          valueBuilder: (row) => formatQuantity(row.qtyAvailable ?? 0),
        ),
      ],
      rowRoute: (_) => '/inventory/stock-balances',
    );
  }
}

class StockIssueRegisterPage extends StatelessWidget {
  const StockIssueRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _InventoryRegisterShell<StockIssueModel>(
      controllerName: 'StockIssueRegisterController',
      title: 'Stock issues',
      embedded: embedded,
      loader: (service, filters) =>
          _loadEnrichedInventoryRegister<StockIssueModel>(
            listLoader: () => service.stockIssues(
              filters:
                  <String, dynamic>{
                      ...filters,
                      'sort_by': 'issue_date',
                      if (filters['status'] != null)
                        'issue_status': filters['status'],
                      if (filters['statuses'] != null)
                        'issue_statuses': filters['statuses'],
                    }
                    ..remove('status')
                    ..remove('statuses'),
            ),
          ),
      matches: (row, query) {
        final data = row.toJson();
        return [
          stringValue(data, 'issue_no'),
          stringValue(data, 'issue_status'),
          stringValue(data, 'issue_purpose'),
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No stock issues found.',
      newRoute: '/inventory/stock-issues/new',
      newLabel: 'New Issue',
      searchHint: 'Search issues',
      statusValue: (row) => stringValue(row.toJson(), 'issue_status'),
      statusFilterItems: _inventoryStatusItems(const [
        'draft',
        'posted',
        'cancelled',
      ]),
      dateValue: (row) => nullableStringValue(row.toJson(), 'issue_date'),
      categoryItemsLoader: _loadOpeningStockCategoryItems,
      categoryValues: _genericCategoryValues,
      columns: [
        PurchaseRegisterColumn<StockIssueModel>(
          label: 'No',
          valueBuilder: (row) => stringValue(row.toJson(), 'issue_no'),
        ),
        PurchaseRegisterColumn<StockIssueModel>(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'issue_date')),
        ),
        PurchaseRegisterColumn<StockIssueModel>(
          label: 'Product',
          valueBuilder: _inventoryProductSummary,
        ),
        PurchaseRegisterColumn<StockIssueModel>(
          label: 'Warehouse',
          valueBuilder: _inventoryWarehouseLabel,
        ),
        PurchaseRegisterColumn<StockIssueModel>(
          label: 'Qty',
          valueBuilder: (row) => _inventoryQuantitySummary(row, 'issue_qty'),
        ),
        PurchaseRegisterColumn<StockIssueModel>(
          label: 'Purpose',
          valueBuilder: (row) => stringValue(row.toJson(), 'issue_purpose'),
        ),
        PurchaseRegisterColumn<StockIssueModel>(
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'issue_status'),
          widgetBuilder: (context, row) => purchaseStatusBadge(
            context,
            stringValue(row.toJson(), 'issue_status'),
          ),
        ),
      ],
      rowRoute: (row) =>
          '/inventory/stock-issues/${intValue(row.toJson(), 'id')}',
    );
  }
}

class InternalStockReceiptRegisterPage extends StatelessWidget {
  const InternalStockReceiptRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _InventoryRegisterShell<InternalStockReceiptModel>(
      controllerName: 'InternalStockReceiptRegisterController',
      title: 'Internal stock receipts',
      embedded: embedded,
      loader: (service, filters) =>
          _loadEnrichedInventoryRegister<InternalStockReceiptModel>(
            listLoader: () => service.internalStockReceipts(
              filters:
                  <String, dynamic>{
                      ...filters,
                      'sort_by': 'receipt_date',
                      if (filters['status'] != null)
                        'receipt_status': filters['status'],
                      if (filters['statuses'] != null)
                        'receipt_statuses': filters['statuses'],
                    }
                    ..remove('status')
                    ..remove('statuses'),
            ),
          ),
      matches: (row, query) {
        final data = row.toJson();
        return [
          stringValue(data, 'receipt_no'),
          stringValue(data, 'receipt_status'),
          stringValue(data, 'receipt_source'),
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No internal stock receipts found.',
      newRoute: '/inventory/internal-stock-receipts/new',
      newLabel: 'New Receipt',
      searchHint: 'Search receipts',
      statusValue: (row) => stringValue(row.toJson(), 'receipt_status'),
      statusFilterItems: _inventoryStatusItems(const [
        'draft',
        'posted',
        'cancelled',
      ]),
      dateValue: (row) => nullableStringValue(row.toJson(), 'receipt_date'),
      categoryItemsLoader: _loadOpeningStockCategoryItems,
      categoryValues: _genericCategoryValues,
      columns: [
        PurchaseRegisterColumn<InternalStockReceiptModel>(
          label: 'No',
          valueBuilder: (row) => stringValue(row.toJson(), 'receipt_no'),
        ),
        PurchaseRegisterColumn<InternalStockReceiptModel>(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'receipt_date')),
        ),
        PurchaseRegisterColumn<InternalStockReceiptModel>(
          label: 'Product',
          valueBuilder: _inventoryProductSummary,
        ),
        PurchaseRegisterColumn<InternalStockReceiptModel>(
          label: 'Warehouse',
          valueBuilder: _inventoryWarehouseLabel,
        ),
        PurchaseRegisterColumn<InternalStockReceiptModel>(
          label: 'Qty',
          valueBuilder: (row) => _inventoryQuantitySummary(row, 'receipt_qty'),
        ),
        PurchaseRegisterColumn<InternalStockReceiptModel>(
          label: 'Source',
          valueBuilder: (row) => stringValue(row.toJson(), 'receipt_source'),
        ),
        PurchaseRegisterColumn<InternalStockReceiptModel>(
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'receipt_status'),
          widgetBuilder: (context, row) => purchaseStatusBadge(
            context,
            stringValue(row.toJson(), 'receipt_status'),
          ),
        ),
      ],
      rowRoute: (row) =>
          '/inventory/internal-stock-receipts/${intValue(row.toJson(), 'id')}',
    );
  }
}

class StockTransferRegisterPage extends StatelessWidget {
  const StockTransferRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _InventoryRegisterShell<StockTransferModel>(
      controllerName: 'StockTransferRegisterController',
      title: 'Stock transfers',
      embedded: embedded,
      loader: (service, filters) =>
          _loadEnrichedInventoryRegister<StockTransferModel>(
            listLoader: () => service.stockTransfers(
              filters:
                  <String, dynamic>{
                      ...filters,
                      'sort_by': 'transfer_date',
                      if (filters['status'] != null)
                        'transfer_status': filters['status'],
                      if (filters['statuses'] != null)
                        'transfer_statuses': filters['statuses'],
                    }
                    ..remove('status')
                    ..remove('statuses'),
            ),
          ),
      matches: (row, query) {
        final data = row.toJson();
        return [
          stringValue(data, 'transfer_no'),
          stringValue(data, 'transfer_status'),
          stringValue(data, 'remarks'),
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No stock transfers found.',
      newRoute: '/inventory/stock-transfers/new',
      newLabel: 'New Transfer',
      searchHint: 'Search transfers',
      statusValue: (row) => stringValue(row.toJson(), 'transfer_status'),
      statusFilterItems: _inventoryStatusItems(const [
        'draft',
        'posted',
        'received',
        'cancelled',
      ]),
      dateValue: (row) => nullableStringValue(row.toJson(), 'transfer_date'),
      categoryItemsLoader: _loadOpeningStockCategoryItems,
      categoryValues: _genericCategoryValues,
      columns: [
        PurchaseRegisterColumn<StockTransferModel>(
          label: 'No',
          valueBuilder: (row) => stringValue(row.toJson(), 'transfer_no'),
        ),
        PurchaseRegisterColumn<StockTransferModel>(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'transfer_date')),
        ),
        PurchaseRegisterColumn<StockTransferModel>(
          label: 'Product',
          valueBuilder: _inventoryProductSummary,
        ),
        PurchaseRegisterColumn<StockTransferModel>(
          label: 'From Warehouse',
          valueBuilder: (row) => _inventoryTransferWarehouseLabel(
            row,
            'from_warehouse_name',
            'from_warehouse_code',
            'from_warehouse_id',
          ),
        ),
        PurchaseRegisterColumn<StockTransferModel>(
          label: 'To Warehouse',
          valueBuilder: (row) => _inventoryTransferWarehouseLabel(
            row,
            'to_warehouse_name',
            'to_warehouse_code',
            'to_warehouse_id',
          ),
        ),
        PurchaseRegisterColumn<StockTransferModel>(
          label: 'Qty',
          valueBuilder: (row) => _inventoryQuantitySummary(row, 'transfer_qty'),
        ),
        PurchaseRegisterColumn<StockTransferModel>(
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'transfer_status'),
          widgetBuilder: (context, row) => purchaseStatusBadge(
            context,
            stringValue(row.toJson(), 'transfer_status'),
          ),
        ),
      ],
      rowRoute: (row) =>
          '/inventory/stock-transfers/${intValue(row.toJson(), 'id')}',
    );
  }
}

class ProduceTrackingRegisterPage extends StatelessWidget {
  const ProduceTrackingRegisterPage({
    super.key,
    this.embedded = false,
    this.routePrefix = '/inventory/produce-trackings',
  });

  final bool embedded;
  final String routePrefix;

  @override
  Widget build(BuildContext context) {
    return _InventoryRegisterShell<ProduceTrackingModel>(
      controllerName: 'ProduceTrackingRegisterController',
      title: 'Produce Tracking',
      embedded: embedded,
      loader: (service, filters) => service.produceTrackings(
        filters:
            <String, dynamic>{
                ...filters,
                'sort_by': 'tracking_date',
                if (filters['status'] != null)
                  'tracking_status': filters['status'],
                if (filters['statuses'] != null)
                  'tracking_statuses': filters['statuses'],
              }
              ..remove('status')
              ..remove('statuses'),
      ),
      matches: (row, query) {
        final data = row.toJson();
        return [
          stringValue(data, 'tracking_no'),
          stringValue(data, 'tracking_status'),
          stringValue(data, 'reference_flow'),
          stringValue(data, 'reference_document_label'),
          stringValue(data, 'assigned_to_name'),
          stringValue(data, 'transporter_name'),
          stringValue(data, 'current_location'),
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No produce tracking records found.',
      newRoute: '$routePrefix/new',
      newLabel: 'New Produce Tracking',
      searchHint: 'Search produce tracking',
      statusValue: (row) => stringValue(row.toJson(), 'tracking_status'),
      statusFilterItems: _inventoryStatusItems(const [
        'draft',
        'ready_to_dispatch',
        'dispatched',
        'in_transit',
        'reached_destination',
        'delivered',
        'returned',
        'cancelled',
      ]),
      dateValue: (row) => nullableStringValue(row.toJson(), 'tracking_date'),
      columns: [
        PurchaseRegisterColumn<ProduceTrackingModel>(
          label: 'No',
          valueBuilder: (row) => stringValue(row.toJson(), 'tracking_no'),
        ),
        PurchaseRegisterColumn<ProduceTrackingModel>(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'tracking_date')),
        ),
        PurchaseRegisterColumn<ProduceTrackingModel>(
          label: 'Based On',
          valueBuilder: (row) =>
              stringValue(row.toJson(), 'reference_document_label'),
        ),
        PurchaseRegisterColumn<ProduceTrackingModel>(
          label: 'Assigned To',
          valueBuilder: (row) => stringValue(row.toJson(), 'assigned_to_name'),
        ),
        PurchaseRegisterColumn<ProduceTrackingModel>(
          label: 'Transporter',
          flex: 2,
          valueBuilder: (row) => stringValue(row.toJson(), 'transporter_name'),
        ),
        PurchaseRegisterColumn<ProduceTrackingModel>(
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'tracking_status'),
          widgetBuilder: (context, row) => purchaseStatusBadge(
            context,
            stringValue(row.toJson(), 'tracking_status'),
          ),
        ),
      ],
      rowRoute: (row) => '$routePrefix/${intValue(row.toJson(), 'id')}',
    );
  }
}

class StockDamageRegisterPage extends StatelessWidget {
  const StockDamageRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _InventoryRegisterShell<StockDamageEntryModel>(
      controllerName: 'StockDamageRegisterController',
      title: 'Stock damage',
      embedded: embedded,
      loader: (service, filters) =>
          _loadEnrichedInventoryRegister<StockDamageEntryModel>(
            listLoader: () => service.stockDamageEntries(
              filters:
                  <String, dynamic>{
                      ...filters,
                      'sort_by': 'damage_date',
                      if (filters['status'] != null)
                        'damage_status': filters['status'],
                      if (filters['statuses'] != null)
                        'damage_statuses': filters['statuses'],
                    }
                    ..remove('status')
                    ..remove('statuses'),
            ),
          ),
      matches: (row, query) {
        final data = row.toJson();
        return [
          stringValue(data, 'damage_no'),
          stringValue(data, 'damage_status'),
          stringValue(data, 'damage_type'),
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No stock damages found.',
      newRoute: '/inventory/stock-damage/new',
      newLabel: 'New Damage',
      searchHint: 'Search damage entries',
      statusValue: (row) => stringValue(row.toJson(), 'damage_status'),
      statusFilterItems: _inventoryStatusItems(const [
        'draft',
        'posted',
        'cancelled',
      ]),
      dateValue: (row) => nullableStringValue(row.toJson(), 'damage_date'),
      categoryItemsLoader: _loadOpeningStockCategoryItems,
      categoryValues: _genericCategoryValues,
      columns: [
        PurchaseRegisterColumn<StockDamageEntryModel>(
          label: 'No',
          valueBuilder: (row) => stringValue(row.toJson(), 'damage_no'),
        ),
        PurchaseRegisterColumn<StockDamageEntryModel>(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'damage_date')),
        ),
        PurchaseRegisterColumn<StockDamageEntryModel>(
          label: 'Product',
          valueBuilder: _inventoryProductSummary,
        ),
        PurchaseRegisterColumn<StockDamageEntryModel>(
          label: 'Warehouse',
          valueBuilder: _inventoryWarehouseLabel,
        ),
        PurchaseRegisterColumn<StockDamageEntryModel>(
          label: 'Qty',
          valueBuilder: (row) => _inventoryQuantitySummary(row, 'damage_qty'),
        ),
        PurchaseRegisterColumn<StockDamageEntryModel>(
          label: 'Type',
          valueBuilder: (row) => stringValue(row.toJson(), 'damage_type'),
        ),
        PurchaseRegisterColumn<StockDamageEntryModel>(
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'damage_status'),
          widgetBuilder: (context, row) => purchaseStatusBadge(
            context,
            stringValue(row.toJson(), 'damage_status'),
          ),
        ),
      ],
      rowRoute: (row) =>
          '/inventory/stock-damage/${intValue(row.toJson(), 'id')}',
    );
  }
}

class InventoryAdjustmentRegisterPage extends StatelessWidget {
  const InventoryAdjustmentRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _InventoryRegisterShell<InventoryAdjustmentModel>(
      controllerName: 'InventoryAdjustmentRegisterController',
      title: 'Inventory adjustments',
      embedded: embedded,
      loader: (service, filters) =>
          _loadEnrichedInventoryRegister<InventoryAdjustmentModel>(
            listLoader: () => service.inventoryAdjustments(
              filters:
                  <String, dynamic>{
                      ...filters,
                      'sort_by': 'adjustment_date',
                      if (filters['status'] != null)
                        'adjustment_status': filters['status'],
                      if (filters['statuses'] != null)
                        'adjustment_statuses': filters['statuses'],
                    }
                    ..remove('status')
                    ..remove('statuses'),
            ),
          ),
      matches: (row, query) {
        final data = row.toJson();
        return [
          stringValue(data, 'adjustment_no'),
          stringValue(data, 'adjustment_status'),
          stringValue(data, 'adjustment_type'),
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No inventory adjustments found.',
      newRoute: '/inventory/adjustments/new',
      newLabel: 'New Adjustment',
      searchHint: 'Search adjustments',
      statusValue: (row) => stringValue(row.toJson(), 'adjustment_status'),
      statusFilterItems: _inventoryStatusItems(const [
        'draft',
        'posted',
        'cancelled',
      ]),
      dateValue: (row) => nullableStringValue(row.toJson(), 'adjustment_date'),
      categoryItemsLoader: _loadOpeningStockCategoryItems,
      categoryValues: _genericCategoryValues,
      columns: [
        PurchaseRegisterColumn<InventoryAdjustmentModel>(
          label: 'No',
          valueBuilder: (row) => stringValue(row.toJson(), 'adjustment_no'),
        ),
        PurchaseRegisterColumn<InventoryAdjustmentModel>(
          label: 'Date',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'adjustment_date')),
        ),
        PurchaseRegisterColumn<InventoryAdjustmentModel>(
          label: 'Product',
          valueBuilder: _inventoryProductSummary,
        ),
        PurchaseRegisterColumn<InventoryAdjustmentModel>(
          label: 'Warehouse',
          valueBuilder: _inventoryLineWarehouseSummary,
        ),
        PurchaseRegisterColumn<InventoryAdjustmentModel>(
          label: 'Qty',
          valueBuilder: (row) =>
              _inventoryQuantitySummary(row, 'adjustment_qty'),
        ),
        PurchaseRegisterColumn<InventoryAdjustmentModel>(
          label: 'Type',
          valueBuilder: (row) => stringValue(row.toJson(), 'adjustment_type'),
        ),
        PurchaseRegisterColumn<InventoryAdjustmentModel>(
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'adjustment_status'),
          widgetBuilder: (context, row) => purchaseStatusBadge(
            context,
            stringValue(row.toJson(), 'adjustment_status'),
          ),
        ),
      ],
      rowRoute: (row) =>
          '/inventory/adjustments/${intValue(row.toJson(), 'id')}',
    );
  }
}

class StockMovementRegisterPage extends StatelessWidget {
  const StockMovementRegisterPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const {},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  @override
  Widget build(BuildContext context) {
    return _InventoryRegisterShell<StockMovementModel>(
      controllerName: 'StockMovementRegisterController',
      title: 'Stock movements',
      embedded: embedded,
      queryParameters: queryParameters,
      onDashboardFilter: (controller, filter) {
        if (filter == 'stock_in') {
          controller.setMovementTypes({
            'purchase_receipt',
            'sales_return',
            'stock_transfer_in',
            'stock_adjustment_in',
            'production_receipt',
            'jobwork_receipt',
            'sample_receipt',
            'internal_receipt',
          });
        } else if (filter == 'stock_out') {
          controller.setMovementTypes({
            'purchase_return',
            'sales_delivery',
            'stock_transfer_out',
            'stock_adjustment_out',
            'production_issue',
            'jobwork_issue',
            'damage',
            'expiry',
            'sample_issue',
            'internal_issue',
          });
        } else {
          controller.setMovementTypes({});
        }
      },
      loader: (service, filters) => service.stockMovements(
        filters:
            <String, dynamic>{
                ...filters,
                'sort_by': 'movement_date',
                if (filters['date_from'] != null)
                  'voucher_from': filters['date_from'],
                if (filters['date_to'] != null)
                  'voucher_to': filters['date_to'],
              }
              ..remove('date_from')
              ..remove('date_to'),
      ),
      matches: (row, query) {
        final data = row.toJson();
        return [
          stringValue(data, 'movement_type'),
          stringValue(data, 'reference_no'),
          stringValue(data, 'reference_module'),
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No stock movements found.',
      newRoute: '/inventory/stock-movements/new',
      newLabel: 'New Stock Movement',
      searchHint: 'Search movements',
      dateValue: (row) => nullableStringValue(row.toJson(), 'movement_date'),
      filterOptionsLoader: _loadStockMovementFilterOptions,
      footerBuilder: (context, controller, currentPage) {
        final pageQtyIn = controller.rows.fold<double>(
          0,
          (sum, row) => sum + (row.qtyIn ?? 0),
        );
        final pageQtyOut = controller.rows.fold<double>(
          0,
          (sum, row) => sum + (row.qtyOut ?? 0),
        );
        return _StockMovementSummaryFooter(
          pageQtyIn: pageQtyIn,
          pageQtyOut: pageQtyOut,
          overallQtyIn: controller.pagination?.qtyInTotal ?? 0,
          overallQtyOut: controller.pagination?.qtyOutTotal ?? 0,
        );
      },
      columns: [
        PurchaseRegisterColumn<StockMovementModel>(
          label: 'Date',
          flex: 2,
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'movement_date')),
        ),
        PurchaseRegisterColumn<StockMovementModel>(
          label: 'Product',
          flex: 3,
          valueBuilder: _inventoryMovementProductLabel,
        ),
        PurchaseRegisterColumn<StockMovementModel>(
          label: 'Type',
          valueBuilder: (row) => stringValue(row.toJson(), 'movement_type'),
        ),
        PurchaseRegisterColumn<StockMovementModel>(
          label: 'Reference',
          flex: 3,
          valueBuilder: (row) => stringValue(row.toJson(), 'reference_no'),
        ),
        PurchaseRegisterColumn<StockMovementModel>(
          label: 'Party',
          flex: 3,
          valueBuilder: (row) => row.partyName ?? '',
        ),
        PurchaseRegisterColumn<StockMovementModel>(
          label: 'Qty',
          valueBuilder: (row) =>
              formatQuantity(doubleValue(row.toJson(), 'qty')),
        ),
      ],
      rowRoute: (row) =>
          '/inventory/stock-movements/${intValue(row.toJson(), 'id')}',
    );
  }
}

class _StockMovementSummaryFooter extends StatelessWidget {
  const _StockMovementSummaryFooter({
    required this.pageQtyIn,
    required this.pageQtyOut,
    required this.overallQtyIn,
    required this.overallQtyOut,
  });

  final double pageQtyIn;
  final double pageQtyOut;
  final double overallQtyIn;
  final double overallQtyOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    final pageNet = pageQtyIn - pageQtyOut;
    final overallNet = overallQtyIn - overallQtyOut;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppUiConstants.spacingSm,
        vertical: AppUiConstants.spacingXs,
      ),
      decoration: BoxDecoration(
        color: appTheme.subtleFill.withValues(alpha: 0.55),
        border: Border(
          top: BorderSide(color: theme.dividerColor),
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowHeight: 42,
                dataRowMinHeight: 42,
                dataRowMaxHeight: 48,
                columns: const <DataColumn>[
                  DataColumn(label: Text('')),
                  DataColumn(numeric: true, label: Text('Stock In')),
                  DataColumn(numeric: true, label: Text('Stock Out')),
                  DataColumn(numeric: true, label: Text('Net')),
                ],
                rows: <DataRow>[
                  DataRow(
                    cells: <DataCell>[
                      const DataCell(Text('Page total')),
                      DataCell(Text(formatQuantity(pageQtyIn))),
                      DataCell(Text(formatQuantity(pageQtyOut))),
                      DataCell(Text(formatQuantity(pageNet))),
                    ],
                  ),
                  DataRow(
                    cells: <DataCell>[
                      const DataCell(Text('Overall page total')),
                      DataCell(Text(formatQuantity(overallQtyIn))),
                      DataCell(Text(formatQuantity(overallQtyOut))),
                      DataCell(Text(formatQuantity(overallNet))),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class StockBatchRegisterPage extends StatelessWidget {
  const StockBatchRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _InventoryRegisterShell<StockBatchModel>(
      controllerName: 'StockBatchRegisterController',
      title: 'Stock batches',
      embedded: embedded,
      loader: (service, filters) => service.stockBatches(
        filters: <String, dynamic>{...filters, 'sort_by': 'batch_no'},
      ),
      matches: (row, query) {
        final data = row.toJson();
        return [
          stringValue(data, 'batch_no'),
          stringValue(data, 'item_code'),
          stringValue(data, 'item_name'),
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No stock batches found.',
      newRoute: '/inventory/stock-batches/new',
      newLabel: 'New Stock Batch',
      searchHint: 'Search batches',
      columns: [
        PurchaseRegisterColumn<StockBatchModel>(
          label: 'Batch',
          valueBuilder: (row) => stringValue(row.toJson(), 'batch_no'),
        ),
        PurchaseRegisterColumn<StockBatchModel>(
          label: 'Balance',
          valueBuilder: (row) =>
              formatQuantity(doubleValue(row.toJson(), 'balance_qty')),
        ),
        PurchaseRegisterColumn<StockBatchModel>(
          label: 'Expiry',
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'expiry_date')),
        ),
      ],
      rowRoute: (row) =>
          '/inventory/stock-batches/${intValue(row.toJson(), 'id')}',
    );
  }
}

class StockSerialRegisterPage extends StatelessWidget {
  const StockSerialRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _InventoryRegisterShell<StockSerialModel>(
      controllerName: 'StockSerialRegisterController',
      title: 'Stock serials',
      embedded: embedded,
      loader: (service, filters) => service.stockSerials(
        filters:
            <String, dynamic>{
                ...filters,
                'sort_by': 'serial_no',
                if (filters['status'] != null) 'status': filters['status'],
                if (filters['statuses'] != null)
                  'statuses': filters['statuses'],
                if (filters['date_from'] != null)
                  'inward_from': filters['date_from'],
                if (filters['date_to'] != null) 'inward_to': filters['date_to'],
              }
              ..remove('date_from')
              ..remove('date_to'),
      ),
      matches: (row, query) {
        final data = row.toJson();
        return [
          stringValue(data, 'serial_no'),
          stringValue(data, 'status'),
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No stock serials found.',
      newRoute: '/inventory/stock-serials/new',
      newLabel: 'New Stock Serial',
      searchHint: 'Search serials',
      statusValue: (row) => stringValue(row.toJson(), 'status'),
      columns: [
        PurchaseRegisterColumn<StockSerialModel>(
          label: 'Serial',
          valueBuilder: (row) => stringValue(row.toJson(), 'serial_no'),
        ),
        PurchaseRegisterColumn<StockSerialModel>(
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'status'),
          widgetBuilder: (context, row) =>
              purchaseStatusBadge(context, stringValue(row.toJson(), 'status')),
        ),
        PurchaseRegisterColumn<StockSerialModel>(
          label: 'Warehouse',
          valueBuilder: (row) => stringValue(row.toJson(), 'warehouse_id'),
        ),
      ],
      rowRoute: (row) =>
          '/inventory/stock-serials/${intValue(row.toJson(), 'id')}',
    );
  }
}
