import '../../../controller/project/project_task_management_controller.dart';
import '../../../screen.dart';

const List<String> projectTaskStatusOrder = <String>[
  'open',
  'working',
  'on_hold',
  'completed',
  'cancelled',
];

List<String> projectTaskBoardStatuses(String filter) {
  switch (filter.trim().toLowerCase()) {
    case 'pending':
      return const <String>['open', 'working', 'on_hold'];
    case 'all':
      return projectTaskStatusOrder;
    case 'open':
    case 'working':
    case 'on_hold':
    case 'completed':
    case 'cancelled':
      return <String>[filter.trim().toLowerCase()];
    default:
      return projectTaskStatusOrder;
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
}) {
  final taskId = row.task.id;
  final currentStatus = (row.task.taskStatus ?? 'open').trim().toLowerCase();
  return taskId != null &&
      projectTaskStatusOrder.contains(destinationStatus) &&
      currentStatus != destinationStatus &&
      !movingTaskIds.contains(taskId);
}

class ProjectTaskKanbanBoard extends StatelessWidget {
  const ProjectTaskKanbanBoard({
    super.key,
    required this.rows,
    required this.statusFilter,
    required this.employeeNames,
    required this.onOpen,
    required this.onAdd,
    required this.onDelete,
    required this.onMove,
    required this.canDelete,
    required this.isBusy,
    required this.movingTaskIds,
  });

  final List<ProjectTaskRow> rows;
  final String statusFilter;
  final List<String> Function(Iterable<int> ids) employeeNames;
  final ValueChanged<ProjectTaskRow> onOpen;
  final ValueChanged<String> onAdd;
  final ValueChanged<ProjectTaskRow> onDelete;
  final Future<void> Function(ProjectTaskRow row, String status) onMove;
  final bool canDelete;
  final bool isBusy;
  final Set<int> movingTaskIds;

