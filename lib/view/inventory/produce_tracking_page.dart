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
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final String _controllerTag;
  late final ProduceTrackingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('ProduceTrackingViewModel');
    _viewModel = Get.put(
      ProduceTrackingViewModel(initialId: widget.initialId)
        ..load(selectId: widget.initialId),
      tag: _controllerTag,
      permanent: true,
    );
  }

  @override
  void dispose() {
    _workspaceController.dispose();
    _pageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProduceTrackingViewModel>(
      tag: _controllerTag,
      builder: (_) {
        final content = _buildContent(context);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: _viewModel.loading
                ? null
                : () {
                    _viewModel.resetDraft();
                    if (!Responsive.isDesktop(context)) {
                      _workspaceController.openEditor();
                    }
                  },
            icon: Icons.add_outlined,
            label: 'New Produce Tracking',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Produce Tracking',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  void _showActionSnackBar() {
    final message = _viewModel.consumeActionMessage();
    if (!mounted || message == null || message.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading produce tracking...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load produce tracking',
        message: _viewModel.pageError!,
        onRetry: () => _viewModel.load(selectId: widget.initialId),
      );
    }

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Produce Tracking',
      editorTitle:
          _viewModel.selected?.toString() ?? 'New Produce Tracking',
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<ProduceTrackingModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search produce tracking',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No produce tracking records found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: stringValue(row.toJson(), 'tracking_no', 'Draft'),
          subtitle: [
            displayDate(nullableStringValue(row.toJson(), 'tracking_date')),
            stringValue(row.toJson(), 'tracking_status'),
          ].where((v) => v.trim().isNotEmpty).join(' · '),
          detail: stringValue(
            row.toJson(),
            'current_location',
            stringValue(row.toJson(), 'destination_location'),
          ),
          selected: selected,
          onTap: () async {
            await _viewModel.select(row);
            if (!context.mounted) {
              return;
            }
            if (!Responsive.isDesktop(context)) {
              _workspaceController.openEditor();
            }
          },
        ),
      ),
      editor: _ProduceTrackingEditor(
        vm: _viewModel,
        onSave: (formContext) async {
          if (!Form.of(formContext).validate()) {
            return;
          }
          await _viewModel.save();
          _showActionSnackBar();
        },
        onPost: () async {
          await _viewModel.post();
          _showActionSnackBar();
        },
        onCancel: () async {
          await _viewModel.cancel();
          _showActionSnackBar();
        },
        onDelete: () async {
          await _viewModel.delete();
          _showActionSnackBar();
        },
        onUpdateLocation: () async {
          await _viewModel.updateLocation();
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
                    onChanged: canEdit ? vm.onSalesDeliveryChanged : null,
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
                    onChanged: canEdit ? vm.onPurchaseOrderChanged : null,
                    validator: (_) {
                      if (vm.referenceFlow == 'purchase_order' &&
                          vm.purchaseOrderId == null) {
                        return 'Purchase Order is required';
                      }
                      return null;
                    },
                  ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Assigned To',
                  mappedItems: vm.partyDropdownItems,
                  initialValue: vm.destinationPartyId,
                  onChanged: canEdit ? vm.onDestinationPartyChanged : null,
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
                AppFormTextField(
                  labelText: 'Vehicle No',
                  controller: vm.vehicleNoController,
                  enabled: canEdit,
                ),
                AppFormTextField(
                  labelText: 'Driver Name',
                  controller: vm.driverNameController,
                  enabled: canEdit,
                ),
                AppFormTextField(
                  labelText: 'Driver Phone',
                  controller: vm.driverPhoneController,
                  enabled: canEdit,
                ),
                AppFormTextField(
                  labelText: 'LR No',
                  controller: vm.lrNoController,
                  enabled: canEdit,
                ),
                AppFormTextField(
                  labelText: 'LR Date',
                  controller: vm.lrDateController,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  enabled: canEdit,
                  validator: Validators.optionalDate('LR Date'),
                ),
                AppDropdownField<String>.fromMapped(
                  labelText: 'Tracking Status',
                  mappedItems: produceTrackingStatusItems,
                  initialValue: vm.trackingStatus,
                  onChanged: vm.onTrackingStatusChanged,
                ),
                AppFormTextField(
                  labelText: 'Current Location',
                  controller: vm.currentLocationController,
                ),
                AppFormTextField(
                  labelText: 'Current Latitude',
                  controller: vm.currentLatitudeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                AppFormTextField(
                  labelText: 'Current Longitude',
                  controller: vm.currentLongitudeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                AppFormTextField(
                  labelText: 'Remarks',
                  controller: vm.remarksController,
                  enabled: canEdit,
                  maxLines: 2,
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
                          labelText: 'Tracked Qty',
                          controller: line.trackedQtyController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          enabled: canEdit,
                          validator: Validators.requiredPositiveNumber(
                            'Tracked Qty',
                          ),
                        ),
                        AppFormTextField(
                          labelText: 'Balance Qty',
                          controller: line.balanceQtyController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          enabled: canEdit,
                          validator: Validators.optionalNonNegativeNumber(
                            'Balance Qty',
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
