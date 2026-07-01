import '../../controller/project/project_vendor_work_management_controller.dart';
import '../../screen.dart';
import 'widgets/project_subtab_expandable_section.dart';

class ProjectVendorWorkManagementPage extends StatefulWidget {
  const ProjectVendorWorkManagementPage({
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
  State<ProjectVendorWorkManagementPage> createState() =>
      _ProjectVendorWorkManagementPageState();
}

class _ProjectVendorWorkManagementPageState
    extends State<ProjectVendorWorkManagementPage> {
  static const List<AppDropdownItem<String>> _statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'open', label: 'Open'),
        AppDropdownItem(value: 'ordered', label: 'Ordered'),
        AppDropdownItem(value: 'in_progress', label: 'In Progress'),
        AppDropdownItem(value: 'completed', label: 'Completed'),
      ];

  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'ProjectVendorWorkManagementController',
      scope: widget.controllerScope,
    );
    if (!Get.isRegistered<ProjectVendorWorkManagementController>(
      tag: _controllerTag,
    )) {
      Get.put(
        ProjectVendorWorkManagementController(
          constrainedProjectId: widget.constrainedProjectId,
        ),
        tag: _controllerTag,
      );
    }
  }

  @override
  void didUpdateWidget(covariant ProjectVendorWorkManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.constrainedProjectId != widget.constrainedProjectId) {
      unawaited(
        _controller.applyProjectConstraint(widget.constrainedProjectId),
      );
    }
  }

  ProjectVendorWorkManagementController get _controller =>
      Get.find<ProjectVendorWorkManagementController>(tag: _controllerTag);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProjectVendorWorkManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => controller.startNewVendorWork(
              isDesktop: Responsive.isDesktop(context),
            ),
            icon: Icons.handyman_outlined,
            label: 'New Vendor Work',
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
          title: 'Project Vendor Works',
          actions: actions,
          scrollController: controller.pageScrollController,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProjectVendorWorkManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading project vendor works...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load project vendor works',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }

    if (controller.isProjectConstrained) {
      return _buildConstrainedContent(context, controller);
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Project Vendor Works',
      editorTitle: controller.partyName(
        controller.selectedRow?.work.vendorPartyId,
      ),
      scrollController: controller.pageScrollController,
      list: SettingsListCard<ProjectVendorWorkRow>(
        searchController: controller.searchController,
        searchHint: 'Search vendor works',
        items: controller.filteredRows,
        selectedItem: controller.selectedRow,
        emptyMessage: 'No vendor works found.',
        itemBuilder: (row, selected) => SettingsListTile(
          title: controller.partyName(row.work.vendorPartyId).isNotEmpty
              ? controller.partyName(row.work.vendorPartyId)
              : 'Vendor Work',
          subtitle: [
            row.project.projectName ?? '',
            row.work.workStatus ?? '',
            controller.decimalText(row.work.amount),
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
    ProjectVendorWorkManagementController controller,
  ) {
    return ProjectSubtabExpandableSection(
      title: 'Project Vendor Works',
      description:
          'Manage outsourced work, linked vendor documents, and committed values for the selected project.',
      addLabel: 'Add Vendor Work',
      addIcon: Icons.handyman_outlined,
      onAdd: controller.saving
          ? null
          : () => controller.startNewVendorWork(
              isDesktop: Responsive.isDesktop(context),
            ),
      addEnabled: !controller.saving,
      emptyMessage: 'No vendor works found.',
      showDraftTile: controller.showDraftTile && controller.selectedRow == null,
      draftTitle: 'New Vendor Work',
      draftSubtitle: 'Add a vendor work entry for this project.',
      onDraftToggle: controller.hideDraftTile,
      draftChild: _buildEditorForm(context, controller),

      recordTiles: controller.filteredRows
          .map((row) {
            final expanded = controller.selectedRow?.work.id == row.work.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
              child: SettingsExpandableTile(
                key: ValueKey<String>(
                  'project-vendor-work-${row.work.id}-$expanded',
                ),
                title: controller.partyName(row.work.vendorPartyId).isNotEmpty
                    ? controller.partyName(row.work.vendorPartyId)
                    : 'Vendor Work',
                subtitle: [
                  row.work.workStatus ?? '',
                  controller.decimalText(row.work.amount),
                ].where((item) => item.isNotEmpty).join(' | '),
                detail: row.work.workDescription ?? '',
                expanded: expanded,
                highlighted: expanded,
                leadingIcon: Icons.handyman_outlined,
                trailing: IconButton(
                  tooltip: 'Delete vendor work',
                  onPressed: controller.saving
                      ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Delete Vendor Work'),
                              content: const Text(
                                'Remove this vendor work entry?',
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
                          final message = await controller.deleteVendorWork();
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
    ProjectVendorWorkManagementController controller,
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
                  initialValue: controller.vendorPartyId,
                  labelText: 'Vendor',
                  mappedItems: controller.partyItems,
                  onChanged: controller.setVendorPartyId,
                  validator: Validators.requiredSelection('Vendor'),
                ),
                AppDropdownField<int>.fromMapped(
                  initialValue: controller.purchaseOrderId,
                  labelText: 'Purchase Order',
                  mappedItems: controller.purchaseOrderItems,
                  onChanged: controller.setPurchaseOrderId,
                ),
                AppDropdownField<int>.fromMapped(
                  initialValue: controller.purchaseInvoiceId,
                  labelText: 'Purchase Invoice',
                  mappedItems: controller.purchaseInvoiceItems,
                  onChanged: controller.setPurchaseInvoiceId,
                ),
                AppDropdownField<String>.fromMapped(
                  initialValue: controller.status,
                  labelText: 'Work Status',
                  mappedItems: _statusItems,
                  onChanged: (value) =>
                      controller.setStatus(value ?? controller.status),
                ),
                AppFormTextField(
                  controller: controller.amountController,
                  labelText: 'Amount',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.compose([
                    Validators.required('Amount'),
                    Validators.optionalNonNegativeNumber('Amount'),
                  ]),
                ),
                AppFormTextField(
                  controller: controller.voucherIdController,
                  labelText: 'Voucher ID',
                  keyboardType: TextInputType.number,
                ),
                AppFormTextField(
                  controller: controller.descriptionController,
                  labelText: 'Work Description',
                  maxLines: 3,
                  validator: Validators.compose([
                    Validators.required('Work Description'),
                    Validators.optionalMaxLength(500, 'Work Description'),
                  ]),
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
                          final message = await controller.saveVendorWork();
                          if (!mounted || message == null) {
                            return;
                          }
                          appScaffoldMessengerKey.currentState
                            ?..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(content: Text(message)));
                        },
                  icon: controller.selectedRow?.work.id == null
                      ? Icons.add
                      : Icons.save_outlined,
                  label: controller.saving ? 'Saving...' : 'Save Vendor Work',
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
