import '../../screen.dart';
import '../../controller/hr/hr_module_refresh_controller.dart';

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
  final employee = _asJsonMap(data['employee']);
  if (employee == null) {
    return '';
  }
  return stringValue(employee, 'employee_name');
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

class AttendanceRegisterController extends GetxController {
  final HrService _service = HrService();
  final HrModuleRefreshController _refreshController =
      HrModuleRefreshController.ensureRegistered();
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
  Worker? _refreshWorker;

  @override
  void onInit() {
    super.onInit();
    WorkingContextService.version.addListener(_onWorkingContextChanged);
    searchController.addListener(update);
    _refreshWorker = ever<HrModuleRefreshEvent?>(_refreshController.lastEvent, (
      event,
    ) {
      if (event == null) {
        return;
      }
      unawaited(load());
    });
    unawaited(load());
  }

  @override
  void onClose() {
    _refreshWorker?.dispose();
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
  final HrModuleRefreshController _refreshController =
      HrModuleRefreshController.ensureRegistered();
  final TextEditingController searchController = TextEditingController();
  String statusFilter = '';

  static const List<AppDropdownItem<String>> statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: '', label: 'All statuses'),
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'processed', label: 'Processed'),
        AppDropdownItem(value: 'posted', label: 'Posted'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  bool loading = true;
  String? error;
  String? companyBanner;
  List<PayrollRunModel> rows = const <PayrollRunModel>[];
  Worker? _refreshWorker;

  @override
  void onInit() {
    super.onInit();
    WorkingContextService.version.addListener(_onWorkingContextChanged);
    searchController.addListener(update);
    _refreshWorker = ever<HrModuleRefreshEvent?>(_refreshController.lastEvent, (
      event,
    ) {
      if (event == null) {
        return;
      }
      unawaited(load());
    });
    unawaited(load());
  }

  @override
  void onClose() {
    _refreshWorker?.dispose();
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
          final status = row.status?.trim().toLowerCase() ?? '';
          final statusMatches = statusFilter.isEmpty || status == statusFilter;
          if (!statusMatches) {
            return false;
          }
          if (q.isEmpty) {
            return true;
          }
          return [
            row.periodLabel,
            row.runDate ?? '',
            row.status ?? '',
            row.linesCount?.toString() ?? '',
            row.companyId?.toString() ?? '',
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  void setStatusFilter(String value) {
    statusFilter = value;
    update();
  }
}

class PayslipRegisterController extends GetxController {
  final HrService _service = HrService();
  final HrModuleRefreshController _refreshController =
      HrModuleRefreshController.ensureRegistered();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();

  bool loading = true;
  String? error;
  String? companyBanner;
  int? sessionCompanyId;
  bool canViewAllHr = false;
  int? filterEmployeeId;
  int? filterPayrollRunId;
  List<EmployeeModel> employees = const <EmployeeModel>[];
  List<PayslipModel> rows = const <PayslipModel>[];
  Worker? _refreshWorker;

  @override
  void onInit() {
    super.onInit();
    WorkingContextService.version.addListener(_onWorkingContextChanged);
    searchController.addListener(update);
    _refreshWorker = ever<HrModuleRefreshEvent?>(_refreshController.lastEvent, (
      event,
    ) {
      if (event == null) {
        return;
      }
      unawaited(load());
    });
    unawaited(load());
  }

  @override
  void onClose() {
    _refreshWorker?.dispose();
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
      if (filterPayrollRunId != null) {
        filters['payroll_run_id'] = filterPayrollRunId;
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
          if (q.isEmpty) {
            return true;
          }
          return [
            row.id?.toString() ?? '',
            displayDate(row.payslipDate),
            row.employeeDisplayLabel,
            row.payrollPeriodLabel,
            row.netSalary?.toStringAsFixed(2) ?? '',
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
      if (filterPayrollRunId != null) 'Payroll run: #$filterPayrollRunId',
    ];
  }

  void clearFilters() {
    searchController.clear();
    filterEmployeeId = null;
    filterPayrollRunId = null;
    dateFromController.clear();
    dateToController.clear();
    update();
  }

  void setEmployeeFilter(int? value) {
    filterEmployeeId = value;
    update();
  }

  void applyRouteFilters({int? payrollRunId}) {
    filterPayrollRunId = payrollRunId;
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
          filters: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HrCompanyContextFilters(
                companyBanner: controller.companyBanner,
                searchController: controller.searchController,
                searchHint: 'Period, status, run date…',
              ),
              const SizedBox(height: AppUiConstants.spacingSm),
              AppDropdownField<String>.fromMapped(
                labelText: 'Status',
                mappedItems: PayrollRunRegisterController.statusItems,
                initialValue: controller.statusFilter,
                onChanged: (value) => controller.setStatusFilter(value ?? ''),
              ),
            ],
          ),
          rows: controller.filteredRows,
          columns: [
            PurchaseRegisterColumn<PayrollRunModel>(
              label: 'Period',
              valueBuilder: (row) => row.periodLabel,
            ),
            PurchaseRegisterColumn<PayrollRunModel>(
              label: 'Run date',
              valueBuilder: (row) => displayDate(row.runDate),
            ),
            PurchaseRegisterColumn<PayrollRunModel>(
              label: 'Status',
              valueBuilder: (row) => row.status ?? '',
            ),
            PurchaseRegisterColumn<PayrollRunModel>(
              label: 'Lines',
              valueBuilder: (row) => row.linesCount?.toString() ?? '',
            ),
          ],
          onRowTap: (row) async {
            final id = row.id;
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
  const PayslipRegisterPage({
    super.key,
    this.embedded = false,
    this.queryParameters = const <String, String>{},
  });

  final bool embedded;
  final Map<String, String> queryParameters;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !Get.isRegistered<PayslipRegisterController>(tag: _controllerTag)) {
        return;
      }
      final controller = Get.find<PayslipRegisterController>(
        tag: _controllerTag,
      );
      controller.applyRouteFilters(
        payrollRunId: int.tryParse(
          widget.queryParameters['payroll_run_id'] ?? '',
        ),
      );
      unawaited(controller.load());
    });
  }

  @override
  void didUpdateWidget(covariant PayslipRegisterPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.queryParameters, widget.queryParameters)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            !Get.isRegistered<PayslipRegisterController>(tag: _controllerTag)) {
          return;
        }
        final controller = Get.find<PayslipRegisterController>(
          tag: _controllerTag,
        );
        controller.applyRouteFilters(
          payrollRunId: int.tryParse(
            widget.queryParameters['payroll_run_id'] ?? '',
          ),
        );
        unawaited(controller.load());
      });
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
              valueBuilder: (row) => displayDate(row.payslipDate),
            ),
            PurchaseRegisterColumn<PayslipModel>(
              label: 'Employee',
              valueBuilder: (row) => row.employeeDisplayLabel,
            ),
            PurchaseRegisterColumn<PayslipModel>(
              label: 'Period',
              valueBuilder: (row) => row.payrollPeriodLabel,
            ),
            PurchaseRegisterColumn<PayslipModel>(
              label: 'Net',
              valueBuilder: (row) => row.netSalary?.toStringAsFixed(2) ?? '',
            ),
          ],
          onRowTap: (row) {
            final id = row.id;
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
