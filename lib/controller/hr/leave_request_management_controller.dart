import '../../screen.dart';
import '../../helper/hr_register_reload_helper.dart';

class LeaveRequestManagementController extends GetxController {
  LeaveRequestManagementController();

  static const List<AppDropdownItem<String>> statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'pending', label: 'Pending'),
        AppDropdownItem(value: 'approved', label: 'Approved'),
        AppDropdownItem(value: 'rejected', label: 'Rejected'),
      ];

  static const List<AppDropdownItem<String?>> listStatusFilterItems =
      <AppDropdownItem<String?>>[
        AppDropdownItem<String?>(value: null, label: 'All statuses'),
        AppDropdownItem<String?>(value: 'pending', label: 'Pending'),
        AppDropdownItem<String?>(value: 'approved', label: 'Approved'),
        AppDropdownItem<String?>(value: 'rejected', label: 'Rejected'),
      ];

  final HrService _hrService = HrService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController listDateFromController = TextEditingController();
  final TextEditingController listDateToController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  String? companyBanner;
  int? sessionCompanyId;
  bool canViewAllHr = false;
  int? linkedEmployeeId;
  int? listFilterEmployeeId;
  String? listFilterStatus;
  List<LeaveRequestModel> leaveRequests = const <LeaveRequestModel>[];
  List<LeaveRequestModel> filteredLeaveRequests = const <LeaveRequestModel>[];
  List<EmployeeModel> employees = const <EmployeeModel>[];
  List<LeaveTypeModel> leaveTypes = const <LeaveTypeModel>[];
  LeaveRequestModel? selectedLeaveRequest;
  int? employeeId;
  int? leaveTypeId;
  String status = 'pending';

  @override
  void onInit() {
    super.onInit();
    WorkingContextService.version.addListener(_onWorkingContextChanged);
    searchController.addListener(_applySearch);
    loadData();
  }

  @override
  void onClose() {
    WorkingContextService.version.removeListener(_onWorkingContextChanged);
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    fromDateController.dispose();
    toDateController.dispose();
    reasonController.dispose();
    listDateFromController.dispose();
    listDateToController.dispose();
    super.onClose();
  }

  void _onWorkingContextChanged() {
    unawaited(loadData());
  }

  Future<void> loadData({int? selectId}) async {
    initialLoading = leaveRequests.isEmpty;
    pageError = null;
    update();

    try {
      final info = await hrSessionCompanyInfo();
      final cid = info.companyId;
      if (cid == null) {
        companyBanner = info.banner;
        sessionCompanyId = null;
        canViewAllHr = false;
        linkedEmployeeId = null;
        leaveRequests = const <LeaveRequestModel>[];
        filteredLeaveRequests = const <LeaveRequestModel>[];
        initialLoading = false;
        pageError = 'Select a session company to load leave requests.';
        resetForm(notify: false);
        update();
        return;
      }

      final ctxRes = await _hrService.expenseClaimsLinkedEmployee(
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
        companyBanner = info.banner;
        sessionCompanyId = cid;
        canViewAllHr = false;
        linkedEmployeeId = null;
        leaveRequests = const <LeaveRequestModel>[];
        filteredLeaveRequests = const <LeaveRequestModel>[];
        initialLoading = false;
        pageError =
            'No employee record is linked to your user for this company. '
            'Your user employee code must match an employee in HR.';
        resetForm(notify: false);
        update();
        return;
      }

      final filters = <String, dynamic>{'company_id': cid, 'per_page': 200};
      if (viewAll && listFilterEmployeeId != null) {
        filters['employee_id'] = listFilterEmployeeId;
      }
      if (viewAll && (listFilterStatus ?? '').isNotEmpty) {
        filters['status'] = listFilterStatus;
      }
      final dateFrom = listDateFromController.text.trim();
      final dateTo = listDateToController.text.trim();
      if (dateFrom.isNotEmpty) {
        filters['date_from'] = dateFrom;
      }
      if (dateTo.isNotEmpty) {
        filters['date_to'] = dateTo;
      }

      final responses = await Future.wait<dynamic>([
        _hrService.leaveRequests(filters: filters),
        _hrService.leaveTypes(
          filters: const {'per_page': 200, 'sort_by': 'leave_name'},
        ),
        _hrService.employees(
          filters: <String, dynamic>{
            'per_page': 500,
            'sort_by': 'employee_name',
            'company_id': cid,
          },
        ),
      ]);

      final nextLeaveRequests =
          (responses[0] as PaginatedResponse<LeaveRequestModel>).data ??
          const <LeaveRequestModel>[];
      final nextLeaveTypes =
          (responses[1] as PaginatedResponse<LeaveTypeModel>).data ??
          const <LeaveTypeModel>[];
      final nextEmployees =
          (responses[2] as PaginatedResponse<EmployeeModel>).data ??
          const <EmployeeModel>[];

      companyBanner = info.banner;
      sessionCompanyId = cid;
      canViewAllHr = viewAll;
      linkedEmployeeId = linked;
      leaveRequests = nextLeaveRequests;
      leaveTypes = nextLeaveTypes;
      employees = nextEmployees;
      filteredLeaveRequests = filterLeaveRequests(
        nextLeaveRequests,
        searchController.text,
      );
      initialLoading = false;
      pageError = null;

      final selected = selectId != null
          ? nextLeaveRequests.cast<LeaveRequestModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedLeaveRequest == null
                ? (filteredLeaveRequests.isNotEmpty
                      ? filteredLeaveRequests.first
                      : null)
                : nextLeaveRequests.cast<LeaveRequestModel?>().firstWhere(
                    (item) => item?.id == selectedLeaveRequest?.id,
                    orElse: () => filteredLeaveRequests.isNotEmpty
                        ? filteredLeaveRequests.first
                        : null,
                  ));

      if (selected != null) {
        selectLeaveRequest(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (errorValue) {
      pageError = errorValue.toString();
      initialLoading = false;
    }

    update();
  }

  List<EmployeeModel> get formEmployees {
    if (sessionCompanyId == null) {
      return const <EmployeeModel>[];
    }
    final base = employees
        .where((item) => item.companyId == sessionCompanyId && item.id != null)
        .toList(growable: false);
    if (canViewAllHr) {
      return base;
    }
    if (linkedEmployeeId == null) {
      return base;
    }
    return base
        .where((item) => item.id == linkedEmployeeId)
        .toList(growable: false);
  }

  LeaveTypeModel? get activeLeaveType {
    for (final t in leaveTypes) {
      if (t.id == leaveTypeId) {
        return t;
      }
    }
    return null;
  }

  bool isCasualLeaveType(LeaveTypeModel? type) {
    if (type == null) {
      return false;
    }
    final code = (type.leaveCode ?? '').toUpperCase().trim();
    if (code == 'CL') {
      return true;
    }
    final name = (type.leaveName ?? '').toLowerCase();
    return name == 'casual leave' || name.contains('casual');
  }

  List<LeaveRequestModel> filterLeaveRequests(
    List<LeaveRequestModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (LeaveRequestModel item) {
      return [
        item.employeeCode ?? '',
        item.employeeName ?? '',
        item.leaveTypeName ?? '',
        item.status ?? '',
        item.reason ?? '',
      ];
    });
  }

  void _applySearch() {
    filteredLeaveRequests = filterLeaveRequests(
      leaveRequests,
      searchController.text,
    );
    update();
  }

  void selectLeaveRequest(LeaveRequestModel item, {bool notify = true}) {
    selectedLeaveRequest = item;
    employeeId = item.employeeId;
    leaveTypeId = item.leaveTypeId;
    fromDateController.text = normalizeDateValue(item.fromDate);
    toDateController.text = normalizeDateValue(item.toDate);
    reasonController.text = item.reason ?? '';
    status = item.status ?? 'pending';
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedLeaveRequest = null;
    employeeId = (!canViewAllHr && linkedEmployeeId != null)
        ? linkedEmployeeId
        : null;
    leaveTypeId = null;
    fromDateController.clear();
    toDateController.clear();
    reasonController.clear();
    status = 'pending';
    formError = null;
    if (notify) {
      update();
    }
  }

  void startNew({required bool isDesktop}) {
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }

  Future<LeaveTypeModel?> createLeaveType({
    required String leaveName,
    required String maxDays,
    required bool isPaidValue,
  }) async {
    final response = await _hrService.createLeaveType(
      LeaveTypeModel(
        leaveName: leaveName,
        maxDaysPerYear: double.tryParse(maxDays.trim()),
        isPaid: isPaidValue,
      ),
    );
    final created = response.data;
    if (created?.id == null) {
      return null;
    }
    final refreshed = await _hrService.leaveTypes(
      filters: const {'per_page': 200, 'sort_by': 'leave_name'},
    );
    final createdLeaveType = created!;
    leaveTypes = refreshed.data ?? <LeaveTypeModel>[createdLeaveType];
    leaveTypeId = createdLeaveType.id;
    update();
    return createdLeaveType;
  }

  Future<void> save({FormState? formState}) async {
    final FormState? form = formState;
    if (form == null || !form.validate()) {
      return;
    }

    saving = true;
    formError = null;
    update();

    final model = LeaveRequestModel(
      id: selectedLeaveRequest?.id,
      employeeId: employeeId,
      leaveTypeId: leaveTypeId,
      fromDate: nullIfEmpty(fromDateController.text.trim()),
      toDate: nullIfEmpty(toDateController.text.trim()),
      reason: nullIfEmpty(reasonController.text.trim()),
      status: status,
    );

    try {
      final response = selectedLeaveRequest == null
          ? await _hrService.createLeaveRequest(model)
          : await _hrService.updateLeaveRequest(
              selectedLeaveRequest!.id!,
              model,
            );
      final saved = response.data;
      if (saved == null) {
        formError = response.message;
        update();
        return;
      }

      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadData(selectId: saved.id);
      reloadAttendanceRegister();
      reloadPayrollRunRegister();
      reloadPayslipRegister();
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> delete() async {
    final id = selectedLeaveRequest?.id;
    if (id == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _hrService.deleteLeaveRequest(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadData();
      reloadAttendanceRegister();
      reloadPayrollRunRegister();
      reloadPayslipRegister();
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  String leaveListSelectedEmployeeLabel() {
    if (listFilterEmployeeId == null) {
      return '';
    }
    for (final EmployeeModel e in employees) {
      if (e.id == listFilterEmployeeId) {
        return e.toString();
      }
    }
    return 'Employee #$listFilterEmployeeId';
  }

  List<String> leaveListAppliedFilterChips() {
    return <String>[
      if (companyBanner != null) 'Company: $companyBanner',
      if (searchController.text.trim().isNotEmpty)
        'Search: ${searchController.text.trim()}',
      if (canViewAllHr && listFilterEmployeeId != null)
        'Employee: ${leaveListSelectedEmployeeLabel()}',
      if (canViewAllHr && (listFilterStatus ?? '').isNotEmpty)
        'Status: ${hrDropdownLabel(listStatusFilterItems, listFilterStatus)}',
      if (listDateFromController.text.trim().isNotEmpty)
        'From: ${listDateFromController.text.trim()}',
      if (listDateToController.text.trim().isNotEmpty)
        'To: ${listDateToController.text.trim()}',
    ];
  }

  void clearLeaveListFilters() {
    searchController.clear();
    listFilterEmployeeId = null;
    listFilterStatus = null;
    listDateFromController.clear();
    listDateToController.clear();
    filteredLeaveRequests = filterLeaveRequests(
      leaveRequests,
      searchController.text,
    );
    update();
  }

  void setListFilterEmployeeId(int? value) {
    listFilterEmployeeId = value;
    update();
  }

  void setListFilterStatus(String? value) {
    listFilterStatus = value;
    update();
  }

  void setEmployeeId(int? value) {
    employeeId = value;
    update();
  }

  void setLeaveTypeId(int? value) {
    leaveTypeId = value;
    update();
  }

  void setStatus(String? value) {
    status = value ?? 'pending';
    update();
  }
}
