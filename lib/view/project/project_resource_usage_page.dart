import '../../controller/project/project_resource_usage_management_controller.dart';
import '../../screen.dart';

class ProjectResourceUsageManagementPage extends StatefulWidget {
  const ProjectResourceUsageManagementPage({
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
  State<ProjectResourceUsageManagementPage> createState() =>
      _ProjectResourceUsageManagementPageState();
}

class _ProjectResourceUsageManagementPageState
    extends State<ProjectResourceUsageManagementPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'ProjectResourceUsageManagementController',
      scope: widget.controllerScope,
    );
    if (!Get.isRegistered<ProjectResourceUsageManagementController>(
      tag: _controllerTag,
    )) {
      Get.put(
        ProjectResourceUsageManagementController(
          constrainedProjectId: widget.constrainedProjectId,
        ),
        tag: _controllerTag,
      );
    }
  }

  @override
  void didUpdateWidget(
    covariant ProjectResourceUsageManagementPage oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.constrainedProjectId != widget.constrainedProjectId) {
      unawaited(_controller.applyProjectConstraint(widget.constrainedProjectId));
    }
  }

  ProjectResourceUsageManagementController get _controller =>
      Get.find<ProjectResourceUsageManagementController>(tag: _controllerTag);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProjectResourceUsageManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => controller.startNewUsage(
              isDesktop: Responsive.isDesktop(context),
            ),
            icon: Icons.precision_manufacturing_outlined,
            label: 'New Resource Usage',
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
          title: 'Project Resource Usage',
          actions: actions,
          scrollController: controller.pageScrollController,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProjectResourceUsageManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading project resource usage...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load project resource usage',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }

    final selectedRow = controller.selectedRow;
    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Project Resource Usage',
      editorTitle: selectedRow?.usage.resourceName,
      scrollController: controller.pageScrollController,
      list: SettingsListCard<ProjectResourceUsageRow>(
        searchController: controller.searchController,
        searchHint: 'Search resource usage',
        items: controller.filteredRows,
        selectedItem: controller.selectedRow,
        emptyMessage: 'No resource usage found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: row.usage.resourceName ?? 'Resource Usage',
          subtitle: [
            row.project.projectName ?? '',
            row.usage.usageDate ?? '',
            controller.assetLabel(controller.assetById(row.usage.assetId)),
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
                  initialValue: controller.assetId,
                  labelText: 'Asset',
                  mappedItems: controller.assetItems,
                  onChanged: controller.setAssetId,
                ),
                AppFormTextField(
                  controller: controller.resourceNameController,
                  labelText: 'Resource Name',
                  validator: Validators.compose([
                    Validators.required('Resource Name'),
                    Validators.optionalMaxLength(255, 'Resource Name'),
                  ]),
                ),
                AppFormTextField(
                  controller: controller.usageDateController,
                  labelText: 'Usage Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.compose([
                    Validators.required('Usage Date'),
                    Validators.optionalDate('Usage Date'),
                  ]),
                ),
                AppFormTextField(
                  controller: controller.usageHoursController,
                  labelText: 'Usage Hours',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Usage Hours',
                  ),
                ),
                AppFormTextField(
                  controller: controller.usageQtyController,
                  labelText: 'Usage Qty',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber('Usage Qty'),
                ),
                AppFormTextField(
                  controller: controller.unitCostController,
                  labelText: 'Unit Cost',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.compose([
                    Validators.required('Unit Cost'),
                    Validators.optionalNonNegativeNumber('Unit Cost'),
                  ]),
                ),
                AppFormTextField(
                  controller: controller.totalCostController,
                  labelText: 'Total Cost',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  readOnly: true,
                  validator: Validators.optionalNonNegativeNumber('Total Cost'),
                ),
                AppFormTextField(
                  controller: controller.voucherIdController,
                  labelText: 'Voucher ID',
                  keyboardType: TextInputType.number,
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
              AppErrorStateView.inline(message: controller.formError!),
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
                          final message = await controller.saveUsage();
                          if (!mounted || message == null) {
                            return;
                          }
                          appScaffoldMessengerKey.currentState
                            ?..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(content: Text(message)));
                        },
                  icon: controller.selectedRow?.usage.id == null
                      ? Icons.add
                      : Icons.save_outlined,
                  label: controller.saving
                      ? 'Saving...'
                      : 'Save Resource Usage',
                  busy: controller.saving,
                ),
                AppActionButton(
                  onPressed: controller.saving
                      ? null
                      : () => controller.startNewUsage(
                          isDesktop: Responsive.isDesktop(context),
                        ),
                  icon: Icons.refresh,
                  label: 'New',
                  filled: false,
                ),
                if (controller.selectedRow?.usage.id != null)
                  AppActionButton(
                    onPressed: controller.saving
                        ? null
                        : () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Resource Usage'),
                                content: const Text(
                                  'Remove this resource usage entry?',
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
                            final message = await controller.deleteUsage();
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
