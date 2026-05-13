import '../../screen.dart';
import '../../view_model/maintenance/maintenance_plan_view_model.dart';

class MaintenancePlanPage extends StatefulWidget {
  const MaintenancePlanPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<MaintenancePlanPage> createState() => _MaintenancePlanPageState();
}

class _MaintenancePlanPageState extends State<MaintenancePlanPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final MaintenancePlanViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MaintenancePlanViewModel()..load(selectId: widget.initialId);
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
        title: const Text('Delete maintenance plan'),
        content: const Text(
          'This removes the plan and its asset links. Continue?',
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
    await _viewModel.deletePlan();
    _snack();
    _openRoute('/maintenance/plans');
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
                    _openRoute('/maintenance/plans/new');
                    if (!Responsive.isDesktop(context)) {
                      _workspaceController.openEditor();
                    }
                  },
            icon: Icons.add_outlined,
            label: 'New maintenance plan',
          ),
        ];
        final content = _buildContent(context);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Maintenance plans',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading maintenance plans...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load maintenance plans',
        message: _viewModel.pageError!,
        onRetry: () => _viewModel.load(selectId: widget.initialId),
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Maintenance plans',
      editorTitle: _viewModel.selected == null
          ? 'New maintenance plan'
          : _viewModel.listTitle(_viewModel.selected!),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<MaintenancePlanModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search code, name, type, schedule',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No maintenance plans found.',
        itemBuilder: (row, selected) {
          final data = row.toJson();
          return SettingsListTile(
            title: _viewModel.listTitle(row),
            subtitle: [
              stringValue(data, 'plan_code'),
              stringValue(data, 'maintenance_type'),
              stringValue(data, 'schedule_basis'),
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
      editor: _MaintenancePlanEditor(
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

class _MaintenancePlanEditor extends StatelessWidget {
  const _MaintenancePlanEditor({
    required this.vm,
    required this.onSave,
    required this.onDelete,
  });

  final MaintenancePlanViewModel vm;
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
                  AppFormTextField(
                    labelText: 'Plan code',
                    controller: vm.planCodeController,
                    validator: Validators.required('Plan code'),
                  ),
                  AppFormTextField(
                    labelText: 'Plan name',
                    controller: vm.planNameController,
                    validator: Validators.required('Plan name'),
                  ),
                  AppFormTextField(
                    labelText: 'Maintenance type',
                    controller: vm.maintenanceTypeController,
                  ),
                  AppFormTextField(
                    labelText: 'Schedule basis',
                    controller: vm.scheduleBasisController,
                  ),
                  AppFormTextField(
                    labelText: 'Frequency value',
                    controller: vm.frequencyValueController,
                    keyboardType: TextInputType.number,
                  ),
                  AppFormTextField(
                    labelText: 'Checklist notes',
                    controller: vm.checklistNotesController,
                    maxLines: 4,
                  ),
                  SwitchListTile(
                    title: const Text('Auto-generate request'),
                    value: vm.isAutoGenerateRequest,
                    onChanged: (v) => vm.setIsAutoGenerateRequest(v),
                  ),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: vm.isActive,
                    onChanged: (v) => vm.setIsActive(v),
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
