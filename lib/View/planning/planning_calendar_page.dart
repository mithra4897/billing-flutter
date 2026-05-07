import '../../screen.dart';
import '../../view_model/planning/planning_calendar_view_model.dart';

class PlanningCalendarPage extends StatefulWidget {
  const PlanningCalendarPage({
    super.key,
    this.embedded = false,
    this.editorOnly = false,
    this.initialId,
  });

  final bool embedded;
  final bool editorOnly;
  final int? initialId;

  @override
  State<PlanningCalendarPage> createState() => _PlanningCalendarPageState();
}

class _PlanningCalendarPageState extends State<PlanningCalendarPage> {
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  late final PlanningCalendarViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PlanningCalendarViewModel()..load(selectId: widget.initialId);
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
                _openRoute('/planning/calendars/new');
              }
              if (!Responsive.isDesktop(context)) _workspaceController.openEditor();
            },
            icon: Icons.add_outlined,
            label: 'New Calendar',
          ),
        ];
        final content = _buildContent();
        if (widget.embedded) return ShellPageActions(actions: actions, child: content);
        return AppStandaloneShell(
          title: 'Planning Calendars',
          scrollController: _pageScrollController,
          actions: actions,
          child: content,
        );
      },
    );
  }

  Widget _buildContent() {
    if (_viewModel.loading) return const AppLoadingView(message: 'Loading calendars...');
    if (_viewModel.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load calendars',
        message: _viewModel.pageError!,
        onRetry: _viewModel.load,
      );
    }
    return SettingsWorkspace(
      controller: _workspaceController,
      title: 'Planning Calendars',
      editorTitle: _viewModel.selected == null
          ? 'New Planning Calendar'
          : stringValue(_viewModel.selected!.toJson(), 'calendar_name', 'Calendar'),
      editorOnly: widget.editorOnly,
      scrollController: _pageScrollController,
      list: SettingsListCard<PlanningCalendarModel>(
        searchController: _viewModel.searchController,
        searchHint: 'Search calendars',
        items: _viewModel.filteredRows,
        selectedItem: _viewModel.selected,
        emptyMessage: 'No calendars found.',
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: stringValue(data, 'calendar_name', 'Calendar'),
            subtitle: stringValue(data, 'calendar_code'),
            selected: selected,
            onTap: () async {
              final id = intValue(data, 'id');
              final isDesktop = Responsive.isDesktop(context);
              await _viewModel.select(item);
              if (!mounted || id == null) return;
              if (widget.editorOnly || !isDesktop) {
                _openRoute('/planning/calendars/$id');
              }
              if (!isDesktop) _workspaceController.openEditor();
            },
          );
        },
      ),
      editor: _viewModel.detailLoading
          ? const AppLoadingView(message: 'Loading calendar...')
          : _CalendarEditor(
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
                  _openRoute('/planning/calendars');
                }
              },
            ),
    );
  }
}

class _CalendarEditor extends StatelessWidget {
  const _CalendarEditor({required this.vm, required this.onSave, required this.onDelete});
  final PlanningCalendarViewModel vm;
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
                AppFormTextField(
                  labelText: 'Calendar Code',
                  controller: vm.codeController,
                  validator: Validators.required('Calendar Code'),
                ),
                AppFormTextField(
                  labelText: 'Calendar Name',
                  controller: vm.nameController,
                  validator: Validators.required('Calendar Name'),
                ),
                AppFormTextField(labelText: 'Planning Frequency', controller: vm.frequencyController),
                AppFormTextField(labelText: 'Week Start Day', controller: vm.weekStartDayController),
                AppSwitchTile(
                  label: 'Default Calendar',
                  value: vm.isDefault,
                  onChanged: vm.setIsDefault,
                ),
                AppSwitchTile(
                  label: 'Active',
                  value: vm.isActive,
                  onChanged: vm.setIsActive,
                ),
                AppFormTextField(labelText: 'Remarks', controller: vm.remarksController, maxLines: 2),
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
                  AppActionButton(icon: Icons.delete_outline, label: 'Delete', filled: false, onPressed: onDelete),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
