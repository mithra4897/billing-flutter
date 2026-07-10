import '../../screen.dart';
import '../../model/inventory/opening_stock_item_model.dart';
import '../../view_model/inventory/inventory_module_refresh_controller.dart';

typedef InventoryRegisterLoader<T> =
    Future<PaginatedResponse<T>> Function(InventoryService service);
typedef InventoryRegisterMatcher<T> = bool Function(T row, String query);
typedef InventoryRegisterValueGetter<T> = String? Function(T row);
typedef InventoryRegisterValuesGetter<T> = List<String> Function(T row);
typedef InventoryRegisterDropdownLoader =
    Future<List<AppDropdownItem<String>>> Function(InventoryService service);

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
) async {
  final response = await service.openingStocks(
    filters: const {'per_page': 200, 'sort_by': 'opening_date'},
  );
  final rows = response.data ?? const <OpeningStockModel>[];
  if (rows.isEmpty) {
    return response;
  }

  final itemResponse = await service.items(
    filters: const {'per_page': 500, 'sort_by': 'item_name'},
  );
  final itemById = <int, ItemModel>{
    for (final item in itemResponse.data ?? const <ItemModel>[])
      if (item.id != null) item.id!: item,
  };

  final enriched = await Future.wait<OpeningStockModel>(
    rows.map((row) async {
      final id = intValue(row.toJson(), 'id');
      if (id == null) {
        return row;
      }
      try {
        final detail = await service.openingStock(id);
        final detailedRow = detail.data ?? row;
        return _enrichOpeningStockRowWithItemMaster(detailedRow, itemById);
      } catch (_) {
        return row;
      }
    }),
  );

  return PaginatedResponse<OpeningStockModel>(
    success: response.success,
    message: response.message,
    data: enriched,
    meta: response.meta,
    errors: response.errors,
  );
}

OpeningStockModel _enrichOpeningStockRowWithItemMaster(
  OpeningStockModel row,
  Map<int, ItemModel> itemById,
) {
  final rawItems = row.toJson()['items'];
  if (rawItems is! List) {
    return row;
  }

  final enrichedItems = rawItems
      .map((item) {
        if (item is! Map) {
          return item;
        }
        final map = Map<String, dynamic>.from(item);
        final itemId = intValue(map, 'item_id');
        final itemMaster = itemId == null ? null : itemById[itemId];
        if (itemMaster == null) {
          return map;
        }
        map['item_id'] ??= itemMaster.id;
        map['item_code'] ??= itemMaster.itemCode;
        map['item_name'] ??= itemMaster.itemName;
        map['category_code'] ??= itemMaster.categoryCode;
        map['category_name'] ??= itemMaster.categoryName;
        return map;
      })
      .toList(growable: false);

  return OpeningStockModel.fromJson(<String, dynamic>{
    ...row.toJson(),
    'items': enrichedItems,
  });
}

