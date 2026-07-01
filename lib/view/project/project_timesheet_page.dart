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
          AdaptiveShellActionButton(
            onPressed: () => controller.startNewTimesheet(
              isDesktop: Responsive.isDesktop(context),
            ),
            icon: Icons.schedule_outlined,
            label: 'New Timesheet',
          ),
        ];

        final content = _buildContent(context, controller);
        if (widget.embedded && widget.useShellActions) {
          return ShellPageActions(actions: actions, child: content);
        }
        if (widget.embedded) {
          return content;
        }
        return AppStandaloneShell(
          title: 'Project Timesheets',
          actions: actions,
          scrollController: controller.pageScrollController,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProjectTimesheetManagementController controller,
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

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Project Timesheets',
      editorTitle: controller.selectedRow == null
          ? null
          : controller.employeeName(
              controller.selectedRow!.timesheet.employeeId,
            ),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<ProjectTimesheetRow>(
        searchController: controller.searchController,
        searchHint: 'Search timesheets',
        items: controller.filteredRows,
        selectedItem: controller.selectedRow,
        emptyMessage: 'No timesheets found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: controller.employeeName(row.timesheet.employeeId).isNotEmpty
              ? controller.employeeName(row.timesheet.employeeId)
              : 'Timesheet',
          subtitle: [
            row.project.projectName ?? '',
            row.timesheet.workDate ?? '',
            row.timesheet.timesheetStatus ?? '',
          ].where((item) => item.isNotEmpty).join(' • '),
          selected: selected,
          onTap: () => controller.selectRow(row),
        ),
      ),
      editorBuilder: (_) => _buildEditorForm(context, controller),
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
