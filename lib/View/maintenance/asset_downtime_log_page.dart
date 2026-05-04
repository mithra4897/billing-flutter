import '../../screen.dart';
import '../../view_model/maintenance/asset_downtime_log_view_model.dart';

class AssetDowntimeLogPage extends StatefulWidget {
  const AssetDowntimeLogPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<AssetDowntimeLogPage> createState() => _AssetDowntimeLogPageState();
}

class _AssetDowntimeLogPageState extends State<AssetDowntimeLogPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final AssetDowntimeLogViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AssetDowntimeLogViewModel()..load(selectId: widget.initialId);
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
        title: const Text('Delete downtime log'),
        content: const Text('Delete this downtime log?'),
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
    await _viewModel.deleteLog();
    _snack();
    _openRoute('/maintenance/downtime-logs');
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
                    _openRoute('/maintenance/downtime-logs/new');
                    if (!Responsive.isDesktop(context)) {
                      _workspaceController.openEditor();
                    }
                  },
            icon: Icons.add_outlined,
            label: 'New downtime log',
          ),
        ];
        final content = _buildContent(context);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Asset downtime logs',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading downtime logs...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load downtime logs',
        message: _viewModel.pageError!,
        onRetry: () => _viewModel.load(selectId: widget.initialId),
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Asset downtime logs',
      editorTitle: _viewModel.selected == null
          ? 'New downtime log'
          : _viewModel.listTitle(_viewModel.selected!),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<AssetDowntimeLogModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search reason, asset',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No downtime logs found.',
        itemBuilder: (row, selected) {
          final data = row.toJson();
          return SettingsListTile(
            title: _viewModel.listTitle(row),
            subtitle: [
              stringValue(data, 'downtime_reason'),
              stringValue(data, 'downtime_start'),
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
      editor: _DowntimeLogEditor(
        vm: _viewModel,
        onSave: (formContext) async {
          if (!Form.of(formContext).validate()) {
            return;
          }
          await _viewModel.save();
          _snack();
        },
        onDelete: _confirmDelete,
      ),
    );
  }
}

class _DowntimeLogEditor extends StatelessWidget {
  const _DowntimeLogEditor({
    required this.vm,
    required this.onSave,
    required this.onDelete,
  });

  final AssetDowntimeLogViewModel vm;
  final Future<void> Function(BuildContext formContext) onSave;
  final Future<void> Function() onDelete;

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
              SettingsFormWrap(
                children: [
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
                      vm.setAssetId(v);
                    },
                    validator: Validators.requiredSelection('Asset'),
                  ),
                  AppDropdownField<int?>.fromMapped(
                    labelText: 'Maintenance work order',
                    mappedItems: [
                      const AppDropdownItem<int?>(
                        value: null,
                        label: '—',
                      ),
                      ...vm.workOrders
                          .where((w) => intValue(w.toJson(), 'id') != null)
                          .map(
                            (w) => AppDropdownItem<int?>(
                              value: intValue(w.toJson(), 'id'),
                              label: vm.workOrderLabel(w),
                            ),
                          ),
                    ],
                    initialValue: vm.maintenanceWorkOrderId,
                    onChanged: (int? v) {
                      vm.setMaintenanceWorkOrderId(v);
                    },
                  ),
                  AppFormTextField(
                    labelText: 'Downtime reason',
                    controller: vm.downtimeReasonController,
                  ),
                  AppFormTextField(
                    labelText: 'Downtime start (ISO datetime)',
                    controller: vm.downtimeStartController,
                    validator: Validators.required('Downtime start'),
                  ),
                  AppFormTextField(
                    labelText: 'Downtime end (optional)',
                    controller: vm.downtimeEndController,
                  ),
                  AppFormTextField(
                    labelText: 'Production impact notes',
                    controller: vm.productionImpactController,
                    maxLines: 3,
                  ),
                  SwitchListTile(
                    title: const Text('Planned downtime'),
                    value: vm.isPlanned,
                    onChanged: vm.setIsPlanned,
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
                    onPressed: () => onSave(formContext),
                  ),
                  if (vm.selected != null)
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
