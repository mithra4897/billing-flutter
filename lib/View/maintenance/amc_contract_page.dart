import '../../screen.dart';
import '../../view_model/maintenance/amc_contract_view_model.dart';
import '../purchase/purchase_support.dart';

class AmcContractPage extends StatefulWidget {
  const AmcContractPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<AmcContractPage> createState() => _AmcContractPageState();
}

class _AmcContractPageState extends State<AmcContractPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final AmcContractViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AmcContractViewModel()..load(selectId: widget.initialId);
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
        title: const Text('Delete AMC contract'),
        content: const Text(
          'Only draft AMC contracts can be deleted. Continue?',
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
    await _viewModel.deleteContract();
    _snack();
    _openRoute('/maintenance/amc-contracts');
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
                    _openRoute('/maintenance/amc-contracts/new');
                    if (!Responsive.isDesktop(context)) {
                      _workspaceController.openEditor();
                    }
                  },
            icon: Icons.add_outlined,
            label: 'New AMC contract',
          ),
        ];
        final content = _buildContent(context);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'AMC contracts',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading AMC contracts...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load AMC contracts',
        message: _viewModel.pageError!,
        onRetry: () => _viewModel.load(selectId: widget.initialId),
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'AMC contracts',
      editorTitle: _viewModel.selected == null
          ? 'New AMC contract'
          : _viewModel.listTitle(_viewModel.selected!),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<AmcContractModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search contract no., vendor, status, type',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No AMC contracts found.',
        itemBuilder: (row, selected) {
          final data = row.toJson();
          return SettingsListTile(
            title: _viewModel.listTitle(row),
            subtitle: [
              displayDate(nullableStringValue(data, 'contract_date')),
              _viewModel.vendorLabelFor(data),
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
      editor: _AmcContractEditor(
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
        onDelete: _confirmDelete,
      ),
    );
  }
}

class _AmcContractEditor extends StatelessWidget {
  const _AmcContractEditor({
    required this.vm,
    required this.onSave,
    required this.onApprove,
    required this.onTerminate,
    required this.onCancelContract,
    required this.onDelete,
  });

  final AmcContractViewModel vm;
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
                    labelText: 'Vendor',
                    mappedItems: vm.vendorOptions
                        .where((p) => p.id != null)
                        .map(
                          (p) => AppDropdownItem<int>(
                            value: p.id!,
                            label: p.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.vendorPartyId,
                    onChanged: (int? v) {
                      if (edit) {
                        vm.setVendorPartyId(v);
                      }
                    },
                    validator: Validators.requiredSelection('Vendor'),
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
                    validator: Validators.required('Start date'),
                  ),
                  AppFormTextField(
                    labelText: 'End date',
                    controller: vm.endDateController,
                    enabled: edit,
                    validator: Validators.required('End date'),
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
                    labelText: 'Remarks',
                    controller: vm.remarksController,
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
