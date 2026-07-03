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

  DateTime? _normalizedRowDate(Map<String, dynamic> row, String key) {
    final rawDate = nullableStringValue(row, key);
    final parsed = rawDate == null ? null : DateTime.tryParse(rawDate);
    if (parsed == null) {
      return null;
    }
    return _normalizeDate(parsed);
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

  Widget _buildFollowupHighlights(
    BuildContext context,
    Map<String, dynamic> row,
  ) {
    final assignedLabel = _assignedLabel(row).trim();
    final mutedText = Theme.of(
      context,
    ).extension<AppThemeExtension>()!.mutedText;
    final items = <Widget>[];

    if (assignedLabel.isNotEmpty) {
      items.add(
        RichText(
          text: TextSpan(
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: mutedText),
            children: [
              const TextSpan(text: 'Assigned To: '),
              TextSpan(
                text: assignedLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const SizedBox(height: 4),
          items[index],
        ],
      ],
    );
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

  List<Map<String, dynamic>> get _nextFollowups => _nextFollowupRows
      .where((row) {
        if (_shouldHideRow(row)) {
          return false;
        }
        final nextFollowup = _normalizedRowDate(row, 'next_followup');
        if (nextFollowup == null) {
          return false;
        }
        final today = _normalizeDate(DateTime.now());
        return nextFollowup.isAfter(today);
      })
      .toList(growable: false);

  List<Map<String, dynamic>> get _visiblePendingFollowups {
    final today = _normalizeDate(DateTime.now());
    final pendingRows = <Map<String, dynamic>>[];
    final seenKeys = <String>{};

    bool addIfMatches(Map<String, dynamic> row, String key) {
      if (_shouldHideRow(row)) {
        return false;
      }
      final status = nullableStringValue(row, 'status');
      if (crmIsCompletedFollowupStatus(status)) {
        return false;
      }

      final normalized = _normalizedRowDate(row, key);
      if (normalized == null) {
        return false;
      }

      if (_showDueTodayOnly) {
        if (normalized != today) {
          return false;
        }
      } else if (_showOverdueOnly) {
        if (!normalized.isBefore(today)) {
          return false;
        }
      } else if (_showUpcomingOnly) {
        if (!normalized.isAfter(today)) {
          return false;
        }
      } else if (!_showOpenFollowupsOnly && !normalized.isBefore(today)) {
        return false;
      }

      final rowId = nullableStringValue(row, 'id') ?? '';
      final sourceType = nullableStringValue(row, 'source_type') ?? '';
      final identity = '$sourceType|$rowId|$key';
      if (!seenKeys.add(identity)) {
        return false;
      }

      pendingRows.add(row);
      return true;
    }

    for (final row in _followups) {
      addIfMatches(row, 'followup_date');
    }
    for (final row in _nextFollowupRows) {
      addIfMatches(row, 'next_followup');
    }

    return pendingRows;
  }

  List<Map<String, dynamic>> get _todayFollowups {
    final today = _normalizeDate(DateTime.now());
    final todayRows = <Map<String, dynamic>>[];
    final seenKeys = <String>{};

    bool addIfToday(Map<String, dynamic> row, String key) {
      if (_shouldHideRow(row)) {
        return false;
      }
      if (crmIsCompletedFollowupStatus(nullableStringValue(row, 'status'))) {
        return false;
      }

      final normalized = _normalizedRowDate(row, key);
      if (normalized != today) {
        return false;
      }

      final rowId = nullableStringValue(row, 'id') ?? '';
      final sourceType = nullableStringValue(row, 'source_type') ?? '';
      final identity = '$sourceType|$rowId|$key';
      if (!seenKeys.add(identity)) {
        return false;
      }

      todayRows.add(row);
      return true;
    }

    for (final row in _followups) {
      addIfToday(row, 'followup_date');
    }
    for (final row in _nextFollowupRows) {
      addIfToday(row, 'next_followup');
    }

    return todayRows;
  }

  List<Map<String, dynamic>> get _upcomingFollowups {
    final today = _normalizeDate(DateTime.now());
    return _followups
        .where((row) {
          if (_shouldHideRow(row)) {
            return false;
          }
          if (crmIsCompletedFollowupStatus(
            nullableStringValue(row, 'status'),
          )) {
            return false;
          }

          final rawDate = nullableStringValue(row, 'followup_date');
          final parsed = rawDate == null ? null : DateTime.tryParse(rawDate);
          if (parsed == null) {
            return false;
          }

          return _normalizeDate(parsed).isAfter(today);
        })
        .toList(growable: false);
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
    return 'No Pending Followups';
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
    return 'Pending Followups';
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
    return 'No pending followups are assigned to you right now.';
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
              (row) => _buildFollowupCard(
                context,
                row,
                icon: Icons.alarm_outlined,
                fallbackTitle: 'Pending Followup',
                dateText: displayDateTime(
                  nullableStringValue(row, 'followup_date'),
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
            (row) => _buildFollowupCard(
              context,
              row,
              icon: Icons.alarm_outlined,
              fallbackTitle: 'Pending Followup',
              dateText: displayDateTime(
                nullableStringValue(row, 'followup_date'),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildNextFollowupList(BuildContext context) {
    if (_nextFollowups.isEmpty) {
      return const SettingsEmptyState(
        icon: Icons.event_repeat_outlined,
        title: 'No Next Followups',
        message: 'No pending followups have a next followup scheduled yet.',
        minHeight: 180,
      );
    }

    return Column(
      children: _nextFollowups
          .map(
            (row) => _buildFollowupCard(
              context,
              row,
              icon: Icons.event_repeat_outlined,
              fallbackTitle: 'Next Followup',
              extraContent: Wrap(
                spacing: AppUiConstants.spacingSm,
                runSpacing: AppUiConstants.spacingSm,
                children: [
                  _buildNextFollowupDetailCard(
                    context,
                    label: 'Next Followup',
                    value: displayDateTime(
                      nullableStringValue(row, 'next_followup'),
                    ),
                  ),
                ],
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
            (row) => _buildFollowupCard(
              context,
              row,
              icon: Icons.today_outlined,
              fallbackTitle: 'Today Followup',
              dateText: displayDateTime(
                nullableStringValue(row, 'followup_date'),
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
            (row) => _buildFollowupCard(
              context,
              row,
              icon: Icons.upcoming_outlined,
              fallbackTitle: 'Upcoming Followup',
              dateText: displayDateTime(
                nullableStringValue(row, 'followup_date'),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildSectionListRow(BuildContext context, {required Widget child}) {
    final borderColor = Theme.of(
      context,
    ).extension<AppThemeExtension>()!.tableBorder.withValues(alpha: 0.5);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppUiConstants.spacingSm,
          vertical: AppUiConstants.spacingMd,
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
    Widget? extraContent,
  }) {
    final detailRoute = _detailRouteForRow(row);
    final notes = stringValue(row, 'notes');
    final title = _cardTitle(row, fallback: fallbackTitle);
    final trimmedDateText = (dateText ?? '').trim();

    return _buildSectionListRow(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(width: AppUiConstants.spacingSm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (trimmedDateText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        trimmedDateText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).extension<AppThemeExtension>()!.mutedText,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildFollowupHighlights(context, row),
                    if (notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(notes),
                    ],
                  ],
                ),
              ),
              if (detailRoute != null)
                AppActionButton(
                  icon: Icons.open_in_new_outlined,
                  label: 'Open',
                  filled: false,
                  onPressed: () =>
                      _openCrmFollowupShellRoute(context, detailRoute),
                ),
            ],
          ),
          if (extraContent != null) ...[
            const SizedBox(height: AppUiConstants.spacingSm),
            extraContent,
          ],
        ],
      ),
    );
  }

  Widget _buildNextFollowupDetailCard(
    BuildContext context, {
    required String label,
    required String value,
    bool expand = false,
  }) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).extension<AppThemeExtension>()!.subtleFill,
        borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppUiConstants.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(value),
          ],
        ),
      ),
    );

    if (expand) {
      return SizedBox(width: double.infinity, child: card);
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 280),
      child: DecoratedBox(decoration: const BoxDecoration(), child: card),
    );
  }

  Widget _buildGapList(BuildContext context) {
    final visibleGaps = _gaps
        .where((row) => !_shouldHideRow(row))
        .toList(growable: false);

    if (visibleGaps.isEmpty) {
      return const SettingsEmptyState(
        icon: Icons.task_alt_outlined,
        title: 'All Open Opportunities Have Followups',
        message:
            'No open opportunities are waiting for a new pending followup.',
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
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next Followup',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppUiConstants.spacingSm),
                  _buildNextFollowupList(context),
                ],
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Needs Followup',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppUiConstants.spacingSm),
                  _buildGapList(context),
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
