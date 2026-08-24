import '../../screen.dart';
import 'widgets/monthly_attendance_calendar_grid.dart';

const List<AppDropdownItem<String>> _monthlyAttendanceStatuses =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'present', label: 'Present'),
      AppDropdownItem(value: 'half_day', label: 'Half day'),
      AppDropdownItem(value: 'leave', label: 'Paid leave'),
      AppDropdownItem(value: 'lop', label: 'LOP'),
      AppDropdownItem(value: 'absent', label: 'Absent'),
    ];

const List<AppDropdownItem<String>> _attendanceSourceFilters =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'activity_watch', label: 'Activity Watch'),
      AppDropdownItem(value: 'manual', label: 'Manual'),
      AppDropdownItem(value: 'login', label: 'Legacy ERP Login'),
    ];

const List<AppDropdownItem<String>> _attendanceStatusFilters =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'present', label: 'Present'),
      AppDropdownItem(value: 'half_day', label: 'Half day'),
      AppDropdownItem(value: 'leave', label: 'Paid leave'),
      AppDropdownItem(value: 'lop', label: 'LOP'),
      AppDropdownItem(value: 'absent', label: 'Absent'),
      AppDropdownItem(value: 'holiday', label: 'Holiday'),
    ];

int? _attendanceReportYear;
int? _attendanceReportMonth;

class MonthlyAttendancePage extends StatefulWidget {
  const MonthlyAttendancePage({
    super.key,
    this.embedded = false,
    this.manualOnly = true,
    this.includeAllActiveEmployees = false,
  });

  final bool embedded;
  final bool manualOnly;
  final bool includeAllActiveEmployees;

  @override
  State<MonthlyAttendancePage> createState() => _MonthlyAttendancePageState();
}

