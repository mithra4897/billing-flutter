import '../../controller/purchase/purchase_order_management_controller.dart';
import '../../screen.dart';

class PurchaseOrderPage extends StatefulWidget {
  const PurchaseOrderPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<PurchaseOrderPage> createState() => _PurchaseOrderPageState();
}

class _PurchaseOrderPageState extends State<PurchaseOrderPage> {
  late final String _controllerTag;

  PurchaseOrderManagementController get _controller =>
      Get.find<PurchaseOrderManagementController>(tag: _controllerTag);

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'PurchaseOrderManagementController',
      scope: uniqueControllerScope(<String, Object?>{
        'identity': identityHashCode(this),
      }),
    );
    Get.put(PurchaseOrderManagementController(), tag: _controllerTag);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_controller.initialize(initialId: widget.initialId));
    });
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<PurchaseOrderManagementController>(
        tag: _controllerTag,
      )) {
        Get.delete<PurchaseOrderManagementController>(
          tag: _controllerTag,
          force: true,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PurchaseOrderManagementController>(
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
            label: 'New Order',
          ),
        ];
        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Purchase Orders',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildLineItemTable(PurchaseOrderManagementController controller) {
    final itemOptions = controller.purchasableItemOptions
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

    final taxOptions = controller.taxCodes
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
              (option) => option?.value == line.itemId,
              orElse: () => null,
            );

      return ErpLineItemTableRow(
        rowKey: line,
        itemId: line.itemId,
        itemSelection: itemSelection,
        itemOptions: itemOptions,
        onItemChanged: controller.isSelectedOrderReadOnly
            ? null
            : (value) => controller.setLineItemId(line, value),
        itemValidator: (_) =>
            Validators.requiredSelectionField(line.itemId, 'Item'),
        uomId: line.uomId,
        uomOptions: uomOptions,
        onUomChanged: controller.isSelectedOrderReadOnly
            ? null
            : (value) => controller.setLineUomId(line, value),
        uomValidator: (_) => Validators.dependentSelectionField(
          prerequisite: line.itemId,
          prerequisiteName: 'item',
          value: line.uomId,
          fieldName: 'UOM',
        ),
        warehouseId: line.warehouseId,
        warehouseOptions: warehouseOptions,
        onWarehouseChanged: controller.isSelectedOrderReadOnly
            ? null
            : (value) => controller.setLineWarehouseId(line, value),
        qtyController: line.qtyController,
        onQtyChanged: controller.isSelectedOrderReadOnly
            ? null
            : (_) => controller.refreshComputedState(),
        qtyValidator: (value) {
          final parsed = Validators.parseFlexibleNumber(value);
          if ((parsed == null || parsed <= 0) &&
              controller.lineAllowsBlankQty(line)) {
            return null;
          }
          return Validators.compose([
            Validators.required('Ordered Qty'),
            Validators.optionalNonNegativeNumber('Ordered Qty'),
          ])(value);
        },
        rateController: line.rateController,
        onRateChanged: controller.isSelectedOrderReadOnly
            ? null
            : (_) => controller.refreshComputedState(),
        rateValidator: Validators.compose([
          Validators.required('Rate'),
          Validators.optionalNonNegativeNumber('Rate'),
        ]),
        discountController: line.discountController,
        onDiscountChanged: controller.isSelectedOrderReadOnly
            ? null
            : (_) => controller.refreshComputedState(),
        discountValidator: Validators.optionalNonNegativeNumber('Discount %'),
        taxCodeId: line.taxCodeId,
        taxOptions: taxOptions,
        onTaxCodeChanged: controller.isSelectedOrderReadOnly
            ? null
            : (value) => controller.setLineTaxCodeId(line, value),
        descriptionController: line.descriptionController,
        remarksController: line.remarksController,
        amount: amount,
        deleteEnabled:
            !controller.isSelectedOrderReadOnly && controller.lines.length > 1,
      );
    });

    return ErpLineItemTable(
      title: 'Lines',
      lines: rows,
      onChanged: (_) {},
      onAddLine: controller.isSelectedOrderReadOnly ? null : controller.addLine,
      onDeleteLine: controller.isSelectedOrderReadOnly
          ? null
          : controller.removeLine,
      addButtonLabel: 'Add Line',
      visibleColumns: const <ErpLineItemTableColumn>{
        ErpLineItemTableColumn.no,
        ErpLineItemTableColumn.item,
        ErpLineItemTableColumn.uom,
        ErpLineItemTableColumn.warehouse,
        ErpLineItemTableColumn.qty,
        ErpLineItemTableColumn.rate,
        ErpLineItemTableColumn.discount,
        ErpLineItemTableColumn.taxCode,
        ErpLineItemTableColumn.amount,
        ErpLineItemTableColumn.action,
      },
      columnLabels: const <ErpLineItemTableColumn, String>{
        ErpLineItemTableColumn.qty: 'Ordered Qty',
        ErpLineItemTableColumn.taxCode: 'Tax Code',
      },
      enabled: !controller.isSelectedOrderReadOnly,
      footer: GstSummaryCard(
        taxable: controller.orderTaxSummary().taxable,
        cgst: controller.orderTaxSummary().cgst,
        sgst: controller.orderTaxSummary().sgst,
        igst: controller.orderTaxSummary().igst,
        cess: controller.orderTaxSummary().cess,
        total:
            controller.orderTaxSummary().total +
            (controller.applyRoundOff
                ? (Validators.parseFlexibleNumber(
                        controller.roundOffController.text.trim(),
                      ) ??
                      0)
                : 0),
        currencyCode: 'INR',
        subtitle: (() {
          final roundOff = controller.applyRoundOff
              ? (Validators.parseFlexibleNumber(
                      controller.roundOffController.text.trim(),
                    ) ??
                    0)
              : 0;
          if (roundOff == 0) {
            return 'Live totals for the current purchase order lines.';
          }
          return 'Live totals for the current purchase order lines · includes round off ${roundOff.toStringAsFixed(2)}';
        })(),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    PurchaseOrderManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading purchase orders...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load purchase orders',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Purchase Orders',
      editorTitle: controller.selectedItem == null
          ? 'New Purchase Order'
          : stringValue(
              controller.selectedItem!.toJson(),
              'order_no',
              'Purchase Order',
            ),
      editorOnly: widget.editorOnly,
      scrollController: controller.pageScrollController,
      list: PurchaseListCard<PurchaseOrderModel>(
        items: controller.filteredItems,
        selectedItem: controller.selectedItem,
        emptyMessage: 'No purchase orders found.',
        searchController: controller.searchController,
        searchHint: 'Search orders',
        filterFields: [
          AppFormTextField(
            labelText: 'Search',
            controller: controller.searchController,
            hintText: 'Order no or supplier name',
          ),
          AppDropdownField<int?>.fromMapped(
            labelText: 'Supplier',
            mappedItems: [
              const AppDropdownItem<int?>(value: null, label: 'All Suppliers'),
              ...controller.suppliers
                  .where((item) => item.id != null)
                  .map(
                    (item) => AppDropdownItem<int?>(
                      value: item.id,
                      label: item.toString(),
                    ),
                  ),
            ],
            initialValue: controller.filterSupplierId,
            onChanged: controller.setFilterSupplierId,
          ),
          AppFormTextField(
            labelText: 'Date From',
            controller: controller.dateFromController,
            hintText: 'YYYY-MM-DD',
            keyboardType: TextInputType.datetime,
            inputFormatters: const [DateInputFormatter()],
            validator: Validators.optionalDate('Date From'),
          ),
          AppFormTextField(
            labelText: 'Date To',
            controller: controller.dateToController,
            hintText: 'YYYY-MM-DD',
            keyboardType: TextInputType.datetime,
            inputFormatters: const [DateInputFormatter()],
            validator: Validators.optionalDate('Date To'),
          ),
          AppActionButton(
            icon: Icons.clear_outlined,
            label: 'Clear',
            filled: false,
            onPressed: controller.clearFilters,
          ),
        ],
        statusValue: controller.statusFilter,
        statusItems: PurchaseOrderManagementController.statusItems,
        onStatusChanged: (value) => controller.setStatusFilter(value ?? ''),
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'order_no', 'Draft Order'),
            subtitle: [
              displayDate(nullableStringValue(data, 'order_date')),
              purchaseStatusLabel(nullableStringValue(data, 'order_status')),
            ].where((value) => value.isNotEmpty).join(' · '),
            detail: stringValue(data, 'supplier_name'),
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
            if (controller.selectionInfo != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppUiConstants.spacingSm),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(
                    AppUiConstants.cardRadius,
                  ),
                ),
                child: Text(controller.selectionInfo!),
              ),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            if (controller.isSelectedOrderReadOnly) ...[
              Text(
                purchaseReadOnlyMessage(
                  'purchase order',
                  nullableStringValue(
                    controller.selectedItem?.toJson() ?? const {},
                    'order_status',
                  ),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            IgnorePointer(
              ignoring: controller.isSelectedOrderReadOnly,
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
                        labelText: 'Order No',
                        controller: controller.orderNoController,
                        documentSeries: controller.seriesOptions(),
                        documentSeriesId: controller.documentSeriesId,
                        hintText: 'Auto-generated on save',
                        validator: Validators.optionalMaxLength(
                          100,
                          'Order No',
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Order Date',
                        controller: controller.orderDateController,
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateInputFormatter()],
                        validator: Validators.compose([
                          Validators.required('Order Date'),
                          Validators.date('Order Date'),
                        ]),
                      ),
                      AppFormTextField(
                        labelText: 'Expected Receipt Date',
                        controller: controller.expectedReceiptDateController,
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateInputFormatter()],
                        validator: Validators.compose([
                          Validators.optionalDate('Expected Receipt Date'),
                          Validators.optionalDateOnOrAfter(
                            'Expected Receipt Date',
                            () => controller.orderDateController.text.trim(),
                            startFieldName: 'Order Date',
                          ),
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
                        mappedItems: <AppDropdownItem<int>>[
                          const AppDropdownItem(
                            value: PurchaseOrderManagementController
                                .allSelectionId,
                            label: 'All',
                          ),
                          ...controller.filteredSupplierOptions
                              .where((item) => item.id != null)
                              .map(
                                (item) => AppDropdownItem(
                                  value: item.id!,
                                  label: item.toString(),
                                ),
                              ),
                        ],
                        initialValue: controller.supplierPartyId,
                        onChanged: controller.handleSupplierChanged,
                        validator: Validators.requiredSelection('Supplier'),
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Requisition',
                        mappedItems: <AppDropdownItem<int>>[
                          const AppDropdownItem(
                            value: PurchaseOrderManagementController
                                .allSelectionId,
                            label: 'All',
                          ),
                          ...controller.filteredRequisitionOptions
                              .where(
                                (item) => intValue(item.toJson(), 'id') != null,
                              )
                              .map(
                                (item) => AppDropdownItem(
                                  value: intValue(item.toJson(), 'id')!,
                                  label: stringValue(
                                    item.toJson(),
                                    'requisition_no',
                                    'Requisition',
                                  ),
                                ),
                              ),
                        ],
                        initialValue: controller.purchaseRequisitionId,
                        onChanged: controller.handleRequisitionChanged,
                      ),
                      AppFormTextField(
                        labelText: 'Supplier Ref No',
                        controller: controller.supplierReferenceNoController,
                        validator: Validators.optionalMaxLength(
                          100,
                          'Supplier Ref No',
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Supplier Ref Date',
                        controller: controller.supplierReferenceDateController,
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateInputFormatter()],
                        validator: Validators.optionalDate('Supplier Ref Date'),
                      ),
                      AppFormTextField(
                        labelText: 'Round off',
                        controller: controller.roundOffController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        enabled: controller.applyRoundOff,
                        validator: (value) {
                          final text = (value ?? '').trim();
                          if (text.isEmpty) {
                            return null;
                          }
                          return Validators.parseFlexibleNumber(text) == null
                              ? 'Round off must be a valid number'
                              : null;
                        },
                      ),
                      AppSwitchTile(
                        label: 'Apply round off',
                        value: controller.applyRoundOff,
                        onChanged: controller.setApplyRoundOff,
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
                  _buildLineItemTable(controller),
                ],
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                Builder(
                  builder: (_) {
                    final selectedData =
                        controller.selectedItem?.toJson() ??
                        const <String, dynamic>{};
                    final status = stringValue(
                      selectedData,
                      'order_status',
                    ).toLowerCase();
                    final canPreview =
                        controller.selectedItem != null &&
                        status != 'cancelled';
                    final canPost =
                        controller.selectedItem != null && status == 'draft';
                    final canClose =
                        controller.selectedItem != null &&
                        status != 'closed' &&
                        status != 'cancelled';
                    final canCancel =
                        controller.selectedItem != null &&
                        status != 'fully_received' &&
                        status != 'fully_invoiced' &&
                        status != 'closed' &&
                        status != 'cancelled';

                    return Wrap(
                      spacing: AppUiConstants.spacingSm,
                      runSpacing: AppUiConstants.spacingSm,
                      children: [
                        if (canPreview)
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
                        if (!controller.isSelectedOrderReadOnly)
                          AppActionButton(
                            icon: Icons.save_outlined,
                            label: controller.selectedItem == null
                                ? 'Save Order'
                                : 'Update Order',
                            onPressed: controller.canEditSelectedOrder
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
                              () => PurchaseService().postOrder(
                                intValue(
                                  controller.selectedItem!.toJson(),
                                  'id',
                                )!,
                                PurchaseOrderModel.fromJson(
                                  const <String, dynamic>{},
                                ),
                              ),
                            ),
                          ),
                        if (canClose)
                          AppActionButton(
                            icon: Icons.task_alt_outlined,
                            label: 'Close',
                            filled: false,
                            onPressed: () => controller.docAction(
                              context,
                              () => PurchaseService().closeOrder(
                                intValue(
                                  controller.selectedItem!.toJson(),
                                  'id',
                                )!,
                                PurchaseOrderModel.fromJson(
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
                            onPressed: () async {
                              final reason = await promptCancellationReason(
                                context,
                                title: 'Cancel order',
                                subjectLabel:
                                    controller.selectedItem?.toString() ??
                                    'this purchase order',
                              );
                              if (reason == null || !context.mounted) {
                                return;
                              }
                              await controller.docAction(
                                context,
                                () => PurchaseService().cancelOrder(
                                  intValue(
                                    controller.selectedItem!.toJson(),
                                    'id',
                                  )!,
                                  <String, dynamic>{'cancel_reason': reason},
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
