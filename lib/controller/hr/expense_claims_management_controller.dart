import '../../screen.dart';
import 'hr_module_refresh_controller.dart';

Map<String, dynamic>? expenseClaimAsJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return null;
}

String nestedExpenseEmployeeName(Map<String, dynamic> data) {
  final employee = expenseClaimAsJsonMap(data['employee']);
  if (employee == null) {
    return '';
  }
  return stringValue(employee, 'employee_name');
}

String expenseClaimStatusCode(dynamic status) {
  final value = status?.toString().trim().toLowerCase() ?? '';
  if (value == '0' || value == 'draft') {
    return 'draft';
  }
  if (value == '1' || value == 'applied' || value == 'submitted') {
    return 'applied';
  }
  if (value == 'approved') {
    return 'approved';
  }
  if (value == 'reimbursed') {
    return 'reimbursed';
  }
  if (value == 'rejected') {
    return 'rejected';
  }
  if (value == 'cancelled') {
    return 'cancelled';
  }
  return value;
}

String expenseClaimStatusLabel(dynamic status) {
  switch (expenseClaimStatusCode(status)) {
    case 'draft':
      return 'Draft';
    case 'applied':
      return 'Applied';
    case 'approved':
      return 'Approved';
    case 'reimbursed':
      return 'Reimbursed';
    case 'rejected':
      return 'Rejected';
    case 'cancelled':
      return 'Cancelled';
    default:
      return (status?.toString().trim().isNotEmpty ?? false)
          ? status.toString()
          : '-';
  }
}

String expensePaymentSubtitle(Map<String, dynamic> data) {
  final status = expenseClaimStatusCode(data['claim_status']);
  final reimbursementVoucherId = intValue(data, 'reimbursement_voucher_id');
  if (status == 'approved' && reimbursementVoucherId == null) {
    return 'Unpaid · ${stringValue(data, 'total_amount')}';
  }
  if (status == 'reimbursed') {
    return 'Paid · ${stringValue(data, 'total_amount')}';
  }
  return '${expenseClaimStatusLabel(data['claim_status'])} · ${stringValue(data, 'total_amount')}';
}

bool isHrApprovalQueueRow(Map<String, dynamic> data) {
  final status = expenseClaimStatusCode(data['claim_status']);
  final reimbursementVoucherId = intValue(data, 'reimbursement_voucher_id');
  if (status == 'applied') {
    return true;
  }
  if (status == 'rejected') {
    return true;
  }
  if (status == 'approved' && reimbursementVoucherId == null) {
    return true;
  }
  if (status == 'reimbursed') {
    return true;
  }
  return false;
}

class ExpenseLineEditors {
  ExpenseLineEditors({
    required this.expenseDate,
    required this.category,
    required this.description,
    required this.amount,
    required this.remarks,
    this.projectId,
    this.projectTaskId,
  });

  final TextEditingController expenseDate;
  final TextEditingController category;
  final TextEditingController description;
  final TextEditingController amount;
  final TextEditingController remarks;
  final int? projectId;
  final int? projectTaskId;

  void dispose() {
    expenseDate.dispose();
    category.dispose();
    description.dispose();
    amount.dispose();
    remarks.dispose();
  }
}

Map<String, dynamic>? expenseClaimLineMap(dynamic item) {
  if (item is Map<String, dynamic>) {
    return item;
  }
  if (item is Map) {
    return Map<String, dynamic>.from(item);
  }
  return null;
}

List<ExpenseLineEditors> expenseClaimEditorsFromJson(
  Map<String, dynamic> data,
) {
  final linesRaw = data['lines'];
  final editors = <ExpenseLineEditors>[];
  if (linesRaw is List) {
    for (final item in linesRaw) {
      final mapped = expenseClaimLineMap(item);
      if (mapped == null) {
        continue;
      }
      editors.add(
        ExpenseLineEditors(
          expenseDate: TextEditingController(
            text: displayDate(nullableStringValue(mapped, 'expense_date')),
          ),
          category: TextEditingController(
            text: stringValue(mapped, 'expense_category'),
          ),
          description: TextEditingController(
            text: stringValue(mapped, 'description'),
          ),
          amount: TextEditingController(text: stringValue(mapped, 'amount')),
          remarks: TextEditingController(text: stringValue(mapped, 'remarks')),
          projectId: intValue(mapped, 'project_id'),
          projectTaskId: intValue(mapped, 'project_task_id'),
        ),
      );
    }
  }
  if (editors.isEmpty) {
    editors.add(
      ExpenseLineEditors(
        expenseDate: TextEditingController(
          text: displayDate(DateTime.now().toIso8601String()),
        ),
        category: TextEditingController(),
        description: TextEditingController(),
        amount: TextEditingController(),
        remarks: TextEditingController(),
      ),
    );
  }
  return editors;
}

