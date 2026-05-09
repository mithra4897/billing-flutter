import 'dart:math' as math;

import '../../screen.dart';
import 'crm_dashboard_support.dart';

void _openCrmShellRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

class CrmDashboardPage extends StatelessWidget {
  const CrmDashboardPage({
    super.key,
    this.embedded = false,
    this.crmService,
    this.now,
  });

  final bool embedded;
  final CrmService? crmService;
  final DateTime Function()? now;

  @override
  Widget build(BuildContext context) {
    final content = _CrmDashboardContent(
      crmService: crmService ?? CrmService(),
      now: now ?? DateTime.now,
    );
    if (embedded) {
      return content;
    }

    return FutureBuilder<PublicBrandingModel?>(
      future: SessionStorage.getBranding(),
      builder: (context, snapshot) {
        final branding =
            snapshot.data ??
            const PublicBrandingModel(companyName: 'Billing ERP');

        return AdaptiveShell(
          title: 'CRM Dashboard',
          branding: branding,
          child: content,
        );
      },
    );
  }
}

class _CrmDashboardContent extends StatefulWidget {
  const _CrmDashboardContent({required this.crmService, required this.now});

  final CrmService crmService;
  final DateTime Function() now;

  @override
  State<_CrmDashboardContent> createState() => _CrmDashboardContentState();
}

class _CrmDashboardContentState extends State<_CrmDashboardContent> {
  late Future<_CrmDashboardSnapshot> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _loadSnapshot();
  }

  Future<_CrmDashboardSnapshot> _loadSnapshot() async {
    final leadResponse = await widget.crmService.leads(
      filters: const <String, dynamic>{'per_page': 1},
    );
    final enquiryResponse = await widget.crmService.enquiries(
      filters: const <String, dynamic>{'per_page': 1},
    );
    final pendingFollowupResponse = await widget.crmService.pendingFollowups();

    final pendingItems = sortCrmPendingFollowups(
      (pendingFollowupResponse.data ?? const <CrmFollowupModel>[]).map(
        (item) => CrmPendingFollowupItem.fromJson(item.toJson()),
      ),
      today: widget.now(),
    );

    return _CrmDashboardSnapshot(
      leadCount: leadResponse.meta?.total ?? leadResponse.data?.length ?? 0,
      enquiryCount:
          enquiryResponse.meta?.total ?? enquiryResponse.data?.length ?? 0,
      pendingFollowups: pendingItems,
    );
  }

  void _reload() {
    setState(() {
      _snapshotFuture = _loadSnapshot();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CrmDashboardSnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        final body = switch (snapshot.connectionState) {
          ConnectionState.waiting || ConnectionState.active =>
            const AppLoadingView(message: 'Loading CRM dashboard...'),
          _ when snapshot.hasError => AppErrorStateView(
            title: 'Unable to load CRM dashboard',
            message: snapshot.error.toString(),
            onRetry: _reload,
          ),
          _ => _CrmDashboardBody(
            snapshot: snapshot.data ?? const _CrmDashboardSnapshot.empty(),
            now: widget.now(),
          ),
        };

        return Padding(
          padding: const EdgeInsets.all(AppUiConstants.pagePadding),
          child: body,
        );
      },
    );
  }
}

class _CrmDashboardBody extends StatelessWidget {
  const _CrmDashboardBody({required this.snapshot, required this.now});

  final _CrmDashboardSnapshot snapshot;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.of(context).size.width >= 1060;
    final tasks = snapshot.pendingFollowups.take(4).toList(growable: false);
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = snapshot.summaryCards(now, appTheme);
              final compact = constraints.maxWidth < 720;
              final medium = constraints.maxWidth < 1100;

