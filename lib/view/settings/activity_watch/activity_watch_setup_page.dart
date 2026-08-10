import '../../../screen.dart';
import '../../../model/activity_watch_enrollment.dart';
import '../../../service/activity_watch/activity_watch_service.dart';
import '../../../core/activity_watch/service/activity_watch_service_control.dart';
import '../../../core/files/external_url.dart';
import 'activity_watch_dashboard_metrics.dart';

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
  String? _expandedSummaryKey;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _toDate = today;
    _fromDate = today.subtract(const Duration(days: 30));
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
      final results = await Future.wait<Object>(<Future<Object>>[
        _service.devices(),
        _service.summaries(from: _fromDate, to: _toDate),
      ]);
      if (!mounted) return;
      final currentUser = await SessionStorage.getCurrentUser();
      final summaryPage = results[1] as ActivityWatchSummaryPage;
      setState(() {
        _isSuperAdmin =
            currentUser?['is_super_admin'] == true ||
            currentUser?['is_super_admin'] == 1;
        _devices = results[0] as List<ActivityWatchDevice>;
        _devicePage = 1;
        _summaries = summaryPage.items;
        _expandedSummaryKey = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
          consentVersion: 2,
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
        consentVersion: 2,
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

  Future<void> _pickDate({required bool from}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: from ? _fromDate : _toDate,
      firstDate: DateUtils.dateOnly(
        DateTime.now().subtract(const Duration(days: 90)),
      ),
      lastDate: DateUtils.dateOnly(DateTime.now()),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (from) {
        _fromDate = selected;
        if (_fromDate.isAfter(_toDate)) _toDate = _fromDate;
      } else {
        _toDate = selected;
        if (_toDate.isBefore(_fromDate)) _fromDate = _toDate;
      }
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
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Text(
                'Activity Watch',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingXl),
          _buildSummaryCard(),
          const SizedBox(height: AppUiConstants.spacingXl),
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildEnrollmentAndDevicesRow(),
                  if (_pairingExpiresAt != null) ...<Widget>[
                    const SizedBox(height: AppUiConstants.spacingXl),
                    _buildPairingCard(),
                  ],
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

  Widget _buildEnrollmentAndDevicesRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildEnrollmentCard(),
              const SizedBox(height: AppUiConstants.spacingXl),
              _buildDevicesCard(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: _buildEnrollmentCard()),
            const SizedBox(width: AppUiConstants.spacingXl),
            Expanded(child: _buildDevicesCard()),
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
            title: const Text('I consent to managed office-device monitoring.'),
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
        ErpModuleDashboard(snapshot: _buildActivityDashboardSnapshot()),
      ],
    );
  }

  ErpDashboardSnapshot _buildActivityDashboardSnapshot() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final appTheme = theme.extension<AppThemeExtension>()!;
    final metrics = ActivityWatchDashboardMetrics.fromSummaries(_summaries);
    final dailyTrend = metrics.dailyActive.length <= 12
        ? metrics.dailyActive
        : metrics.dailyActive.sublist(metrics.dailyActive.length - 12);
    final employeeOptions = _employeeFilterOptions();

    return ErpDashboardSnapshot(
      title: 'Activity dashboard',
      subtitle:
          'Privacy-safe device activity from ${_date(_fromDate)} to ${_date(_toDate)}.',
      actions: <ErpDashboardAction>[
        ErpDashboardAction(
          label: 'From ${_date(_fromDate)}',
          icon: Icons.calendar_today_outlined,
          onPressed: () => _pickDate(from: true),
        ),
        ErpDashboardAction(
          label: 'To ${_date(_toDate)}',
          icon: Icons.event_outlined,
          onPressed: () => _pickDate(from: false),
        ),
      ],
      stats: _summaries.isEmpty
          ? const <ErpDashboardStat>[]
          : <ErpDashboardStat>[
              ErpDashboardStat(
                label: 'Active time',
                value: _duration(metrics.activeSeconds),
                helper: 'Focused foreground activity',
                icon: Icons.bolt_outlined,
                color: colors.primary,
              ),
              ErpDashboardStat(
                label: 'Idle time',
                value: _duration(metrics.idleSeconds),
                helper: 'No recent input activity',
                icon: Icons.hourglass_empty_outlined,
                color: colors.tertiary,
              ),
              ErpDashboardStat(
                label: 'Browser time',
                value: _duration(metrics.browserSeconds),
                helper: 'Category-only browser usage',
                icon: Icons.language_outlined,
                color: colors.secondary,
              ),
              ErpDashboardStat(
                label: 'Tracked time',
                value: _duration(metrics.trackedSeconds),
                helper: 'Total reported device duration',
                icon: Icons.schedule_outlined,
                color: appTheme.tableLinkText,
              ),
            ],
      primarySections: _summaries.isEmpty
          ? const <ErpDashboardListSection>[]
          : <ErpDashboardListSection>[
              ErpDashboardListSection(
                title: 'Recent daily activity',
                subtitle: 'Select a record to open complete activity details',
                icon: Icons.history_outlined,
                maxVisibleItems: 6,
                secondaryFilterOptions: _isSuperAdmin
                    ? employeeOptions
                    : const <ErpDashboardListFilterOption>[],
                items: _summaries
                    .map(
                      (summary) => ErpDashboardListItem(
                        title: summary.deviceLabel,
                        subtitle: _date(summary.workDate),
                        detail:
                            'Active ${_duration(summary.activeSeconds)} · Idle ${_duration(summary.idleSeconds)} · Browser ${_duration(summary.browserSeconds)}',
                        statusLabel:
                            '${_duration(summary.trackedSeconds)} tracked',
                        statusColor: colors.primary,
                        secondaryFilterTags: summary.employeeId == null
                            ? const <String>['unassigned']
                            : <String>['employee:${summary.employeeId}'],
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
      trend: _summaries.isEmpty
          ? null
          : ErpDashboardTrendCardData(
              title: 'Active time trend',
              subtitle: metrics.dailyActive.length > 12
                  ? 'Active minutes for the latest 12 reporting days'
                  : 'Active minutes by day',
              color: colors.primary,
              points: dailyTrend
                  .map(
                    (point) => ErpDashboardTrendPoint(
                      label: _shortDate(point.date),
                      value: point.activeSeconds / 60,
                    ),
                  )
                  .toList(growable: false),
            ),
      distribution: null,
      highlights: _summaries.isEmpty
          ? null
          : ErpDashboardHighlightsCardData(
              title: 'Highlights',
              subtitle: 'Additional privacy-safe report totals',
              entries: <ErpDashboardHighlightEntry>[
                ErpDashboardHighlightEntry(
                  label: 'Input activity',
                  value: _duration(metrics.inputSeconds),
                  helper: 'Aggregate sampled input time',
                  color: colors.primary,
                ),
                ErpDashboardHighlightEntry(
                  label: 'Devices',
                  value: '${metrics.deviceCount}',
                  helper: 'Devices represented in this report',
                  color: colors.secondary,
                ),
                ErpDashboardHighlightEntry(
                  label: 'Applications',
                  value: '${metrics.applicationCount}',
                  helper: 'Unique foreground application names',
                  color: colors.tertiary,
                ),
                ErpDashboardHighlightEntry(
                  label: 'Offline time',
                  value: _duration(metrics.offlineSeconds),
                  helper: 'Reported disconnected duration',
                  color: colors.error,
                ),
              ],
            ),
      emptyTitle: 'No activity found',
      emptyMessage:
          'Try a different date range or confirm that a connected device is reporting.',
    );
  }

  List<ErpDashboardListFilterOption> _employeeFilterOptions() {
    final employees = <String, String>{};
    for (final summary in _summaries) {
      final id = summary.employeeId;
      final label = summary.employeeName?.trim().isNotEmpty == true
          ? summary.employeeName!.trim()
          : summary.employeeCode?.trim().isNotEmpty == true
          ? summary.employeeCode!.trim()
          : 'Unassigned employee';
      employees[id == null ? 'unassigned' : 'employee:$id'] = label;
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

  Widget _buildSelectedMetrics(ActivityWatchSummary summary) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    final entries = <(String, String, IconData, Color)>[
      (
        'Active time',
        _duration(summary.activeSeconds),
        Icons.bolt_outlined,
        theme.colorScheme.primary,
      ),
      (
        'Idle time',
        _duration(summary.idleSeconds),
        Icons.hourglass_empty_outlined,
        theme.colorScheme.tertiary,
      ),
      (
        'Keyboard active',
        _duration(summary.keyboardActiveSeconds),
        Icons.keyboard_alt_outlined,
        theme.colorScheme.secondary,
      ),
      (
        'Keyboard idle',
        _duration(summary.keyboardIdleSeconds),
        Icons.keyboard_hide_outlined,
        appTheme.mutedText,
      ),
      (
        'Mouse active',
        _duration(summary.mouseActiveSeconds),
        Icons.mouse_outlined,
        theme.colorScheme.primary,
      ),
      (
        'Mouse idle',
        _duration(summary.mouseIdleSeconds),
        Icons.hourglass_disabled_outlined,
        appTheme.mutedText,
      ),
      (
        'Browser time',
        _duration(summary.browserSeconds),
        Icons.language_outlined,
        appTheme.tableLinkText,
      ),
      (
        'Locked time',
        _duration(summary.lockedSeconds),
        Icons.lock_outline,
        theme.colorScheme.error,
      ),
      (
        'Offline time',
        _duration(summary.offlineSeconds),
        Icons.cloud_off_outlined,
        theme.colorScheme.error,
      ),
      (
        'Unknown time',
        _duration(summary.unknownSeconds),
        Icons.help_outline,
        appTheme.mutedText,
      ),
      (
        'Tracked time',
        _duration(summary.trackedSeconds),
        Icons.schedule_outlined,
        appTheme.tableLinkText,
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: appTheme.cardBackground,
        border: Border.all(color: appTheme.tableBorder),
        borderRadius: BorderRadius.circular(AppUiConstants.tableRadiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppUiConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Daily activity metrics',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingXxs),
            Text(
              'Sampled activity durations only; no keys, clicks, coordinates, URLs, or screenshots are collected.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: appTheme.mutedText,
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingSm),
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingSm,
              children: entries
                  .map(
                    (entry) => SizedBox(
                      width: 154,
                      child: _buildMetricTile(
                        label: entry.$1,
                        value: entry.$2,
                        icon: entry.$3,
                        color: entry.$4,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final appTheme = theme.extension<AppThemeExtension>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: appTheme.subtleFill,
        borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
        border: Border.all(color: appTheme.tableBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppUiConstants.spacingSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 20, color: color),
            const SizedBox(height: AppUiConstants.spacingXs),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: appTheme.tableTitleText,
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingXxs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: appTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                  rows: summary.applications
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
                rows: summary.browserTitles
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
    final applications = summary.backgroundApplications;
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

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static String _shortDate(DateTime value) => '${value.month}/${value.day}';

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
