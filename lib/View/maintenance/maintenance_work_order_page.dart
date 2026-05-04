import '../../screen.dart';
import '../../view_model/maintenance/maintenance_work_order_view_model.dart';

class MaintenanceWorkOrderPage extends StatefulWidget {
  const MaintenanceWorkOrderPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<MaintenanceWorkOrderPage> createState() =>
      _MaintenanceWorkOrderPageState();
}

class _MaintenanceWorkOrderPageState extends State<MaintenanceWorkOrderPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final MaintenanceWorkOrderViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MaintenanceWorkOrderViewModel()
      ..load(selectId: widget.initialId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _pageScrollController.dispose();
    _workspaceController.dispose();
    super.dispose();
  }

  void _openRoute(String route) {
    final navigate = ShellRouteScope.maybeOf(context);
    if (navigate != null) {
      navigate(route);
      return;
    }
    Navigator.of(context).pushNamed(route);
  }

  void _snack() {
    final msg = _viewModel.consumeActionMessage();
    if (!mounted || msg == null || msg.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete work order'),
        content: const Text(
          'Only draft work orders can be deleted. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      return;
    }
    await _viewModel.deleteWorkOrder();
    _snack();
    _openRoute('/maintenance/work-orders');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: _viewModel.loading
                ? null
                : () {
                    _viewModel.resetDraft();
                    _openRoute('/maintenance/work-orders/new');
                    if (!Responsive.isDesktop(context)) {
                      _workspaceController.openEditor();
                    }
                  },
            icon: Icons.add_outlined,
            label: 'New work order',
          ),
        ];
        final content = _buildContent(context);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Maintenance work orders',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading work orders...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load work orders',
        message: _viewModel.pageError!,
        onRetry: () => _viewModel.load(selectId: widget.initialId),
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Maintenance work orders',
      editorTitle: _viewModel.selected == null
          ? 'New maintenance work order'
          : _viewModel.listTitle(_viewModel.selected!),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<MaintenanceWorkOrderModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search no., status, type, asset',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No maintenance work orders found.',
        itemBuilder: (row, selected) {
          final data = row.toJson();
          return SettingsListTile(
            title: _viewModel.listTitle(row),
            subtitle: [
              stringValue(data, 'work_order_status'),
              stringValue(data, 'work_order_type'),
              _viewModel.listAssetSubtitle(data),
            ].where((v) => v.trim().isNotEmpty).join(' · '),
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
          );
        },
      ),
      editor: _MaintenanceWorkOrderEditor(
        vm: _viewModel,
        onSave: (formContext) async {
          if (!Form.of(formContext).validate()) {
            return;
          }
          await _viewModel.save();
          _snack();
        },
        onApprove: () async {
          await _viewModel.approveWorkOrder();
          _snack();
        },
        onStart: () async {
          await _viewModel.startWorkOrder();
          _snack();
        },
        onComplete: () async {
          await _viewModel.completeWorkOrder();
          _snack();
        },
        onClose: () async {
          await _viewModel.closeWorkOrder();
          _snack();
        },
        onCancel: () async {
          await _viewModel.cancelWorkOrder();
          _snack();
        },
        onDelete: _confirmDelete,
      ),
    );
  }
}

class _MaintenanceWorkOrderEditor extends StatelessWidget {
  const _MaintenanceWorkOrderEditor({
    required this.vm,
    required this.onSave,
    required this.onApprove,
    required this.onStart,
    required this.onComplete,
    required this.onClose,
    required this.onCancel,
    required this.onDelete,
  });

  final MaintenanceWorkOrderViewModel vm;
  final Future<void> Function(BuildContext formContext) onSave;
  final Future<void> Function() onApprove;
  final Future<void> Function() onStart;
  final Future<void> Function() onComplete;
  final Future<void> Function() onClose;
  final Future<void> Function() onCancel;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    if (vm.detailLoading) {
      return const AppLoadingView(message: 'Loading document...');
    }

    final theme = Theme.of(context);
    final detail = vm.selected?.toJson();
    final spare = detail == null
        ? ''
        : stringValue(detail, 'spare_cost');
    final extSvc = detail == null
        ? ''
        : stringValue(detail, 'external_service_cost');
    final total = detail == null ? '' : stringValue(detail, 'total_cost');

