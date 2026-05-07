import '../../screen.dart';
import '../../view_model/planning/mrp_run_view_model.dart';

class MrpRunPage extends StatefulWidget {
  const MrpRunPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<MrpRunPage> createState() => _MrpRunPageState();
}

class _MrpRunPageState extends State<MrpRunPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final MrpRunViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MrpRunViewModel()..load(selectId: widget.initialId);
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
                _openRoute('/planning/mrp-runs/new');
              }
              if (!isDesktop) _workspaceController.openEditor();
            },
            icon: Icons.add_outlined,
            label: 'New MRP Run',
          ),
        ];
        final content = _buildContent();
        if (widget.embedded) return ShellPageActions(actions: actions, child: content);
        return AppStandaloneShell(
          title: 'MRP Runs',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent() {
    if (_viewModel.loading) return const AppLoadingView(message: 'Loading MRP runs...');
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load MRP runs',
        message: _viewModel.pageError!,
        onRetry: _viewModel.load,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'MRP Runs',
      editorTitle: _viewModel.selected == null
          ? 'New MRP Run'
          : stringValue(_viewModel.selected!.toJson(), 'run_no', 'MRP Run'),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<MrpRunModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search MRP runs',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No MRP runs found.',
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'run_no', 'MRP Run'),
            subtitle: [
              nullableStringValue(data, 'run_date') ?? '',
              stringValue(data, 'run_status'),
            ].where((x) => x.isNotEmpty).join(' · '),
            selected: selected,
            onTap: () async {
              final id = intValue(data, 'id');
              final isDesktop = Responsive.isDesktop(context);
              await _viewModel.select(item);
              if (!mounted || id == null) return;
              if (widget.editorOnly || !isDesktop) {
                _openRoute('/planning/mrp-runs/$id');
              }
              if (!isDesktop) _workspaceController.openEditor();
            },
          );
        },
      ),
      editor: _viewModel.detailLoading
          ? const AppLoadingView(message: 'Loading MRP run...')
          : _MrpRunEditor(
              vm: _viewModel,
              onSave: () async {
                await _viewModel.save();
                _snack();
              },
              onProcess: () async {
                await _viewModel.process();
                _snack();
              },
              onCancelRun: () async {
                await _viewModel.cancel();
                _snack();
              },
              onDelete: () async {
                final shouldNavigateBack =
                    widget.editorOnly || !Responsive.isDesktop(context);
                await _viewModel.delete();
                _snack();
                if (shouldNavigateBack) {
                  _openRoute('/planning/mrp-runs');
                }
              },
            ),
    );
  }
}

class _MrpRunEditor extends StatelessWidget {
  const _MrpRunEditor({
    required this.vm,
    required this.onSave,
    required this.onProcess,
    required this.onCancelRun,
    required this.onDelete,
  });
  final MrpRunViewModel vm;
  final Future<void> Function() onSave;
  final Future<void> Function() onProcess;
  final Future<void> Function() onCancelRun;
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
                AppFormTextField(labelText: 'Run No (optional)', controller: vm.runNoController),
                AppFormTextField(
                  labelText: 'Run Date',
                  controller: vm.runDateController,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([Validators.required('Run Date'), Validators.date('Run Date')]),
                ),
                AppFormTextField(
                  labelText: 'Planning Start Date',
                  controller: vm.startDateController,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([Validators.required('Planning Start Date'), Validators.date('Planning Start Date')]),
                ),
                AppFormTextField(
                  labelText: 'Planning End Date',
                  controller: vm.endDateController,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([Validators.required('Planning End Date'), Validators.date('Planning End Date')]),
                ),
                AppFormTextField(labelText: 'Notes', controller: vm.notesController, maxLines: 2),
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
                if (vm.selected != null && (vm.status == 'draft' || vm.status == 'failed'))
                  AppActionButton(icon: Icons.play_arrow_outlined, label: 'Process', filled: false, onPressed: onProcess),
                if (vm.selected != null && vm.status != 'cancelled')
                  AppActionButton(icon: Icons.cancel_outlined, label: 'Cancel Run', filled: false, onPressed: onCancelRun),
                if (vm.selected != null)
                  AppActionButton(icon: Icons.delete_outline, label: 'Delete', filled: false, onPressed: onDelete),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
