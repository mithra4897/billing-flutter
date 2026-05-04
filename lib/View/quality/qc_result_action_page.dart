import '../../screen.dart';
import '../../view_model/quality/qc_result_action_view_model.dart';

String _inspectionNoLabel(QcInspectionModel i) {
  final no = stringValue(i.toJson(), 'inspection_no');
  if (no.isNotEmpty) {
    return no;
  }
  final id = intValue(i.toJson(), 'id');
  return id != null ? 'Inspection #$id' : '';
}

class QcResultActionPage extends StatefulWidget {
  const QcResultActionPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<QcResultActionPage> createState() => _QcResultActionPageState();
}

class _QcResultActionPageState extends State<QcResultActionPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final QcResultActionViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = QcResultActionViewModel()..load(selectId: widget.initialId);
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
            label: 'New result action',
          ),
        ];
        final content = _buildContent(context);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'QC result actions',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading result actions...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load result actions',
        message: _viewModel.pageError!,
        onRetry: () => _viewModel.load(selectId: widget.initialId),
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'QC result actions',
      editorTitle:
          _viewModel.selected?.toString() ?? 'New QC result action',
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<QcResultActionModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search inspection, type, status',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No QC result actions found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: row.actionType.isNotEmpty ? row.actionType : 'Action',
          subtitle: [
            row.actionStatus,
            row.inspectionNoLabel,
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
      editor: _QcResultActionEditor(
        vm: _viewModel,
        inspectionLabel: _inspectionNoLabel,
        onSave: (formContext) async {
          if (!Form.of(formContext).validate()) {
            return;
          }
          await _viewModel.save();
          _snack();
        },
        onComplete: () async {
          await _viewModel.completeAction();
          _snack();
        },
        onCancel: () async {
          await _viewModel.cancelAction();
          _snack();
        },
        onDelete: () async {
          await _viewModel.deleteAction();
          _snack();
        },
      ),
    );
  }
}

class _QcResultActionEditor extends StatelessWidget {
  const _QcResultActionEditor({
    required this.vm,
    required this.inspectionLabel,
    required this.onSave,
    required this.onComplete,
    required this.onCancel,
    required this.onDelete,
  });

  final QcResultActionViewModel vm;
  final String Function(QcInspectionModel i) inspectionLabel;
  final Future<void> Function(BuildContext formContext) onSave;
  final Future<void> Function() onComplete;
  final Future<void> Function() onCancel;
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
                    mappedItems: vm.inspectionOptions
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
                  AppDropdownField<String>.fromMapped(
                    labelText: 'Action type',
                    mappedItems: kQcResultActionTypeItems,
                    initialValue: vm.actionType.isNotEmpty
                        ? vm.actionType
                        : 'accept_to_stock',
                    onChanged: (String? v) {
                      if (edit && v != null) {
                        vm.setActionType(v);
                      }
                    },
                  ),
                  AppFormTextField(
                    labelText: 'Action qty',
                    controller: vm.actionQtyController,
                    enabled: edit,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: Validators.compose([
                      Validators.required('Action qty'),
                      (v) {
                        final q = double.tryParse((v ?? '').trim());
                        if (q == null || q <= 0) {
                          return 'Enter a quantity greater than zero';
                        }
                        return null;
                      },
                    ]),
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Target warehouse (optional)',
                    mappedItems: vm
                        .warehouseOptionsForInspection(vm.qcInspectionId)
                        .where((w) => w.id != null)
                        .map(
                          (w) => AppDropdownItem<int>(
                            value: w.id!,
                            label: w.toString(),
                          ),
                        )
                        .toList(growable: false),
                    initialValue: vm.targetWarehouseId,
                    onChanged: (int? v) {
                      if (edit) {
                        vm.setTargetWarehouseId(v);
                      }
                    },
                  ),
                  AppFormTextField(
                    labelText: 'Reference document type (optional)',
                    controller: vm.referenceDocTypeController,
                    enabled: edit,
                  ),
                  AppFormTextField(
                    labelText: 'Reference document id (optional)',
                    controller: vm.referenceDocIdController,
                    enabled: edit,
                    keyboardType: TextInputType.number,
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
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(vm.actionStatus),
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
                  if (vm.canComplete)
                    AppActionButton(
                      icon: Icons.check_circle_outline,
                      label: 'Complete',
                      filled: false,
                      onPressed: vm.saving ? null : () => onComplete(),
                    ),
                  if (vm.canCancel)
                    AppActionButton(
                      icon: Icons.cancel_outlined,
                      label: 'Cancel action',
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
