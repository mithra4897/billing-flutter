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
    this.crmService,
  });

  final bool embedded;
  final Map<String, String> queryParameters;
  final CrmService? crmService;

  @override
  State<CrmFollowupsPage> createState() => _CrmFollowupsPageState();
}

class _CrmFollowupsPageState extends State<CrmFollowupsPage> {
  late final CrmService _crmService;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _filterDateFromController =
      TextEditingController();
  final TextEditingController _filterDateToController = TextEditingController();
  bool _loading = true;
  bool _filtersVisible = false;
  bool _isSuperAdmin = false;
  String? _error;
  DateTime? _filterDateFrom;
  DateTime? _filterDateTo;
  Set<int> _employeeFilterIds = <int>{};
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
  final Set<String> _collapsedSections = <String>{};

  String get _dashboardFilter =>
      (widget.queryParameters['dashboard_filter'] ?? '').trim();

  bool get _showDueTodayOnly => _dashboardFilter == 'due_today';
  bool get _showOverdueOnly => _dashboardFilter == 'overdue';
  bool get _showUpcomingOnly => _dashboardFilter == 'upcoming';
  bool get _showOpenFollowupsOnly => _dashboardFilter == 'open_followups';
  bool get _hasDashboardFilter =>
      _showDueTodayOnly ||
      _showOverdueOnly ||
      _showUpcomingOnly ||
      _showOpenFollowupsOnly;

  List<AppDropdownItem<int>> get _employeeItems {
    final employees = <int, String>{};
    for (final row in [..._followups, ..._nextFollowupRows]) {
      final assigned =
          JsonModel.mapOf(row['assigned_user']) ?? const <String, dynamic>{};
      final id = intValue(assigned, 'id') ?? intValue(row, 'assigned_to');
      if (id == null) continue;
      final label = stringValue(assigned, 'display_name').isNotEmpty
          ? stringValue(assigned, 'display_name')
          : stringValue(assigned, 'username');
      employees[id] = label.isEmpty ? 'Employee $id' : label;
    }
    return employees.entries
        .map(
          (entry) => AppDropdownItem<int>(value: entry.key, label: entry.value),
        )
        .toList(growable: false);
  }

  bool _matchesEmployee(Map<String, dynamic> row) {
    if (_employeeFilterIds.isEmpty) return true;
    final assigned =
        JsonModel.mapOf(row['assigned_user']) ?? const <String, dynamic>{};
    final assignedId = intValue(assigned, 'id') ?? intValue(row, 'assigned_to');
    return assignedId != null && _employeeFilterIds.contains(assignedId);
  }

