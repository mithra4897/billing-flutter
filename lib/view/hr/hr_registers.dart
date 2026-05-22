import '../../screen.dart';

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
  final run = _asJsonMap(line['payroll_run']) ?? _asJsonMap(line['payrollRun']);
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

class AttendanceRegisterController extends GetxController {
  final HrService _service = HrService();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();

  bool loading = true;
  String? error;
  String? companyBanner;
  int? sessionCompanyId;
  bool canViewAllHr = false;
  int? filterEmployeeId;
  String? filterAttendanceStatus;
  List<EmployeeModel> employees = const <EmployeeModel>[];
  List<AttendanceRecordModel> rows = const <AttendanceRecordModel>[];

  @override
  void onInit() {
    super.onInit();
    WorkingContextService.version.addListener(_onWorkingContextChanged);
    searchController.addListener(update);
    unawaited(load());
  }

  @override
  void onClose() {
    WorkingContextService.version.removeListener(_onWorkingContextChanged);
    searchController
      ..removeListener(update)
      ..dispose();
    dateFromController.dispose();
    dateToController.dispose();
    super.onClose();
  }

  void _onWorkingContextChanged() {
    unawaited(load());
  }

  Future<void> load() async {
    loading = true;
    error = null;
    update();
    try {
      final info = await hrSessionCompanyInfo();
      final cid = info.companyId;
      if (cid == null) {
        companyBanner = info.banner;
        sessionCompanyId = null;
        canViewAllHr = false;
        employees = const <EmployeeModel>[];
        rows = const <AttendanceRecordModel>[];
        loading = false;
        error = 'Select a session company to load attendance records.';
        update();
        return;
      }

      final ctxRes = await _service.expenseClaimsLinkedEmployee(companyId: cid);
      final ctx = ctxRes.data ?? const <String, dynamic>{};
      final viewAll =
          ctx['can_view_all_hr_records'] == true ||
          ctx['can_view_all_hr_records'] == 1 ||
          ctx['can_view_all_claims'] == true ||
          ctx['can_view_all_claims'] == 1;
      final linked = intValue(ctx, 'employee_id');

      if (!viewAll && linked == null) {
        companyBanner = info.banner;
        sessionCompanyId = cid;
        canViewAllHr = false;
        employees = const <EmployeeModel>[];
        rows = const <AttendanceRecordModel>[];
        loading = false;
        error =
            'No employee record is linked to your user for this company. '
            'Your user employee code must match an employee in HR.';
        update();
        return;
      }

      var nextEmployees = const <EmployeeModel>[];
      if (viewAll) {
        final empResp = await _service.employees(
          filters: <String, dynamic>{
            'company_id': cid,
            'per_page': 500,
            'sort_by': 'employee_name',
          },
        );
        nextEmployees = empResp.data ?? const <EmployeeModel>[];
      }

      final filters = <String, dynamic>{'company_id': cid, 'per_page': 200};
      if (viewAll && filterEmployeeId != null) {
        filters['employee_id'] = filterEmployeeId;
      }
      if (viewAll &&
          filterAttendanceStatus != null &&
          filterAttendanceStatus!.isNotEmpty) {
        filters['status'] = filterAttendanceStatus;
      }
      final dateFrom = dateFromController.text.trim();
      final dateTo = dateToController.text.trim();
      if (dateFrom.isNotEmpty) {
        filters['date_from'] = dateFrom;
      }
      if (dateTo.isNotEmpty) {
        filters['date_to'] = dateTo;
      }

      final response = await _service.attendance(filters: filters);
      companyBanner = info.banner;
      sessionCompanyId = cid;
      canViewAllHr = viewAll;
      employees = nextEmployees;
      rows = response.data ?? const <AttendanceRecordModel>[];
      loading = false;
      error = null;
      update();
    } catch (err) {
      error = err.toString();
      loading = false;
      update();
    }
  }

  List<AttendanceRecordModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows
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

  String selectedEmployeeLabel() {
    if (filterEmployeeId == null) {
      return '';
    }
    for (final EmployeeModel e in employees) {
      if (e.id == filterEmployeeId) {
        return e.toString();
      }
    }
    return 'Employee #$filterEmployeeId';
  }