class _MonthlyAttendancePageState extends State<MonthlyAttendancePage> {
  final HrService _service = HrService();
  final ScrollController _pageScrollController = ScrollController();
  final ScrollController _gridScrollController = ScrollController();
  final GlobalKey _todayColumnKey = GlobalKey();
  final TextEditingController _searchController = TextEditingController();
  late int _year;
  late int _month;
  int? _companyId;
  int _page = 1;
  int _perPage = 20;
  bool _loading = true;
  bool _saving = false;
  bool _filtersVisible = false;
  String? _error;
  MonthlyAttendanceSheetModel? _sheet;
  final Set<int> _selectedEmployees = <int>{};
  final Set<String> _lockedCells = <String>{};
  final Set<String> _draftCells = <String>{};
  final Set<String> _agentCells = <String>{};
  final Map<String, String> _statuses = <String, String>{};
  final Map<String, AttendanceRecordModel> _recordsByCell =
      <String, AttendanceRecordModel>{};
  Set<int> _filterEmployeeIds = <int>{};
  Set<String> _filterStatuses = <String>{};
  Set<String> _filterSources = <String>{};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = widget.manualOnly ? now.year : _attendanceReportYear ?? now.year;
    _month = widget.manualOnly
        ? now.month
        : _attendanceReportMonth ?? now.month;
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _gridScrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  String _dateKey(int employeeId, int day) =>
      '$employeeId:${_year.toString().padLeft(4, '0')}-'
      '${_month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  String _dateValue(int day) =>
      '${_year.toString().padLeft(4, '0')}-'
      '${_month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final companyId = await hrResolveCompanyId(context);
      if (!mounted) return;
      if (companyId == null) {
        throw Exception('Select a session company to load monthly attendance.');
      }
      final response = await _service.monthlyAttendanceSheet(
        companyId: companyId,
        year: _year,
        month: _month,
        includeSystemEmployees:
            widget.includeAllActiveEmployees || !widget.manualOnly,
        activeEmployeesOnly: widget.includeAllActiveEmployees,
      );
      if (!response.success || response.data == null) {
        throw Exception(
          response.message.isEmpty
              ? 'Unable to load attendance.'
              : response.message,
        );
      }
      final sheet = response.data!;
      _companyId = companyId;
      _sheet = sheet;
      if (!widget.manualOnly) _page = 1;
      _selectedEmployees.clear();
      _statuses.clear();
      _lockedCells.clear();
      _draftCells.clear();
      _agentCells.clear();
      _recordsByCell.clear();
      if (widget.manualOnly) {
        for (final employee in sheet.employees) {
          for (var day = 1; day <= sheet.daysInMonth; day++) {
            if (_isEditable(employee, day, sheet)) {
              _statuses[_dateKey(employee.id, day)] = 'present';
            }
          }
        }
      }
      for (final record in sheet.attendance) {
        final employeeId = record.employeeId;
        final date = DateTime.tryParse(record.attendanceDate ?? '');
        if (employeeId == null || date == null) continue;
        final key = _dateKey(employeeId, date.day);
        _statuses[key] = record.status ?? 'present';
        _recordsByCell[key] = record;
        if (record.submissionStatus == 'draft' && record.source == 'manual') {
          _draftCells.add(key);
        } else {
          _lockedCells.add(key);
        }
        if (record.source == 'activity_watch') _agentCells.add(key);
      }
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
      _sheet = null;
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToTodayColumn();
        });
      }
    }
  }

  void _scrollToTodayColumn() {
    if (!mounted || !_gridScrollController.hasClients) return;
    final now = DateTime.now();
    if (_year != now.year || _month != now.month) return;
    final todayContext = _todayColumnKey.currentContext;
    if (todayContext == null) return;
    Scrollable.ensureVisible(
      todayContext,
      alignment: 0.5,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  bool _isEditable(
    MonthlyAttendanceEmployeeModel employee,
    int day,
    MonthlyAttendanceSheetModel sheet,
  ) {
    final date = DateTime(_year, _month, day);
    final today = DateTime.tryParse(sheet.today);
    final joining = DateTime.tryParse(employee.joiningDate ?? '');
    final relieving = DateTime.tryParse(employee.relievingDate ?? '');
    if (today != null && date.isAfter(today)) return false;
    if (joining != null && date.isBefore(joining)) return false;
    if (relieving != null && date.isAfter(relieving)) return false;
    return !sheet.weeklyOffDays.contains(date.weekday % 7);
  }

  Future<void> _submit() async {
    final sheet = _sheet;
    final companyId = _companyId;
    if (sheet == null || companyId == null || _selectedEmployees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one employee.')),
      );
      return;
    }
    final records = <Map<String, dynamic>>[];
    for (final employee in sheet.employees) {
      if (!_selectedEmployees.contains(employee.id)) continue;
      for (var day = 1; day <= sheet.daysInMonth; day++) {
        final key = _dateKey(employee.id, day);
        if (!_isEditable(employee, day, sheet)) {
          continue;
        }
        if (widget.manualOnly && _lockedCells.contains(key)) continue;
        records.add(<String, dynamic>{
          'employee_id': employee.id,
          'attendance_date': _dateValue(day),
          'status': _statuses[key] ?? 'present',
        });
      }
    }
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('There are no new attendance days to save.'),
        ),
      );
      return;
    }
    if (records.length > 15000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select fewer employees and save in batches.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Submit monthly attendance'),
        content: const Text(
          'Submitted cells are locked and payroll can use them. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      final response = await _service.saveMonthlyAttendance(
        companyId: companyId,
        year: _year,
        month: _month,
        records: records,
        saveMode: 'submit',
        includeSystemEmployees:
            widget.includeAllActiveEmployees || !widget.manualOnly,
        activeEmployeesOnly: widget.includeAllActiveEmployees,
      );
      if (!response.success) throw Exception(response.message);
      if (!mounted) return;
      final data = response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : const <String, dynamic>{};
      final created =
          JsonModel.nullableInt(data['created_count']) ?? records.length;
      final updated = JsonModel.nullableInt(data['updated_count']) ?? 0;
      final changed = created + updated;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Submitted $changed monthly attendance record(s) for payroll.',
          ),
        ),
      );
      if (widget.manualOnly) {
        _attendanceReportYear = _year;
        _attendanceReportMonth = _month;
        openHrShellRoute(context, '/hr/attendance');
        return;
      }
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildInlineFilterBar() => HrInlineFilterBar(
    filterFields: [
      hrListFilterBox(
        child: AppFormTextField(
          controller: _searchController,
          labelText: 'Search',
          hintText: 'Employee name or code',
        ),
      ),
      hrListFilterBox(
        child: AppDropdownField<int>.fromMapped(
          labelText: 'Employee',
          mappedItems: (_sheet?.employees ?? const [])
              .map(
                (employee) => AppDropdownItem<int>(
                  value: employee.id,
                  label: employee.employeeName,
                ),
              )
              .toList(growable: false),
          multiInitialValues: _filterEmployeeIds,
          multiHintText: 'Select employees',
          onMultiChanged: (values) {
            setState(() => _filterEmployeeIds = Set<int>.from(values));
          },
        ),
      ),
      hrListFilterBox(
        child: AppDropdownField<String>.fromMapped(
          labelText: 'Status',
          mappedItems: _attendanceStatusFilters,
          multiInitialValues: _filterStatuses,
          multiHintText: 'Select statuses',
          onMultiChanged: (values) {
            setState(() => _filterStatuses = Set<String>.from(values));
          },
        ),
      ),
      hrListFilterBox(
        child: AppDropdownField<String>.fromMapped(
          labelText: 'Source',
          mappedItems: _attendanceSourceFilters,
          multiInitialValues: _filterSources,
          multiHintText: 'Select sources',
          onMultiChanged: (values) {
            setState(() => _filterSources = Set<String>.from(values));
          },
        ),
      ),
      hrListFilterBox(
        child: AppDropdownField<int>.fromMapped(
          labelText: 'Month',
          initialValue: _month,
          mappedItems: List<AppDropdownItem<int>>.generate(
            12,
            (index) => AppDropdownItem<int>(
              value: index + 1,
              label: _monthName(index + 1),
            ),
          ),
          onChanged: (value) => _selectReportPeriod(month: value),
        ),
      ),
      hrListFilterBox(
        child: AppDropdownField<int>.fromMapped(
          labelText: 'Year',
          initialValue: _year,
          mappedItems: List<AppDropdownItem<int>>.generate(7, (index) {
            final value = DateTime.now().year - 4 + index;
            return AppDropdownItem<int>(value: value, label: '$value');
          }),
          onChanged: (value) => _selectReportPeriod(year: value),
        ),
      ),
    ],
    onClear: () {
      _clearFilters();
      unawaited(_applyFilters());
    },
  );

  void _onSearchChanged() => setState(() {});

  void _selectReportPeriod({int? year, int? month}) {
    final nextYear = year ?? _year;
    final nextMonth = month ?? _month;
    if (nextYear == _year && nextMonth == _month) {
      return;
    }
    setState(() {
      _year = nextYear;
      _month = nextMonth;
      _page = 1;
    });
    _resetGridScroll();
    unawaited(_applyFilters());
  }

  void _resetGridScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_gridScrollController.hasClients) {
        _gridScrollController.jumpTo(0);
      }
    });
  }

  void _clearFilters() {
    final now = DateTime.now();
    setState(() {
      _month = now.month;
      _year = now.year;
      _searchController.clear();
      _filterEmployeeIds = <int>{};
      _filterStatuses = <String>{};
      _filterSources = <String>{};
      _page = 1;
    });
  }

  Future<void> _applyFilters() async {
    _attendanceReportYear = _year;
    _attendanceReportMonth = _month;
    setState(() => _page = 1);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      if (!widget.manualOnly) ...[
        AdaptiveShellActionButton(
          icon: Icons.filter_alt_outlined,
          label: 'Filter',
          filled: false,
          onPressed: _loading
              ? null
              : () => setState(() => _filtersVisible = !_filtersVisible),
        ),
        AdaptiveShellActionButton(
          icon: Icons.refresh_outlined,
          label: 'Reload',
          filled: false,
          onPressed: _loading ? null : _load,
        ),
        AdaptiveShellActionButton(
          icon: Icons.groups_outlined,
          label: 'Bulk attendance',
          onPressed: _loading
              ? null
              : () => openHrShellRoute(context, '/hr/monthly-attendance'),
        ),
      ],
      if (widget.manualOnly) ...[
        AdaptiveShellActionButton(
          icon: Icons.refresh_outlined,
          label: 'Reload',
          filled: false,
          onPressed: _loading || _saving ? null : _load,
        ),
        AdaptiveShellActionButton(
          icon: Icons.task_alt_outlined,
          label: _saving ? 'Submitting…' : 'Submit attendance',
          onPressed: _loading || _saving ? null : _submit,
        ),
      ],
    ];
    final content = _buildContent();
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: widget.manualOnly ? 'Bulk Attendance' : 'Attendance',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      controller: _pageScrollController,
      padding: const EdgeInsets.all(AppUiConstants.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.manualOnly) ...[
            AppSectionCard(
              child: Wrap(
                spacing: AppUiConstants.spacingMd,
                runSpacing: AppUiConstants.spacingSm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Month',
                    width: 190,
                    initialValue: _month,
                    mappedItems: List<AppDropdownItem<int>>.generate(
                      12,
                      (index) => AppDropdownItem<int>(
                        value: index + 1,
                        label: _monthName(index + 1),
                      ),
                    ),
                    onChanged: (value) {
                      if (value != null) setState(() => _month = value);
                    },
                  ),
                  AppDropdownField<int>.fromMapped(
                    labelText: 'Year',
                    width: 140,
                    initialValue: _year,
                    mappedItems: List<AppDropdownItem<int>>.generate(7, (
                      index,
                    ) {
                      final value = DateTime.now().year - 4 + index;
                      return AppDropdownItem<int>(
                        value: value,
                        label: '$value',
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) setState(() => _year = value);
                    },
                  ),
                  FilledButton.icon(
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('Load month'),
                  ),
                  const Text(
                    'Eligible days default to Present. Mark exceptions and submit when ready.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppUiConstants.spacingMd),
          ] else if (_filtersVisible) ...[
            _buildInlineFilterBar(),
            const SizedBox(height: AppUiConstants.spacingMd),
          ],
          if (_loading)
            const AppLoadingView(message: 'Loading monthly attendance...')
          else if (_error != null)
            AppErrorStateView(
              title: 'Unable to load monthly attendance',
              message: _error!,
              onRetry: _load,
            )
          else if (_visibleEmployees(_sheet).isEmpty)
            AppSectionCard(
              child: Text(
                widget.includeAllActiveEmployees
                    ? 'No active employees found for this company.'
                    : widget.manualOnly
                    ? 'No eligible manual-attendance employees found.'
                    : 'No saved attendance records match the selected filters.',
              ),
            )
          else ...[
            MonthlyAttendanceCalendarGrid(
              sheet: _sheet!,
              employees: widget.manualOnly
                  ? _visibleEmployees(_sheet)
                  : _pagedEmployees(_sheet!),
              year: _year,
              month: _month,
              scrollController: _gridScrollController,
              todayColumnKey: _todayColumnKey,
              cellBuilder: _buildAttendanceCell,
              manualOnly: widget.manualOnly,
              page: _page,
              perPage: _perPage,
              selectedEmployeeIds: _selectedEmployees,
              onEmployeeSelected: widget.manualOnly
                  ? (employeeId, selected) {
                      setState(() {
                        if (selected) {
                          _selectedEmployees.add(employeeId);
                        } else {
                          _selectedEmployees.remove(employeeId);
                        }
                      });
                    }
                  : null,
              onAllEmployeesSelected: widget.manualOnly
                  ? (selected) => setState(() {
                      _selectedEmployees
                        ..clear()
                        ..addAll(
                          selectAllHrRecords(
                            _sheet!.employees.map((employee) => employee.id),
                            selected: selected,
                          ),
                        );
                    })
                  : null,
            ),
            if (!widget.manualOnly) ...[
              const SizedBox(height: AppUiConstants.spacingSm),
              _buildPagination(_sheet!),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildAttendanceCell(
    MonthlyAttendanceEmployeeModel employee,
    int day,
    MonthlyAttendanceSheetModel sheet,
  ) {
    final key = _dateKey(employee.id, day);
    final editable = _isEditable(employee, day, sheet);
    final locked = _lockedCells.contains(key);
    final isAgentRecord = _agentCells.contains(key);
    final savedRecord = _recordsByCell[key];
    final record = savedRecord != null && _recordMatchesFilters(savedRecord)
        ? savedRecord
        : null;
    if (!widget.manualOnly) {
      if (record == null) {
        final date = DateTime(_year, _month, day);
        final isOff = sheet.weeklyOffDays.contains(date.weekday % 7);
        final joining = DateTime.tryParse(employee.joiningDate ?? '');
        final relieving = DateTime.tryParse(employee.relievingDate ?? '');
        final notApplicable =
            (joining != null && date.isBefore(joining)) ||
            (relieving != null && date.isAfter(relieving));
        return Tooltip(
          message: notApplicable
              ? 'Not applicable for employment period'
              : isOff
              ? 'Weekly off — no attendance record'
              : 'No saved attendance record',
          child: _emptyStatusBadge(
            notApplicable
                ? 'NA'
                : isOff
                ? 'WO'
                : '—',
            notApplicable
                ? Colors.blueGrey
                : isOff
                ? Colors.purple
                : Colors.grey,
          ),
        );
      }
      return InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _openSavedRecord(record),
        child: Tooltip(
          message:
              '${record.source == 'activity_watch' ? 'Activity Watch' : 'Manual'} attendance — edit record',
          child: _statusBadge(
            record.status ?? 'present',
            locked: false,
            draft: record.submissionStatus == 'draft',
            source: record.source,
          ),
        ),
      );
    }
    if (!editable && !locked) {
      final date = DateTime(_year, _month, day);
      final isOff = sheet.weeklyOffDays.contains(date.weekday % 7);
      return Tooltip(
        message: isOff ? 'Weekly off' : 'Not eligible',
        child: const SizedBox(width: 38, child: Center(child: Text('—'))),
      );
    }
    final status = _statuses[key] ?? 'present';
    final badge = _statusBadge(
      status,
      locked: locked && (widget.manualOnly || !isAgentRecord),
      draft: _draftCells.contains(key),
    );
    if (locked && (widget.manualOnly || !isAgentRecord)) {
      return Tooltip(message: 'Existing attendance is locked', child: badge);
    }
    return PopupMenuButton<String>(
      tooltip: _draftCells.contains(key)
          ? 'Draft: mark ${employee.employeeName} on ${_dateValue(day)}'
          : 'Mark ${employee.employeeName} on ${_dateValue(day)}',
      onSelected: (value) => setState(() => _statuses[key] = value),
      itemBuilder: (context) => _monthlyAttendanceStatuses
          .map(
            (item) => PopupMenuItem<String>(
              value: item.value,
              child: Text(item.label),
            ),
          )
          .toList(growable: false),
      child: isAgentRecord && !widget.manualOnly
          ? Tooltip(
              message: 'Activity Watch: select to create a manual override',
              child: badge,
            )
          : badge,
    );
  }

  Widget _statusBadge(
    String status, {
    required bool locked,
    required bool draft,
    String? source,
  }) {
    final (label, color) = switch (status) {
      'half_day' => ('HD', Colors.orange),
      'leave' => ('PL', Colors.blue),
      'lop' => ('LOP', Colors.deepOrange),
      'absent' => ('A', Colors.red),
      'holiday' => ('H', Colors.indigo),
      _ => ('P', Colors.green),
    };
    final sourceLabel = switch (source) {
      'activity_watch' => 'AW',
      'login' => 'ERP',
      'manual' => 'M',
      _ => null,
    };
    final displayLabel = sourceLabel == null ? label : '$label\n$sourceLabel';
    return Container(
      width: 42,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        locked
            ? '$label🔒'
            : draft
            ? '$displayLabel•'
            : displayLabel,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: locked || sourceLabel != null ? 9 : 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _emptyStatusBadge(String label, Color color) {
    return Container(
      width: 42,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  List<MonthlyAttendanceEmployeeModel> _visibleEmployees(
    MonthlyAttendanceSheetModel? sheet,
  ) {
    if (sheet == null) return const <MonthlyAttendanceEmployeeModel>[];
    if (widget.manualOnly) return sheet.employees;
    final employeeIds = sheet.attendance
        .where(_recordMatchesFilters)
        .map((record) => record.employeeId)
        .whereType<int>()
        .toSet();
    final query = _searchController.text.trim().toLowerCase();
    return sheet.employees
        .where(
          (employee) =>
              employeeIds.contains(employee.id) &&
              (_filterEmployeeIds.isEmpty ||
                  _filterEmployeeIds.contains(employee.id)) &&
              (query.isEmpty ||
                  employee.employeeName.toLowerCase().contains(query) ||
                  (employee.employeeCode ?? '').toLowerCase().contains(query)),
        )
        .toList(growable: false);
  }

  List<MonthlyAttendanceEmployeeModel> _pagedEmployees(
    MonthlyAttendanceSheetModel sheet,
  ) {
    final employees = _visibleEmployees(sheet);
    if (employees.isEmpty) return employees;
    final start = (_page - 1) * _perPage;
    if (start >= employees.length) {
      return const <MonthlyAttendanceEmployeeModel>[];
    }
    final end = (start + _perPage) > employees.length
        ? employees.length
        : start + _perPage;
    return employees.sublist(start, end);
  }

  Widget _buildPagination(MonthlyAttendanceSheetModel sheet) {
    final total = _visibleEmployees(sheet).length;
    final lastPage = total == 0 ? 1 : (total + _perPage - 1) ~/ _perPage;
    return ReportPaginationBar(
      meta: PaginationMeta(
        currentPage: _page,
        lastPage: lastPage,
        perPage: _perPage,
        total: total,
      ),
      perPageOptions: const <int>[10, 20, 50],
      onPerPageChanged: (value) {
        setState(() {
          _perPage = value;
          _page = 1;
        });
      },
      onPageChanged: (value) => setState(() => _page = value),
    );
  }

  bool _recordMatchesFilters(AttendanceRecordModel record) {
    final status = record.status ?? '';
    final source = record.source ?? 'manual';
    return (_filterStatuses.isEmpty || _filterStatuses.contains(status)) &&
        (_filterSources.isEmpty || _filterSources.contains(source));
  }

  Future<void> _openSavedRecord(AttendanceRecordModel record) async {
    final id = record.id;
    final companyId = _companyId;
    if (id == null || companyId == null) return;
    await openAttendanceRecordEditor(
      context,
      hr: _service,
      companyId: companyId,
      recordId: id,
      onSaved: _load,
    );
  }

  String _monthName(int month) => const <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];
}
