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
      scope: <String, Object?>{'identity': identityHashCode(this)},
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
                  labelText: 'Receipt No',
                  controller: controller.receiptNoController,
                  hintText: 'Auto-generated on save',
                  validator: Validators.optionalMaxLength(100, 'Receipt No'),
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
                  mappedItems: controller.orders
                      .where((item) => intValue(item.toJson(), 'id') != null)
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
                  validator: Validators.requiredSelection('Warehouse'),
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
                  validator: Validators.optionalDate('Supplier Invoice Date'),
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
                        onPressed: controller.isSelectedReceiptReadOnly
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
                        options: controller.itemsLookup
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppSearchPickerOption<int>(
                                value: item.id!,
                                label: item.toString(),
                                subtitle: item.itemCode,
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) async {
                          await controller.setLineItemId(line, value);
                        },
                        validator: (_) => Validators.requiredSelectionField(
                          line.itemId,
                          'Item',
                        ),
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
                        onChanged: (value) async {
                          await controller.setLineWarehouseId(line, value);
                        },
                        validator: Validators.requiredSelection('Warehouse'),
                      ),
                      if (controller.isSerialManagedItem(line.itemId))
                        Builder(
                          builder: (context) {
                            final serialOptions = controller
                                .serialOptionsForLine(line);
                            return AppDropdownField<int>.fromMapped(
                              labelText: 'Serial Number',
                              mappedItems: serialOptions
                                  .where(
                                    (serial) =>
                                        intValue(serial.toJson(), 'id') != null,
                                  )
                                  .map(
                                    (serial) => AppDropdownItem<int>(
                                      value: intValue(serial.toJson(), 'id')!,
                                      label: stringValue(
                                        serial.toJson(),
                                        'serial_no',
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                              initialValue: line.serialId,
                              onChanged: (value) =>
                                  controller.setLineSerialId(line, value),
                              validator: (_) {
                                final dependencyError =
                                    Validators.dependentSelectionField(
                                      prerequisite: line.warehouseId,
                                      prerequisiteName: 'warehouse',
                                      value: line.serialId,
                                      fieldName: 'Serial number',
                                    );
                                if (dependencyError != null &&
                                    line.warehouseId == null) {
                                  return dependencyError;
                                }
                                if (serialOptions.isEmpty) {
                                  return 'No serial is available for the selected warehouse';
                                }
                                return dependencyError;
                              },
                            );
                          },
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
                      AppFormTextField(
                        labelText: 'Received Qty',
                        controller: line.receivedQtyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.compose([
                          Validators.required('Received Qty'),
                          Validators.optionalNonNegativeNumber('Received Qty'),
                        ]),
                      ),
                      AppFormTextField(
                        labelText: 'Accepted Qty',
                        controller: line.acceptedQtyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.optionalNonNegativeNumber(
                          'Accepted Qty',
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Rejected Qty',
                        controller: line.rejectedQtyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.optionalNonNegativeNumber(
                          'Rejected Qty',
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Rate',
                        controller: line.rateController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.optionalNonNegativeNumber('Rate'),
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
                ],
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
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
                if (controller.selectedItem != null) ...[
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
