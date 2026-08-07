import '../../../screen.dart';
import '../../../model/activity_watch_enrollment.dart';
import '../../../service/activity_watch/activity_watch_service.dart';
import '../../../core/activity_watch/service/activity_watch_service_control.dart';
import '../../../core/files/external_url.dart';

class ActivityWatchSetupPage extends StatefulWidget {
  const ActivityWatchSetupPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ActivityWatchSetupPage> createState() => _ActivityWatchSetupPageState();
}

class _ActivityWatchSetupPageState extends State<ActivityWatchSetupPage> {
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
  DateTime? _pairingExpiresAt;
  String? _installerUrl;
  List<ActivityWatchDevice> _devices = const <ActivityWatchDevice>[];
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
      final summaryPage = results[1] as ActivityWatchSummaryPage;
      setState(() {
        _devices = results[0] as List<ActivityWatchDevice>;
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
          consentVersion: 1,
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
        consentVersion: 1,
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
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Activity Watch',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppUiConstants.spacingXl),
              _buildEnrollmentCard(),
              if (_pairingExpiresAt != null) ...<Widget>[
                const SizedBox(height: AppUiConstants.spacingXl),
                _buildPairingCard(),
              ],
              if (_credential != null) ...<Widget>[
                const SizedBox(height: AppUiConstants.spacingXl),
                _buildCredentialCard(),
              ],
              const SizedBox(height: AppUiConstants.spacingXl),
              _buildDevicesCard(),
              const SizedBox(height: AppUiConstants.spacingXl),
              _buildSummaryCard(),
            ],
          ),
        ),
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
            'Tracks activity time and app categories. No keys, screen content, URLs, or screenshots are collected.',
          ),
          const SizedBox(height: AppUiConstants.spacingLg),
          AppFormTextField(controller: _deviceLabel, labelText: 'Device label'),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _consented,
            onChanged: _submitting
                ? null
                : (value) => setState(() => _consented = value ?? false),
            title: const Text('I consent to activity-time collection.'),
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
            ..._devices.map(
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
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text('Activity', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppUiConstants.spacingSm),
          Wrap(
            spacing: AppUiConstants.spacingSm,
            runSpacing: AppUiConstants.spacingSm,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: () => _pickDate(from: true),
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text('From ${_date(_fromDate)}'),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickDate(from: false),
                icon: const Icon(Icons.event_outlined),
                label: Text('To ${_date(_toDate)}'),
              ),
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingSm),
          if (_loading)
            const LinearProgressIndicator()
          else if (_summaries.isEmpty)
            const Text('No activity for this period.')
          else ...<Widget>[
            _buildSummaryTable(),
            if (_selectedSummary != null) ...<Widget>[
              const SizedBox(height: AppUiConstants.spacingMd),
              _buildApplicationTable(_selectedSummary!),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryTable() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: _buildActivityTableTheme(
            DataTable(
              headingRowHeight: 48,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 180,
              horizontalMargin: AppUiConstants.spacingMd,
              columnSpacing: AppUiConstants.spacingLg,
              columns: const <DataColumn>[
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Device')),
                DataColumn(label: Text('Active'), numeric: true),
                DataColumn(label: Text('Idle'), numeric: true),
                DataColumn(label: Text('Input'), numeric: true),
                DataColumn(label: Text('Browser'), numeric: true),
                DataColumn(label: Text('Locked'), numeric: true),
                DataColumn(label: Text('Offline'), numeric: true),
                DataColumn(label: Text('Unknown'), numeric: true),
                DataColumn(label: Text('Tracked'), numeric: true),
                DataColumn(label: Text('Applications')),
              ],
              rows: _summaries
                  .map(
                    (summary) => DataRow(
                      selected: _summaryKey(summary) == _expandedSummaryKey,
                      onSelectChanged: (_) => _toggleApplicationTable(summary),
                      cells: <DataCell>[
                        DataCell(Text(_date(summary.workDate))),
                        DataCell(Text(summary.deviceLabel)),
                        DataCell(Text(_duration(summary.activeSeconds))),
                        DataCell(Text(_duration(summary.idleSeconds))),
                        DataCell(Text(_duration(summary.inputSeconds))),
                        DataCell(Text(_duration(summary.browserSeconds))),
                        DataCell(Text(_duration(summary.lockedSeconds))),
                        DataCell(Text(_duration(summary.offlineSeconds))),
                        DataCell(Text(_duration(summary.unknownSeconds))),
                        DataCell(Text(_duration(summary.trackedSeconds))),
                        DataCell(
                          IconButton(
                            tooltip: _summaryKey(summary) == _expandedSummaryKey
                                ? 'Hide applications'
                                : 'Show applications',
                            onPressed: () => _toggleApplicationTable(summary),
                            icon: Icon(
                              _summaryKey(summary) == _expandedSummaryKey
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(growable: false),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Applications · ${_date(summary.workDate)} · ${summary.deviceLabel}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppUiConstants.spacingXs),
        if (summary.applications.isEmpty)
          const Text('No foreground application totals.')
        else
          _buildActivityTableTheme(
            DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 40,
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
    );
  }

  ActivityWatchSummary? get _selectedSummary {
    final selectedKey = _expandedSummaryKey;
    if (selectedKey == null) return null;

    for (final summary in _summaries) {
      if (_summaryKey(summary) == selectedKey) return summary;
    }
    return null;
  }

  void _toggleApplicationTable(ActivityWatchSummary summary) {
    final summaryKey = _summaryKey(summary);
    setState(
      () => _expandedSummaryKey = _expandedSummaryKey == summaryKey
          ? null
          : summaryKey,
    );
  }

  static String _summaryKey(ActivityWatchSummary summary) =>
      '${summary.deviceId}:${_date(summary.workDate)}';

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

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
