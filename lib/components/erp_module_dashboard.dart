import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/constants/app_ui_constants.dart';
import '../app/theme/app_theme_extension.dart';
import '../helper/responsive.dart';
import '../View/core/page_shell_actions.dart';
import 'adaptive_shell.dart';

enum ErpDashboardTrendControlValue { monthly, weekly, yearly, custom }

class ErpDashboardSnapshot {
  const ErpDashboardSnapshot({
    required this.title,
    required this.subtitle,
    this.actions = const <ErpDashboardAction>[],
    this.stats = const <ErpDashboardStat>[],
    this.primarySections = const <ErpDashboardListSection>[],
    this.trend,
    this.distribution,
    this.highlights,
    this.emptyTitle = 'No dashboard data yet',
    this.emptyMessage =
        'Connect this module to live analytics or add activity to populate the dashboard.',
  });

  final String title;
  final String subtitle;
  final List<ErpDashboardAction> actions;
  final List<ErpDashboardStat> stats;
  final List<ErpDashboardListSection> primarySections;
  final ErpDashboardTrendCardData? trend;
  final ErpDashboardDistributionCardData? distribution;
  final ErpDashboardHighlightsCardData? highlights;
  final String emptyTitle;
  final String emptyMessage;

  bool get hasContent {
    if (stats.isNotEmpty) {
      return true;
    }
    if (primarySections.any((section) => section.items.isNotEmpty)) {
      return true;
    }
    if (trend?.points.isNotEmpty == true) {
      return true;
    }
    if (distribution?.segments.isNotEmpty == true) {
      return true;
    }
    if (highlights?.entries.isNotEmpty == true) {
      return true;
    }
    return false;
  }
}

