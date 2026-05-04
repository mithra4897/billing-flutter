import '../../screen.dart';
import '../../view_model/quality/qc_plan_view_model.dart';
import '../purchase/purchase_support.dart';

const List<AppDropdownItem<String>> _qcScopeItems = <AppDropdownItem<String>>[
  AppDropdownItem(value: 'all', label: 'All'),
  AppDropdownItem(value: 'item', label: 'Item'),
  AppDropdownItem(value: 'category', label: 'Category'),
];

const List<AppDropdownItem<String>> _acceptanceBasisItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'all_pass', label: 'All pass'),
      AppDropdownItem(
        value: 'min_pass_percent',
        label: 'Minimum pass percent',
      ),
    ];

const List<AppDropdownItem<String>> _checkpointTypeItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'visual', label: 'Visual'),
      AppDropdownItem(value: 'dimensional', label: 'Dimensional'),
      AppDropdownItem(value: 'functional', label: 'Functional'),
      AppDropdownItem(value: 'documentary', label: 'Documentary'),
    ];

class QcPlanPage extends StatefulWidget {
  const QcPlanPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<QcPlanPage> createState() => _QcPlanPageState();
}

class _QcPlanPageState extends State<QcPlanPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final QcPlanViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = QcPlanViewModel()..load(selectId: widget.initialId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _pageScrollController.dispose();
    _workspaceController.dispose();
    super.dispose();
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
            label: 'New QC plan',
          ),
        ];
        final content = _buildContent(context);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'QC Plan',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading QC plans...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load QC plans',
        message: _viewModel.pageError!,
        onRetry: () => _viewModel.load(selectId: widget.initialId),
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'QC Plan',
      editorTitle: _viewModel.selected?.toString() ?? 'New QC plan',
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<QcPlanModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search plans',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No QC plans found.',
        itemBuilder: (item, selected) {
          final row = item;
          return SettingsListTile(
            title: row.planCode.isNotEmpty ? row.planCode : row.planName,
            subtitle: [
              row.qcScope,
              row.approvalStatus,
            ].where((v) => v.trim().isNotEmpty).join(' · '),
            detail: row.itemLabel.isNotEmpty ? row.itemLabel : row.categoryLabel,
            selected: selected,
            onTap: () async {
              await _viewModel.select(item);
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
      editor: _QcPlanEditor(
        vm: _viewModel,
        checkpointTypes: _checkpointTypeItems,
        onSave: () async {
          await _viewModel.save();
          _snack();
        },
        onApprove: () async {
          await _viewModel.approvePlan();
          _snack();
        },
        onDeactivate: () async {
          await _viewModel.deactivatePlan();
          _snack();
        },
        onObsolete: () async {
          await _viewModel.obsoletePlan();
          _snack();
        },
        onDelete: () async {
          await _viewModel.deletePlan();
          _snack();
        },
      ),
    );
  }
}

class _QcPlanEditor extends StatelessWidget {
  const _QcPlanEditor({
    required this.vm,
    required this.checkpointTypes,
    required this.onSave,
    required this.onApprove,
    required this.onDeactivate,
    required this.onObsolete,
    required this.onDelete,
  });

  final QcPlanViewModel vm;
  final List<AppDropdownItem<String>> checkpointTypes;
  final Future<void> Function() onSave;
  final Future<void> Function() onApprove;
  final Future<void> Function() onDeactivate;
  final Future<void> Function() onObsolete;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    if (vm.detailLoading) {
      return const AppLoadingView(message: 'Loading document...');
    }

