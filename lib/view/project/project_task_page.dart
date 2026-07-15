import '../../controller/project/project_task_management_controller.dart';
import '../../screen.dart';
import 'widgets/project_subtab_expandable_section.dart';

class ProjectTaskManagementPage extends StatefulWidget {
  const ProjectTaskManagementPage({
    super.key,
    this.embedded = false,
    this.constrainedProjectId,
    this.initialProjectId,
    this.initialTaskId,
    this.initialDashboardFilter = '',
    this.controllerScope = const <String, Object?>{},
    this.useShellActions = true,
  });

  final bool embedded;
  final int? constrainedProjectId;
  final int? initialProjectId;
  final int? initialTaskId;
  final String initialDashboardFilter;
  final Map<String, Object?> controllerScope;
  final bool useShellActions;

  @override
  State<ProjectTaskManagementPage> createState() =>
      _ProjectTaskManagementPageState();
}

class _ProjectTaskManagementPageState extends State<ProjectTaskManagementPage> {
  static const List<AppDropdownItem<String>> _taskStatusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'open', label: 'Open'),
        AppDropdownItem(value: 'working', label: 'Working'),
        AppDropdownItem(value: 'completed', label: 'Completed'),
        AppDropdownItem(value: 'on_hold', label: 'On Hold'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  static const List<AppDropdownItem<String>> _taskListStatusFilterItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'pending', label: 'Pending'),
        AppDropdownItem(value: 'all', label: 'All Statuses'),
        AppDropdownItem(value: 'open', label: 'Open'),
        AppDropdownItem(value: 'working', label: 'Working'),
        AppDropdownItem(value: 'on_hold', label: 'On Hold'),
        AppDropdownItem(value: 'completed', label: 'Completed'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'ProjectTaskManagementController',
      scope: widget.controllerScope,
    );
    if (!Get.isRegistered<ProjectTaskManagementController>(
      tag: _controllerTag,
    )) {
      Get.put(
        ProjectTaskManagementController(
          constrainedProjectId: widget.constrainedProjectId,
          initialProjectId: widget.initialProjectId,
          initialTaskId: widget.initialTaskId,
          initialDashboardFilter: widget.initialDashboardFilter,
        ),
        tag: _controllerTag,
      );
    }
  }

  @override
  void didUpdateWidget(covariant ProjectTaskManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.constrainedProjectId != widget.constrainedProjectId) {
      unawaited(
        _controller.applyProjectConstraint(widget.constrainedProjectId),
      );
    }
  }

  ProjectTaskManagementController get _controller =>
      Get.find<ProjectTaskManagementController>(tag: _controllerTag);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProjectTaskManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => controller.startNewTask(
              isDesktop: Responsive.isDesktop(context),
            ),
            icon: Icons.add_task_outlined,
            label: 'New Task',
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
          title: 'Project Tasks',
          actions: actions,
          scrollController: controller.pageScrollController,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProjectTaskManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading project tasks...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load project tasks',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }

    if (controller.isProjectConstrained) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTaskFilters(controller),
          const SizedBox(height: AppUiConstants.spacingMd),
          _buildConstrainedContent(context, controller),
        ],
      );
    }

    final selectedRow = controller.selectedRow;
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Project Tasks',
      editorTitle: selectedRow == null
          ? null
          : (selectedRow.task.taskName ?? selectedRow.task.taskCode),
      scrollController: controller.pageScrollController,
      list: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTaskFilters(controller),
          const SizedBox(height: AppUiConstants.spacingMd),
          SettingsListCard<ProjectTaskRow>(
            searchController: controller.searchController,
            searchHint: 'Search tasks',
            items: controller.filteredRows,
            selectedItem: controller.selectedRow,
            emptyMessage: 'No tasks match the selected filters.',
            itemBuilder: (row, selected) => SettingsListTile(
              title: row.task.taskName ?? 'Task',
              subtitle: [
                row.task.taskCode ?? '',
                row.project.projectName ?? '',
                row.task.taskStatus ?? '',
              ].where((item) => item.isNotEmpty).join(' • '),
              selected: selected,
              onTap: () => controller.selectRow(row),
            ),
          ),
        ],
      ),
      editorBuilder: (_) => _buildEditorForm(context, controller),
    );
  }

  Widget _buildTaskFilters(ProjectTaskManagementController controller) {
    return AppSectionCard(
      child: SettingsFormWrap(
        children: [
          AppDropdownField<String>.fromMapped(
            labelText: 'Task status',
            mappedItems: _taskListStatusFilterItems,
            initialValue: controller.listStatusFilter,
            onChanged: controller.setListStatusFilter,
          ),
          if (controller.isSuperAdmin)
            AppDropdownField<int>.fromMapped(
              labelText: 'Assigned employees',
              mappedItems: controller.assignedEmployeeFilterItems,
              multiInitialValues: controller.filterEmployeeIds,
              multiHintText: 'All assigned employees',
              onMultiChanged: controller.setFilterEmployeeIds,
            ),
        ],
      ),
    );
  }

  Widget _buildConstrainedContent(
    BuildContext context,
    ProjectTaskManagementController controller,
  ) {
    return ProjectSubtabExpandableSection(
      title: 'Project Tasks',
      description:
          'Manage task breakdown, assignment, timeline, cost, and progress for the selected project.',
      addLabel: 'Add Task',
      addIcon: Icons.add_task_outlined,
      onAdd: controller.saving
          ? null
          : () => controller.startNewTask(
              isDesktop: Responsive.isDesktop(context),
            ),
      addEnabled: !controller.saving,
      emptyMessage: 'No tasks found.',
      showDraftTile: controller.showDraftTile && controller.selectedRow == null,
      draftTitle: 'New Task',
      draftSubtitle: 'Add a task for this project.',
      onDraftToggle: controller.hideDraftTile,
      draftChild: _buildEditorForm(context, controller),

      recordTiles: controller.filteredRows
          .map((row) {
            final expanded = controller.selectedRow?.task.id == row.task.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
              child: SettingsExpandableTile(
                key: ValueKey<String>('project-task-${row.task.id}-$expanded'),
                title: row.task.taskName ?? 'Task',
                subtitle: [
                  row.task.taskCode ?? '',
                  row.task.taskStatus ?? '',
                ].where((item) => item.isNotEmpty).join(' | '),
                detail: [
                  controller
                      .employeeNames(
                        row.task.assignedEmployeeIds.isEmpty &&
                                row.task.assignedEmployeeId != null
                            ? <int>[row.task.assignedEmployeeId!]
                            : row.task.assignedEmployeeIds,
                      )
                      .join(', '),
                  row.task.plannedEndDate ?? '',
                  row.task.progressPercent == null
                      ? ''
                      : '${controller.decimalText(row.task.progressPercent)}%',
                ].where((item) => item.isNotEmpty).join(' | '),
                expanded: expanded,
                highlighted: expanded,
                leadingIcon: Icons.task_outlined,
                trailing: controller.canDeleteTasks
                    ? IconButton(
                        tooltip: 'Delete task',
                        onPressed: controller.saving
                            ? null
                            : () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Delete Task'),
                                    content: Text(
                                      'Remove ${row.task.taskName ?? 'this task'}?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(
                                          dialogContext,
                                        ).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton.tonal(
                                        onPressed: () => Navigator.of(
                                          dialogContext,
                                        ).pop(true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed != true) {
                                  return;
                                }
                                controller.selectRow(row);
                                final message = await controller.deleteTask();
                                if (!mounted || message == null) {
                                  return;
                                }
                                appScaffoldMessengerKey.currentState
                                  ?..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(content: Text(message)),
                                  );
                              },
                        icon: const Icon(Icons.remove_circle_outline),
                      )
                    : null,
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
    ProjectTaskManagementController controller,
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
                AppFormTextField(
                  controller: controller.taskCodeController,
                  labelText: 'Task Code',
                  suffixIcon: controller.loadingTaskCode
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  validator: Validators.optionalMaxLength(100, 'Task Code'),
                ),
                AppFormTextField(
                  controller: controller.taskNameController,
                  labelText: 'Task Name',
                  validator: Validators.compose([
                    Validators.required('Task Name'),
                    Validators.optionalMaxLength(255, 'Task Name'),
                  ]),
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Assigned Employees',
                  mappedItems: controller.employeeItems,
                  multiInitialValues: controller.assignedEmployeeIds,
                  multiHintText: 'Select employees',
                  onMultiChanged: controller.setAssignedEmployeeIds,
                ),
                AppDropdownField<String>.fromMapped(
                  initialValue: controller.taskStatus,
                  labelText: 'Task Status',
                  mappedItems: _taskStatusItems,
                  onChanged: (value) =>
                      controller.setTaskStatus(value ?? controller.taskStatus),
                ),
                AppFormTextField(
                  controller: controller.plannedStartDateController,
                  labelText: 'Planned Start Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('Planned Start Date'),
                ),
                AppFormTextField(
                  controller: controller.plannedEndDateController,
                  labelText: 'Planned End Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDateOnOrAfter(
                    'Planned End Date',
                    () => controller.plannedStartDateController.text,
                    startFieldName: 'Planned Start Date',
                  ),
                ),
                AppFormTextField(
                  controller: controller.actualStartDateController,
                  labelText: 'Actual Start Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('Actual Start Date'),
                ),
                AppFormTextField(
                  controller: controller.actualEndDateController,
                  labelText: 'Actual End Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDateOnOrAfter(
                    'Actual End Date',
                    () => controller.actualStartDateController.text,
                    startFieldName: 'Actual Start Date',
                  ),
                ),
                AppFormTextField(
                  controller: controller.estimatedHoursController,
                  labelText: 'Estimated Hours',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Estimated Hours',
                  ),
                ),
                AppFormTextField(
                  controller: controller.actualHoursController,
                  labelText: 'Actual Hours',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Actual Hours',
                  ),
                ),
                AppFormTextField(
                  controller: controller.estimatedCostController,
                  labelText: 'Estimated Cost',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Estimated Cost',
                  ),
                ),
                AppFormTextField(
                  controller: controller.actualCostController,
                  labelText: 'Actual Cost',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Actual Cost',
                  ),
                ),
                AppFormTextField(
                  controller: controller.progressPercentController,
                  labelText: 'Progress Percent',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Progress Percent',
                  ),
                ),
                AppFormTextField(
                  controller: controller.descriptionController,
                  labelText: 'Description',
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSwitchTile(
              label: 'Billable',
              subtitle: 'Use this task for billable work if needed.',
              value: controller.isBillable,
              onChanged: controller.setIsBillable,
            ),
            const SizedBox(height: AppUiConstants.spacingXs),
            AppFormTextField(
              controller: controller.remarksController,
              labelText: 'Remarks',
              maxLines: 3,
              validator: Validators.optionalMaxLength(500, 'Remarks'),
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
                          final message = await controller.saveTask();
                          if (!mounted || message == null) {
                            return;
                          }
                          appScaffoldMessengerKey.currentState
                            ?..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(content: Text(message)));
                        },
                  icon: controller.selectedRow?.task.id == null
                      ? Icons.add
                      : Icons.save_outlined,
                  label: controller.saving ? 'Saving...' : 'Save Task',
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