  List<String> get appliedFilterChips {
    return <String>[
      if (companyBanner != null) 'Company: $companyBanner',
      if (searchController.text.trim().isNotEmpty)
        'Search: ${searchController.text.trim()}',
      if (canViewAllHr && filterEmployeeId != null)
        'Employee: ${selectedEmployeeLabel()}',
      if (canViewAllHr && (filterAttendanceStatus ?? '').isNotEmpty)
        'Status: ${hrDropdownLabel(_hrAttendanceStatusFilterItems, filterAttendanceStatus)}',
      if (dateFromController.text.trim().isNotEmpty)
        'From: ${dateFromController.text.trim()}',
      if (dateToController.text.trim().isNotEmpty)
        'To: ${dateToController.text.trim()}',
    ];
  }

  void clearFilters() {
    searchController.clear();
    filterEmployeeId = null;
    filterAttendanceStatus = null;
    dateFromController.clear();
    dateToController.clear();
    update();
  }

  void setEmployeeFilter(int? value) {
    filterEmployeeId = value;
    update();
  }

  void setAttendanceStatusFilter(String? value) {
    filterAttendanceStatus = value;
    update();
  }
}

class PayrollRunRegisterController extends GetxController {
  final HrService _service = HrService();
  final TextEditingController searchController = TextEditingController();

  bool loading = true;
  String? error;
  String? companyBanner;
  List<PayrollRunModel> rows = const <PayrollRunModel>[];

  @override
  void onInit() {
    super.onInit();
    WorkingContextService.version.addListener(_onWorkingContextChanged);
    searchController.addListener(update);
    unawaited(load());
  }

  @override
  void onClose() {
    WorkingContextService.version.removeListener(_onWorkingContextChanged);
    searchController
      ..removeListener(update)
      ..dispose();
    super.onClose();
  }

  void _onWorkingContextChanged() {
    unawaited(load());
  }

  Future<void> load() async {
    loading = true;
    error = null;
    update();
    try {
      final info = await hrSessionCompanyInfo();
      final filters = <String, dynamic>{'per_page': 200};
      if (info.companyId != null) {
        filters['company_id'] = info.companyId;
      }
      final response = await _service.payrollRuns(filters: filters);
      companyBanner = info.banner;
      rows = response.data ?? const <PayrollRunModel>[];
      loading = false;
      update();
    } catch (err) {
      error = err.toString();
      loading = false;
      update();
    }
  }

  List<PayrollRunModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows
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
}

class PayslipRegisterController extends GetxController {
  final HrService _service = HrService();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();

  bool loading = true;
  String? error;
  String? companyBanner;
  int? sessionCompanyId;
  bool canViewAllHr = false;
  int? filterEmployeeId;
  List<EmployeeModel> employees = const <EmployeeModel>[];
  List<PayslipModel> rows = const <PayslipModel>[];

  @override
  void onInit() {
    super.onInit();
    WorkingContextService.version.addListener(_onWorkingContextChanged);
    searchController.addListener(update);
    unawaited(load());
  }

  @override
  void onClose() {
    WorkingContextService.version.removeListener(_onWorkingContextChanged);
    searchController
      ..removeListener(update)
      ..dispose();
    dateFromController.dispose();
    dateToController.dispose();
    super.onClose();
  }

  void _onWorkingContextChanged() {
    unawaited(load());
  }