Future<PaginatedResponse<T>>
_loadEnrichedInventoryRegister<T extends JsonModel>({
  required InventoryService service,
  required Future<PaginatedResponse<T>> Function() listLoader,
  required Future<ApiResponse<T>> Function(int id) detailLoader,
  required T Function(Map<String, dynamic> json) fromJson,
}) async {
  final response = await listLoader();
  final rows = response.data ?? <T>[];
  if (rows.isEmpty) {
    return response;
  }

  final itemResponse = await service.items(
    filters: const {'per_page': 500, 'sort_by': 'item_name'},
  );
  final itemById = <int, ItemModel>{
    for (final item in itemResponse.data ?? const <ItemModel>[])
      if (item.id != null) item.id!: item,
  };

  final enriched = await Future.wait<T>(
    rows.map((row) async {
      final id = intValue(row.toJson(), 'id');
      if (id == null) {
        return row;
      }
      try {
        final detail = await detailLoader(id);
        final detailedRow = detail.data ?? row;

        final rawItems = detailedRow.toJson()['items'];
        if (rawItems is! List) {
          return detailedRow;
        }

        final enrichedItems = rawItems
            .map((item) {
              if (item is! Map) {
                return item;
              }
              final map = Map<String, dynamic>.from(item);
              final itemId = intValue(map, 'item_id');
              final itemMaster = itemId == null ? null : itemById[itemId];
              if (itemMaster == null) {
                return map;
              }
              map['item_id'] ??= itemMaster.id;
              map['item_code'] ??= itemMaster.itemCode;
              map['item_name'] ??= itemMaster.itemName;
              map['category_code'] ??= itemMaster.categoryCode;
              map['category_name'] ??= itemMaster.categoryName;
              return map;
            })
            .toList(growable: false);

        return fromJson(<String, dynamic>{
          ...detailedRow.toJson(),
          'items': enrichedItems,
        });
      } catch (_) {
        return row;
      }
    }),
  );

  return PaginatedResponse<T>(
    success: response.success,
    message: response.message,
    data: enriched,
    meta: response.meta,
    errors: response.errors,
  );
}

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
    this.dateValue,
    this.categoryValues,
    this.categoryItemsLoader,
  });

  final InventoryRegisterLoader<T> loader;
  final InventoryRegisterMatcher<T> matches;
  final InventoryRegisterValueGetter<T>? statusValue;
  final InventoryRegisterValueGetter<T>? dateValue;
  final InventoryRegisterValuesGetter<T>? categoryValues;
  final InventoryRegisterDropdownLoader? categoryItemsLoader;
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
  List<AppDropdownItem<String>> loadedCategoryItems =
      const <AppDropdownItem<String>>[];
  Worker? _refreshWorker;

  List<T> get filteredRows {
    final query = searchController.text.trim().toLowerCase();
    return rows
        .where((row) {
          if (query.isNotEmpty && !matches(row, query)) {
            return false;
          }
          if (statuses.isNotEmpty) {
            final rowStatus = (statusValue?.call(row) ?? '')
                .trim()
                .toLowerCase();
            if (!statuses.contains(rowStatus)) {
              return false;
            }
          }
          if (categories.isNotEmpty && categoryValues != null) {
            final rowCategories =
                (categoryValues?.call(row) ?? const <String>[])
                    .map((value) => value.trim().toLowerCase())
                    .where((value) => value.isNotEmpty)
                    .toSet();
            if (!rowCategories.any(categories.contains)) {
              return false;
            }
          }
          if (dateValue != null &&
              !matchesDateValueRange(
                dateValue!.call(row),
                fromValue: dateFromController.text,
                toValue: dateToController.text,
              )) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  List<AppDropdownItem<String>> get statusItems {
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
    searchController.addListener(update);
    dateFromController.addListener(update);
    dateToController.addListener(update);
    _refreshWorker = ever<InventoryModuleRefreshEvent?>(
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
    searchController
      ..removeListener(update)
      ..dispose();
    dateFromController
      ..removeListener(update)
      ..dispose();
    dateToController
      ..removeListener(update)
      ..dispose();
    super.onClose();
  }

  void setStatuses(Set<String> values) {
    statuses = values
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();
    update();
  }

  void setCategories(Set<String> values) {
    categories = values
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();
    update();
  }

  void clearFilters() {
    searchController.clear();
    dateFromController.clear();
    dateToController.clear();
    statuses = <String>{};
    categories = <String>{};
    update();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    update();
    try {
      final response = await loader(_service);
      rows = response.data ?? <T>[];
      if (categoryItemsLoader != null) {
        loadedCategoryItems = await categoryItemsLoader!(_service);
      }
      loading = false;
      update();
    } catch (err) {
      error = err.toString();
      loading = false;
      update();
    }
  }
}

class _RegisterFilters extends StatelessWidget {
  const _RegisterFilters({
    required this.searchController,
    required this.searchHint,
    this.dateFromController,
    this.dateToController,
    required this.statuses,
    required this.statusItems,
    required this.onStatusChanged,
    required this.categories,
    required this.categoryItems,
    required this.onCategoryChanged,
    this.showAdvancedFilters = true,
    this.onSearchSubmitted,
  });

  final TextEditingController searchController;
  final String searchHint;
  final TextEditingController? dateFromController;
  final TextEditingController? dateToController;
  final Set<String> statuses;
  final List<AppDropdownItem<String>> statusItems;
  final ValueChanged<Set<String>> onStatusChanged;
  final Set<String> categories;
  final List<AppDropdownItem<String>> categoryItems;
  final ValueChanged<Set<String>> onCategoryChanged;
  final bool showAdvancedFilters;
  final VoidCallback? onSearchSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFormTextField(
          labelText: 'Search',
          controller: searchController,
          hintText: searchHint,
          textInputAction: TextInputAction.search,
          onFieldSubmitted: (_) {
            onSearchSubmitted?.call();
          },
          onEditingComplete: onSearchSubmitted,
        ),
        if (showAdvancedFilters &&
            (dateFromController != null || dateToController != null)) ...[
          const SizedBox(height: AppUiConstants.spacingMd),
          Wrap(
            spacing: AppUiConstants.spacingMd,
            runSpacing: AppUiConstants.spacingMd,
            children: [
              if (dateFromController != null)
                SizedBox(
                  width: 220,
                  child: AppDateField(
                    labelText: 'From Date',
                    controller: dateFromController!,
                  ),
                ),
              if (dateToController != null)
                SizedBox(
                  width: 220,
                  child: AppDateField(
                    labelText: 'To Date',
                    controller: dateToController!,
                  ),
                ),
            ],
          ),
        ],
        if (showAdvancedFilters && statusItems.isNotEmpty) ...[
          const SizedBox(height: AppUiConstants.spacingMd),
          AppDropdownField<String>.fromMapped(
            labelText: 'Status',
            mappedItems: statusItems
                .where((item) => item.value.trim().isNotEmpty)
                .toList(growable: false),
            multiInitialValues: statuses,
            multiHintText: 'Select statuses',
            onMultiChanged: onStatusChanged,
          ),
        ],
        if (showAdvancedFilters && categoryItems.isNotEmpty) ...[
          const SizedBox(height: AppUiConstants.spacingMd),
          AppDropdownField<String>.fromMapped(
            labelText: 'Category',
            mappedItems: categoryItems
                .where((item) => item.value.trim().isNotEmpty)
                .toList(growable: false),
            multiInitialValues: categories,
            multiHintText: 'Select categories',
            onMultiChanged: onCategoryChanged,
          ),
        ],
      ],
    );
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
    this.statusValue,
    this.dateValue,
    this.categoryValues,
    this.categoryItemsLoader,
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
  final InventoryRegisterValueGetter<T>? statusValue;
  final InventoryRegisterValueGetter<T>? dateValue;
  final InventoryRegisterValuesGetter<T>? categoryValues;
  final InventoryRegisterDropdownLoader? categoryItemsLoader;

  @override
  State<_InventoryRegisterShell<T>> createState() =>
      _InventoryRegisterShellState<T>();
}

class _InventoryRegisterShellState<T>
    extends State<_InventoryRegisterShell<T>> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(widget.controllerName);
    if (!Get.isRegistered<InventoryRegisterController<T>>(
      tag: _controllerTag,
    )) {
      Get.put(
        InventoryRegisterController<T>(
          loader: widget.loader,
          matches: widget.matches,
          statusValue: widget.statusValue,
          dateValue: widget.dateValue,
          categoryValues: widget.categoryValues,
          categoryItemsLoader: widget.categoryItemsLoader,
        ),
        tag: _controllerTag,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<InventoryRegisterController<T>>(
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
              onPressed: () => _openFilterPanel(context, controller),
              icon: Icons.filter_alt_outlined,
              label: 'Filter',
              filled: false,
            ),
            AdaptiveShellActionButton(
              onPressed: () =>
                  _openInventoryShellRoute(context, widget.newRoute),
              icon: Icons.add_outlined,
              label: widget.newLabel,
            ),
          ],
          filters: _RegisterFilters(
            searchController: controller.searchController,
            searchHint: widget.searchHint,
            showAdvancedFilters: false,
            statuses: controller.statuses,
            statusItems: controller.statusItems,
            onStatusChanged: controller.setStatuses,
            categories: controller.categories,
            categoryItems: controller.categoryItems,
            onCategoryChanged: controller.setCategories,
          ),
          rows: controller.filteredRows,
          columns: widget.columns,
          onRowTap: (row) =>
              _openInventoryShellRoute(context, widget.rowRoute(row)),
        );
      },
    );
  }

  Future<void> _openFilterPanel(
    BuildContext context,
    InventoryRegisterController<T> controller,
  ) async {
    final dialogSearchController = TextEditingController(
      text: controller.searchController.text,
    );
    final dialogDateFromController = TextEditingController(
      text: controller.dateFromController.text,
    );
    final dialogDateToController = TextEditingController(
      text: controller.dateToController.text,
    );
    final tempStatuses = Set<String>.from(controller.statuses);
    final tempCategories = Set<String>.from(controller.categories);

    void applyDialogFilters(BuildContext dialogContext) {
      controller.searchController.text = dialogSearchController.text;
      controller.dateFromController.text = dialogDateFromController.text;
      controller.dateToController.text = dialogDateToController.text;
      controller.setStatuses(tempStatuses);
      controller.setCategories(tempCategories);
      Navigator.of(dialogContext).pop();
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final appTheme = Theme.of(
          dialogContext,
        ).extension<AppThemeExtension>()!;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.enter): () {
                  applyDialogFilters(dialogContext);
                },
                const SingleActivator(LogicalKeyboardKey.numpadEnter): () {
                  applyDialogFilters(dialogContext);
                },
              },
              child: Focus(
                autofocus: true,
                child: Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppUiConstants.cardRadius,
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        AppUiConstants.cardPadding,
                        AppUiConstants.cardPadding,
                        AppUiConstants.cardPadding,
                        MediaQuery.of(dialogContext).viewInsets.bottom +
                            AppUiConstants.cardPadding,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Filter ${widget.title}',
                                  style: Theme.of(dialogContext)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                tooltip: 'Close',
                                icon: const Icon(Icons.close),
                                color: appTheme.mutedText,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppUiConstants.spacingMd),
                          _RegisterFilters(
                            searchController: dialogSearchController,
                            searchHint: widget.searchHint,
                            dateFromController: controller.supportsDateFilter
                                ? dialogDateFromController
                                : null,
                            dateToController: controller.supportsDateFilter
                                ? dialogDateToController
                                : null,
                            statuses: tempStatuses,
                            statusItems: controller.statusItems,
                            onStatusChanged: (values) {
                              setDialogState(() {
                                tempStatuses
                                  ..clear()
                                  ..addAll(values);
                              });
                            },
                            categories: tempCategories,
                            categoryItems: controller.categoryItems,
                            onCategoryChanged: (values) {
                              setDialogState(() {
                                tempCategories
                                  ..clear()
                                  ..addAll(values);
                              });
                            },
                            onSearchSubmitted: () =>
                                applyDialogFilters(dialogContext),
                          ),
                          const SizedBox(height: AppUiConstants.spacingMd),
                          Wrap(
                            spacing: AppUiConstants.spacingMd,
                            runSpacing: AppUiConstants.spacingMd,
                            children: [
                              FilledButton.icon(
                                onPressed: () =>
                                    applyDialogFilters(dialogContext),
                                icon: const Icon(Icons.search),
                                label: const Text('Apply Filters'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () {
                                  controller.clearFilters();
                                  Navigator.of(dialogContext).pop();
                                },
                                icon: const Icon(Icons.clear),
                                label: const Text('Clear'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
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
        ),
      ],
      rowRoute: (row) =>
          '/inventory/opening-stocks/${intValue(row.toJson(), 'id')}',
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
      loader: (service) => _loadEnrichedInventoryRegister<StockIssueModel>(
        service: service,
        listLoader: () => service.stockIssues(
          filters: const {'per_page': 200, 'sort_by': 'issue_date'},
        ),
        detailLoader: service.stockIssue,
        fromJson: StockIssueModel.fromJson,
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
          label: 'Purpose',
          valueBuilder: (row) => stringValue(row.toJson(), 'issue_purpose'),
        ),
        PurchaseRegisterColumn<StockIssueModel>(
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'issue_status'),
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
      loader: (service) =>
          _loadEnrichedInventoryRegister<InternalStockReceiptModel>(
            service: service,
            listLoader: () => service.internalStockReceipts(
              filters: const {'per_page': 200, 'sort_by': 'receipt_date'},
            ),
            detailLoader: service.internalStockReceipt,
            fromJson: InternalStockReceiptModel.fromJson,
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
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'receipt_status'),
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
      loader: (service) => _loadEnrichedInventoryRegister<StockTransferModel>(
        service: service,
        listLoader: () => service.stockTransfers(
          filters: const {'per_page': 200, 'sort_by': 'transfer_date'},
        ),
        detailLoader: service.stockTransfer,
        fromJson: StockTransferModel.fromJson,
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
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'transfer_status'),
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
      loader: (service) => service.produceTrackings(
        filters: const {'per_page': 200, 'sort_by': 'tracking_date'},
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
      loader: (service) =>
          _loadEnrichedInventoryRegister<StockDamageEntryModel>(
            service: service,
            listLoader: () => service.stockDamageEntries(
              filters: const {'per_page': 200, 'sort_by': 'damage_date'},
            ),
            detailLoader: service.stockDamageEntry,
            fromJson: StockDamageEntryModel.fromJson,
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
          label: 'Type',
          valueBuilder: (row) => stringValue(row.toJson(), 'damage_type'),
        ),
        PurchaseRegisterColumn<StockDamageEntryModel>(
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'damage_status'),
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
      loader: (service) =>
          _loadEnrichedInventoryRegister<InventoryAdjustmentModel>(
            service: service,
            listLoader: () => service.inventoryAdjustments(
              filters: const {'per_page': 200, 'sort_by': 'adjustment_date'},
            ),
            detailLoader: service.inventoryAdjustment,
            fromJson: InventoryAdjustmentModel.fromJson,
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
          label: 'Type',
          valueBuilder: (row) => stringValue(row.toJson(), 'adjustment_type'),
        ),
        PurchaseRegisterColumn<InventoryAdjustmentModel>(
          label: 'Status',
          valueBuilder: (row) => stringValue(row.toJson(), 'adjustment_status'),
        ),
      ],
      rowRoute: (row) =>
          '/inventory/adjustments/${intValue(row.toJson(), 'id')}',
    );
  }
}

class StockMovementRegisterPage extends StatelessWidget {
  const StockMovementRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _InventoryRegisterShell<StockMovementModel>(
      controllerName: 'StockMovementRegisterController',
      title: 'Stock movements',
      embedded: embedded,
      loader: (service) => service.stockMovements(
        filters: const {'per_page': 200, 'sort_by': 'movement_date'},
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
      columns: [
        PurchaseRegisterColumn<StockMovementModel>(
          label: 'Date',
          flex: 2,
          valueBuilder: (row) =>
              displayDate(nullableStringValue(row.toJson(), 'movement_date')),
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

class StockBatchRegisterPage extends StatelessWidget {
  const StockBatchRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _InventoryRegisterShell<StockBatchModel>(
      controllerName: 'StockBatchRegisterController',
      title: 'Stock batches',
      embedded: embedded,
      loader: (service) => service.stockBatches(
        filters: const {'per_page': 200, 'sort_by': 'batch_no'},
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
      loader: (service) => service.stockSerials(
        filters: const {'per_page': 200, 'sort_by': 'serial_no'},
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