              if (compact) {
                return Column(
                  children: cards
                      .map(
                        (card) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppUiConstants.spacingMd,
                          ),
                          child: _CrmSummaryCard(card: card),
                        ),
                      )
                      .toList(growable: false),
                );
              }

              if (medium) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _CrmSummaryCard(card: cards[0])),
                        const SizedBox(width: AppUiConstants.spacingMd),
                        Expanded(child: _CrmSummaryCard(card: cards[1])),
                      ],
                    ),
                    const SizedBox(height: AppUiConstants.spacingMd),
                    Row(
                      children: [
                        Expanded(child: _CrmSummaryCard(card: cards[2])),
                        const SizedBox(width: AppUiConstants.spacingMd),
                        Expanded(child: _CrmSummaryCard(card: cards[3])),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  for (var index = 0; index < cards.length; index += 1) ...[
                    Expanded(child: _CrmSummaryCard(card: cards[index])),
                    if (index != cards.length - 1)
                      const SizedBox(width: AppUiConstants.spacingMd),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          if (desktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 13,
                  child: _CrmTasksBoard(tasks: tasks, now: now),
                ),
                const SizedBox(width: AppUiConstants.spacingMd),
                Expanded(
                  flex: 8,
                  child: _CrmInsightsBoard(snapshot: snapshot, now: now),
                ),
              ],
            )
          else
            Column(
              children: [
                _CrmTasksBoard(tasks: tasks, now: now),
                const SizedBox(height: AppUiConstants.spacingMd),
                _CrmInsightsBoard(snapshot: snapshot, now: now),
              ],
            ),
        ],
      ),
    );
  }
}

class _CrmDashboardSnapshot {
  const _CrmDashboardSnapshot({
    required this.leadCount,
    required this.enquiryCount,
    required this.pendingFollowups,
  });

  const _CrmDashboardSnapshot.empty()
    : leadCount = 0,
      enquiryCount = 0,
      pendingFollowups = const <CrmPendingFollowupItem>[];

  final int leadCount;
  final int enquiryCount;
  final List<CrmPendingFollowupItem> pendingFollowups;

  int countByBucket(CrmFollowupTimingBucket bucket, DateTime today) {
    return pendingFollowups
        .where((item) => crmFollowupBucket(item, today: today) == bucket)
        .length;
  }

  int countByPriority(String priority) {
    return pendingFollowups
        .where((item) => crmNormalizePriority(item.priority) == priority)
        .length;
  }

  int get pendingActions => pendingFollowups.length;

  int get unscheduledFollowups =>
      pendingFollowups.where((item) => item.followupDate == null).length;

  List<_CrmSummaryCardData> summaryCards(
    DateTime today,
    AppThemeExtension appTheme,
  ) {
    return <_CrmSummaryCardData>[
      _CrmSummaryCardData(
        title: 'Total Leads',
        subtitle: 'Live CRM lead records',
        accent: appTheme.crmLeadAccent,
        value: '$leadCount',
      ),
      _CrmSummaryCardData(
        title: 'Open Enquiries',
        subtitle: 'Tracked CRM enquiry records',
        accent: appTheme.crmEnquiryAccent,
        value: '$enquiryCount',
      ),
      _CrmSummaryCardData(
        title: 'Due Today',
        value: '${countByBucket(CrmFollowupTimingBucket.today, today)}',
        subtitle: 'Pending follow-ups scheduled today',
        accent: appTheme.crmTodayAccent,
      ),
      _CrmSummaryCardData(
        title: 'Pending Actions',
        value: '$pendingActions',
        subtitle: 'Open follow-ups not completed',
        accent: appTheme.crmPendingAccent,
      ),
    ];
  }

  List<_ChartSlice> distributionSlices(
    DateTime today,
    AppThemeExtension appTheme,
  ) {
    return <_ChartSlice>[
      _ChartSlice(
        label: 'Today',
        color: appTheme.crmTodayChartAccent,
        value: countByBucket(CrmFollowupTimingBucket.today, today),
      ),
      _ChartSlice(
        label: 'Overdue',
        color: appTheme.crmOverdueChartAccent,
        value: countByBucket(CrmFollowupTimingBucket.overdue, today),
      ),
      _ChartSlice(
        label: 'Upcoming',
        color: appTheme.crmUpcomingChartAccent,
        value: countByBucket(CrmFollowupTimingBucket.upcoming, today),
      ),
      _ChartSlice(
        label: 'No Date',
        color: appTheme.crmNoDateChartAccent,
        value: unscheduledFollowups,
      ),
    ];
  }

