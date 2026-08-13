import '../../../screen.dart';
import '../../../model/activity_watch_enrollment.dart';
import '../../../service/activity_watch/activity_watch_service.dart';
import '../../../core/activity_watch/service/activity_watch_service_control.dart';
import '../../../core/files/external_url.dart';

enum _ActivityDateFilter { today, month, year, custom }

const _activityGraphGreen = Color(0xFF68A95B);
const _activityGraphRed = Color(0xFFFF5252);

final class _ActivityGraphPoint {
  const _ActivityGraphPoint({
    required this.date,
    required this.activeSeconds,
    required this.idleSeconds,
  });

  final DateTime date;
  final int activeSeconds;
  final int idleSeconds;
}

final class _DeviceActivityPoint {
  const _DeviceActivityPoint({
    required this.date,
    required this.activeSeconds,
    required this.idleSeconds,
    required this.keyboardActiveSeconds,
    required this.keyboardIdleSeconds,
    required this.mouseActiveSeconds,
    required this.mouseIdleSeconds,
    required this.browserSeconds,
    required this.lockedSeconds,
    required this.untrackedSeconds,
  });

  final DateTime date;
  final int activeSeconds;
  final int idleSeconds;
  final int keyboardActiveSeconds;
  final int keyboardIdleSeconds;
  final int mouseActiveSeconds;
  final int mouseIdleSeconds;
  final int browserSeconds;
  final int lockedSeconds;
  final int untrackedSeconds;
}

class _ActivityGraph extends StatefulWidget {
  const _ActivityGraph({
    required this.title,
    required this.activeLabel,
    this.idleLabel,
    required this.points,
    required this.activeColor,
    this.idleColor,
  });

  final String title;
  final String activeLabel;
  final String? idleLabel;
  final List<_ActivityGraphPoint> points;
  final Color activeColor;
  final Color? idleColor;

  @override
  State<_ActivityGraph> createState() => _ActivityGraphState();
}

class _ActivityGraphState extends State<_ActivityGraph> {
  int? _hoveredIndex;

  void _setHoveredIndex(Offset position, double width) {
    if (width <= 0 || widget.points.isEmpty) return;
    final fraction = (position.dx / width).clamp(0.0, 1.0);
    final index = widget.points.length == 1
        ? 0
        : (fraction * (widget.points.length - 1)).round();
    if (_hoveredIndex != index) setState(() => _hoveredIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    final scale = _activityGraphScale(widget.points, widget.idleColor != null);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: appTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppUiConstants.tableRadiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppUiConstants.spacingMd),
        child: widget.points.isEmpty
            ? Text(
                'No activity was reported for this device in the selected date range.',
                style: theme.textTheme.bodySmall,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    widget.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppUiConstants.spacingSm),
                  SizedBox(
                    height: 152,
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 44,
                          child: _ActivityGraphTimeline(scale: scale),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              const tooltipMaximumWidth = 260.0;
                              final tooltipWidth =
                                  constraints.maxWidth < tooltipMaximumWidth
                                  ? constraints.maxWidth
                                  : tooltipMaximumWidth;
                              final tooltipLeft = _activityGraphTooltipLeft(
                                hoveredIndex: _hoveredIndex,
                                count: widget.points.length,
                                graphWidth: constraints.maxWidth,
                                tooltipWidth: tooltipWidth,
                              );
                              return MouseRegion(
                                opaque: true,
                                onExit: (_) =>
                                    setState(() => _hoveredIndex = null),
                                onHover: (event) => _setHoveredIndex(
                                  event.localPosition,
                                  constraints.maxWidth,
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: <Widget>[
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _ActivityGraphPainter(
                                          points: widget.points,
                                          activeColor: widget.activeColor,
                                          idleColor: widget.idleColor,
                                          gridColor: theme.dividerColor
                                              .withValues(alpha: 0.16),
                                          hoveredIndex: _hoveredIndex,
                                          scale: scale,
                                        ),
                                        child: const SizedBox.expand(),
                                      ),
                                    ),
                                    if (_hoveredIndex != null)
                                      _ActivityGraphTooltip(
                                        point: widget.points[_hoveredIndex!],
                                        activeLabel: widget.activeLabel,
                                        idleLabel: widget.idleLabel,
                                        left: tooltipLeft,
                                        width: tooltipWidth,
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppUiConstants.spacingXxs),
                  Padding(
                    padding: const EdgeInsets.only(left: 56, right: 12),
                    child: _ActivityGraphDateAxis(points: widget.points),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ActivityGraphTimeline extends StatelessWidget {
  const _ActivityGraphTimeline({required this.scale});

  final int scale;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: <Widget>[
      Text(
        _durationLabel(scale),
        style: Theme.of(context).textTheme.labelSmall,
      ),
      Text(
        _durationLabel((scale * 2 / 3).round()),
        style: Theme.of(context).textTheme.labelSmall,
      ),
      Text(
        _durationLabel((scale / 3).round()),
        style: Theme.of(context).textTheme.labelSmall,
      ),
      Text('0m', style: Theme.of(context).textTheme.labelSmall),
    ],
  );
}

class _ActivityGraphDateAxis extends StatelessWidget {
  const _ActivityGraphDateAxis({required this.points});

  final List<_ActivityGraphPoint> points;

  @override
  Widget build(BuildContext context) {
    final labelCount = points.length < 4 ? points.length : 4;
    if (labelCount == 0) return const SizedBox.shrink();
    if (labelCount == 1) {
      return Align(
        alignment: Alignment.centerLeft,
        child: _label(context, points.first.date),
      );
    }
    final lastIndex = points.length - 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List<Widget>.generate(labelCount, (index) {
        final pointIndex = ((lastIndex * index) / (labelCount - 1)).round();
        return _label(context, points[pointIndex].date);
      }),
    );
  }

  Widget _label(BuildContext context, DateTime date) => Text(
    _activityGraphDate(date),
    style: Theme.of(context).textTheme.labelSmall,
  );
}

class _ActivityGraphTooltip extends StatelessWidget {
  const _ActivityGraphTooltip({
    required this.point,
    required this.activeLabel,
    required this.idleLabel,
    required this.left,
    required this.width,
  });

  final _ActivityGraphPoint point;
  final String activeLabel;
  final String? idleLabel;
  final double left;
  final double width;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: 4,
    child: IgnorePointer(
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          '${_activityGraphDate(point.date)}  $activeLabel ${_durationLabel(point.activeSeconds)}'
          '${idleLabel == null ? '' : ' · $idleLabel ${_durationLabel(point.idleSeconds)}'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onInverseSurface,
          ),
        ),
      ),
    ),
  );
}

