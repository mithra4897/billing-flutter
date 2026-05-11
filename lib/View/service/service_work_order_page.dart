import '../../screen.dart';
import '../../view_model/service/service_work_order_view_model.dart';
import '../purchase/purchase_support.dart';

const List<AppDropdownItem<String>> _kExecutionModeItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'onsite', label: 'Onsite'),
      AppDropdownItem(value: 'remote', label: 'Remote'),
      AppDropdownItem(value: 'workshop', label: 'Workshop'),
    ];

String _woListTitle(ServiceWorkOrderModel row) {
  final data = row.toJson();
  final no = stringValue(data, 'work_order_no');
  if (no.isNotEmpty) {
    return no;
  }
  final id = intValue(data, 'id');
  return id != null ? 'Work order #$id' : 'Work order';
}

class ServiceWorkOrderPage extends StatefulWidget {
  const ServiceWorkOrderPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<ServiceWorkOrderPage> createState() => _ServiceWorkOrderPageState();
}

class _ServiceWorkOrderPageState extends State<ServiceWorkOrderPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final ServiceWorkOrderViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ServiceWorkOrderViewModel()..load(selectId: widget.initialId);
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final isDesktop = Responsive.isDesktop(context);
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: _viewModel.loading
                ? null
                : () {
                    _viewModel.resetDraft();
                    if (widget.editorOnly || !isDesktop) {
                      _openRoute('/service/work-orders/new');
                    }
                    if (!isDesktop) {
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
          title: 'Service work orders',
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
      title: 'Service work orders',
      editorTitle: _viewModel.selected == null
          ? 'New work order'
          : _woListTitle(_viewModel.selected!),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<ServiceWorkOrderModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search work order no., customer, status',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No work orders found.',
        itemBuilder: (row, selected) {
          final data = row.toJson();
          return SettingsListTile(
            title: _woListTitle(row),
            subtitle: [
              displayDate(nullableStringValue(data, 'work_order_date')),
              _viewModel.customerLabelFor(data),
              stringValue(data, 'work_order_status'),
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
      editor: _ServiceWorkOrderEditor(
        vm: _viewModel,
        onSave: (formContext) async {
          if (!Form.of(formContext).validate()) {
            return;
          }
          await _viewModel.save();
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
        onCancelWo: () async {
          await _viewModel.cancelWorkOrder();
          _snack();
        },
        onDelete: () async {
          final shouldNavigateBack =
              widget.editorOnly || !Responsive.isDesktop(context);
          await _viewModel.deleteWorkOrder();
          _snack();
          if (shouldNavigateBack) {
            _openRoute('/service/work-orders');
          }
        },
      ),
    );
  }
}

class _ServiceWorkOrderEditor extends StatelessWidget {
  const _ServiceWorkOrderEditor({
    required this.vm,
    required this.onSave,
    required this.onStart,
    required this.onComplete,
    required this.onClose,
    required this.onCancelWo,
    required this.onDelete,
  });

  final ServiceWorkOrderViewModel vm;
  final Future<void> Function(BuildContext formContext) onSave;
  final Future<void> Function() onStart;
  final Future<void> Function() onComplete;
  final Future<void> Function() onClose;
  final Future<void> Function() onCancelWo;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    if (vm.detailLoading) {
      return const AppLoadingView(message: 'Loading document...');
    }

    final edit = vm.canEdit;

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
              SettingsFormWrap(
                children: [
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Service ticket',
                    mappedItems: vm.ticketOptions
                        .map((t) {
                          final id = intValue(t.toJson(), 'id');
                          if (id == null) {
                            return null;
                          }
                          return AppDropdownItem<int>(
                            value: id,
                            label: vm.ticketLabel(t),
                          );
                        })
                        .whereType<AppDropdownItem<int>>()
                        .toList(growable: false),
                    initialValue: vm.serviceTicketId,
                    onChanged: (int? v) {
                      if (edit) {
                        vm.setServiceTicketId(v);
                      }
                    },
                    validator: Validators.requiredSelection('Service ticket'),
                  ),
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
                      if (edit) {
                        vm.setCompanyId(v);
                      }
                    },
                    validator: Validators.requiredSelection('Company'),
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
                        final navigate = ShellRouteScope.maybeOf(context);
                        if (navigate != null) {
                          navigate(uri.toString());
                        } else {
                          Navigator.of(context).pushNamed(uri.toString());
                        }
                      },
                    mappedItems: vm.parties
                        .where((p) => p.id != null)
                        .map(
                          (p) => AppDropdownItem<int>(
                            value: p.id!,
                            label: p.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.customerPartyId,
                    onChanged: (int? v) {
                      if (edit) {
                        vm.setCustomerPartyId(v);
                      }
                    },
                    validator: Validators.requiredSelection('Customer'),
                  ),
                  AppFormTextField(
                    labelText: 'Work order no. (optional if series set)',
                    controller: vm.workOrderNoController,
                    enabled: edit,
                  ),
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Document series',
                    mappedItems: [
                      const AppDropdownItem<int?>(
                        value: null,
                        label: '—',
                      ),
                      ...vm.woSeriesOptions
                          .where((s) => s.id != null)
                          .map(
                            (s) => AppDropdownItem<int?>(
                              value: s.id!,
                              label: s.toString(),
                            ),
                          ),
                    ],
                    initialValue: vm.documentSeriesId,
                    onChanged: (int? v) {
                      if (edit) {
                        vm.setDocumentSeriesId(v);
                      }
                    },
                  ),
                  AppFormTextField(
                    labelText: 'Work order date',
                    controller: vm.workOrderDateController,
                    enabled: edit,
                    validator: Validators.required('Work order date'),
                  ),
                  AppDropdownField<String>.fromMapped(
                    labelText: 'Execution mode',
                    mappedItems: _kExecutionModeItems,
                    initialValue: vm.executionMode.isNotEmpty
                        ? vm.executionMode
                        : 'onsite',
                    onChanged: (String? v) {
                      if (edit && v != null) {
                        vm.setExecutionMode(v);
                      }
                    },
                  ),
                  AppFormTextField(
                    labelText: 'Technician user id (optional)',
                    controller: vm.technicianUserIdController,
                    enabled: edit,
                    keyboardType: TextInputType.number,
                  ),
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Branch (optional)',
                    mappedItems: [
                      const AppDropdownItem<int?>(
                        value: null,
                        label: '—',
                      ),
                      ...vm.branchOptions
                          .where((b) => b.id != null)
                          .map(
                            (b) => AppDropdownItem<int?>(
                              value: b.id!,
                              label: b.toString(),
                            ),
                          ),
                    ],
                    initialValue: vm.branchId,
                    onChanged: (int? v) {
                      if (edit) {
                        vm.setBranchId(v);
                      }
                    },
                  ),
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Location (optional)',
                    mappedItems: [
                      const AppDropdownItem<int?>(
                        value: null,
                        label: '—',
                      ),
                      ...vm.locationOptions
                          .where((l) => l.id != null)
                          .map(
                            (l) => AppDropdownItem<int?>(
                              value: l.id!,
                              label: l.toString(),
                            ),
                          ),
                    ],
                    initialValue: vm.locationId,
                    onChanged: (int? v) {
                      if (edit) {
                        vm.setLocationId(v);
                      }
                    },
                  ),
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Financial year (optional)',
                    mappedItems: [
                      const AppDropdownItem<int?>(
                        value: null,
                        label: '—',
                      ),
                      ...vm.financialYearOptions
                          .where((f) => f.id != null)
                          .map(
                            (f) => AppDropdownItem<int?>(
                              value: f.id!,
                              label: f.toString(),
                            ),
                          ),
                    ],
                    initialValue: vm.financialYearId,
                    onChanged: (int? v) {
                      if (edit) {
                        vm.setFinancialYearId(v);
                      }
                    },
                  ),
                  AppFormTextField(
                    labelText: 'Diagnosis notes',
                    controller: vm.diagnosisNotesController,
                    enabled: edit,
                    maxLines: 3,
                  ),
                  AppFormTextField(
                    labelText: 'Action taken',
                    controller: vm.actionTakenController,
                    enabled: edit,
                    maxLines: 2,
                  ),
                  AppFormTextField(
                    labelText: 'Resolution summary',
                    controller: vm.resolutionSummaryController,
                    enabled: edit,
                    maxLines: 2,
                  ),
                  AppFormTextField(
                    labelText: 'Customer site address',
                    controller: vm.customerSiteAddressController,
                    enabled: edit,
                    maxLines: 2,
                  ),
                  AppFormTextField(
                    labelText: 'Remarks',
                    controller: vm.remarksController,
                    enabled: edit,
                    maxLines: 2,
                  ),
                  if (vm.selected != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppUiConstants.spacingSm,
                        bottom: AppUiConstants.spacingSm,
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
                  AppActionButton(
                    icon: Icons.save_outlined,
                    label: vm.selected == null ? 'Save' : 'Update',
                    busy: vm.saving,
                    onPressed: edit ? () => onSave(formContext) : null,
                  ),
                  if (vm.canStart)
                    AppActionButton(
                      icon: Icons.play_arrow_outlined,
                      label: 'Start',
                      filled: false,
                      onPressed: vm.saving ? null : () => onStart(),
                    ),
                  if (vm.canComplete)
                    AppActionButton(
                      icon: Icons.task_alt_outlined,
                      label: 'Complete',
                      filled: false,
                      onPressed: vm.saving ? null : () => onComplete(),
                    ),
                  if (vm.canClose)
                    AppActionButton(
                      icon: Icons.door_front_door_outlined,
                      label: 'Close',
                      filled: false,
                      onPressed: vm.saving ? null : () => onClose(),
                    ),
                  if (vm.canCancel)
                    AppActionButton(
                      icon: Icons.cancel_outlined,
                      label: 'Cancel WO',
                      filled: false,
                      onPressed: vm.saving ? null : () => onCancelWo(),
                    ),
                  if (vm.canDelete)
                    AppActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      filled: false,
                      onPressed: vm.saving ? null : () => onDelete(),
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