  List<_MonthlyPoint> monthlyFollowupPoints(DateTime today) {
    final start = DateTime(today.year, today.month - 2, 1);
    return List<_MonthlyPoint>.generate(6, (index) {
      final month = DateTime(start.year, start.month + index, 1);
      final nextMonth = DateTime(month.year, month.month + 1, 1);
      final count = pendingFollowups.where((item) {
        final value = item.followupDate;
        if (value == null) {
          return false;
        }
        return !value.isBefore(month) && value.isBefore(nextMonth);
      }).length;
      return _MonthlyPoint(label: _monthLabel(month.month), value: count);
    });
  }
}

class _CrmSummaryCardData {
  const _CrmSummaryCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accent;
}

class _CrmSummaryCard extends StatelessWidget {
  const _CrmSummaryCard({required this.card});

  final _CrmSummaryCardData card;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: appTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: appTheme.cardShadow,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: appTheme.cardShadow.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 5,
              decoration: BoxDecoration(
                color: card.accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            Text(
              card.title,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              card.value,
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingXs),
            Text(
              card.subtitle,
              style: textTheme.bodyMedium?.copyWith(color: appTheme.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrmTasksBoard extends StatelessWidget {
  const _CrmTasksBoard({required this.tasks, required this.now});

  final List<CrmPendingFollowupItem> tasks;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    return AppSectionCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tasks for Today',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          if (tasks.isEmpty)
            Container(
              key: const ValueKey<String>('crm-pending-followups-empty'),
              width: double.infinity,
              padding: const EdgeInsets.all(AppUiConstants.cardPadding),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: appTheme.cardShadow.withValues(alpha: 0.28),
                ),
              ),
              child: Text(
                'No pending follow-ups.',
                style: textTheme.bodyLarge?.copyWith(color: appTheme.mutedText),
              ),
            )
          else
            ...tasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(
                  bottom: AppUiConstants.spacingSm,
                ),
                child: _CrmTaskRow(item: task, now: now),
              ),
            ),
        ],
      ),
    );
  }
}

class _CrmTaskRow extends StatelessWidget {
  const _CrmTaskRow({required this.item, required this.now});

  final CrmPendingFollowupItem item;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    final dateColor = crmFollowupDateColor(item, today: now);
    final priorityColor = crmPriorityColor(item.priority);
    final statusLabel = item.status.trim().isEmpty
        ? 'Pending'
        : item.status.trim();
    final priorityLabel = crmPriorityLabel(item.priority);