class ErpDashboardAction {
  const ErpDashboardAction({
    required this.label,
    required this.icon,
    this.route,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final String? route;
  final VoidCallback? onPressed;
}

class ErpDashboardStat {
  const ErpDashboardStat({
    required this.label,
    required this.value,
    required this.icon,
    this.helper,
    this.color = const Color(0xFF2F6FED),
  });

  final String label;
  final String value;
  final String? helper;
  final IconData icon;
  final Color color;
}

class ErpDashboardListSection {
  const ErpDashboardListSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.items = const <ErpDashboardListItem>[],
    this.emptyTitle = 'No records yet',
    this.emptyMessage = 'This section will populate when activity starts.',
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<ErpDashboardListItem> items;
  final String emptyTitle;
  final String emptyMessage;
}

class ErpDashboardListItem {
  const ErpDashboardListItem({
    required this.title,
    required this.subtitle,
    this.detail,
    this.statusLabel,
    this.statusColor,
    this.route,
  });

  final String title;
  final String subtitle;
  final String? detail;
  final String? statusLabel;
  final Color? statusColor;
  final String? route;
}

class ErpDashboardTrendCardData {
  const ErpDashboardTrendCardData({
    required this.title,
    required this.subtitle,
    this.points = const <ErpDashboardTrendPoint>[],
    this.emptyMessage =
        'Trend data will appear here once analytics is available.',
    this.color = const Color(0xFF2F6FED),
  });

  final String title;
  final String subtitle;
  final List<ErpDashboardTrendPoint> points;
  final String emptyMessage;
  final Color color;
}

class ErpDashboardTrendPoint {
  const ErpDashboardTrendPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class ErpDashboardDistributionCardData {
  const ErpDashboardDistributionCardData({
    required this.title,
    required this.subtitle,
    this.segments = const <ErpDashboardDistributionSegment>[],
    this.emptyMessage =
        'Distribution data will appear here once the module has categorized records.',
  });

  final String title;
  final String subtitle;
  final List<ErpDashboardDistributionSegment> segments;
  final String emptyMessage;
}

class ErpDashboardDistributionSegment {
  const ErpDashboardDistributionSegment({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

class ErpDashboardHighlightsCardData {
  const ErpDashboardHighlightsCardData({
    required this.title,
    required this.subtitle,
    this.entries = const <ErpDashboardHighlightEntry>[],
    this.emptyMessage = 'No highlights available yet.',
  });

  final String title;
  final String subtitle;
  final List<ErpDashboardHighlightEntry> entries;
  final String emptyMessage;
}

class ErpDashboardHighlightEntry {
  const ErpDashboardHighlightEntry({
    required this.label,
    required this.value,
    this.helper,
    this.color = const Color(0xFF2F6FED),
  });

  final String label;
  final String value;
  final String? helper;
  final Color color;
}

class ErpModuleDashboard extends StatelessWidget {
  const ErpModuleDashboard({
    super.key,
    required this.snapshot,
    this.trendControlValue,
    this.onTrendControlChanged,
    this.showTrendControls = false,
  });

  final ErpDashboardSnapshot snapshot;
  final ErpDashboardTrendControlValue? trendControlValue;
  final ValueChanged<ErpDashboardTrendControlValue>? onTrendControlChanged;
  final bool showTrendControls;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final showTwoColumn = width >= AppUiConstants.dashboardSplitBreakpoint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DashboardHeader(snapshot: snapshot),
        const SizedBox(height: AppUiConstants.spacingLg),
        _DashboardStatGrid(stats: snapshot.stats),
        const SizedBox(height: AppUiConstants.spacingLg),
        if (!snapshot.hasContent)
          _DashboardEmptyState(
            title: snapshot.emptyTitle,
            message: snapshot.emptyMessage,
          )
        else if (showTwoColumn)
          Row(
            key: const Key('erp-dashboard-two-column'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 13,
                child: _DashboardPrimaryColumn(
                  sections: snapshot.primarySections,
                ),
              ),
              const SizedBox(width: AppUiConstants.spacingLg),
              Expanded(
                flex: 8,
                child: _DashboardInsightsColumn(
                  snapshot: snapshot,
                  trendControlValue: trendControlValue,
                  onTrendControlChanged: onTrendControlChanged,
                  showTrendControls: showTrendControls,
                ),
              ),
            ],
          )
        else
          Column(
            key: const Key('erp-dashboard-stacked'),
            children: [
              _DashboardPrimaryColumn(sections: snapshot.primarySections),
              const SizedBox(height: AppUiConstants.spacingLg),
              _DashboardInsightsColumn(
                snapshot: snapshot,
                trendControlValue: trendControlValue,
                onTrendControlChanged: onTrendControlChanged,
                showTrendControls: showTrendControls,
              ),
            ],
          ),
      ],
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.snapshot});

  final ErpDashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    final actions = snapshot.actions;
    final isCompact = MediaQuery.of(context).size.width < 720;

    return _DashboardSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCompact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DashboardHeaderText(snapshot: snapshot, appTheme: appTheme),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: AppUiConstants.spacingMd),
                  Wrap(
                    spacing: AppUiConstants.spacingSm,
                    runSpacing: AppUiConstants.spacingSm,
                    children: actions
                        .map((action) => _DashboardActionButton(action: action))
                        .toList(growable: false),
                  ),
                ],
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _DashboardHeaderText(
                    snapshot: snapshot,
                    appTheme: appTheme,
                  ),
                ),
                if (actions.isNotEmpty)
                  Wrap(
                    spacing: AppUiConstants.spacingSm,
                    runSpacing: AppUiConstants.spacingSm,
                    children: actions
                        .map((action) => _DashboardActionButton(action: action))
                        .toList(growable: false),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DashboardHeaderText extends StatelessWidget {
  const _DashboardHeaderText({required this.snapshot, required this.appTheme});

  final ErpDashboardSnapshot snapshot;
  final AppThemeExtension appTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          snapshot.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppUiConstants.spacingXs),
        Text(
          snapshot.subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: appTheme.mutedText),
        ),
      ],
    );
  }
}

