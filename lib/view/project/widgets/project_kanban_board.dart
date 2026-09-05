import '../../../components/app_progress_bar.dart';
import '../../../controller/project/project_milestone_management_controller.dart';
import '../../../controller/project/project_task_management_controller.dart';
import '../../../screen.dart';

const List<String> projectBoardStatusOrder = <String>[
  'draft',
  'open',
  'working',
  'on_hold',
  'completed',
  'cancelled',
];

List<String> projectBoardStatuses(Set<String> selectedStatuses) {
  if (selectedStatuses.isEmpty) return projectBoardStatusOrder;
  return projectBoardStatusOrder
      .where(selectedStatuses.contains)
      .toList(growable: false);
}

Map<String, List<ProjectModel>> groupProjectsByStatus(
  Iterable<ProjectModel> projects,
  Iterable<String> statuses,
) {
  final grouped = <String, List<ProjectModel>>{
    for (final status in statuses) status: <ProjectModel>[],
  };
  for (final project in projects) {
    final status = (project.projectStatus ?? 'draft').trim().toLowerCase();
    grouped[status]?.add(project);
  }
  return grouped;
}

int projectGridColumns(double availableWidth) {
  if (availableWidth >= 1280) return 4;
  if (availableWidth >= 900) return 3;
  if (availableWidth >= 600) return 2;
  return 1;
}

// --- Task board status definitions and helpers ---

const List<String> projectTaskStatusOrder = <String>[
  'open',
  'working',
  'in_review',
  'completed',
  'on_hold',
  'cancelled',
];

const List<String> normalProjectTaskBoardStatuses = <String>[
  'open',
  'working',
  'in_review',
  'completed',
];

List<String> projectTaskBoardStatuses(
  String filter, {
  required bool isSuperAdmin,
}) {
  final visibleStatuses = isSuperAdmin
      ? projectTaskStatusOrder
      : normalProjectTaskBoardStatuses;
  switch (filter.trim().toLowerCase()) {
    case 'pending':
      return visibleStatuses
          .where(<String>{'open', 'working', 'in_review'}.contains)
          .toList(growable: false);
    case 'all':
      return visibleStatuses;
    case 'open':
    case 'working':
    case 'in_review':
    case 'on_hold':
    case 'completed':
    case 'cancelled':
      final status = filter.trim().toLowerCase();
      return visibleStatuses.contains(status)
          ? <String>[status]
          : visibleStatuses;
    default:
      return visibleStatuses;
  }
}

Map<String, List<ProjectTaskRow>> groupProjectTaskRowsByStatus(
  Iterable<ProjectTaskRow> rows,
  Iterable<String> statuses,
) {
  final grouped = <String, List<ProjectTaskRow>>{
    for (final status in statuses) status: <ProjectTaskRow>[],
  };
  for (final row in rows) {
    final status = (row.task.taskStatus ?? 'open').trim().toLowerCase();
    grouped[status]?.add(row);
  }
  return grouped;
}

bool canDropProjectTask({
  required ProjectTaskRow row,
  required String destinationStatus,
  required Set<int> movingTaskIds,
  required bool isSuperAdmin,
}) {
  final taskId = row.task.id;
  final currentStatus = (row.task.taskStatus ?? 'open').trim().toLowerCase();
  return taskId != null &&
      projectTaskStatusOrder.contains(destinationStatus) &&
      currentStatus != destinationStatus &&
      (isSuperAdmin ||
          (currentStatus != 'completed' &&
              const <String>{
                'open',
                'working',
                'in_review',
              }.contains(destinationStatus))) &&
      !movingTaskIds.contains(taskId);
}

// --- Milestone board status definitions and helpers ---

const List<String> projectMilestoneStatusOrder = <String>[
  'open',
  'completed',
  'cancelled',
];

List<String> projectMilestoneBoardStatuses(String filter) {
  switch (filter.trim().toLowerCase()) {
    case 'pending':
      return const <String>['open'];
    case 'all':
      return projectMilestoneStatusOrder;
    case 'open':
    case 'completed':
    case 'cancelled':
      return <String>[filter.trim().toLowerCase()];
    default:
      return projectMilestoneStatusOrder;
  }
}

