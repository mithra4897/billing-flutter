import '../../screen.dart';
import '../../view_model/assets/asset_category_view_model.dart';
import 'asset_shell_route.dart';

class AssetCategoryPage extends StatefulWidget {
  const AssetCategoryPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<AssetCategoryPage> createState() => _AssetCategoryPageState();
}

class _AssetCategoryPageState extends State<AssetCategoryPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final AssetCategoryViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = AssetCategoryViewModel()..load(selectId: widget.initialId);
  }

  @override
  void dispose() {
    _vm.dispose();
    _pageScrollController.dispose();
    _workspaceController.dispose();
    super.dispose();
  }

  void _snack() {
    final msg = _vm.consumeActionMessage();
    if (!mounted || msg == null || msg.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _vm,
      builder: (context, _) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () {
              _vm.resetDraft();
              if (!Responsive.isDesktop(context)) {
                _workspaceController.openEditor();
              }
            },
            icon: Icons.add_outlined,
            label: 'New category',
          ),
        ];
        final content = _buildContent(context);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Asset categories',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_vm.loading) {
      return const AppLoadingView(message: 'Loading categories...');
    }
    if (_vm.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load categories',
        message: _vm.pageError!,
        onRetry: () => _vm.load(selectId: widget.initialId),
      );
    }

    final editorTitle = _vm.detail != null || _vm.selected != null
        ? () {
            final m = _vm.detail ?? _vm.selected;
            if (m == null) {
              return 'Asset category';
            }
            final data = m.toJson();
            final name = stringValue(data, 'category_name');
            final code = stringValue(data, 'category_code');
            if (name.isNotEmpty) {
              return name;
            }
            if (code.isNotEmpty) {
              return code;
            }
            final id = intValue(data, 'id');
            return id != null ? 'Category #$id' : 'Asset category';
          }()
        : 'New asset category';

    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Asset categories',
      editorTitle: editorTitle,
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<AssetCategoryModel>(
        searchController: _vm.searchController,
        searchHint: 'Search code, name, type, parent',
        items: _vm.filteredRows,
        selectedItem: _vm.selected,
        emptyMessage: 'No categories found.',
        itemBuilder: (item, selected) {
          return SettingsListTile(
            title: _vm.listTitle(item),
            subtitle: _vm.listSubtitle(item),
            selected: selected,
            onTap: () async {
              final isDesktop = Responsive.isDesktop(context);
              await _vm.select(item);
              if (!mounted) {
                return;
              }
              if (!isDesktop) {
                _workspaceController.openEditor();
              }
            },
          );
        },
      ),
      editor: _vm.detailLoading
          ? const AppLoadingView(message: 'Loading category...')
          : _AssetCategoryEditor(
              vm: _vm,
              onSave: () async {
                final ok = await _vm.save();
                if (!mounted) {
                  return;
                }
                if (ok) {
                  _snack();
                }
              },
              onDelete: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete category'),
                    content: const Text(
                      'Only categories without assets or child categories '
                      'can be deleted.',
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
                if (ok != true) {
                  return;
                }
                final deleted = await _vm.deleteCategory();
                if (!context.mounted) {
                  return;
                }
                if (deleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category deleted.')),
                  );
                  openAssetShellRoute(context, '/assets/categories');
                } else {
                  _snack();
                }
              },
            ),
    );
  }
}

class _AssetCategoryEditor extends StatelessWidget {
  const _AssetCategoryEditor({
    required this.vm,
    required this.onSave,
    required this.onDelete,
  });

  final AssetCategoryViewModel vm;
  final Future<void> Function() onSave;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExisting = intValue(vm.detail?.toJson() ?? {}, 'id') != null;
    final parents = vm.parentOptions();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (vm.formError != null) ...[
            AppErrorStateView.inline(message: vm.formError!),
            const SizedBox(height: AppUiConstants.spacingSm),
          ],
          Text(
            isExisting ? 'Edit category' : 'New category',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          if (vm.saving) const LinearProgressIndicator(),
          SettingsFormWrap(
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Company',
                  border: OutlineInputBorder(),
                ),
                initialValue: vm.companyId,
                items: vm.companies
                    .where((CompanyModel c) => c.id != null)
                    .map(
                      (CompanyModel c) => DropdownMenuItem<int>(
                        value: c.id,
                        child: Text(c.toString()),
                      ),
                    )
                    .toList(growable: false),
                onChanged: vm.saving ? null : (int? v) => vm.setCompanyId(v),
              ),
              AppFormTextField(
                labelText: 'Category code',
                controller: vm.categoryCodeController,
              ),
              AppFormTextField(
                labelText: 'Category name',
                controller: vm.categoryNameController,
              ),
              DropdownButtonFormField<int?>(
                decoration: const InputDecoration(
                  labelText: 'Parent category',
                  border: OutlineInputBorder(),
                ),
                initialValue: vm.parentCategoryId,
                items: <DropdownMenuItem<int?>>[
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('None'),
                  ),
                  ...parents
                      .where(
                        (AssetCategoryModel c) =>
                            intValue(c.toJson(), 'id') != null,
                      )
                      .map(
                        (AssetCategoryModel c) => DropdownMenuItem<int?>(
                          value: intValue(c.toJson(), 'id'),
                          child: Text(vm.listTitle(c)),
                        ),
                      ),
                ],
                onChanged: vm.saving
                    ? null
                    : (int? v) => vm.setParentCategoryId(v),
              ),
              AppFormTextField(
                labelText: 'Asset type',
                controller: vm.assetTypeController,
                hintText: 'e.g. tangible, intangible',
              ),
              AppFormTextField(
                labelText: 'Default depreciation method',
                controller: vm.defaultDepreciationMethodController,
                hintText: 'e.g. straight_line',
              ),
              AppFormTextField(
                labelText: 'Default useful life (months)',
                controller: vm.defaultUsefulLifeMonthsController,
                keyboardType: TextInputType.number,
              ),
              AppFormTextField(
                labelText: 'Default salvage value',
                controller: vm.defaultSalvageValueController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              AppFormTextField(
                labelText: 'Capitalization threshold',
                controller: vm.capitalizationThresholdController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              AppFormTextField(
                labelText: 'Remarks',
                controller: vm.remarksController,
                maxLines: 3,
              ),
            ],
          ),
          SwitchListTile(
            title: const Text('Active'),
            value: vm.isActive,
            onChanged: vm.saving ? null : (bool v) => vm.setIsActive(v),
          ),
          SwitchListTile(
            title: const Text('Depreciable'),
            value: vm.isDepreciable,
            onChanged: vm.saving ? null : (bool v) => vm.setIsDepreciable(v),
          ),
          SwitchListTile(
            title: const Text('Tag required'),
            value: vm.isTagRequired,
            onChanged: vm.saving ? null : (bool v) => vm.setIsTagRequired(v),
          ),
          SwitchListTile(
            title: const Text('Serial required'),
            value: vm.isSerialRequired,
            onChanged: vm.saving ? null : (bool v) => vm.setIsSerialRequired(v),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          Wrap(
            spacing: AppUiConstants.spacingSm,
            runSpacing: AppUiConstants.spacingSm,
            children: [
              FilledButton(
                onPressed: vm.saving ? null : () => onSave(),
                child: vm.saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isExisting ? 'Save' : 'Create'),
              ),
              if (isExisting)
                OutlinedButton(
                  onPressed: vm.saving ? null : () => onDelete(),
                  child: const Text('Delete'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