class _ActivityGraphPainter extends CustomPainter {
  _ActivityGraphPainter({
    required this.points,
    required this.activeColor,
    required this.idleColor,
    required this.gridColor,
    required this.hoveredIndex,
    required this.scale,
  });

  final List<_ActivityGraphPoint> points;
  final Color activeColor;
  final Color? idleColor;
  final Color gridColor;
  final int? hoveredIndex;
  final int scale;

  @override
  void paint(Canvas canvas, Size size) {
    const horizontalPadding = 12.0;
    const verticalPadding = 16.0;
    final width = size.width - (horizontalPadding * 2);
    final height = size.height - (verticalPadding * 2);
    if (width <= 0 || height <= 0) return;

    final chartScale = scale.toDouble();
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var index = 0; index < 4; index += 1) {
      final y = verticalPadding + ((height / 3) * index);
      canvas.drawLine(
        Offset(horizontalPadding, y),
        Offset(horizontalPadding + width, y),
        gridPaint,
      );
    }
    if (hoveredIndex != null && points.isNotEmpty) {
      final index = hoveredIndex!.clamp(0, points.length - 1);
      final ratio = points.length == 1 ? 0.5 : index / (points.length - 1);
      final x = horizontalPadding + (width * ratio);
      canvas.drawLine(
        Offset(x, verticalPadding),
        Offset(x, verticalPadding + height),
        Paint()
          ..color = activeColor.withValues(alpha: 0.45)
          ..strokeWidth = 1,
      );
    }
    _drawSeries(
      canvas,
      points,
      activeColor,
      chartScale,
      width,
      height,
      3,
      isActive: true,
    );
    if (idleColor != null) {
      _drawSeries(
        canvas,
        points,
        idleColor!,
        chartScale,
        width,
        height,
        2,
        isActive: false,
      );
    }
  }

  void _drawSeries(
    Canvas canvas,
    List<_ActivityGraphPoint> points,
    Color color,
    double scale,
    double width,
    double height,
    double strokeWidth, {
    required bool isActive,
  }) {
    const horizontalPadding = 12.0;
    const verticalPadding = 16.0;
    final offsets = List<Offset>.generate(points.length, (index) {
      final ratio = points.length == 1 ? 0.5 : index / (points.length - 1);
      final seconds = isActive
          ? points[index].activeSeconds
          : points[index].idleSeconds;
      return Offset(
        horizontalPadding + (width * ratio),
        verticalPadding + height - ((seconds / scale) * height),
      );
    });
    final path = Path();
    for (var index = 0; index < offsets.length; index += 1) {
      final offset = offsets[index];
      if (index == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        final previous = offsets[index - 1];
        final midpoint = (previous.dx + offset.dx) / 2;
        path.cubicTo(
          midpoint,
          previous.dy,
          midpoint,
          offset.dy,
          offset.dx,
          offset.dy,
        );
      }
    }
    final fillPath = Path.from(path)
      ..lineTo(offsets.last.dx, verticalPadding + height)
      ..lineTo(offsets.first.dx, verticalPadding + height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                color.withValues(alpha: 0.30),
                color.withValues(alpha: 0.12),
              ],
            ).createShader(
              Rect.fromLTWH(horizontalPadding, verticalPadding, width, height),
            ),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ActivityGraphPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.activeColor != activeColor ||
      oldDelegate.idleColor != idleColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.hoveredIndex != hoveredIndex ||
      oldDelegate.scale != scale;
}

int _activityGraphScale(List<_ActivityGraphPoint> points, bool hasIdleSeries) {
  final maximum = points.fold<int>(0, (current, point) {
    final value = hasIdleSeries && point.idleSeconds > point.activeSeconds
        ? point.idleSeconds
        : point.activeSeconds;
    return value > current ? value : current;
  });
  return maximum <= 0 ? 60 : ((maximum + 899) ~/ 900) * 900;
}

String _durationLabel(int seconds) =>
    seconds >= 3600 ? '${seconds ~/ 3600}h' : '${seconds ~/ 60}m';

double _activityGraphTooltipLeft({
  required int? hoveredIndex,
  required int count,
  required double graphWidth,
  required double tooltipWidth,
}) {
  if (hoveredIndex == null || count <= 1 || graphWidth <= tooltipWidth) {
    return 0;
  }
  const horizontalPadding = 12.0;
  final ratio = hoveredIndex / (count - 1);
  final anchor =
      horizontalPadding + ((graphWidth - (horizontalPadding * 2)) * ratio);
  final preferredLeft = anchor - (tooltipWidth / 2);
  final maximumLeft = graphWidth - tooltipWidth;
  return preferredLeft.clamp(0.0, maximumLeft);
}

