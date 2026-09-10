import '../../screen.dart';

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
  late final String _controllerTag;
  late final AssetCategoryViewModel _vm;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('AssetCategoryViewModel');
    _vm = Get.put(
      AssetCategoryViewModel()..load(selectId: widget.initialId),
      tag: _controllerTag,
      permanent: true,
    );
  }

  @override
  void dispose() {
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
    if (!widget.editorOnly) {
      return AssetCategoryRegisterPage(embedded: widget.embedded);
    }
    return GetBuilder<AssetCategoryViewModel>(
      tag: _controllerTag,
      builder: (_) {
        final actions = <Widget>[
          if (!widget.editorOnly)
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

  static const List<ErpLinkFieldOption<String>> _assetTypeOptions = [
    ErpLinkFieldOption(value: 'machinery', label: 'Machinery'),
    ErpLinkFieldOption(value: 'vehicle', label: 'Vehicle'),
    ErpLinkFieldOption(value: 'computer', label: 'Computer'),
    ErpLinkFieldOption(value: 'furniture', label: 'Furniture'),
    ErpLinkFieldOption(value: 'building', label: 'Building'),
    ErpLinkFieldOption(value: 'electrical', label: 'Electrical'),
    ErpLinkFieldOption(value: 'tool', label: 'Tool'),
    ErpLinkFieldOption(value: 'office_equipment', label: 'Office equipment'),
    ErpLinkFieldOption(value: 'other', label: 'Other'),
  ];

  static const List<ErpLinkFieldOption<String>> _depreciationMethodOptions = [
    ErpLinkFieldOption(value: 'straight_line', label: 'Straight line'),
    ErpLinkFieldOption(value: 'written_down_value', label: 'Written down value'),
    ErpLinkFieldOption(value: 'manual', label: 'Manual'),
  ];

  static ErpLinkFieldOption<T>? _selectedOption<T>(
    T? value,
    List<ErpLinkFieldOption<T>> options,
  ) {
    if (value == null) {
      return null;
    }
    for (final option in options) {
      if (option.value == value) {
        return option;
      }
    }
    return null;
  }

  static ErpLinkFieldOption<String>? _selectedTextOption(
    String text,
    List<ErpLinkFieldOption<String>> options,
  ) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    for (final option in options) {
      if (option.value.toLowerCase() == trimmed.toLowerCase()) {
        return option;
      }
    }
    return ErpLinkFieldOption<String>(value: trimmed, label: trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final isExisting = intValue(vm.detail?.toJson() ?? {}, 'id') != null;
    final parents = vm.parentOptions();
    final companyOptions = vm.companies
        .where((CompanyModel c) => c.id != null)
        .map(
          (CompanyModel c) => ErpLinkFieldOption<int>(
            value: c.id!,
            label: c.toString(),
          ),
        )
        .toList(growable: false);

    final parentOptions = parents
        .where((AssetCategoryModel c) => intValue(c.toJson(), 'id') != null)
        .map(
          (AssetCategoryModel c) => ErpLinkFieldOption<int>(
            value: intValue(c.toJson(), 'id')!,
            label: vm.listTitle(c),
          ),
        )
        .toList(growable: false);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (vm.formError != null) ...[
            AppErrorStateView.inline(message: vm.formError!),
            const SizedBox(height: AppUiConstants.spacingSm),
          ],
          if (vm.saving) const LinearProgressIndicator(),
          SettingsFormWrap(
            children: [
              ErpLinkField<int>(
                labelText: 'Company',
                doctypeLabel: 'Company',
                enabled: !vm.saving,
                isRequired: true,
                initialSelection: _selectedOption(vm.companyId, companyOptions),
                options: companyOptions,
                onChanged: vm.setCompanyId,
              ),
              AppFormTextField(
                labelText: 'Category code',
                controller: vm.categoryCodeController,
                isRequired: true,
              ),
              AppFormTextField(
                labelText: 'Category name',
                controller: vm.categoryNameController,
                isRequired: true,
              ),
              ErpLinkField<int>(
                labelText: 'Parent category',
                doctypeLabel: 'Asset category',
                enabled: !vm.saving,
                initialSelection: _selectedOption(
                  vm.parentCategoryId,
                  parentOptions,
                ),
                options: parentOptions,
                onChanged: vm.setParentCategoryId,
                onClear: () => vm.setParentCategoryId(null),
              ),
              ErpLinkField<String>(
                labelText: 'Asset type',
                doctypeLabel: 'Asset type',
                enabled: !vm.saving,
                initialSelection: _selectedTextOption(
                  vm.assetTypeController.text,
                  _assetTypeOptions,
                ),
                options: _assetTypeOptions,
                onChanged: (val) => vm.assetTypeController.text = val ?? '',
                onClear: () => vm.assetTypeController.clear(),
              ),
              ErpLinkField<String>(
                labelText: 'Default depreciation method',
                doctypeLabel: 'Depreciation method',
                enabled: !vm.saving,
                initialSelection: _selectedTextOption(
                  vm.defaultDepreciationMethodController.text,
                  _depreciationMethodOptions,
                ),
                options: _depreciationMethodOptions,
                onChanged: (val) =>
                    vm.defaultDepreciationMethodController.text = val ?? '',
                onClear: () => vm.defaultDepreciationMethodController.clear(),
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
