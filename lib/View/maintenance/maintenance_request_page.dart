import '../../screen.dart';
import '../../view_model/maintenance/maintenance_request_view_model.dart';

class MaintenanceRequestPage extends StatefulWidget {
  const MaintenanceRequestPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<MaintenanceRequestPage> createState() => _MaintenanceRequestPageState();
}

class _MaintenanceRequestPageState extends State<MaintenanceRequestPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final MaintenanceRequestViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MaintenanceRequestViewModel()
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
        title: const Text('Delete maintenance request'),
        content: const Text(
          'Only draft or open requests can be deleted. Continue?',
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
    await _viewModel.deleteRequest();
    _snack();
    _openRoute('/maintenance/requests');
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
                    _openRoute('/maintenance/requests/new');
                    if (!Responsive.isDesktop(context)) {
                      _workspaceController.openEditor();
                    }
                  },
            icon: Icons.add_outlined,
            label: 'New request',
          ),
        ];
        final content = _buildContent(context);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Maintenance requests',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading maintenance requests...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load maintenance requests',
        message: _viewModel.pageError!,
        onRetry: () => _viewModel.load(selectId: widget.initialId),
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Maintenance requests',
      editorTitle: _viewModel.selected == null
          ? 'New maintenance request'
          : _viewModel.listTitle(_viewModel.selected!),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<MaintenanceRequestModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search no., title, status, type',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No maintenance requests found.',
        itemBuilder: (row, selected) {
          final data = row.toJson();
          return SettingsListTile(
            title: _viewModel.listTitle(row),
            subtitle: [
              stringValue(data, 'request_status'),
              stringValue(data, 'request_type'),
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
      editor: _MaintenanceRequestEditor(
        vm: _viewModel,
        onSave: (formContext) async {
          if (!Form.of(formContext).validate()) {
            return;
          }
          await _viewModel.save();
          _snack();
        },
        onDelete: _confirmDelete,
        onApprove: () async {
          await _viewModel.approveRequest();
          _snack();
        },
        onCancel: () async {
          await _viewModel.cancelRequest();
          _snack();
        },
      ),
    );
  }
}

class _MaintenanceRequestEditor extends StatelessWidget {
  const _MaintenanceRequestEditor({
    required this.vm,
    required this.onSave,
    required this.onDelete,
    required this.onApprove,
    required this.onCancel,
  });

  final MaintenanceRequestViewModel vm;
  final Future<void> Function(BuildContext formContext) onSave;
  final Future<void> Function() onDelete;
  final Future<void> Function() onApprove;
  final Future<void> Function() onCancel;

  @override
  Widget build(BuildContext context) {
    if (vm.detailLoading) {
      return const AppLoadingView(message: 'Loading document...');
    }

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
                    if (vm.canCancel)
                      FilledButton.tonal(
                        onPressed: vm.saving ? null : () => onCancel(),
                        child: const Text('Cancel request'),
                      ),
                  ],
                ),
                const SizedBox(height: AppUiConstants.spacingMd),
              ],
              SettingsFormWrap(
                children: [
                  if (vm.selected == null) ...[
                    AppDropdownField<int?>.fromMapped(
                      labelText: 'Document series (for auto no.)',
                      mappedItems: [
                        const AppDropdownItem<int?>(value: null, label: '—'),
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
                      labelText: 'Request no. (or use series above)',
                      controller: vm.requestNoController,
                    ),
                  ] else
                    AppFormTextField(
                      labelText: 'Request no.',
                      controller: vm.requestNoController,
                      readOnly: true,
                    ),
                  AppFormTextField(
                    labelText: 'Request date',
                    controller: vm.requestDateController,
                    readOnly: !vm.canEdit,
                    validator: Validators.required('Request date'),
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Asset',
                    mappedItems: vm.assets
                        .map(
                          (a) => AppDropdownItem<int>(
                            value: intValue(a.toJson(), 'id')!,
                            label: vm.assetLabel(a),
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
                    labelText: 'Maintenance plan',
                    mappedItems: [
                      const AppDropdownItem<int?>(value: null, label: '—'),
                      ...vm.maintenancePlans
                          .where((p) => intValue(p.toJson(), 'id') != null)
                          .map((p) {
                            final d = p.toJson();
                            final code = stringValue(d, 'plan_code');
                            final name = stringValue(d, 'plan_name');
                            final label = [
                              code,
                              name,
                            ].where((x) => x.trim().isNotEmpty).join(' — ');
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
                  AppFormTextField(
                    labelText: 'Issue title',
                    controller: vm.issueTitleController,
                    readOnly: !vm.canEdit,
                    validator: Validators.required('Issue title'),
                  ),
                  AppFormTextField(
                    labelText: 'Issue description',
                    controller: vm.issueDescriptionController,
                    maxLines: 4,
                    readOnly: !vm.canEdit,
                  ),
                  AppFormTextField(
                    labelText: 'Request type',
                    controller: vm.requestTypeController,
                    readOnly: !vm.canEdit,
                  ),
                  AppFormTextField(
                    labelText: 'Priority',
                    controller: vm.priorityLevelController,
                    readOnly: !vm.canEdit,
                  ),
                  AppFormTextField(
                    labelText: 'Requested by (user id)',
                    controller: vm.requestedByController,
                    keyboardType: TextInputType.number,
                    readOnly: !vm.canEdit,
                  ),
                  AppFormTextField(
                    labelText: 'Target completion date',
                    controller: vm.targetCompletionController,
                    readOnly: !vm.canEdit,
                  ),
                  AppFormTextField(
                    labelText: 'Remarks',
                    controller: vm.remarksController,
                    maxLines: 3,
                    readOnly: !vm.canEdit,
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
