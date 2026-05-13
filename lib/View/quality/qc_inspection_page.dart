import '../../screen.dart';
import '../../view_model/quality/qc_inspection_view_model.dart';

class QcInspectionPage extends StatefulWidget {
  const QcInspectionPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<QcInspectionPage> createState() => _QcInspectionPageState();
}

class _QcInspectionPageState extends State<QcInspectionPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final QcInspectionViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = QcInspectionViewModel()..load(selectId: widget.initialId);
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

  String _editorTitle() {
    if (_viewModel.selectedId == null) {
      return 'New QC inspection';
    }
    final no = _viewModel.inspectionNoLabel;
    return no.isNotEmpty ? no : 'QC inspection #${_viewModel.selectedId}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final content = _buildContent(context);
        if (widget.embedded) {
          return ShellPageActions(actions: const <Widget>[], child: content);
        }
        return AppStandaloneShell(
          title: 'QC inspection',
          scrollController: _pageScrollController,
          actions: const <Widget>[],
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load QC inspection',
        message: _viewModel.pageError!,
        onRetry: () => _viewModel.load(selectId: widget.initialId),
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'QC inspection',
      editorTitle: _editorTitle(),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: const SizedBox.shrink(),
      editor: _QcInspectionEditor(
        vm: _viewModel,
        onSave: (formContext) async {
          if (!Form.of(formContext).validate()) {
            return;
          }
          await _viewModel.save();
          _snack();
        },
        onStart: () async {
          await _viewModel.startInspection();
          _snack();
        },
        onComplete: () async {
          await _viewModel.completeInspection();
          _snack();
        },
        onApprove: () async {
          await _viewModel.approveInspection();
          _snack();
        },
        onReject: () async {
          await _viewModel.rejectInspection();
          _snack();
        },
        onCancel: () async {
          await _viewModel.cancelInspection();
          _snack();
        },
        onDelete: () async {
          await _viewModel.deleteInspection();
          _snack();
        },
      ),
    );
  }
}

class _QcInspectionEditor extends StatelessWidget {
  const _QcInspectionEditor({
    required this.vm,
    required this.onSave,
    required this.onStart,
    required this.onComplete,
    required this.onApprove,
    required this.onReject,
    required this.onCancel,
    required this.onDelete,
  });

  final QcInspectionViewModel vm;
  final Future<void> Function(BuildContext formContext) onSave;
  final Future<void> Function() onStart;
  final Future<void> Function() onComplete;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;
  final Future<void> Function() onCancel;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    if (vm.detailLoading) {
      return const AppLoadingView(message: 'Loading document...');
    }