  Future<void> load() async {
    loading = true;
    error = null;
    update();
    try {
      final info = await hrSessionCompanyInfo();
      final cid = info.companyId;
      if (cid == null) {
        companyBanner = info.banner;
        sessionCompanyId = null;
        canViewAllHr = false;
        employees = const <EmployeeModel>[];
        rows = const <PayslipModel>[];
        loading = false;
        error = 'Select a session company to load payslips.';
        update();
        return;
      }

      final ctxRes = await _service.expenseClaimsLinkedEmployee(companyId: cid);
      final ctx = ctxRes.data ?? const <String, dynamic>{};
      final viewAll =
          ctx['can_view_all_hr_records'] == true ||
          ctx['can_view_all_hr_records'] == 1 ||
          ctx['can_view_all_claims'] == true ||
          ctx['can_view_all_claims'] == 1;
      final linked = intValue(ctx, 'employee_id');

      if (!viewAll && linked == null) {
        companyBanner = info.banner;
        sessionCompanyId = cid;
        canViewAllHr = false;
        employees = const <EmployeeModel>[];
        rows = const <PayslipModel>[];
        loading = false;
        error =
            'No employee record is linked to your user for this company. '
            'Your user employee code must match an employee in HR.';
        update();
        return;
      }

      var nextEmployees = const <EmployeeModel>[];
      if (viewAll) {
        final empResp = await _service.employees(
          filters: <String, dynamic>{
            'company_id': cid,
            'per_page': 500,
            'sort_by': 'employee_name',
          },
        );
        nextEmployees = empResp.data ?? const <EmployeeModel>[];
      }

      final filters = <String, dynamic>{'company_id': cid, 'per_page': 200};
      if (viewAll && filterEmployeeId != null) {
        filters['employee_id'] = filterEmployeeId;
      }
      final dateFrom = dateFromController.text.trim();
      final dateTo = dateToController.text.trim();
      if (dateFrom.isNotEmpty) {
        filters['date_from'] = dateFrom;
      }
      if (dateTo.isNotEmpty) {
        filters['date_to'] = dateTo;
      }

      final response = await _service.payslips(filters: filters);
      companyBanner = info.banner;
      sessionCompanyId = cid;
      canViewAllHr = viewAll;
      employees = nextEmployees;
      rows = response.data ?? const <PayslipModel>[];
      loading = false;
      error = null;
      update();
    } catch (err) {
      error = err.toString();
      loading = false;
      update();
    }
  }

  List<PayslipModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows
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

  String selectedEmployeeLabel() {
    if (filterEmployeeId == null) {
      return '';
    }
    for (final EmployeeModel e in employees) {
      if (e.id == filterEmployeeId) {
        return e.toString();
      }
    }
    return 'Employee #$filterEmployeeId';
  }

  List<String> get appliedFilterChips {
    return <String>[
      if (companyBanner != null) 'Company: $companyBanner',
      if (searchController.text.trim().isNotEmpty)
        'Search: ${searchController.text.trim()}',
      if (canViewAllHr && filterEmployeeId != null)
        'Employee: ${selectedEmployeeLabel()}',
      if (dateFromController.text.trim().isNotEmpty)
        'From: ${dateFromController.text.trim()}',
      if (dateToController.text.trim().isNotEmpty)
        'To: ${dateToController.text.trim()}',
    ];
  }

  void clearFilters() {
    searchController.clear();
    filterEmployeeId = null;
    dateFromController.clear();
    dateToController.clear();
    update();
  }

  void setEmployeeFilter(int? value) {
    filterEmployeeId = value;
    update();
  }
}

class AttendanceRegisterPage extends StatefulWidget {
  const AttendanceRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<AttendanceRegisterPage> createState() => _AttendanceRegisterPageState();
}

