import '../../controller/sales/sales_delivery_management_controller.dart';
import '../../screen.dart';

class SalesDeliveryPage extends StatefulWidget {
  const SalesDeliveryPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

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
    );
    if (!Get.isRegistered<SalesDeliveryManagementController>(
      tag: _controllerTag,
    )) {
      Get.put(SalesDeliveryManagementController(), tag: _controllerTag);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_controller.initialize(initialId: widget.initialId));
    });
  }

  Future<void> _openPrintPreview(
    BuildContext context,
    SalesDeliveryManagementController controller,
  ) {
    return controller.openPrintPreview(context);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SalesDeliveryManagementController>(
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

  Widget _buildContent(
    BuildContext context,
    SalesDeliveryManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading sales deliveries...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load sales deliveries',
        message: controller.pageError!,
        onRetry: controller.loadPage,
      );
    }
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Sales Deliveries',
      editorTitle: controller.selectedItem == null
          ? 'New Sales Delivery'
          : stringValue(
              controller.selectedItem!.toJson(),
              'delivery_no',
              'Sales Delivery',
            ),
      editorOnly: widget.editorOnly,
      scrollController: controller.pageScrollController,
      list: PurchaseListCard<SalesDeliveryModel>(
        items: controller.filteredItems,
        selectedItem: controller.selectedItem,
        emptyMessage: 'No sales deliveries found.',
        searchController: controller.searchController,
        searchHint: 'Search deliveries',
        statusValue: controller.statusFilter,
        statusItems: SalesDeliveryManagementController.statusItems,
        onStatusChanged: (value) => controller.setStatusFilter(value ?? ''),
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'delivery_no', 'Draft Delivery'),
            subtitle: [
              displayDate(nullableStringValue(data, 'delivery_date')),
              stringValue(data, 'delivery_status'),
            ].where((value) => value.isNotEmpty).join(' · '),
            detail: quotationCustomerLabel(data),
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
            CrmSalesPipelineBar(data: controller.salesChain),
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
                  labelText: 'Delivery No',
                  controller: controller.deliveryNoController,
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
                AppDropdownField<int>.fromMapped(
                  labelText: 'Customer',
                  doctypeLabel: 'Customer',
                  allowCreate: true,
                  onNavigateToCreateNew: (name) {
                    final uri = Uri(
                      path: '/parties',
                      queryParameters: {
                        'new': '1',
                        if (name.trim().isNotEmpty) 'party_name': name.trim(),
                      },
                    );
                    openModuleShellRoute(context, uri.toString());
                  },
                  mappedItems: controller.customers
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: controller.customerPartyId,
                  onChanged: controller.setCustomerPartyId,
                  validator: Validators.requiredSelection('Customer'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Sales Order',
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
                  initialValue: controller.salesOrderId,
                  onChanged: (value) =>
                      unawaited(controller.applySalesOrderSelection(value)),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Transporter',
                  mappedItems: controller.allParties
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
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
                  onPressed: controller.addLine,
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
                        onChanged: (value) =>
                            controller.setLineItemId(index, value),
                        validator: (_) =>
                            line.itemId == null ? 'Item is required' : null,
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
                        onChanged: (value) => unawaited(
                          controller.setLineWarehouseId(index, value),
                        ),
                        validator: Validators.requiredSelection('Warehouse'),
                      ),
                      if (controller.isBatchManagedItem(line.itemId))
                        AppDropdownField<int>.fromMapped(
                          labelText: 'Batch',
                          mappedItems: controller
                              .batchOptionsForLine(line)
                              .map(
                                (batch) => AppDropdownItem<int>(
                                  value:
                                      int.tryParse(
                                        batch['batch_id']?.toString() ?? '',
                                      ) ??
                                      0,
                                  label: stringValue(
                                    batch,
                                    'batch_no',
                                    'Batch',
                                  ),
                                ),
                              )
                              .where((item) => item.value != 0)
                              .toList(growable: false),
                          initialValue: line.batchId,
                          onChanged: (value) => unawaited(
                            controller.setLineBatchId(index, value),
                          ),
                          validator: (_) {
                            if (!controller.isBatchManagedItem(line.itemId)) {
                              return null;
                            }
                            if (line.warehouseId == null) {
                              return 'Select warehouse first';
                            }
                            final batches = controller.batchOptionsForLine(
                              line,
                            );
                            if (batches.isEmpty) {
                              return 'No batches found for the selected warehouse';
                            }
                            return line.batchId == null
                                ? 'Batch is required'
                                : null;
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
                                controller.setLineUomId(index, value),
                            validator: (_) {
                              if (line.itemId == null) {
                                return 'Select item first';
                              }
                              return line.uomId == null
                                  ? 'UOM is required'
                                  : null;
                            },
                          );
                        },
                      ),
                      if (controller.isSerialManagedItem(line.itemId))
                        AppSerialNumbersField(
                          values: line.serialNumbers,
                          canOpen:
                              ((controller.isBatchManagedItem(line.itemId)
                                  ? line.batchId != null
                                  : line.warehouseId != null) ||
                              line.serialNumbers.isNotEmpty),
                          beforeOpen: () =>
                              controller.syncSerialOptionsForLine(line),
                          validator: (values) {
                            final serialOptions = controller
                                .serialOptionsForLine(line);
                            if (line.warehouseId == null) {
                              return 'Select warehouse first';
                            }
                            if (controller.isBatchManagedItem(line.itemId) &&
                                line.batchId == null) {
                              return 'Select batch first';
                            }
                            if (serialOptions.isEmpty) {
                              return 'No serials found in backend for the selected warehouse.';
                            }
                            final serialLabelSet = serialOptions
                                .map(
                                  (serial) =>
                                      (serial['serial_no']
                                          ?.toString()
                                          .trim()
                                          .toLowerCase() ??
                                      ''),
                                )
                                .where((value) => value.isNotEmpty)
                                .toSet();
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
                      AppFormTextField(
                        labelText: 'Delivered Qty',
                        controller: line.deliveredQtyController,
                        enabled: !controller.isSerialManagedItem(line.itemId),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (_) {
                          final text = line.deliveredQtyController.text.trim();
                          if (text.isEmpty) {
                            return 'Delivered Qty is required';
                          }
                          final qty = double.tryParse(text);
                          if (qty == null || qty < 0) {
                            return 'Delivered Qty must be a valid non-negative number';
                          }
                          if (qty <= 0) {
                            return 'Delivered Qty must be greater than zero';
                          }
                          if (controller.isSerialManagedItem(line.itemId)) {
                            final serialCount = controller
                                .lineSerialNumbers(line)
                                .length;
                            if (serialCount == 0) {
                              return 'Add at least one serial number';
                            }
                            if (qty != serialCount) {
                              return 'Qty must match serial count';
                            }
                          }
                          return null;
                        },
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
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                AppActionButton(
                  icon: Icons.print_outlined,
                  label: 'Print',
                  filled: false,
                  onPressed: () => _openPrintPreview(context, controller),
                ),
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: controller.selectedItem == null
                      ? 'Save Delivery'
                      : 'Update Delivery',
                  onPressed: () => controller.save(context),
                  busy: controller.saving,
                ),
                if (controller.selectedItem != null) ...[
                  AppActionButton(
                    icon: Icons.publish_outlined,
                    label: 'Post',
                    filled: false,
                    onPressed: () => controller.postSelected(context),
                  ),
                  AppActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Cancel',
                    filled: false,
                    onPressed: () => controller.cancelSelected(context),
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