    final edit = vm.canEditHeader;

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
              if (vm.selectedId != null)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppUiConstants.spacingSm,
                  ),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(vm.inspectionStatus),
                  ),
                ),
              SettingsFormWrap(
                children: [
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Financial year',
                    mappedItems: vm.financialYearOptions
                        .where((x) => x.id != null)
                        .map(
                          (x) => AppDropdownItem<int>(
                            value: x.id!,
                            label: x.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.financialYearId,
                    onChanged: (int? v) {
                      if (edit) {
                        vm.setFinancialYearId(v);
                      }
                    },
                    validator: Validators.requiredSelection('Financial year'),
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Document series (optional)',
                    mappedItems: vm.qcSeriesOptions
                        .where((x) => x.id != null)
                        .map(
                          (x) => AppDropdownItem<int>(
                            value: x.id!,
                            label: x.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.documentSeriesId,
                    onChanged: (int? v) {
                      if (edit) {
                        vm.setDocumentSeriesId(v);
                      }
                    },
                  ),
                  AppFormTextField(
                    labelText: 'Inspection date',
                    controller: vm.inspectionDateController,
                    enabled: edit,
                    inputFormatters: const [DateInputFormatter()],
                    validator: Validators.compose([
                      Validators.required('Inspection date'),
                      Validators.optionalDate('Inspection date'),
                    ]),
                  ),
                  AppDropdownField<String>.fromMapped(
                    labelText: 'Inspection scope',
                    mappedItems: kQcInspectionScopeItems,
                    initialValue: vm.inspectionScope,
                    onChanged: (String? v) {
                      if (edit && v != null) {
                        vm.setInspectionScope(v);
                      }
                    },
                  ),
                  AppDropdownField<String>.fromMapped(
                    labelText: 'Source document type',
                    mappedItems: kQcInspectionSourceTypeItems,
                    initialValue: vm.sourceDocumentType,
                    onChanged: (String? v) {
                      if (edit && v != null) {
                        vm.setSourceDocumentType(v);
                      }
                    },
                  ),
                  AppFormTextField(
                    labelText: 'Source document id',
                    controller: vm.sourceDocumentIdController,
                    enabled: edit,
                    keyboardType: TextInputType.number,
                    validator: Validators.compose([
                      Validators.required('Source document id'),
                      (v) {
                        final n = int.tryParse((v ?? '').trim());
                        if (n == null || n <= 0) {
                          return 'Enter a valid id';
                        }
                        return null;
                      },
                    ]),
                  ),
                  AppFormTextField(
                    labelText: 'Source line id (optional)',
                    controller: vm.sourceLineIdController,
                    enabled: edit,
                    keyboardType: TextInputType.number,
                  ),
                  AppSearchPickerField<int>(
                    labelText: 'Item',
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
                    validator: (_) =>
                        vm.itemId == null ? 'Item is required' : null,
                    onChanged: (int? v) {
                      if (edit) {
                        vm.setItemId(v);
                      }
                    },
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'UOM',
                    mappedItems: vm.uomOptions
                        .where((x) => x.id != null)
                        .map(
                          (x) => AppDropdownItem<int>(
                            value: x.id!,
                            label: x.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.uomId,
                    onChanged: (int? v) {
                      if (edit) {
                        vm.setUomId(v);
                      }
                    },
                    validator: Validators.requiredSelection('UOM'),
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText:
                        'QC plan (optional — scope “all”; else add lines via API)',
                    mappedItems: vm.qcPlanOptions
                        .where((x) => x.id != null)
                        .map(
                          (x) => AppDropdownItem<int>(
                            value: x.id!,
                            label: '${x.planCode} · ${x.planName}',
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.qcPlanId,
                    onChanged: (int? v) {
                      if (edit) {
                        vm.setQcPlanId(v);
                      }
                    },
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Warehouse (optional)',
                    mappedItems: vm.warehouseOptions
                        .where((x) => x.id != null)
                        .map(
                          (x) => AppDropdownItem<int>(
                            value: x.id!,
                            label: x.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.warehouseId,
                    onChanged: (int? v) {
                      if (edit) {
                        vm.setWarehouseId(v);
                      }
                    },
                  ),
                  AppFormTextField(
                    labelText: 'Lot no (optional)',
                    controller: vm.lotNoController,
                    enabled: edit,
                  ),
                  AppFormTextField(
                    labelText: 'Inspected qty',
                    controller: vm.inspectedQtyController,
                    enabled: edit,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: Validators.compose([
                      Validators.required('Inspected qty'),
                      (v) {
                        final q = double.tryParse((v ?? '').trim());
                        if (q == null || q <= 0) {
                          return 'Must be greater than zero';
                        }
                        return null;
                      },
                    ]),
                  ),
                  AppFormTextField(
                    labelText: 'Sample size (optional)',
                    controller: vm.sampleSizeController,
                    enabled: edit,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'Accepted qty',
                    controller: vm.acceptedQtyController,
                    enabled: edit,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'Rejected qty',
                    controller: vm.rejectedQtyController,
                    enabled: edit,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'Hold qty',
                    controller: vm.holdQtyController,
                    enabled: edit,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'Rework qty',
                    controller: vm.reworkQtyController,
                    enabled: edit,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  AppFormTextField(
                    labelText: 'Remarks',
                    controller: vm.remarksController,
                    enabled: edit,
                    maxLines: 2,
                  ),
                  AppSwitchTile(
                    label: 'Active',
                    value: vm.isActive,
                    onChanged: edit ? vm.setIsActive : null,
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
                    label: vm.selectedId == null ? 'Save' : 'Update',
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
                      icon: Icons.done_all_outlined,
                      label: 'Complete',
                      filled: false,
                      onPressed: vm.saving ? null : () => onComplete(),
                    ),
                  if (vm.canApprove)
                    AppActionButton(
                      icon: Icons.check_circle_outline,
                      label: 'Approve',
                      filled: false,
                      onPressed: vm.saving ? null : () => onApprove(),
                    ),
                  if (vm.canReject)
                    AppActionButton(
                      icon: Icons.block_outlined,
                      label: 'Reject',
                      filled: false,
                      onPressed: vm.saving ? null : () => onReject(),
                    ),
                  if (vm.canCancelInspection)
                    AppActionButton(
                      icon: Icons.cancel_outlined,
                      label: 'Cancel inspection',
                      filled: false,
                      onPressed: vm.saving ? null : () => onCancel(),
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
