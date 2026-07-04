import '../../screen.dart';

void _openCrmFollowupShellRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

class CrmFollowupsPage extends StatefulWidget {
  const CrmFollowupsPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

  @override
  State<CrmFollowupsPage> createState() => _CrmFollowupsPageState();
}

class _CrmFollowupsPageState extends State<CrmFollowupsPage> {
  final CrmService _crmService = CrmService();
  final ScrollController _scrollController = ScrollController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _followups = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _nextFollowupRows = const <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _gaps = const <Map<String, dynamic>>[];
  final Map<int, TextEditingController> _followupDateControllers =
      <int, TextEditingController>{};
  final Map<int, TextEditingController> _nextFollowupControllers =
      <int, TextEditingController>{};
  final Map<int, TextEditingController> _notesControllers =
      <int, TextEditingController>{};
  final Set<int> _savingOpportunityIds = <int>{};

  String get _dashboardFilter =>
      (widget.queryParameters['dashboard_filter'] ?? '').trim();

  bool get _showDueTodayOnly => _dashboardFilter == 'due_today';
  bool get _showOverdueOnly => _dashboardFilter == 'overdue';
  bool get _showUpcomingOnly => _dashboardFilter == 'upcoming';
  bool get _showOpenFollowupsOnly => _dashboardFilter == 'open_followups';

  DateTime _normalizeDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime? _parseRowDateTime(Map<String, dynamic> row, String key) {
    final rawDate = nullableStringValue(row, key);
    final parsed = rawDate == null ? null : DateTime.tryParse(rawDate);
    if (parsed == null) {
      return null;
    }
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  DateTime? _normalizedRowDate(Map<String, dynamic> row, String key) {
    final parsed = _parseRowDateTime(row, key);
    if (parsed == null) {
      return null;
    }
    return _normalizeDate(parsed);
  }

  String _rowIdentity(Map<String, dynamic> row) {
    final sourceType = nullableStringValue(row, 'source_type') ?? '';
    final rowId = nullableStringValue(row, 'id') ?? '';
    return '$sourceType|$rowId';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final controller in _followupDateControllers.values) {
      controller.dispose();
    }
    for (final controller in _nextFollowupControllers.values) {
      controller.dispose();
    }
    for (final controller in _notesControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _crmService.opportunityFollowupsBoard();
      final data = response.data ?? const <String, dynamic>{};
      final followups =
          (data['followups'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false);
      final nextFollowups =
          (data['next_followups'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false);
      final gaps =
          (data['opportunities_without_followups'] as List<dynamic>? ??
                  const <dynamic>[])
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false);

      if (!mounted) {
        return;
      }

      _ensureGapControllers(gaps);
      final activeIds = gaps
          .map((item) => intValue(item, 'opportunity_id'))
          .whereType<int>()
          .toSet();

      setState(() {
        _followups = followups;
        _nextFollowupRows = nextFollowups;
        _gaps = gaps;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _disposeInactiveGapControllers(activeIds);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _ensureGapControllers(List<Map<String, dynamic>> gaps) {
    for (final gap in gaps) {
      final opportunityId = intValue(gap, 'opportunity_id');
      if (opportunityId == null) {
        continue;
      }
      _followupDateControllers.putIfAbsent(
        opportunityId,
        () => TextEditingController(text: currentDateTimeInput()),
      );
      _nextFollowupControllers.putIfAbsent(
        opportunityId,
        () => TextEditingController(),
      );
      _notesControllers.putIfAbsent(
        opportunityId,
        () => TextEditingController(),
      );
    }
  }

  void _disposeInactiveGapControllers(Set<int> activeIds) {
    void disposeMissing(Map<int, TextEditingController> source) {
      final removable = source.keys
          .where((id) => !activeIds.contains(id))
          .toList(growable: false);
      for (final id in removable) {
        source.remove(id)?.dispose();
      }
    }

    disposeMissing(_followupDateControllers);
    disposeMissing(_nextFollowupControllers);
    disposeMissing(_notesControllers);
  }

  Future<void> _pickDateTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final now = DateTime.now();
    final initial = tryParseCalendarDateTime(controller.text) ?? now;
    final selected = await showAppDateTimePickerDialog(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      dateTitle: 'Select Followup Date',
      timeTitle: 'Select Followup Time',
    );
    if (selected == null) {
      return;
    }
    controller.text = formatCalendarDateTime(selected);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _createFollowup(Map<String, dynamic> gap) async {
    final opportunityId = intValue(gap, 'opportunity_id');
    if (opportunityId == null) {
      return;
    }

    final followupDate =
        _followupDateControllers[opportunityId]?.text.trim() ?? '';
    if (followupDate.isEmpty) {
      appScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Followup date is required.')),
      );
      return;
    }

    final notes = _notesControllers[opportunityId]?.text.trim() ?? '';
    if (notes.isEmpty) {
      appScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Notes are required.')),
      );
      return;
    }

    setState(() {
      _savingOpportunityIds.add(opportunityId);
    });

    try {
      final response = await _crmService
          .createOpportunityFollowup(opportunityId, {
            'followup_date': followupDate,
            'next_followup': nullIfEmpty(
              _nextFollowupControllers[opportunityId]?.text ?? '',
            ),
            'notes': notes,
            'status': 'pending',
          });
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await _load();
    } catch (error) {
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingOpportunityIds.remove(opportunityId);
        });
      }
    }
  }

