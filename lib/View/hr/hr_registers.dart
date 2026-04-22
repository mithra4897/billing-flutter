import '../../screen.dart';
import '../purchase/purchase_register_page.dart';
import '../purchase/purchase_support.dart';
import 'hr_list_filter_helpers.dart';
import 'hr_workflow_dialogs.dart';

void _showNeedCompanySnack(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Choose a company in the header session control before using HR actions.',
      ),
    ),
  );
}

Map<String, dynamic>? _asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

String _nestedEmployeeName(Map<String, dynamic> data) {
  final emp = _asJsonMap(data['employee']);
  if (emp == null) {
    return '';
  }
  return stringValue(emp, 'employee_name');
}

String _payslipLineEmployeeName(Map<String, dynamic> payslipData) {
  final line =
      _asJsonMap(payslipData['payroll_line']) ??
      _asJsonMap(payslipData['payrollLine']);
  if (line == null) {
    return '';
  }
  return _nestedEmployeeName(line);
}

String _payslipPayrollPeriod(Map<String, dynamic> payslipData) {
  final line =
      _asJsonMap(payslipData['payroll_line']) ??
      _asJsonMap(payslipData['payrollLine']);
  if (line == null) {
    return '';
  }
  final run =
      _asJsonMap(line['payroll_run']) ?? _asJsonMap(line['payrollRun']);
  if (run == null) {
    return '';
  }
  final y = stringValue(run, 'payroll_year');
  final m = stringValue(run, 'payroll_month');
  if (y.isEmpty || m.isEmpty) {
    return '';
  }
  return '$y-${m.padLeft(2, '0')}';
}

String _payslipNetSalary(Map<String, dynamic> payslipData) {
  final line =
      _asJsonMap(payslipData['payroll_line']) ??
      _asJsonMap(payslipData['payrollLine']);
  if (line == null) {
    return '';
  }
  return stringValue(line, 'net_salary');
}

class _HrCompanyContextFilters extends StatelessWidget {
  const _HrCompanyContextFilters({
    required this.companyBanner,
    this.searchController,
    this.searchHint,
  });

  final String? companyBanner;
  final TextEditingController? searchController;
  final String? searchHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (companyBanner != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.apartment_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppUiConstants.spacingSm),
                Expanded(
                  child: Text(
                    'Session company: $companyBanner. Change via the header '
                    'session button.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: AppUiConstants.spacingSm),
                Expanded(
                  child: Text(
                    'No company in session. Open the header session menu and '
                    'select a company. Lists below show all companies until then.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (searchController != null &&
            (searchHint != null && searchHint!.trim().isNotEmpty))
          AppFormTextField(
            labelText: 'Search',
            controller: searchController!,
            hintText: searchHint,
          ),
      ],
    );
  }
}

const List<AppDropdownItem<String?>> _hrAttendanceStatusFilterItems =
    <AppDropdownItem<String?>>[
  AppDropdownItem<String?>(value: null, label: 'All statuses'),
  AppDropdownItem<String?>(value: 'present', label: 'Present'),
  AppDropdownItem<String?>(value: 'absent', label: 'Absent'),
  AppDropdownItem<String?>(value: 'leave', label: 'Leave'),
  AppDropdownItem<String?>(value: 'half_day', label: 'Half day'),
  AppDropdownItem<String?>(value: 'holiday', label: 'Holiday'),
];

String _payrollPeriodLabel(Map<String, dynamic> data) {
  final y = stringValue(data, 'payroll_year');
  final m = stringValue(data, 'payroll_month');
  if (y.isEmpty || m.isEmpty) {
    return '';
  }
  return '$y-${m.padLeft(2, '0')}';
}

class AttendanceRegisterPage extends StatefulWidget {
  const AttendanceRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AttendanceRegisterPage> createState() =>
      _AttendanceRegisterPageState();
}