  bool _matchesSearch(Map<String, dynamic> row) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }
    final assigned =
        JsonModel.mapOf(row['assigned_user']) ?? const <String, dynamic>{};
    final searchableText = <String>[
      stringValue(row, 'opportunity_no'),
      stringValue(row, 'lead_no'),
      stringValue(row, 'customer_name'),
      stringValue(row, 'lead_name'),
      stringValue(row, 'status'),
      stringValue(row, 'followup_date'),
      stringValue(row, 'next_followup'),
      stringValue(row, 'notes'),
      stringValue(assigned, 'display_name'),
      stringValue(assigned, 'username'),
    ].join(' ').toLowerCase();
    return searchableText.contains(query);
  }

  DateTime _normalizeDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String get _dateRangeLabel {
    final from = _filterDateFrom == null
        ? 'Any date'
        : formatCalendarDate(_filterDateFrom!);
    final to = _filterDateTo == null
        ? 'Any date'
        : formatCalendarDate(_filterDateTo!);
    return '$from - $to';
  }

  bool _matchesDateRange(_FollowupListEntry entry) {
    final rowDate = _normalizedRowDate(entry.row, entry.dateKey);
    if (rowDate == null) {
      return false;
    }
    if (_filterDateFrom == null && _filterDateTo == null) {
      return true;
    }
    return (_filterDateFrom == null || !rowDate.isBefore(_filterDateFrom!)) &&
        (_filterDateTo == null || !rowDate.isAfter(_filterDateTo!));
  }

  // Kept as a small compatibility helper for callers using the previous date
  // picker flow; the inline AppDateField now owns the picker interaction.
  // ignore: unused_element
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showAppDatePickerDialog(
      context: context,
      initialDate: _filterDateFrom ?? now,
      firstDate: appCalendarFirstDate(now),
      lastDate: appCalendarLastDate(now),
      title: 'Filter followups by date',
    );
    if (selected == null || !mounted) {
      return;
    }
    _filterDateFromController.text = formatCalendarDate(selected);
  }

  void _clearDateFilter() {
    _filterDateFromController.clear();
    _filterDateToController.clear();
    if (_employeeFilterIds.isNotEmpty) {
      setState(() => _employeeFilterIds = <int>{});
    }
  }

  void _syncDateFilter() {
    final rawFrom = _filterDateFromController.text.trim();
    final rawTo = _filterDateToController.text.trim();
    final nextFrom = rawFrom.isEmpty ? null : tryParseCalendarDate(rawFrom);
    final nextTo = rawTo.isEmpty ? null : tryParseCalendarDate(rawTo);
    final normalizedFrom = nextFrom == null ? null : _normalizeDate(nextFrom);
    final normalizedTo = nextTo == null ? null : _normalizeDate(nextTo);
    if (normalizedFrom == _filterDateFrom && normalizedTo == _filterDateTo) {
      return;
    }
    setState(() {
      _filterDateFrom = normalizedFrom;
      _filterDateTo = normalizedTo;
    });
  }

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
    _crmService = widget.crmService ?? CrmService();
    _searchController.addListener(_onSearchChanged);
    _filterDateFromController.addListener(_syncDateFilter);
    _filterDateToController.addListener(_syncDateFilter);
    _loadAccess();
    _load();
  }

  void _onSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadAccess() async {
    final currentUser = await SessionStorage.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _isSuperAdmin =
          currentUser?['is_super_admin'] == true ||
          currentUser?['is_super_admin'] == 1 ||
          currentUser?['is_super_admin'] == '1';
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _filterDateFromController
      ..removeListener(_syncDateFilter)
      ..dispose();
    _filterDateToController
      ..removeListener(_syncDateFilter)
      ..dispose();
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
    final trimmedDateText = (dateText ?? '').trim();
    final trimmedInlineDetailText = (inlineDetailText ?? '').trim();
    final trimmedNotes = (notes ?? '').trim();

    return <String>[
      if (trimmedDateText.isNotEmpty) trimmedDateText,
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
      if (!_matchesEmployee(row) ||
          _shouldHideRow(row) ||
          !_matchesSearch(row) ||
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
      if (!_matchesEmployee(row) ||
          _shouldHideRow(row) ||
          !_matchesSearch(row)) {
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
        if (!_matchesDateRange(entry)) {
          return false;
        }
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
        (entry) =>
            _matchesDateRange(entry) &&
            _normalizedRowDate(entry.row, entry.dateKey) == today,
      ),
    );
  }

  List<_FollowupListEntry> get _upcomingFollowups {
    final today = _normalizeDate(DateTime.now());
    return _sortedEntries(
      _effectiveFollowupEntries.where((entry) {
        if (!_matchesDateRange(entry)) {
          return false;
        }
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
        children: List<Widget>.generate(_visiblePendingFollowups.length, (
          index,
        ) {
          final entry = _visiblePendingFollowups[index];
          return _buildFollowupCard(
            context,
            entry.row,
            icon: Icons.alarm_outlined,
            fallbackTitle: 'Pending Followup',
            dateText: displayDateTime(
              nullableStringValue(entry.row, entry.dateKey),
            ),
            showBottomBorder: index != _visiblePendingFollowups.length - 1,
          );
        }),
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
      children: List<Widget>.generate(_visiblePendingFollowups.length, (index) {
        final entry = _visiblePendingFollowups[index];
        return _buildFollowupCard(
          context,
          entry.row,
          icon: Icons.alarm_outlined,
          fallbackTitle: 'Pending Followup',
          dateText: displayDateTime(
            nullableStringValue(entry.row, entry.dateKey),
          ),
          showBottomBorder: index != _visiblePendingFollowups.length - 1,
        );
      }),
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
      children: List<Widget>.generate(_todayFollowups.length, (index) {
        final entry = _todayFollowups[index];
        return _buildFollowupCard(
          context,
          entry.row,
          icon: Icons.today_outlined,
          fallbackTitle: 'Today Followup',
          dateText: displayDateTime(
            nullableStringValue(entry.row, entry.dateKey),
          ),
          showBottomBorder: index != _todayFollowups.length - 1,
        );
      }),
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
      children: List<Widget>.generate(_upcomingFollowups.length, (index) {
        final entry = _upcomingFollowups[index];
        return _buildFollowupCard(
          context,
          entry.row,
          icon: Icons.upcoming_outlined,
          fallbackTitle: 'Upcoming Followup',
          dateText: displayDateTime(
            nullableStringValue(entry.row, entry.dateKey),
          ),
          showBottomBorder: index != _upcomingFollowups.length - 1,
        );
      }),
    );
  }

  Widget _buildSelectedDateFollowupList(BuildContext context) {
    final entries = _selectedDateEntries;
    if (entries.isEmpty) {
      return SettingsEmptyState(
        icon: Icons.event_busy_outlined,
        title: 'No Followups in Selected Range',
        message: 'No followups match these dates and the current route filter.',
        minHeight: 180,
      );
    }

    return Column(
      children: List<Widget>.generate(entries.length, (index) {
        final entry = entries[index];
        return _buildFollowupCard(
          context,
          entry.row,
          icon: Icons.event_note_outlined,
          fallbackTitle: 'CRM Followup',
          dateText: displayDateTime(
            nullableStringValue(entry.row, entry.dateKey),
          ),
          showBottomBorder: index != entries.length - 1,
        );
      }),
    );
  }

  Widget _buildDateFilter(BuildContext context) {
    return AppSectionCard(
      showShadow: false,
      child: AppRegisterFilters(
        dateFromController: _filterDateFromController,
        dateToController: _filterDateToController,
        partyLabel: _isSuperAdmin ? 'Employee' : null,
        partyItems: _isSuperAdmin ? _employeeItems : null,
        selectedPartyIds: _isSuperAdmin ? _employeeFilterIds : null,
        onPartyChanged: _isSuperAdmin
            ? (values) =>
                setState(() => _employeeFilterIds = Set<int>.from(values))
            : null,
        onClear: _clearDateFilter,
      ),
    );
  }

  Widget _buildTimelineSection({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    final isCollapsed = _collapsedSections.contains(title);
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() {
              if (isCollapsed) {
                _collapsedSections.remove(title);
              } else {
                _collapsedSections.add(title);
              }
            }),
            borderRadius: BorderRadius.circular(AppUiConstants.buttonRadius),
            child: Row(
              children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  border: Border.all(color: appTheme.tableBorder),
                  borderRadius: BorderRadius.circular(
                    AppUiConstants.buttonRadius,
                  ),
                ),
                child: Icon(
                  isCollapsed
                      ? Icons.keyboard_arrow_right
                      : Icons.keyboard_arrow_down,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppUiConstants.spacingXs),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            ),
          ),
          if (!isCollapsed) ...[
            const SizedBox(height: AppUiConstants.spacingMd),
            child,
          ],
        ],
      ),
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
    bool showBottomBorder = true,
  }) {
    final detailRoute = _detailRouteForRow(row);
    final notes = stringValue(row, 'notes');
    final title = _cardTitle(row, fallback: fallbackTitle);
    final summaryText = _followupSummaryText(
      row,
      inlineDetailText: inlineDetailText,
      notes: notes,
    );
    final appTheme = Theme.of(context).extension<AppThemeExtension>()!;
    final parsedDate = dateText == null
        ? null
        : DateTime.tryParse(nullableStringValue(row, 'next_followup') ?? '') ??
              DateTime.tryParse(
                nullableStringValue(row, 'followup_date') ?? '',
              );
    final localDate = parsedDate?.isUtc == true
        ? parsedDate!.toLocal()
        : parsedDate;
    final timeText = localDate == null
        ? (dateText ?? 'No date')
        : MaterialLocalizations.of(
            context,
          ).formatTimeOfDay(TimeOfDay.fromDateTime(localDate));
    final dateLabel = localDate == null
        ? null
        : formatCalendarDate(_normalizeDate(localDate));
    final assignedLabel = _assignedLabel(row).trim();

    Widget detailCard = Material(
      key: ValueKey<String>('followup-card-${_rowIdentity(row)}'),
      color: appTheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppUiConstants.cardRadius),
        side: BorderSide(color: appTheme.tableBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppUiConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppUiConstants.spacingSm,
              runSpacing: AppUiConstants.spacingXs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                AppStatusBadge(
                  label: 'Follow-up',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            if (summaryText.isNotEmpty) ...[
              const SizedBox(height: AppUiConstants.spacingXs),
              Text(
                summaryText,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: appTheme.mutedText),
              ),
            ],
            if (assignedLabel.isNotEmpty || detailRoute != null) ...[
              const SizedBox(height: AppUiConstants.spacingSm),
              Row(
                children: [
                  if (assignedLabel.isNotEmpty) ...[
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.12),
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        assignedLabel.characters.first.toUpperCase(),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: AppUiConstants.spacingXs),
                    Expanded(
                      child: Text(
                        assignedLabel,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ] else
                    const Spacer(),
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
            ],
          ],
        ),
      ),
    );

    return LayoutBuilder(
      key: ValueKey<String>('followup-timeline-${_rowIdentity(row)}'),
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        final timelineRail = SizedBox(
          width: 24,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (showBottomBorder)
                Positioned(
                  left: 11,
                  top: 14,
                  bottom: -AppUiConstants.spacingMd,
                  child: Container(
                    key: const ValueKey<String>('followup-timeline-rail'),
                    width: 2,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.28),
                  ),
                ),
              Positioned(
                left: 5,
                top: 8,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: appTheme.cardBackground,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.24),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        final timeLabel = Padding(
          padding: const EdgeInsets.only(top: AppUiConstants.spacingXs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (dateLabel != null)
                Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: appTheme.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 16,
                    color: appTheme.mutedText,
                  ),
                  const SizedBox(width: AppUiConstants.spacingXxs),
                  Text(
                    timeText,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: appTheme.mutedText),
                  ),
                ],
              ),
            ],
          ),
        );

        return Padding(
          padding: EdgeInsets.only(
            bottom: showBottomBorder ? AppUiConstants.spacingMd : 0,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                timelineRail,
                const SizedBox(width: AppUiConstants.spacingXs),
                if (!compact) ...[
                  SizedBox(width: 132, child: timeLabel),
                  const SizedBox(width: AppUiConstants.spacingSm),
                  Expanded(child: detailCard),
                ] else
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        timeLabel,
                        const SizedBox(height: AppUiConstants.spacingXs),
                        detailCard,
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_FollowupListEntry> get _selectedDateEntries {
    if (_filterDateFrom == null && _filterDateTo == null) {
      return const <_FollowupListEntry>[];
    }
    final source = _hasDashboardFilter
        ? _visiblePendingFollowups
        : _effectiveFollowupEntries;
    return _sortedEntries(source.where(_matchesDateRange));
  }

  Widget _buildGapList(BuildContext context) {
    final visibleGaps = _gaps
        .where((row) => !_shouldHideRow(row) && _matchesSearch(row))
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
                      AppFormTextField(
                        controller: _followupDateControllers[opportunityId]!,
                        labelText: 'Followup Date',
                        hintText: 'Date and time',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateTimeInputFormatter()],
                        allowType: false,
                        onChanged: (_) => setState(() {}),
                      ),
                      AppFormTextField(
                        controller: _nextFollowupControllers[opportunityId]!,
                        labelText: 'Next Followup',
                        hintText: 'Date and time',
                        keyboardType: TextInputType.datetime,
                        inputFormatters: const [DateTimeInputFormatter()],
                        allowType: false,
                        onChanged: (_) => setState(() {}),
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
          if (_filtersVisible) ...[
            const SizedBox(height: AppUiConstants.spacingMd),
            _buildDateFilter(context),
            const SizedBox(height: AppUiConstants.spacingMd),
          ],
          if (!_filtersVisible)
            const SizedBox(height: AppUiConstants.spacingMd),
          if (_filterDateFrom != null || _filterDateTo != null)
            _buildTimelineSection(
              context: context,
              title: _dateRangeLabel,
              child: _buildSelectedDateFollowupList(context),
            )
          else if (!_hasDashboardFilter) ...[
            _buildTimelineSection(
              context: context,
              title: 'Today',
              child: _buildTodayFollowupList(context),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            _buildTimelineSection(
              context: context,
              title: 'Overdue',
              child: _buildPendingList(context),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
            _buildTimelineSection(
              context: context,
              title: 'Upcoming Followups',
              child: _buildUpcomingFollowupList(context),
            ),
          ] else
            _buildTimelineSection(
              context: context,
              title: _pendingSectionTitle,
              child: _buildPendingList(context),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      AdaptiveShellSearchField(
        controller: _searchController,
        hintText: 'Search followups',
      ),
      AdaptiveShellActionButton(
        onPressed: () => setState(() => _filtersVisible = !_filtersVisible),
        icon: Icons.filter_alt_outlined,
        label: 'Filter',
        filled: _filtersVisible,
      ),
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
  const _FollowupListEntry({required this.row, required this.dateKey});

  final Map<String, dynamic> row;
  final String dateKey;
}
