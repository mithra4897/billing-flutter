import '../../controller/project/project_resource_usage_management_controller.dart';
import '../../screen.dart';
import 'widgets/project_subtab_expandable_section.dart';

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
  bool _filtersVisible = false;

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
  void didUpdateWidget(covariant ProjectResourceUsageManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.constrainedProjectId != widget.constrainedProjectId) {
      unawaited(
        _controller.applyProjectConstraint(widget.constrainedProjectId),
      );
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
          AdaptiveShellSearchField(
            controller: controller.searchController,
            hintText: 'Search resource usage',
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
            icon: Icons.engineering_outlined,
            label: 'New Usage',
          ),
        ];

        return _buildContent(context, controller, widget.useShellActions ? actions : const <Widget>[]);
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProjectResourceUsageManagementController controller,
    List<Widget> actions,
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

    if (controller.isProjectConstrained) {
      return _buildConstrainedContent(context, controller);
    }

    final columns = <PurchaseRegisterColumn<ProjectResourceUsageRow>>[
      PurchaseRegisterColumn(
        label: 'Project',
        flex: 3,
        valueBuilder: (row) => row.project.projectName ?? '',
      ),
      PurchaseRegisterColumn(
        label: 'Resource',
        flex: 3,
        valueBuilder: (row) => row.usage.resourceName ?? '',
      ),
      PurchaseRegisterColumn(
        label: 'Date',
        flex: 2,
        valueBuilder: (row) => row.usage.usageDate ?? '',
      ),
      PurchaseRegisterColumn(
        label: 'Hours',
        flex: 2,
        alignRight: true,
        valueBuilder: (row) => controller.decimalText(row.usage.usageHours),
      ),
      PurchaseRegisterColumn(
        label: 'Total Cost',
        flex: 2,
        alignRight: true,
        valueBuilder: (row) => controller.decimalText(row.usage.totalCost),
      ),
    ];

    return PurchaseRegisterPage<ProjectResourceUsageRow>(
      title: 'Project Resource Usage',
      loading: false,
      errorMessage: null,
      onRetry: controller.loadData,
      embedded: widget.embedded,
      fullPageStyle: true,
      emphasizeRows: false,
      emptyMessage: 'No resource usages found.',
      actions: actions,
      rows: controller.filteredRows,
      columns: columns,
      onRowTap: (row) {
        controller.selectRow(row);
        _openEditor(context, controller);
      },
      filters: _filtersVisible ? _buildFilterPanel(controller) : null,
    );
  }

  Widget _buildFilterPanel(ProjectResourceUsageManagementController controller) {
    return AppRegisterFilters(
      dateFromController: controller.dateFromController,
      dateToController: controller.dateToController,
      onClear: controller.clearFilters,
    );
  }

  void _openEditor(
    BuildContext context,
    ProjectResourceUsageManagementController controller,
  ) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => GetBuilder<ProjectResourceUsageManagementController>(
          tag: _controllerTag,
          builder: (ctrl) => AppStandaloneShell(
            title: ctrl.selectedRow == null ? 'New Resource Usage' : 'Edit Resource Usage',
            scrollController: ScrollController(),
            actions: const <Widget>[],
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppUiConstants.pagePadding),
                  child: _buildEditorForm(context, ctrl),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConstrainedContent(
    BuildContext context,
    ProjectResourceUsageManagementController controller,
  ) {
    return ProjectSubtabExpandableSection(
      title: 'Project Resource Usage',
      description:
          'Track project assets, usage hours, quantities, and cost accumulation for the selected project.',
      addLabel: 'Add Resource Usage',
      addIcon: Icons.precision_manufacturing_outlined,
      onAdd: controller.saving
          ? null
          : () => controller.startNewUsage(
              isDesktop: Responsive.isDesktop(context),
            ),
      addEnabled: !controller.saving,
      emptyMessage: 'No resource usage found.',
      showDraftTile: controller.showDraftTile && controller.selectedRow == null,
      draftTitle: 'New Resource Usage',
      draftSubtitle: 'Add a resource usage entry for this project.',
      onDraftToggle: controller.hideDraftTile,
      draftChild: _buildEditorForm(context, controller),

      recordTiles: controller.filteredRows
          .map((row) {
            final expanded = controller.selectedRow?.usage.id == row.usage.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
              child: SettingsExpandableTile(
                key: ValueKey<String>(
                  'project-resource-usage-${row.usage.id}-$expanded',
                ),
                title: row.usage.resourceName ?? 'Resource Usage',
                subtitle: [
                  row.usage.usageDate ?? '',
                  controller.assetLabel(
                    controller.assetById(row.usage.assetId),
                  ),
                ].where((item) => item.isNotEmpty).join(' | '),
                detail: [
                  controller.decimalText(row.usage.usageHours),
                  controller.decimalText(row.usage.totalCost),
                ].where((item) => item.isNotEmpty).join(' | '),
                expanded: expanded,
                highlighted: expanded,
                leadingIcon: Icons.precision_manufacturing_outlined,
                trailing: IconButton(
                  tooltip: 'Delete resource usage',
                  onPressed: controller.saving
                      ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Delete Resource Usage'),
                              content: const Text(
                                'Remove this resource usage entry?',
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
                          final message = await controller.deleteUsage();
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
    ProjectResourceUsageManagementController controller,
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
