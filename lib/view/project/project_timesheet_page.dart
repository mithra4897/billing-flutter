import '../../controller/project/project_timesheet_management_controller.dart';
import '../../screen.dart';

class ProjectTimesheetManagementPage extends StatefulWidget {
  const ProjectTimesheetManagementPage({super.key, this.embedded = false});

  final bool embedded;

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
    );
    Get.put(ProjectTimesheetManagementController(), tag: _controllerTag);
  }

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
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
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

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Project Timesheets',
      editorTitle: controller.selectedRow == null
          ? null
          : controller.employeeName(controller.selectedRow!.timesheet.employeeId),
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
      editorBuilder: (_) => Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsFormWrap(
              children: [
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
                  validator: Validators.optionalNonNegativeNumber('Hourly Cost'),
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
                  validator: Validators.optionalNonNegativeNumber('Cost Amount'),
                ),
                AppFormTextField(
                  controller: controller.billableAmountController,
                  labelText: 'Billable Amount',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
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
            const SizedBox(height: 8),
            AppFormTextField(
              controller: controller.notesController,
              labelText: 'Notes',
              maxLines: 3,
            ),
            if ((controller.formError ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                controller.formError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppActionButton(
                  onPressed: controller.saving
                      ? null
                      : () async {
                          final message = await controller.saveTimesheet();
                          if (!mounted || message == null) return;
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
                AppActionButton(
                  onPressed: controller.saving
                      ? null
                      : () => controller.startNewTimesheet(
                          isDesktop: Responsive.isDesktop(context),
                        ),
                  icon: Icons.refresh,
                  label: 'New',
                  filled: false,
                ),
                if (controller.selectedRow?.timesheet.id != null)
                  AppActionButton(
                    onPressed: controller.saving
                        ? null
                        : () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Timesheet'),
                                content: const Text(
                                  'Remove this timesheet entry?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton.tonal(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true) return;
                            final message = await controller.deleteTimesheet();
                            if (!mounted || message == null) return;
                            appScaffoldMessengerKey.currentState
                              ?..hideCurrentSnackBar()
                              ..showSnackBar(SnackBar(content: Text(message)));
                          },
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    filled: false,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
