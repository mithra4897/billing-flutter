import '../../controller/project/project_task_management_controller.dart';
import '../../screen.dart';
import 'widgets/project_subtab_expandable_section.dart';
import 'widgets/project_kanban_board.dart';

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
    this.constrainedTableView = false,
  });

  final bool embedded;
  final int? constrainedProjectId;
  final int? initialProjectId;
  final int? initialTaskId;
  final String initialDashboardFilter;
  final Map<String, Object?> controllerScope;
  final bool useShellActions;
  final bool constrainedTableView;

  @override
  State<ProjectTaskManagementPage> createState() =>
      _ProjectTaskManagementPageState();
}

String _taskDateRange(String? start, String? end) {
  final values = <String>[
    normalizeDateValue(start),
    normalizeDateValue(end),
  ].where((value) => value.isNotEmpty).toList(growable: false);
  return values.join(' → ');
}

String _taskStatusLabel(String? status) {
  final value = (status ?? '').trim().toLowerCase();
  if (value == 'working') {
    return 'In Progress';
  }
  if (value == 'in_review') {
    return 'In Review';
  }
  if (value.isEmpty) {
    return '';
  }
  return value
      .split('_')
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

class _ProjectTaskManagementPageState extends State<ProjectTaskManagementPage> {
  static const List<AppDropdownItem<String>> _taskPriorityItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'low', label: 'Low'),
        AppDropdownItem(value: 'medium', label: 'Medium'),
        AppDropdownItem(value: 'high', label: 'High'),
        AppDropdownItem(value: 'critical', label: 'Critical'),
      ];

  static const List<AppDropdownItem<String>> _taskListStatusFilterItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'open', label: 'Open'),
        AppDropdownItem(value: 'working', label: 'Working'),
        AppDropdownItem(value: 'in_review', label: 'In Review'),
        AppDropdownItem(value: 'completed', label: 'Completed'),
        AppDropdownItem(value: 'on_hold', label: 'On Hold'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  static const List<AppDropdownItem<String>> _taskStatusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'open', label: 'Open'),
        AppDropdownItem(value: 'working', label: 'In Progress'),
        AppDropdownItem(value: 'in_review', label: 'In Review'),
        AppDropdownItem(value: 'completed', label: 'Completed'),
        AppDropdownItem(value: 'on_hold', label: 'On Hold'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  static const List<AppDropdownItem<String>> _normalUserTaskStatusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'open', label: 'Open'),
        AppDropdownItem(value: 'working', label: 'In Progress'),
        AppDropdownItem(value: 'in_review', label: 'In Review'),
      ];

  late final String _controllerTag;
  bool _filtersVisible = false;

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
          if (!controller.isProjectConstrained)
            AdaptiveShellSearchField(
              controller: controller.searchController,
              hintText: 'Search tasks',
            ),
          if (!controller.isProjectConstrained)
            AdaptiveShellActionButton(
              onPressed: () =>
                  setState(() => _filtersVisible = !_filtersVisible),
              icon: Icons.filter_list_outlined,
              label: 'Filter',
            ),
          if (controller.canManageTasks)
            AdaptiveShellActionButton(
              onPressed: () {
                if (controller.isProjectConstrained) {
                  controller.startNewTask(
                    isDesktop: Responsive.isDesktop(context),
                  );
                  return;
                }
                _openTaskEditor(context, controller);
              },
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
      if (widget.constrainedTableView) {
        return _buildConstrainedTable(context, controller);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTaskFilters(controller),
          const SizedBox(height: AppUiConstants.spacingMd),
          _buildConstrainedContent(context, controller),
        ],
      );
    }

    return SingleChildScrollView(
      controller: controller.pageScrollController,
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_filtersVisible) ...[
            _buildTaskFilters(controller),
            const SizedBox(height: AppUiConstants.spacingMd),
          ],
          ProjectKanbanBoard.task(
            rows: controller.filteredRows,
            statusFilter: controller.listStatusFilter,
            employeeNames: controller.employeeNames,
            onOpen: (row) => _openTaskEditor(context, controller, row: row),
            onAdd: (status) =>
                _openTaskEditor(context, controller, initialStatus: status),
            onDelete: (row) => _deleteTask(context, controller, row),
            onMove: (row, status) =>
                _moveTask(context, controller, row, status),
            canDelete: controller.canDeleteTasks && controller.canManageTasks,
            isSuperAdmin: controller.canManageTasks,
            isBusy: controller.saving,
            movingTaskIds: controller.movingTaskIds,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskFilters(ProjectTaskManagementController controller) {
    return AppRegisterFiltersSection(
      keyPrefix: 'project-tasks',
      filters: AppRegisterFilters(
        searchController: controller.isProjectConstrained
            ? controller.searchController
            : null,
        searchLabel: 'Search tasks',
        searchHint: 'Name, code, project, or employee',
        dateFromController: controller.dateFromController,
        dateToController: controller.dateToController,
        partyLabel: controller.isProjectConstrained ? null : 'Project',
        partyItems: controller.isProjectConstrained
            ? null
            : controller.projectItems,
        selectedPartyIds: controller.filterProjectIds,
        onPartyChanged: controller.setFilterProjectIds,
        secondaryPartyLabel: controller.isSuperAdmin ? 'Employee' : null,
        secondaryPartyItems: controller.isSuperAdmin
            ? controller.assignedEmployeeFilterItems
            : null,
        selectedSecondaryPartyIds: controller.filterEmployeeIds,
        onSecondaryPartyChanged: controller.setFilterEmployeeIds,
        statusItems: _taskListStatusFilterItems,
        selectedStatuses: controller.selectedStatuses,
        onStatusesChanged: controller.setSelectedStatuses,
        categoryLabel: 'Priority',
        categoryItems: _taskPriorityItems,
        selectedCategories: controller.selectedPriorities,
        onCategoriesChanged: controller.setSelectedPriorities,
        onClear: controller.clearFilters,
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
      onAdd: controller.saving || !controller.canManageTasks
          ? null
          : () => controller.startNewTask(
              isDesktop: Responsive.isDesktop(context),
            ),
      addEnabled: !controller.saving && controller.canManageTasks,
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppStatusBadge(
                      label: taskPriorityLabel(row.task.priority),
                      color: taskPriorityColor(context, row.task.priority),
                    ),
                    if (controller.canDeleteTasks && controller.canManageTasks)
                      IconButton(
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
                      ),
                  ],
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

  Widget _buildConstrainedTable(
    BuildContext context,
    ProjectTaskManagementController controller,
  ) {
    final columns = <PurchaseRegisterColumn<ProjectTaskRow>>[
      PurchaseRegisterColumn(
        label: 'Task',
        flex: 3,
        valueBuilder: (row) => row.task.taskName ?? row.task.taskCode ?? '',
        detailBuilder: (row) => row.task.taskCode ?? '',
      ),
      PurchaseRegisterColumn(
        label: 'Details',
        flex: 4,
        valueBuilder: (row) => row.task.description ?? row.task.remarks ?? '',
      ),
      PurchaseRegisterColumn(
        label: 'Schedule',
        flex: 3,
        valueBuilder: (row) =>
            _taskDateRange(row.task.plannedStartDate, row.task.plannedEndDate),
      ),
      PurchaseRegisterColumn(
        label: 'People',
        flex: 3,
        valueBuilder: (row) => controller
            .employeeNames(
              row.task.assignedEmployeeIds.isEmpty &&
                      row.task.assignedEmployeeId != null
                  ? <int>[row.task.assignedEmployeeId!]
                  : row.task.assignedEmployeeIds,
            )
            .join(', '),
      ),
      PurchaseRegisterColumn<ProjectTaskRow>(
        label: 'Priority',
        flex: 2,
        valueBuilder: (row) => taskPriorityLabel(row.task.priority),
        widgetBuilder: (context, row) => AppStatusBadge(
          label: taskPriorityLabel(row.task.priority),
          color: taskPriorityColor(context, row.task.priority),
        ),
      ),
      PurchaseRegisterColumn(
        label: 'Status',
        flex: 2,
        valueBuilder: (row) => _taskStatusLabel(row.task.taskStatus),
      ),
      PurchaseRegisterColumn<ProjectTaskRow>(
        label: 'Progress',
        flex: 2,
        alignRight: true,
        valueBuilder: (row) => row.task.progressPercent == null
            ? ''
            : '${controller.decimalText(row.task.progressPercent)}%',
        widgetBuilder: (context, row) => Text(
          row.task.progressPercent == null
              ? '-'
              : '${controller.decimalText(row.task.progressPercent)}%',
          textAlign: TextAlign.right,
        ),
      ),
    ];

    return PurchaseRegisterPage<ProjectTaskRow>(
      title: 'Project Tasks',
      loading: false,
      errorMessage: null,
      onRetry: controller.loadData,
      embedded: true,
      fullPageStyle: true,
      contentSized: widget.constrainedTableView,
      emphasizeRows: false,
      emptyMessage: 'No tasks found.',
      actions: const <Widget>[],
      rows: controller.filteredRows,
      columns: columns,
      onRowTap: (row) => _openTaskEditor(context, controller, row: row),
    );
  }

  Widget _buildEditorForm(
    BuildContext context,
    ProjectTaskManagementController controller, {
    VoidCallback? onSaved,
  }) {
    final canManage = controller.canManageTasks;
    final canChangeStatus = controller.canEditTaskStatus(
      controller.selectedRow,
    );
    final statusItems = canManage || !canChangeStatus
        ? _taskStatusItems
        : _normalUserTaskStatusItems;
    return Form(
      child: Builder(
        builder: (formContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsFormWrap(
              maxWidth: double.infinity,
              children: [
                if (!controller.isProjectConstrained)
                  AppDropdownField<int>.fromMapped(
                    initialValue: controller.projectId,
                    labelText: 'Project',
                    mappedItems: controller.projectItems,
                    onChanged: canManage ? controller.setProjectId : null,
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
                  readOnly: !canManage,
                ),
                AppFormTextField(
                  controller: controller.taskNameController,
                  labelText: 'Task Name',
                  validator: Validators.compose([
                    Validators.required('Task Name'),
                    Validators.optionalMaxLength(255, 'Task Name'),
                  ]),
                  readOnly: !canManage,
                ),
                AppDropdownField<int>.fromMapped(
                  labelText: 'Assigned Employees',
                  mappedItems: controller.employeeItems,
                  multiInitialValues: controller.assignedEmployeeIds,
                  multiHintText: 'Select employees',
                  onMultiChanged: canManage
                      ? controller.setAssignedEmployeeIds
                      : null,
                ),
                AppDropdownField<String>.fromMapped(
                  initialValue: controller.taskPriority,
                  labelText: 'Priority',
                  mappedItems: _taskPriorityItems,
                  onChanged: canManage
                      ? (value) => controller.setTaskPriority(
                          value ?? controller.taskPriority,
                        )
                      : null,
                ),
                AppDropdownField<String>.fromMapped(
                  initialValue: controller.taskStatus,
                  labelText: 'Status',
                  mappedItems: statusItems,
                  onChanged: canChangeStatus
                      ? (value) => controller.setTaskStatus(
                          value ?? controller.taskStatus,
                        )
                      : null,
                ),
                AppFormTextField(
                  controller: controller.plannedStartDateController,
                  labelText: 'Planned Start Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('Planned Start Date'),
                  readOnly: !canManage,
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
                  readOnly: !canManage,
                ),
                AppFormTextField(
                  controller: controller.actualStartDateController,
                  labelText: 'Actual Start Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('Actual Start Date'),
                  readOnly: !canManage,
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
                  readOnly: !canManage,
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
                  readOnly: !canManage,
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
                  readOnly: !canManage,
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
                  readOnly: !canManage,
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
                  readOnly: !canManage,
                ),
                AppFormTextField(
                  controller: controller.progressPercentController,
                  labelText: 'Progress Percent (Based on Status)',
                  readOnly: true,
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppFormTextField(
              controller: controller.descriptionController,
              labelText: 'Description',
              maxLines: 3,
              readOnly: !canManage,
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSwitchTile(
              label: 'Billable',
              subtitle: 'Use this task for billable work if needed.',
              value: controller.isBillable,
              onChanged: canManage ? controller.setIsBillable : null,
            ),
            const SizedBox(height: AppUiConstants.spacingXs),
            AppFormTextField(
              controller: controller.remarksController,
              labelText: 'Remarks',
              maxLines: 3,
              validator: Validators.optionalMaxLength(500, 'Remarks'),
              readOnly: !canManage,
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
                  onPressed: controller.saving || !canChangeStatus
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
                          onSaved?.call();
                        },
                  icon: controller.selectedRow?.task.id == null
                      ? Icons.add
                      : Icons.save_outlined,
                  label: controller.saving
                      ? 'Saving...'
                      : canManage
                      ? 'Save Task'
                      : 'Update Status',
                  busy: controller.saving,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTaskEditor(
    BuildContext context,
    ProjectTaskManagementController controller, {
    ProjectTaskRow? row,
    String? initialStatus,
  }) async {
    if (row == null) {
      controller.startNewTask(isDesktop: true);
      if (initialStatus != null) {
        controller.setTaskStatus(initialStatus);
      }
    } else {
      controller.selectRow(row, toggleIfSelected: false);
    }

    await showAppFilterPanel<void>(
      context: context,
      title: row?.task.taskName ?? 'New Project Task',
      maxWidth: 960,
      builder: (dialogContext) => GetBuilder<ProjectTaskManagementController>(
        tag: _controllerTag,
        builder: (dialogController) => _buildEditorForm(
          dialogContext,
          dialogController,
          onSaved: () => Navigator.of(dialogContext).pop(),
        ),
      ),
    );
  }

  Future<void> _deleteTask(
    BuildContext context,
    ProjectTaskManagementController controller,
    ProjectTaskRow row,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Remove ${row.task.taskName ?? 'this task'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    controller.selectRow(row, toggleIfSelected: false);
    final message = await controller.deleteTask();
    if (!mounted || message == null) {
      return;
    }
    appScaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _moveTask(
    BuildContext context,
    ProjectTaskManagementController controller,
    ProjectTaskRow row,
    String status,
  ) async {
    final errorColor = Theme.of(context).colorScheme.error;
    try {
      final message = await controller.moveTaskToStatus(row, status);
      if (!mounted || message == null) {
        return;
      }
      appScaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } catch (errorValue) {
      if (!mounted) {
        return;
      }
      appScaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Unable to move task: $errorValue'),
            backgroundColor: errorColor,
          ),
        );
    }
  }
}
