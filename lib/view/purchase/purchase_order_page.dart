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
      scope: <String, Object?>{'identity': identityHashCode(this)},
    );
    Get.put(PurchaseOrderManagementController(), tag: _controllerTag);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_controller.initialize(initialId: widget.initialId));
    });
  }

  @override
  void dispose() {
    Get.delete<PurchaseOrderManagementController>(
      tag: _controllerTag,
      force: true,
    );
    super.dispose();
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
    final taxSummary = controller.orderTaxSummary();
    final currency = controller.currencyCodeController.text.trim().isEmpty
        ? 'INR'
        : controller.currencyCodeController.text.trim();
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
      editor: Form(
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
                AppDropdownField<int>.fromMapped(
                  labelText: 'Financial Year',
                  mappedItems: controller.financialYears
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: controller.financialYearId,
                  onChanged: controller.setFinancialYearId,
                  validator: Validators.requiredSelection('Financial Year'),
                ),
                AppDropdownField<int>.fromMapped(
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
                AppFormTextField(
                  labelText: 'Order No',
                  controller: controller.orderNoController,
                  hintText: 'Auto-generated on save',
                  validator: Validators.optionalMaxLength(100, 'Order No'),
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
                  mappedItems: <AppDropdownItem<int>>[
                    const AppDropdownItem(
                      value: PurchaseOrderManagementController.allSelectionId,
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
                      value: PurchaseOrderManagementController.allSelectionId,
                      label: 'All',
                    ),
                    ...controller.filteredRequisitionOptions
                        .where((item) => intValue(item.toJson(), 'id') != null)
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
                  labelText: 'Currency',
                  controller: controller.currencyCodeController,
                  validator: Validators.optionalMaxLength(10, 'Currency'),
                ),
                AppFormTextField(
                  labelText: 'Exchange Rate',
                  controller: controller.exchangeRateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Exchange Rate',
                  ),
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
                  Row(
                    children: [
                      Text(
                        'Lines',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      AppActionButton(
                        icon: Icons.add_outlined,
                        label: 'Add Line',
                        onPressed: controller.isSelectedOrderReadOnly
                            ? null
                            : controller.addLine,
                        filled: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppUiConstants.spacingSm),
                  ...List<Widget>.generate(controller.lines.length, (index) {
              final line = controller.lines[index];
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: AppUiConstants.spacingSm,
                ),
                child: PurchaseCompactLineCard(
                  index: index,
                  total: controller.lines.length,
                  removeEnabled: controller.lines.length > 1,
                  onRemove: () => controller.removeLine(index),
                  child: PurchaseCompactFieldGrid(
                    children: [
                      AppSearchPickerField<int>(
                        labelText: 'Item',
                        selectedLabel: controller.itemsLookup
                            .cast<ItemModel?>()
                            .firstWhere(
                              (item) => item?.id == line.itemId,
                              orElse: () => null,
                            )
                            ?.toString(),
                        options: controller.purchasableItemOptions
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppSearchPickerOption<int>(
                                value: item.id!,
                                label: item.toString(),
                                subtitle: item.itemCode,
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) =>
                            controller.setLineItemId(line, value),
                        validator: (_) => Validators.requiredSelectionField(
                          line.itemId,
                          'Item',
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          final options = controller.uomOptionsForItem(
                            line.itemId,
                          );
                          if (options.length == 1) {
                            final onlyId = options.first.id;
                            if (line.uomId != onlyId) {
                              line.uomId = onlyId;
                            }
                          }
                          return AppDropdownField<int>.fromMapped(
                            labelText: 'UOM',
                            mappedItems: options
                                .where((item) => item.id != null)
                                .map(
                                  (item) => AppDropdownItem(
                                    value: item.id!,
                                    label: item.toString(),
                                  ),
                                )
                                .toList(growable: false),
                            initialValue: line.uomId,
                            onChanged: (value) =>
                                controller.setLineUomId(line, value),
                            validator: (_) =>
                                Validators.dependentSelectionField(
                                  prerequisite: line.itemId,
                                  prerequisiteName: 'item',
                                  value: line.uomId,
                                  fieldName: 'UOM',
                                ),
                          );
                        },
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
                        initialValue: line.warehouseId,
                        onChanged: (value) =>
                            controller.setLineWarehouseId(line, value),
                      ),
                      AppFormTextField(
                        labelText: 'Ordered Qty',
                        controller: line.qtyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.compose([
                          Validators.required('Ordered Qty'),
                          Validators.optionalNonNegativeNumber('Ordered Qty'),
                        ]),
                      ),
                      AppFormTextField(
                        labelText: 'Rate',
                        controller: line.rateController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.compose([
                          Validators.required('Rate'),
                          Validators.optionalNonNegativeNumber('Rate'),
                        ]),
                      ),
                      AppFormTextField(
                        labelText: 'Discount %',
                        controller: line.discountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.optionalNonNegativeNumber(
                          'Discount %',
                        ),
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'Tax Code',
                        mappedItems: controller.taxCodes
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem(
                                value: item.id!,
                                label: item.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: line.taxCodeId,
                        onChanged: (value) =>
                            controller.setLineTaxCodeId(line, value),
                      ),
                      AppFormTextField(
                        labelText: 'Description',
                        controller: line.descriptionController,
                      ),
                      AppFormTextField(
                        labelText: 'Remarks',
                        controller: line.remarksController,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              );
            }),
                  const SizedBox(height: AppUiConstants.spacingMd),
                  GstSummaryCard(
                    taxable: taxSummary.taxable,
                    cgst: taxSummary.cgst,
                    sgst: taxSummary.sgst,
                    igst: taxSummary.igst,
                    cess: 0,
                    total: taxSummary.total,
                    currencyCode: currency,
                    subtitle: 'Live totals for the current purchase order lines.',
                  ),
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
                    final status = stringValue(selectedData, 'order_status');
                    final canPost =
                        controller.selectedItem != null && status == 'draft';
                    final canClose = controller.selectedItem != null &&
                        status != 'closed' &&
                        status != 'cancelled';
                    final canCancel = controller.selectedItem != null &&
                        status != 'fully_received' &&
                        status != 'fully_invoiced' &&
                        status != 'closed' &&
                        status != 'cancelled';

                    return Wrap(
                      spacing: AppUiConstants.spacingSm,
                      runSpacing: AppUiConstants.spacingSm,
                      children: [
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
                            onPressed: () => controller.docAction(
                              context,
                              () => PurchaseService().cancelOrder(
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