Map<String, List<ProjectMilestoneRow>> groupProjectMilestoneRowsByStatus(
  Iterable<ProjectMilestoneRow> rows,
  Iterable<String> statuses,
) {
  final grouped = <String, List<ProjectMilestoneRow>>{
    for (final status in statuses) status: <ProjectMilestoneRow>[],
  };
  for (final row in rows) {
    final status = (row.milestone.milestoneStatus ?? 'open')
        .trim()
        .toLowerCase();
    grouped[status]?.add(row);
  }
  return grouped;
}

bool canDropProjectMilestone({
  required ProjectMilestoneRow row,
  required String destinationStatus,
  required Set<int> movingMilestoneIds,
}) {
  final milestoneId = row.milestone.id;
  final currentStatus = (row.milestone.milestoneStatus ?? 'open')
      .trim()
      .toLowerCase();
  return milestoneId != null &&
      projectMilestoneStatusOrder.contains(destinationStatus) &&
      currentStatus != destinationStatus &&
      !movingMilestoneIds.contains(milestoneId);
}

// --- Unified Kanban Board Widget ---

class ProjectKanbanBoard<T extends Object> extends StatefulWidget {
  const ProjectKanbanBoard({
    super.key,
    required this.statuses,
    required this.groupedItems,
    required this.statusLabel,
    required this.statusAccent,
    required this.cardBuilder,
    required this.onAdd,
    required this.onMove,
    required this.canDrop,
    required this.canDrag,
    required this.canAdd,
    required this.isBusy,
    required this.isItemMoving,
    required this.hasItemId,
    required this.itemLabel,
    this.laneWidth,
    this.minLaneWidth = 200.0,
    this.fitToScreen = true,
    this.responsiveBreakpoint = 760.0,
  });

  factory ProjectKanbanBoard.task({
    Key? key,
    required List<ProjectTaskRow> rows,
    required String statusFilter,
    required List<String> Function(Iterable<int> ids) employeeNames,
    required ValueChanged<ProjectTaskRow> onOpen,
    required ValueChanged<String> onAdd,
    required ValueChanged<ProjectTaskRow> onDelete,
    required Future<void> Function(ProjectTaskRow row, String status) onMove,
    required bool canDelete,
    required bool isSuperAdmin,
    required bool isBusy,
    required Set<int> movingTaskIds,
    double? laneWidth,
    double minLaneWidth = 200.0,
    bool fitToScreen = true,
  }) {
    final statuses = projectTaskBoardStatuses(
      statusFilter,
      isSuperAdmin: isSuperAdmin,
    );
    final grouped = groupProjectTaskRowsByStatus(rows, statuses);

    return ProjectKanbanBoard<ProjectTaskRow>(
          key: key,
          statuses: statuses,
          groupedItems: grouped,
          itemLabel: 'Task',
          statusLabel: _taskStatusLabel,
          statusAccent: _taskStatusAccent,
          isBusy: isBusy,
          laneWidth: laneWidth,
          minLaneWidth: minLaneWidth,
          fitToScreen: fitToScreen,
          hasItemId: (row) => row.task.id != null,
          isItemMoving: (row) =>
              row.task.id != null && movingTaskIds.contains(row.task.id),
          canDrop: (row, destinationStatus) => canDropProjectTask(
            row: row,
            destinationStatus: destinationStatus,
            movingTaskIds: movingTaskIds,
            isSuperAdmin: isSuperAdmin,
          ),
          canDrag: (row) =>
              isSuperAdmin || (row.task.taskStatus ?? 'open') != 'completed',
          canAdd: isSuperAdmin,
          onAdd: onAdd,
          onMove: onMove,
          cardBuilder: (context, row, accent, {required bool isFeedback}) {
            final taskId = row.task.id;
            final isMoving = taskId != null && movingTaskIds.contains(taskId);
            return _ProjectTaskCard(
              row: row,
              accent: accent,
              employeeNames: employeeNames,
              onOpen: isFeedback ? () {} : () => onOpen(row),
              onDelete:
                  isFeedback ||
                      !isSuperAdmin ||
                      !canDelete ||
                      isBusy ||
                      isMoving
                  ? null
                  : () => onDelete(row),
              isMoving: !isFeedback && isMoving,
            );
          },
        )
        as ProjectKanbanBoard<T>;
  }

