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

class _ProjectManagementPageState extends State<ProjectManagementPage>
    with SingleTickerProviderStateMixin {
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

  static const List<_ProjectMasterTab> _allTabs = <_ProjectMasterTab>[
    _ProjectMasterTab(
      key: 'general',
      label: 'General',
      emptyMessage: 'Create or select a project to manage its details.',
    ),
    _ProjectMasterTab(
      key: 'tasks',
      label: 'Tasks',
      emptyMessage: 'Save the project first to add and manage tasks.',
    ),
    _ProjectMasterTab(
      key: 'milestones',
      label: 'Milestones',
      emptyMessage: 'Save the project first to manage milestones.',
    ),
    _ProjectMasterTab(
      key: 'timesheets',
      label: 'Timesheets',
      emptyMessage: 'Save the project first to manage timesheets.',
    ),
    _ProjectMasterTab(
      key: 'expenses',
      label: 'Expenses',
      emptyMessage: 'Save the project first to manage project expenses.',
    ),
    _ProjectMasterTab(
      key: 'resources',
      label: 'Resource Usage',
      emptyMessage: 'Save the project first to track resource usage.',
    ),
    _ProjectMasterTab(
      key: 'vendor_works',
      label: 'Vendor Works',
      emptyMessage: 'Save the project first to manage vendor work.',
    ),
    _ProjectMasterTab(
      key: 'billings',
      label: 'Billings',
      emptyMessage: 'Save the project first to manage billings.',
    ),
  ];

  late final String _controllerTag;
  late final TabController _tabController;

  List<_ProjectMasterTab> get _visibleTabs {
    final showOnly = widget.showOnlyTabIndex;
    if (showOnly != null && showOnly >= 0 && showOnly < _allTabs.length) {
      return <_ProjectMasterTab>[_allTabs[showOnly]];
    }
    return _allTabs;
  }

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('ProjectManagementController');
    if (!Get.isRegistered<ProjectManagementController>(tag: _controllerTag)) {
      Get.put(ProjectManagementController(), tag: _controllerTag);
    }

    final tabs = _visibleTabs;
    final initialIndex = widget.showOnlyTabIndex != null
        ? 0
        : widget.initialTabIndex.clamp(0, tabs.length - 1);
    _tabController = TabController(
      length: tabs.length,
      vsync: this,
      initialIndex: initialIndex,
    )..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          ].where((item) => item.isNotEmpty).join(' | '),
          selected: selected,
          trailing: SettingsStatusPill(
            label: (project.isActive ?? true) ? 'Active' : 'Inactive',
            active: project.isActive ?? true,
          ),
          onTap: () => controller.selectProject(project),
        ),
      ),
      editorBuilder: (_) => _buildEditor(context, controller),
    );
  }

  Widget _buildEditor(
    BuildContext context,
    ProjectManagementController controller,
  ) {
    final tabs = _visibleTabs;
    final activeTab = tabs[_tabController.index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tabs.length > 1) ...[
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: tabs.map((tab) => Tab(text: tab.label)).toList(growable: false),
          ),
          const SizedBox(height: 16),
        ],
        _buildTabBody(context, controller, activeTab),
      ],
    );
  }

  Widget _buildTabBody(
    BuildContext context,
    ProjectManagementController controller,
    _ProjectMasterTab tab,
  ) {
    switch (tab.key) {
      case 'general':
        return _buildGeneralTab(context, controller);
      case 'tasks':
        return _buildProjectChildTab(
          projectId: controller.selectedProject?.id,
          emptyMessage: tab.emptyMessage,
          child: ProjectTaskManagementPage(
            key: const ValueKey<String>('project-master-tasks'),
            embedded: true,
            constrainedProjectId: controller.selectedProject?.id,
            controllerScope: const <String, Object?>{
              'host': 'project_master',
              'tab': 'tasks',
            },
            useShellActions: false,
          ),
        );
      case 'milestones':
        return _buildProjectChildTab(
          projectId: controller.selectedProject?.id,
          emptyMessage: tab.emptyMessage,
          child: ProjectMilestoneManagementPage(
            key: const ValueKey<String>('project-master-milestones'),
            embedded: true,
            constrainedProjectId: controller.selectedProject?.id,
            controllerScope: const <String, Object?>{
              'host': 'project_master',
              'tab': 'milestones',
            },
            useShellActions: false,
          ),
        );
      case 'timesheets':
        return _buildProjectChildTab(
          projectId: controller.selectedProject?.id,
          emptyMessage: tab.emptyMessage,
          child: ProjectTimesheetManagementPage(
            key: const ValueKey<String>('project-master-timesheets'),
            embedded: true,
            constrainedProjectId: controller.selectedProject?.id,
            controllerScope: const <String, Object?>{
              'host': 'project_master',
              'tab': 'timesheets',
            },
            useShellActions: false,
          ),
        );
      case 'expenses':
        return _buildProjectChildTab(
          projectId: controller.selectedProject?.id,
          emptyMessage: tab.emptyMessage,
          child: ProjectExpenseManagementPage(
            key: const ValueKey<String>('project-master-expenses'),
            embedded: true,
            constrainedProjectId: controller.selectedProject?.id,
            controllerScope: const <String, Object?>{
              'host': 'project_master',
              'tab': 'expenses',
            },
            useShellActions: false,
          ),
        );
      case 'resources':
        return _buildProjectChildTab(
          projectId: controller.selectedProject?.id,
          emptyMessage: tab.emptyMessage,
          child: ProjectResourceUsageManagementPage(
            key: const ValueKey<String>('project-master-resources'),
            embedded: true,
            constrainedProjectId: controller.selectedProject?.id,
            controllerScope: const <String, Object?>{
              'host': 'project_master',
              'tab': 'resources',
            },
            useShellActions: false,
          ),
        );
      case 'vendor_works':
        return _buildProjectChildTab(
          projectId: controller.selectedProject?.id,
          emptyMessage: tab.emptyMessage,
          child: ProjectVendorWorkManagementPage(
            key: const ValueKey<String>('project-master-vendor-works'),
            embedded: true,
            constrainedProjectId: controller.selectedProject?.id,
            controllerScope: const <String, Object?>{
              'host': 'project_master',
              'tab': 'vendor_works',
            },
            useShellActions: false,
          ),
        );
      case 'billings':
        return _buildProjectChildTab(
          projectId: controller.selectedProject?.id,
          emptyMessage: tab.emptyMessage,
          child: ProjectBillingManagementPage(
            key: const ValueKey<String>('project-master-billings'),
            embedded: true,
            constrainedProjectId: controller.selectedProject?.id,
            controllerScope: const <String, Object?>{
              'host': 'project_master',
              'tab': 'billings',
            },
            useShellActions: false,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProjectChildTab({
    required int? projectId,
    required String emptyMessage,
    required Widget child,
  }) {
    if (projectId == null) {
      return AppSectionCard(
        child: Padding(
          padding: const EdgeInsets.all(AppUiConstants.cardPadding),
          child: Text(emptyMessage),
        ),
      );
    }

    return child;
  }

  Widget _buildGeneralTab(
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

class _ProjectMasterTab {
  const _ProjectMasterTab({
    required this.key,
    required this.label,
    required this.emptyMessage,
  });

  final String key;
  final String label;
  final String emptyMessage;
}