class _AttendanceRegisterPageState extends State<AttendanceRegisterPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('AttendanceRegisterController');
    if (!Get.isRegistered<AttendanceRegisterController>(tag: _controllerTag)) {
      Get.put(AttendanceRegisterController(), tag: _controllerTag);
    }
  }

  Future<void> _openAttendanceFilterPanel(
    BuildContext context,
    AttendanceRegisterController controller,
  ) async {
    final applied = await showHrListFilterDialog(
      context: context,
      title: 'Filter Attendance',
      header: controller.companyBanner == null
          ? null
          : Text(
              'Session company: ${controller.companyBanner}. Change via the '
              'header session button.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
      filterFields: [
        hrListFilterBox(
          child: AppFormTextField(
            controller: controller.searchController,
            labelText: 'Search',
            hintText: 'Employee, date, status…',
          ),
        ),
        if (controller.canViewAllHr) ...[
          hrListFilterBox(
            child: AppDropdownField<int?>.fromMapped(
              labelText: 'Employee filter',
              mappedItems: <AppDropdownItem<int?>>[
                const AppDropdownItem<int?>(
                  value: null,
                  label: 'All employees',
                ),
                ...controller.employees
                    .where(
                      (EmployeeModel e) =>
                          e.companyId == controller.sessionCompanyId &&
                          e.id != null,
                    )
                    .map(
                      (EmployeeModel e) => AppDropdownItem<int?>(
                        value: e.id,
                        label: e.toString(),
                      ),
                    ),
              ],
              initialValue: controller.filterEmployeeId,
              onChanged: controller.setEmployeeFilter,
            ),
          ),
          hrListFilterBox(
            child: AppDropdownField<String?>.fromMapped(
              labelText: 'Status',
              mappedItems: _hrAttendanceStatusFilterItems,
              initialValue: controller.filterAttendanceStatus,
              onChanged: controller.setAttendanceStatusFilter,
            ),
          ),
        ],
        hrListFilterBox(
          child: AppFormTextField(
            controller: controller.dateFromController,
            labelText: 'From date',
            keyboardType: TextInputType.datetime,
            inputFormatters: const [DateInputFormatter()],
          ),
        ),
        hrListFilterBox(
          child: AppFormTextField(
            controller: controller.dateToController,
            labelText: 'To date',
            keyboardType: TextInputType.datetime,
            inputFormatters: const [DateInputFormatter()],
          ),
        ),
      ],
      onClear: controller.clearFilters,
    );
    if (applied == true && context.mounted) {
      await controller.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AttendanceRegisterController>(
      tag: _controllerTag,
      builder: (controller) {
        return PurchaseRegisterPage<AttendanceRecordModel>(
          title: 'Attendance',
          embedded: widget.embedded,
          loading: controller.loading,
          errorMessage: controller.error,
          onRetry: controller.load,
          emptyMessage: 'No attendance records found.',
          actions: [
            AdaptiveShellActionButton(
              icon: Icons.filter_alt_outlined,
              label: 'Filter',
              filled: false,
              onPressed: () => _openAttendanceFilterPanel(context, controller),
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
                  hr: controller._service,
                  companyId: companyId,
                  onSaved: controller.load,
                );
              },
            ),
          ],
          filters: hrListAppliedFiltersCard(
            context,
            controller.appliedFilterChips,
          ),
          rows: controller.filteredRows,
          columns: [
            PurchaseRegisterColumn<AttendanceRecordModel>(
              label: 'Employee',
              valueBuilder: (row) => _nestedEmployeeName(row.toJson()),
            ),
            PurchaseRegisterColumn<AttendanceRecordModel>(
              label: 'Date',
              valueBuilder: (row) => displayDate(
                nullableStringValue(row.toJson(), 'attendance_date'),
              ),
            ),
            PurchaseRegisterColumn<AttendanceRecordModel>(
              label: 'Status',
              valueBuilder: (row) => stringValue(row.toJson(), 'status'),
            ),
            PurchaseRegisterColumn<AttendanceRecordModel>(
              label: 'Check in',
              valueBuilder: (row) => displayDateTime(
                nullableStringValue(row.toJson(), 'check_in'),
              ),
            ),
          ],
          onRowTap: (row) async {
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
              hr: controller._service,
              id: id,
              companyId: companyId,
              onChanged: controller.load,
            );
          },
        );
      },
    );
  }
}

class PayrollRunRegisterPage extends StatefulWidget {
  const PayrollRunRegisterPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<PayrollRunRegisterPage> createState() => _PayrollRunRegisterPageState();
}