  String _assignedLabel(Map<String, dynamic> row) {
    final user =
        JsonModel.mapOf(row['assigned_user']) ?? const <String, dynamic>{};
    final displayName = stringValue(user, 'display_name');
    if (displayName.isNotEmpty) {
      return displayName;
    }
    return stringValue(user, 'username');
  }

  String _leadLabel(Map<String, dynamic> row) {
    final leadName = stringValue(row, 'lead_name');
    if (leadName.isNotEmpty) {
      return leadName;
    }
    return stringValue(row, 'subject_name');
  }

  String _cardTitle(Map<String, dynamic> row, {required String fallback}) {
    final sourceType = _normalizedStatusValue(
      nullableStringValue(row, 'source_type'),
    );
    if (sourceType == 'lead_activity') {
      final leadLabel = _leadLabel(row);
      if (leadLabel.isNotEmpty) {
        return leadLabel;
      }
    }

    final customerName = stringValue(row, 'customer_name');
    if (customerName.isNotEmpty) {
      return customerName;
    }

    final opportunityName = stringValue(row, 'opportunity_name');
    if (opportunityName.isNotEmpty) {
      return opportunityName;
    }

    final subjectName = stringValue(row, 'subject_name');
    if (subjectName.isNotEmpty) {
      return subjectName;
    }

    return fallback;
  }

  String _followupSummaryText(
    Map<String, dynamic> row, {
    String? dateText,
    String? inlineDetailText,
    String? notes,
  }) {
    final assignedLabel = _assignedLabel(row).trim();
    final trimmedDateText = (dateText ?? '').trim();
    final trimmedInlineDetailText = (inlineDetailText ?? '').trim();
    final trimmedNotes = (notes ?? '').trim();

    return <String>[
      if (trimmedDateText.isNotEmpty) trimmedDateText,
      if (assignedLabel.isNotEmpty) 'Assigned $assignedLabel',
      if (trimmedInlineDetailText.isNotEmpty) trimmedInlineDetailText,
      if (trimmedNotes.isNotEmpty) trimmedNotes,
    ].join(' • ');
  }

  String _normalizedStatusValue(String? value) =>
      (value ?? '').trim().toLowerCase();

  bool _isHiddenLeadRow(Map<String, dynamic> row) {
    final sourceType = _normalizedStatusValue(
      nullableStringValue(row, 'source_type'),
    );
    if (sourceType != 'lead_activity') {
      return false;
    }

    return const {
      'own',
      'lost',
      'converted',
    }.contains(_normalizedStatusValue(nullableStringValue(row, 'lead_status')));
  }

  bool _isHiddenOpportunityRow(Map<String, dynamic> row) {
    final sourceType = _normalizedStatusValue(
      nullableStringValue(row, 'source_type'),
    );
    if (sourceType == 'lead_activity') {
      return false;
    }

    return const {'won', 'lost'}.contains(
      _normalizedStatusValue(
        nullableStringValue(row, 'opportunity_status') ??
            nullableStringValue(row, 'status'),
      ),
    );
  }

  bool _shouldHideRow(Map<String, dynamic> row) {
    return _isHiddenLeadRow(row) || _isHiddenOpportunityRow(row);
  }

