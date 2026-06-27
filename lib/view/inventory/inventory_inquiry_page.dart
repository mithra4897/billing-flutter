import '../../controller/inventory/inventory_inquiry_management_controller.dart';
import '../../model/inventory/inventory_inquiry_model.dart';
import '../../screen.dart';

class InventoryInquiryPage extends StatefulWidget {
  const InventoryInquiryPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<InventoryInquiryPage> createState() => _InventoryInquiryPageState();
}

class _InventoryInquiryPageState extends State<InventoryInquiryPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'InventoryInquiryManagementController',
    );
    Get.put(InventoryInquiryManagementController(), tag: _controllerTag);
  }

  List<Widget> _shellActions(InventoryInquiryManagementController controller) {
    return <Widget>[
      AdaptiveShellActionButton(
        onPressed: controller.running ? null : controller.run,
        icon: Icons.play_arrow_outlined,
        label: 'Run Inquiry',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<InventoryInquiryManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final body = _buildBody(context, controller);
        if (widget.embedded) {
          return ShellPageActions(
            actions: _shellActions(controller),
            child: body,
          );
        }
        return AppStandaloneShell(
          title: 'Inventory Inquiry',
          scrollController: controller.pageScrollController,
          actions: _shellActions(controller),
          child: body,
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    InventoryInquiryManagementController controller,
  ) {
    if (controller.loadingLookups) {
      return const AppLoadingView(message: 'Loading inquiry data...');
    }
    if (controller.error != null && controller.items.isEmpty) {
      return AppErrorStateView(
        title: 'Unable to load inventory inquiry',
        message: controller.error!,
        onRetry: controller.bootstrap,
      );
    }

    final warehouseItems = <AppDropdownItem<int?>>[
      const AppDropdownItem<int?>(value: null, label: 'All warehouses'),
      ...controller.warehouses.map(
        (WarehouseModel warehouse) => AppDropdownItem<int?>(
          value: warehouse.id,
          label: warehouse.toString(),
        ),
      ),
    ];

    return SingleChildScrollView(
      controller: controller.pageScrollController,
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (controller.error != null) ...<Widget>[
            AppErrorStateView.inline(message: controller.error!),
            const SizedBox(height: AppUiConstants.spacingMd),
          ],
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Parameters',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppUiConstants.spacingSm),
                Text(
                  'Choose an inquiry, item, and optional company or warehouse '
                  'filters to inspect live stock data.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppUiConstants.spacingMd),
                Wrap(
                  spacing: AppUiConstants.spacingMd,
                  runSpacing: AppUiConstants.spacingMd,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    AppDropdownField<String>.fromMapped(
                      labelText: 'Inquiry',
                      mappedItems:
                          InventoryInquiryManagementController.inquiryModes,
                      initialValue: controller.mode,
                      width: 240,
                      onChanged: controller.setMode,
                    ),
                    AppSearchPickerField<int>(
                      labelText: 'Item',
                      selectedLabel: controller.selectedItem?.toString(),
                      options: controller.items
                          .where((ItemModel item) => item.id != null)
                          .map(
                            (ItemModel item) => AppSearchPickerOption<int>(
                              value: item.id!,
                              label: item.toString(),
                              subtitle: item.itemCode,
                              searchText: item.pickerSearchText,
                            ),
                          )
                          .toList(growable: false),
                      width: 340,
                      onChanged: controller.setItemId,
                    ),
                    if (controller.mode == 'batch' ||
                        controller.mode == 'serials')
                      AppDropdownField<int?>.fromMapped(
                        labelText: 'Warehouse',
                        mappedItems: warehouseItems,
                        initialValue: controller.warehouseId,
                        width: 240,
                        onChanged: controller.setWarehouseId,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingLg),
          _buildResultArea(context, controller),
        ],
      ),
    );
  }

  Widget _buildResultArea(
    BuildContext context,
    InventoryInquiryManagementController controller,
  ) {
    if (controller.running) {
      return const AppSectionCard(
        child: AppLoadingView(message: 'Running inquiry...'),
      );
    }

    if (!_hasResult(controller)) {
      return const AppSectionCard(
        child: SettingsEmptyState(
          icon: Icons.query_stats_outlined,
          title: 'Run Inventory Inquiry',
          message:
              'Choose an inquiry mode and item, then run the inquiry to inspect stock details.',
          minHeight: 220,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSelectionSummary(context, controller),
        const SizedBox(height: AppUiConstants.spacingLg),
        ..._buildModeSections(context, controller),
      ],
    );
  }

  Widget _buildSelectionSummary(
    BuildContext context,
    InventoryInquiryManagementController controller,
  ) {
    final item = controller.selectedItem;
    final company = controller.selectedCompany;
    return AppSectionCard(
      child: Wrap(
        spacing: AppUiConstants.spacingLg,
        runSpacing: AppUiConstants.spacingMd,
        children: <Widget>[
          _InquiryInfoBlock(
            label: 'Item',
            value: item == null
                ? '-'
                : '${item.itemCode.isEmpty ? item.itemName : item.itemCode} · ${item.itemName}',
          ),
          _InquiryInfoBlock(
            label: 'Company',
            value: company?.toString() ?? 'Default / all accessible',
          ),
          _InquiryInfoBlock(
            label: 'Mode',
            value:
                InventoryInquiryManagementController.inquiryModes
                    .cast<AppDropdownItem<String>?>()
                    .firstWhere(
                      (AppDropdownItem<String>? option) =>
                          option?.value == controller.mode,
                      orElse: () => null,
                    )
                    ?.label ??
                controller.mode,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildModeSections(
    BuildContext context,
    InventoryInquiryManagementController controller,
  ) {
    switch (controller.mode) {
      case 'summary':
        return <Widget>[
          _buildSummarySection(
            context,
            title: 'Stock Summary',
            data: controller.summaryResult,
          ),
        ];
      case 'warehouse':
        return <Widget>[_buildWarehouseSection(context, controller)];
      case 'batch':
        return <Widget>[_buildBatchSection(context, controller)];
      case 'serials':
        return <Widget>[_buildSerialSection(context, controller)];
      case 'card':
        return <Widget>[_buildStockCardSection(context, controller)];
      case 'reorder':
        return <Widget>[
          _buildReorderSection(context, controller.reorderResult),
        ];
      default:
        return <Widget>[
          _buildSummarySection(
            context,
            title: 'Inventory Inquiry',
            data: controller.summaryResult,
          ),
        ];
    }
  }

  Widget _buildWarehouseSection(
    BuildContext context,
    InventoryInquiryManagementController controller,
  ) {
    final rows = controller.warehouseRows
        .map(
          (row) => <String, dynamic>{
            'warehouse_name': row.warehouseName ?? '',
            'qty_on_hand': row.qtyOnHand,
            'qty_reserved': row.qtyReserved,
            'qty_available': row.qtyAvailable,
            'avg_cost': row.avgCost,
          },
        )
        .toList(growable: false);
    return _buildCollectionTableSection(
      context,
      title: 'Warehouse-wise Stock',
      rows: rows,
      columns: const <_InquiryTableColumn>[
        _InquiryTableColumn('Warehouse', 'warehouse_name'),
        _InquiryTableColumn('On Hand', 'qty_on_hand', numeric: true),
        _InquiryTableColumn('Reserved', 'qty_reserved', numeric: true),
        _InquiryTableColumn('Available', 'qty_available', numeric: true),
        _InquiryTableColumn('Avg Cost', 'avg_cost', numeric: true),
      ],
      emptyMessage: 'No warehouse-wise stock found for this item.',
    );
  }

  Widget _buildBatchSection(
    BuildContext context,
    InventoryInquiryManagementController controller,
  ) {
    final rows = controller.batchRows
        .map(
          (row) => <String, dynamic>{
            'batch_no': row.batchNo ?? '',
            'warehouse_name': row.warehouseName ?? '',
            'mfg_date': row.mfgDate,
            'expiry_date': row.expiryDate,
            'balance_qty': row.balanceQty,
            'is_expired': row.isExpired,
          },
        )
        .toList(growable: false);
    return _buildCollectionTableSection(
      context,
      title: 'Batch-wise Stock',
      rows: rows,
      columns: const <_InquiryTableColumn>[
        _InquiryTableColumn('Batch', 'batch_no'),
        _InquiryTableColumn('Warehouse', 'warehouse_name'),
        _InquiryTableColumn('Mfg Date', 'mfg_date', isDate: true),
        _InquiryTableColumn('Expiry', 'expiry_date', isDate: true),
        _InquiryTableColumn('Available', 'balance_qty', numeric: true),
        _InquiryTableColumn('Expired', 'is_expired', boolean: true),
      ],
      emptyMessage: 'No batches found for this item.',
    );
  }

  Widget _buildSerialSection(
    BuildContext context,
    InventoryInquiryManagementController controller,
  ) {
    final rows = controller.serialRows
        .map(
          (row) => <String, dynamic>{
            'serial_no': row.serialNo ?? '',
            'warehouse_name': row.warehouseName ?? '',
            'batch_no': row.batchNo ?? '',
            'status': row.status ?? '',
            'inward_date': row.inwardDate,
            'outward_date': row.outwardDate,
          },
        )
        .toList(growable: false);
    return _buildCollectionTableSection(
      context,
      title: 'Available Serials',
      rows: rows,
      columns: const <_InquiryTableColumn>[
        _InquiryTableColumn('Serial No', 'serial_no'),
        _InquiryTableColumn('Warehouse', 'warehouse_name'),
        _InquiryTableColumn('Batch', 'batch_no'),
        _InquiryTableColumn('Status', 'status'),
        _InquiryTableColumn('Inward', 'inward_date', isDate: true),
        _InquiryTableColumn('Outward', 'outward_date', isDate: true),
      ],
      emptyMessage: 'No available serials found for this item.',
    );
  }

  Widget _buildStockCardSection(
    BuildContext context,
    InventoryInquiryManagementController controller,
  ) {
    final card = controller.stockCardResult;
    final warehouseRows = card?.warehouseRows ?? controller.warehouseRows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildItemProfileSection(context, card?.item),
        const SizedBox(height: AppUiConstants.spacingLg),
        _buildSummarySection(
          context,
          title: 'Stock Summary',
          data: card?.summary,
        ),
        const SizedBox(height: AppUiConstants.spacingLg),
        _buildCollectionTableSection(
          context,
          title: 'Warehouse-wise Stock',
          rows: warehouseRows
              .map(
                (row) => <String, dynamic>{
                  'warehouse_name': row.warehouseName ?? '',
                  'qty_on_hand': row.qtyOnHand,
                  'qty_reserved': row.qtyReserved,
                  'qty_available': row.qtyAvailable,
                  'avg_cost': row.avgCost,
                },
              )
              .toList(growable: false),
          columns: const <_InquiryTableColumn>[
            _InquiryTableColumn('Warehouse', 'warehouse_name'),
            _InquiryTableColumn('On Hand', 'qty_on_hand', numeric: true),
            _InquiryTableColumn('Reserved', 'qty_reserved', numeric: true),
            _InquiryTableColumn('Available', 'qty_available', numeric: true),
            _InquiryTableColumn('Avg Cost', 'avg_cost', numeric: true),
          ],
          emptyMessage: 'No warehouse-wise stock found for this item.',
        ),
        if ((card?.batchRows ?? const <InventoryInquiryBatchRowModel>[])
            .isNotEmpty) ...<Widget>[
          const SizedBox(height: AppUiConstants.spacingLg),
          _buildCollectionTableSection(
            context,
            title: 'Batch-wise Stock',
            rows: card!.batchRows
                .map(
                  (row) => <String, dynamic>{
                    'batch_no': row.batchNo ?? '',
                    'warehouse_name': row.warehouseName ?? '',
                    'expiry_date': row.expiryDate,
                    'balance_qty': row.balanceQty,
                  },
                )
                .toList(growable: false),
            columns: const <_InquiryTableColumn>[
              _InquiryTableColumn('Batch', 'batch_no'),
              _InquiryTableColumn('Warehouse', 'warehouse_name'),
              _InquiryTableColumn('Expiry', 'expiry_date', isDate: true),
              _InquiryTableColumn('Available', 'balance_qty', numeric: true),
            ],
            emptyMessage: 'No batch balances found.',
          ),
        ],
        if ((card?.serialRows ?? const <InventoryInquirySerialRowModel>[])
            .isNotEmpty) ...<Widget>[
          const SizedBox(height: AppUiConstants.spacingLg),
          _buildCollectionTableSection(
            context,
            title: 'Available Serials',
            rows: card!.serialRows
                .map(
                  (row) => <String, dynamic>{
                    'serial_no': row.serialNo ?? '',
                    'warehouse_name': row.warehouseName ?? '',
                    'batch_no': row.batchNo ?? '',
                    'status': row.status ?? '',
                  },
                )
                .toList(growable: false),
            columns: const <_InquiryTableColumn>[
              _InquiryTableColumn('Serial No', 'serial_no'),
              _InquiryTableColumn('Warehouse', 'warehouse_name'),
              _InquiryTableColumn('Batch', 'batch_no'),
              _InquiryTableColumn('Status', 'status'),
            ],
            emptyMessage: 'No serials found.',
          ),
        ],
      ],
    );
  }

  Widget _buildItemProfileSection(BuildContext context, ItemModel? item) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Item Profile', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppUiConstants.spacingMd),
          Wrap(
            spacing: AppUiConstants.spacingLg,
            runSpacing: AppUiConstants.spacingMd,
            children: <Widget>[
              _InquiryInfoBlock(label: 'Code', value: item?.itemCode ?? '-'),
              _InquiryInfoBlock(label: 'Name', value: item?.itemName ?? '-'),
              _InquiryInfoBlock(
                label: 'Category',
                value: item?.categoryName ?? '-',
              ),
              _InquiryInfoBlock(label: 'Brand', value: item?.brandName ?? '-'),
              _InquiryInfoBlock(
                label: 'Base UOM',
                value: item?.baseUomName ?? '-',
              ),
              _InquiryInfoBlock(
                label: 'Track Inventory',
                value: _boolLabel(item?.trackInventory),
              ),
              _InquiryInfoBlock(
                label: 'Has Batch',
                value: _boolLabel(item?.hasBatch),
              ),
              _InquiryInfoBlock(
                label: 'Has Serial',
                value: _boolLabel(item?.hasSerial),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(
    BuildContext context, {
    required String title,
    required InventoryInquirySummaryModel? data,
  }) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppUiConstants.spacingMd),
          Wrap(
            spacing: AppUiConstants.spacingMd,
            runSpacing: AppUiConstants.spacingMd,
            children: <Widget>[
              _metricCard(context, 'On Hand', _number(data?.qtyOnHand)),
              _metricCard(context, 'Reserved', _number(data?.qtyReserved)),
              _metricCard(context, 'Available', _number(data?.qtyAvailable)),
              _metricCard(context, 'Avg Cost', _number(data?.avgCost)),
              _metricCard(
                context,
                'Last Purchase Rate',
                _number(data?.lastPurchaseRate),
              ),
              _metricCard(
                context,
                'Last Sales Rate',
                _number(data?.lastSalesRate),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReorderSection(
    BuildContext context,
    InventoryInquiryReorderStatusModel? data,
  ) {
    final belowReorder = data?.isBelowReorder ?? false;
    final belowMin = data?.isBelowMinStock ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Reorder Status',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Wrap(
                spacing: AppUiConstants.spacingMd,
                runSpacing: AppUiConstants.spacingMd,
                children: <Widget>[
                  _metricCard(
                    context,
                    'Available Qty',
                    _number(data?.availableQty),
                  ),
                  _metricCard(
                    context,
                    'Min Stock Level',
                    _number(data?.minStockLevel),
                  ),
                  _metricCard(
                    context,
                    'Reorder Level',
                    _number(data?.reorderLevel),
                  ),
                  _metricCard(
                    context,
                    'Reorder Qty',
                    _number(data?.reorderQty),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppUiConstants.spacingLg),
        AppSectionCard(
          child: Wrap(
            spacing: AppUiConstants.spacingMd,
            runSpacing: AppUiConstants.spacingMd,
            children: <Widget>[
              _statusChip(
                context,
                label: belowMin ? 'Below Min Stock' : 'Above Min Stock',
                active: belowMin,
              ),
              _statusChip(
                context,
                label: belowReorder ? 'Needs Reorder' : 'Stock Healthy',
                active: belowReorder,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionTableSection(
    BuildContext context, {
    required String title,
    required List<Map<String, dynamic>> rows,
    required List<_InquiryTableColumn> columns,
    required String emptyMessage,
  }) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppUiConstants.spacingMd),
          if (rows.isEmpty)
            Text(emptyMessage)
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: columns
                    .map((column) => DataColumn(label: Text(column.label)))
                    .toList(growable: false),
                rows: rows
                    .map((row) {
                      return DataRow(
                        cells: columns
                            .map(
                              (column) => DataCell(
                                Text(_displayCellValue(row, column)),
                              ),
                            )
                            .toList(growable: false),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _metricCard(BuildContext context, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(AppUiConstants.spacingMd),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(
    BuildContext context, {
    required String label,
    required bool active,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? scheme.errorContainer.withValues(alpha: 0.35)
            : scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? scheme.error : scheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _displayCellValue(
    Map<String, dynamic> row,
    _InquiryTableColumn column,
  ) {
    final value = row[column.path];
    if (column.boolean) {
      return _boolLabel(value);
    }
    if (column.isDate) {
      final text = value?.toString() ?? '';
      return text.isEmpty ? '-' : displayDate(text);
    }
    if (column.numeric) {
      return _number(value);
    }
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? '-' : text;
  }

  String _number(dynamic value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (number == null) {
      return '-';
    }
    if (number == number.roundToDouble()) {
      return number.round().toString();
    }
    return number.toStringAsFixed(2);
  }

  String _boolLabel(dynamic value) {
    return value == true || value == 1 || value?.toString() == '1'
        ? 'Yes'
        : 'No';
  }

  bool _hasResult(InventoryInquiryManagementController controller) {
    return controller.summaryResult != null ||
        controller.warehouseRows.isNotEmpty ||
        controller.batchRows.isNotEmpty ||
        controller.serialRows.isNotEmpty ||
        controller.stockCardResult != null ||
        controller.reorderResult != null;
  }
}

class _InquiryTableColumn {
  const _InquiryTableColumn(
    this.label,
    this.path, {
    this.numeric = false,
    this.isDate = false,
    this.boolean = false,
  });

  final String label;
  final String path;
  final bool numeric;
  final bool isDate;
  final bool boolean;
}

class _InquiryInfoBlock extends StatelessWidget {
  const _InquiryInfoBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