String _activityGraphDate(DateTime value) {
  const months = <String>[
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
  return '${months[value.month - 1]} ${value.day}';
}

class ActivityWatchSetupPage extends StatefulWidget {
  const ActivityWatchSetupPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ActivityWatchSetupPage> createState() => _ActivityWatchSetupPageState();
}

class _ActivityWatchSetupPageState extends State<ActivityWatchSetupPage> {
  static const int _devicePageSize = 5;

  final _deviceLabel = TextEditingController();
  final _scrollController = ScrollController();
  final _service = ActivityWatchService();
  bool _consented = false;
  bool _submitting = false;
  bool _loading = true;
  String? _credential;
  String? _deviceId;
  String? _loadError;
  bool _configuredAutomatically = false;
  bool _isSuperAdmin = false;
  DateTime? _pairingExpiresAt;
  String? _installerUrl;
  List<ActivityWatchDevice> _devices = const <ActivityWatchDevice>[];
  int _devicePage = 1;
  List<ActivityWatchSummary> _summaries = const <ActivityWatchSummary>[];
  late DateTime _fromDate;
  late DateTime _toDate;
  _ActivityDateFilter _dateFilter = _ActivityDateFilter.month;
  String? _expandedSummaryKey;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _toDate = today;
    _fromDate = DateTime(today.year, today.month);
    _deviceLabel.text = defaultTargetPlatform == TargetPlatform.macOS
        ? 'Mac desktop'
        : defaultTargetPlatform == TargetPlatform.windows
        ? 'Windows desktop'
        : 'Linux desktop';
    _loadStatus();
  }

  @override
  void dispose() {
    _deviceLabel.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String get _platform => switch (defaultTargetPlatform) {
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
    TargetPlatform.linux => 'linux',
    _ => '',
  };

  Future<void> _loadStatus() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final currentUser = await SessionStorage.getCurrentUser();
      final isSuperAdmin =
          currentUser?['is_super_admin'] == true ||
          currentUser?['is_super_admin'] == 1 ||
          currentUser?['is_super_admin'] == '1';
      final companyId = await SessionStorage.getCurrentCompanyId();
      final results = await Future.wait<Object>(<Future<Object>>[
        _service.devices(companyScope: isSuperAdmin, companyId: companyId),
        _loadSummaries(companyScope: isSuperAdmin, companyId: companyId),
      ]);
      if (!mounted) return;
      final summaryPage = results[1] as ActivityWatchSummaryPage;
      setState(() {
        _isSuperAdmin = isSuperAdmin;
        _devices = _uniqueDevices(results[0] as List<ActivityWatchDevice>);
        _devicePage = 1;
        _summaries = _uniqueSummaries(summaryPage.items);
        _expandedSummaryKey = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<ActivityWatchSummaryPage> _loadSummaries({
    required bool companyScope,
    required int? companyId,
  }) async {
    final first = await _service.summaries(
      from: _fromDate,
      to: _toDate,
      page: 1,
      limit: companyScope ? 100 : 31,
      companyScope: companyScope,
      companyId: companyId,
    );
    if (!companyScope || first.lastPage <= 1) return first;

    final items = <ActivityWatchSummary>[...first.items];
    for (var page = 2; page <= first.lastPage; page++) {
      final next = await _service.summaries(
        from: _fromDate,
        to: _toDate,
        page: page,
        limit: 100,
        companyScope: true,
        companyId: companyId,
      );
      items.addAll(next.items);
    }
    return ActivityWatchSummaryPage(
      items: items,
      page: 1,
      lastPage: 1,
      total: items.length,
    );
  }

  Future<void> _enroll() async {
    if (!_consented || _deviceLabel.text.trim().isEmpty || _platform.isEmpty) {
      return;
    }
    setState(() => _submitting = true);
    try {
      if (kIsWeb) {
        final pairing = await _service.createPairingSession(
          deviceLabel: _deviceLabel.text,
          platform: _platform,
          consentVersion: 3,
        );
        final downloaded = await saveTextFile(
          suggestedName:
              'billing-activity-watch-${pairing.deviceId}.billingawpair',
          text: const JsonEncoder.withIndent(
            '  ',
          ).convert(pairing.toBundleJson(platform: _platform)),
          mimeType: 'application/vnd.billing.activity-watch-pairing+json',
        );
        if (!downloaded) {
          throw StateError(
            'The Activity Watch pairing file was not downloaded.',
          );
        }
        if (!mounted) return;
        setState(() {
          _deviceId = pairing.deviceId;
          _credential = null;
          _pairingExpiresAt = pairing.expiresAt;
          _installerUrl = pairing.installerUrl;
        });
        await _loadStatus();
        return;
      }
      final enrollment = await _service.enroll(
        deviceLabel: _deviceLabel.text,
        platform: _platform,
        consentVersion: 3,
      );
      if (!mounted) return;
      setState(() {
        _deviceId = enrollment.deviceId;
        _credential = enrollment.credential;
      });
      try {
        final configured = await ActivityWatchServiceControl.applyEnrollment(
          deviceId: enrollment.deviceId,
          credential: enrollment.credential,
        );
        if (mounted) setState(() => _configuredAutomatically = configured);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Device enrolled, but automatic service configuration failed: $error',
              ),
            ),
          );
        }
      }
      await _loadStatus();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Activity Watch enrollment failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _revoke(ActivityWatchDevice device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Activity Watch device?'),
        content: Text(
          '${device.label} will stop uploading as soon as its current credential is rejected.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.revoke(device.id);
      await _loadStatus();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not revoke device: $error')),
      );
    }
  }

  Future<void> _applyDateFilter(String value) async {
    final selected = _ActivityDateFilter.values.byName(value);
    final today = DateUtils.dateOnly(DateTime.now());
    if (selected == _ActivityDateFilter.custom) {
      final range = await showDialog<DateTimeRange>(
        context: context,
        builder: (context) => ErpDashboardCustomRangeDialog(
          initialRange: DateTimeRange(start: _fromDate, end: _toDate),
          firstDate: DateTime(today.year - 5),
          lastDate: today,
        ),
      );
      if (range == null || !mounted) {
        if (mounted) setState(() {});
        return;
      }
      setState(() {
        _dateFilter = selected;
        _fromDate = DateUtils.dateOnly(range.start);
        _toDate = DateUtils.dateOnly(range.end);
      });
      await _loadStatus();
      return;
    }

    setState(() {
      _dateFilter = selected;
      _toDate = today;
      _fromDate = switch (selected) {
        _ActivityDateFilter.today => today,
        _ActivityDateFilter.month => DateTime(today.year, today.month),
        _ActivityDateFilter.year => DateTime(today.year),
        _ActivityDateFilter.custom => _fromDate,
      };
    });
    await _loadStatus();
  }

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(AppUiConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildSummaryCard(),
          const SizedBox(height: AppUiConstants.spacingXl),
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildConnectivitySection(),
                  if (_credential != null) ...<Widget>[
                    const SizedBox(height: AppUiConstants.spacingXl),
                    _buildCredentialCard(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
    return widget.embedded
        ? ShellPageActions(actions: const <Widget>[], child: content)
        : AppStandaloneShell(
            title: 'Activity Watch',
            scrollController: _scrollController,
            actions: const <Widget>[],
            child: content,
          );
  }

  Widget _buildConnectivitySection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasPairing = _pairingExpiresAt != null;
        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildEnrollmentCard(),
              const SizedBox(height: AppUiConstants.spacingXl),
              _buildDevicesCard(),
              if (hasPairing) ...<Widget>[
                const SizedBox(height: AppUiConstants.spacingXl),
                _buildPairingCard(),
              ],
            ],
          );
        }

        if (hasPairing && constraints.maxWidth >= 1120) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _buildEnrollmentCard()),
              const SizedBox(width: AppUiConstants.spacingXl),
              Expanded(child: _buildDevicesCard()),
              const SizedBox(width: AppUiConstants.spacingXl),
              Expanded(child: _buildPairingCard()),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: _buildEnrollmentCard()),
                const SizedBox(width: AppUiConstants.spacingXl),
                Expanded(child: _buildDevicesCard()),
              ],
            ),
            if (hasPairing) ...<Widget>[
              const SizedBox(height: AppUiConstants.spacingXl),
              _buildPairingCard(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildEnrollmentCard() {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Connect a computer',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          const Text(
            'Tracks sampled keyboard/mouse time, foreground app and browser titles, and bounded background process names. No keys, clicks, coordinates, URLs, screenshots, clipboard, or page content are collected.',
          ),
          const SizedBox(height: AppUiConstants.spacingLg),
          AppFormTextField(controller: _deviceLabel, labelText: 'Device label'),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _consented,
            onChanged: _submitting
                ? null
                : (value) => setState(() => _consented = value ?? false),
            title: const Text(
              'I consent to managed office-device monitoring, including USB device and removable-file metadata.',
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _submitting || !_consented || _platform.isEmpty
                  ? null
                  : _enroll,
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.shield_outlined),
              label: Text(
                _submitting
                    ? 'Preparing…'
                    : kIsWeb
                    ? 'Connect this computer'
                    : 'Enroll this device',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPairingCard() {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Complete setup',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          const Text(
            'Install the agent once, then open the downloaded pairing file.',
          ),
          if (_installerUrl != null && _installerUrl!.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppUiConstants.spacingSm),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => openExternalUrl(_installerUrl!),
                icon: const Icon(Icons.download_outlined),
                label: Text('Download ${_platformLabel(_platform)} agent'),
              ),
            ),
          ],
          const SizedBox(height: AppUiConstants.spacingSm),
          Text('Expires ${_dateTime(_pairingExpiresAt)}.'),
        ],
      ),
    );
  }

  Widget _buildCredentialCard() {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'One-time service credential',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          const Text(
            'Save this in the protected Go service credential file. It will not be shown again after this page is closed.',
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          SelectableText('Device ID: $_deviceId\nCredential: $_credential'),
          if (_configuredAutomatically) ...<Widget>[
            const SizedBox(height: AppUiConstants.spacingSm),
            const Text(
              'The protected credential file and local service configuration were updated automatically. Restart the agent to use this enrollment.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDevicesCard() {
    final visibleDevices = _pagedDevices;

    return AppSectionCard(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Devices',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loading ? null : _loadStatus,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (_loading) const LinearProgressIndicator(),
            if (_loadError != null)
              Padding(
                padding: const EdgeInsets.only(top: AppUiConstants.spacingSm),
                child: Text('Could not load devices: $_loadError'),
              )
            else if (!_loading && _devices.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: AppUiConstants.spacingSm),
                child: Text('No connected computers.'),
              )
            else
              ...visibleDevices.map(
                (device) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    device.isActive
                        ? device.isPaired
                              ? Icons.desktop_windows_outlined
                              : Icons.pending_outlined
                        : Icons.desktop_access_disabled_outlined,
                  ),
                  title: Text(device.label),
                  subtitle: Text(device.connectionStatus),
                  trailing: device.isActive
                      ? TextButton(
                          onPressed: () => _revoke(device),
                          child: const Text('Disconnect'),
                        )
                      : null,
                ),
              ),
            LocalPageNavigation(
              totalItems: _devices.length,
              currentPage: _devicePage,
              pageSize: _devicePageSize,
              onPageChanged: (page) => setState(() => _devicePage = page),
            ),
          ],
        ),
      ),
    );
  }

  List<ActivityWatchDevice> get _pagedDevices {
    final start = (_devicePage - 1) * _devicePageSize;
    if (start >= _devices.length) return const <ActivityWatchDevice>[];
    final end = (start + _devicePageSize).clamp(0, _devices.length).toInt();
    return _devices.sublist(start, end);
  }

  Widget _buildSummaryCard() {
    if (_loading) {
      return const AppSectionCard(
        child: AppLoadingView(message: 'Loading activity dashboard...'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ErpModuleDashboard(
          snapshot: _buildActivityDashboardSnapshot(),
          showHeader: false,
        ),
      ],
    );
  }

  ErpDashboardSnapshot _buildActivityDashboardSnapshot() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final employeeOptions = _employeeFilterOptions();

    return ErpDashboardSnapshot(
      title: 'Activity dashboard',
      subtitle:
          'Privacy-safe device activity from ${_date(_fromDate)} to ${_date(_toDate)}.',
      actions: const <ErpDashboardAction>[],
      stats: const <ErpDashboardStat>[],
      primarySections: _summaries.isEmpty
          ? const <ErpDashboardListSection>[]
          : <ErpDashboardListSection>[
              ErpDashboardListSection(
                title: 'Recent daily activity',
                subtitle: 'Select a record to open complete activity details',
                icon: Icons.history_outlined,
                maxVisibleItems: 6,
                filterOptions: _dateFilterOptions(),
                initialFilterValue: _dateFilter.name,
                onFilterChanged: _applyDateFilter,
                secondaryFilterOptions: _isSuperAdmin
                    ? employeeOptions
                    : const <ErpDashboardListFilterOption>[],
                items: _summaries
                    .map(
                      (summary) => ErpDashboardListItem(
                        title: summary.employeeName?.trim().isNotEmpty == true
                            ? summary.employeeName!.trim()
                            : summary.deviceLabel,
                        subtitle:
                            '${summary.deviceLabel} - ${_date(summary.workDate)}',
                        detail:
                            'Active ${_duration(summary.activeSeconds)} · Idle ${_duration(summary.idleSeconds)} · Browser ${_duration(summary.browserSeconds)}',
                        statusLabel:
                            '${_duration(summary.trackedSeconds)} tracked',
                        statusColor: colors.primary,
                        filterTags: _ActivityDateFilter.values
                            .map((filter) => filter.name)
                            .toList(growable: false),
                        secondaryFilterTags: <String>[
                          _employeeFilterValue(summary),
                        ],
                        onPressed: () => _toggleSummaryDetails(summary),
                        expandedContent:
                            _summaryKey(summary) == _expandedSummaryKey
                            ? _buildExpandedSummaryDetails(summary)
                            : null,
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
      distribution: null,
      highlights: null,
      emptyTitle: 'No activity found',
      emptyMessage:
          'Try a different date range or confirm that a connected device is reporting.',
    );
  }

  List<ErpDashboardListFilterOption> _employeeFilterOptions() {
    final employees = <String, String>{};
    for (final summary in _summaries) {
      final label = summary.employeeName?.trim().isNotEmpty == true
          ? summary.employeeName!.trim()
          : summary.employeeCode?.trim().isNotEmpty == true
          ? summary.employeeCode!.trim()
          : 'Unassigned employee';
      employees[_employeeFilterValue(summary)] = label;
    }
    final options = employees.entries.toList()
      ..sort((left, right) => left.value.compareTo(right.value));
    return <ErpDashboardListFilterOption>[
      const ErpDashboardListFilterOption(value: '', label: 'All employees'),
      ...options.map(
        (entry) =>
            ErpDashboardListFilterOption(value: entry.key, label: entry.value),
      ),
    ];
  }

  List<ErpDashboardListFilterOption> _dateFilterOptions() => _ActivityDateFilter
      .values
      .map(
        (filter) => ErpDashboardListFilterOption(
          value: filter.name,
          label: _dateFilterLabel(filter),
        ),
      )
      .toList(growable: false);

  Widget _buildSelectedMetrics(ActivityWatchSummary summary) {
    final timeline = _deviceActivityTrend(summary.deviceId);
    final graphs = <Widget>[
      _ActivityGraph(
        title: 'Active and idle time',
        activeLabel: 'Active time',
        idleLabel: 'Idle time',
        activeColor: _activityGraphGreen,
        idleColor: _activityGraphRed,
        points: _graphPoints(
          timeline,
          (point) => point.activeSeconds,
          (point) => point.idleSeconds,
        ),
      ),
      _ActivityGraph(
        title: 'Keyboard activity',
        activeLabel: 'Keyboard active',
        idleLabel: 'Keyboard idle',
        activeColor: _activityGraphGreen,
        idleColor: _activityGraphRed,
        points: _graphPoints(
          timeline,
          (point) => point.keyboardActiveSeconds,
          (point) => point.keyboardIdleSeconds,
        ),
      ),
      _ActivityGraph(
        title: 'Mouse activity',
        activeLabel: 'Mouse active',
        idleLabel: 'Mouse idle',
        activeColor: _activityGraphGreen,
        idleColor: _activityGraphRed,
        points: _graphPoints(
          timeline,
          (point) => point.mouseActiveSeconds,
          (point) => point.mouseIdleSeconds,
        ),
      ),
      _ActivityGraph(
        title: 'Browser time',
        activeLabel: 'Browser time',
        activeColor: _activityGraphGreen,
        points: _graphPoints(timeline, (point) => point.browserSeconds),
      ),
      _ActivityGraph(
        title: 'Locked time',
        activeLabel: 'Locked time',
        activeColor: _activityGraphGreen,
        points: _graphPoints(timeline, (point) => point.lockedSeconds),
      ),
      _ActivityGraph(
        title: 'Untracked time',
        activeLabel: 'Untracked time',
        activeColor: _activityGraphGreen,
        points: _graphPoints(timeline, (point) => point.untrackedSeconds),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final graphWidth = wide
            ? (constraints.maxWidth - AppUiConstants.spacingLg) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: AppUiConstants.spacingLg,
          runSpacing: AppUiConstants.spacingLg,
          children: graphs
              .map((graph) => SizedBox(width: graphWidth, child: graph))
              .toList(growable: false),
        );
      },
    );
  }

  List<_DeviceActivityPoint> _deviceActivityTrend(String deviceId) {
    final byDate =
        <
          DateTime,
          (
            int active,
            int idle,
            int keyboardActive,
            int keyboardIdle,
            int mouseActive,
            int mouseIdle,
            int browser,
            int locked,
            int untracked,
          )
        >{};
    for (final item in _summaries) {
      if (item.deviceId != deviceId) continue;
      final date = DateUtils.dateOnly(item.workDate);
      final totals = byDate[date] ?? (0, 0, 0, 0, 0, 0, 0, 0, 0);
      byDate[date] = (
        totals.$1 + item.activeSeconds,
        totals.$2 + item.idleSeconds,
        totals.$3 + item.keyboardActiveSeconds,
        totals.$4 + item.keyboardIdleSeconds,
        totals.$5 + item.mouseActiveSeconds,
        totals.$6 + item.mouseIdleSeconds,
        totals.$7 + item.browserSeconds,
        totals.$8 + item.lockedSeconds,
        totals.$9 + item.unknownSeconds,
      );
    }
    final points =
        byDate.entries
            .map(
              (entry) => _DeviceActivityPoint(
                date: entry.key,
                activeSeconds: entry.value.$1,
                idleSeconds: entry.value.$2,
                keyboardActiveSeconds: entry.value.$3,
                keyboardIdleSeconds: entry.value.$4,
                mouseActiveSeconds: entry.value.$5,
                mouseIdleSeconds: entry.value.$6,
                browserSeconds: entry.value.$7,
                lockedSeconds: entry.value.$8,
                untrackedSeconds: entry.value.$9,
              ),
            )
            .toList(growable: false)
          ..sort((left, right) => left.date.compareTo(right.date));
    return points.length <= 12 ? points : points.sublist(points.length - 12);
  }

  List<_ActivityGraphPoint> _graphPoints(
    List<_DeviceActivityPoint> timeline,
    int Function(_DeviceActivityPoint point) active, [
    int Function(_DeviceActivityPoint point)? idle,
  ]) => timeline
      .map(
        (point) => _ActivityGraphPoint(
          date: point.date,
          activeSeconds: active(point),
          idleSeconds: idle?.call(point) ?? 0,
        ),
      )
      .toList(growable: false);

  Widget _buildActivityTableSurface(Widget table) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    return LayoutBuilder(
      builder: (context, constraints) => DecoratedBox(
        decoration: BoxDecoration(
          color: appTheme.cardBackground,
          border: Border.all(color: appTheme.tableBorder),
          borderRadius: BorderRadius.circular(AppUiConstants.tableRadiusSm),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppUiConstants.tableRadiusSm),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: _buildActivityTableTheme(table),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTableTheme(Widget child) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;

    return Theme(
      data: theme.copyWith(
        dividerColor: appTheme.tableBorder,
        dataTableTheme: DataTableThemeData(
          headingRowColor: WidgetStatePropertyAll(
            appTheme.tableHeaderBackground,
          ),
          dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.selected)) {
              return appTheme.tableRowSelected;
            }
            if (states.contains(WidgetState.hovered)) {
              return appTheme.tableRowHover;
            }
            return appTheme.cardBackground;
          }),
          headingTextStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: appTheme.tableTitleText,
          ),
          dataTextStyle: theme.textTheme.bodySmall?.copyWith(
            color: appTheme.tableCellText,
          ),
        ),
      ),
      child: child,
    );
  }

  Widget _buildApplicationTable(ActivityWatchSummary summary) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: appTheme.subtleFill,
        border: Border.all(color: appTheme.tableBorder),
        borderRadius: BorderRadius.circular(AppUiConstants.tableRadiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppUiConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.apps_outlined,
                  size: 20,
                  color: appTheme.tableLinkText,
                ),
                const SizedBox(width: AppUiConstants.spacingXs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Application activity',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppUiConstants.spacingXxs),
                      Text(
                        '${_date(summary.workDate)} · ${summary.deviceLabel}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: appTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            if (summary.applications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: AppUiConstants.spacingMd,
                ),
                child: Text('No application totals for this day.'),
              )
            else
              _buildActivityTableSurface(
                DataTable(
                  headingRowHeight: 44,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 48,
                  horizontalMargin: AppUiConstants.spacingMd,
                  columnSpacing: AppUiConstants.spacingLg,
                  columns: const <DataColumn>[
                    DataColumn(label: Text('Application')),
                    DataColumn(label: Text('Category')),
                    DataColumn(label: Text('Duration'), numeric: true),
                  ],
                  rows: _uniqueApplications(summary.applications)
                      .map(
                        (application) => DataRow(
                          cells: <DataCell>[
                            DataCell(Text(application.name)),
                            DataCell(Text(application.classification)),
                            DataCell(Text(_duration(application.seconds))),
                          ],
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleSummaryDetails(ActivityWatchSummary summary) {
    final key = _summaryKey(summary);
    setState(() {
      _expandedSummaryKey = _expandedSummaryKey == key ? null : key;
    });
  }

  Widget _buildExpandedSummaryDetails(ActivityWatchSummary summary) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppUiConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.insights_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppUiConstants.spacingXs),
                Expanded(
                  child: Text(
                    'Full activity details',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  _date(summary.workDate),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).extension<AppThemeExtension>()!.mutedText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            _buildSelectedMetrics(summary),
            const SizedBox(height: AppUiConstants.spacingMd),
            _buildApplicationTable(summary),
            const SizedBox(height: AppUiConstants.spacingMd),
            _buildBrowserTitleTable(summary),
            const SizedBox(height: AppUiConstants.spacingMd),
            _buildBackgroundApplicationList(summary),
            const SizedBox(height: AppUiConstants.spacingMd),
            _buildUsbDetails(summary),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowserTitleTable(ActivityWatchSummary summary) {
    return _buildDetailListSection(
      icon: Icons.tab_outlined,
      title: 'Browser tab titles',
      subtitle: 'Foreground browser titles only; URLs are never collected',
      emptyMessage: 'No browser tab titles reported for this day.',
      child: summary.browserTitles.isEmpty
          ? null
          : _buildActivityTableSurface(
              DataTable(
                headingRowHeight: 44,
                dataRowMinHeight: 44,
                dataRowMaxHeight: 56,
                columns: const <DataColumn>[
                  DataColumn(label: Text('Tab title')),
                  DataColumn(label: Text('Duration'), numeric: true),
                ],
                rows: _uniqueBrowserTitles(summary.browserTitles)
                    .map(
                      (item) => DataRow(
                        cells: <DataCell>[
                          DataCell(Text(item.title)),
                          DataCell(Text(_duration(item.seconds))),
                        ],
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
    );
  }

  Widget _buildBackgroundApplicationList(ActivityWatchSummary summary) {
    final applications = _uniqueBackgroundApplications(
      summary.backgroundApplications,
    );
    return _buildDetailListSection(
      icon: Icons.memory_outlined,
      title: 'Background applications',
      subtitle: 'Latest bounded process inventory for this device and day',
      emptyMessage: 'No background application inventory reported.',
      child: applications.isEmpty
          ? null
          : Wrap(
              spacing: AppUiConstants.spacingXs,
              runSpacing: AppUiConstants.spacingXs,
              children: applications
                  .map(
                    (item) => Chip(
                      avatar: const Icon(Icons.circle, size: 9),
                      label: Text(
                        (item.state ?? '').trim().isEmpty
                            ? item.name
                            : '${item.name} · ${item.state}',
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }

  Widget _buildUsbDetails(ActivityWatchSummary summary) {
    final hasData =
        summary.usbTotalPorts > 0 ||
        summary.usbUsedPorts > 0 ||
        summary.usbDevices.isNotEmpty ||
        summary.usbFileEvents.isNotEmpty;
    return _buildDetailListSection(
      icon: Icons.usb_outlined,
      title: 'USB activity',
      subtitle:
          'Best-effort port status and observed removable-file metadata; file contents are never collected',
      emptyMessage: 'No USB metadata reported for this day.',
      child: !hasData
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  '${summary.usbUsedPorts} used / ${summary.usbTotalPorts} total ports',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (summary.usbDevices.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppUiConstants.spacingSm),
                  _buildActivityTableSurface(
                    DataTable(
                      columns: const <DataColumn>[
                        DataColumn(label: Text('Device')),
                        DataColumn(label: Text('Drive')),
                        DataColumn(label: Text('Storage')),
                        DataColumn(label: Text('Observed')),
                      ],
                      rows: summary.usbDevices
                          .map(
                            (device) => DataRow(
                              cells: <DataCell>[
                                DataCell(
                                  Text(
                                    '${device.name} · ${device.connected ? 'Connected' : 'Disconnected'}',
                                  ),
                                ),
                                DataCell(Text(device.driveLetter ?? '—')),
                                DataCell(
                                  Text(
                                    device.capacityBytes <= 0
                                        ? '—'
                                        : '${_bytes(device.capacityBytes - device.freeBytes)} / ${_bytes(device.capacityBytes)}',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    _duration(device.observedDurationSeconds),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ],
                if (summary.usbFileEvents.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppUiConstants.spacingSm),
                  Text(
                    'Observed file changes',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  _buildActivityTableSurface(
                    DataTable(
                      columns: const <DataColumn>[
                        DataColumn(label: Text('Action')),
                        DataColumn(label: Text('File')),
                        DataColumn(label: Text('Drive')),
                        DataColumn(label: Text('Size'), numeric: true),
                      ],
                      rows: summary.usbFileEvents
                          .map(
                            (event) => DataRow(
                              cells: <DataCell>[
                                DataCell(Text(event.operation)),
                                DataCell(
                                  Tooltip(
                                    message: event.relativePath,
                                    child: Text(event.name),
                                  ),
                                ),
                                DataCell(Text(event.driveLetter)),
                                DataCell(
                                  Text(
                                    event.sizeBytes > 0
                                        ? _bytes(event.sizeBytes)
                                        : '—',
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ],
                if (summary.usbFilesTruncated) ...<Widget>[
                  const SizedBox(height: AppUiConstants.spacingXs),
                  const Text(
                    'Some USB file metadata was omitted because the safety limit was reached.',
                  ),
                ],
              ],
            ),
    );
  }

  static String _employeeFilterValue(ActivityWatchSummary summary) {
    final employeeId = summary.employeeId;
    if (employeeId != null) return 'employee:$employeeId';
    final ownerUserId = summary.ownerUserId;
    if (ownerUserId != null) return 'user:$ownerUserId';
    return 'unassigned';
  }

  String _bytes(int value) {
    if (value < 1024) return '$value B';
    final kib = value / 1024;
    if (kib < 1024) return '${kib.toStringAsFixed(1)} KB';
    final mib = kib / 1024;
    if (mib < 1024) return '${mib.toStringAsFixed(1)} MB';
    return '${(mib / 1024).toStringAsFixed(1)} GB';
  }

  Widget _buildDetailListSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required String emptyMessage,
    required Widget? child,
  }) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: appTheme.subtleFill,
        border: Border.all(color: appTheme.tableBorder),
        borderRadius: BorderRadius.circular(AppUiConstants.tableRadiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppUiConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, color: appTheme.tableLinkText),
                const SizedBox(width: AppUiConstants.spacingXs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: appTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            child ?? Text(emptyMessage),
          ],
        ),
      ),
    );
  }

  static String _summaryKey(ActivityWatchSummary summary) =>
      '${summary.deviceId}:${_date(summary.workDate)}';

  List<ActivityWatchSummary> _uniqueSummaries(
    List<ActivityWatchSummary> summaries,
  ) {
    final byKey = <String, ActivityWatchSummary>{};
    for (final summary in summaries) {
      byKey[_summaryKey(summary)] = summary;
    }
    final unique = byKey.values.toList(growable: false);
    return unique
      ..sort((left, right) => right.workDate.compareTo(left.workDate));
  }

  List<ActivityWatchDevice> _uniqueDevices(List<ActivityWatchDevice> devices) {
    final byKey = <String, ActivityWatchDevice>{};
    for (final device in devices) {
      final key =
          '${device.label.trim().toLowerCase()}|'
          '${device.platform.trim().toLowerCase()}|${device.connectionStatus}';
      final previous = byKey[key];
      if (previous == null ||
          _deviceDate(device).isAfter(_deviceDate(previous))) {
        byKey[key] = device;
      }
    }
    final unique = byKey.values.toList(growable: false);
    unique.sort((left, right) {
      if (left.isActive != right.isActive) return left.isActive ? -1 : 1;
      return _deviceDate(right).compareTo(_deviceDate(left));
    });
    return unique;
  }

  static DateTime _deviceDate(ActivityWatchDevice device) =>
      device.lastSeenAt ?? device.pairedAt ?? device.consentedAt;

  static List<ActivityWatchApplicationTotal> _uniqueApplications(
    List<ActivityWatchApplicationTotal> applications,
  ) {
    final totals = <String, ActivityWatchApplicationTotal>{};
    for (final application in applications) {
      final key =
          '${application.name.trim().toLowerCase()}|'
          '${application.classification.trim().toLowerCase()}';
      final previous = totals[key];
      totals[key] = previous == null
          ? application
          : ActivityWatchApplicationTotal(
              name: previous.name,
              classification: previous.classification,
              seconds: previous.seconds + application.seconds,
            );
    }
    return totals.values.toList(growable: false);
  }

  static List<ActivityWatchBrowserTitleTotal> _uniqueBrowserTitles(
    List<ActivityWatchBrowserTitleTotal> titles,
  ) {
    final totals = <String, ActivityWatchBrowserTitleTotal>{};
    for (final title in titles) {
      final key = title.title.trim().toLowerCase();
      final previous = totals[key];
      totals[key] = previous == null
          ? title
          : ActivityWatchBrowserTitleTotal(
              title: previous.title,
              seconds: previous.seconds + title.seconds,
            );
    }
    return totals.values.toList(growable: false);
  }

  static List<ActivityWatchBackgroundApplication> _uniqueBackgroundApplications(
    List<ActivityWatchBackgroundApplication> applications,
  ) {
    final unique = <String, ActivityWatchBackgroundApplication>{};
    for (final application in applications) {
      final key =
          '${application.name.trim().toLowerCase()}|'
          '${(application.state ?? '').trim().toLowerCase()}';
      unique[key] = application;
    }
    return unique.values.toList(growable: false);
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static String _dateFilterLabel(_ActivityDateFilter filter) =>
      switch (filter) {
        _ActivityDateFilter.today => 'Today',
        _ActivityDateFilter.month => 'This month',
        _ActivityDateFilter.year => 'This year',
        _ActivityDateFilter.custom => 'Custom range',
      };

  static String _dateTime(DateTime? value) {
    if (value == null) return 'never';
    final local = value.toLocal();
    return '${_date(local)} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  static String _duration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  static String _platformLabel(String platform) => switch (platform) {
    'macos' => 'macOS',
    'windows' => 'Windows',
    'linux' => 'Linux',
    _ => 'desktop',
  };
}
