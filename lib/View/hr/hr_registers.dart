import '../../screen.dart';
import '../purchase/purchase_register_page.dart';
import '../purchase/purchase_support.dart';
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
    required this.controller,
    required this.hint,
  });

  final String? companyBanner;
  final TextEditingController controller;
  final String hint;

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
        AppFormTextField(
          labelText: 'Search',
          controller: controller,
          hintText: hint,
        ),
      ],
    );
  }
}

String _payrollPeriodLabel(Map<String, dynamic> data) {
  final y = stringValue(data, 'payroll_year');
  final m = stringValue(data, 'payroll_month');
  if (y.isEmpty || m.isEmpty) {
    return '';
  }
  return '$y-${m.padLeft(2, '0')}';
}

int? _attendanceRowCompanyId(AttendanceRecordModel row) {
  final emp = _asJsonMap(row.toJson()['employee']);
  if (emp == null) {
    return null;
  }
  return intValue(emp, 'company_id');
}

int? _expenseRowCompanyId(ExpenseClaimModel row) {
  return intValue(row.toJson(), 'company_id');
}

int? _payslipRowCompanyId(PayslipModel row) {
  final data = row.toJson();
  final line =
      _asJsonMap(data['payroll_line']) ?? _asJsonMap(data['payrollLine']);
  if (line == null) {
    return null;
  }
  final emp = _asJsonMap(line['employee']);
  if (emp == null) {
    return null;
  }
  return intValue(emp, 'company_id');
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
  bool _loading = true;
  String? _error;
  String? _companyBanner;
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
      final response = await _service.attendance(
        filters: const {'per_page': 200},
      );
      if (!mounted) {
        return;
      }
      var rows = response.data ?? const <AttendanceRecordModel>[];
      final cid = info.companyId;
      if (cid != null) {
        rows = rows
            .where((r) => _attendanceRowCompanyId(r) == cid)
            .toList(growable: false);
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = rows;
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
      filters: _HrCompanyContextFilters(
        companyBanner: _companyBanner,
        controller: _searchController,
        hint: 'Employee, date, status…',
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

class ExpenseClaimRegisterPage extends StatefulWidget {
  const ExpenseClaimRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ExpenseClaimRegisterPage> createState() =>
      _ExpenseClaimRegisterPageState();
}

class _ExpenseClaimRegisterPageState extends State<ExpenseClaimRegisterPage> {
  final HrService _service = HrService();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String? _error;
  String? _companyBanner;
  List<ExpenseClaimModel> _rows = const <ExpenseClaimModel>[];

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
      final response = await _service.expenseClaims(
        filters: const {'per_page': 200},
      );
      if (!mounted) {
        return;
      }
      var rows = response.data ?? const <ExpenseClaimModel>[];
      final cid = info.companyId;
      if (cid != null) {
        rows = rows
            .where((r) => _expenseRowCompanyId(r) == cid)
            .toList(growable: false);
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = rows;
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

  List<ExpenseClaimModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    return _rows
        .where((ExpenseClaimModel row) {
          final data = row.toJson();
          if (q.isEmpty) {
            return true;
          }
          return [
            stringValue(data, 'claim_no'),
            stringValue(data, 'claim_date'),
            stringValue(data, 'claim_status'),
            stringValue(data, 'total_amount'),
            _nestedEmployeeName(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<ExpenseClaimModel>(
      title: 'Expense claims',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No expense claims found.',
      actions: [
        AdaptiveShellActionButton(
          icon: Icons.add_outlined,
          label: 'New claim',
          onPressed: () async {
            final companyId = await hrResolveCompanyId(context);
            if (!context.mounted) {
              return;
            }
            if (companyId == null) {
              _showNeedCompanySnack(context);
              return;
            }
            await openExpenseClaimEditor(
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
        controller: _searchController,
        hint: 'Claim no., employee, status…',
      ),
      rows: _filtered,
      columns: [
        PurchaseRegisterColumn<ExpenseClaimModel>(
          label: 'Claim no.',
          valueBuilder: (ExpenseClaimModel row) =>
              stringValue(row.toJson(), 'claim_no'),
        ),
        PurchaseRegisterColumn<ExpenseClaimModel>(
          label: 'Date',
          valueBuilder: (ExpenseClaimModel row) => displayDate(
            nullableStringValue(row.toJson(), 'claim_date'),
          ),
        ),
        PurchaseRegisterColumn<ExpenseClaimModel>(
          label: 'Employee',
          valueBuilder: (ExpenseClaimModel row) =>
              _nestedEmployeeName(row.toJson()),
        ),
        PurchaseRegisterColumn<ExpenseClaimModel>(
          label: 'Amount',
          valueBuilder: (ExpenseClaimModel row) =>
              stringValue(row.toJson(), 'total_amount'),
        ),
        PurchaseRegisterColumn<ExpenseClaimModel>(
          label: 'Status',
          valueBuilder: (ExpenseClaimModel row) =>
              stringValue(row.toJson(), 'claim_status'),
        ),
      ],
      onRowTap: (ExpenseClaimModel row) async {
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
        await showExpenseClaimDetailDialog(
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
        controller: _searchController,
        hint: 'Period, status, run date…',
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
  bool _loading = true;
  String? _error;
  String? _companyBanner;
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
      final response = await _service.payslips(
        filters: const {'per_page': 200},
      );
      if (!mounted) {
        return;
      }
      var rows = response.data ?? const <PayslipModel>[];
      final cid = info.companyId;
      if (cid != null) {
        rows = rows
            .where((r) => _payslipRowCompanyId(r) == cid)
            .toList(growable: false);
      }
      setState(() {
        _companyBanner = info.banner;
        _rows = rows;
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

  @override
  Widget build(BuildContext context) {
    return PurchaseRegisterPage<PayslipModel>(
      title: 'Payslips',
      embedded: widget.embedded,
      loading: _loading,
      errorMessage: _error,
      onRetry: _load,
      emptyMessage: 'No payslips found.',
      actions: const <Widget>[],
      filters: _HrCompanyContextFilters(
        companyBanner: _companyBanner,
        controller: _searchController,
        hint: 'Employee, period, date…',
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