    return Container(
      key: ValueKey<String>(
        'crm-pending-followup-${item.id ?? item.subjectName}',
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: appTheme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appTheme.cardShadow.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: appTheme.cardShadow.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CrmTaskIdentity(item: item, accent: priorityColor),
                const SizedBox(height: AppUiConstants.spacingSm),
                Wrap(
                  spacing: AppUiConstants.spacingMd,
                  runSpacing: AppUiConstants.spacingSm,
                  children: [
                    _CrmMiniMeta(
                      icon: Icons.flag_outlined,
                      label: priorityLabel,
                      color: priorityColor,
                    ),
                    _CrmMiniMeta(
                      icon: Icons.schedule_outlined,
                      label: _crmTimeLabel(item.followupDate),
                      color: dateColor,
                    ),
                    _CrmMiniMeta(icon: Icons.info_outline, label: statusLabel),
                  ],
                ),
                const SizedBox(height: AppUiConstants.spacingSm),
                Align(
                  alignment: Alignment.centerRight,
                  child: _CrmActionButton(
                    label: 'Open',
                    onTap: () => _openEnquiry(context),
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                flex: 6,
                child: _CrmTaskIdentity(item: item, accent: priorityColor),
              ),
              Expanded(
                flex: 2,
                child: _CrmMiniMeta(
                  icon: Icons.flag_outlined,
                  label: priorityLabel,
                  color: priorityColor,
                ),
              ),
              Expanded(
                flex: 2,
                child: _CrmMiniMeta(
                  icon: Icons.schedule_outlined,
                  label: _crmTimeLabel(item.followupDate),
                  color: dateColor,
                ),
              ),
              Expanded(
                flex: 2,
                child: _CrmMiniMeta(
                  icon: Icons.info_outline,
                  label: statusLabel,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: _CrmActionButton(
                  label: 'Open',
                  onTap: () => _openEnquiry(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openEnquiry(BuildContext context) {
    final enquiryId = item.enquiryId;
    final route = enquiryId == null
        ? '/crm/enquiries'
        : '/crm/enquiries?select_id=$enquiryId';
    _openCrmShellRoute(context, route);
  }
}

class _CrmTaskIdentity extends StatelessWidget {
  const _CrmTaskIdentity({required this.item, required this.accent});

  final CrmPendingFollowupItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    final initials = _crmInitials(item.assignedUserName ?? item.subjectName);
    final subtitle = (item.summary?.trim().isNotEmpty == true)
        ? item.summary!.trim()
        : item.assignedUserName?.trim().isNotEmpty == true
        ? item.assignedUserName!.trim()
        : 'No notes available.';

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: <Color>[
                accent.withValues(alpha: 0.85),
                accent.withValues(alpha: 0.55),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: textTheme.labelLarge?.copyWith(
              color: appTheme.cardBackground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: AppUiConstants.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.subjectName,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: appTheme.mutedText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CrmMiniMeta extends StatelessWidget {
  const _CrmMiniMeta({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    final iconColor = color ?? appTheme.crmChartText;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: iconColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _CrmActionButton extends StatelessWidget {
  const _CrmActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: appTheme.crmActionBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: appTheme.cardShadow.withValues(alpha: 0.48),
            ),
            boxShadow: [
              BoxShadow(
                color: appTheme.crmActionShadow,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: appTheme.cardBackground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CrmInsightsBoard extends StatelessWidget {
  const _CrmInsightsBoard({required this.snapshot, required this.now});

  final _CrmDashboardSnapshot snapshot;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    final slices = snapshot
        .distributionSlices(now, appTheme)
        .where((slice) => slice.value > 0)
        .toList(growable: false);
    final total = slices.fold<int>(0, (sum, item) => sum + item.value);
    final monthlyPoints = snapshot.monthlyFollowupPoints(now);

    return AppSectionCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Follow-up Distribution',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 420;
              final chart = _CrmDonutChart(
                slices: slices,
                total: total,
                mutedTextColor: appTheme.crmChartMutedText,
              );
              final legend = Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: slices
                    .map(
                      (slice) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: slice.color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(slice.label),
                          ],
                        ),
                      ),
                    )
                    .toList(growable: false),
              );

              if (compact) {
                return Column(
                  children: [
                    chart,
                    const SizedBox(height: AppUiConstants.spacingSm),
                    legend,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: chart),
                  const SizedBox(width: AppUiConstants.spacingMd),
                  legend,
                ],
              );
            },
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          Text(
            'Follow-up Trend by Month',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          SizedBox(height: 156, child: _CrmLineChart(points: monthlyPoints)),
        ],
      ),
    );
  }
}

class _ChartSlice {
  const _ChartSlice({
    required this.label,
    required this.color,
    required this.value,
  });

  final String label;
  final Color color;
  final int value;
}

class _MonthlyPoint {
  const _MonthlyPoint({required this.label, required this.value});

  final String label;
  final int value;
}

class _CrmDonutChart extends StatelessWidget {
  const _CrmDonutChart({
    required this.slices,
    required this.total,
    required this.mutedTextColor,
  });

  final List<_ChartSlice> slices;
  final int total;
  final Color mutedTextColor;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Text(
            'No pending follow-up data.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: mutedTextColor),
          ),
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(150),
            painter: _DonutChartPainter(slices: slices, total: total),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$total',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Open',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: mutedTextColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CrmLineChart extends StatelessWidget {
  const _CrmLineChart({required this.points});

  final List<_MonthlyPoint> points;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    return CustomPaint(
      painter: _LineChartPainter(
        points: points,
        gridColor: appTheme.crmChartGrid,
        lineStartColor: appTheme.crmChartLineStart,
        lineEndColor: appTheme.crmChartLineEnd,
        fillColor: appTheme.crmChartFill,
        textColor: appTheme.crmChartText,
        mutedTextColor: appTheme.crmChartMutedText,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({required this.slices, required this.total});

  final List<_ChartSlice> slices;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) {
      return;
    }

    final center = (Offset.zero & size).center;
    final radius = math.min(size.width, size.height) / 2 - 8;
    const strokeWidth = 24.0;
    var startAngle = -math.pi / 2;

    for (final slice in slices) {
      final sweepAngle = (slice.value / total) * (math.pi * 2);
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.total != total || oldDelegate.slices != slices;
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.points,
    required this.gridColor,
    required this.lineStartColor,
    required this.lineEndColor,
    required this.fillColor,
    required this.textColor,
    required this.mutedTextColor,
  });

  final List<_MonthlyPoint> points;
  final Color gridColor;
  final Color lineStartColor;
  final Color lineEndColor;
  final Color fillColor;
  final Color textColor;
  final Color mutedTextColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[lineStartColor, lineEndColor],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          fillColor.withValues(alpha: 0.18),
          fillColor.withValues(alpha: 0.02),
        ],
      ).createShader(Offset.zero & size);

    final leftPad = 34.0;
    final rightPad = 12.0;
    final topPad = 14.0;
    final bottomPad = 28.0;
    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;
    final values = points.map((point) => point.value).toList(growable: false);
    final maxValue = values.isEmpty ? 1 : math.max(values.reduce(math.max), 1);
    final xStep = points.length > 1
        ? chartWidth / (points.length - 1)
        : chartWidth;

    for (var i = 0; i < 4; i += 1) {
      final dy = topPad + (chartHeight / 3) * i;
      canvas.drawLine(
        Offset(leftPad, dy),
        Offset(size.width - rightPad, dy),
        gridPaint,
      );
    }

    final path = Path();
    final fillPath = Path();
    final plotted = <Offset>[];

    for (var i = 0; i < points.length; i += 1) {
      final x = leftPad + (xStep * i);
      final y =
          topPad + chartHeight - ((points[i].value / maxValue) * chartHeight);
      final point = Offset(x, y);
      plotted.add(point);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
        fillPath.moveTo(point.dx, size.height - bottomPad);
        fillPath.lineTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
        fillPath.lineTo(point.dx, point.dy);
      }
    }

    if (plotted.isNotEmpty) {
      fillPath.lineTo(plotted.last.dx, size.height - bottomPad);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(path, linePaint);
    }

    final pointPaint = Paint()..color = lineEndColor;
    final labelStyle = TextStyle(
      color: textColor,
      fontSize: 10,
      fontWeight: FontWeight.w600,
    );
    final monthStyle = TextStyle(color: textColor, fontSize: 11);
    final yStyle = TextStyle(color: mutedTextColor, fontSize: 10);

    for (var i = 0; i < plotted.length; i += 1) {
      canvas.drawCircle(plotted[i], 4.5, pointPaint);
      final valuePainter = TextPainter(
        text: TextSpan(text: '${points[i].value}', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      valuePainter.paint(
        canvas,
        Offset(plotted[i].dx - (valuePainter.width / 2), plotted[i].dy - 18),
      );

      final monthPainter = TextPainter(
        text: TextSpan(text: points[i].label, style: monthStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      monthPainter.paint(
        canvas,
        Offset(plotted[i].dx - (monthPainter.width / 2), size.height - 20),
      );
    }

    for (var i = 0; i < 4; i += 1) {
      final value = ((maxValue / 3) * (3 - i)).round();
      final painter = TextPainter(
        text: TextSpan(text: '$value', style: yStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(0, topPad + (chartHeight / 3) * i - 6));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

String _crmInitials(String text) {
  final parts = text
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList(growable: false);
  if (parts.isEmpty) {
    return 'NA';
  }
  return parts.map((part) => part[0].toUpperCase()).join();
}

String _crmTimeLabel(DateTime? value) {
  if (value == null) {
    return 'No time';
  }
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final meridiem = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $meridiem';
}

String _monthLabel(int month) {
  const labels = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return labels[(month - 1).clamp(0, 11)];
}
