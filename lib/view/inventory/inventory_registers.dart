import '../../screen.dart';
import '../../view_model/inventory/inventory_module_refresh_controller.dart';

typedef InventoryRegisterLoader<T> =
    Future<PaginatedResponse<T>> Function(InventoryService service);
typedef InventoryRegisterMatcher<T> = bool Function(T row, String query);

void _openInventoryShellRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

class InventoryRegisterController<T> extends GetxController {
  InventoryRegisterController({required this.loader, required this.matches});

  final InventoryRegisterLoader<T> loader;
  final InventoryRegisterMatcher<T> matches;
  final InventoryService _service = InventoryService();
  final InventoryModuleRefreshController _refreshController =
      InventoryModuleRefreshController.ensureRegistered();
  final TextEditingController searchController = TextEditingController();

  bool loading = true;
  String? error;
  List<T> rows = <T>[];
  Worker? _refreshWorker;

  List<T> get filteredRows {
    final query = searchController.text.trim().toLowerCase();
    return rows
        .where((row) => query.isEmpty || matches(row, query))
        .toList(growable: false);
  }

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(update);
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
    super.onClose();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    update();
    try {
      final response = await loader(_service);
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

class _RegisterFilters extends StatelessWidget {
  const _RegisterFilters({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFormTextField(
          labelText: 'Search',
          controller: searchController,
          hintText: searchHint,
        ),
        if (statusItems.isNotEmpty) ...[
          const SizedBox(height: AppUiConstants.spacingMd),
          AppDropdownField<String>.fromMapped(
            labelText: 'Status',
            mappedItems: statusItems,
            initialValue: status.isEmpty ? null : status,
            onChanged: onStatusChanged,
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
              onPressed: () =>
                  _openInventoryShellRoute(context, widget.newRoute),
              icon: Icons.add_outlined,
              label: widget.newLabel,
            ),
          ],
          filters: _RegisterFilters(
            searchController: controller.searchController,
            searchHint: widget.searchHint,
            status: '',
            statusItems: const <AppDropdownItem<String>>[],
            onStatusChanged: (_) {},
          ),
          rows: controller.filteredRows,
          columns: widget.columns,
          onRowTap: (row) =>
              _openInventoryShellRoute(context, widget.rowRoute(row)),
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
      loader: (service) => service.openingStocks(
        filters: const {'per_page': 200, 'sort_by': 'opening_date'},
      ),
      matches: (row, query) {
        final data = row.toJson();
        return [
          stringValue(data, 'opening_no'),
          stringValue(data, 'opening_status'),
          stringValue(data, 'remarks'),
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No opening stock documents found.',
      newRoute: '/inventory/opening-stocks/new',
      newLabel: 'New Opening Stock',
      searchHint: 'Search opening stock',
      columns: [
        PurchaseRegisterColumn<OpeningStockModel>(
          label: 'No',
          valueBuilder: (row) => stringValue(row.toJson(), 'opening_no'),
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
      loader: (service) => service.stockIssues(
        filters: const {'per_page': 200, 'sort_by': 'issue_date'},
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
      newLabel: 'New Stock Issue',
      searchHint: 'Search issues',
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
      loader: (service) => service.internalStockReceipts(
        filters: const {'per_page': 200, 'sort_by': 'receipt_date'},
      ),
      matches: (row, query) {
        final data = row.toJson();
        return [
          stringValue(data, 'receipt_no'),
          stringValue(data, 'receipt_status'),
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No internal receipts found.',
      newRoute: '/inventory/internal-stock-receipts/new',
      newLabel: 'New Internal Receipt',
      searchHint: 'Search receipts',
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
      loader: (service) => service.stockTransfers(
        filters: const {'per_page': 200, 'sort_by': 'transfer_date'},
      ),
      matches: (row, query) {
        final data = row.toJson();
        return [
          stringValue(data, 'transfer_no'),
          stringValue(data, 'transfer_status'),
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No stock transfers found.',
      newRoute: '/inventory/stock-transfers/new',
      newLabel: 'New Stock Transfer',
      searchHint: 'Search transfers',
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

class StockDamageRegisterPage extends StatelessWidget {
  const StockDamageRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return _InventoryRegisterShell<StockDamageEntryModel>(
      controllerName: 'StockDamageRegisterController',
      title: 'Stock damage',
      embedded: embedded,
      loader: (service) => service.stockDamageEntries(
        filters: const {'per_page': 200, 'sort_by': 'damage_date'},
      ),
      matches: (row, query) {
        final data = row.toJson();
        return [
          stringValue(data, 'damage_no'),
          stringValue(data, 'damage_status'),
          stringValue(data, 'damage_type'),
        ].join(' ').toLowerCase().contains(query);
      },
      emptyMessage: 'No stock damage entries found.',
      newRoute: '/inventory/stock-damage/new',
      newLabel: 'New Stock Damage',
      searchHint: 'Search damage entries',
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
      loader: (service) => service.inventoryAdjustments(
        filters: const {'per_page': 200, 'sort_by': 'adjustment_date'},
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
          valueBuilder: (row) => stringValue(row.toJson(), 'qty'),
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
          valueBuilder: (row) => stringValue(row.toJson(), 'balance_qty'),
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
