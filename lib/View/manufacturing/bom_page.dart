import '../../screen.dart';
import '../../view_model/manufacturing/bom_view_model.dart';
import '../purchase/purchase_support.dart';

class BomPage extends StatefulWidget {
  const BomPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<BomPage> createState() => _BomPageState();
}

class _BomPageState extends State<BomPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final BomViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = BomViewModel()..load(selectId: widget.initialId);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _pageScrollController.dispose();
    _workspaceController.dispose();
    super.dispose();
  }

  void _openShellRoute(String route) {
    final navigate = ShellRouteScope.maybeOf(context);
    if (navigate != null) {
      navigate(route);
      return;
    }
    Navigator.of(context).pushNamed(route);
  }

  void _showActionSnackBar() {
    final message = _viewModel.consumeActionMessage();
    if (!mounted || message == null || message.trim().isEmpty) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () {
              _viewModel.resetDraft();
              _openShellRoute('/manufacturing/boms/new');
              if (!Responsive.isDesktop(context)) {
                _workspaceController.openEditor();
              }
            },
            icon: Icons.add_outlined,
            label: 'New BOM',
          ),
        ];

        final content = _buildContent(context);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'BOM',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading BOMs...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load BOMs',
        message: _viewModel.pageError!,
        onRetry: _viewModel.load,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'BOM',
      editorTitle: _viewModel.selected == null
          ? 'New BOM'
          : stringValue(_viewModel.selected!.toJson(), 'bom_code', 'BOM'),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<BomModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search BOM',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No BOMs found.',
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'bom_code', 'BOM'),
            subtitle: [
              stringValue(data, 'bom_name'),
              stringValue(data, 'approval_status'),
            ].where((v) => v.trim().isNotEmpty).join(' · '),
            detail: stringValue(data, 'version_no'),
            selected: selected,
            onTap: () async {
              final isDesktop = Responsive.isDesktop(context);
              await _viewModel.select(item);
              if (!mounted) return;
              _openShellRoute('/manufacturing/boms/${intValue(data, 'id')}');
              if (!isDesktop) {
                _workspaceController.openEditor();
              }
            },
          );
        },
      ),
      editor: _BomEditor(
        vm: _viewModel,
        onSave: () async {
          await _viewModel.save();
          _showActionSnackBar();
          if (_viewModel.selected != null) {
            final id = intValue(_viewModel.selected!.toJson(), 'id');
            if (id != null) {
              _openShellRoute('/manufacturing/boms/$id');
            }
          }
        },
        onApprove: () async {
          await _viewModel.approve();
          _showActionSnackBar();
        },
        onDelete: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete BOM'),
              content: const Text(
                'Only non-approved BOMs can be deleted. Continue?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if (ok != true) return;
          await _viewModel.delete();
          _showActionSnackBar();
          _openShellRoute('/manufacturing/boms');
        },
      ),
    );
  }
}

class _BomEditor extends StatelessWidget {
  const _BomEditor({
    required this.vm,
    required this.onSave,
    required this.onApprove,
    required this.onDelete,
  });

