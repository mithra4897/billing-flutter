import '../../controller/sales/sales_delivery_management_controller.dart';
import '../../screen.dart';

class SalesDeliveryPage extends StatefulWidget {
  const SalesDeliveryPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
    this.initialOrderId,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;
  final int? initialOrderId;
  final Map<String, String> queryParameters;

  @override
  State<SalesDeliveryPage> createState() => _SalesDeliveryPageState();
}

class _SalesDeliveryPageState extends State<SalesDeliveryPage> {
  late final String _controllerTag;

  SalesDeliveryManagementController get _controller =>
      Get.find<SalesDeliveryManagementController>(tag: _controllerTag);

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'SalesDeliveryManagementController',
      scope: <String, Object?>{'identity': identityHashCode(this)},
    );
    Get.put(SalesDeliveryManagementController(), tag: _controllerTag);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        _controller.initialize(
          initialId: widget.initialId,
          initialOrderId: widget.initialOrderId,
          editorOnly: widget.editorOnly,
        ),
      );
    });
  }

  @override
  void dispose() {
    Get.delete<SalesDeliveryManagementController>(
      tag: _controllerTag,
      force: true,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SalesDeliveryManagementController>(
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
            onPressed: () {
              controller.resetForm();
              if (!Responsive.isDesktop(context)) {
                controller.workspaceController.openEditor();
              }
            },
            icon: Icons.add_outlined,
            label: 'New Delivery',
          ),
        ];
        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Sales Deliveries',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Future<void> _openFilterPanel(
    BuildContext context,
    SalesDeliveryManagementController controller,
  ) {
    return openSalesSearchStatusFilterPanel(
      context: context,
      title: 'Filter Sales Deliveries',
      searchController: controller.searchController,
      dateFromController: controller.dateFromController,
      dateToController: controller.dateToController,
      searchHint: 'Search deliveries',
      status: controller.statusFilter,
      statusItems: SalesDeliveryManagementController.statusItems,
      onApply: (search, status, dateFrom, dateTo) {
        controller.searchController.text = search;
        controller.dateFromController.text = dateFrom;
        controller.dateToController.text = dateTo;
        controller.setStatusFilter(status);
      },
      onClear: () {
        controller.searchController.clear();
        controller.dateFromController.clear();
        controller.dateToController.clear();
        controller.setStatusFilter('');
      },
    );
  }

  Widget _buildGridHintCell(
    BuildContext context,
    String text, {
    bool muted = true,
  }) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    return ErpLineItemCellFrame(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.2,
            color: muted ? appTheme.tableMutedText : appTheme.tableCellText,
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryLineTable(SalesDeliveryManagementController controller) {
    final selectedData = controller.selectedItem?.toJson() ?? const {};
    final status = stringValue(selectedData, 'delivery_status', 'draft');
    final canEdit = controller.selectedItem == null || status == 'draft';

    final itemOptions = controller.itemPickerOptions
        .map(
          (option) => ErpLinkFieldOption<int>(
            value: option.value,
            label: option.label,
            subtitle: option.subtitle,
            searchText: option.searchText ?? option.subtitle,
          ),
        )
        .toList(growable: false);

    final rows = List<ErpLineItemTableRow>.generate(controller.lines.length, (
      index,
    ) {
      final line = controller.lines[index];
      final qty =
          Validators.parseFlexibleNumber(line.deliveredQtyController.text) ?? 0;
      final rate =
          Validators.parseFlexibleNumber(line.rateController.text) ?? 0;
      final amount = qty * rate;
      final uomOptions = controller
          .uomOptionsForItem(line.itemId)
          .where((item) => item.id != null)
          .map(
            (item) =>
                AppDropdownItem<int>(value: item.id!, label: item.toString()),
          )
          .toList(growable: false);

      if (canEdit && uomOptions.length == 1) {
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
                ) ??
                ErpLinkFieldOption<int>(
                  value: line.itemId!,
                  label:
                      controller.itemLabelById(line.itemId) ??
                      (() {
                        final fallback = line.descriptionController.text.trim();
                        return fallback.isEmpty ? 'Item' : fallback;
                      })(),
                  subtitle: line.itemId!.toString(),
                );

      return ErpLineItemTableRow(
        rowKey: line,
        itemId: line.itemId,
        itemSelection: itemSelection,
        itemOptions: itemOptions,
        onItemChanged: canEdit
            ? (value) => controller.setLineItemId(index, value)
            : null,
        itemValidator: (_) =>
            Validators.requiredSelectionField(line.itemId, 'Item'),
        warehouseId: line.warehouseId,
        warehouseOptions: controller.warehouseDropdownItems,
        onWarehouseChanged: canEdit
            ? (value) => unawaited(controller.setLineWarehouseId(index, value))
            : null,
        uomId: line.uomId,
        uomOptions: uomOptions,
        onUomChanged: canEdit
            ? (value) => controller.setLineUomId(index, value)
            : null,
        uomValidator: (_) => Validators.dependentSelectionField(
          prerequisite: line.itemId,
          prerequisiteName: 'item',
          value: line.uomId,
          fieldName: 'UOM',
        ),
        qtyController: line.deliveredQtyController,
        qtyValidator: (_) {
          final quantityError = Validators.requiredPositiveNumberField(
            line.deliveredQtyController.text,
            'Delivered Qty',
          );
          if (quantityError != null) {
            return quantityError;
          }
          final qtyValue = double.tryParse(
            line.deliveredQtyController.text.trim(),
          );
          if (controller.isSerialManagedItem(line.itemId)) {
            final serialCount = controller.lineSerialNumbers(line).length;
            if (serialCount == 0) {
              return 'Add at least one serial number';
            }
            if (qtyValue != serialCount) {
              return 'Qty must match serial count';
            }
          }
          return null;
        },
        rateController: line.rateController,
        rateValidator: Validators.optionalNonNegativeNumber('Rate'),
        descriptionController: line.descriptionController,
        remarksController: line.remarksController,
        amount: amount,
        deleteEnabled: controller.lines.length > 1,
        customCells: <String, Widget>{
          'batch': () {
            if (line.itemId == null) {
              return _buildGridHintCell(context, 'Select item');
            }
            if (!controller.isBatchManagedItem(line.itemId)) {
              return _buildGridHintCell(context, 'Not required');
            }
            if (line.warehouseId == null) {
              return _buildGridHintCell(context, 'Select warehouse');
            }
            final batchItems = controller
                .batchOptionsForLine(line)
                .map(
                  (batch) => AppDropdownItem<int>(
                    value:
                        int.tryParse(batch['batch_id']?.toString() ?? '') ?? 0,
                    label: stringValue(batch, 'batch_no', 'Batch'),
                  ),
                )
                .where((item) => item.value != 0)
                .toList(growable: false);
            if (batchItems.isEmpty) {
              return _buildGridHintCell(context, 'No batches');
            }
            return ErpLineItemCellFrame(
              child: IgnorePointer(
                ignoring: !canEdit,
                child: AppDropdownField<int>.fromMapped(
                  labelText: '',
                  hintText: 'Batch',
                  fieldPadding: EdgeInsets.zero,
                  mappedItems: batchItems,
                  initialValue: line.batchId,
                  onChanged: (value) =>
                      unawaited(controller.setLineBatchId(index, value)),
                ),
              ),
            );
          }(),
          'serials': () {
            if (line.itemId == null) {
              return _buildGridHintCell(context, 'Select item');
            }
            if (!controller.isSerialManagedItem(line.itemId)) {
              return _buildGridHintCell(context, 'Not required');
            }
            if (line.warehouseId == null) {
              return _buildGridHintCell(context, 'Select warehouse');
            }
            if (controller.isBatchManagedItem(line.itemId) &&
                line.batchId == null) {
              return _buildGridHintCell(context, 'Select batch');
            }
            return ErpLineItemCellFrame(
              height: null,
              child: IgnorePointer(
                ignoring: !canEdit,
                child: AppSerialNumbersField(
                  labelText: '',
                  emptyText: 'Add serials',
                  countSummaryBuilder: (count) => '$count serials',
                  values: line.serialNumbers,
                  canOpen:
                      ((controller.isBatchManagedItem(line.itemId)
                          ? line.batchId != null
                          : line.warehouseId != null) ||
                      line.serialNumbers.isNotEmpty),
                  beforeOpen: () => controller.syncSerialOptionsForLine(line),
                  validator: (values) {
                    if (line.warehouseId == null) {
                      return 'Select warehouse first';
                    }
                    if (controller.isBatchManagedItem(line.itemId) &&
                        line.batchId == null) {
                      return 'Select batch first';
                    }
                    final serialOptions = controller.serialOptionsForLine(line);
                    if (serialOptions.isEmpty) {
                      return 'No serials found in backend for the selected warehouse.';
                    }
                    final serialLabelSet = controller.serialLabelSetForLine(
                      line,
                    );
                    for (final value in values) {
                      if (!serialLabelSet.contains(
                        value.trim().toLowerCase(),
                      )) {
                        return 'Serial "$value" is not available for the selected warehouse/batch.';
                      }
                    }
                    return null;
                  },
                  onChanged: (values) {
                    controller.setLineSerialNumbers(line, values);
                    controller.refreshState();
                  },
                ),
              ),
            );
          }(),
        },
      );
    });

    return ErpLineItemTable(
      title: 'Delivery Items',
      lines: rows,
      onAddLine: canEdit ? controller.addLine : null,
      onDeleteLine: canEdit ? controller.removeLine : null,
      visibleColumns: const <ErpLineItemTableColumn>{
        ErpLineItemTableColumn.no,
        ErpLineItemTableColumn.item,
        ErpLineItemTableColumn.warehouse,
        ErpLineItemTableColumn.uom,
        ErpLineItemTableColumn.qty,
        ErpLineItemTableColumn.rate,
        ErpLineItemTableColumn.amount,
        ErpLineItemTableColumn.action,
      },
      columnLabels: const <ErpLineItemTableColumn, String>{
        ErpLineItemTableColumn.qty: 'Delivered Qty',
      },
      customColumns: const <ErpLineItemCustomColumn>[
        ErpLineItemCustomColumn(
          id: 'batch',
          label: 'Batch',
          width: 150,
          insertAfter: ErpLineItemTableColumn.warehouse,
        ),
        ErpLineItemCustomColumn(
          id: 'serials',
          label: 'Serials',
          width: 220,
          insertAfter: ErpLineItemTableColumn.warehouse,
        ),
      ],
      enabled: canEdit,
    );
  }

  Widget _buildReturnableDcTable(SalesDeliveryManagementController controller) {
    final selectedData = controller.selectedItem?.toJson() ?? const {};
    final status = stringValue(selectedData, 'delivery_status', 'draft');
    final canEdit = controller.selectedItem == null || status == 'draft';

    final itemOptions = controller.itemPickerOptions
        .map(
          (option) => ErpLinkFieldOption<int>(
            value: option.value,
            label: option.label,
            subtitle: option.subtitle,
            searchText: option.searchText ?? option.subtitle,
          ),
        )
        .toList(growable: false);

    final rows = List<ErpLineItemTableRow>.generate(
      controller.returnableDcs.length,
      (index) {
        final row = controller.returnableDcs[index];
        final qty = Validators.parseFlexibleNumber(row.qtyController.text) ?? 0;
        final uomOptions = controller
            .uomOptionsForItem(row.itemId)
            .where((item) => item.id != null)
            .map(
              (item) =>
                  AppDropdownItem<int>(value: item.id!, label: item.toString()),
            )
            .toList(growable: false);

        if (canEdit && uomOptions.length == 1) {
          final onlyId = uomOptions.first.value;
          if (row.uomId != onlyId) {
            row.uomId = onlyId;
          }
        }

        final itemSelection = row.itemId == null
            ? null
            : itemOptions.cast<ErpLinkFieldOption<int>?>().firstWhere(
                (item) => item?.value == row.itemId,
                orElse: () => null,
              );

        return ErpLineItemTableRow(
          rowKey: row,
          itemId: row.itemId,
          itemSelection: itemSelection,
          itemOptions: itemOptions,
          onItemChanged: canEdit
              ? (value) => controller.setReturnableDcItemId(index, value)
              : null,
          uomId: row.uomId,
          uomOptions: uomOptions,
          onUomChanged: canEdit
              ? (value) => controller.setReturnableDcUomId(index, value)
              : null,
          uomValidator: (_) => row.uomId == null ? 'UOM is required' : null,
          qtyController: row.qtyController,
          qtyValidator: (_) => Validators.requiredPositiveNumberField(
            row.qtyController.text,
            'Qty',
          ),
          descriptionController: row.descriptionController,
          remarksController: row.remarksController,
          amount: qty,
          deleteEnabled: controller.returnableDcs.length > 1,
          customCells: <String, Widget>{
            'item_name': ErpLineItemTextCell(
              controller: row.itemNameController,
              hintText: 'Use when item is not in item master',
              enabled: canEdit,
            ),
          },
        );
      },
    );

    return ErpLineItemTable(
      title: 'Returnable Items',
      lines: rows,
      onAddLine: canEdit ? controller.addReturnableDc : null,
      onDeleteLine: canEdit ? controller.removeReturnableDc : null,
      addButtonLabel: 'Add Returnable Item',
      visibleColumns: const <ErpLineItemTableColumn>{
        ErpLineItemTableColumn.no,
        ErpLineItemTableColumn.item,
        ErpLineItemTableColumn.uom,
        ErpLineItemTableColumn.qty,
        ErpLineItemTableColumn.action,
      },
      customColumns: const <ErpLineItemCustomColumn>[
        ErpLineItemCustomColumn(
          id: 'item_name',
          label: 'New Item Name',
          width: 220,
          insertAfter: ErpLineItemTableColumn.item,
        ),
      ],
      enabled: canEdit,
    );
  }

  Widget _buildContent(
    BuildContext context,
    SalesDeliveryManagementController controller,
  ) {
    final selectedData = controller.selectedItem?.toJson() ?? const {};
    final status = stringValue(selectedData, 'delivery_status', 'draft');
    final deliveryKind = controller.deliveryKind;
    final canEdit = controller.selectedItem == null || status == 'draft';
    final canPost = controller.selectedItem != null && status == 'draft';
    final canCancel = controller.selectedItem != null && status == 'draft';
    final hasExistingInvoice =
        ((controller.salesChain?['invoices'] as List?) ?? const []).isNotEmpty;
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading sales deliveries...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load sales deliveries',
        message: controller.pageError!,
        onRetry: controller.reloadLastRequestedPage,
      );
    }
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Delivery Challans',
      editorTitle: controller.selectedItem == null
          ? 'New ${controller.deliveryKindLabel}'
          : stringValue(
              controller.selectedItem!.toJson(),
              'delivery_no',
              controller.deliveryKindLabel,
            ),
      editorOnly: widget.editorOnly,
      scrollController: controller.pageScrollController,
      list: PurchaseListCard<SalesDeliveryModel>(
        items: controller.filteredItems,
        selectedItem: controller.selectedItem,
        emptyMessage: 'No delivery challans found.',
        searchController: controller.searchController,
        searchHint: 'Search deliveries',
        statusValue: controller.statusFilter,
        statusItems: SalesDeliveryManagementController.statusItems,
        onStatusChanged: (value) => controller.setStatusFilter(value ?? ''),
        showInlineFilters: false,
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'delivery_no', 'Draft Delivery'),
            subtitle: displayDate(nullableStringValue(data, 'delivery_date')),
            detail: salesListDetailWithCancelReason(
              data,
              quotationCustomerLabel(data),
              statusKey: 'delivery_status',
            ),
            trailing: salesStatusBadge(
              context,
              stringValue(data, 'delivery_status'),
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
            if (controller.selectedItem != null && !canEdit) ...[
              Padding(
                padding: const EdgeInsets.only(
                  bottom: AppUiConstants.spacingMd,
                ),
                child: Text(
                  'This document is read-only (Posted/Completed/Cancelled documents cannot be edited)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (controller.formError != null) ...[
              AppErrorStateView.inline(message: controller.formError!),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            CrmSalesPipelineBar(
              data: controller.salesChain,
              hideDeliveryChip: true,
            ),
            SettingsFormWrap(
              children: [
                ...buildSalesDocumentContextFields(
                  documentSeriesItems: controller.documentSeriesDropdownItems,
                  documentSeriesId: controller.documentSeriesId,
                  onDocumentSeriesChanged: controller.setDocumentSeriesId,
                ),
                GeneratedDocumentNumberField(
                  labelText: 'Delivery No',
                  controller: controller.deliveryNoController,
                  documentSeries: controller.seriesOptions(),
                  documentSeriesId: controller.documentSeriesId,
                  hintText: 'Auto-generated on save',
                  validator: Validators.optionalMaxLength(100, 'Delivery No'),
                ),
                AppFormTextField(
                  labelText: 'Delivery Date',
                  controller: controller.deliveryDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('Delivery Date'),
                    Validators.date('Delivery Date'),
                  ]),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Challan Type',
                  mappedItems: const <AppDropdownItem<String>>[
                    AppDropdownItem(value: 'dc', label: 'DC'),
                    AppDropdownItem(value: 'rdc', label: 'Returnable DC'),
                  ],
                  initialValue: controller.deliveryKind,
                  onChanged: controller.setDeliveryKind,
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Customer',
                  doctypeLabel: 'Customer',
                  allowCreate: true,
                  onNavigateToCreateNew: (name) {
                    final uri = Uri(
                      path: '/parties',
                      queryParameters: {
                        'new': '1',
                        'party_context': 'customer',
                        if (name.trim().isNotEmpty) 'party_name': name.trim(),
                      },
                    );
                    openModuleShellRoute(context, uri.toString());
                  },
                  mappedItems: controller.customerDropdownItems,
                  initialValue: controller.customerPartyId,
                  onChanged: controller.setCustomerPartyId,
                  validator: Validators.requiredSelection('Customer'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Sales Order',
                  mappedItems: controller.orderDropdownItems,
                  initialValue: controller.salesOrderId,
                  onChanged: (value) =>
                      unawaited(controller.applySalesOrderSelection(value)),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Transporter',
                  mappedItems: controller.transporterDropdownItems,
                  initialValue: controller.transporterPartyId,
                  onChanged: controller.setTransporterPartyId,
                ),
                AppFormTextField(
                  labelText: 'Vehicle No',
                  controller: controller.vehicleNoController,
                ),
                AppFormTextField(
                  labelText: 'LR No',
                  controller: controller.lrNoController,
                ),
                AppFormTextField(
                  labelText: 'LR Date',
                  controller: controller.lrDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('LR Date'),
                ),
                AppFormTextField(
                  labelText: 'Notes',
                  controller: controller.notesController,
                  maxLines: 3,
                ),
                AppFormTextField(
                  labelText: 'Terms & Conditions',
                  controller: controller.termsController,
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
            GetBuilder<SalesDeliveryManagementController>(
              tag: _controllerTag,
              id: SalesDeliveryManagementController.lineItemsSectionId,
              builder: (controller) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (controller.deliveryKind == 'dc')
                    _buildDeliveryLineTable(controller),
                  if (controller.deliveryKind == 'rdc') ...[
                    const SizedBox(height: AppUiConstants.spacingLg),
                    _buildReturnableDcTable(controller),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            SalesDocumentActionRow(
              actions: [
                if (controller.selectedItem != null &&
                    deliveryKind == 'dc' &&
                    !hasExistingInvoice &&
                    const {'posted', 'partially_invoiced'}.contains(status))
                  AppActionButton(
                    icon: Icons.receipt_long_outlined,
                    label: 'Create invoice',
                    filled: false,
                    onPressed: () {
                      final deliveryId = intValue(selectedData, 'id');
                      if (deliveryId == null) {
                        return;
                      }
                      openModuleShellRoute(
                        context,
                        '/sales/invoices/new?delivery_id=$deliveryId',
                      );
                    },
                  ),
                if (controller.selectedItem != null &&
                    !const {'cancelled'}.contains(status))
                  AppActionButton(
                    icon: status == 'draft'
                        ? Icons.preview_outlined
                        : Icons.print_outlined,
                    label: status == 'draft' ? 'Preview' : 'Print',
                    filled: false,
                    onPressed: () => controller.openPrintPreview(
                      context,
                      allowPrint: status != 'draft',
                      allowDownload: status != 'draft',
                      allowTemplateEditing: status != 'draft',
                    ),
                  ),
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: controller.selectedItem == null
                      ? 'Save ${controller.deliveryKindLabel}'
                      : 'Update ${controller.deliveryKindLabel}',
                  onPressed: canEdit ? () => controller.save(context) : null,
                  busy: controller.saving,
                ),
                if (canPost)
                  AppActionButton(
                    icon: Icons.publish_outlined,
                    label: 'Post',
                    filled: false,
                    onPressed: () => controller.postSelected(context),
                  ),
                if (canCancel)
                  AppActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    filled: false,
                    onPressed: () => controller.cancelSelected(context),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
