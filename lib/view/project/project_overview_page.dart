import '../../controller/project/project_management_controller.dart';
import '../../screen.dart';
import 'widgets/project_filter_options.dart';
import 'widgets/project_kanban_board.dart';

class ProjectOverviewPage extends StatefulWidget {
  const ProjectOverviewPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProjectOverviewPage> createState() => _ProjectOverviewPageState();
}

class _ProjectOverviewPageState extends State<ProjectOverviewPage> {
  static const _controllerScope = <String, Object?>{'host': 'project_overview'};

  late final String _controllerTag;
  final ScrollController _scrollController = ScrollController();
  bool _filtersVisible = false;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag(
      'ProjectManagementController',
      scope: _controllerScope,
    );
    if (!Get.isRegistered<ProjectManagementController>(tag: _controllerTag)) {
      Get.put(ProjectManagementController(), tag: _controllerTag);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProjectManagementController>(
      tag: _controllerTag,
      builder: (controller) {
        final actions = <Widget>[
          AdaptiveShellSearchField(
            controller: controller.searchController,
            hintText: 'Search projects',
          ),
          AdaptiveShellActionButton(
            onPressed: () => setState(() => _filtersVisible = !_filtersVisible),
            icon: Icons.filter_list_outlined,
            label: 'Filter',
          ),
          AdaptiveShellActionButton(
            onPressed: () => openModuleShellRoute(context, '/projects?new=1'),
            icon: Icons.add_circle_outline,
            label: 'New Project',
          ),
        ];
        final content = _buildContent(context, controller);
        if (widget.embedded) {
          return ShellPageActions(actions: actions, child: content);
        }
        return AppStandaloneShell(
          title: 'Projects',
          actions: actions,
          scrollController: _scrollController,
          child: content,
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

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppUiConstants.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_filtersVisible) ...[
            AppSectionCard(
              child: AppRegisterFilters(
                dateFromController: controller.dateFromController,
                dateToController: controller.dateToController,
                partyLabel: 'Customer',
                partyItems: controller.customerFilterItems,
                selectedPartyIds: controller.filterCustomerIds,
                onPartyChanged: controller.setFilterCustomerIds,
                statusItems: projectStatusItems,
                selectedStatuses: controller.selectedStatuses,
                onStatusesChanged: controller.setSelectedStatuses,
                typeLabel: 'Project type',
                typeItems: controller.projectTypeFilterItems,
                selectedTypes: controller.selectedProjectTypes,
                onTypesChanged: controller.setSelectedProjectTypes,
                categoryLabel: 'Billing method',
                categoryItems: controller.billingMethodFilterItems,
                selectedCategories: controller.selectedBillingMethods,
                onCategoriesChanged: controller.setSelectedBillingMethods,
                onClear: controller.clearFilters,
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingLg),
          ],
          ProjectGrid(
            projects: controller.filteredProjects,
            customerName: controller.partyName,
            employeeNames: controller.projectEmployeeNames,
            onOpen: (project) {
              final projectId = project.id;
              if (projectId != null) {
                openModuleShellRoute(context, '/projects/$projectId/detail');
              }
            },
            onEdit: (project) {
              final projectId = project.id;
              if (projectId != null) {
                openModuleShellRoute(context, '/projects?edit=$projectId');
              }
            },
            onDelete: (project) => _deleteProject(context, controller, project),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProject(
    BuildContext context,
    ProjectManagementController controller,
    ProjectModel project,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Remove ${project.projectName ?? 'this project'}?'),
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
    if (confirmed != true || !mounted) return;
    final message = await controller.deleteProject(project);
    if (!mounted || message == null) return;
    appScaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
