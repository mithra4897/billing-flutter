import '../../screen.dart';

class ProduceTrackingPage extends StatefulWidget {
  const ProduceTrackingPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<ProduceTrackingPage> createState() => _ProduceTrackingPageState();
}

class _ProduceTrackingPageState extends State<ProduceTrackingPage> {
  late final String _controllerTag;

  ProduceTrackingViewModel get _controller =>
      Get.find<ProduceTrackingViewModel>(tag: _controllerTag);

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'ProduceTrackingViewModel',
      scope: <String, Object?>{'identity': identityHashCode(this)},
    );
    Get.put(ProduceTrackingViewModel(initialId: widget.initialId), tag: _controllerTag);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        _controller.initialize(
          initialId: widget.initialId,
          editorOnly: widget.editorOnly,
        ),
      );
    });
  }

  @override
  void dispose() {
    Get.delete<ProduceTrackingViewModel>(tag: _controllerTag, force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProduceTrackingViewModel>(
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
            onPressed: controller.loading
                ? null
                : () {
                    controller.resetDraft();
                    if (!Responsive.isDesktop(context)) {
                      controller.workspaceController.openEditor();
                    }
                  },
            icon: Icons.add_outlined,
            label: 'New Produce Tracking',
          ),
        ];
        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Produce Tracking',
          scrollController: controller.pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Future<void> _openFilterPanel(
    BuildContext context,
    ProduceTrackingViewModel controller,
  ) {
    return openSalesSearchStatusFilterPanel(
      context: context,
      title: 'Filter Produce Tracking',
      searchController: controller.searchController,
      dateFromController: controller.dateFromController,
      dateToController: controller.dateToController,
      searchHint: 'Search by tracking no, location or vehicle',
      status: controller.statusFilter,
      statusItems: ProduceTrackingViewModel.listStatusFilter,
      onApply: (search, status, dateFrom, dateTo) {
        controller.searchController.text = search;
        controller.dateFromController.text = dateFrom;
        controller.dateToController.text = dateTo;
        controller.statusFilter = status;
        controller.applyFilters();
      },
      onClear: () {
        controller.searchController.clear();
        controller.dateFromController.clear();
        controller.dateToController.clear();
        controller.statusFilter = '';
        controller.applyFilters();
      },
    );
  }

  void _showActionSnackBar() {
    final message = _controller.consumeActionMessage();
    if (!mounted || message == null || message.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildContent(
    BuildContext context,
    ProduceTrackingViewModel controller,
  ) {
    if (controller.loading) {
      return const AppLoadingView(message: 'Loading produce tracking...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load produce tracking',
        message: controller.pageError!,
        onRetry: controller.reloadLastRequestedPage,
      );
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Produce Tracking',
      editorTitle: controller.selected?.toString() ?? 'New Produce Tracking',
      editorOnly: widget.editorOnly,
      scrollController: controller.pageScrollController,
      list: PurchaseListCard<ProduceTrackingModel>(
        items: controller.filteredItems,
        selectedItem: controller.selected,
        emptyMessage: 'No produce tracking records found.',
        searchController: controller.searchController,
        searchHint: 'Search produce tracking',
        statusValue: controller.statusFilter,
        statusItems: ProduceTrackingViewModel.listStatusFilter,
        onStatusChanged: (value) {
          controller.statusFilter = value ?? '';
          controller.applyFilters();
        },
        showInlineFilters: false,
        itemBuilder: (row, selected) {
          final data = row.toJson();
          final status = stringValue(data, 'tracking_status');
          final referenceFlow = stringValue(data, 'reference_flow', 'tracking');
          return SettingsListTile(
            title: stringValue(data, 'tracking_no', 'Draft Tracking'),
            subtitle: [
              'Date ${displayDate(nullableStringValue(data, 'tracking_date'))}',
              if (status.isNotEmpty) 'Status ${status.toUpperCase()}',
            ].where((value) => value.isNotEmpty).join(' · '),
            detail: JsonModel.combineValues(
              <String>[
                stringValue(data, 'current_location'),
                stringValue(data, 'destination_location'),
                stringValue(data, 'vehicle_no'),
              ],
              defaultValue: referenceFlow.replaceAll('_', ' '),
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  referenceFlow.replaceAll('_', ' ').toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (status.isNotEmpty)
                  Text(
                    status.replaceAll('_', ' '),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            selected: selected,
            onTap: () async {
              await controller.selectDocument(row);
              if (!context.mounted) {
                return;
              }
              if (!Responsive.isDesktop(context)) {
                controller.workspaceController.openEditor();
              }
            },
          );
        },
      ),
      editor: _ProduceTrackingEditor(
        vm: controller,
        onSave: (formContext) async {
          if (!(controller.formKey.currentState?.validate() ?? false)) {
            return;
          }
          await controller.save();
          _showActionSnackBar();
        },
        onPost: () async {
          await controller.post();
          _showActionSnackBar();
        },
        onCancel: () async {
          await controller.cancel();
          _showActionSnackBar();
        },
        onDelete: () async {
          await controller.delete();
          _showActionSnackBar();
        },
        onUpdateLocation: () async {
          await controller.updateLocation();
          _showActionSnackBar();
        },
      ),
    );
  }
}

class _ProduceTrackingEditor extends StatelessWidget {
  const _ProduceTrackingEditor({
    required this.vm,
    required this.onSave,
    required this.onPost,
    required this.onCancel,
    required this.onDelete,
    required this.onUpdateLocation,
  });

  final ProduceTrackingViewModel vm;
  final Future<void> Function(BuildContext formContext) onSave;
  final Future<void> Function() onPost;
  final Future<void> Function() onCancel;
  final Future<void> Function() onDelete;
  final Future<void> Function() onUpdateLocation;

  @override
  Widget build(BuildContext context) {
    if (vm.detailLoading) {
      return const AppLoadingView(message: 'Loading document...');
    }

    final canEdit = vm.status == 'draft' || vm.selected == null;
    final canUpdateLocation = vm.selected != null && vm.status != 'cancelled';
    final contextLabel = vm.contextLabels.isEmpty
        ? 'No working context selected'
        : vm.contextLabels.join(' / ');

    return Form(
      key: vm.formKey,
      child: Builder(
        builder: (formContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vm.formError != null) ...[
              AppErrorStateView.inline(message: vm.formError!),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Context'),
              child: Text(contextLabel),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            SettingsFormWrap(
              children: [
                DocumentSeriesSelector<int>(
                  labelText: 'Document Series',
                  mappedItems: vm.seriesOptions
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem<int>(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: vm.documentSeriesId,
                  onChanged: canEdit
                      ? (value) {
                          vm.documentSeriesId = value;
                          vm.update();
                        }
                      : null,
                ),
                AppFormTextField(
                  labelText: 'Tracking No',
                  controller: vm.trackingNoController,
                  hintText: 'Leave blank if series auto-generates',
                  enabled: canEdit,
                  validator: Validators.optionalMaxLength(100, 'Tracking No'),
                ),
                AppFormTextField(
                  labelText: 'Tracking Date',
                  controller: vm.trackingDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: canEdit,
                  validator: Validators.compose([
                    Validators.required('Tracking Date'),
                    Validators.date('Tracking Date'),
                  ]),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Reference Type',
                  mappedItems: produceTrackingFlowItems,
                  initialValue: vm.referenceFlow,
                  onChanged: canEdit ? vm.onReferenceFlowChanged : null,
                ),
                if (vm.referenceFlow == 'sales_delivery')
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Reference Document',
                    mappedItems: vm.salesDeliveryDropdownItems,
                    initialValue: vm.salesDeliveryId,
                    onChanged: canEdit
                        ? (value) {
                            unawaited(vm.onSalesDeliveryChanged(value));
                          }
                        : null,
                    validator: (_) {
                      if (vm.referenceFlow == 'sales_delivery' &&
                          vm.salesDeliveryId == null) {
                        return 'Sales Delivery is required';
                      }
                      return null;
                    },
                  ),
                if (vm.referenceFlow == 'purchase_order')
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Reference Document',
                    mappedItems: vm.purchaseOrderDropdownItems,
                    initialValue: vm.purchaseOrderId,
                    onChanged: canEdit
                        ? (value) {
                            unawaited(vm.onPurchaseOrderChanged(value));
                          }
                        : null,
                    validator: (_) {
                      if (vm.referenceFlow == 'purchase_order' &&
                          vm.purchaseOrderId == null) {
                        return 'Purchase Order is required';
                      }
                      return null;
                    },
                  ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Assigned To Type',
                  mappedItems: produceTrackingAssignedTypeItems,
                  initialValue: vm.assignedToType,
                  onChanged: canEdit ? vm.onAssignedToTypeChanged : null,
                ),
                if (vm.assignedToType == 'employee')
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Assigned To',
                    mappedItems: vm.employeeDropdownItems,
                    initialValue: vm.assignedEmployeeId,
                    onChanged: canEdit ? vm.onAssignedEmployeeChanged : null,
                    validator: (_) => vm.assignedEmployeeId == null
                        ? 'Employee is required'
                        : null,
                  ),
                if (vm.assignedToType == 'supplier')
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Assigned To',
                    mappedItems: vm.supplierDropdownItems,
                    initialValue: vm.assignedSupplierPartyId,
                    onChanged: canEdit ? vm.onAssignedSupplierChanged : null,
                    validator: (_) => vm.assignedSupplierPartyId == null
                        ? 'Supplier is required'
                        : null,
                  ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Transporter',
                  mappedItems: vm.transporterDropdownItems,
                  initialValue: vm.transporterId,
                  onChanged: canEdit ? vm.onTransporterChanged : null,
                ),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Delivery Mode'),
                  child: Text(
                    vm.transporterById(vm.transporterId)?.deliveryModeLabel ??
                        'Select a transporter',
                  ),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Source Warehouse',
                  mappedItems: vm.warehouseOptions
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem<int>(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: vm.sourceWarehouseId,
                  onChanged: canEdit ? vm.onSourceWarehouseChanged : null,
                  validator: Validators.requiredSelection('Source Warehouse'),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Tracking Status',
                  mappedItems: produceTrackingStatusItems,
                  initialValue: vm.trackingStatus,
                  onChanged: vm.onTrackingStatusChanged,
                ),
                AppFormTextField(
                  labelText: 'Remarks',
                  controller: vm.remarksController,
                  enabled: canEdit,
                  maxLines: 2,
                ),
                if (vm.showTransportDetails)
                  AppFormTextField(
                    labelText: 'Vehicle No',
                    controller: vm.vehicleNoController,
                    enabled: canEdit,
                  ),
                if (vm.showTransportDetails)
                  AppFormTextField(
                    labelText: 'Driver Name',
                    controller: vm.driverNameController,
                    enabled: canEdit,
                  ),
                if (vm.showTransportDetails)
                  AppFormTextField(
                    labelText: 'Driver Phone',
                    controller: vm.driverPhoneController,
                    enabled: canEdit,
                  ),
                if (vm.showTransportDetails)
                  AppFormTextField(
                    labelText: 'LR No',
                    controller: vm.lrNoController,
                    enabled: canEdit,
                  ),
                if (vm.showTransportDetails)
                  AppFormTextField(
                    labelText: 'LR Date',
                    controller: vm.lrDateController,
                    keyboardType: TextInputType.datetime,
                    inputFormatters: const [DateInputFormatter()],
                    enabled: canEdit,
                    validator: Validators.optionalDate('LR Date'),
                  ),
                if (vm.showTransportDetails)
                  AppFormTextField(
                    labelText: 'Current Location',
                    controller: vm.currentLocationController,
                  ),
                if (vm.showTransportDetails)
                  AppFormTextField(
                    labelText: 'Current Latitude',
                    controller: vm.currentLatitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                if (vm.showTransportDetails)
                  AppFormTextField(
                    labelText: 'Current Longitude',
                    controller: vm.currentLongitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSwitchTile(
              label: 'Active',
              value: vm.isActive,
              onChanged: canEdit ? vm.onIsActiveChanged : null,
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Row(
              children: [
                Text(
                  'Tracked Items',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                AppActionButton(
                  icon: Icons.add_outlined,
                  label: 'Add line',
                  filled: false,
                  onPressed: canEdit ? vm.addLine : null,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            if (vm.lines.isEmpty)
              const Text('No line items added.')
            else
              ...List<Widget>.generate(vm.lines.length, (index) {
                final line = vm.lines[index];
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppUiConstants.spacingSm,
                  ),
                  child: PurchaseCompactLineCard(
                    index: index,
                    total: vm.lines.length,
                    removeEnabled: canEdit && vm.lines.length > 1,
                    onRemove: canEdit ? () => vm.removeLine(index) : null,
                    child: PurchaseCompactFieldGrid(
                      children: [
                        AppSearchPickerField<int>(
                          labelText: 'Item',
                          selectedLabel: vm.itemById(line.itemId)?.toString(),
                          options: vm.items
                              .where((item) => item.id != null)
                              .map(
                                (item) => AppSearchPickerOption<int>(
                                  value: item.id!,
                                  label: item.toString(),
                                  subtitle: item.itemCode,
                                ),
                              )
                              .toList(growable: false),
                          validator: (_) =>
                              line.itemId == null ? 'Item is required' : null,
                          onChanged: (value) {
                            if (!canEdit) {
                              return;
                            }
                            vm.onLineItemChanged(index, value);
                          },
                        ),
                        AppDropdownField<int>.fromMapped(
                          labelText: 'Warehouse',
                          mappedItems: vm.warehouseOptions
                              .where((item) => item.id != null)
                              .map(
                                (item) => AppDropdownItem<int>(
                                  value: item.id!,
                                  label: item.toString(),
                                ),
                              )
                              .toList(growable: false),
                          initialValue: line.warehouseId,
                          validator: Validators.requiredSelection('Warehouse'),
                          onChanged: canEdit
                              ? (value) =>
                                  vm.onLineWarehouseChanged(index, value)
                              : null,
                        ),
                        AppDropdownField<int>.fromMapped(
                          labelText: 'UOM',
                          mappedItems: vm.uomOptionsForItem(line.itemId)
                              .where((item) => item.id != null)
                              .map(
                                (item) => AppDropdownItem<int>(
                                  value: item.id!,
                                  label: item.toString(),
                                ),
                              )
                              .toList(growable: false),
                          initialValue: line.uomId,
                          validator: Validators.requiredSelection('UOM'),
                          onChanged: canEdit
                              ? (value) => vm.onLineUomChanged(index, value)
                              : null,
                        ),
                        if (vm.itemHasBatch(line.itemId))
                          AppDropdownField<int>.fromMapped(
                            labelText: 'Batch',
                            mappedItems: vm.batchOptionsForLine(line)
                                .map(
                                  (item) => AppDropdownItem<int>(
                                    value: intValue(item, 'id')!,
                                    label: stringValue(
                                      item,
                                      'batch_no',
                                      'Batch',
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            initialValue: line.batchId,
                            onChanged: canEdit
                                ? (value) => vm.onLineBatchChanged(index, value)
                                : null,
                          ),
                        if (vm.itemHasSerial(line.itemId))
                          AppDropdownField<int>.fromMapped(
                            labelText: 'Serial',
                            mappedItems: vm.serialOptionsForLine(line)
                                .map(
                                  (item) => AppDropdownItem<int>(
                                    value: intValue(item, 'id')!,
                                    label: stringValue(
                                      item,
                                      'serial_no',
                                      'Serial',
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            initialValue: line.serialId,
                            onChanged: canEdit
                                ? (value) =>
                                    vm.onLineSerialChanged(index, value)
                                : null,
                          ),
                        AppFormTextField(
                          labelText: 'Qty',
                          controller: line.trackedQtyController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          enabled: canEdit,
                          validator: Validators.requiredPositiveNumber(
                            'Qty',
                          ),
                        ),
                        AppFormTextField(
                          labelText: 'Remarks',
                          controller: line.remarksController,
                          maxLines: 2,
                          enabled: canEdit,
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
                  icon: Icons.save_outlined,
                  label: vm.selected == null ? 'Save' : 'Update',
                  busy: vm.saving,
                  onPressed: canEdit ? () => onSave(formContext) : null,
                ),
                if (vm.selected != null && vm.status == 'draft') ...[
                  AppActionButton(
                    icon: Icons.publish_outlined,
                    label: 'Post',
                    filled: false,
                    onPressed: onPost,
                  ),
                  AppActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    filled: false,
                    onPressed: onDelete,
                  ),
                  AppActionButton(
                    icon: Icons.block_outlined,
                    label: 'Cancel',
                    filled: false,
                    onPressed: onCancel,
                  ),
                ],
                if (canUpdateLocation)
                  AppActionButton(
                    icon: Icons.location_on_outlined,
                    label: 'Update Location',
                    filled: false,
                    onPressed: onUpdateLocation,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
