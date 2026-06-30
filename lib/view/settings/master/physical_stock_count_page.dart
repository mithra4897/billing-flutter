import '../../../controller/settings/master/physical_stock_count_management_controller.dart';
import '../../../screen.dart';

class PhysicalStockCountPage extends StatefulWidget {
  const PhysicalStockCountPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PhysicalStockCountPage> createState() => _PhysicalStockCountPageState();
}

class _PhysicalStockCountPageState extends State<PhysicalStockCountPage> {
  late final String _controllerTag;
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  String _statusFilter = '';
  String _categoryFilter = '';

  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All status'),
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'counted', label: 'Counted'),
        AppDropdownItem(value: 'reconciled', label: 'Reconciled'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  Future<void> _openFilterPanel(
    BuildContext context,
    PhysicalStockCountManagementController controller,
  ) {
    return openInventorySearchStatusCategoryFilterPanel(
      context: context,
      title: 'Filter Physical Counts',
      searchController: controller.searchController,
      dateFromController: _dateFromController,
      dateToController: _dateToController,
      searchHint: 'Count no, status, scope, or warehouse',
      status: _statusFilter,
      statusItems: _statusItems,
      category: _categoryFilter,
      categoryItems: _buildCategoryItems(controller),
      onApply: (search, status, dateFrom, dateTo, category) {
        setState(() {
          controller.searchController.text = search;
          _dateFromController.text = dateFrom;
          _dateToController.text = dateTo;
          _statusFilter = status;
          _categoryFilter = category;
        });
      },
      onClear: () {
        setState(() {
          controller.searchController.clear();
          _dateFromController.clear();
          _dateToController.clear();
          _statusFilter = '';
          _categoryFilter = '';
        });
      },
    );
  }

  List<AppDropdownItem<String>> _buildCategoryItems(
    PhysicalStockCountManagementController controller,
  ) {
    final seen = <String>{};
    final values = controller.allItems
        .map((item) => (item.categoryName ?? item.categoryCode ?? '').trim())
        .where((value) => value.isNotEmpty && seen.add(value))
        .toList(growable: false);
    return <AppDropdownItem<String>>[
      const AppDropdownItem<String>(value: '', label: 'All categories'),
      ...values.map(
        (value) => AppDropdownItem<String>(value: value, label: value),
      ),
    ];
  }

  String _categoryForItem(
    PhysicalStockCountManagementController controller,
    int? itemId,
  ) {
    final item = controller.allItems.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );
    return (item?.categoryName ?? item?.categoryCode ?? '').trim();
  }

  List<PhysicalStockCountModel> _visibleItems(
    PhysicalStockCountManagementController controller,
  ) {
    return controller.filteredItems
        .where((item) {
          final matchesStatus =
              _statusFilter.isEmpty ||
              (item.countStatus ?? '').trim().toLowerCase() ==
                  _statusFilter.toLowerCase();
          final matchesDate = matchesDateValueRange(
            item.countDate,
            fromValue: _dateFromController.text,
            toValue: _dateToController.text,
          );
          final matchesCategory =
              _categoryFilter.isEmpty ||
              item.items.any(
                (line) =>
                    _categoryForItem(controller, line.itemId) ==
                    _categoryFilter,
              );
          return matchesStatus && matchesDate && matchesCategory;
        })
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'PhysicalStockCountManagementController',
    );
    Get.put(PhysicalStockCountManagementController(), tag: _controllerTag);
  }

  @override
  void dispose() {
    _dateFromController.dispose();
    _dateToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PhysicalStockCountManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => _openFilterPanel(context, controller),
            icon: Icons.filter_alt_outlined,
            label: 'Filter',
            filled: false,
          ),
          AdaptiveShellActionButton(
            onPressed: () =>
                controller.startNew(isDesktop: Responsive.isDesktop(context)),
            icon: Icons.checklist_rtl_outlined,
            label: 'New Count',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(
            actions: actions,
            child: _buildContent(context, controller),
          );
        }

        return AppStandaloneShell(
          title: 'Physical Counts',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: _buildContent(context, controller),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    PhysicalStockCountManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading physical counts...');
    }

    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load physical counts',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }

    final countStatus = controller.selectedCount?.countStatus ?? 'draft';

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Physical Counts',
      editorTitle: controller.selectedCount?.toString(),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<PhysicalStockCountModel>(
        searchController: controller.searchController,
        searchHint: 'Search physical counts',
        items: _visibleItems(controller),
        selectedItem: controller.selectedCount,
        emptyMessage: 'No physical counts found.',
        itemBuilder: (item, selected) => SettingsListTile(
          title: item.countNo ?? '-',
          subtitle: [
            item.countDate ?? '',
            item.countStatus ?? '',
            item.warehouseName ?? '',
          ].where((value) => value.trim().isNotEmpty).join(' · '),
          selected: selected,
          onTap: () => controller.selectCount(item),
        ),
      ),
      editorBuilder: (_) => Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.formError != null) ...[
              AppErrorStateView.inline(message: controller.formError!),
              const SizedBox(height: 16),
            ],
            SettingsFormWrap(
              children: [
                DocumentSeriesSelector<int?>(
                  initialValue: controller.documentSeriesId,
                  labelText: 'Document Series',
                  mappedItems: <AppDropdownItem<int?>>[
                    const AppDropdownItem<int?>(
                      value: null,
                      label: 'Auto / None',
                    ),
                    ...controller.filteredDocumentSeriesOptions.map(
                      (series) => AppDropdownItem<int?>(
                        value: series.id,
                        label: series.toString(),
                      ),
                    ),
                  ],
                  onChanged: controller.setDocumentSeriesId,
                ),
                AppDropdownField<int?>.fromMapped(
                  initialValue: controller.warehouseId,
                  labelText: 'Warehouse',
                  mappedItems: controller.filteredWarehouseOptions
                      .where((warehouse) => warehouse.id != null)
                      .map(
                        (warehouse) => AppDropdownItem<int?>(
                          value: warehouse.id,
                          label: warehouse.toString(),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: controller.setWarehouseId,
                  validator: Validators.requiredSelection('Warehouse'),
                ),
                GeneratedDocumentNumberField(
                  labelText: 'Count No',
                  controller: controller.countNoController,
                  documentSeries: controller.filteredDocumentSeriesOptions,
                  documentSeriesId: controller.documentSeriesId,
                  validator: Validators.optionalMaxLength(100, 'Count No'),
                ),
                AppFormTextField(
                  labelText: 'Count Date',
                  controller: controller.countDateController,
                  hintText: 'YYYY-MM-DD',
                  validator: Validators.compose([
                    Validators.required('Count Date'),
                    Validators.optionalDate('Count Date'),
                  ]),
                ),
                DropdownButtonFormField<String>(
                  initialValue: controller.countScope,
                  decoration: const InputDecoration(labelText: 'Count Scope'),
                  items: PhysicalStockCountManagementController.scopeItems
                      .map(
                        (scope) => DropdownMenuItem<String>(
                          value: scope.value,
                          child: Text(scope.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: controller.setCountScope,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppFormTextField(
              labelText: 'Remarks',
              controller: controller.remarksController,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item Lines',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                AppActionButton(
                  icon: Icons.add_circle_outline,
                  label: 'Add Line',
                  onPressed: controller.addLine,
                  filled: false,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (controller.lines.isEmpty)
              const Text('No item lines added yet.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.lines.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final line = controller.lines[index];
                  final batchOptions = controller.batchOptionsForItem(
                    line.itemId,
                  );
                  final serialOptions = controller.serialOptionsForItem(
                    line.itemId,
                    line.batchId,
                  );
                  final systemController = TextEditingController(
                    text: line.systemQty?.toString() ?? '',
                  );
                  final countedController = TextEditingController(
                    text: line.countedQty?.toString() ?? '',
                  );
                  final costController = TextEditingController(
                    text: line.unitCost?.toString() ?? '',
                  );
                  final remarksController = TextEditingController(
                    text: line.remarks ?? '',
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Line ${index + 1}'),
                          IconButton(
                            onPressed: () => controller.removeLine(index),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                      SettingsFormWrap(
                        children: [
                          DropdownButtonFormField<int>(
                            initialValue: line.itemId,
                            decoration: const InputDecoration(
                              labelText: 'Item',
                            ),
                            items: controller.allItems
                                .where((item) => item.id != null)
                                .map(
                                  (item) => DropdownMenuItem<int>(
                                    value: item.id,
                                    child: Text(item.toString()),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) {
                              final item = controller.allItems
                                  .cast<ItemModel?>()
                                  .firstWhere(
                                    (entry) => entry?.id == value,
                                    orElse: () => null,
                                  );
                              controller.updateLine(
                                index,
                                PhysicalStockCountLineModel(
                                  id: line.id,
                                  itemId: value,
                                  uomId:
                                      item?.baseUomId ??
                                      line.uomId ??
                                      (controller.uoms.isNotEmpty
                                          ? controller.uoms.first.id
                                          : null),
                                  batchId: null,
                                  serialId: null,
                                  countedQty: line.countedQty,
                                  unitCost: line.unitCost,
                                  remarks: line.remarks,
                                ),
                              );
                            },
                          ),
                          DropdownButtonFormField<int>(
                            initialValue: line.uomId,
                            decoration: const InputDecoration(labelText: 'UOM'),
                            items: controller.uoms
                                .where((uom) => uom.id != null)
                                .map(
                                  (uom) => DropdownMenuItem<int>(
                                    value: uom.id,
                                    child: Text(uom.toString()),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) => controller.updateLine(
                              index,
                              PhysicalStockCountLineModel(
                                id: line.id,
                                itemId: line.itemId,
                                uomId: value,
                                batchId: line.batchId,
                                serialId: line.serialId,
                                countedQty: line.countedQty,
                                unitCost: line.unitCost,
                                remarks: line.remarks,
                              ),
                            ),
                          ),
                          DropdownButtonFormField<int?>(
                            initialValue: line.batchId,
                            decoration: const InputDecoration(
                              labelText: 'Batch',
                            ),
                            items: <DropdownMenuItem<int?>>[
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('None'),
                              ),
                              ...batchOptions.map(
                                (batch) => DropdownMenuItem<int?>(
                                  value: int.tryParse(
                                    batch.toJson()['id']?.toString() ?? '',
                                  ),
                                  child: Text(controller.batchLabel(batch)),
                                ),
                              ),
                            ],
                            onChanged: (value) => controller.updateLine(
                              index,
                              PhysicalStockCountLineModel(
                                id: line.id,
                                itemId: line.itemId,
                                uomId: line.uomId,
                                batchId: value,
                                serialId: null,
                                countedQty: line.countedQty,
                                unitCost: line.unitCost,
                                remarks: line.remarks,
                              ),
                            ),
                          ),
                          DropdownButtonFormField<int?>(
                            initialValue: line.serialId,
                            decoration: const InputDecoration(
                              labelText: 'Serial',
                            ),
                            items: <DropdownMenuItem<int?>>[
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('None'),
                              ),
                              ...serialOptions.map(
                                (serial) => DropdownMenuItem<int?>(
                                  value: int.tryParse(
                                    serial.toJson()['id']?.toString() ?? '',
                                  ),
                                  child: Text(controller.serialLabel(serial)),
                                ),
                              ),
                            ],
                            onChanged: (value) => controller.updateLine(
                              index,
                              PhysicalStockCountLineModel(
                                id: line.id,
                                itemId: line.itemId,
                                uomId: line.uomId,
                                batchId: line.batchId,
                                serialId: value,
                                countedQty: line.countedQty,
                                unitCost: line.unitCost,
                                remarks: line.remarks,
                              ),
                            ),
                          ),
                          AppFormTextField(
                            labelText: 'System Qty',
                            controller: systemController,
                            readOnly: true,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          AppFormTextField(
                            labelText: 'Counted Qty',
                            controller: countedController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (value) => controller.updateLine(
                              index,
                              PhysicalStockCountLineModel(
                                id: line.id,
                                itemId: line.itemId,
                                uomId: line.uomId,
                                batchId: line.batchId,
                                serialId: line.serialId,
                                countedQty: double.tryParse(value.trim()),
                                unitCost: line.unitCost,
                                remarks: line.remarks,
                              ),
                            ),
                          ),
                          AppFormTextField(
                            labelText: 'Unit Cost',
                            controller: costController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (value) => controller.updateLine(
                              index,
                              PhysicalStockCountLineModel(
                                id: line.id,
                                itemId: line.itemId,
                                uomId: line.uomId,
                                batchId: line.batchId,
                                serialId: line.serialId,
                                countedQty: line.countedQty,
                                unitCost: double.tryParse(value.trim()),
                                remarks: line.remarks,
                              ),
                            ),
                          ),
                          AppFormTextField(
                            labelText: 'Line Remarks',
                            controller: remarksController,
                            maxLines: 2,
                            onChanged: (value) => controller.updateLine(
                              index,
                              PhysicalStockCountLineModel(
                                id: line.id,
                                itemId: line.itemId,
                                uomId: line.uomId,
                                batchId: line.batchId,
                                serialId: line.serialId,
                                countedQty: line.countedQty,
                                unitCost: line.unitCost,
                                remarks: nullIfEmpty(value),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: controller.selectedCount == null
                      ? 'Save Count'
                      : 'Update Count',
                  onPressed: controller.save,
                  busy: controller.saving,
                ),
                if (controller.selectedCount?.id != null &&
                    countStatus == 'draft')
                  AppActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    onPressed: controller.saving
                        ? null
                        : controller.deleteSelected,
                    filled: false,
                  ),
                if (controller.selectedCount?.id != null &&
                    countStatus == 'draft')
                  AppActionButton(
                    icon: Icons.playlist_add_check_outlined,
                    label: 'Mark Counted',
                    onPressed: controller.saving
                        ? null
                        : controller.markCounted,
                    filled: false,
                  ),
                if (controller.selectedCount?.id != null &&
                    (countStatus == 'draft' || countStatus == 'counted'))
                  AppActionButton(
                    icon: Icons.check_circle_outline,
                    label: 'Reconcile',
                    onPressed: controller.saving ? null : controller.reconcile,
                    filled: false,
                  ),
                if (controller.selectedCount?.id != null &&
                    countStatus != 'reconciled' &&
                    countStatus != 'cancelled')
                  AppActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    onPressed: controller.saving ? null : controller.cancel,
                    filled: false,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
