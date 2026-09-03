import '../../components/app_progress_bar.dart';
import '../../controller/project/project_timesheet_management_controller.dart';
import '../../screen.dart';
import 'widgets/project_subtab_expandable_section.dart';

class ProjectTimesheetManagementPage extends StatefulWidget {
  const ProjectTimesheetManagementPage({
    super.key,
    this.embedded = false,
    this.constrainedProjectId,
    this.controllerScope = const <String, Object?>{},
    this.useShellActions = true,
  });

  final bool embedded;
  final int? constrainedProjectId;
  final Map<String, Object?> controllerScope;
  final bool useShellActions;

  @override
  State<ProjectTimesheetManagementPage> createState() =>
      _ProjectTimesheetManagementPageState();
}

class _ProjectTimesheetManagementPageState
    extends State<ProjectTimesheetManagementPage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'approved', label: 'Approved'),
        AppDropdownItem(value: 'rejected', label: 'Rejected'),
      ];

  bool _filtersVisible = false;

  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'ProjectTimesheetManagementController',
      scope: widget.controllerScope,
    );
    if (!Get.isRegistered<ProjectTimesheetManagementController>(
      tag: _controllerTag,
    )) {
      Get.put(
        ProjectTimesheetManagementController(
          constrainedProjectId: widget.constrainedProjectId,
        ),
        tag: _controllerTag,
      );
    }
  }

  @override
  void didUpdateWidget(covariant ProjectTimesheetManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.constrainedProjectId != widget.constrainedProjectId) {
      unawaited(
        _controller.applyProjectConstraint(widget.constrainedProjectId),
      );
    }
  }

  ProjectTimesheetManagementController get _controller =>
      Get.find<ProjectTimesheetManagementController>(tag: _controllerTag);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProjectTimesheetManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellSearchField(
            controller: controller.searchController,
            hintText: 'Search timesheets',
          ),
          AdaptiveShellActionButton(
            onPressed: () => setState(() => _filtersVisible = !_filtersVisible),
            icon: Icons.filter_list_outlined,
            label: 'Filter',
          ),
          AdaptiveShellActionButton(
            onPressed: () {
              controller.resetForm();
              _openEditor(context, controller);
            },
            icon: Icons.more_time_outlined,
            label: 'New Timesheet',
          ),
        ];

        return _buildContent(context, controller, widget.useShellActions ? actions : const <Widget>[]);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProjectTimesheetManagementController controller,
    List<Widget> actions,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading project timesheets...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load project timesheets',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }

    if (controller.isProjectConstrained) {
      return _buildConstrainedContent(context, controller);
    }

    final columns = <PurchaseRegisterColumn<ProjectTimesheetRow>>[
      PurchaseRegisterColumn(
        label: 'Project',
        flex: 3,
        valueBuilder: (row) => row.project.projectName ?? '',
      ),
      PurchaseRegisterColumn(
        label: 'Employee',
        flex: 3,
        valueBuilder: (row) =>
            controller.employeeName(row.timesheet.employeeId),
      ),
      PurchaseRegisterColumn(
        label: 'Work Date',
        flex: 2,
        valueBuilder: (row) => row.timesheet.workDate ?? '',
      ),
      PurchaseRegisterColumn(
        label: 'Hours',
        flex: 2,
        alignRight: true,
        valueBuilder: (row) =>
            controller.decimalText(row.timesheet.hoursWorked),
      ),
      PurchaseRegisterColumn(
        label: 'Billable',
        flex: 2,
        alignRight: true,
        valueBuilder: (row) =>
            controller.decimalText(row.timesheet.billableAmount),
      ),
      PurchaseRegisterColumn<ProjectTimesheetRow>(
        label: 'Status',
        flex: 2,
        valueBuilder: (row) => row.timesheet.timesheetStatus ?? '',
        widgetBuilder: (context, row) {
          final status = row.timesheet.timesheetStatus ?? '';
          final trimmed = status.trim().toLowerCase();
          final error = trimmed == 'rejected';
          final progress = trimmed == 'approved'
              ? 1.0
              : trimmed == 'rejected'
              ? 0.0
              : 0.2;
          final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
          final color = error
              ? Theme.of(context).colorScheme.error
              : progress >= 1.0
              ? appTheme.success
              : progress > 0
              ? appTheme.info
              : appTheme.warning;

          return AppProgressBar(
            label: status.isEmpty ? '-' : status[0].toUpperCase() + status.substring(1).replaceAll('_', ' '),
            progress: error ? 0.0 : progress,
            color: color,
          );
        },
      ),
    ];

    return PurchaseRegisterPage<ProjectTimesheetRow>(
      title: 'Project Timesheets',
      loading: false,
      errorMessage: null,
      onRetry: controller.loadData,
      embedded: widget.embedded,
      fullPageStyle: true,
      emphasizeRows: false,
      emptyMessage: 'No timesheets found.',
      actions: actions,
      rows: controller.filteredRows,
      columns: columns,
      onRowTap: (row) {
        controller.selectRow(row);
        _openEditor(context, controller);
      },
      filters: _filtersVisible
          ? _buildFilterPanel(controller)
          : null,
    );
  }

  Widget _buildFilterPanel(ProjectTimesheetManagementController controller) {
    return AppRegisterFilters(
      dateFromController: controller.dateFromController,
      dateToController: controller.dateToController,
      statusItems: _statusItems,
      selectedStatuses: controller.selectedStatuses,
      onStatusesChanged: controller.setStatuses,
      onClear: controller.clearFilters,
    );
  }

  void _openEditor(
    BuildContext context,
    ProjectTimesheetManagementController controller,
  ) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => GetBuilder<ProjectTimesheetManagementController>(
          tag: _controllerTag,
          builder: (ctrl) => AppStandaloneShell(
            title: ctrl.selectedRow == null ? 'New Project Timesheet' : 'Edit Project Timesheet',
            scrollController: ScrollController(),
            actions: const <Widget>[],
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppUiConstants.pagePadding),
              child: AppSectionCard(
                child: _buildEditorForm(context, ctrl),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConstrainedContent(
    BuildContext context,
    ProjectTimesheetManagementController controller,
  ) {
    return ProjectSubtabExpandableSection(
      title: 'Project Timesheets',
      description:
          'Manage employee time entries, rates, approvals, and billable values for the selected project.',
      addLabel: 'Add Timesheet',
      addIcon: Icons.schedule_outlined,
      onAdd: controller.saving
          ? null
          : () => controller.startNewTimesheet(
              isDesktop: Responsive.isDesktop(context),
            ),
      addEnabled: !controller.saving,
      emptyMessage: 'No timesheets found.',
      showDraftTile: controller.showDraftTile && controller.selectedRow == null,
      draftTitle: 'New Timesheet',
      draftSubtitle: 'Add a timesheet entry for this project.',
      onDraftToggle: controller.hideDraftTile,
      draftChild: _buildEditorForm(context, controller),

      recordTiles: controller.filteredRows
          .map((row) {
            final expanded =
                controller.selectedRow?.timesheet.id == row.timesheet.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
              child: SettingsExpandableTile(
                key: ValueKey<String>(
                  'project-timesheet-${row.timesheet.id}-$expanded',
                ),
                title:
                    controller.employeeName(row.timesheet.employeeId).isNotEmpty
                    ? controller.employeeName(row.timesheet.employeeId)
                    : 'Timesheet',
                subtitle: [
                  row.timesheet.workDate ?? '',
                  row.timesheet.timesheetStatus ?? '',
                ].where((item) => item.isNotEmpty).join(' | '),
                detail: [
                  controller.decimalText(row.timesheet.hoursWorked),
                  controller.decimalText(row.timesheet.billableAmount),
                ].where((item) => item.isNotEmpty).join(' | '),
                expanded: expanded,
                highlighted: expanded,
                leadingIcon: Icons.schedule_outlined,
                trailing: IconButton(
                  tooltip: 'Delete timesheet',
                  onPressed: controller.saving
                      ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Delete Timesheet'),
                              content: const Text(
                                'Remove this timesheet entry?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton.tonal(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true) {
                            return;
                          }
                          controller.selectRow(row);
                          final message = await controller.deleteTimesheet();
                          if (!mounted || message == null) {
                            return;
                          }
                          appScaffoldMessengerKey.currentState
                            ?..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(content: Text(message)));
                        },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                onToggle: () {
                  if (expanded) {
                    controller.resetForm();
                  } else {
                    controller.selectRow(row);
                  }
                },
                child: expanded
                    ? _buildEditorForm(context, controller)
                    : const SizedBox.shrink(),
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _buildEditorForm(
    BuildContext context,
    ProjectTimesheetManagementController controller,
  ) {
    return Form(
      child: Builder(
        builder: (formContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsFormWrap(
              children: [
                if (!controller.isProjectConstrained)
                  AppDropdownField<int>.fromMapped(
                    initialValue: controller.projectId,
                    labelText: 'Project',
                    mappedItems: controller.projectItems,
                    onChanged: controller.setProjectId,
                    validator: Validators.requiredSelection('Project'),
                  ),
                AppDropdownField<int>.fromMapped(
                  initialValue: controller.taskId,
                  labelText: 'Task',
                  mappedItems: controller.taskItems,
                  onChanged: controller.setTaskId,
                ),
                AppDropdownField<int>.fromMapped(
                  initialValue: controller.employeeId,
                  labelText: 'Employee',
                  mappedItems: controller.employeeItems,
                  onChanged: controller.setEmployeeId,
                  validator: Validators.requiredSelection('Employee'),
                ),
                AppFormTextField(
                  controller: controller.workDateController,
                  labelText: 'Work Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('Work Date'),
                    Validators.optionalDate('Work Date'),
                  ]),
                ),
                AppFormTextField(
                  controller: controller.hoursWorkedController,
                  labelText: 'Hours Worked',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.compose([
                    Validators.required('Hours Worked'),
                    Validators.optionalNonNegativeNumber('Hours Worked'),
                  ]),
                ),
                AppFormTextField(
                  controller: controller.hourlyCostController,
                  labelText: 'Hourly Cost',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Hourly Cost',
                  ),
                ),
                AppFormTextField(
                  controller: controller.billableRateController,
                  labelText: 'Billable Rate',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Billable Rate',
                  ),
                ),
                AppFormTextField(
                  controller: controller.costAmountController,
                  labelText: 'Cost Amount',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  readOnly: true,
                  validator: Validators.optionalNonNegativeNumber(
                    'Cost Amount',
                  ),
                ),
                AppFormTextField(
                  controller: controller.billableAmountController,
                  labelText: 'Billable Amount',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  readOnly: true,
                  validator: Validators.optionalNonNegativeNumber(
                    'Billable Amount',
                  ),
                ),
                AppFormTextField(
                  controller: controller.voucherIdController,
                  labelText: 'Voucher ID',
                  keyboardType: TextInputType.number,
                ),
                AppDropdownField<String>.fromMapped(
                  initialValue: controller.status,
                  labelText: 'Status',
                  mappedItems: _statusItems,
                  onChanged: (value) =>
                      controller.setStatus(value ?? controller.status),
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingXs),
            AppFormTextField(
              controller: controller.notesController,
              labelText: 'Notes',
              maxLines: 3,
            ),
            if ((controller.formError ?? '').isNotEmpty) ...[
              const SizedBox(height: AppUiConstants.spacingSm),
              AppErrorStateView.inline(message: controller.formError!),
            ],
            const SizedBox(height: AppUiConstants.spacingMd),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: [
                AppActionButton(
                  onPressed: controller.saving
                      ? null
                      : () async {
                          if (!Form.of(formContext).validate()) {
                            return;
                          }
                          final message = await controller.saveTimesheet();
                          if (!mounted || message == null) {
                            return;
                          }
                          appScaffoldMessengerKey.currentState
                            ?..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(content: Text(message)));
                        },
                  icon: controller.selectedRow?.timesheet.id == null
                      ? Icons.add
                      : Icons.save_outlined,
                  label: controller.saving ? 'Saving...' : 'Save Timesheet',
                  busy: controller.saving,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
