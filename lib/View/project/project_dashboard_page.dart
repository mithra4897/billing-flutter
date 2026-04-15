import '../../screen.dart';

class ProjectDashboardPage extends StatefulWidget {
  const ProjectDashboardPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProjectDashboardPage> createState() => _ProjectDashboardPageState();
}

class _ProjectDashboardPageState extends State<ProjectDashboardPage> {
  final ProjectService _projectService = ProjectService();
  final MasterService _masterService = MasterService();
  final ScrollController _pageScrollController = ScrollController();

  bool _loading = true;
  String? _pageError;
  List<ProjectModel> _projects = const <ProjectModel>[];
  List<_DashboardTaskRow> _tasks = const <_DashboardTaskRow>[];
  List<_DashboardMilestoneRow> _milestones = const <_DashboardMilestoneRow>[];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _pageError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _projectService.projects(
          filters: const {'per_page': 200, 'sort_by': 'project_name'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
      ]);

      final projects =
          (responses[0] as PaginatedResponse<ProjectModel>).data ??
          const <ProjectModel>[];
      final companies =
          (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final activeCompanies = companies.where((item) => item.isActive).toList();
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );

      final scopedProjects = contextSelection.companyId == null
          ? projects
          : projects
                .where((item) => item.companyId == contextSelection.companyId)
                .toList(growable: false);

      final tasks = scopedProjects
          .expand(
            (project) => project.tasks.map(
              (task) => _DashboardTaskRow(project: project, task: task),
            ),
          )
          .toList(growable: false);

      final milestones = scopedProjects
          .expand(
            (project) => project.milestones.map(
              (milestone) => _DashboardMilestoneRow(
                project: project,
                milestone: milestone,
              ),
            ),
          )
          .toList(growable: false);

      if (!mounted) {
        return;
      }

      setState(() {
        _projects = scopedProjects;
        _tasks = tasks;
        _milestones = milestones;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _pageError = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    if (widget.embedded) {
      return content;
    }

    return AppStandaloneShell(
      title: 'Project Dashboard',
      scrollController: _pageScrollController,
      actions: const <Widget>[],
      child: content,
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const AppLoadingView(message: 'Loading project dashboard...');
    }

    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable To Load Project Dashboard',
        message: _pageError!,
        onRetry: _loadData,
      );
    }

    final cards = <Widget>[
      Expanded(
        child: _DashboardListCard<ProjectModel>(
          title: 'Projects',
          icon: Icons.folder_open_outlined,
          items: _projects,
          emptyMessage: 'No projects available.',
          itemBuilder: (project) => SettingsListTile(
            title: project.projectName ?? project.projectCode ?? 'Project',
            subtitle: [
              project.projectCode ?? '',
              project.projectType ?? '',
            ].where((item) => item.isNotEmpty).join(' • '),
            detail: project.projectStatus,
            selected: false,
            onTap: () {},
            trailing: SettingsStatusPill(
              label: (project.projectStatus ?? 'draft').toUpperCase(),
              active:
                  (project.projectStatus ?? 'draft') == 'open' ||
                  (project.projectStatus ?? 'draft') == 'working' ||
                  (project.projectStatus ?? 'draft') == 'completed',
            ),
          ),
        ),
      ),
      Expanded(
        child: _DashboardListCard<_DashboardTaskRow>(
          title: 'Tasks',
          icon: Icons.task_alt_outlined,
          items: _tasks,
          emptyMessage: 'No tasks available.',
          itemBuilder: (row) => SettingsListTile(
            title: row.task.taskName ?? row.task.taskCode ?? 'Task',
            subtitle: [
              row.task.taskCode ?? '',
              row.project.projectName ?? '',
            ].where((item) => item.isNotEmpty).join(' • '),
            detail: row.task.taskStatus,
            selected: false,
            onTap: () {},
            trailing: SettingsStatusPill(
              label: (row.task.taskStatus ?? 'open').toUpperCase(),
              active:
                  (row.task.taskStatus ?? 'open') == 'completed' ||
                  (row.task.taskStatus ?? 'open') == 'working',
            ),
          ),
        ),
      ),
      Expanded(
        child: _DashboardListCard<_DashboardMilestoneRow>(
          title: 'Milestones',
          icon: Icons.flag_outlined,
          items: _milestones,
          emptyMessage: 'No milestones available.',
          itemBuilder: (row) => SettingsListTile(
            title: row.milestone.milestoneName ?? 'Milestone',
            subtitle: [
              row.project.projectName ?? '',
              row.milestone.targetDate ?? '',
            ].where((item) => item.isNotEmpty).join(' • '),
            detail: row.milestone.milestoneStatus,
            selected: false,
            onTap: () {},
            trailing: SettingsStatusPill(
              label: (row.milestone.milestoneStatus ?? 'open').toUpperCase(),
              active: (row.milestone.milestoneStatus ?? 'open') == 'completed',
            ),
          ),
        ),
      ),
    ];

    return SingleChildScrollView(
      controller: _pageScrollController,
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: Responsive.isDesktop(context)
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                cards[0],
                const SizedBox(width: AppUiConstants.spacingLg),
                cards[1],
                const SizedBox(width: AppUiConstants.spacingLg),
                cards[2],
              ],
            )
          : Column(
              children: [
                cards[0],
                const SizedBox(height: AppUiConstants.spacingLg),
                cards[1],
                const SizedBox(height: AppUiConstants.spacingLg),
                cards[2],
              ],
            ),
    );
  }
}

class _DashboardListCard<T> extends StatelessWidget {
  const _DashboardListCard({
    required this.title,
    required this.icon,
    required this.items,
    required this.emptyMessage,
    required this.itemBuilder,
    this.height = 520,
  });

  final String title;
  final IconData icon;
  final List<T> items;
  final String emptyMessage;
  final Widget Function(T item) itemBuilder;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: AppSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: AppUiConstants.spacingSm),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Expanded(
              child: items.isEmpty
                  ? Align(
                      alignment: Alignment.topLeft,
                      child: Text(emptyMessage),
                    )
                  : Scrollbar(
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppUiConstants.spacingXs),
                        itemBuilder: (context, index) => itemBuilder(
                          items[index],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTaskRow {
  const _DashboardTaskRow({required this.project, required this.task});

  final ProjectModel project;
  final ProjectTaskModel task;
}

class _DashboardMilestoneRow {
  const _DashboardMilestoneRow({
    required this.project,
    required this.milestone,
  });

  final ProjectModel project;
  final ProjectMilestoneModel milestone;
}