class ExpenseClaimsManagementController extends GetxController {
  ExpenseClaimsManagementController();

  static const List<AppDropdownItem<String?>> paymentFilterItems =
      <AppDropdownItem<String?>>[
        AppDropdownItem<String?>(value: null, label: 'All payments'),
        AppDropdownItem<String?>(value: 'unpaid', label: 'Unpaid'),
        AppDropdownItem<String?>(value: 'paid', label: 'Paid'),
      ];

  static const List<AppDropdownItem<String?>> statusFilterItems =
      <AppDropdownItem<String?>>[
        AppDropdownItem<String?>(value: null, label: 'All statuses'),
        AppDropdownItem<String?>(value: '0', label: 'Draft'),
        AppDropdownItem<String?>(value: '1', label: 'Applied'),
        AppDropdownItem<String?>(value: 'approved', label: 'Approved'),
        AppDropdownItem<String?>(value: 'reimbursed', label: 'Reimbursed'),
        AppDropdownItem<String?>(value: 'rejected', label: 'Rejected'),
        AppDropdownItem<String?>(value: 'cancelled', label: 'Cancelled'),
      ];

  final HrService hrService = HrService();
  final HrModuleRefreshController _refreshController =
      HrModuleRefreshController.ensureRegistered();
  final AccountsService accountsService = AccountsService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController claimNoController = TextEditingController();
  final TextEditingController claimDateController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool initialLoading = true;
  bool editorLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? companyBanner;
  int? companyId;
  List<ExpenseClaimModel> rows = const <ExpenseClaimModel>[];
  ExpenseClaimModel? selectedListRow;
  Map<String, dynamic>? editorSnapshot;
  int? editingClaimId;
  bool isNewClaim = false;
  int formGeneration = 0;

  int? linkedEmployeeId;
  bool canViewAllClaims = false;
  bool canSelfServiceClaims = false;

  List<EmployeeModel> employees = const <EmployeeModel>[];
  int? employeeId;

  int? filterEmployeeId;
  String? filterPaymentStatus;
  String? filterClaimStatus;

  List<ExpenseLineEditors> lineEditors = <ExpenseLineEditors>[];
  Worker? _refreshWorker;

  bool get employeeFieldReadOnly => true;

  bool get isSelfServiceUser => canSelfServiceClaims;

  String get editorTitle => isNewClaim
      ? 'New expense claim'
      : (editingClaimId != null ? 'Claim #$editingClaimId' : 'Expense claim');

  @override
  void onInit() {
    super.onInit();
    WorkingContextService.version.addListener(_onWorkingContextChanged);
    searchController.addListener(_onSearchChanged);
    _refreshWorker = ever<HrModuleRefreshEvent?>(_refreshController.lastEvent, (
      event,
    ) {
      if (event == null || event.source == 'expense_claims') {
        return;
      }
      unawaited(loadPage(selectClaimId: editingClaimId));
    });
    loadPage();
  }

  @override
  void onClose() {
    _refreshWorker?.dispose();
    WorkingContextService.version.removeListener(_onWorkingContextChanged);
    searchController.removeListener(_onSearchChanged);
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController.dispose();
    claimNoController.dispose();
    claimDateController.dispose();
    notesController.dispose();
    disposeLineEditors();
    super.onClose();
  }

  void _onWorkingContextChanged() {
    unawaited(loadPage());
  }

  void _onSearchChanged() {
    update();
  }

  void disposeLineEditors() {
    for (final editor in lineEditors) {
      editor.dispose();
    }
    lineEditors = <ExpenseLineEditors>[];
  }

