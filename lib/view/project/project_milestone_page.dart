import '../../controller/project/project_milestone_management_controller.dart';
import '../../screen.dart';
import 'widgets/project_subtab_expandable_section.dart';

class ProjectMilestoneManagementPage extends StatefulWidget {
  const ProjectMilestoneManagementPage({
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
      scope: widget.controllerScope,
    );
    if (!Get.isRegistered<ProjectMilestoneManagementController>(
      tag: _controllerTag,
    )) {
      Get.put(
        ProjectMilestoneManagementController(
          constrainedProjectId: widget.constrainedProjectId,
        ),
        tag: _controllerTag,
      );
    }
  }

  @override
  void didUpdateWidget(covariant ProjectMilestoneManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.constrainedProjectId != widget.constrainedProjectId) {
      unawaited(
        _controller.applyProjectConstraint(widget.constrainedProjectId),
      );
    }
  }

  ProjectMilestoneManagementController get _controller =>
      Get.find<ProjectMilestoneManagementController>(tag: _controllerTag);

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
        if (widget.embedded && widget.useShellActions) {
          return ShellPageActions(actions: actions, child: content);
        }
        if (widget.embedded) {
          return content;
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

    if (controller.isProjectConstrained) {
      return _buildConstrainedContent(context, controller);
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
      editorBuilder: (_) => _buildEditorForm(context, controller),
    );
  }

  Widget _buildConstrainedContent(
    BuildContext context,
    ProjectMilestoneManagementController controller,
  ) {
    return ProjectSubtabExpandableSection(
      title: 'Project Milestones',
      description:
          'Track milestone commitments, dates, values, and completion progress for the selected project.',
      addLabel: 'Add Milestone',
      addIcon: Icons.flag_outlined,
      onAdd: controller.saving
          ? null
          : () => controller.startNewMilestone(
              isDesktop: Responsive.isDesktop(context),
            ),
      addEnabled: !controller.saving,
      emptyMessage: 'No milestones found.',
      showDraftTile: controller.showDraftTile && controller.selectedRow == null,
      draftTitle: 'New Milestone',
      draftSubtitle: 'Add a milestone for this project.',
      onDraftToggle: controller.hideDraftTile,
      draftChild: _buildEditorForm(context, controller),

      recordTiles: controller.filteredRows
          .map((row) {
            final expanded =
                controller.selectedRow?.milestone.id == row.milestone.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
              child: SettingsExpandableTile(
                key: ValueKey<String>(
                  'project-milestone-${row.milestone.id}-$expanded',
                ),
                title: row.milestone.milestoneName ?? 'Milestone',
                subtitle: [
                  row.milestone.targetDate ?? '',
                  row.milestone.milestoneStatus ?? '',
                ].where((item) => item.isNotEmpty).join(' | '),
                detail: row.milestone.milestoneAmount == null
                    ? ''
                    : 'Amount ${row.milestone.milestoneAmount}',
                expanded: expanded,
                highlighted: expanded,
                leadingIcon: Icons.flag_outlined,
                trailing: IconButton(
                  tooltip: 'Delete milestone',
                  onPressed: controller.saving
                      ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Delete Milestone'),
                              content: Text(
                                'Remove ${row.milestone.milestoneName ?? 'this milestone'}?',
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
                          final message = await controller.deleteMilestone();
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
    ProjectMilestoneManagementController controller,
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
