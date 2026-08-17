import '../../screen.dart';

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
  });

  final bool embedded;
  final bool manualOnly;

  @override
  State<MonthlyAttendancePage> createState() => _MonthlyAttendancePageState();
}

class _MonthlyAttendancePageState extends State<MonthlyAttendancePage> {
  final HrService _service = HrService();
  final ScrollController _pageScrollController = ScrollController();
  final ScrollController _gridScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late int _year;
  late int _month;
  int? _companyId;
  bool _loading = true;
  bool _saving = false;
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _gridScrollController.dispose();
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
        includeSystemEmployees: !widget.manualOnly,
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
      _selectedEmployees
        ..clear()
        ..addAll(sheet.employees.map((employee) => employee.id));
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
      if (mounted) setState(() => _loading = false);
    }
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

  Future<void> _save({required bool submit}) async {
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

    if (submit) {
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
    }

    setState(() => _saving = true);
    try {
      final response = await _service.saveMonthlyAttendance(
        companyId: companyId,
        year: _year,
        month: _month,
        records: records,
        saveMode: submit ? 'submit' : 'draft',
        includeSystemEmployees: !widget.manualOnly,
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
            submit
                ? 'Submitted $changed monthly attendance record(s) for payroll.'
                : 'Saved $changed monthly attendance record(s) as draft.',
          ),
        ),
      );
      if (submit && widget.manualOnly) {
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

  Future<void> _openPeriodFilter() async {
    var nextMonth = _month;
    var nextYear = _year;
    var nextEmployeeIds = Set<int>.from(_filterEmployeeIds);
    var nextStatuses = Set<String>.from(_filterStatuses);
    var nextSources = Set<String>.from(_filterSources);
    final nextSearchController = TextEditingController(
      text: _searchController.text,
    );
    final applied = await showHrListFilterDialog(
      context: context,
      title: 'Filter Attendance',
      filterFields: [
        hrListFilterBox(
          child: AppFormTextField(
            controller: nextSearchController,
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
            multiInitialValues: nextEmployeeIds,
            multiHintText: 'Select employees',
            onMultiChanged: (values) {
              nextEmployeeIds = Set<int>.from(values);
            },
          ),
        ),
        hrListFilterBox(
          child: AppDropdownField<String>.fromMapped(
            labelText: 'Status',
            mappedItems: _attendanceStatusFilters,
            multiInitialValues: nextStatuses,
            multiHintText: 'Select statuses',
            onMultiChanged: (values) {
              nextStatuses = Set<String>.from(values);
            },
          ),
        ),
        hrListFilterBox(
          child: AppDropdownField<String>.fromMapped(
            labelText: 'Source',
            mappedItems: _attendanceSourceFilters,
            multiInitialValues: nextSources,
            multiHintText: 'Select sources',
            onMultiChanged: (values) {
              nextSources = Set<String>.from(values);
            },
          ),
        ),
        hrListFilterBox(
          child: AppDropdownField<int>.fromMapped(
            labelText: 'Month',
            initialValue: nextMonth,
            mappedItems: List<AppDropdownItem<int>>.generate(
              12,
              (index) => AppDropdownItem<int>(
                value: index + 1,
                label: _monthName(index + 1),
              ),
            ),
            onChanged: (value) {
              if (value != null) nextMonth = value;
            },
          ),
        ),
        hrListFilterBox(
          child: AppDropdownField<int>.fromMapped(
            labelText: 'Year',
            initialValue: nextYear,
            mappedItems: List<AppDropdownItem<int>>.generate(7, (index) {
              final value = DateTime.now().year - 4 + index;
              return AppDropdownItem<int>(value: value, label: '$value');
            }),
            onChanged: (value) {
              if (value != null) nextYear = value;
            },
          ),
        ),
      ],
      onClear: () {
        final now = DateTime.now();
        nextMonth = now.month;
        nextYear = now.year;
        nextSearchController.clear();
        nextEmployeeIds = <int>{};
        nextStatuses = <String>{};
        nextSources = <String>{};
      },
    );
    if (applied != true || !mounted) {
      nextSearchController.dispose();
      return;
    }
    final periodChanged = nextMonth != _month || nextYear != _year;
    setState(() {
      _month = nextMonth;
      _year = nextYear;
      _searchController.text = nextSearchController.text;
      _filterEmployeeIds = nextEmployeeIds;
      _filterStatuses = nextStatuses;
      _filterSources = nextSources;
    });
    nextSearchController.dispose();
    if (periodChanged) {
      _attendanceReportYear = _year;
      _attendanceReportMonth = _month;
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      if (!widget.manualOnly)
        AdaptiveShellActionButton(
          icon: Icons.filter_alt_outlined,
          label: 'Filter',
          filled: false,
          onPressed: _loading || _saving ? null : _openPeriodFilter,
        ),
      AdaptiveShellActionButton(
        icon: Icons.refresh_outlined,
        label: 'Reload',
        filled: false,
        onPressed: _loading || _saving ? null : _load,
      ),
      if (widget.manualOnly) ...[
        AdaptiveShellActionButton(
          icon: Icons.save_outlined,
          label: _saving ? 'Saving…' : 'Save draft',
          filled: false,
          onPressed: _loading || _saving ? null : () => _save(submit: false),
        ),
        AdaptiveShellActionButton(
          icon: Icons.task_alt_outlined,
          label: _saving ? 'Submitting…' : 'Submit attendance',
          onPressed: _loading || _saving ? null : () => _save(submit: true),
        ),
      ],
      if (!widget.manualOnly)
        AdaptiveShellActionButton(
          icon: Icons.groups_outlined,
          label: 'Bulk attendance',
          filled: false,
          onPressed: _loading || _saving
              ? null
              : () => openHrShellRoute(context, '/hr/monthly-attendance'),
        ),
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
          ] else ...[
            hrListAppliedFiltersCard(context, _appliedFilterChips()),
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
                widget.manualOnly
                    ? 'No eligible manual-attendance employees found. This screen lists employees without an active ERP user.'
                    : 'No saved attendance records match the selected filters.',
              ),
            )
          else ...[
            _buildLegend(),
            const SizedBox(height: AppUiConstants.spacingSm),
            _buildGrid(_sheet!),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend() => AppSectionCard(
    child: Wrap(
      spacing: AppUiConstants.spacingMd,
      runSpacing: AppUiConstants.spacingXs,
      children: const [
        Text('P = Present'),
        Text('HD = Half day (0.5 payable)'),
        Text('PL = Paid leave'),
        Text('LOP = Unpaid leave'),
        Text('A = Absent'),
        Text('AW = Activity Watch'),
        Text('M = Manual'),
        Text('• = Draft (not in payroll)'),
      ],
    ),
  );

  Widget _buildGrid(MonthlyAttendanceSheetModel sheet) {
    final employees = _visibleEmployees(sheet);
    return AppSectionCard(
      child: Scrollbar(
        controller: _gridScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _gridScrollController,
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: widget.manualOnly,
            headingRowHeight: 56,
            dataRowMinHeight: 54,
            dataRowMaxHeight: 54,
            columnSpacing: 12,
            columns: <DataColumn>[
              const DataColumn(
                label: SizedBox(width: 190, child: Text('Employee')),
              ),
              for (var day = 1; day <= sheet.daysInMonth; day++)
                DataColumn(
                  label: SizedBox(
                    width: 38,
                    child: Text(
                      '$day\n${_weekdayLetter(day)}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
            rows: employees
                .map((employee) {
                  return DataRow(
                    selected:
                        widget.manualOnly &&
                        _selectedEmployees.contains(employee.id),
                    onSelectChanged: widget.manualOnly
                        ? (selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedEmployees.add(employee.id);
                              } else {
                                _selectedEmployees.remove(employee.id);
                              }
                            });
                          }
                        : null,
                    cells: <DataCell>[
                      DataCell(
                        SizedBox(
                          width: 190,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                employee.employeeName,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if ((employee.employeeCode ?? '').isNotEmpty)
                                Text(
                                  employee.employeeCode!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ),
                      for (var day = 1; day <= sheet.daysInMonth; day++)
                        DataCell(_buildAttendanceCell(employee, day, sheet)),
                    ],
                  );
                })
                .toList(growable: false),
          ),
        ),
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
        return Tooltip(
          message: isOff
              ? 'Weekly off — no attendance record'
              : 'No saved attendance record',
          child: SizedBox(
            width: 42,
            child: Center(child: Text(isOff ? 'WO' : '—')),
          ),
        );
      }
      return InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _openSavedRecord(record),
        child: Tooltip(
          message:
              '${record.source == 'activity_watch' ? 'Activity Watch' : 'Manual'} attendance — open record',
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
        borderRadius: BorderRadius.circular(6),
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

  bool _recordMatchesFilters(AttendanceRecordModel record) {
    final status = record.status ?? '';
    final source = record.source ?? 'manual';
    return (_filterStatuses.isEmpty || _filterStatuses.contains(status)) &&
        (_filterSources.isEmpty || _filterSources.contains(source));
  }

  List<String> _appliedFilterChips() {
    final employeeNames = <int, String>{
      for (final employee in _sheet?.employees ?? const [])
        employee.id: employee.employeeName,
    };
    return <String>[
      'Period: ${_monthName(_month)} $_year',
      if (_searchController.text.trim().isNotEmpty)
        'Search: ${_searchController.text.trim()}',
      if (_filterEmployeeIds.isNotEmpty)
        'Employee: ${_filterEmployeeIds.map((id) => employeeNames[id] ?? id).join(', ')}',
      if (_filterStatuses.isNotEmpty)
        'Status: ${_filterStatuses.map(_attendanceStatusLabel).join(', ')}',
      if (_filterSources.isNotEmpty)
        'Source: ${_filterSources.map(_attendanceSourceLabel).join(', ')}',
    ];
  }

  String _attendanceStatusLabel(String value) =>
      hrDropdownLabel(_attendanceStatusFilters, value);

  String _attendanceSourceLabel(String value) =>
      hrDropdownLabel(_attendanceSourceFilters, value);

  Future<void> _openSavedRecord(AttendanceRecordModel record) async {
    final id = record.id;
    final companyId = _companyId;
    if (id == null || companyId == null) return;
    await showAttendanceRecordDetailDialog(
      context,
      hr: _service,
      id: id,
      companyId: companyId,
      onChanged: _load,
    );
  }

  String _weekdayLetter(int day) {
    return const <String>[
      'M',
      'T',
      'W',
      'T',
      'F',
      'S',
      'S',
    ][DateTime(_year, _month, day).weekday - 1];
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
