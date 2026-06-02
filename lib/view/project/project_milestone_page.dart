import '../../controller/project/project_milestone_management_controller.dart';
import '../../screen.dart';

class ProjectMilestoneManagementPage extends StatefulWidget {
  const ProjectMilestoneManagementPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProjectMilestoneManagementPage> createState() =>
      _ProjectMilestoneManagementPageState();
}

class _ProjectMilestoneManagementPageState
    extends State<ProjectMilestoneManagementPage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'open', label: 'Open'),
        AppDropdownItem(value: 'completed', label: 'Completed'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'ProjectMilestoneManagementController',
    );
    Get.put(ProjectMilestoneManagementController(), tag: _controllerTag);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProjectMilestoneManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => controller.startNewMilestone(
              isDesktop: Responsive.isDesktop(context),
            ),
            icon: Icons.flag_outlined,
            label: 'New Milestone',
          ),
        ];

        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Project Milestones',
          actions: actions,
          scrollController: controller.pageScrollController,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProjectMilestoneManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading project milestones...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load project milestones',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }

    final selectedRow = controller.selectedRow;
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Project Milestones',
      editorTitle: selectedRow?.milestone.milestoneName,
      scrollController: controller.pageScrollController,
      list: SettingsListCard<ProjectMilestoneRow>(
        searchController: controller.searchController,
        searchHint: 'Search milestones',
        items: controller.filteredRows,
        selectedItem: controller.selectedRow,
        emptyMessage: 'No milestones found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: row.milestone.milestoneName ?? 'Milestone',
          subtitle: [
            row.project.projectName ?? '',
            row.milestone.targetDate ?? '',
            row.milestone.milestoneStatus ?? '',
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
                AppFormTextField(
                  controller: controller.nameController,
                  labelText: 'Milestone Name',
                  validator: Validators.compose([
                    Validators.required('Milestone Name'),
                    Validators.optionalMaxLength(255, 'Milestone Name'),
                  ]),
                ),
                AppDropdownField<String>.fromMapped(
                  initialValue: controller.status,
                  labelText: 'Status',
                  mappedItems: _statusItems,
                  onChanged: (value) =>
                      controller.setStatus(value ?? controller.status),
                ),
                AppFormTextField(
                  controller: controller.targetDateController,
                  labelText: 'Target Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('Target Date'),
                ),
                AppFormTextField(
                  controller: controller.completionDateController,
                  labelText: 'Completion Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDateOnOrAfter(
                    'Completion Date',
                    () => controller.targetDateController.text,
                    startFieldName: 'Target Date',
                  ),
                ),
                AppFormTextField(
                  controller: controller.amountController,
                  labelText: 'Milestone Amount',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Milestone Amount',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppFormTextField(
              controller: controller.remarksController,
              labelText: 'Remarks',
              maxLines: 3,
              validator: Validators.optionalMaxLength(500, 'Remarks'),
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
                          final message = await controller.saveMilestone();
                          if (!mounted || message == null) {
                            return;
                          }
                          appScaffoldMessengerKey.currentState
                            ?..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(content: Text(message)));
                        },
                  icon: controller.selectedRow?.milestone.id == null
                      ? Icons.add
                      : Icons.save_outlined,
                  label: controller.saving ? 'Saving...' : 'Save Milestone',
                  busy: controller.saving,
                ),
                AppActionButton(
                  onPressed: controller.saving
                      ? null
                      : () => controller.startNewMilestone(
                          isDesktop: Responsive.isDesktop(context),
                        ),
                  icon: Icons.refresh,
                  label: 'New',
                  filled: false,
                ),
                if (controller.selectedRow?.milestone.id != null)
                  AppActionButton(
                    onPressed: controller.saving
                        ? null
                        : () async {
                            final row = controller.selectedRow;
                            if (row?.milestone.id == null) {
                              return;
                            }
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Milestone'),
                                content: Text(
                                  'Remove ${row!.milestone.milestoneName ?? 'this milestone'}?',
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
                            if (confirmed != true) {
                              return;
                            }
                            final message = await controller.deleteMilestone();
                            if (!mounted || message == null) {
                              return;
                            }
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