  @override
  Widget build(BuildContext context) {
    final statuses = projectTaskBoardStatuses(statusFilter);
    final grouped = groupProjectTaskRowsByStatus(rows, statuses);
    final lanes = statuses
        .map(
          (status) => _ProjectTaskLane(
            status: status,
            rows: grouped[status]!,
            employeeNames: employeeNames,
            onOpen: onOpen,
            onAdd: () => onAdd(status),
            onDelete: onDelete,
            onMove: onMove,
            canDelete: canDelete,
            isBusy: isBusy,
            movingTaskIds: movingTaskIds,
          ),
        )
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
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

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < lanes.length; index++) ...[
                SizedBox(width: 340, child: lanes[index]),
                if (index != lanes.length - 1)
                  const SizedBox(width: AppUiConstants.spacingMd),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ProjectTaskLane extends StatelessWidget {
  const _ProjectTaskLane({
    required this.status,
    required this.rows,
    required this.employeeNames,
    required this.onOpen,
    required this.onAdd,
    required this.onDelete,
    required this.onMove,
    required this.canDelete,
    required this.isBusy,
    required this.movingTaskIds,
  });

  final String status;
  final List<ProjectTaskRow> rows;
  final List<String> Function(Iterable<int> ids) employeeNames;
  final ValueChanged<ProjectTaskRow> onOpen;
  final VoidCallback onAdd;
  final ValueChanged<ProjectTaskRow> onDelete;
  final Future<void> Function(ProjectTaskRow row, String status) onMove;
  final bool canDelete;
  final bool isBusy;
  final Set<int> movingTaskIds;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    final accent = _statusAccent(context, status);

    return DragTarget<ProjectTaskRow>(
      onWillAcceptWithDetails: (details) => canDropProjectTask(
        row: details.data,
        destinationStatus: status,
        movingTaskIds: movingTaskIds,
      ),
      onAcceptWithDetails: (details) {
        unawaited(onMove(details.data, status));
      },
      builder: (context, candidateData, rejectedData) {
        final isTargeted = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(AppUiConstants.spacingMd),
          decoration: BoxDecoration(
            color: accent.withValues(
              alpha: isTargeted
                  ? 0.20
                  : Theme.of(context).brightness == Brightness.dark
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
              _ProjectTaskLaneHeader(
                label: _statusLabel(status),
                count: rows.length,
                accent: accent,
                onAdd: isBusy ? null : onAdd,
              ),
              const SizedBox(height: AppUiConstants.spacingLg),
              if (rows.isEmpty)
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
                    'No ${_statusLabel(status).toLowerCase()} tasks',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: appTheme.mutedText),
                  ),
                )
              else
                for (final row in rows) ...[
                  _buildDraggableCard(context, row, accent),
                  const SizedBox(height: AppUiConstants.spacingSm),
                ],
              OutlinedButton.icon(
                onPressed: isBusy ? null : onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Task'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accent,
                  side: BorderSide(color: accent.withValues(alpha: 0.60)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDraggableCard(
    BuildContext context,
    ProjectTaskRow row,
    Color accent,
  ) {
    final taskId = row.task.id;
    final isMoving = taskId != null && movingTaskIds.contains(taskId);
    final card = _ProjectTaskCard(
      row: row,
      accent: accent,
      employeeNames: employeeNames,
      onOpen: () => onOpen(row),
      onDelete: canDelete && !isBusy && !isMoving ? () => onDelete(row) : null,
      showDragHandle: taskId != null,
      isMoving: isMoving,
    );
    if (taskId == null || isMoving || isBusy) {
      return card;
    }

    return Draggable<ProjectTaskRow>(
      data: row,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: IgnorePointer(
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 320,
            child: _ProjectTaskCard(
              row: row,
              accent: accent,
              employeeNames: employeeNames,
              onOpen: () {},
              onDelete: null,
              showDragHandle: true,
              isMoving: false,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.28, child: card),
      child: card,
    );
  }
}

class _ProjectTaskLaneHeader extends StatelessWidget {
  const _ProjectTaskLaneHeader({
    required this.label,
    required this.count,
    required this.accent,
    required this.onAdd,
  });

  final String label;
  final int count;
  final Color accent;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(AppUiConstants.pillRadius),
          ),
          child: Text(
            '$count',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          onPressed: onAdd,
          tooltip: 'Add $label task',
          icon: const Icon(Icons.add_circle_outline, size: 20),
          color: accent,
        ),
      ],
    );
  }
}

class _ProjectTaskCard extends StatelessWidget {
  const _ProjectTaskCard({
    required this.row,
    required this.accent,
    required this.employeeNames,
    required this.onOpen,
    required this.onDelete,
    required this.showDragHandle,
    required this.isMoving,
  });

  final ProjectTaskRow row;
  final Color accent;
  final List<String> Function(Iterable<int> ids) employeeNames;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;
  final bool showDragHandle;
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
            padding: const EdgeInsets.all(AppUiConstants.spacingLg),
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
                          'Billable',
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
                    if (showDragHandle && !isMoving)
                      Tooltip(
                        message: 'Drag to change status',
                        child: Icon(
                          Icons.drag_indicator,
                          color: appTheme.mutedText,
                        ),
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
                Row(
                  children: [
                    Text('Progress', style: theme.textTheme.labelMedium),
                    const Spacer(),
                    Text(
                      '${progress.toStringAsFixed(progress == progress.roundToDouble() ? 0 : 1)}%',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: appTheme.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    AppUiConstants.pillRadius,
                  ),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: progress / 100,
                    color: accent,
                    backgroundColor: accent.withValues(alpha: 0.10),
                  ),
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

String _statusLabel(String status) {
  switch (status) {
    case 'open':
      return 'New';
    case 'working':
      return 'In Progress';
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

Color _statusAccent(BuildContext context, String status) {
  final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
  switch (status) {
    case 'open':
      return Theme.of(context).colorScheme.primary;
    case 'working':
      return appTheme.info;
    case 'on_hold':
      return appTheme.warning;
    case 'completed':
      return appTheme.success;
    case 'cancelled':
      return Theme.of(context).colorScheme.error;
    default:
      return appTheme.mutedText;
  }
}