    return Form(
      child: Builder(
        builder: (formContext) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (vm.formError != null) ...[
                AppErrorStateView.inline(message: vm.formError!),
                const SizedBox(height: AppUiConstants.spacingSm),
              ],
              if (vm.selected != null) ...[
                Wrap(
                  spacing: AppUiConstants.spacingSm,
                  runSpacing: AppUiConstants.spacingSm,
                  children: [
                    if (vm.canApprove)
                      FilledButton(
                        onPressed: vm.saving ? null : () => onApprove(),
                        child: const Text('Approve'),
                      ),
                    if (vm.canStart)
                      FilledButton.tonal(
                        onPressed: vm.saving ? null : () => onStart(),
                        child: const Text('Start'),
                      ),
                    if (vm.canComplete)
                      FilledButton.tonal(
                        onPressed: vm.saving ? null : () => onComplete(),
                        child: const Text('Complete'),
                      ),
                    if (vm.canClose)
                      FilledButton.tonal(
                        onPressed: vm.saving ? null : () => onClose(),
                        child: const Text('Close'),
                      ),
                    if (vm.canCancel)
                      FilledButton.tonal(
                        onPressed: vm.saving ? null : () => onCancel(),
                        child: const Text('Cancel WO'),
                      ),
                  ],
                ),
                const SizedBox(height: AppUiConstants.spacingMd),
              ],
              SettingsFormWrap(
                children: [
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Company',
                    mappedItems: vm.companies
                        .where((c) => c.id != null)
                        .map(
                          (c) => AppDropdownItem<int>(
                            value: c.id!,
                            label: c.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.companyId,
                    onChanged: (int? v) {
                      if (vm.canEdit) {
                        vm.setCompanyId(v);
                      }
                    },
                    validator: Validators.requiredSelection('Company'),
                  ),
                  if (vm.selected == null) ...[
                    AppDropdownField<int?>.fromMapped(
                      labelText: 'Document series (for auto no.)',
                      mappedItems: [
                        const AppDropdownItem<int?>(
                          value: null,
                          label: '—',
                        ),
                        ...vm.seriesOptions
                            .where((s) => s.id != null)
                            .map(
                              (s) => AppDropdownItem<int?>(
                                value: s.id,
                                label: s.toString(),
                              ),
                            ),
                      ],
                      initialValue: vm.documentSeriesId,
                      onChanged: (int? v) {
                        if (vm.canEdit) {
                          vm.setDocumentSeriesId(v);
                        }
                      },
                    ),
                    AppFormTextField(
                      labelText: 'Work order no. (or use series)',
                      controller: vm.workOrderNoController,
                    ),
                  ] else
                    AppFormTextField(
                      labelText: 'Work order no.',
                      controller: vm.workOrderNoController,
                      readOnly: true,
                    ),
                  AppFormTextField(
                    labelText: 'Work order date',
                    controller: vm.workOrderDateController,
                    readOnly: !vm.canEdit,
                    validator: Validators.required('Work order date'),
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Asset',
                    mappedItems: vm.assets
                        .map(
                          (a) => AppDropdownItem<int>(
                            value: intValue(a.toJson(), 'id')!,
                            label: vm.assetPickerLabel(a),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.assetId,
                    onChanged: (int? v) {
                      if (vm.canEdit) {
                        vm.setAssetId(v);
                      }
                    },
                    validator: Validators.requiredSelection('Asset'),
                  ),
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Branch',
                    mappedItems: [
                      const AppDropdownItem<int?>(
                        value: null,
                        label: '—',
                      ),
                      ...vm.branchOptions
                          .where((b) => b.id != null)
                          .map(
                            (b) => AppDropdownItem<int?>(
                              value: b.id,
                              label: b.toString(),
                            ),
                          ),
                    ],
                    initialValue: vm.branchId,
                    onChanged: (int? v) {
                      if (vm.canEdit) {
                        vm.setBranchId(v);
                      }
                    },
                  ),
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Location',
                    mappedItems: [
                      const AppDropdownItem<int?>(
                        value: null,
                        label: '—',
                      ),
                      ...vm.locationOptions
                          .where((l) => l.id != null)
                          .map(
                            (l) => AppDropdownItem<int?>(
                              value: l.id,
                              label: l.toString(),
                            ),
                          ),
                    ],
                    initialValue: vm.locationId,
                    onChanged: (int? v) {
                      if (vm.canEdit) {
                        vm.setLocationId(v);
                      }
                    },
                  ),
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Financial year',
                    mappedItems: [
                      const AppDropdownItem<int?>(
                        value: null,
                        label: '—',
                      ),
                      ...vm.financialYearOptions
                          .where((fy) => fy.id != null)
                          .map(
                            (fy) => AppDropdownItem<int?>(
                              value: fy.id,
                              label: fy.toString(),
                            ),
                          ),
                    ],
                    initialValue: vm.financialYearId,
                    onChanged: (int? v) {
                      if (vm.canEdit) {
                        vm.setFinancialYearId(v);
                      }
                    },
                  ),
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Maintenance request',
                    mappedItems: [
                      const AppDropdownItem<int?>(
                        value: null,
                        label: '—',
                      ),
                      ...vm.maintenanceRequests
                          .where((r) => intValue(r.toJson(), 'id') != null)
                          .map(
                            (r) => AppDropdownItem<int?>(
                              value: intValue(r.toJson(), 'id'),
                              label: vm.requestListLabel(r),
                            ),
                          ),
                    ],
                    initialValue: vm.maintenanceRequestId,
                    onChanged: (int? v) {
                      if (vm.canEdit) {
                        vm.setMaintenanceRequestId(v);
                      }
                    },
                  ),
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Maintenance plan',
                    mappedItems: [
                      const AppDropdownItem<int?>(
                        value: null,
                        label: '—',
                      ),
                      ...vm.maintenancePlans
                          .where((p) => intValue(p.toJson(), 'id') != null)
                          .map((p) {
                            final d = p.toJson();
                            final code = stringValue(d, 'plan_code');
                            final name = stringValue(d, 'plan_name');
                            final label = [code, name]
                                .where((x) => x.trim().isNotEmpty)
                                .join(' — ');
                            return AppDropdownItem<int?>(
                              value: intValue(d, 'id'),
                              label: label.isNotEmpty
                                  ? label
                                  : 'Plan #${intValue(d, 'id')}',
                            );
                          }),
                    ],
                    initialValue: vm.maintenancePlanId,
                    onChanged: (int? v) {
                      if (vm.canEdit) {
                        vm.setMaintenancePlanId(v);
                      }
                    },
                  ),
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Vendor',
                    mappedItems: [
                      const AppDropdownItem<int?>(
                        value: null,
                        label: '—',
                      ),
                      ...vm.vendorOptions
                          .where((p) => p.id != null)
                          .map(
                            (p) => AppDropdownItem<int?>(
                              value: p.id,
                              label: p.toString(),
                            ),
                          ),
                    ],
                    initialValue: vm.vendorPartyId,
                    onChanged: (int? v) {
                      if (vm.canEdit) {
                        vm.setVendorPartyId(v);
                      }
                    },
                  ),
                  AppFormTextField(
                    labelText: 'Work order type',
                    controller: vm.workOrderTypeController,
                    readOnly: !vm.canEdit,
                  ),
                  AppFormTextField(
                    labelText: 'Execution mode',
                    controller: vm.executionModeController,
                    readOnly: !vm.canEdit,
                  ),
                  AppFormTextField(
                    labelText: 'Assigned technician',
                    controller: vm.assignedTechnicianController,
                    readOnly: !vm.canEdit,
                  ),
                  AppFormTextField(
                    labelText: 'Assigned team',
                    controller: vm.assignedTeamController,
                    readOnly: !vm.canEdit,
                  ),
                  AppFormTextField(
                    labelText: 'Fault description',
                    controller: vm.faultDescriptionController,
                    maxLines: 3,
                    readOnly: !vm.canEdit,
                  ),
                  AppFormTextField(
                    labelText: 'Action taken',
                    controller: vm.actionTakenController,
                    maxLines: 3,
                    readOnly: !vm.canEdit,
                  ),
                  AppFormTextField(
                    labelText: 'Resolution summary',
                    controller: vm.resolutionSummaryController,
                    maxLines: 3,
                    readOnly: !vm.canEdit,
                  ),
                  AppFormTextField(
                    labelText: 'Planned start (ISO datetime)',
                    controller: vm.plannedStartController,
                    readOnly: !vm.canEdit,
                  ),
                  AppFormTextField(
                    labelText: 'Planned end (ISO datetime)',
                    controller: vm.plannedEndController,
                    readOnly: !vm.canEdit,
                  ),
                  AppFormTextField(
                    labelText: 'Actual start (ISO datetime)',
                    controller: vm.actualStartController,
                    readOnly: !vm.canEdit,
                  ),
                  AppFormTextField(
                    labelText: 'Actual end (ISO datetime)',
                    controller: vm.actualEndController,
                    readOnly: !vm.canEdit,
                  ),
                  AppFormTextField(
                    labelText: 'Downtime minutes',
                    controller: vm.downtimeMinutesController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    readOnly: !vm.canEdit,
                  ),
                  AppFormTextField(
                    labelText: 'Labor cost',
                    controller: vm.laborCostController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    readOnly: !vm.canEdit,
                  ),
                  AppFormTextField(
                    labelText: 'Other cost',
                    controller: vm.otherCostController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    readOnly: !vm.canEdit,
                  ),
                  if (vm.selected != null && (spare.isNotEmpty || extSvc.isNotEmpty || total.isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (spare.isNotEmpty)
                            Text(
                              'Spare cost (system): $spare',
                              style: theme.textTheme.bodySmall,
                            ),
                          if (extSvc.isNotEmpty)
                            Text(
                              'External service cost (system): $extSvc',
                              style: theme.textTheme.bodySmall,
                            ),
                          if (total.isNotEmpty)
                            Text(
                              'Total cost (system): $total',
                              style: theme.textTheme.titleSmall,
                            ),
                        ],
                      ),
                    ),
                  AppFormTextField(
                    labelText: 'Remarks',
                    controller: vm.remarksController,
                    maxLines: 3,
                    readOnly: !vm.canEdit,
                  ),
                  if (vm.selected != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppUiConstants.spacingSm,
                      ),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(vm.workOrderStatus),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Wrap(
                spacing: AppUiConstants.spacingSm,
                runSpacing: AppUiConstants.spacingSm,
                children: [
                  if (vm.canEdit)
                    AppActionButton(
                      icon: Icons.save_outlined,
                      label: vm.selected == null ? 'Save' : 'Update',
                      busy: vm.saving,
                      onPressed: () => onSave(formContext),
                    ),
                  if (vm.selected != null && vm.canDelete)
                    AppActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      filled: false,
                      onPressed: vm.saving ? null : onDelete,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