class _PayrollRunRegisterPageState extends State<PayrollRunRegisterPage> {
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('PayrollRunRegisterController');
    if (!Get.isRegistered<PayrollRunRegisterController>(tag: _controllerTag)) {
      Get.put(PayrollRunRegisterController(), tag: _controllerTag);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PayrollRunRegisterController>(
      tag: _controllerTag,
      builder: (controller) {
        return PurchaseRegisterPage<PayrollRunModel>(
          title: 'Payroll runs',
          embedded: widget.embedded,
          loading: controller.loading,
          errorMessage: controller.error,
          onRetry: controller.load,
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
                  hr: controller._service,
                  companyId: companyId,
                  onSaved: controller.load,
                );
              },
            ),
          ],
          filters: _HrCompanyContextFilters(
            companyBanner: controller.companyBanner,
            searchController: controller.searchController,
            searchHint: 'Period, status, run date…',
          ),
          rows: controller.filteredRows,
          columns: [
            PurchaseRegisterColumn<PayrollRunModel>(
              label: 'Period',
              valueBuilder: (row) => _payrollPeriodLabel(row.toJson()),
            ),
            PurchaseRegisterColumn<PayrollRunModel>(
              label: 'Run date',
              valueBuilder: (row) =>
                  displayDate(nullableStringValue(row.toJson(), 'run_date')),
            ),
            PurchaseRegisterColumn<PayrollRunModel>(
              label: 'Status',
              valueBuilder: (row) => stringValue(row.toJson(), 'status'),
            ),
            PurchaseRegisterColumn<PayrollRunModel>(
              label: 'Lines',
              valueBuilder: (row) => stringValue(row.toJson(), 'lines_count'),
            ),
          ],
          onRowTap: (row) async {
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
              hr: controller._service,
              id: id,
              companyId: companyId,
              onChanged: controller.load,
            );
          },
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
  late final String _controllerTag;

  @override
  void initState() {
    super.initState();
    _controllerTag = persistentControllerTag('PayslipRegisterController');
    if (!Get.isRegistered<PayslipRegisterController>(tag: _controllerTag)) {
      Get.put(PayslipRegisterController(), tag: _controllerTag);
    }
  }

  Future<void> _openPayslipFilterPanel(
    BuildContext context,
    PayslipRegisterController controller,
  ) async {
    final applied = await showHrListFilterDialog(
      context: context,
      title: 'Filter Payslips',
      header: controller.companyBanner == null
          ? null
          : Text(
              'Session company: ${controller.companyBanner}. Change via the '
              'header session button.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
      filterFields: [
        hrListFilterBox(
          child: AppFormTextField(
            controller: controller.searchController,
            labelText: 'Search',
            hintText: 'Employee, period, date…',
          ),
        ),
        if (controller.canViewAllHr)
          hrListFilterBox(
            child: AppDropdownField<int?>.fromMapped(
              labelText: 'Employee filter',
              mappedItems: <AppDropdownItem<int?>>[
                const AppDropdownItem<int?>(
                  value: null,
                  label: 'All employees',
                ),
                ...controller.employees
                    .where(
                      (EmployeeModel e) =>
                          e.companyId == controller.sessionCompanyId &&
                          e.id != null,
                    )
                    .map(
                      (EmployeeModel e) => AppDropdownItem<int?>(
                        value: e.id,
                        label: e.toString(),
                      ),
                    ),
              ],
              initialValue: controller.filterEmployeeId,
              onChanged: controller.setEmployeeFilter,
            ),
          ),
        hrListFilterBox(
          child: AppFormTextField(
            controller: controller.dateFromController,
            labelText: 'Payslip from date',
            keyboardType: TextInputType.datetime,
            inputFormatters: const [DateInputFormatter()],
          ),
        ),
        hrListFilterBox(
          child: AppFormTextField(
            controller: controller.dateToController,
            labelText: 'Payslip to date',
            keyboardType: TextInputType.datetime,
            inputFormatters: const [DateInputFormatter()],
          ),
        ),
      ],
      onClear: controller.clearFilters,
    );
    if (applied == true && context.mounted) {
      await controller.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PayslipRegisterController>(
      tag: _controllerTag,
      builder: (controller) {
        return PurchaseRegisterPage<PayslipModel>(
          title: 'Payslips',
          embedded: widget.embedded,
          loading: controller.loading,
          errorMessage: controller.error,
          onRetry: controller.load,
          emptyMessage: 'No payslips found.',
          actions: [
            AdaptiveShellActionButton(
              icon: Icons.filter_alt_outlined,
              label: 'Filter',
              filled: false,
              onPressed: () => _openPayslipFilterPanel(context, controller),
            ),
            AdaptiveShellActionButton(
              icon: Icons.refresh,
              label: 'Refresh',
              onPressed: controller.load,
            ),
          ],
          filters: hrListAppliedFiltersCard(
            context,
            controller.appliedFilterChips,
          ),
          rows: controller.filteredRows,
          columns: [
            PurchaseRegisterColumn<PayslipModel>(
              label: 'Date',
              valueBuilder: (row) => displayDate(
                nullableStringValue(row.toJson(), 'payslip_date'),
              ),
            ),
            PurchaseRegisterColumn<PayslipModel>(
              label: 'Employee',
              valueBuilder: (row) => _payslipLineEmployeeName(row.toJson()),
            ),
            PurchaseRegisterColumn<PayslipModel>(
              label: 'Period',
              valueBuilder: (row) => _payslipPayrollPeriod(row.toJson()),
            ),
            PurchaseRegisterColumn<PayslipModel>(
              label: 'Net',
              valueBuilder: (row) => _payslipNetSalary(row.toJson()),
            ),
          ],
          onRowTap: (row) {
            final id = intValue(row.toJson(), 'id');
            if (id == null) {
              return;
            }
            showPayslipDetailDialog(context, hr: controller._service, id: id);
          },
        );
      },
    );
  }
}
