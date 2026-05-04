import '../../screen.dart';
import '../../view_model/quality/qc_non_conformance_log_view_model.dart';

String _inspectionNoLabel(QcInspectionModel i) {
  final no = stringValue(i.toJson(), 'inspection_no');
  if (no.isNotEmpty) {
    return no;
  }
  final id = intValue(i.toJson(), 'id');
  return id != null ? 'Inspection #$id' : '';
}

class QcNonConformanceLogPage extends StatefulWidget {
  const QcNonConformanceLogPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<QcNonConformanceLogPage> createState() =>
      _QcNonConformanceLogPageState();
}

class _QcNonConformanceLogPageState extends State<QcNonConformanceLogPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final QcNonConformanceLogViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = QcNonConformanceLogViewModel()
      ..load(selectId: widget.initialId);
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
                : () async {
                    await _viewModel.resetDraft();
                    if (!context.mounted) {
                      return;
                    }
                    if (!Responsive.isDesktop(context)) {
                      _workspaceController.openEditor();
                    }
                  },
            icon: Icons.add_outlined,
            label: 'New NCR log',
          ),
        ];
        final content = _buildContent(context);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Non-conformance logs',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading non-conformance logs...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load logs',
        message: _viewModel.pageError!,
        onRetry: () => _viewModel.load(selectId: widget.initialId),
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Non-conformance logs',
      editorTitle: _viewModel.selected?.toString() ?? 'New NCR log',
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<QcNonConformanceLogModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search defect, inspection, closure',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No non-conformance logs found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: row.defectName.isNotEmpty ? row.defectName : 'Defect',
          subtitle: [
            row.closureStatus,
            row.inspectionNoLabel,
            row.severity ?? '',
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
        ),
      ),
      editor: _QcNonConformanceEditor(
        vm: _viewModel,
        inspectionLabel: _inspectionNoLabel,
        onSave: (formContext) async {
          if (!Form.of(formContext).validate()) {
            return;
          }
          await _viewModel.save();
          _snack();
        },
        onClose: () async {
          await _viewModel.closeLog();
          _snack();
        },
        onWaive: () async {
          await _viewModel.waiveLog();
          _snack();
        },
        onDelete: () async {
          await _viewModel.deleteLog();
          _snack();
        },
      ),
    );
  }
}

class _QcNonConformanceEditor extends StatelessWidget {
  const _QcNonConformanceEditor({
    required this.vm,
    required this.inspectionLabel,
    required this.onSave,
    required this.onClose,
    required this.onWaive,
    required this.onDelete,
  });

  final QcNonConformanceLogViewModel vm;
  final String Function(QcInspectionModel i) inspectionLabel;
  final Future<void> Function(BuildContext formContext) onSave;
  final Future<void> Function() onClose;
  final Future<void> Function() onWaive;
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
                    labelText: 'QC inspection',
                    mappedItems: vm.inspections
                        .map((i) {
                          final iid = intValue(i.toJson(), 'id');
                          if (iid == null) {
                            return null;
                          }
                          return AppDropdownItem<int>(
                            value: iid,
                            label: inspectionLabel(i),
                          );
                        })
                        .whereType<AppDropdownItem<int>>()
                        .toList(growable: false),
                    initialValue: vm.qcInspectionId,
                    onChanged: (int? v) {
                      if (edit) {
                        vm.setQcInspectionId(v);
                      }
                    },
                    validator: Validators.requiredSelection('QC inspection'),
                  ),
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Inspection line (optional)',
                    mappedItems: [
                      const AppDropdownItem<int?>(
                        value: null,
                        label: '—',
                      ),
                      ...vm.inspectionLineOptions.map(
                        (o) => AppDropdownItem<int?>(
                          value: o.id,
                          label: o.label,
                        ),
                      ),
                    ],
                    initialValue: vm.qcInspectionLineId,
                    onChanged: (int? v) {
                      if (edit) {
                        vm.setQcInspectionLineId(v);
                      }
                    },
                  ),
                  AppFormTextField(
                    labelText: 'Defect code (optional)',
                    controller: vm.defectCodeController,
                    enabled: edit,
                  ),
                  AppFormTextField(
                    labelText: 'Defect name',
                    controller: vm.defectNameController,
                    enabled: edit,
                    validator: Validators.required('Defect name'),
                  ),
                  AppFormTextField(
                    labelText: 'Severity (optional)',
                    controller: vm.severityController,
                    enabled: edit,
                  ),
                  AppFormTextField(
                    labelText: 'Defect qty',
                    controller: vm.defectQtyController,
                    enabled: edit,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: Validators.compose([
                      Validators.required('Defect qty'),
                      (v) {
                        final q = double.tryParse((v ?? '').trim());
                        if (q == null || q <= 0) {
                          return 'Enter a quantity greater than zero';
                        }
                        return null;
                      },
                    ]),
                  ),
                  AppFormTextField(
                    labelText: 'Root cause (optional)',
                    controller: vm.rootCauseController,
                    enabled: edit,
                    maxLines: 2,
                  ),
                  AppFormTextField(
                    labelText: 'Corrective action (optional)',
                    controller: vm.correctiveActionController,
                    enabled: edit,
                    maxLines: 2,
                  ),
                  AppFormTextField(
                    labelText: 'Preventive action (optional)',
                    controller: vm.preventiveActionController,
                    enabled: edit,
                    maxLines: 2,
                  ),
                  AppFormTextField(
                    labelText: 'Assigned to (user id, optional)',
                    controller: vm.assignedToController,
                    enabled: edit,
                    keyboardType: TextInputType.number,
                  ),
                  AppFormTextField(
                    labelText: 'Due date (optional)',
                    controller: vm.dueDateController,
                    enabled: edit,
                    inputFormatters: const [DateInputFormatter()],
                    validator: Validators.optionalDate('Due date'),
                  ),
                  AppFormTextField(
                    labelText: 'Remarks (optional)',
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
                          labelText: 'Closure status',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(vm.closureStatus),
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
                  if (vm.canClose)
                    AppActionButton(
                      icon: Icons.lock_outline,
                      label: 'Close',
                      filled: false,
                      onPressed: vm.saving ? null : () => onClose(),
                    ),
                  if (vm.canWaive)
                    AppActionButton(
                      icon: Icons.outbond_outlined,
                      label: 'Waive',
                      filled: false,
                      onPressed: vm.saving ? null : () => onWaive(),
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
