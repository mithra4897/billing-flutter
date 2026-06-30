import '../../controller/purchase/purchase_receipt_management_controller.dart';
import '../../screen.dart';

class PurchaseReceiptPage extends StatefulWidget {
  const PurchaseReceiptPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<PurchaseReceiptPage> createState() => _PurchaseReceiptPageState();
}

class _PurchaseReceiptPageState extends State<PurchaseReceiptPage> {
  late final String _controllerTag;

  PurchaseReceiptManagementController get _controller =>
      Get.find<PurchaseReceiptManagementController>(tag: _controllerTag);

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'PurchaseReceiptManagementController',
      scope: uniqueControllerScope(<String, Object?>{
        'identity': identityHashCode(this),
      }),
    );
    Get.put(PurchaseReceiptManagementController(), tag: _controllerTag);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_controller.initialize(initialId: widget.initialId));
    });
  }

  @override
  void dispose() {
    Get.delete<PurchaseReceiptManagementController>(
      tag: _controllerTag,
      force: true,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PurchaseReceiptManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () {
              controller.resetForm();
              if (!Responsive.isDesktop(context)) {
                controller.workspaceController.openEditor();
              }
            },
            icon: Icons.add_outlined,
            label: 'New Receipt',
          ),
        ];
        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Purchase Receipts',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildLineItemTable(PurchaseReceiptManagementController controller) {
    final itemOptions = controller.itemsLookup
        .where((item) => item.id != null)
        .map(
          (item) => ErpLinkFieldOption<int>(
            value: item.id!,
            label: item.toString(),
            subtitle: item.itemCode,
            searchText: item.pickerSearchText,
          ),
        )
        .toList(growable: false);

    final warehouseOptions = controller.warehouses
        .where((item) => item.id != null)
        .map(
          (item) =>
              AppDropdownItem<int>(value: item.id!, label: item.toString()),
        )
        .toList(growable: false);

    final rows = List<ErpLineItemTableRow>.generate(controller.lines.length, (
      index,
    ) {
      final line = controller.lines[index];
      final amount = controller.taxBreakdownForLine(line).total;
      final uomOptions = controller
          .uomOptionsForItem(line.itemId)
          .where((item) => item.id != null)
          .map(
            (item) =>
                AppDropdownItem<int>(value: item.id!, label: item.toString()),
          )
          .toList(growable: false);

      if (uomOptions.length == 1) {
        final onlyId = uomOptions.first.value;
        if (line.uomId != onlyId) {
          line.uomId = onlyId;
        }
      }

      final itemSelection = line.itemId == null
          ? null
          : itemOptions.cast<ErpLinkFieldOption<int>?>().firstWhere(
              (item) => item?.value == line.itemId,
              orElse: () => null,
            );

      return ErpLineItemTableRow(
        rowKey: line,
        itemId: line.itemId,
        itemSelection: itemSelection,
        itemOptions: itemOptions,
        onItemChanged: controller.isSelectedReceiptReadOnly
            ? null
            : (value) async {
                await controller.setLineItemId(line, value);
              },
        itemValidator: (_) =>
            Validators.requiredSelectionField(line.itemId, 'Item'),
        warehouseId: line.warehouseId,
        warehouseOptions: warehouseOptions,
        onWarehouseChanged: controller.isSelectedReceiptReadOnly
            ? null
            : (value) async {
                await controller.setLineWarehouseId(line, value);
              },
        uomId: line.uomId,
        uomOptions: uomOptions,
        onUomChanged: controller.isSelectedReceiptReadOnly
            ? null
            : (value) => controller.setLineUomId(line, value),
        uomValidator: (_) => Validators.dependentSelectionField(
          prerequisite: line.itemId,
          prerequisiteName: 'item',
          value: line.uomId,
          fieldName: 'UOM',
        ),
        rateController: line.rateController,
        rateValidator: Validators.optionalNonNegativeNumber('Rate'),
        descriptionController: line.descriptionController,
        remarksController: line.remarksController,
        amount: amount,
        deleteEnabled:
            !controller.isSelectedReceiptReadOnly &&
            controller.lines.length > 1,
        cellWidgets: <ErpLineItemTableColumn, Widget>{
          ErpLineItemTableColumn.qty: ErpLineItemTextCell(
            key: ValueKey('receipt-qty-$index'),
            controller: line.receivedQtyController,
            hintText: 'Received Qty',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              final parsed = Validators.parseFlexibleNumber(value);
              if ((parsed == null || parsed <= 0) &&
                  controller.lineAllowsBlankQty(line)) {
                return null;
              }
              return Validators.compose([
                Validators.required('Received Qty'),
                Validators.optionalNonNegativeNumber('Received Qty'),
              ])(value);
            },
          ),
        },
        customCells: <String, Widget>{
          'serial': controller.isSerialManagedItem(line.itemId)
              ? ErpLineItemCellFrame(
                  child: AppDropdownField<int>.fromMapped(
                    labelText: '',
                    hintText: 'Serial Number',
                    fieldPadding: EdgeInsets.zero,
                    mappedItems: controller
                        .serialOptionsForLine(line)
                        .where(
                          (serial) => intValue(serial.toJson(), 'id') != null,
                        )
                        .map(
                          (serial) => AppDropdownItem<int>(
                            value: intValue(serial.toJson(), 'id')!,
                            label: stringValue(serial.toJson(), 'serial_no'),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: line.serialId,
                    onChanged: controller.isSelectedReceiptReadOnly
                        ? null
                        : (value) => controller.setLineSerialId(line, value),
                    enabled: !controller.isSelectedReceiptReadOnly,
                  ),
                )
              : const ErpLineItemTextCell(
                  readOnly: true,
                  enabled: false,
                  initialValue: '-',
                ),
          'accepted_qty': ErpLineItemTextCell(
            key: ValueKey('accepted-qty-$index'),
            controller: line.acceptedQtyController,
            hintText: 'Accepted Qty',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: Validators.optionalNonNegativeNumber('Accepted Qty'),
          ),
          'rejected_qty': ErpLineItemTextCell(
            key: ValueKey('rejected-qty-$index'),
            controller: line.rejectedQtyController,
            hintText: 'Rejected Qty',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: Validators.optionalNonNegativeNumber('Rejected Qty'),
          ),
        },
      );
    });

    final visibleColumns = <ErpLineItemTableColumn>{
      ErpLineItemTableColumn.no,
      ErpLineItemTableColumn.item,
      ErpLineItemTableColumn.warehouse,
      ErpLineItemTableColumn.uom,
      ErpLineItemTableColumn.qty,
      ErpLineItemTableColumn.rate,
      ErpLineItemTableColumn.amount,
      if (!controller.isSelectedReceiptReadOnly) ErpLineItemTableColumn.action,
    };

    final hasSerialManagedLines = controller.lines.any(
      (line) => controller.isSerialManagedItem(line.itemId),
    );
    final customColumns = <ErpLineItemCustomColumn>[
      if (hasSerialManagedLines)
        const ErpLineItemCustomColumn(
          id: 'serial',
          label: 'Serial Number',
          width: 180,
          insertAfter: ErpLineItemTableColumn.warehouse,
        ),
      const ErpLineItemCustomColumn(
        id: 'accepted_qty',
        label: 'Accepted Qty',
        width: 130,
        insertAfter: ErpLineItemTableColumn.qty,
      ),
      const ErpLineItemCustomColumn(
        id: 'rejected_qty',
        label: 'Rejected Qty',
        width: 130,
        insertAfter: ErpLineItemTableColumn.qty,
      ),
    ];

    return ErpLineItemTable(
      title: 'Lines',
      lines: rows,
      onAddLine: controller.isSelectedReceiptReadOnly
          ? null
          : controller.addLine,
      onDeleteLine: controller.isSelectedReceiptReadOnly
          ? null
          : controller.removeLine,
      addButtonLabel: 'Add Line',
      visibleColumns: visibleColumns,
      columnLabels: const <ErpLineItemTableColumn, String>{
        ErpLineItemTableColumn.qty: 'Received Qty',
      },
      customColumns: customColumns,
      enabled: !controller.isSelectedReceiptReadOnly,
    );
  }

  Widget _buildContent(
    BuildContext context,
    PurchaseReceiptManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading purchase receipts...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load purchase receipts',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Purchase Receipts',
      editorTitle: controller.selectedItem == null
          ? 'New Purchase Receipt'
          : stringValue(
              controller.selectedItem!.toJson(),
              'receipt_no',
              'Purchase Receipt',
            ),
      editorOnly: widget.editorOnly,
      scrollController: controller.pageScrollController,
      list: PurchaseListCard<PurchaseReceiptModel>(
        items: controller.filteredItems,
        selectedItem: controller.selectedItem,
        emptyMessage: 'No purchase receipts found.',
        searchController: controller.searchController,
        searchHint: 'Search receipts',
        statusValue: controller.statusFilter,
        statusItems: PurchaseReceiptManagementController.statusItems,
        onStatusChanged: (value) => controller.setStatusFilter(value ?? ''),
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'receipt_no', 'Draft Receipt'),
            subtitle: [
              displayDate(nullableStringValue(data, 'receipt_date')),
              purchaseStatusLabel(nullableStringValue(data, 'receipt_status')),
            ].where((value) => value.isNotEmpty).join(' · '),
            detail: stringValue(
              data,
              'purchase_order_no',
              stringValue(data, 'supplier_name'),
            ),
            selected: selected,
            onTap: () => controller.selectDocument(item),
          );
        },
      ),
      editorBuilder: (_) => Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.formError != null) ...[
              AppErrorStateView.inline(message: controller.formError!),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            if (controller.isSelectedReceiptReadOnly) ...[
              Text(
                purchaseReadOnlyMessage(
                  'purchase receipt',
                  nullableStringValue(
                    controller.selectedItem?.toJson() ?? const {},
                    'receipt_status',
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            IgnorePointer(
              ignoring: controller.isSelectedReceiptReadOnly,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsFormWrap(
                    children: [
                      DocumentSeriesSelector<int>(
                        labelText: 'Document Series',
                        mappedItems: controller
                            .seriesOptions()
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem(
                                value: item.id!,
                                label: item.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: controller.documentSeriesId,
                        onChanged: controller.setDocumentSeriesId,
                      ),
                      GeneratedDocumentNumberField(
                        labelText: 'Receipt No',
                        controller: controller.receiptNoController,
                        documentSeries: controller.seriesOptions(),
                        documentSeriesId: controller.documentSeriesId,
                        hintText: 'Auto-generated on save',
                        validator: Validators.optionalMaxLength(
                          100,
                          'Receipt No',
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Receipt Date',
                        controller: controller.receiptDateController,
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateInputFormatter()],
                        validator: Validators.compose([
                          Validators.required('Receipt Date'),
                          Validators.date('Receipt Date'),
                        ]),
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Supplier',
                        doctypeLabel: 'Supplier',
                        allowCreate: true,
                        onNavigateToCreateNew: (name) {
                          final uri = Uri(
                            path: '/parties',
                            queryParameters: {
                              'new': '1',
                              'party_context': 'supplier',
                              if (name.trim().isNotEmpty)
                                'party_name': name.trim(),
                            },
                          );
                          openModuleShellRoute(context, uri.toString());
                        },
                        mappedItems: controller.suppliers
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem(
                                value: item.id!,
                                label: item.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: controller.supplierPartyId,
                        onChanged: controller.setSupplierPartyId,
                        validator: Validators.requiredSelection('Supplier'),
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Purchase Order',
                        mappedItems: controller
                            .receiptOrderOptions()
                            .where(
                              (item) => intValue(item.toJson(), 'id') != null,
                            )
                            .map(
                              (item) => AppDropdownItem(
                                value: intValue(item.toJson(), 'id')!,
                                label: stringValue(
                                  item.toJson(),
                                  'order_no',
                                  'Order',
                                ),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: controller.purchaseOrderId,
                        onChanged: controller.handlePurchaseOrderChanged,
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Warehouse',
                        mappedItems: controller.warehouses
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem(
                                value: item.id!,
                                label: item.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: controller.warehouseId,
                        onChanged: controller.setWarehouseId,
                        validator: (_) => Validators.requiredSelectionField(
                          controller.warehouseId,
                          'Warehouse',
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Supplier Invoice No',
                        controller: controller.supplierInvoiceNoController,
                      ),
                      AppFormTextField(
                        labelText: 'Supplier Invoice Date',
                        controller: controller.supplierInvoiceDateController,
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateInputFormatter()],
                        validator: Validators.optionalDate(
                          'Supplier Invoice Date',
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Supplier DC No',
                        controller: controller.supplierDcNoController,
                      ),
                      AppFormTextField(
                        labelText: 'Supplier DC Date',
                        controller: controller.supplierDcDateController,
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateInputFormatter()],
                        validator: Validators.optionalDate('Supplier DC Date'),
                      ),
                      AppFormTextField(
                        labelText: 'Notes',
                        controller: controller.notesController,
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppUiConstants.spacingMd),
                  AppSwitchTile(
                    label: 'Active',
                    value: controller.isActive,
                    onChanged: controller.setIsActive,
                  ),
                  const SizedBox(height: AppUiConstants.spacingLg),
                  _buildLineItemTable(controller),
                ],
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Builder(
              builder: (_) {
                final selectedData =
                    controller.selectedItem?.toJson() ??
                    const <String, dynamic>{};
                final status = stringValue(selectedData, 'receipt_status');
                final canPost =
                    controller.selectedItem != null && status == 'draft';
                final canCancel =
                    controller.selectedItem != null &&
                    status != 'fully_invoiced' &&
                    status != 'cancelled';

                return Wrap(
                  spacing: AppUiConstants.spacingSm,
                  runSpacing: AppUiConstants.spacingSm,
                  children: [
                    if (!controller.isSelectedReceiptReadOnly)
                      AppActionButton(
                        icon: Icons.save_outlined,
                        label: controller.selectedItem == null
                            ? 'Save Receipt'
                            : 'Update Receipt',
                        onPressed: controller.canEditSelectedReceipt
                            ? () => controller.save(context)
                            : null,
                        busy: controller.saving,
                      ),
                    if (canPost)
                      AppActionButton(
                        icon: Icons.publish_outlined,
                        label: 'Post',
                        filled: false,
                        onPressed: () => controller.docAction(
                          context,
                          () => PurchaseService().postReceipt(
                            intValue(controller.selectedItem!.toJson(), 'id')!,
                            PurchaseReceiptModel.fromJson(
                              const <String, dynamic>{},
                            ),
                          ),
                        ),
                      ),
                    if (canCancel)
                      AppActionButton(
                        icon: Icons.cancel_outlined,
                        label: 'Cancel',
                        filled: false,
                        onPressed: () => controller.docAction(
                          context,
                          () => PurchaseService().cancelReceipt(
                            intValue(controller.selectedItem!.toJson(), 'id')!,
                            PurchaseReceiptModel.fromJson(
                              const <String, dynamic>{},
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