  List<_FollowupListEntry> _sortedEntries(
    Iterable<_FollowupListEntry> entries,
  ) {
    final sorted = entries.toList(growable: false);
    sorted.sort((left, right) {
      final leftDate = _parseRowDateTime(left.row, left.dateKey);
      final rightDate = _parseRowDateTime(right.row, right.dateKey);
      if (leftDate == null && rightDate == null) {
        return 0;
      }
      if (leftDate == null) {
        return 1;
      }
      if (rightDate == null) {
        return -1;
      }

      final dateCompare = leftDate.compareTo(rightDate);
      if (dateCompare != 0) {
        return dateCompare;
      }

      final leftId = intValue(left.row, 'id') ?? 0;
      final rightId = intValue(right.row, 'id') ?? 0;
      return rightId.compareTo(leftId);
    });
    return sorted;
  }

  List<_FollowupListEntry> get _effectiveFollowupEntries {
    final entriesByIdentity = <String, _FollowupListEntry>{};

    for (final row in _followups) {
      if (_shouldHideRow(row) ||
          crmIsCompletedFollowupStatus(nullableStringValue(row, 'status'))) {
        continue;
      }
      if (_normalizedRowDate(row, 'next_followup') != null) {
        continue;
      }
      if (_normalizedRowDate(row, 'followup_date') == null) {
        continue;
      }
      entriesByIdentity[_rowIdentity(row)] = _FollowupListEntry(
        row: row,
        dateKey: 'followup_date',
      );
    }

    for (final row in _nextFollowupRows) {
      if (_shouldHideRow(row)) {
        continue;
      }
      if (_normalizedRowDate(row, 'next_followup') == null) {
        continue;
      }
      entriesByIdentity[_rowIdentity(row)] = _FollowupListEntry(
        row: row,
        dateKey: 'next_followup',
      );
    }

    return _sortedEntries(entriesByIdentity.values);
  }

  String? _detailRouteForRow(Map<String, dynamic> row) {
    final opportunityId = intValue(row, 'opportunity_id');
    if (opportunityId != null) {
      return '/crm/opportunities/$opportunityId';
    }

    final leadId = intValue(row, 'lead_id');
    if (leadId != null) {
      return '/crm/leads/$leadId';
    }

    return null;
  }

  List<_FollowupListEntry> get _visiblePendingFollowups {
    final today = _normalizeDate(DateTime.now());
    return _sortedEntries(
      _effectiveFollowupEntries.where((entry) {
        final normalized = _normalizedRowDate(entry.row, entry.dateKey);
        if (normalized == null) {
          return false;
        }

        if (_showDueTodayOnly) {
          return normalized == today;
        }
        if (_showOverdueOnly) {
          return normalized.isBefore(today);
        }
        if (_showUpcomingOnly) {
          return normalized.isAfter(today);
        }
        if (_showOpenFollowupsOnly) {
          return true;
        }
        return normalized.isBefore(today);
      }),
    );
  }

  List<_FollowupListEntry> get _todayFollowups {
    final today = _normalizeDate(DateTime.now());
    return _sortedEntries(
      _effectiveFollowupEntries.where(
        (entry) => _normalizedRowDate(entry.row, entry.dateKey) == today,
      ),
    );
  }

  List<_FollowupListEntry> get _upcomingFollowups {
    final today = _normalizeDate(DateTime.now());
    return _sortedEntries(
      _effectiveFollowupEntries.where((entry) {
        final normalized = _normalizedRowDate(entry.row, entry.dateKey);
        return normalized != null && normalized.isAfter(today);
      }),
    );
  }

  String get _pendingListTitle {
    if (_showDueTodayOnly) {
      return 'No Followups Due Today';
    }
    if (_showOverdueOnly) {
      return 'No Overdue Followups';
    }
    if (_showUpcomingOnly) {
      return 'No Upcoming Followups';
    }
    if (_showOpenFollowupsOnly) {
      return 'No Open Followups';
    }
    return 'No Overdue Followups';
  }

  String get _pendingSectionTitle {
    if (_showDueTodayOnly) {
      return 'Due Today';
    }
    if (_showOverdueOnly) {
      return 'Overdue';
    }
    if (_showUpcomingOnly) {
      return 'Upcoming';
    }
    if (_showOpenFollowupsOnly) {
      return 'Open Followups';
    }
    return 'Overdue';
  }

