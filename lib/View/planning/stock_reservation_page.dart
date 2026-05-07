import '../../screen.dart';
import '../../view_model/planning/stock_reservation_view_model.dart';

class StockReservationPage extends StatefulWidget {
  const StockReservationPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<StockReservationPage> createState() => _StockReservationPageState();
}

class _StockReservationPageState extends State<StockReservationPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final StockReservationViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = StockReservationViewModel()..load(selectId: widget.initialId);
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
                _openRoute('/planning/stock-reservations/new');
              }
              if (!Responsive.isDesktop(context)) {
                _workspaceController.openEditor();
              }
            },
            icon: Icons.add_outlined,
            label: 'New Stock Reservation',
          ),
        ];
        final content = _buildContent();
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Stock Reservations',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent() {
    if (_viewModel.loading) {
      return const AppLoadingView(message: 'Loading stock reservations...');
    }
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load stock reservations',
        message: _viewModel.pageError!,
        onRetry: _viewModel.load,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Stock Reservations',
      editorTitle: _viewModel.selected == null
          ? 'New Stock Reservation'
          : 'Reservation #${intValue(_viewModel.selected!.toJson(), 'id') ?? ''}',
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<StockReservationModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search reference, item, status',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No stock reservations found.',
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title:
                '${stringValue(data, 'reference_type')} #${intValue(data, 'reference_id') ?? '—'}',
            subtitle: [
              stringValue(data, 'status'),
              stringValue(data, 'reserved_qty'),
            ].where((x) => x.trim().isNotEmpty).join(' · '),
            selected: selected,
            onTap: () async {
              final isDesktop = Responsive.isDesktop(context);
              await _viewModel.select(item);
              if (!mounted) return;
              final id = intValue(data, 'id');
              if (id != null && (widget.editorOnly || !isDesktop)) {
                _openRoute('/planning/stock-reservations/$id');
              }
              if (!isDesktop) _workspaceController.openEditor();
            },
          );
        },
      ),
      editor: _viewModel.detailLoading
          ? const AppLoadingView(message: 'Loading stock reservation...')
          : _StockReservationEditor(
              vm: _viewModel,
              onSave: () async {
                await _viewModel.save();
                _snack();
              },
              onRelease: () async {
                await _viewModel.release();
                _snack();
              },
              onDelete: () async {
                final shouldNavigateBack =
                    widget.editorOnly || !Responsive.isDesktop(context);
                await _viewModel.delete();
                _snack();
                if (shouldNavigateBack) {
                  _openRoute('/planning/stock-reservations');
                }
              },
            ),
    );
  }
}

class _StockReservationEditor extends StatelessWidget {
  const _StockReservationEditor({
    required this.vm,
    required this.onSave,
    required this.onRelease,
    required this.onDelete,
  });

  final StockReservationViewModel vm;
  final Future<void> Function() onSave;
  final Future<void> Function() onRelease;
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
                AppDropdownField<int>.fromMapped(
                  labelText: 'Company',
                  mappedItems: vm.companies
                      .where((x) => x.id != null)
                      .map((x) => AppDropdownItem<int>(value: x.id!, label: x.toString()))
                      .toList(growable: false),
                  initialValue: vm.companyId,
                  onChanged: vm.onCompanyChanged,
                  validator: Validators.requiredSelection('Company'),
                ),
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
                  validator: (_) => vm.itemId == null ? 'Item is required' : null,
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Warehouse',
                  mappedItems: vm.warehouseOptions
                      .where((x) => x.id != null)
                      .map((x) => AppDropdownItem<int>(value: x.id!, label: x.toString()))
                      .toList(growable: false),
                  initialValue: vm.warehouseId,
                  onChanged: vm.setWarehouseId,
                  validator: Validators.requiredSelection('Warehouse'),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Batch (optional)',
                  mappedItems: vm.batchOptions
                      .where((x) => intValue(x.toJson(), 'id') != null)
                      .map(
                        (x) => AppDropdownItem<int>(
                          value: intValue(x.toJson(), 'id')!,
                          label: x.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: vm.batchId,
                  onChanged: vm.setBatchId,
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Serial (optional)',
                  mappedItems: vm.serialOptions
                      .where((x) => intValue(x.toJson(), 'id') != null)
                      .map(
                        (x) => AppDropdownItem<int>(
                          value: intValue(x.toJson(), 'id')!,
                          label: x.toString(),
                        ),
                      )
                      .toList(growable: false),
                  initialValue: vm.serialId,
                  onChanged: vm.setSerialId,
                ),
                AppFormTextField(
                  labelText: 'Reference Type',
                  controller: vm.referenceTypeController,
                  enabled: !vm.isLocked,
                  validator: Validators.required('Reference Type'),
                ),
                AppFormTextField(
                  labelText: 'Reference Id',
                  controller: vm.referenceIdController,
                  enabled: !vm.isLocked,
                  keyboardType: TextInputType.number,
                  validator: Validators.compose([
                    Validators.required('Reference Id'),
                    Validators.optionalMinimumInteger(1, 'Reference Id'),
                  ]),
                ),
                AppFormTextField(
                  labelText: 'Reference Line Id',
                  controller: vm.referenceLineIdController,
                  enabled: !vm.isLocked,
                  keyboardType: TextInputType.number,
                ),
                AppFormTextField(
                  labelText: 'Reserved Qty',
                  controller: vm.reservedQtyController,
                  enabled: !vm.isLocked,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: Validators.requiredPositiveNumber('Reserved Qty'),
                ),
                AppFormTextField(
                  labelText: 'Remarks',
                  controller: vm.remarksController,
                  enabled: !vm.isLocked,
                  maxLines: 2,
                ),
                AppFormTextField(
                  labelText: 'Release Qty',
                  controller: vm.releaseQtyController,
                  enabled: vm.selected != null && !vm.isLocked,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                AppFormTextField(
                  labelText: 'Release Remarks',
                  controller: vm.releaseRemarksController,
                  enabled: vm.selected != null && !vm.isLocked,
                  maxLines: 2,
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
                  onPressed: () async {
                    if (!Form.of(formContext).validate()) return;
                    await onSave();
                  },
                ),
                if (vm.selected != null && !vm.isLocked)
                  AppActionButton(
                    icon: Icons.unarchive_outlined,
                    label: 'Release Qty',
                    filled: false,
                    onPressed: onRelease,
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