  factory ProjectKanbanBoard.project({
    Key? key,
    required List<ProjectModel> projects,
    required Set<String> selectedStatuses,
    required String Function(int? id) customerName,
    required ValueChanged<ProjectModel> onOpen,
    double? laneWidth,
    double minLaneWidth = 200.0,
    bool fitToScreen = true,
  }) {
    final statuses = projectBoardStatuses(selectedStatuses);
    final grouped = groupProjectsByStatus(projects, statuses);

    return ProjectKanbanBoard<ProjectModel>(
          key: key,
          statuses: statuses,
          groupedItems: grouped,
          itemLabel: 'Project',
          statusLabel: _projectStatusLabel,
          statusAccent: _projectStatusAccent,
          isBusy: false,
          laneWidth: laneWidth,
          minLaneWidth: minLaneWidth,
          fitToScreen: fitToScreen,
          hasItemId: (project) => project.id != null,
          isItemMoving: (_) => false,
          canDrop: (project, destinationStatus) => false,
          canDrag: (_) => false,
          canAdd: false,
          onAdd: (_) {},
          onMove: (project, destinationStatus) async {},
          cardBuilder: (context, project, accent, {required bool isFeedback}) =>
              _ProjectCard(
                project: project,
                accent: accent,
                customerName: customerName,
                employeeNames: const <String>[],
                onOpen: isFeedback ? () {} : () => onOpen(project),
              ),
        )
        as ProjectKanbanBoard<T>;
  }

  factory ProjectKanbanBoard.milestone({
    Key? key,
    required List<ProjectMilestoneRow> rows,
    required String statusFilter,
    required ValueChanged<ProjectMilestoneRow> onOpen,
    required ValueChanged<String> onAdd,
    required ValueChanged<ProjectMilestoneRow> onDelete,
    required Future<void> Function(ProjectMilestoneRow row, String status)
    onMove,
    required bool canDelete,
    required bool isBusy,
    required Set<int> movingMilestoneIds,
    double? laneWidth,
    double minLaneWidth = 200.0,
    bool fitToScreen = true,
  }) {
    final statuses = projectMilestoneBoardStatuses(statusFilter);
    final grouped = groupProjectMilestoneRowsByStatus(rows, statuses);

    return ProjectKanbanBoard<ProjectMilestoneRow>(
          key: key,
          statuses: statuses,
          groupedItems: grouped,
          itemLabel: 'Milestone',
          statusLabel: _milestoneStatusLabel,
          statusAccent: _milestoneStatusAccent,
          isBusy: isBusy,
          laneWidth: laneWidth,
          minLaneWidth: minLaneWidth,
          fitToScreen: fitToScreen,
          hasItemId: (row) => row.milestone.id != null,
          isItemMoving: (row) =>
              row.milestone.id != null &&
              movingMilestoneIds.contains(row.milestone.id),
          canDrop: (row, destinationStatus) => canDropProjectMilestone(
            row: row,
            destinationStatus: destinationStatus,
            movingMilestoneIds: movingMilestoneIds,
          ),
          canDrag: (_) => true,
          canAdd: true,
          onAdd: onAdd,
          onMove: onMove,
          cardBuilder: (context, row, accent, {required bool isFeedback}) {
            final milestoneId = row.milestone.id;
            final isMoving =
                milestoneId != null && movingMilestoneIds.contains(milestoneId);
            return _ProjectMilestoneCard(
              row: row,
              accent: accent,
              onOpen: isFeedback ? () {} : () => onOpen(row),
              onDelete: isFeedback || !canDelete || isBusy || isMoving
                  ? null
                  : () => onDelete(row),
              isMoving: !isFeedback && isMoving,
            );
          },
        )
        as ProjectKanbanBoard<T>;
  }

