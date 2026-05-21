import '../../controller/project/project_management_controller.dart';
import '../../screen.dart';

class ProjectManagementPage extends StatefulWidget {
  const ProjectManagementPage({
    super.key,
    this.embedded = false,
    this.initialTabIndex = 0,
    this.showOnlyTabIndex,
  });

  final bool embedded;
  final int initialTabIndex;
  final int? showOnlyTabIndex;

  @override
  State<ProjectManagementPage> createState() => _ProjectManagementPageState();
}

class _ProjectManagementPageState extends State<ProjectManagementPage> {
  static const List<AppDropdownItem<String>> _billingMethodItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'fixed', label: 'Fixed'),
        AppDropdownItem(value: 'time_and_material', label: 'Time And Material'),
        AppDropdownItem(value: 'milestone', label: 'Milestone'),
        AppDropdownItem(value: 'cost_plus', label: 'Cost Plus'),
      ];

  static const List<AppDropdownItem<String>> _projectStatusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'draft', label: 'Draft'),
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
    _controllerTag = persistentControllerTag('ProjectManagementController');
    Get.put(ProjectManagementController(), tag: _controllerTag);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProjectManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellActionButton(
            onPressed: () => controller.startNewProject(
              isDesktop: Responsive.isDesktop(context),
            ),
            icon: Icons.add_circle_outline,
            label: 'New Project',
          ),
        ];

        if (widget.embedded) {
          return ShellPageActions(
            actions: actions,
            child: _buildContent(context, controller),
          );
        }

        return AppStandaloneShell(
          title: 'Projects',
          actions: actions,
          scrollController: controller.pageScrollController,
          child: _buildContent(context, controller),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProjectManagementController controller,
  ) {
    if (controller.initialLoading) {
      return const AppLoadingView(message: 'Loading projects...');
    }
    if (controller.pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load projects',
        message: controller.pageError!,
        onRetry: controller.loadData,
      );
    }

    return SettingsWorkspace(
      controller: controller.workspaceController,
      title: 'Projects',
      editorTitle:
          controller.selectedProject?.projectName ??
          controller.selectedProject?.projectCode,
      scrollController: controller.pageScrollController,
      list: SettingsListCard<ProjectModel>(
        searchController: controller.searchController,
        searchHint: 'Search projects',
        items: controller.filteredProjects,
        selectedItem: controller.selectedProject == null
            ? null
            : controller.filteredProjects.cast<ProjectModel?>().firstWhere(
                (item) => item?.id == controller.selectedProject?.id,
                orElse: () => null,
              ),
        emptyMessage: 'No projects found.',
        itemBuilder: (project, selected) => SettingsListTile(
          title: project.projectName ?? '',
          subtitle: [
            project.projectCode ?? '',
            controller.companyName(project.companyId),
            project.projectStatus ?? '',
          ].where((item) => item.isNotEmpty).join(' • '),
          selected: selected,
          trailing: SettingsStatusPill(
            label: (project.isActive ?? true) ? 'Active' : 'Inactive',
            active: project.isActive ?? true,
          ),
          onTap: () => controller.selectProject(project),
        ),
      ),
      editor: _buildEditor(context, controller),
    );
  }

  Widget _buildEditor(
    BuildContext context,
    ProjectManagementController controller,
  ) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsFormWrap(
            children: [
              AppFormTextField(
                controller: controller.projectCodeController,
                labelText: 'Project Code',
                readOnly: true,
                suffixIcon: controller.loadingProjectCode
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                validator: Validators.compose([
                  Validators.required('Project Code'),
                  Validators.optionalMaxLength(100, 'Project Code'),
                ]),
              ),
              AppFormTextField(
                controller: controller.projectNameController,
                labelText: 'Project Name',
                validator: Validators.compose([
                  Validators.required('Project Name'),
                  Validators.optionalMaxLength(255, 'Project Name'),
                ]),
              ),
              AppDropdownField<int>.fromMapped(
                initialValue: controller.customerPartyId,
                labelText: 'Customer',
                doctypeLabel: 'Customer',
                allowCreate: true,
                onNavigateToCreateNew: (name) {
                  final uri = Uri(
                    path: '/parties',
                    queryParameters: {
                      'new': '1',
                      if (name.trim().isNotEmpty) 'party_name': name.trim(),
                    },
                  );
                  final navigate = ShellRouteScope.maybeOf(context);
                  if (navigate != null) {
                    navigate(uri.toString());
                  } else {
                    Navigator.of(context).pushNamed(uri.toString());
                  }
                },
                mappedItems: controller.partyItems,
                onChanged: controller.setCustomerPartyId,
              ),
              AppFormTextField(
                controller: controller.projectTypeController,
                labelText: 'Project Type',
                validator: Validators.optionalMaxLength(100, 'Project Type'),
              ),
              AppDropdownField<String>.fromMapped(
                initialValue: controller.billingMethod,
                labelText: 'Billing Method',
                mappedItems: _billingMethodItems,
                onChanged: (value) => controller.setBillingMethod(
                  value ?? controller.billingMethod,
                ),
              ),
              AppFormTextField(
                controller: controller.expectedStartDateController,
                labelText: 'Expected Start Date',
                keyboardType: TextInputType.datetime,
                inputFormatters: const [DateInputFormatter()],
                validator: Validators.optionalDate('Expected Start Date'),
              ),
              AppFormTextField(
                controller: controller.expectedEndDateController,
                labelText: 'Expected End Date',
                keyboardType: TextInputType.datetime,
                inputFormatters: const [DateInputFormatter()],
                validator: Validators.optionalDateOnOrAfter(
                  'Expected End Date',
                  () => controller.expectedStartDateController.text,
                  startFieldName: 'Expected Start Date',
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
                controller: controller.budgetAmountController,
                labelText: 'Budget Amount',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.optionalNonNegativeNumber(
                  'Budget Amount',
                ),
              ),
              AppFormTextField(
                controller: controller.percentCompletionController,
                labelText: 'Percent Completion',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.optionalNonNegativeNumber(
                  'Percent Completion',
                ),
              ),
              AppDropdownField<String>.fromMapped(
                initialValue: controller.projectStatus,
                labelText: 'Project Status',
                mappedItems: _projectStatusItems,
                onChanged: (value) => controller.setProjectStatus(
                  value ?? controller.projectStatus,
                ),
              ),
              UploadPathField(
                controller: controller.imagePathController,
                labelText: 'Image Path',
                onUpload: () => controller.uploadProjectImage(context),
                isUploading: controller.uploadingImage,
                previewUrl: AppConfig.resolvePublicFileUrl(
                  controller.imagePathController.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppSwitchTile(
            label: 'Active',
            subtitle:
                'Inactive projects stay visible but should not accept new work.',
            value: controller.isActive,
            onChanged: controller.setIsActive,
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
                        final message = await controller.saveProject();
                        if (!mounted || message == null) {
                          return;
                        }
                        appScaffoldMessengerKey.currentState
                          ?..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(content: Text(message)));
                      },
                icon: controller.selectedProject?.id == null
                    ? Icons.add
                    : Icons.save_outlined,
                label: controller.saving ? 'Saving...' : 'Save Project',
                busy: controller.saving,
              ),
              AppActionButton(
                onPressed: controller.saving
                    ? null
                    : () => controller.startNewProject(
                        isDesktop: Responsive.isDesktop(context),
                      ),
                icon: Icons.refresh,
                label: 'New',
                filled: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
