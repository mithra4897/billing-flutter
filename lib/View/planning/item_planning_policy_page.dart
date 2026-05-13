import '../../screen.dart';
import '../../view_model/planning/item_planning_policy_view_model.dart';

class ItemPlanningPolicyPage extends StatefulWidget {
  const ItemPlanningPolicyPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<ItemPlanningPolicyPage> createState() => _ItemPlanningPolicyPageState();
}

class _ItemPlanningPolicyPageState extends State<ItemPlanningPolicyPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final ItemPlanningPolicyViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ItemPlanningPolicyViewModel()
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
    if (!mounted || msg == null || msg.trim().isEmpty) return;
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
            onPressed: () {
              _viewModel.resetDraft();
              if (widget.editorOnly || !isDesktop) {
                _openRoute('/planning/item-policies/new');
              }
              if (!isDesktop) _workspaceController.openEditor();
            },
            icon: Icons.add_outlined,
            label: 'New Item Policy',
          ),
        ];
        final content = _buildContent();
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Item Planning Policies',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent() {
    if (_viewModel.loading)
      return const AppLoadingView(message: 'Loading item policies...');
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load item policies',
        message: _viewModel.pageError!,
        onRetry: _viewModel.load,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Item Planning Policies',
      editorTitle: _viewModel.selected == null
          ? 'New Item Policy'
          : 'Policy #${intValue(_viewModel.selected!.toJson(), 'id') ?? ''}',
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<ItemPlanningPolicyModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search item policies',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No item policies found.',
        itemBuilder: (item, selected) {
          final data = item.toJson();
          final itemMap = data['item'] is Map<String, dynamic>
              ? data['item'] as Map<String, dynamic>
              : const <String, dynamic>{};
          return SettingsListTile(
            title: stringValue(itemMap, 'item_name', 'Item Policy'),
            subtitle: stringValue(data, 'planning_method'),
            selected: selected,
            onTap: () async {
              final id = intValue(data, 'id');
              final isDesktop = Responsive.isDesktop(context);
              await _viewModel.select(item);
              if (!mounted || id == null) return;
              if (widget.editorOnly || !isDesktop) {
                _openRoute('/planning/item-policies/$id');
              }
              if (!isDesktop) _workspaceController.openEditor();
            },
          );
        },
      ),
      editor: _viewModel.detailLoading
          ? const AppLoadingView(message: 'Loading item policy...')
          : _ItemPolicyEditor(
              vm: _viewModel,
              onSave: () async {
                await _viewModel.save();
                _snack();
              },
              onDelete: () async {
                final shouldNavigateBack =
                    widget.editorOnly || !Responsive.isDesktop(context);
                await _viewModel.delete();
                _snack();
                if (shouldNavigateBack) {
                  _openRoute('/planning/item-policies');
                }
              },
            ),
    );
  }
}

class _ItemPolicyEditor extends StatelessWidget {
  const _ItemPolicyEditor({
    required this.vm,
    required this.onSave,
    required this.onDelete,
  });
  final ItemPlanningPolicyViewModel vm;
  final Future<void> Function() onSave;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Builder(
        builder: (formContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vm.formError != null) ...[
              AppErrorStateView.inline(message: vm.formError!),
              const SizedBox(height: AppUiConstants.spacingSm),
            ],
            SettingsFormWrap(
              children: [
                AppSearchPickerField<int>(
                  labelText: 'Item',
                  selectedLabel: vm.items
                      .cast<ItemModel?>()
                      .firstWhere((x) => x?.id == vm.itemId, orElse: () => null)
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
                  onChanged: vm.setItemId,
                  validator: (_) =>
                      vm.itemId == null ? 'Item is required' : null,
                ),
                AppFormTextField(
                  labelText: 'Planning Method',
                  controller: vm.planningMethodController,
                ),
                AppFormTextField(
                  labelText: 'Procurement Type',
                  controller: vm.procurementTypeController,
                ),
                AppFormTextField(
                  labelText: 'Reorder Level Qty',
                  controller: vm.reorderLevelQtyController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                AppFormTextField(
                  labelText: 'Reorder Qty',
                  controller: vm.reorderQtyController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                AppSwitchTile(
                  label: 'MRP Enabled',
                  value: vm.isMrpEnabled,
                  onChanged: vm.setIsMrpEnabled,
                ),
                AppSwitchTile(
                  label: 'Reorder Enabled',
                  value: vm.isReorderEnabled,
                  onChanged: vm.setIsReorderEnabled,
                ),
                AppSwitchTile(
                  label: 'Active',
                  value: vm.isActive,
                  onChanged: vm.setIsActive,
                ),
                AppFormTextField(
                  labelText: 'Remarks',
                  controller: vm.remarksController,
                  maxLines: 2,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              children: [
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: vm.selected == null ? 'Save' : 'Update',
                  busy: vm.saving,
                  onPressed: () async {
                    if (!Form.of(formContext).validate()) return;
                    await onSave();
                  },
                ),
                if (vm.selected != null)
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
    );
  }
}