  final List<String> statuses;
  final Map<String, List<T>> groupedItems;
  final String Function(String status) statusLabel;
  final Color Function(BuildContext context, String status) statusAccent;
  final Widget Function(
    BuildContext context,
    T item,
    Color accent, {
    required bool isFeedback,
  })
  cardBuilder;
  final ValueChanged<String> onAdd;
  final Future<void> Function(T item, String destinationStatus) onMove;
  final bool Function(T item, String destinationStatus) canDrop;
  final bool Function(T item) canDrag;
  final bool canAdd;
  final bool isBusy;
  final bool Function(T item) isItemMoving;
  final bool Function(T item) hasItemId;
  final double? laneWidth;
  final double minLaneWidth;
  final bool fitToScreen;
  final String itemLabel;
  final double responsiveBreakpoint;

  @override
  State<ProjectKanbanBoard<T>> createState() => _ProjectKanbanBoardState<T>();
}

class _ProjectKanbanBoardState<T extends Object>
    extends State<ProjectKanbanBoard<T>> {
  late final ScrollController _scrollController;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll(double dx) {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (
      timer,
    ) {
      if (!_scrollController.hasClients) return;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (dx < 0 && currentScroll > 0) {
        _scrollController.jumpTo((currentScroll + dx).clamp(0.0, maxScroll));
      } else if (dx > 0 && currentScroll < maxScroll) {
        _scrollController.jumpTo((currentScroll + dx).clamp(0.0, maxScroll));
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final lanes = widget.statuses
        .map(
          (status) => _ProjectKanbanLane<T>(
            status: status,
            items: widget.groupedItems[status] ?? const [],
            label: widget.statusLabel(status),
            accent: widget.statusAccent(context, status),
            cardBuilder: widget.cardBuilder,
            onAdd: () => widget.onAdd(status),
            onMove: (item) {
              _stopAutoScroll();
              return widget.onMove(item, status);
            },
            canDrop: (item) => widget.canDrop(item, status),
            canDrag: widget.canDrag,
            canAdd: widget.canAdd,
            isBusy: widget.isBusy,
            isItemMoving: widget.isItemMoving,
            hasItemId: widget.hasItemId,
            itemLabel: widget.itemLabel,
          ),
        )
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < widget.responsiveBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < lanes.length; index++) ...[
                lanes[index],
                if (index != lanes.length - 1)
                  const SizedBox(height: AppUiConstants.spacingMd),
              ],
            ],
          );
        }

        final resolvedLaneWidth = widget.laneWidth ?? 340.0;
        const autoScrollZoneWidth = 80.0;

        // Use a Listener to detect horizontal pointer position during drag and
        // trigger auto-scroll when the pointer is within the edge zones.  This
        // avoids using Positioned.fill inside a Stack which crashes when the
        // parent provides unbounded height (no size available for hit-testing).
        return Listener(
          onPointerMove: (event) {
            final x = event.localPosition.dx;
            final width = constraints.maxWidth;
            if (x < autoScrollZoneWidth) {
              _startAutoScroll(-10.0);
            } else if (x > width - autoScrollZoneWidth) {
              _startAutoScroll(10.0);
            } else {
              _stopAutoScroll();
            }
          },
          onPointerUp: (_) => _stopAutoScroll(),
          onPointerCancel: (_) => _stopAutoScroll(),
          child: Scrollbar(
            controller: _scrollController,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            thickness: 6,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: AppUiConstants.spacingLg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < lanes.length; index++) ...[
                    SizedBox(width: resolvedLaneWidth, child: lanes[index]),
                    if (index != lanes.length - 1)
                      const SizedBox(width: AppUiConstants.spacingMd),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- Lane presentation ---

class _ProjectKanbanLane<T extends Object> extends StatelessWidget {
  const _ProjectKanbanLane({
    required this.status,
    required this.items,
    required this.label,
    required this.accent,
    required this.cardBuilder,
    required this.onAdd,
    required this.onMove,
    required this.canDrop,
    required this.canDrag,
    required this.canAdd,
    required this.isBusy,
    required this.isItemMoving,
    required this.hasItemId,
    required this.itemLabel,
  });

  final String status;
  final List<T> items;
  final String label;
  final Color accent;
  final Widget Function(
    BuildContext context,
    T item,
    Color accent, {
    required bool isFeedback,
  })
  cardBuilder;
  final VoidCallback onAdd;
  final Future<void> Function(T item) onMove;
  final bool Function(T item) canDrop;
  final bool Function(T item) canDrag;
  final bool canAdd;
  final bool isBusy;
  final bool Function(T item) isItemMoving;
  final bool Function(T item) hasItemId;
  final String itemLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;

    return DragTarget<T>(
      onWillAcceptWithDetails: (details) => canDrop(details.data),
      onAcceptWithDetails: (details) {
        unawaited(onMove(details.data));
      },
      builder: (context, candidateData, rejectedData) {
        final isTargeted = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: accent.withValues(
              alpha: isTargeted
                  ? 0.20
                  : theme.brightness == Brightness.dark
                  ? 0.14
                  : 0.10,
            ),
            borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
            border: Border.all(
              color: accent.withValues(alpha: isTargeted ? 0.85 : 0.16),
              width: isTargeted ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProjectKanbanLaneHeader(
                label: label,
                count: items.length,
                accent: accent,
                // New items always start in Open. Keep creation in the Open lane
                // after a card is dragged to another status.
                onAdd: isBusy || !canAdd || status != 'open' ? null : onAdd,
                itemLabel: itemLabel,
              ),
              const SizedBox(height: AppUiConstants.spacingLg),
              if (items.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppUiConstants.spacingMd,
                    vertical: AppUiConstants.spacingXl,
                  ),
                  decoration: BoxDecoration(
                    color: appTheme.cardBackground.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(
                      AppUiConstants.cardRadius,
                    ),
                  ),
                  child: Text(
                    'No ${label.toLowerCase()} ${itemLabel.toLowerCase()}s',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: appTheme.mutedText,
                    ),
                  ),
                )
              else
                for (final item in items) ...[
                  _buildDraggableCard(context, item),
                  const SizedBox(height: AppUiConstants.spacingSm),
                ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraggableCard(BuildContext context, T item) {
    final hasId = hasItemId(item);
    final isMoving = isItemMoving(item);
    final card = cardBuilder(context, item, accent, isFeedback: false);

    if (!hasId || isMoving || isBusy || !canDrag(item)) {
      return card;
    }

    return Draggable<T>(
      data: item,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: IgnorePointer(
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 320,
            child: cardBuilder(context, item, accent, isFeedback: true),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.28, child: card),
      child: card,
    );
  }
}

class _ProjectKanbanLaneHeader extends StatelessWidget {
  const _ProjectKanbanLaneHeader({
    required this.label,
    required this.count,
    required this.accent,
    required this.onAdd,
    required this.itemLabel,
    this.showControls = true,
  });

  final String label;
  final int count;
  final Color accent;
  final VoidCallback? onAdd;
  final String itemLabel;
  final bool showControls;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 5,
          height: 40,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(AppUiConstants.pillRadius),
          ),
        ),
        const SizedBox(width: AppUiConstants.spacingSm),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (showControls) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(AppUiConstants.pillRadius),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onAdd,
            tooltip: 'Add $label $itemLabel',
            icon: const Icon(Icons.add_circle_outline, size: 20),
            color: accent,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.accent,
    required this.customerName,
    required this.employeeNames,
    required this.onOpen,
    this.onEdit,
    this.onDelete,
  });

  final ProjectModel project;
  final Color accent;
  final String Function(int? id) customerName;
  final List<String> employeeNames;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    final progress = (project.percentCompletion ?? 0).clamp(0, 100).toDouble();
    final dueDate = normalizeDateValue(
      project.expectedEndDate ?? project.expectedStartDate,
    );
    final customer = customerName(project.customerPartyId);

    return Material(
      color: appTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
        side: BorderSide(color: appTheme.tableBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.circle, size: 9, color: accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      dueDate.isEmpty ? 'No target date' : dueDate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: appTheme.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if ((project.billingMethod ?? '').trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: AppUiConstants.spacingSm,
                      ),
                      child: Text(
                        _billingMethodLabel(project.billingMethod!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: appTheme.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      tooltip: 'Project actions',
                      padding: EdgeInsets.zero,
                      onSelected: (value) {
                        if (value == 'edit') onEdit?.call();
                        if (value == 'delete') onDelete?.call();
                      },
                      itemBuilder: (_) => [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                      ],
                    )
                  else
                    const SizedBox(width: 20),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingSm),
              Text(
                project.projectName ?? 'Project',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if ((project.notes ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  project.notes!.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: appTheme.mutedText,
                  ),
                ),
              ],
              const SizedBox(height: AppUiConstants.spacingLg),
              AppProgressBar(
                label: 'Progress',
                progress: progress / 100,
                color: accent,
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              Divider(color: appTheme.tableBorder),
              const SizedBox(height: AppUiConstants.spacingXs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        project.projectCode ?? '',
                        customer,
                      ].where((part) => part.trim().isNotEmpty).join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: appTheme.mutedText,
                      ),
                    ),
                  ),
                  if (employeeNames.isNotEmpty)
                    _AssigneeStack(names: employeeNames),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProjectGrid extends StatelessWidget {
  const ProjectGrid({
    super.key,
    required this.projects,
    required this.customerName,
    required this.employeeNames,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ProjectModel> projects;
  final String Function(int? id) customerName;
  final List<String> Function(ProjectModel project) employeeNames;
  final ValueChanged<ProjectModel> onOpen;
  final ValueChanged<ProjectModel> onEdit;
  final ValueChanged<ProjectModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppUiConstants.spacingMd;
        final columns = projectGridColumns(constraints.maxWidth);
        final cardWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: projects
              .map((project) {
                final accent = _projectStatusAccent(
                  context,
                  (project.projectStatus ?? 'draft').trim().toLowerCase(),
                );
                return SizedBox(
                  width: cardWidth,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 12, 10, 16),
                    decoration: BoxDecoration(
                      color: accent.withValues(
                        alpha: Theme.of(context).brightness == Brightness.dark
                            ? 0.14
                            : 0.10,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppUiConstants.cardRadius,
                      ),
                      border: Border.all(color: accent.withValues(alpha: 0.16)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProjectKanbanLaneHeader(
                          label: _projectStatusLabel(
                            (project.projectStatus ?? 'draft')
                                .trim()
                                .toLowerCase(),
                          ),
                          count: 1,
                          accent: accent,
                          onAdd: null,
                          itemLabel: 'Project',
                          showControls: false,
                        ),
                        const SizedBox(height: AppUiConstants.spacingLg),
                        _ProjectCard(
                          project: project,
                          accent: accent,
                          customerName: customerName,
                          employeeNames: employeeNames(project),
                          onOpen: () => onOpen(project),
                          onEdit: () => onEdit(project),
                          onDelete: () => onDelete(project),
                        ),
                      ],
                    ),
                  ),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }
}

// --- Task card presentation ---

class _ProjectTaskCard extends StatelessWidget {
  const _ProjectTaskCard({
    required this.row,
    required this.accent,
    required this.employeeNames,
    required this.onOpen,
    required this.onDelete,
    required this.isMoving,
  });

  final ProjectTaskRow row;
  final Color accent;
  final List<String> Function(Iterable<int> ids) employeeNames;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;
  final bool isMoving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    final task = row.task;
    final progress = (task.progressPercent ?? 0).clamp(0, 100).toDouble();
    final assignedIds =
        task.assignedEmployeeIds.isEmpty && task.assignedEmployeeId != null
        ? <int>[task.assignedEmployeeId!]
        : task.assignedEmployeeIds;
    final names = employeeNames(assignedIds);
    final date = normalizeDateValue(
      task.plannedEndDate ?? task.plannedStartDate,
    );

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: isMoving ? 0.62 : 1,
      child: Material(
        color: appTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
          side: BorderSide(color: appTheme.tableBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isMoving ? null : onOpen,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, size: 9, color: accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        date.isEmpty ? 'No due date' : date,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: appTheme.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (task.isBillable == true)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          'Billable',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: appTheme.mutedText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (isMoving)
                      const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (onDelete != null)
                      PopupMenuButton<String>(
                        tooltip: 'Task actions',
                        padding: EdgeInsets.zero,
                        onSelected: (value) {
                          if (value == 'edit') onOpen();
                          if (value == 'delete') onDelete!();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    AppStatusBadge(
                      label: taskPriorityLabel(task.priority),
                      color: taskPriorityColor(context, task.priority),
                    ),
                  ],
                ),
                const SizedBox(height: AppUiConstants.spacingSm),
                Text(
                  task.taskName ?? 'Task',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((task.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description!.trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: appTheme.mutedText,
                    ),
                  ),
                ],
                const SizedBox(height: AppUiConstants.spacingLg),
                AppProgressBar(
                  label: 'Progress',
                  progress: progress / 100,
                  color: accent,
                ),
                const SizedBox(height: AppUiConstants.spacingMd),
                Divider(color: appTheme.tableBorder),
                const SizedBox(height: AppUiConstants.spacingXs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        [
                          task.taskCode ?? '',
                          row.project.projectName ?? '',
                        ].where((value) => value.trim().isNotEmpty).join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: appTheme.mutedText,
                        ),
                      ),
                    ),
                    if (names.isNotEmpty) _AssigneeStack(names: names),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssigneeStack extends StatelessWidget {
  const _AssigneeStack({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final visibleNames = names.take(3).toList(growable: false);
    final remaining = names.length - visibleNames.length;
    return Tooltip(
      message: names.join(', '),
      child: SizedBox(
        width: ((visibleNames.length * 22) + (remaining > 0 ? 24 : 8))
            .toDouble(),
        height: 30,
        child: Stack(
          children: [
            for (var index = 0; index < visibleNames.length; index++)
              Positioned(
                left: index * 22,
                child: _AssigneeAvatar(name: visibleNames[index]),
              ),
            if (remaining > 0)
              Positioned(
                left: visibleNames.length * 22,
                child: _AssigneeAvatar(name: '+$remaining'),
              ),
          ],
        ),
      ),
    );
  }
}

class _AssigneeAvatar extends StatelessWidget {
  const _AssigneeAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name.startsWith('+')
        ? name
        : name
              .trim()
              .split(RegExp(r'\s+'))
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();
    return CircleAvatar(
      radius: 15,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      child: Text(
        initials,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

// --- Milestone card presentation ---

class _ProjectMilestoneCard extends StatelessWidget {
  const _ProjectMilestoneCard({
    required this.row,
    required this.accent,
    required this.onOpen,
    required this.onDelete,
    required this.isMoving,
  });

  final ProjectMilestoneRow row;
  final Color accent;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;
  final bool isMoving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    final milestone = row.milestone;
    final targetDate = normalizeDateValue(milestone.targetDate);
    final completionDate = normalizeDateValue(milestone.completionDate);
    final amount = milestone.milestoneAmount;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: isMoving ? 0.62 : 1,
      child: Material(
        color: appTheme.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
          side: BorderSide(color: appTheme.tableBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isMoving ? null : onOpen,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, size: 9, color: accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        targetDate.isEmpty
                            ? 'No target date'
                            : 'Target $targetDate',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: appTheme.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (amount != null && amount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppUiConstants.pillRadius,
                          ),
                        ),
                        child: Text(
                          '₹${_formatAmount(amount)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (isMoving)
                      const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (onDelete != null)
                      PopupMenuButton<String>(
                        tooltip: 'Milestone actions',
                        padding: EdgeInsets.zero,
                        onSelected: (value) {
                          if (value == 'edit') onOpen();
                          if (value == 'delete') onDelete!();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: AppUiConstants.spacingSm),
                Text(
                  milestone.milestoneName ?? 'Milestone',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if ((milestone.remarks ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    milestone.remarks!.trim(),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: appTheme.mutedText,
                    ),
                  ),
                ],
                if (completionDate.isNotEmpty) ...[
                  const SizedBox(height: AppUiConstants.spacingSm),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 14,
                        color: appTheme.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Completed: $completionDate',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: appTheme.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppUiConstants.spacingMd),
                Divider(color: appTheme.tableBorder),
                const SizedBox(height: AppUiConstants.spacingXs),
                Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 14,
                      color: appTheme.mutedText,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        row.project.projectName ?? 'Project',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: appTheme.mutedText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatAmount(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
  }
}

// --- Status label and accent mappings (strictly from theme) ---

String _projectStatusLabel(String status) {
  switch (status) {
    case 'draft':
      return 'Draft';
    case 'open':
      return 'Open';
    case 'working':
      return 'In Progress';
    case 'on_hold':
      return 'In Review';
    case 'completed':
      return 'Completed';
    case 'cancelled':
      return 'Cancelled';
    default:
      return status;
  }
}

String _billingMethodLabel(String value) {
  switch (value.trim().toLowerCase()) {
    case 'time_and_material':
      return 'Time & Material';
    case 'cost_plus':
      return 'Cost Plus';
    case 'milestone':
      return 'Milestone';
    case 'fixed':
      return 'Fixed';
    default:
      return value.trim();
  }
}

Color _projectStatusAccent(BuildContext context, String status) {
  final theme = Theme.of(context);
  final appTheme = theme.extension<AppThemeExtension>()!;
  switch (status) {
    case 'draft':
      return appTheme.mutedText;
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

String _taskStatusLabel(String status) {
  switch (status) {
    case 'open':
      return 'Open';
    case 'working':
      return 'In Progress';
    case 'in_review':
      return 'In Review';
    case 'on_hold':
      return 'On Hold';
    case 'completed':
      return 'Completed';
    case 'cancelled':
      return 'Cancelled';
    default:
      return status;
  }
}

Color _taskStatusAccent(BuildContext context, String status) {
  final theme = Theme.of(context);
  final appTheme = theme.extension<AppThemeExtension>()!;
  switch (status) {
    case 'open':
      return theme.colorScheme.primary;
    case 'working':
      return appTheme.info;
    case 'in_review':
      return appTheme.warning;
    case 'on_hold':
      return appTheme.mutedText;
    case 'completed':
      return appTheme.success;
    case 'cancelled':
      return theme.colorScheme.error;
    default:
      return appTheme.mutedText;
  }
}

String taskPriorityLabel(String? priority) {
  switch ((priority ?? 'medium').trim().toLowerCase()) {
    case 'low':
      return 'Low';
    case 'high':
      return 'High';
    case 'critical':
      return 'Critical';
    default:
      return 'Medium';
  }
}

Color taskPriorityColor(BuildContext context, String? priority) {
  final theme = Theme.of(context);
  final appTheme = theme.extension<AppThemeExtension>()!;
  switch ((priority ?? 'medium').trim().toLowerCase()) {
    case 'low':
      return appTheme.success;
    case 'high':
      return theme.colorScheme.error;
    case 'critical':
      return theme.colorScheme.onErrorContainer;
    default:
      return appTheme.warning;
  }
}

String _milestoneStatusLabel(String status) {
  switch (status) {
    case 'open':
      return 'Open';
    case 'completed':
      return 'Completed';
    case 'cancelled':
      return 'Cancelled';
    default:
      return status;
  }
}

Color _milestoneStatusAccent(BuildContext context, String status) {
  final theme = Theme.of(context);
  final appTheme = theme.extension<AppThemeExtension>()!;
  switch (status) {
    case 'open':
      return theme.colorScheme.primary;
    case 'completed':
      return appTheme.success;
    case 'cancelled':
      return theme.colorScheme.error;
    default:
      return appTheme.mutedText;
  }
}