class _DashboardActionButton extends StatelessWidget {
  const _DashboardActionButton({required this.action});

  final ErpDashboardAction action;

  @override
  Widget build(BuildContext context) {
    return AdaptiveShellActionButton(
      icon: action.icon,
      label: action.label,
      filled: false,
      onPressed: () {
        final onPressed = action.onPressed;
        if (onPressed != null) {
          onPressed();
          return;
        }

        final route = action.route;
        if (route == null || route.trim().isEmpty) {
          return;
        }

        final navigate = ShellRouteScope.maybeOf(context);
        if (navigate != null) {
          navigate(route);
          return;
        }
        Navigator.of(context).pushNamed(route);
      },
    );
  }
}

class _DashboardStatGrid extends StatelessWidget {
  const _DashboardStatGrid({required this.stats});

  final List<ErpDashboardStat> stats;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1180
            ? 4
            : width >= 760
            ? 2
            : 1;
        final gap = AppUiConstants.spacingMd;
        final cardWidth = columns == 1
            ? width
            : (width - ((columns - 1) * gap)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: stats
              .map(
                (stat) => SizedBox(
                  width: cardWidth,
                  child: _DashboardStatCard(stat: stat),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _DashboardStatCard extends StatelessWidget {
  const _DashboardStatCard({required this.stat});

  final ErpDashboardStat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;

    return _DashboardSurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
            ),
            child: Icon(stat.icon, color: stat.color),
          ),
          const SizedBox(width: AppUiConstants.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: appTheme.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppUiConstants.spacingXs),
                Text(
                  stat.value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if ((stat.helper ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: AppUiConstants.spacingXs),
                  Text(
                    stat.helper!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: appTheme.mutedText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardPrimaryColumn extends StatelessWidget {
  const _DashboardPrimaryColumn({required this.sections});

  final List<ErpDashboardListSection> sections;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const _DashboardEmptyState(
        title: 'No operational sections',
        message:
            'Add module-specific lists to populate the primary dashboard column.',
      );
    }

    return Column(
      children: sections
          .map(
            (section) => Padding(
              padding: EdgeInsets.only(
                bottom: section == sections.last ? 0 : AppUiConstants.spacingLg,
              ),
              child: _DashboardListCard(section: section),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _DashboardInsightsColumn extends StatelessWidget {
  const _DashboardInsightsColumn({
    required this.snapshot,
    required this.trendControlValue,
    required this.onTrendControlChanged,
    required this.showTrendControls,
  });

  final ErpDashboardSnapshot snapshot;
  final ErpDashboardTrendControlValue? trendControlValue;
  final ValueChanged<ErpDashboardTrendControlValue>? onTrendControlChanged;
  final bool showTrendControls;

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      if (snapshot.trend != null)
        _DashboardTrendCard(
          data: snapshot.trend!,
          trendControlValue: trendControlValue,
          onTrendControlChanged: onTrendControlChanged,
          showTrendControls: showTrendControls,
        ),
      if (snapshot.distribution != null)
        _DashboardDistributionCard(data: snapshot.distribution!),
      if (snapshot.highlights != null)
        _DashboardHighlightsCard(data: snapshot.highlights!),
    ];

    if (cards.isEmpty) {
      return const _DashboardEmptyState(
        title: 'No analytics configured',
        message:
            'Add trend, distribution, or highlight data to populate the analytics column.',
      );
    }

    return Column(
      children: cards
          .map(
            (card) => Padding(
              padding: EdgeInsets.only(
                bottom: card == cards.last ? 0 : AppUiConstants.spacingLg,
              ),
              child: card,
            ),
          )
          .toList(growable: false),
    );
  }
}

class _DashboardListCard extends StatelessWidget {
  const _DashboardListCard({required this.section});

  final ErpDashboardListSection section;

  @override
  Widget build(BuildContext context) {
    final items = section.items;
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    return _DashboardSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashboardCardTitle(
            title: section.title,
            subtitle: section.subtitle,
            icon: section.icon,
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          if (items.isEmpty)
            _DashboardInlineEmptyState(
              title: section.emptyTitle,
              message: section.emptyMessage,
            )
          else
            Column(
              children: items
                  .map(
                    (item) => Padding(
                      padding: EdgeInsets.only(
                        bottom: item == items.last
                            ? 0
                            : AppUiConstants.spacingSm,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          AppUiConstants.buttonRadius,
                        ),
                        onTap: item.route == null
                            ? null
                            : () {
                                final navigate = ShellRouteScope.maybeOf(
                                  context,
                                );
                                if (navigate != null) {
                                  navigate(item.route!);
                                  return;
                                }
                                Navigator.of(context).pushNamed(item.route!);
                              },
                        child: Container(
                          padding: const EdgeInsets.all(
                            AppUiConstants.tilePadding,
                          ),
                          decoration: BoxDecoration(
                            color: appTheme.subtleFill.withValues(alpha: 0.42),
                            borderRadius: BorderRadius.circular(
                              AppUiConstants.buttonRadius,
                            ),
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(
                                      height: AppUiConstants.spacingXxs,
                                    ),
                                    Text(
                                      item.subtitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: appTheme.mutedText),
                                    ),
                                    if ((item.detail ?? '')
                                        .trim()
                                        .isNotEmpty) ...[
                                      const SizedBox(
                                        height: AppUiConstants.spacingXxs,
                                      ),
                                      Text(
                                        item.detail!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: appTheme.mutedText,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if ((item.statusLabel ?? '').trim().isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (item.statusColor ?? itemColor)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                      AppUiConstants.pillRadius,
                                    ),
                                  ),
                                  child: Text(
                                    item.statusLabel!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: item.statusColor ?? itemColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }

  Color get itemColor => const Color(0xFF2F6FED);
}

class _DashboardTrendCard extends StatelessWidget {
  const _DashboardTrendCard({
    required this.data,
    required this.trendControlValue,
    required this.onTrendControlChanged,
    required this.showTrendControls,
  });

  final ErpDashboardTrendCardData data;
  final ErpDashboardTrendControlValue? trendControlValue;
  final ValueChanged<ErpDashboardTrendControlValue>? onTrendControlChanged;
  final bool showTrendControls;

  @override
  Widget build(BuildContext context) {
    return _DashboardSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashboardCardTitle(
            title: data.title,
            subtitle: data.subtitle,
            icon: Icons.show_chart_outlined,
          ),
          if (showTrendControls &&
              trendControlValue != null &&
              onTrendControlChanged != null) ...[
            const SizedBox(height: AppUiConstants.spacingMd),
            Align(
              alignment: Alignment.centerLeft,
              child: _TrendControlDropdown(
                value: trendControlValue!,
                onChanged: onTrendControlChanged!,
              ),
            ),
          ],
          const SizedBox(height: AppUiConstants.spacingMd),
          if (data.points.isEmpty)
            _DashboardInlineEmptyState(
              title: 'No trend points yet',
              message: data.emptyMessage,
            )
          else ...[
            SizedBox(
              height: AppUiConstants.dashboardChartHeight,
              child: CustomPaint(
                painter: _TrendChartPainter(
                  points: data.points,
                  color: data.color,
                  gridColor: Theme.of(
                    context,
                  ).dividerColor.withValues(alpha: 0.12),
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            Row(
              children: data.points
                  .map(
                    (point) => Expanded(
                      child: Text(
                        point.label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _TrendControlDropdown extends StatelessWidget {
  const _TrendControlDropdown({required this.value, required this.onChanged});

  final ErpDashboardTrendControlValue value;
  final ValueChanged<ErpDashboardTrendControlValue> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('erp-dashboard-trend-filter-dropdown'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.20),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ErpDashboardTrendControlValue>(
          value: value,
          borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: const [
            DropdownMenuItem(
              value: ErpDashboardTrendControlValue.monthly,
              child: Text('Monthly'),
            ),
            DropdownMenuItem(
              value: ErpDashboardTrendControlValue.weekly,
              child: Text('Weekly'),
            ),
            DropdownMenuItem(
              value: ErpDashboardTrendControlValue.yearly,
              child: Text('Yearly'),
            ),
            DropdownMenuItem(
              value: ErpDashboardTrendControlValue.custom,
              child: Text('Custom'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}

class _DashboardDistributionCard extends StatelessWidget {
  const _DashboardDistributionCard({required this.data});

  final ErpDashboardDistributionCardData data;

  @override
  Widget build(BuildContext context) {
    final total = data.segments.fold<double>(
      0,
      (sum, segment) => sum + segment.value,
    );

    return _DashboardSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashboardCardTitle(
            title: data.title,
            subtitle: data.subtitle,
            icon: Icons.pie_chart_outline,
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          if (data.segments.isEmpty || total <= 0)
            _DashboardInlineEmptyState(
              title: 'No distribution yet',
              message: data.emptyMessage,
            )
          else ...[
            SizedBox(
              height: AppUiConstants.dashboardChartHeight,
              child: CustomPaint(
                painter: _DistributionPieChartPainter(
                  segments: data.segments,
                  total: total,
                  dividerColor: Theme.of(context).scaffoldBackgroundColor,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            Column(
              children: data.segments
                  .map(
                    (segment) => Padding(
                      padding: EdgeInsets.only(
                        bottom: segment == data.segments.last
                            ? 0
                            : AppUiConstants.spacingSm,
                      ),
                      child: _DistributionRow(segment: segment, total: total),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  const _DistributionRow({required this.segment, required this.total});

  final ErpDashboardDistributionSegment segment;
  final double total;

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : segment.value / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: segment.color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: AppUiConstants.spacingSm),
            Expanded(
              child: Text(
                segment.label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '${_formatSegmentValue(segment.value)}  ${_formatSegmentPercent(ratio)}',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}

class _DistributionPieChartPainter extends CustomPainter {
  _DistributionPieChartPainter({
    required this.segments,
    required this.total,
    required this.dividerColor,
  });

  final List<ErpDashboardDistributionSegment> segments;
  final double total;
  final Color dividerColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty || total <= 0 || size.isEmpty) {
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final ringWidth = radius * 0.34;
    final chartRect = Rect.fromCircle(center: center, radius: radius);
    var startAngle = -math.pi / 2;

    for (final segment in segments) {
      final sweepAngle = (segment.value / total) * math.pi * 2;
      if (sweepAngle <= 0) {
        continue;
      }

      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        chartRect.deflate(ringWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }

    final holePaint = Paint()
      ..color = dividerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - ringWidth, holePaint);
  }

  @override
  bool shouldRepaint(covariant _DistributionPieChartPainter oldDelegate) {
    return oldDelegate.segments != segments ||
        oldDelegate.total != total ||
        oldDelegate.dividerColor != dividerColor;
  }
}

class _DashboardHighlightsCard extends StatelessWidget {
  const _DashboardHighlightsCard({required this.data});

  final ErpDashboardHighlightsCardData data;

  @override
  Widget build(BuildContext context) {
    return _DashboardSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DashboardCardTitle(
            title: data.title,
            subtitle: data.subtitle,
            icon: Icons.insights_outlined,
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          if (data.entries.isEmpty)
            _DashboardInlineEmptyState(
              title: 'No highlights yet',
              message: data.emptyMessage,
            )
          else
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: data.entries
                  .map((entry) => _HighlightTile(entry: entry))
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({required this.entry});

  final ErpDashboardHighlightEntry entry;

  @override
  Widget build(BuildContext context) {
    final width = Responsive.isDesktop(context)
        ? ((MediaQuery.of(context).size.width * 0.32) - 56)
              .clamp(120, 220)
              .toDouble()
        : double.infinity;

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(AppUiConstants.tilePadding),
        decoration: BoxDecoration(
          color: entry.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
          border: Border.all(color: entry.color.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: entry.color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingXs),
            Text(
              entry.value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            if ((entry.helper ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: AppUiConstants.spacingXxs),
              Text(entry.helper!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashboardCardTitle extends StatelessWidget {
  const _DashboardCardTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: appTheme.subtleFill.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
          ),
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: AppUiConstants.spacingSm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppUiConstants.spacingXxs),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: appTheme.mutedText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardSurfaceCard extends StatelessWidget {
  const _DashboardSurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: appTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: appTheme.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppUiConstants.cardPadding),
        child: child,
      ),
    );
  }
}

class _DashboardEmptyState extends StatelessWidget {
  const _DashboardEmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _DashboardSurfaceCard(
      child: _DashboardInlineEmptyState(title: title, message: message),
    );
  }
}

class _DashboardInlineEmptyState extends StatelessWidget {
  const _DashboardInlineEmptyState({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppUiConstants.spacing2xl,
          horizontal: AppUiConstants.spacingMd,
        ),
        child: Column(
          children: [
            Icon(
              Icons.insert_chart_outlined_outlined,
              size: 32,
              color: appTheme.mutedText,
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppUiConstants.spacingXs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: appTheme.mutedText),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  _TrendChartPainter({
    required this.points,
    required this.color,
    required this.gridColor,
  });

  final List<ErpDashboardTrendPoint> points;
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    const horizontalPadding = 12.0;
    const verticalPadding = 18.0;
    final chartWidth = size.width - (horizontalPadding * 2);
    final chartHeight = size.height - (verticalPadding * 2);
    if (chartWidth <= 0 || chartHeight <= 0) {
      return;
    }

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var index = 0; index < 4; index += 1) {
      final y = verticalPadding + (chartHeight / 3) * index;
      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(horizontalPadding + chartWidth, y),
        gridPaint,
      );
    }

    final maxValue = points
        .map((point) => point.value)
        .fold<double>(0, math.max)
        .clamp(1, double.infinity);

    final path = Path();
    final fillPath = Path();
    for (var index = 0; index < points.length; index += 1) {
      final ratio = points.length == 1 ? 0.5 : index / (points.length - 1);
      final dx = horizontalPadding + (chartWidth * ratio);
      final dy =
          verticalPadding +
          chartHeight -
          ((points[index].value / maxValue) * chartHeight);
      if (index == 0) {
        path.moveTo(dx, dy);
        fillPath
          ..moveTo(dx, verticalPadding + chartHeight)
          ..lineTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
        fillPath.lineTo(dx, dy);
      }
    }

    fillPath
      ..lineTo(horizontalPadding + chartWidth, verticalPadding + chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.24),
              color.withValues(alpha: 0.02),
            ],
          ).createShader(
            Rect.fromLTWH(
              horizontalPadding,
              verticalPadding,
              chartWidth,
              chartHeight,
            ),
          );
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    final pointPaint = Paint()..color = color;
    for (var index = 0; index < points.length; index += 1) {
      final ratio = points.length == 1 ? 0.5 : index / (points.length - 1);
      final dx = horizontalPadding + (chartWidth * ratio);
      final dy =
          verticalPadding +
          chartHeight -
          ((points[index].value / maxValue) * chartHeight);
      canvas.drawCircle(Offset(dx, dy), 4, pointPaint);
      canvas.drawCircle(
        Offset(dx, dy),
        7,
        Paint()..color = color.withValues(alpha: 0.16),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter other) {
    return other.points != points ||
        other.color != color ||
        other.gridColor != gridColor;
  }
}

String _formatSegmentValue(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
}

String _formatSegmentPercent(double ratio) {
  return '${(ratio * 100).toStringAsFixed(0)}%';
}
