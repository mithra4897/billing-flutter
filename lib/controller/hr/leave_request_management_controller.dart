import '../../screen.dart';
import 'hr_module_refresh_controller.dart';

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
  final HrModuleRefreshController _refreshController =
      HrModuleRefreshController.ensureRegistered();
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
  bool canApproveLeaveRequests = false;
  int? linkedEmployeeId;
  Set<int> listFilterEmployeeIds = <int>{};
  Set<String> listFilterStatuses = <String>{};
  List<LeaveRequestModel> leaveRequests = const <LeaveRequestModel>[];
  List<LeaveRequestModel> filteredLeaveRequests = const <LeaveRequestModel>[];
  List<EmployeeModel> employees = const <EmployeeModel>[];
  List<LeaveTypeModel> leaveTypes = const <LeaveTypeModel>[];
  LeaveRequestModel? selectedLeaveRequest;
  int? employeeId;
  int? leaveTypeId;
  String status = 'pending';
  PaginationMeta? paginationMeta;
  Timer? _filterDebounce;

  @override
  void onInit() {
    super.onInit();
    WorkingContextService.version.addListener(_onWorkingContextChanged);
    searchController.addListener(_scheduleReload);
    listDateFromController.addListener(_scheduleReload);
    listDateToController.addListener(_scheduleReload);
    loadData();
  }

  @override
  void onClose() {
    WorkingContextService.version.removeListener(_onWorkingContextChanged);
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_scheduleReload)
      ..dispose();
    fromDateController.dispose();
    toDateController.dispose();
    reasonController.dispose();
    listDateFromController
      ..removeListener(_scheduleReload)
      ..dispose();
    listDateToController
      ..removeListener(_scheduleReload)
      ..dispose();
    _filterDebounce?.cancel();
    super.onClose();
  }

  void _onWorkingContextChanged() {
    unawaited(loadData());
  }

  Future<void> loadData({int? selectId, int page = 1}) async {
    _filterDebounce?.cancel();
    initialLoading = leaveRequests.isEmpty;
    pageError = null;
    update();

    try {
      final currentUser = await SessionStorage.getCurrentUser();
      final permissionCodes = await SessionStorage.getPermissionCodes();
      final isSuperAdmin =
          currentUser?['is_super_admin'] == true ||
          currentUser?['is_super_admin'] == 1 ||
          currentUser?['is_super_admin'] == '1';
      canApproveLeaveRequests =
          isSuperAdmin || permissionCodes.contains('hr.approve');

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

      final filters = <String, dynamic>{
        'company_id': cid,
        'page': page,
        'per_page': 50,
        'sort_by': 'from_date',
        'sort_order': 'desc',
        if (searchController.text.trim().isNotEmpty)
          'search': searchController.text.trim(),
        if (listFilterEmployeeIds.length == 1)
          'employee_id': listFilterEmployeeIds.single,
        if (listFilterEmployeeIds.length > 1)
          'employee_ids': listFilterEmployeeIds.join(','),
        if (listFilterStatuses.length == 1) 'status': listFilterStatuses.single,
        if (listFilterStatuses.length > 1)
          'statuses': listFilterStatuses.join(','),
      };
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

      final requestResponse =
          responses[0] as PaginatedResponse<LeaveRequestModel>;
      final nextLeaveRequests =
          requestResponse.data ?? const <LeaveRequestModel>[];
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
      paginationMeta = requestResponse.meta;
      leaveTypes = nextLeaveTypes;
      employees = nextEmployees;
      filteredLeaveRequests = nextLeaveRequests;
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

  EmployeeModel? get formEmployee {
    final id = employeeId;
    if (id == null) {
      return null;
    }
    for (final employee in employees) {
      if (employee.id == id) {
        return employee;
      }
    }
    return null;
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

  void _scheduleReload() {
    _filterDebounce?.cancel();
    _filterDebounce = Timer(
      const Duration(milliseconds: 450),
      () => unawaited(loadData(page: 1)),
    );
  }

  void goToPage(int page) {
    if (page >= 1 && page != paginationMeta?.currentPage) {
      unawaited(loadData(page: page));
    }
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
    employeeId = linkedEmployeeId;
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
      _refreshController.notifyChanged(source: 'leave_request_management');
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
      _refreshController.notifyChanged(source: 'leave_request_management');
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  bool get canApproveSelectedLeaveRequest =>
      canApproveLeaveRequests &&
      selectedLeaveRequest?.id != null &&
      (selectedLeaveRequest?.status ?? '').trim().toLowerCase() == 'pending';

  Future<void> approveSelectedLeaveRequest() async {
    final id = selectedLeaveRequest?.id;
    if (id == null || !canApproveSelectedLeaveRequest) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _hrService.approveLeaveRequest(
        id,
        const LeaveRequestModel(),
      );
      if (response.success != true) {
        formError = response.message;
        return;
      }
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadData(selectId: id);
      _refreshController.notifyChanged(source: 'leave_request_management');
    } catch (errorValue) {
      formError = errorValue.toString();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> rejectSelectedLeaveRequest() async {
    final id = selectedLeaveRequest?.id;
    if (id == null || !canApproveSelectedLeaveRequest) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _hrService.rejectLeaveRequest(
        id,
        const LeaveRequestModel(),
      );
      if (response.success != true) {
        formError = response.message;
        return;
      }
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadData(selectId: id);
      _refreshController.notifyChanged(source: 'leave_request_management');
    } catch (errorValue) {
      formError = errorValue.toString();
    } finally {
      saving = false;
      update();
    }
  }

  String leaveListSelectedEmployeeLabel() {
    if (listFilterEmployeeIds.isEmpty) {
      return '';
    }
    for (final EmployeeModel e in employees) {
      if (e.id != null && listFilterEmployeeIds.contains(e.id)) {
        return e.toString();
      }
    }
    return listFilterEmployeeIds.join(', ');
  }

  List<String> leaveListAppliedFilterChips() {
    return <String>[
      if (companyBanner != null) 'Company: $companyBanner',
      if (searchController.text.trim().isNotEmpty)
        'Search: ${searchController.text.trim()}',
      if (canViewAllHr && listFilterEmployeeIds.isNotEmpty)
        'Employee: ${listFilterEmployeeIds.map((id) => employees.cast<EmployeeModel?>().firstWhere((e) => e?.id == id, orElse: () => null)?.toString() ?? id.toString()).join(', ')}',
      if (canViewAllHr && listFilterStatuses.isNotEmpty)
        'Status: ${listFilterStatuses.join(', ')}',
      if (listDateFromController.text.trim().isNotEmpty)
        'From: ${listDateFromController.text.trim()}',
      if (listDateToController.text.trim().isNotEmpty)
        'To: ${listDateToController.text.trim()}',
    ];
  }

  void clearLeaveListFilters() {
    searchController.clear();
    listFilterEmployeeIds = <int>{};
    listFilterStatuses = <String>{};
    listDateFromController.clear();
    listDateToController.clear();
    update();
    unawaited(loadData(page: 1));
  }

  void setListFilterEmployeeIds(Set<int> values) {
    listFilterEmployeeIds = Set<int>.from(values);
    update();
    _scheduleReload();
  }

  void setListFilterStatuses(Set<String> values) {
    listFilterStatuses = values
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();
    update();
    _scheduleReload();
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
