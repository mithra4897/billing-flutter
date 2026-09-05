import '../../controller/project/project_management_controller.dart';
import '../../screen.dart';

class ProjectDetailPage extends StatefulWidget {
  const ProjectDetailPage({
    super.key,
    required this.projectId,
    this.embedded = false,
  });

  final int projectId;
  final bool embedded;

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  static const _controllerScope = <String, Object?>{'host': 'project_overview'};

  late final String _controllerTag;
  final ScrollController _scrollController = ScrollController();

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
        if (controller.initialLoading) {
          return const AppLoadingView(message: 'Loading project...');
        }
        final project = controller.projects.cast<ProjectModel?>().firstWhere(
          (item) => item?.id == widget.projectId,
          orElse: () => null,
        );
        if (project == null) {
          return AppErrorStateView(
            title: 'Project not found',
            message: 'This project may be unavailable in the current context.',
            onRetry: () => controller.loadData(selectId: widget.projectId),
          );
        }
        final content = _buildContent(context, controller, project);
        if (widget.embedded) {
          return ShellPageActions(actions: const <Widget>[], child: content);
        }
        return AppStandaloneShell(
          title: project.projectName ?? 'Project',
          actions: const <Widget>[],
          scrollController: _scrollController,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProjectManagementController controller,
    ProjectModel project,
  ) {
    final projectId = project.id!;
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppUiConstants.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProjectDetailHeader(
            project: project,
            customerName: controller.partyName(project.customerPartyId),
            onBack: () => openModuleShellRoute(context, '/projects'),
          ),
          const SizedBox(height: AppUiConstants.spacingLg),
          _ProjectDetailExpandableSection(
            title: 'Tasks',
            recordCount: project.tasks.length,
            accentColor: theme.colorScheme.primary,
            childBuilder: () => _detailSectionPage(
              ProjectTaskManagementPage(
                key: ValueKey('project-detail-tasks-$projectId'),
                embedded: true,
                constrainedProjectId: projectId,
                controllerScope: <String, Object?>{
                  'host': 'project_detail',
                  'project_id': projectId,
                  'section': 'tasks',
                },
                useShellActions: false,
                constrainedTableView: true,
              ),
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          _ProjectDetailExpandableSection(
            title: 'Milestones',
            recordCount: project.milestones.length,
            accentColor: appTheme.info,
            childBuilder: () => _detailSectionPage(
              ProjectMilestoneManagementPage(
                key: ValueKey('project-detail-milestones-$projectId'),
                embedded: true,
                constrainedProjectId: projectId,
                controllerScope: <String, Object?>{
                  'host': 'project_detail',
                  'project_id': projectId,
                  'section': 'milestones',
                },
                useShellActions: false,
                constrainedTableView: true,
              ),
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          _ProjectDetailExpandableSection(
            title: 'Timeline',
            recordCount: project.tasks.length,
            accentColor: appTheme.warning,
            childBuilder: () => _ProjectTimelineTab(project: project),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          _ProjectDetailExpandableSection(
            title: 'Billing',
            recordCount: project.billings.length,
            accentColor: appTheme.success,
            childBuilder: () => _detailSectionPage(
              ProjectBillingManagementPage(
                key: ValueKey('project-detail-billing-$projectId'),
                embedded: true,
                constrainedProjectId: projectId,
                controllerScope: <String, Object?>{
                  'host': 'project_detail',
                  'project_id': projectId,
                  'section': 'billing',
                },
                useShellActions: false,
                constrainedTableView: true,
              ),
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          _ProjectDetailExpandableSection(
            title: 'Vendor Works',
            recordCount: project.vendorWorks.length,
            accentColor: theme.colorScheme.secondary,
            childBuilder: () => _detailSectionPage(
              ProjectVendorWorkManagementPage(
                key: ValueKey('project-detail-vendor-works-$projectId'),
                embedded: true,
                constrainedProjectId: projectId,
                controllerScope: <String, Object?>{
                  'host': 'project_detail',
                  'project_id': projectId,
                  'section': 'vendor_works',
                },
                useShellActions: false,
                constrainedTableView: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailSectionPage(Widget child) => child;
}

class _ProjectDetailExpandableSection extends StatelessWidget {
  const _ProjectDetailExpandableSection({
    required this.title,
    required this.recordCount,
    required this.accentColor,
    required this.childBuilder,
  });

  final String title;
  final int recordCount;
  final Color accentColor;
  final Widget Function() childBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppSectionCard(
      showShadow: false,
      child: ExpansionTile(
        initiallyExpanded: true,
        maintainState: true,
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppUiConstants.spacingSm),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppUiConstants.pillRadius),
              ),
              child: Text(
                '$recordCount',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        children: [
          const SizedBox(height: AppUiConstants.spacingMd),
          childBuilder(),
        ],
      ),
    );
  }
}

class _ProjectDetailHeader extends StatelessWidget {
  const _ProjectDetailHeader({
    required this.project,
    required this.customerName,
    required this.onBack,
  });

  final ProjectModel project;
  final String customerName;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    return AppSectionCard(
      showShadow: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            tooltip: 'Back to Projects Overview',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: AppUiConstants.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppUiConstants.spacingSm,
                  runSpacing: AppUiConstants.spacingSm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      project.projectName ?? 'Project',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    AppStatusBadge(
                      label: _projectStatusLabel(project.projectStatus),
                      color: _projectStatusColor(
                        context,
                        project.projectStatus,
                      ),
                    ),
                    if ((project.projectType ?? '').trim().isNotEmpty)
                      _DetailChip(label: project.projectType!.trim()),
                  ],
                ),
                const SizedBox(height: AppUiConstants.spacingXs),
                Text(
                  [
                    _dateRange(
                      project.expectedStartDate,
                      project.expectedEndDate,
                    ),
                    customerName,
                  ].where((value) => value.isNotEmpty).join(' • '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: appTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectTimelineTab extends StatelessWidget {
  const _ProjectTimelineTab({required this.project});

  final ProjectModel project;

  @override
  Widget build(BuildContext context) {
    final rows = project.tasks
        .where((task) {
          return DateTime.tryParse(task.plannedStartDate ?? '') != null &&
              DateTime.tryParse(task.plannedEndDate ?? '') != null;
        })
        .toList(growable: false);
    if (rows.isEmpty) {
      return const Center(
        child: Text('No scheduled tasks available for this timeline.'),
      );
    }
    final dates = rows
        .expand(
          (task) => <DateTime>[
            DateTime.parse(task.plannedStartDate!),
            DateTime.parse(task.plannedEndDate!),
          ],
        )
        .toList(growable: false);
    final start = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final end = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    return AppSectionCard(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 780,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Timeline',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              for (final task in rows)
                _TimelineRow(task: task, start: start, end: end),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.task,
    required this.start,
    required this.end,
  });

  final ProjectTaskModel task;
  final DateTime start;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    final taskStart = DateTime.parse(task.plannedStartDate!);
    final taskEnd = DateTime.parse(task.plannedEndDate!);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppUiConstants.spacingXs),
      child: Row(
        children: [
          SizedBox(
            width: 190,
            child: Text(
              task.taskName ?? task.taskCode ?? 'Task',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppUiConstants.spacingMd),
          CustomPaint(
            size: const Size(560, 32),
            painter: _TimelineBarPainter(
              timelineStart: start,
              timelineEnd: end,
              taskStart: taskStart,
              taskEnd: taskEnd,
              color: _projectStatusColor(context, task.taskStatus),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineBarPainter extends CustomPainter {
  const _TimelineBarPainter({
    required this.timelineStart,
    required this.timelineEnd,
    required this.taskStart,
    required this.taskEnd,
    required this.color,
  });

  final DateTime timelineStart;
  final DateTime timelineEnd;
  final DateTime taskStart;
  final DateTime taskEnd;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final totalDays = timelineEnd
        .difference(timelineStart)
        .inDays
        .clamp(1, 1 << 20)
        .toDouble();
    final startFraction =
        taskStart.difference(timelineStart).inDays / totalDays;
    final endFraction = taskEnd.difference(timelineStart).inDays / totalDays;
    final gridPaint = Paint()..color = color.withValues(alpha: 0.10);
    for (var index = 0; index <= 4; index++) {
      final x = size.width * index / 4;
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), gridPaint);
    }
    final left = (size.width * startFraction).clamp(0, size.width).toDouble();
    final right = (size.width * endFraction)
        .clamp(left + 4, size.width)
        .toDouble();
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, 8, right - left, 16),
        const Radius.circular(8),
      ),
      Paint()..color = color,
    );
    final todayFraction =
        DateUtils.dateOnly(DateTime.now()).difference(timelineStart).inDays /
        totalDays;
    if (todayFraction >= 0 && todayFraction <= 1) {
      final x = size.width * todayFraction;
      canvas.drawRect(
        Rect.fromLTWH(x, 0, 2, size.height),
        Paint()..color = Colors.redAccent,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineBarPainter oldDelegate) =>
      timelineStart != oldDelegate.timelineStart ||
      timelineEnd != oldDelegate.timelineEnd ||
      taskStart != oldDelegate.taskStart ||
      taskEnd != oldDelegate.taskEnd ||
      color != oldDelegate.color;
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: appTheme.tableBorder),
        borderRadius: BorderRadius.circular(AppUiConstants.pillRadius),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

String _projectStatusLabel(String? status) {
  switch (_status(status)) {
    case 'working':
      return 'In Progress';
    case 'on_hold':
      return 'On Hold';
    default:
      final value = _status(status);
      return value.isEmpty
          ? 'Draft'
          : '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

Color _projectStatusColor(BuildContext context, String? status) {
  final theme = Theme.of(context);
  final appTheme = theme.extension<AppThemeExtension>()!;
  switch (_status(status)) {
    case 'open':
      return theme.colorScheme.primary;
    case 'working':
      return appTheme.info;
    case 'on_hold':
      return appTheme.warning;
    case 'completed':
      return appTheme.success;
    case 'cancelled':
      return theme.colorScheme.error;
    default:
      return appTheme.mutedText;
  }
}

String _status(String? value) => (value ?? '').trim().toLowerCase();

String _dateRange(String? start, String? end) {
  final values = <String>[
    normalizeDateValue(start),
    normalizeDateValue(end),
  ].where((value) => value.isNotEmpty).toList(growable: false);
  return values.join(' → ');
}