  final BomViewModel vm;
  final Future<void> Function() onSave;
  final Future<void> Function() onApprove;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    if (vm.detailLoading) {
      return const AppLoadingView(message: 'Loading BOM...');
    }
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
                AppDropdownField<int>.fromMapped(
                  labelText: 'Company',
                  mappedItems: vm.companies
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem<int>(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: vm.companyId,
                  onChanged: vm.onCompanyChanged,
                  validator: Validators.requiredSelection('Company'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Branch',
                  mappedItems: vm.branchOptions
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem<int>(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: vm.branchId,
                  onChanged: vm.onBranchChanged,
                  validator: Validators.requiredSelection('Branch'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Location',
                  mappedItems: vm.locationOptions
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem<int>(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: vm.locationId,
                  onChanged: vm.onLocationChanged,
                  validator: Validators.requiredSelection('Location'),
                ),
                AppFormTextField(
                  labelText: 'BOM Code',
                  controller: vm.bomCodeController,
                  enabled: vm.canEdit,
                  validator: Validators.compose([
                    Validators.required('BOM Code'),
                    Validators.optionalMaxLength(100, 'BOM Code'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'BOM Name',
                  controller: vm.bomNameController,
                  enabled: vm.canEdit,
                  validator: Validators.compose([
                    Validators.required('BOM Name'),
                    Validators.optionalMaxLength(255, 'BOM Name'),
                  ]),
                ),
                AppSearchPickerField<int>(
                  labelText: 'Output Item',
                  selectedLabel: vm.outputItemOptions
                      .cast<ItemModel?>()
                      .firstWhere(
                        (item) => item?.id == vm.outputItemId,
                        orElse: () => null,
                      )
                      ?.toString(),
                  options: vm.outputItemOptions
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppSearchPickerOption<int>(
                          value: item.id!,
                          label: item.toString(),
                          subtitle: item.itemCode,
                        ),
                      )
                      .toList(growable: false),
                  validator: (_) => vm.outputItemId == null
                      ? 'Output Item is required'
                      : vm.outputItemOptions.every(
                          (item) => item.id != vm.outputItemId,
                        )
                      ? 'Choose a manufacturable output item'
                      : null,
                  onChanged: (value) {
                    vm.setOutputItemId(value);
                  },
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Output UOM',
                  mappedItems: vm
                      .uomOptionsForItem(vm.outputItemId)
                      .where((item) => item.id != null)
                      .map(
                        (item) => AppDropdownItem<int>(
                          value: item.id!,
                          label: item.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: vm.outputUomId,
                  onChanged: vm.setOutputUomId,
                  validator: Validators.requiredSelection('Output UOM'),
                ),
                AppFormTextField(
                  labelText: 'Version',
                  controller: vm.versionNoController,
                  enabled: vm.canEdit,
                  validator: Validators.optionalMaxLength(50, 'Version'),
                ),
                AppFormTextField(
                  labelText: 'Batch Size',
                  controller: vm.batchSizeController,
                  enabled: vm.canEdit,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.requiredPositiveNumber('Batch Size'),
                ),
                AppFormTextField(
                  labelText: 'Standard Output Qty',
                  controller: vm.standardOutputQtyController,
                  enabled: vm.canEdit,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.requiredPositiveNumber(
                    'Standard Output Qty',
                  ),
                ),
                AppFormTextField(
                  labelText: 'Notes',
                  controller: vm.notesController,
                  enabled: vm.canEdit,
                  maxLines: 2,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Row(
              children: [
                Text(
                  'Lines',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                AppActionButton(
                  icon: Icons.add_outlined,
                  label: 'Add line',
                  filled: false,
                  onPressed: vm.canEdit ? vm.addLine : null,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            ...List<Widget>.generate(vm.lines.length, (index) {
              final line = vm.lines[index];
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: AppUiConstants.spacingSm,
                ),
                child: PurchaseCompactLineCard(
                  index: index,
                  total: vm.lines.length,
                  removeEnabled: vm.canEdit && vm.lines.length > 1,
                  onRemove: vm.canEdit ? () => vm.removeLine(index) : null,
                  child: PurchaseCompactFieldGrid(
                    children: [
                      AppSearchPickerField<int>(
                        labelText: 'Item',
                        selectedLabel: vm.items
                            .cast<ItemModel?>()
                            .firstWhere(
                              (item) => item?.id == line.itemId,
                              orElse: () => null,
                            )
                            ?.toString(),
                        options: vm.items
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppSearchPickerOption<int>(
                                value: item.id!,
                                label: item.toString(),
                                subtitle: item.itemCode,
                              ),
                            )
                            .toList(growable: false),
                        validator: (_) =>
                            line.itemId == null ? 'Item is required' : null,
                        onChanged: (value) => vm.setLineItemId(index, value),
                      ),
                      AppDropdownField<int>.fromMapped(
                        labelText: 'UOM',
                        mappedItems: vm
                            .uomOptionsForItem(line.itemId)
                            .where((item) => item.id != null)
                            .map(
                              (item) => AppDropdownItem<int>(
                                value: item.id!,
                                label: item.toString(),
                              ),
                            )
                            .toList(growable: false),
                        initialValue: line.uomId,
                        onChanged: (value) => vm.setLineUomId(index, value),
                        validator: Validators.requiredSelection('UOM'),
                      ),
                      AppFormTextField(
                        labelText: 'Required Qty',
                        controller: line.requiredQtyController,
                        enabled: vm.canEdit,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.requiredPositiveNumber(
                          'Required Qty',
                        ),
                      ),
                      AppFormTextField(
                        labelText: 'Wastage %',
                        controller: line.wastagePercentController,
                        enabled: vm.canEdit,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validators.optionalNonNegativeNumber(
                          'Wastage %',
                        ),
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
                AppActionButton(
                  icon: Icons.save_outlined,
                  label: vm.selected == null ? 'Save BOM' : 'Update BOM',
                  busy: vm.saving,
                  onPressed: () async {
                    if (!Form.of(formContext).validate()) return;
                    await onSave();
                  },
                ),
                if (vm.selected != null && !vm.isApproved)
                  AppActionButton(
                    icon: Icons.task_alt_outlined,
                    label: 'Approve',
                    filled: false,
                    onPressed: onApprove,
                  ),
                if (vm.selected != null && !vm.isApproved)
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