class _AttendanceRegisterPageState extends State<AttendanceRegisterPage> {
  final HrService _service = HrService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  int? _sessionCompanyId;
  bool _canViewAllHr = false;
  int? _filterEmployeeId;
  String? _filterAttendanceStatus;
  List<EmployeeModel> _employees = const <EmployeeModel>[];
  List<AttendanceRecordModel> _rows = const <AttendanceRecordModel>[];

  @override
  void initState() {
    super.initState();
    WorkingContextService.version.addListener(_onWorkingContextChanged);
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    WorkingContextService.version.removeListener(_onWorkingContextChanged);
    _searchController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    super.dispose();
  }

  void _onWorkingContextChanged() {
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await hrSessionCompanyInfo();
      final cid = info.companyId;
      if (cid == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _companyBanner = info.banner;
          _sessionCompanyId = null;
          _canViewAllHr = false;
          _employees = const <EmployeeModel>[];
          _rows = const <AttendanceRecordModel>[];
          _loading = false;
          _error = 'Select a session company to load attendance records.';
        });
        return;
      }

      final ctxRes = await _service.expenseClaimsLinkedEmployee(
        companyId: cid,
      );
      final ctx = ctxRes.data ?? const <String, dynamic>{};
      final viewAll =
          ctx['can_view_all_hr_records'] == true ||
          ctx['can_view_all_hr_records'] == 1 ||
          ctx['can_view_all_claims'] == true ||
          ctx['can_view_all_claims'] == 1;
      final linked = intValue(ctx, 'employee_id');

      if (!viewAll && linked == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _companyBanner = info.banner;
          _sessionCompanyId = cid;
          _canViewAllHr = false;
          _employees = const <EmployeeModel>[];
          _rows = const <AttendanceRecordModel>[];
          _loading = false;
          _error =
              'No employee record is linked to your user for this company. '
              'Your user employee code must match an employee in HR.';
        });
        return;
      }

      var employees = const <EmployeeModel>[];
      if (viewAll) {
        final empResp = await _service.employees(
          filters: <String, dynamic>{
            'company_id': cid,
            'per_page': 500,
            'sort_by': 'employee_name',
          },
        );
        employees = empResp.data ?? const <EmployeeModel>[];
      }

      final filters = <String, dynamic>{
        'company_id': cid,
        'per_page': 200,
      };
      if (viewAll && _filterEmployeeId != null) {
        filters['employee_id'] = _filterEmployeeId;
      }
      if (viewAll &&
          _filterAttendanceStatus != null &&
          _filterAttendanceStatus!.isNotEmpty) {
        filters['status'] = _filterAttendanceStatus;
      }
      final dateFrom = _dateFromController.text.trim();
      final dateTo = _dateToController.text.trim();
      if (dateFrom.isNotEmpty) {
        filters['date_from'] = dateFrom;
      }
      if (dateTo.isNotEmpty) {
        filters['date_to'] = dateTo;
      }

      final response = await _service.attendance(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _sessionCompanyId = cid;
        _canViewAllHr = viewAll;
        _employees = employees;
        _rows = response.data ?? const <AttendanceRecordModel>[];
        _loading = false;
        _error = null;
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

  List<AttendanceRecordModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((AttendanceRecordModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          final emp = _asJsonMap(data['employee']);
          final code = emp != null ? stringValue(emp, 'employee_code') : '';
          final name = emp != null ? stringValue(emp, 'employee_name') : '';
          return [
            stringValue(data, 'id'),
            stringValue(data, 'employee_id'),
            code,
            name,
            stringValue(data, 'attendance_date'),
            stringValue(data, 'status'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  String _attendanceSelectedEmployeeLabel() {
    if (_filterEmployeeId == null) {
      return '';
    }
    for (final EmployeeModel e in _employees) {
      if (e.id == _filterEmployeeId) {
        return e.toString();
      }
    }
    return 'Employee #$_filterEmployeeId';
  }

  List<String> _attendanceAppliedFilterChips() {
    final chips = <String>[
      if (_companyBanner != null) 'Company: $_companyBanner',
      if (_searchController.text.trim().isNotEmpty)
        'Search: ${_searchController.text.trim()}',
      if (_canViewAllHr && _filterEmployeeId != null)
        'Employee: ${_attendanceSelectedEmployeeLabel()}',
      if (_canViewAllHr &&
          (_filterAttendanceStatus ?? '').isNotEmpty)
        'Status: ${hrDropdownLabel(_hrAttendanceStatusFilterItems, _filterAttendanceStatus)}',
      if (_dateFromController.text.trim().isNotEmpty)
        'From: ${_dateFromController.text.trim()}',
      if (_dateToController.text.trim().isNotEmpty)
        'To: ${_dateToController.text.trim()}',
    ];
    return chips;
  }

  void _clearAttendanceFilters() {
    setState(() {
      _searchController.clear();
      _filterEmployeeId = null;
      _filterAttendanceStatus = null;
      _dateFromController.clear();
      _dateToController.clear();
    });
  }

  Future<void> _openAttendanceFilterPanel() async {
    final applied = await showHrListFilterDialog(
      context: context,
      title: 'Filter Attendance',
      header: _companyBanner == null
          ? null
          : Text(
              'Session company: $_companyBanner. Change via the header '
              'session button.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
      filterFields: [
        hrListFilterBox(
          child: AppFormTextField(
            controller: _searchController,
            labelText: 'Search',
            hintText: 'Employee, date, status…',
          ),
        ),
        if (_canViewAllHr) ...[
          hrListFilterBox(
            child: AppDropdownField<int?>.fromMapped(
              labelText: 'Employee filter',
              mappedItems: <AppDropdownItem<int?>>[
                const AppDropdownItem<int?>(
                  value: null,
                  label: 'All employees',
                ),
                ..._employees
                    .where(
                      (EmployeeModel e) =>
                          e.companyId == _sessionCompanyId && e.id != null,
                    )
                    .map(
                      (EmployeeModel e) => AppDropdownItem<int?>(
                        value: e.id,
                        label: e.toString(),
                      ),
                    ),
              ],
              initialValue: _filterEmployeeId,
              onChanged: (int? v) => setState(() => _filterEmployeeId = v),
            ),
          ),
          hrListFilterBox(
            child: AppDropdownField<String?>.fromMapped(
              labelText: 'Status',
              mappedItems: _hrAttendanceStatusFilterItems,
              initialValue: _filterAttendanceStatus,
              onChanged: (String? v) =>
                  setState(() => _filterAttendanceStatus = v),
            ),
          ),
        ],
        hrListFilterBox(
          child: AppFormTextField(
            controller: _dateFromController,
            labelText: 'From date',
            keyboardType: TextInputType.datetime,
            inputFormatters: const [DateInputFormatter()],
          ),
        ),
        hrListFilterBox(
          child: AppFormTextField(
            controller: _dateToController,
            labelText: 'To date',
            keyboardType: TextInputType.datetime,
            inputFormatters: const [DateInputFormatter()],
          ),
        ),
      ],
      onClear: _clearAttendanceFilters,
    );
    if (applied == true && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<AttendanceRecordModel>(
      title: 'Attendance',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No attendance records found.',
      actions: [
        AdaptiveShellActionButton(
          icon: Icons.filter_alt_outlined,
          label: 'Filter',
          filled: false,
          onPressed: _openAttendanceFilterPanel,
        ),
        AdaptiveShellActionButton(
          icon: Icons.add_outlined,
          label: 'New attendance',
          onPressed: () async {
            final companyId = await hrResolveCompanyId(context);
            if (!context.mounted) {
              return;
            }
            if (companyId == null) {
              _showNeedCompanySnack(context);
              return;
            }
            await openAttendanceRecordEditor(
              context,
              hr: _service,
              companyId: companyId,
              onSaved: _load,
            );
          },
        ),
      ],
      filters: hrListAppliedFiltersCard(
        context,
        _attendanceAppliedFilterChips(),
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<AttendanceRecordModel>(
          label: 'Employee',
          valueBuilder: (AttendanceRecordModel row) =>
              _nestedEmployeeName(row.toJson()),
        ),
        PurchaseRegisterColumn<AttendanceRecordModel>(
          label: 'Date',
          valueBuilder: (AttendanceRecordModel row) => displayDate(
            nullableStringValue(row.toJson(), 'attendance_date'),
          ),
        ),
        PurchaseRegisterColumn<AttendanceRecordModel>(
          label: 'Status',
          valueBuilder: (AttendanceRecordModel row) =>
              stringValue(row.toJson(), 'status'),
        ),
        PurchaseRegisterColumn<AttendanceRecordModel>(
          label: 'Check in',
          valueBuilder: (AttendanceRecordModel row) => displayDateTime(
            nullableStringValue(row.toJson(), 'check_in'),
          ),
        ),
      ],
      onRowTap: (AttendanceRecordModel row) async {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        final companyId = await hrResolveCompanyId(context);
        if (!context.mounted) {
          return;
        }
        if (companyId == null) {
          _showNeedCompanySnack(context);
          return;
        }
        await showAttendanceRecordDetailDialog(
          context,
          hr: _service,
          id: id,
          companyId: companyId,
          onChanged: _load,
        );
      },
    );
  }
}

class PayrollRunRegisterPage extends StatefulWidget {
  const PayrollRunRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PayrollRunRegisterPage> createState() =>
      _PayrollRunRegisterPageState();
}

class _PayrollRunRegisterPageState extends State<PayrollRunRegisterPage> {
  final HrService _service = HrService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<PayrollRunModel> _rows = const <PayrollRunModel>[];

  @override
  void initState() {
    super.initState();
    WorkingContextService.version.addListener(_onWorkingContextChanged);
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    WorkingContextService.version.removeListener(_onWorkingContextChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onWorkingContextChanged() {
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await hrSessionCompanyInfo();
      final filters = <String, dynamic>{'per_page': 200};
      if (info.companyId != null) {
        filters['company_id'] = info.companyId;
      }
      final response = await _service.payrollRuns(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = response.data ?? const <PayrollRunModel>[];
        _loading = false;
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

  List<PayrollRunModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((PayrollRunModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            _payrollPeriodLabel(data),
            stringValue(data, 'run_date'),
            stringValue(data, 'status'),
            stringValue(data, 'lines_count'),
            stringValue(data, 'company_id'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<PayrollRunModel>(
      title: 'Payroll runs',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No payroll runs found.',
      actions: [
        AdaptiveShellActionButton(
          icon: Icons.add_outlined,
          label: 'New payroll run',
          onPressed: () async {
            final companyId = await hrResolveCompanyId(context);
            if (!context.mounted) {
              return;
            }
            if (companyId == null) {
              _showNeedCompanySnack(context);
              return;
            }
            await openPayrollRunEditor(
              context,
              hr: _service,
              companyId: companyId,
              onSaved: _load,
            );
          },
        ),
      ],
      filters: _HrCompanyContextFilters(
        companyBanner: _companyBanner,
        searchController: _searchController,
        searchHint: 'Period, status, run date…',
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<PayrollRunModel>(
          label: 'Period',
          valueBuilder: (PayrollRunModel row) =>
              _payrollPeriodLabel(row.toJson()),
        ),
        PurchaseRegisterColumn<PayrollRunModel>(
          label: 'Run date',
          valueBuilder: (PayrollRunModel row) => displayDate(
            nullableStringValue(row.toJson(), 'run_date'),
          ),
        ),
        PurchaseRegisterColumn<PayrollRunModel>(
          label: 'Status',
          valueBuilder: (PayrollRunModel row) =>
              stringValue(row.toJson(), 'status'),
        ),
        PurchaseRegisterColumn<PayrollRunModel>(
          label: 'Lines',
          valueBuilder: (PayrollRunModel row) =>
              stringValue(row.toJson(), 'lines_count'),
        ),
      ],
      onRowTap: (PayrollRunModel row) async {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        final companyId = await hrResolveCompanyId(context);
        if (!context.mounted) {
          return;
        }
        if (companyId == null) {
          _showNeedCompanySnack(context);
          return;
        }
        await showPayrollRunDetailDialog(
          context,
          hr: _service,
          id: id,
          companyId: companyId,
          onChanged: _load,
        );
      },
    );
  }
}

class PayslipRegisterPage extends StatefulWidget {
  const PayslipRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PayslipRegisterPage> createState() => _PayslipRegisterPageState();
}

class _PayslipRegisterPageState extends State<PayslipRegisterPage> {
  final HrService _service = HrService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  int? _sessionCompanyId;
  bool _canViewAllHr = false;
  int? _filterEmployeeId;
  List<EmployeeModel> _employees = const <EmployeeModel>[];
  List<PayslipModel> _rows = const <PayslipModel>[];

  @override
  void initState() {
    super.initState();
    WorkingContextService.version.addListener(_onWorkingContextChanged);
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    WorkingContextService.version.removeListener(_onWorkingContextChanged);
    _searchController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    super.dispose();
  }

  void _onWorkingContextChanged() {
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await hrSessionCompanyInfo();
      final cid = info.companyId;
      if (cid == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _companyBanner = info.banner;
          _sessionCompanyId = null;
          _canViewAllHr = false;
          _employees = const <EmployeeModel>[];
          _rows = const <PayslipModel>[];
          _loading = false;
          _error = 'Select a session company to load payslips.';
        });
        return;
      }

      final ctxRes = await _service.expenseClaimsLinkedEmployee(
        companyId: cid,
      );
      final ctx = ctxRes.data ?? const <String, dynamic>{};
      final viewAll =
          ctx['can_view_all_hr_records'] == true ||
          ctx['can_view_all_hr_records'] == 1 ||
          ctx['can_view_all_claims'] == true ||
          ctx['can_view_all_claims'] == 1;
      final linked = intValue(ctx, 'employee_id');

      if (!viewAll && linked == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _companyBanner = info.banner;
          _sessionCompanyId = cid;
          _canViewAllHr = false;
          _employees = const <EmployeeModel>[];
          _rows = const <PayslipModel>[];
          _loading = false;
          _error =
              'No employee record is linked to your user for this company. '
              'Your user employee code must match an employee in HR.';
        });
        return;
      }

      var employees = const <EmployeeModel>[];
      if (viewAll) {
        final empResp = await _service.employees(
          filters: <String, dynamic>{
            'company_id': cid,
            'per_page': 500,
            'sort_by': 'employee_name',
          },
        );
        employees = empResp.data ?? const <EmployeeModel>[];
      }

      final filters = <String, dynamic>{
        'company_id': cid,
        'per_page': 200,
      };
      if (viewAll && _filterEmployeeId != null) {
        filters['employee_id'] = _filterEmployeeId;
      }
      final dateFrom = _dateFromController.text.trim();
      final dateTo = _dateToController.text.trim();
      if (dateFrom.isNotEmpty) {
        filters['date_from'] = dateFrom;
      }
      if (dateTo.isNotEmpty) {
        filters['date_to'] = dateTo;
      }

      final response = await _service.payslips(filters: filters);
      if (!mounted) {
        return;
      }
      setState(() {
        _companyBanner = info.banner;
        _sessionCompanyId = cid;
        _canViewAllHr = viewAll;
        _employees = employees;
        _rows = response.data ?? const <PayslipModel>[];
        _loading = false;
        _error = null;
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

  List<PayslipModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((PayslipModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'id'),
            displayDate(nullableStringValue(data, 'payslip_date')),
            _payslipLineEmployeeName(data),
            _payslipPayrollPeriod(data),
            _payslipNetSalary(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  String _payslipSelectedEmployeeLabel() {
    if (_filterEmployeeId == null) {
      return '';
    }
    for (final EmployeeModel e in _employees) {
      if (e.id == _filterEmployeeId) {
        return e.toString();
      }
    }
    return 'Employee #$_filterEmployeeId';
  }

  List<String> _payslipAppliedFilterChips() {
    return <String>[
      if (_companyBanner != null) 'Company: $_companyBanner',
      if (_searchController.text.trim().isNotEmpty)
        'Search: ${_searchController.text.trim()}',
      if (_canViewAllHr && _filterEmployeeId != null)
        'Employee: ${_payslipSelectedEmployeeLabel()}',
      if (_dateFromController.text.trim().isNotEmpty)
        'From: ${_dateFromController.text.trim()}',
      if (_dateToController.text.trim().isNotEmpty)
        'To: ${_dateToController.text.trim()}',
    ];
  }

  void _clearPayslipFilters() {
    setState(() {
      _searchController.clear();
      _filterEmployeeId = null;
      _dateFromController.clear();
      _dateToController.clear();
    });
  }

  Future<void> _openPayslipFilterPanel() async {
    final applied = await showHrListFilterDialog(
      context: context,
      title: 'Filter Payslips',
      header: _companyBanner == null
          ? null
          : Text(
              'Session company: $_companyBanner. Change via the header '
              'session button.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
      filterFields: [
        hrListFilterBox(
          child: AppFormTextField(
            controller: _searchController,
            labelText: 'Search',
            hintText: 'Employee, period, date…',
          ),
        ),
        if (_canViewAllHr)
          hrListFilterBox(
            child: AppDropdownField<int?>.fromMapped(
              labelText: 'Employee filter',
              mappedItems: <AppDropdownItem<int?>>[
                const AppDropdownItem<int?>(
                  value: null,
                  label: 'All employees',
                ),
                ..._employees
                    .where(
                      (EmployeeModel e) =>
                          e.companyId == _sessionCompanyId && e.id != null,
                    )
                    .map(
                      (EmployeeModel e) => AppDropdownItem<int?>(
                        value: e.id,
                        label: e.toString(),
                      ),
                    ),
              ],
              initialValue: _filterEmployeeId,
              onChanged: (int? v) => setState(() => _filterEmployeeId = v),
            ),
          ),
        hrListFilterBox(
          child: AppFormTextField(
            controller: _dateFromController,
            labelText: 'Payslip from date',
            keyboardType: TextInputType.datetime,
            inputFormatters: const [DateInputFormatter()],
          ),
        ),
        hrListFilterBox(
          child: AppFormTextField(
            controller: _dateToController,
            labelText: 'Payslip to date',
            keyboardType: TextInputType.datetime,
            inputFormatters: const [DateInputFormatter()],
          ),
        ),
      ],
      onClear: _clearPayslipFilters,
    );
    if (applied == true && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<PayslipModel>(
      title: 'Payslips',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No payslips found.',
      actions: [
        AdaptiveShellActionButton(
          icon: Icons.filter_alt_outlined,
          label: 'Filter',
          filled: false,
          onPressed: _openPayslipFilterPanel,
        ),
        AdaptiveShellActionButton(
          icon: Icons.refresh,
          label: 'Refresh',
          onPressed: _load,
        ),
      ],
      filters: hrListAppliedFiltersCard(
        context,
        _payslipAppliedFilterChips(),
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<PayslipModel>(
          label: 'Date',
          valueBuilder: (PayslipModel row) => displayDate(
            nullableStringValue(row.toJson(), 'payslip_date'),
          ),
        ),
        PurchaseRegisterColumn<PayslipModel>(
          label: 'Employee',
          valueBuilder: (PayslipModel row) =>
              _payslipLineEmployeeName(row.toJson()),
        ),
        PurchaseRegisterColumn<PayslipModel>(
          label: 'Period',
          valueBuilder: (PayslipModel row) =>
              _payslipPayrollPeriod(row.toJson()),
        ),
        PurchaseRegisterColumn<PayslipModel>(
          label: 'Net',
          valueBuilder: (PayslipModel row) =>
              _payslipNetSalary(row.toJson()),
        ),
      ],
      onRowTap: (PayslipModel row) {
        final id = intValue(row.toJson(), 'id');
        if (id == null) {
          return;
        }
        showPayslipDetailDialog(context, hr: _service, id: id);
      },
    );
  }
}