  List<ExpenseClaimModel> get filteredRows {
    final query = searchController.text.trim().toLowerCase();
    final showApprovalQueueOnly = canViewAllClaims && !canSelfServiceClaims;
    final visibleRows = showApprovalQueueOnly
        ? rows
              .where((ExpenseClaimModel row) {
                return isHrApprovalQueueRow(row.toJson());
              })
              .toList(growable: false)
        : rows;
    if (query.isEmpty) {
      return visibleRows;
    }
    return visibleRows
        .where((ExpenseClaimModel row) {
          final data = row.toJson();
          return [
            stringValue(data, 'claim_no'),
            stringValue(data, 'claim_date'),
            stringValue(data, 'claim_status'),
            stringValue(data, 'total_amount'),
            nestedExpenseEmployeeName(data),
            expensePaymentSubtitle(data),
          ].join(' ').toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  List<EmployeeModel> get employeesForEditor {
    if (companyId == null) {
      return const <EmployeeModel>[];
    }
    final base = employees
        .where((item) => item.companyId == companyId && item.id != null)
        .toList(growable: false);
    if (isNewClaim && linkedEmployeeId != null) {
      return base
          .where((item) => item.id == linkedEmployeeId)
          .toList(growable: false);
    }
    if (linkedEmployeeId == null && !canViewAllClaims) {
      return base;
    }
    return base;
  }

  Future<void> loadPage({int? selectClaimId}) async {
    initialLoading = rows.isEmpty;
    pageError = null;
    update();

    try {
      final info = await hrSessionCompanyInfo();
      final sessionCompanyId = info.companyId;
      if (sessionCompanyId == null) {
        companyBanner = info.banner;
        companyId = null;
        canSelfServiceClaims = false;
        canViewAllClaims = false;
        linkedEmployeeId = null;
        rows = const <ExpenseClaimModel>[];
        initialLoading = false;
        pageError = 'Select a session company to load expense claims.';
        resetEditorToEmpty(notify: false);
        update();
        return;
      }

      final contextResponse = await hrService.expenseClaimsLinkedEmployee(
        companyId: sessionCompanyId,
      );
      final contextData = contextResponse.data ?? const <String, dynamic>{};
      final allowViewAll =
          contextData['can_view_all_claims'] == true ||
          contextData['can_view_all_claims'] == 1 ||
          contextData['can_view_all_hr_records'] == true ||
          contextData['can_view_all_hr_records'] == 1;
      final allowSelfService =
          contextData['can_self_service_expense_claims'] == true ||
          contextData['can_self_service_expense_claims'] == 1;
      final linkedId = intValue(contextData, 'employee_id');

      final employeeResponse = await hrService.employees(
        filters: <String, dynamic>{
          'per_page': 500,
          'sort_by': 'employee_name',
          'company_id': sessionCompanyId,
        },
      );
      employees = employeeResponse.data ?? const <EmployeeModel>[];

      final filters = <String, dynamic>{
        'company_id': sessionCompanyId,
        'per_page': 200,
      };
      if (allowViewAll && filterEmployeeId != null) {
        filters['employee_id'] = filterEmployeeId;
      }
      if ((filterPaymentStatus ?? '').isNotEmpty) {
        filters['payment_status'] = filterPaymentStatus;
      }
      if ((filterClaimStatus ?? '').isNotEmpty) {
        filters['claim_status'] = filterClaimStatus;
      }

      final listResponse = await hrService.expenseClaims(filters: filters);
      final nextRows = listResponse.data ?? const <ExpenseClaimModel>[];

      companyBanner = info.banner;
      companyId = sessionCompanyId;
      linkedEmployeeId = linkedId;
      canViewAllClaims = allowViewAll;
      canSelfServiceClaims = allowSelfService;
      rows = nextRows;
      initialLoading = false;

      final pickId =
          selectClaimId ??
          (selectedListRow == null
              ? null
              : intValue(selectedListRow!.toJson(), 'id'));

      if (pickId != null &&
          nextRows.any((row) => intValue(row.toJson(), 'id') == pickId)) {
        await hydrateEditorFromClaimId(pickId);
      } else if (nextRows.isNotEmpty) {
        final firstId = intValue(nextRows.first.toJson(), 'id');
        if (firstId != null) {
          await hydrateEditorFromClaimId(firstId);
        }
      } else {
        resetEditorToEmpty(notify: false);
      }
    } catch (errorValue) {
      pageError = errorValue.toString();
      initialLoading = false;
    }

    update();
  }

  void resetEditorToEmpty({bool notify = true}) {
    disposeLineEditors();
    claimNoController.clear();
    claimDateController.text = displayDate(DateTime.now().toIso8601String());
    notesController.clear();
    employeeId = linkedEmployeeId;
    editingClaimId = null;
    isNewClaim = false;
    selectedListRow = null;
    editorSnapshot = null;
    formError = null;
    editorLoading = false;
    lineEditors = expenseClaimEditorsFromJson(<String, dynamic>{});
    formGeneration++;
    if (notify) {
      update();
    }
  }

  void startNewClaim({required bool isDesktop}) {
    if (companyId == null) {
      return;
    }
    disposeLineEditors();
    claimNoController.clear();
    claimDateController.text = displayDate(DateTime.now().toIso8601String());
    notesController.clear();
    employeeId = linkedEmployeeId;
    editingClaimId = null;
    isNewClaim = true;
    selectedListRow = null;
    editorSnapshot = null;
    formError = null;
    editorLoading = false;
    lineEditors = expenseClaimEditorsFromJson(<String, dynamic>{});
    formGeneration++;
    if (!isDesktop) {
      workspaceController.openEditor();
    }
    update();
  }

  Future<void> syncExpenseClaimsListFromServer({int? selectClaimId}) async {
    if (companyId == null) {
      return;
    }
    final filters = <String, dynamic>{'company_id': companyId, 'per_page': 200};
    if (canViewAllClaims && filterEmployeeId != null) {
      filters['employee_id'] = filterEmployeeId;
    }
    if ((filterPaymentStatus ?? '').isNotEmpty) {
      filters['payment_status'] = filterPaymentStatus;
    }
    if ((filterClaimStatus ?? '').isNotEmpty) {
      filters['claim_status'] = filterClaimStatus;
    }
    final listResponse = await hrService.expenseClaims(filters: filters);
    final nextRows = listResponse.data ?? const <ExpenseClaimModel>[];
    final pickId = selectClaimId ?? editingClaimId;
    ExpenseClaimModel? match;
    if (pickId != null) {
      for (final row in nextRows) {
        if (intValue(row.toJson(), 'id') == pickId) {
          match = row;
          break;
        }
      }
    }
    rows = nextRows;
    if (match != null) {
      selectedListRow = match;
    }
    update();
  }

  Future<void> reloadEditorAndListAfterMutation({required int claimId}) async {
    await hydrateEditorFromClaimId(claimId, showLoading: false);
    if (formError != null) {
      return;
    }
    await syncExpenseClaimsListFromServer(selectClaimId: claimId);
  }

  Future<void> hydrateEditorFromClaimId(
    int id, {
    bool showLoading = true,
  }) async {
    if (companyId == null) {
      return;
    }
    if (showLoading) {
      editorLoading = true;
    }
    formError = null;
    isNewClaim = false;
    editingClaimId = id;
    update();

    final response = await hrService.expenseClaim(id);
    if (response.success != true || response.data == null) {
      if (showLoading) {
        editorLoading = false;
      }
      formError = response.message;
      update();
      return;
    }

    final data = response.data!.toJson();
    disposeLineEditors();
    claimNoController.text = stringValue(data, 'claim_no');
    claimDateController.text = displayDate(
      nullableStringValue(data, 'claim_date'),
    );
    notesController.text = stringValue(data, 'notes');
    employeeId = intValue(data, 'employee_id');
    lineEditors = expenseClaimEditorsFromJson(data);
    editorSnapshot = Map<String, dynamic>.from(data);
    selectedListRow = rows.cast<ExpenseClaimModel?>().firstWhere((
      ExpenseClaimModel? row,
    ) {
      if (row == null) {
        return false;
      }
      return intValue(row.toJson(), 'id') == id;
    }, orElse: () => selectedListRow);
    formGeneration++;
    if (showLoading) {
      editorLoading = false;
    }
    update();
  }

  Future<String?> submitClaim({
    required bool applyNow,
    FormState? formState,
  }) async {
    if (companyId == null) {
      return null;
    }
    final form = formState;
    if (form == null || !form.validate()) {
      return null;
    }

    final lines = <Map<String, dynamic>>[];
    for (final line in lineEditors) {
      lines.add(<String, dynamic>{
        'expense_date': line.expenseDate.text.trim(),
        'expense_category': line.category.text.trim(),
        'description': line.description.text.trim(),
        'amount': double.parse(line.amount.text.trim()),
        if (line.remarks.text.trim().isNotEmpty)
          'remarks': line.remarks.text.trim(),
        if (line.projectId != null) 'project_id': line.projectId,
        if (line.projectTaskId != null) 'project_task_id': line.projectTaskId,
      });
    }

    final body = <String, dynamic>{
      'company_id': companyId,
      'employee_id': employeeId,
      'claim_date': claimDateController.text.trim(),
      'claim_status': applyNow ? 1 : 0,
      'lines': lines,
    };
    final claimNo = claimNoController.text.trim();
    if (claimNo.isNotEmpty) {
      body['claim_no'] = claimNo;
    }
    final notes = notesController.text.trim();
    if (notes.isNotEmpty) {
      body['notes'] = notes;
    }

    saving = true;
    formError = null;
    update();

    try {
      final model = ExpenseClaimModel.fromJson(body);
      final response = isNewClaim || editingClaimId == null
          ? await hrService.createExpenseClaim(model)
          : await hrService.updateExpenseClaim(editingClaimId!, model);
      if (response.success != true || response.data == null) {
        formError = response.message;
        saving = false;
        update();
        return null;
      }
      final newId = intValue(response.data!.toJson(), 'id');
      if (applyNow &&
          !isNewClaim &&
          editingClaimId != null &&
          response.success == true) {
        final applyResponse = await hrService.applyExpenseClaim(
          editingClaimId!,
          ExpenseClaimModel.fromJson(const <String, dynamic>{}),
        );
        if (applyResponse.success != true || applyResponse.data == null) {
          formError = applyResponse.message;
          saving = false;
          update();
          return null;
        }
      }
      saving = false;
      _refreshController.notifyChanged(source: 'expense_claims');
      await loadPage(selectClaimId: newId);
      return applyNow
          ? 'Expense claim applied successfully.'
          : response.message;
    } catch (errorValue) {
      formError = errorValue.toString();
      saving = false;
      update();
      return null;
    }
  }

  String? editorStatus() {
    if (isNewClaim) {
      return null;
    }
    if (editorSnapshot != null) {
      return expenseClaimStatusCode(editorSnapshot!['claim_status']);
    }
    final row = selectedListRow?.toJson();
    if (row == null) {
      return null;
    }
    return expenseClaimStatusCode(row['claim_status']);
  }

  bool get editorEditable {
    final status = editorStatus();
    return isSelfServiceUser && (status == null || status == 'draft');
  }

  String selectedEmployeeFilterLabel() {
    if (filterEmployeeId == null) {
      return '';
    }
    for (final employee in employees) {
      if (employee.id == filterEmployeeId) {
        return employee.toString();
      }
    }
    return 'Employee #$filterEmployeeId';
  }

  String editorEmployeeLabel() {
    if (employeeId == null) {
      return '';
    }
    for (final employee in employeesForEditor) {
      if (employee.id == employeeId) {
        return employee.toString();
      }
    }
    return 'Employee #$employeeId';
  }

  List<String> expenseAppliedFilterChips() {
    return <String>[
      if (companyBanner != null) 'Company: $companyBanner',
      if (searchController.text.trim().isNotEmpty)
        'Search: ${searchController.text.trim()}',
      if (canViewAllClaims && filterEmployeeId != null)
        'Employee: ${selectedEmployeeFilterLabel()}',
      if ((filterPaymentStatus ?? '').isNotEmpty)
        'Payment: ${hrDropdownLabel(paymentFilterItems, filterPaymentStatus)}',
      if ((filterClaimStatus ?? '').isNotEmpty)
        'Status: ${hrDropdownLabel(statusFilterItems, filterClaimStatus)}',
    ];
  }

  void clearExpenseFilters() {
    searchController.clear();
    filterEmployeeId = null;
    filterPaymentStatus = null;
    filterClaimStatus = null;
    update();
  }

  void setFilterEmployeeId(int? value) {
    filterEmployeeId = value;
    update();
  }

  void setFilterPaymentStatus(String? value) {
    filterPaymentStatus = value;
    update();
  }

  void setFilterClaimStatus(String? value) {
    filterClaimStatus = value;
    update();
  }

  void setEmployeeId(int? value) {
    employeeId = value;
    update();
  }

  void addLine() {
    lineEditors.add(
      ExpenseLineEditors(
        expenseDate: TextEditingController(
          text: displayDate(DateTime.now().toIso8601String()),
        ),
        category: TextEditingController(),
        description: TextEditingController(),
        amount: TextEditingController(),
        remarks: TextEditingController(),
      ),
    );
    update();
  }

  void removeLineAt(int index) {
    final removed = lineEditors.removeAt(index);
    update();
    disposeDraftEntriesNextFrame<ExpenseLineEditors>([
      removed,
    ], (entry) => entry.dispose());
  }

  Future<void> selectClaim(ExpenseClaimModel item) async {
    selectedListRow = item;
    isNewClaim = false;
    update();
    final id = intValue(item.toJson(), 'id');
    if (id != null) {
      await hydrateEditorFromClaimId(id);
    }
  }
}