    final edit = vm.canEdit;
    final editLines = vm.canEditLines;

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
                        .where((x) => x.id != null)
                        .map(
                          (x) => AppDropdownItem<int>(
                            value: x.id!,
                            label: x.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.companyId,
                    onChanged: (int? v) {
                      if (edit) vm.onCompanyChanged(v);
                    },
                    validator: Validators.requiredSelection('Company'),
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Branch',
                    mappedItems: vm.branchOptions
                        .where((x) => x.id != null)
                        .map(
                          (x) => AppDropdownItem<int>(
                            value: x.id!,
                            label: x.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.branchId,
                    onChanged: (int? v) {
                      if (edit) vm.onBranchChanged(v);
                    },
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Location',
                    mappedItems: vm.locationOptions
                        .where((x) => x.id != null)
                        .map(
                          (x) => AppDropdownItem<int>(
                            value: x.id!,
                            label: x.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.locationId,
                    onChanged: (int? v) {
                      if (edit) vm.onLocationChanged(v);
                    },
                  ),
                  AppFormTextField(
                    labelText: 'Plan code',
                    controller: vm.planCodeController,
                    enabled: edit,
                    validator: Validators.compose([
                      Validators.required('Plan code'),
                      Validators.optionalMaxLength(100, 'Plan code'),
                    ]),
                  ),
                  AppFormTextField(
                    labelText: 'Plan name',
                    controller: vm.planNameController,
                    enabled: edit,
                    validator: Validators.compose([
                      Validators.required('Plan name'),
                      Validators.optionalMaxLength(255, 'Plan name'),
                    ]),
                  ),
                  AppDropdownField<String>.fromMapped(
                    labelText: 'QC scope',
                    mappedItems: _qcScopeItems,
                    initialValue: vm.qcScope,
                    onChanged: (String? v) {
                      if (edit) vm.setQcScope(v ?? 'all');
                    },
                  ),
                  AppSearchPickerField<int>(
                    labelText: 'Item (optional)',
                    selectedLabel: vm.itemOptions
                        .cast<ItemModel?>()
                        .firstWhere(
                          (x) => x?.id == vm.itemId,
                          orElse: () => null,
                        )
                        ?.toString(),
                    options: vm.itemOptions
                        .where((x) => x.id != null)
                        .map(
                          (x) => AppSearchPickerOption<int>(
                            value: x.id!,
                            label: x.toString(),
                            subtitle: x.itemCode,
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (int? v) {
                      if (edit) vm.setItemId(v);
                    },
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Item category (optional)',
                    mappedItems: vm.categoryOptions
                        .where((x) => x.id != null)
                        .map(
                          (x) => AppDropdownItem<int>(
                            value: x.id!,
                            label: x.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.itemCategoryId,
                    onChanged: (int? v) {
                      if (edit) vm.setItemCategoryId(v);
                    },
                  ),
                  AppFormTextField(
                    labelText: 'Sampling method (optional)',
                    controller: vm.samplingMethodController,
                    enabled: edit,
                  ),
                  AppDropdownField<String>.fromMapped(
                    labelText: 'Acceptance basis',
                    mappedItems: _acceptanceBasisItems,
                    initialValue: vm.acceptanceBasis,
                    onChanged: (String? v) {
                      if (edit) vm.setAcceptanceBasis(v ?? 'all_pass');
                    },
                  ),
                  if (vm.acceptanceBasis == 'min_pass_percent')
                    AppFormTextField(
                      labelText: 'Minimum pass %',
                      controller: vm.minPassPercentController,
                      enabled: edit,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: Validators.compose([
                        Validators.required('Minimum pass %'),
                        (v) {
                          final p = double.tryParse((v ?? '').trim());
                          if (p == null) {
                            return 'Enter a valid number';
                          }
                          if (p <= 0 || p > 100) {
                            return 'Must be between 1 and 100';
                          }
                          return null;
                        },
                      ]),
                    ),
                  AppFormTextField(
                    labelText: 'Effective from',
                    controller: vm.effectiveFromController,
                    enabled: edit,
                    inputFormatters: const [DateInputFormatter()],
                    validator: Validators.optionalDate('Effective from'),
                  ),
                  AppFormTextField(
                    labelText: 'Effective to',
                    controller: vm.effectiveToController,
                    enabled: edit,
                    inputFormatters: const [DateInputFormatter()],
                    validator: Validators.optionalDate('Effective to'),
                  ),
                  AppFormTextField(
                    labelText: 'Notes',
                    controller: vm.notesController,
                    enabled: edit,
                    maxLines: 2,
                  ),
                  AppSwitchTile(
                    label: 'Default plan for item/category',
                    value: vm.isDefault,
                    onChanged: edit ? vm.setIsDefault : null,
                  ),
                  AppSwitchTile(
                    label: 'Active',
                    value: vm.isActive,
                    onChanged: edit ? vm.setIsActive : null,
                  ),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Row(
                children: [
                  Text(
                    'Checkpoints',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  AppActionButton(
                    icon: Icons.add_outlined,
                    label: 'Add line',
                    filled: false,
                    onPressed: editLines ? vm.addLine : null,
                  ),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingSm),
              ...List<Widget>.generate(vm.lineDrafts.length, (index) {
                final line = vm.lineDrafts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
                  child: PurchaseCompactLineCard(
                    index: index,
                    total: vm.lineDrafts.length,
                    removeEnabled: editLines && vm.lineDrafts.length > 1,
                    onRemove: editLines ? () => vm.removeLine(index) : null,
                    child: PurchaseCompactFieldGrid(
                      children: [
                        AppFormTextField(
                          labelText: 'Checkpoint name',
                          controller: line.checkpointNameController,
                          enabled: editLines,
                          validator: Validators.compose([
                            Validators.required('Checkpoint name'),
                          ]),
                        ),
                        AppDropdownField<String>.fromMapped(
                          labelText: 'Checkpoint type',
                          mappedItems: checkpointTypes,
                          initialValue: line.checkpointType,
                          onChanged: (String? v) {
                            if (editLines) {
                              vm.setCheckpointType(
                                index,
                                v ?? 'visual',
                              );
                            }
                          },
                        ),
                        AppFormTextField(
                          labelText: 'Specification',
                          controller: line.specificationController,
                          enabled: editLines,
                        ),
                        AppFormTextField(
                          labelText: 'Tolerance min',
                          controller: line.toleranceMinController,
                          enabled: editLines,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        AppFormTextField(
                          labelText: 'Tolerance max',
                          controller: line.toleranceMaxController,
                          enabled: editLines,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        AppFormTextField(
                          labelText: 'Expected text',
                          controller: line.expectedTextController,
                          enabled: editLines,
                        ),
                        AppFormTextField(
                          labelText: 'Unit',
                          controller: line.unitController,
                          enabled: editLines,
                        ),
                        AppFormTextField(
                          labelText: 'Sequence',
                          controller: line.sequenceNoController,
                          enabled: editLines,
                          keyboardType: TextInputType.number,
                        ),
                        AppSwitchTile(
                          label: 'Critical',
                          value: line.isCritical,
                          onChanged: editLines
                              ? (v) => vm.setLineCritical(index, v)
                              : null,
                        ),
                        AppSwitchTile(
                          label: 'Mandatory',
                          value: line.isMandatory,
                          onChanged: editLines
                              ? (v) => vm.setLineMandatory(index, v)
                              : null,
                        ),
                        AppFormTextField(
                          labelText: 'Remarks',
                          controller: line.remarksController,
                          enabled: editLines,
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
                  if (edit)
                    AppActionButton(
                      icon: Icons.save_outlined,
                      label: vm.selected == null ? 'Save' : 'Update',
                      busy: vm.saving,
                      onPressed: () async {
                        if (!Form.of(formContext).validate()) {
                          return;
                        }
                        await onSave();
                      },
                    ),
                  if (vm.canApprove)
                    AppActionButton(
                      icon: Icons.verified_outlined,
                      label: 'Approve',
                      filled: false,
                      onPressed: onApprove,
                    ),
                  if (vm.canDeactivate)
                    AppActionButton(
                      icon: Icons.pause_circle_outline,
                      label: 'Deactivate',
                      filled: false,
                      onPressed: onDeactivate,
                    ),
                  if (vm.canObsolete)
                    AppActionButton(
                      icon: Icons.archive_outlined,
                      label: 'Obsolete',
                      filled: false,
                      onPressed: onObsolete,
                    ),
                  if (vm.canDelete)
                    AppActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      filled: false,
                      onPressed: onDelete,
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