  String get _pendingListMessage {
    if (_showDueTodayOnly) {
      return 'No pending followups are due today.';
    }
    if (_showOverdueOnly) {
      return 'No pending followups are overdue right now.';
    }
    if (_showUpcomingOnly) {
      return 'No pending followups are scheduled after today.';
    }
    if (_showOpenFollowupsOnly) {
      return 'No open followups are assigned right now.';
    }
    return 'No overdue followups are assigned right now.';
  }

  Widget _buildPendingList(BuildContext context) {
    if (_showDueTodayOnly ||
        _showOverdueOnly ||
        _showUpcomingOnly ||
        _showOpenFollowupsOnly) {
      if (_visiblePendingFollowups.isEmpty) {
        return SettingsEmptyState(
          icon: Icons.alarm_off_outlined,
          title: _pendingListTitle,
          message: _pendingListMessage,
          minHeight: 180,
        );
      }

      return Column(
        children: _visiblePendingFollowups
            .map(
              (entry) => _buildFollowupCard(
                context,
                entry.row,
                icon: Icons.alarm_outlined,
                fallbackTitle: 'Pending Followup',
                dateText: displayDateTime(
                  nullableStringValue(entry.row, entry.dateKey),
                ),
              ),
            )
            .toList(growable: false),
      );
    }

    if (_visiblePendingFollowups.isEmpty) {
      return SettingsEmptyState(
        icon: Icons.alarm_off_outlined,
        title: _pendingListTitle,
        message: _pendingListMessage,
        minHeight: 180,
      );
    }

    return Column(
      children: _visiblePendingFollowups
          .map(
            (entry) => _buildFollowupCard(
              context,
              entry.row,
              icon: Icons.alarm_outlined,
              fallbackTitle: 'Pending Followup',
              dateText: displayDateTime(
                nullableStringValue(entry.row, entry.dateKey),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildTodayFollowupList(BuildContext context) {
    if (_todayFollowups.isEmpty) {
      return const SettingsEmptyState(
        icon: Icons.today_outlined,
        title: 'No Followups Due Today',
        message: 'No pending followups are scheduled for today.',
        minHeight: 180,
      );
    }

    return Column(
      children: _todayFollowups
          .map(
            (entry) => _buildFollowupCard(
              context,
              entry.row,
              icon: Icons.today_outlined,
              fallbackTitle: 'Today Followup',
              dateText: displayDateTime(
                nullableStringValue(entry.row, entry.dateKey),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildUpcomingFollowupList(BuildContext context) {
    if (_upcomingFollowups.isEmpty) {
      return const SettingsEmptyState(
        icon: Icons.upcoming_outlined,
        title: 'No Upcoming Followups',
        message: 'No pending followups are scheduled after today.',
        minHeight: 180,
      );
    }

    return Column(
      children: _upcomingFollowups
          .map(
            (entry) => _buildFollowupCard(
              context,
              entry.row,
              icon: Icons.upcoming_outlined,
              fallbackTitle: 'Upcoming Followup',
              dateText: displayDateTime(
                nullableStringValue(entry.row, entry.dateKey),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildSectionListRow(
    BuildContext context, {
    required Widget child,
    bool compact = false,
    bool showBottomBorder = true,
  }) {
    final borderColor = Theme.of(
      context,
    ).extension<AppThemeExtension>()!.tableBorder.withValues(alpha: 0.5);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: showBottomBorder
            ? Border(bottom: BorderSide(color: borderColor))
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppUiConstants.spacingSm,
          vertical: compact
              ? AppUiConstants.spacingXs
              : AppUiConstants.spacingMd,
        ),
        child: child,
      ),
    );
  }

  Widget _buildFollowupCard(
    BuildContext context,
    Map<String, dynamic> row, {
    required IconData icon,
    required String fallbackTitle,
    String? dateText,
    String? inlineDetailText,
  }) {
    final detailRoute = _detailRouteForRow(row);
    final notes = stringValue(row, 'notes');
    final title = _cardTitle(row, fallback: fallbackTitle);
    final summaryText = _followupSummaryText(
      row,
      dateText: dateText,
      inlineDetailText: inlineDetailText,
      notes: notes,
    );
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;

    return _buildSectionListRow(
      context,
      compact: true,
      showBottomBorder: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: AppUiConstants.spacingSm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (summaryText.isNotEmpty) ...[
                  const SizedBox(height: AppUiConstants.spacingXxs),
                  Text(
                    summaryText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: appTheme.mutedText),
                  ),
                ],
              ],
            ),
          ),
          if (detailRoute != null) ...[
            const SizedBox(width: AppUiConstants.spacingXs),
            AppActionButton(
              icon: Icons.open_in_new_outlined,
              label: 'Open',
              filled: false,
              onPressed: () => _openCrmFollowupShellRoute(context, detailRoute),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGapList(BuildContext context) {
    final visibleGaps = _gaps
        .where((row) => !_shouldHideRow(row))
        .toList(growable: false);

    if (visibleGaps.isEmpty) {
      return const SettingsEmptyState(
        icon: Icons.task_alt_outlined,
        title: 'All Open Enquiries Have Followups',
        message: 'No open enquiries are waiting for a new pending followup.',
        minHeight: 180,
      );
    }

    return Column(
      children: visibleGaps
          .map((row) {
            final opportunityId = intValue(row, 'opportunity_id');
            if (opportunityId == null) {
              return const SizedBox.shrink();
            }
            final saving = _savingOpportunityIds.contains(opportunityId);
            return _buildSectionListRow(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              [
                                    stringValue(row, 'opportunity_no'),
                                    stringValue(row, 'customer_name'),
                                  ]
                                  .where((value) => value.trim().isNotEmpty)
                                  .join(' • '),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                    stringValue(row, 'lead_name'),
                                    _assignedLabel(row),
                                  ]
                                  .where((value) => value.trim().isNotEmpty)
                                  .join(' • '),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).extension<AppThemeExtension>()!.mutedText,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      AppActionButton(
                        icon: Icons.open_in_new_outlined,
                        label: 'Open',
                        filled: false,
                        onPressed: () => _openCrmFollowupShellRoute(
                          context,
                          '/crm/opportunities/$opportunityId',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppUiConstants.spacingSm),
                  SettingsFormWrap(
                    children: [
                      AppDateTimeSelectorField(
                        controller: _followupDateControllers[opportunityId]!,
                        labelText: 'Followup Date',
                        hintText: 'YYYY-MM-DD HH:MM:SS',
                        onTap: () => _pickDateTime(
                          context,
                          _followupDateControllers[opportunityId]!,
                        ),
                      ),
                      AppDateTimeSelectorField(
                        controller: _nextFollowupControllers[opportunityId]!,
                        labelText: 'Next Followup',
                        hintText: 'YYYY-MM-DD HH:MM:SS',
                        onTap: () => _pickDateTime(
                          context,
                          _nextFollowupControllers[opportunityId]!,
                        ),
                      ),
                      AppFormTextField(
                        controller: _notesControllers[opportunityId]!,
                        labelText: 'Notes',
                        maxLines: 2,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppUiConstants.spacingSm),
                  AppActionButton(
                    icon: Icons.save_outlined,
                    label: 'Create Followup',
                    onPressed: saving ? null : () => _createFollowup(row),
                    busy: saving,
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_loading) {
      return const AppLoadingView(message: 'Loading CRM followups...');
    }
    if (_error != null) {
      return AppErrorStateView(
        title: 'Unable to load CRM followups',
        message: _error!,
        onRetry: _load,
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_showDueTodayOnly &&
              !_showOverdueOnly &&
              !_showUpcomingOnly &&
              !_showOpenFollowupsOnly) ...[
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today Followups',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppUiConstants.spacingSm),
                  _buildTodayFollowupList(context),
                ],
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overdue',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppUiConstants.spacingSm),
                  _buildPendingList(context),
                ],
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upcoming Followups',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppUiConstants.spacingSm),
                  _buildUpcomingFollowupList(context),
                ],
              ),
            ),
          ] else ...[
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _pendingSectionTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppUiConstants.spacingSm),
                  _buildPendingList(context),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _load,
        icon: Icons.refresh_outlined,
        label: 'Refresh',
        filled: false,
      ),
    ];

    final content = _buildContent(context);
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'CRM Follow ups',
      scrollController: _scrollController,
      actions: actions,
      child: content,
    );
  }
}

class _FollowupListEntry {
  const _FollowupListEntry({
    required this.row,
    required this.dateKey,
  });

  final Map<String, dynamic> row;
  final String dateKey;
}
