import '../../screen.dart';
import '../../view_model/service/service_contract_view_model.dart';
import '../purchase/purchase_support.dart';

String _contractListTitle(ServiceContractModel row) {
  final data = row.toJson();
  final no = stringValue(data, 'contract_no');
  if (no.isNotEmpty) {
    return no;
  }
  final id = intValue(data, 'id');
  return id != null ? 'Contract #$id' : 'Contract';
}

class ServiceContractPage extends StatefulWidget {
  const ServiceContractPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<ServiceContractPage> createState() => _ServiceContractPageState();
}

class _ServiceContractPageState extends State<ServiceContractPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final ServiceContractViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ServiceContractViewModel()..load(selectId: widget.initialId);
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
                      _openRoute('/service/contracts/new');
                    }
                    if (!isDesktop) {
                      _workspaceController.openEditor();
                    }
                  },
            icon: Icons.add_outlined,
            label: 'New service contract',
          ),
        ];
        final content = _buildContent(context);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Service contracts',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading service contracts...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load service contracts',
        message: _viewModel.pageError!,
        onRetry: () => _viewModel.load(selectId: widget.initialId),
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Service contracts',
      editorTitle: _viewModel.selected == null
          ? 'New service contract'
          : _contractListTitle(_viewModel.selected!),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<ServiceContractModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search contract no., customer, status, type',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No service contracts found.',
        itemBuilder: (row, selected) {
          final data = row.toJson();
          return SettingsListTile(
            title: _contractListTitle(row),
            subtitle: [
              displayDate(nullableStringValue(data, 'contract_date')),
              _viewModel.customerLabelFor(data),
              stringValue(data, 'contract_status'),
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
      editor: _ServiceContractEditor(
        vm: _viewModel,
        onSave: (formContext) async {
          if (!Form.of(formContext).validate()) {
            return;
          }
          await _viewModel.save();
          _snack();
        },
        onApprove: () async {
          await _viewModel.approveContract();
          _snack();
        },
        onTerminate: () async {
          await _viewModel.terminateContract();
          _snack();
        },
        onCancelContract: () async {
          await _viewModel.cancelContract();
          _snack();
        },
        onDelete: () async {
          final shouldNavigateBack =
              widget.editorOnly || !Responsive.isDesktop(context);
          await _viewModel.deleteContract();
          _snack();
          if (shouldNavigateBack) {
            _openRoute('/service/contracts');
          }
        },
      ),
    );
  }
}

class _ServiceContractEditor extends StatelessWidget {
  const _ServiceContractEditor({
    required this.vm,
    required this.onSave,
    required this.onApprove,
    required this.onTerminate,
    required this.onCancelContract,
    required this.onDelete,
  });

  final ServiceContractViewModel vm;
  final Future<void> Function(BuildContext formContext) onSave;
  final Future<void> Function() onApprove;
  final Future<void> Function() onTerminate;
  final Future<void> Function() onCancelContract;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    if (vm.detailLoading) {
      return const AppLoadingView(message: 'Loading document...');
    }

    final edit = vm.canEdit;
    final cv = double.tryParse(vm.contractValueController.text.trim()) ?? 0;
    final tax = double.tryParse(vm.taxAmountController.text.trim()) ?? 0;
    final total = (cv + tax).toStringAsFixed(2);

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
                    labelText: 'Contract no. (optional if series set)',
                    controller: vm.contractNoController,
                    enabled: edit,
                  ),
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Document series (for auto number)',
                    mappedItems: [
                      const AppDropdownItem<int?>(
                        value: null,
                        label: '—',
                      ),
                      ...vm.seriesOptions
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
                    labelText: 'Contract date',
                    controller: vm.contractDateController,
                    enabled: edit,
                    validator: Validators.required('Contract date'),
                  ),
                  AppFormTextField(
                    labelText: 'Contract type',
                    controller: vm.contractTypeController,
                    enabled: edit,
                  ),
                  AppFormTextField(
                    labelText: 'Start date',
                    controller: vm.startDateController,
                    enabled: edit,
                  ),
                  AppFormTextField(
                    labelText: 'End date',
                    controller: vm.endDateController,
                    enabled: edit,
                  ),
                  AppFormTextField(
                    labelText: 'Coverage scope',
                    controller: vm.coverageController,
                    enabled: edit,
                    maxLines: 2,
                  ),
                  AppFormTextField(
                    labelText: 'Visit frequency',
                    controller: vm.visitFrequencyController,
                    enabled: edit,
                  ),
                  AppFormTextField(
                    labelText: 'Response time (hours)',
                    controller: vm.responseTimeController,
                    enabled: edit,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'Resolution time (hours)',
                    controller: vm.resolutionTimeController,
                    enabled: edit,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'Contract value',
                    controller: vm.contractValueController,
                    enabled: edit,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'Tax amount',
                    controller: vm.taxAmountController,
                    enabled: edit,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Total: $total',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'Sales invoice id (optional)',
                    controller: vm.salesInvoiceIdController,
                    enabled: edit,
                    keyboardType: TextInputType.number,
                  ),
                  AppFormTextField(
                    labelText: 'Notes',
                    controller: vm.notesController,
                    enabled: edit,
                    maxLines: 3,
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
                        child: Text(vm.contractStatus),
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
                  if (vm.canApprove)
                    AppActionButton(
                      icon: Icons.check_circle_outline,
                      label: 'Approve',
                      filled: false,
                      onPressed: vm.saving ? null : () => onApprove(),
                    ),
                  if (vm.canTerminate)
                    AppActionButton(
                      icon: Icons.stop_circle_outlined,
                      label: 'Terminate',
                      filled: false,
                      onPressed: vm.saving ? null : () => onTerminate(),
                    ),
                  if (vm.canCancel)
                    AppActionButton(
                      icon: Icons.cancel_outlined,
                      label: 'Cancel contract',
                      filled: false,
                      onPressed: vm.saving ? null : () => onCancelContract(),
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
