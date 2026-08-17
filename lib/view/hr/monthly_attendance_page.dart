import '../../screen.dart';

const List<AppDropdownItem<String>> _monthlyAttendanceStatuses =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'present', label: 'Present'),
      AppDropdownItem(value: 'half_day', label: 'Half day'),
      AppDropdownItem(value: 'leave', label: 'Paid leave'),
      AppDropdownItem(value: 'lop', label: 'LOP'),
      AppDropdownItem(value: 'absent', label: 'Absent'),
    ];

class MonthlyAttendancePage extends StatefulWidget {
  const MonthlyAttendancePage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MonthlyAttendancePage> createState() => _MonthlyAttendancePageState();
}

class _MonthlyAttendancePageState extends State<MonthlyAttendancePage> {
  final HrService _service = HrService();
  final ScrollController _pageScrollController = ScrollController();
  final ScrollController _gridScrollController = ScrollController();
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
  final Map<String, String> _statuses = <String, String>{};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _gridScrollController.dispose();
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
      for (final employee in sheet.employees) {
        for (var day = 1; day <= sheet.daysInMonth; day++) {
          if (_isEditable(employee, day, sheet)) {
            _statuses[_dateKey(employee.id, day)] = 'present';
          }
        }
      }
      for (final record in sheet.attendance) {
        final employeeId = record.employeeId;
        final date = DateTime.tryParse(record.attendanceDate ?? '');
        if (employeeId == null || date == null) continue;
        final key = _dateKey(employeeId, date.day);
        _statuses[key] = record.status ?? 'present';
        if (record.submissionStatus == 'draft' && record.source == 'manual') {
          _draftCells.add(key);
        } else {
          _lockedCells.add(key);
        }
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
        if (!_isEditable(employee, day, sheet) || _lockedCells.contains(key)) {
          continue;
        }
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

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      AdaptiveShellActionButton(
        icon: Icons.refresh_outlined,
        label: 'Reload',
        filled: false,
        onPressed: _loading || _saving ? null : _load,
      ),
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
    ];
    final content = _buildContent();
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'Monthly Attendance',
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
                  mappedItems: List<AppDropdownItem<int>>.generate(7, (index) {
                    final value = DateTime.now().year - 4 + index;
                    return AppDropdownItem<int>(value: value, label: '$value');
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
                  'Eligible days default to Present. Mark only the exceptions; existing records are locked.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          if (_loading)
            const AppLoadingView(message: 'Loading monthly attendance...')
          else if (_error != null)
            AppErrorStateView(
              title: 'Unable to load monthly attendance',
              message: _error!,
              onRetry: _load,
            )
          else if ((_sheet?.employees ?? const []).isEmpty)
            const AppSectionCard(
              child: Text(
                'No eligible manual-attendance employees found. This screen only lists employees without an active ERP user.',
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
        Text('• = Draft (not in payroll)'),
        Text('🔒 = Existing record'),
      ],
    ),
  );

  Widget _buildGrid(MonthlyAttendanceSheetModel sheet) {
    return AppSectionCard(
      child: Scrollbar(
        controller: _gridScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _gridScrollController,
          scrollDirection: Axis.horizontal,
          child: DataTable(
            showCheckboxColumn: true,
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
            rows: sheet.employees
                .map((employee) {
                  return DataRow(
                    selected: _selectedEmployees.contains(employee.id),
                    onSelectChanged: (selected) {
                      setState(() {
                        if (selected == true) {
                          _selectedEmployees.add(employee.id);
                        } else {
                          _selectedEmployees.remove(employee.id);
                        }
                      });
                    },
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
      locked: locked,
      draft: _draftCells.contains(key),
    );
    if (locked) {
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
      child: badge,
    );
  }

  Widget _statusBadge(
    String status, {
    required bool locked,
    required bool draft,
  }) {
    final (label, color) = switch (status) {
      'half_day' => ('HD', Colors.orange),
      'leave' => ('PL', Colors.blue),
      'lop' => ('LOP', Colors.deepOrange),
      'absent' => ('A', Colors.red),
      _ => ('P', Colors.green),
    };
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
            ? '$label•'
            : label,
        style: TextStyle(
          color: color,
          fontSize: locked ? 9 : 11,
          fontWeight: FontWeight.w700,
        ),
      ),
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
