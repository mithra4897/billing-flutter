import '../../../screen.dart';

class BudgetLineDraft {
  BudgetLineDraft({this.accountId, String? amount, String? remarks})
    : amountController = TextEditingController(text: amount ?? ''),
      remarksController = TextEditingController(text: remarks ?? '');

  int? accountId;
  final TextEditingController amountController;
  final TextEditingController remarksController;

  void dispose() {
    amountController.dispose();
    remarksController.dispose();
  }
}

class BudgetManagementController extends GetxController {
  BudgetManagementController();

  static const List<AppDropdownItem<String>> statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'approved', label: 'Approved'),
        AppDropdownItem(value: 'closed', label: 'Closed'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  final AccountsService _accountsService = AccountsService();
  final MasterService _masterService = MasterService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<BudgetModel> rows = const <BudgetModel>[];
  List<BudgetModel> filteredRows = const <BudgetModel>[];
  BudgetModel? selectedBudget;
  List<FinancialYearModel> years = const <FinancialYearModel>[];
  List<AccountModel> accounts = const <AccountModel>[];

  int? companyId;
  int? financialYearId;
  String status = 'draft';
  bool isActive = true;
  List<BudgetLineDraft> lines = <BudgetLineDraft>[BudgetLineDraft()];

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    WorkingContextService.version.addListener(_handleWorkingContextChanged);
    loadPage();
  }

  @override
  void onClose() {
    WorkingContextService.version.removeListener(_handleWorkingContextChanged);
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    codeController.dispose();
    nameController.dispose();
    dateFromController.dispose();
    dateToController.dispose();
    notesController.dispose();
    _disposeLines(lines);
    super.onClose();
  }

  void _handleWorkingContextChanged() {
    unawaited(loadPage(selectId: intValue(json(selectedBudget), 'id')));
  }

  Map<String, dynamic> json(BudgetModel? model) => model?.toJson() ?? const {};

  Future<void> loadPage({int? selectId}) async {
    initialLoading = rows.isEmpty;
    pageError = null;
    update();

    try {
      final results = await Future.wait<dynamic>([
        _accountsService.budgets(
          filters: const {'per_page': 200, 'sort_by': 'budget_name'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
        _masterService.financialYears(
          filters: const {'per_page': 100, 'sort_by': 'fy_name'},
        ),
        _accountsService.accountsAll(
          filters: const {'sort_by': 'account_name'},
        ),
      ]);

      final budgets =
          (results[0] as PaginatedResponse<BudgetModel>).data ??
          const <BudgetModel>[];
      final companies =
          (results[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final nextYears =
          (results[2] as PaginatedResponse<FinancialYearModel>).data ??
          const <FinancialYearModel>[];
      final nextAccounts =
          (results[3] as ApiResponse<List<AccountModel>>).data ??
          const <AccountModel>[];

      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: companies
                .where((item) => item.isActive)
                .toList(growable: false),
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: nextYears
                .where((item) => item.isActive)
                .toList(growable: false),
          );

      rows = budgets;
      filteredRows = _filter(budgets, searchController.text);
      years = nextYears.where((item) => item.isActive).toList();
      accounts = nextAccounts.where((item) => item.isActive).toList();
      companyId ??= contextSelection.companyId;
      financialYearId ??= contextSelection.financialYearId;
      initialLoading = false;

      final selected = selectId != null
          ? budgets.cast<BudgetModel?>().firstWhere(
              (item) => intValue(json(item), 'id') == selectId,
              orElse: () => null,
            )
          : (selectedBudget == null
                ? (budgets.isNotEmpty ? budgets.first : null)
                : budgets.cast<BudgetModel?>().firstWhere(
                    (item) =>
                        intValue(json(item), 'id') ==
                        intValue(json(selectedBudget), 'id'),
                    orElse: () => budgets.isNotEmpty ? budgets.first : null,
                  ));

      if (selected != null) {
        await selectBudget(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (errorValue) {
      pageError = errorValue.toString();
      initialLoading = false;
    }

    update();
  }

  List<BudgetModel> _filter(List<BudgetModel> source, String query) {
    return filterMasterList(source, query, (item) {
      final data = item.toJson();
      return [
        stringValue(data, 'budget_code'),
        stringValue(data, 'budget_name'),
        stringValue(data, 'budget_status'),
      ];
    });
  }

  void _applySearch() {
    filteredRows = _filter(rows, searchController.text);
    update();
  }

  Future<void> selectBudget(BudgetModel item, {bool notify = true}) async {
    final id = intValue(json(item), 'id');
    if (id == null) {
      return;
    }

    try {
      final response = await _accountsService.budget(id);
      final full = response.data ?? item;
      final data = full.toJson();
      final lineMaps = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((raw) => Map<String, dynamic>.from(raw))
          .toList(growable: false);

      selectedBudget = full;
      companyId = intValue(data, 'company_id');
      financialYearId = intValue(data, 'financial_year_id');
      codeController.text = stringValue(data, 'budget_code');
      nameController.text = stringValue(data, 'budget_name');
      dateFromController.text = (data['date_from'] ?? '')
          .toString()
          .split('T')
          .first
          .split(' ')
          .first;
      dateToController.text = (data['date_to'] ?? '')
          .toString()
          .split('T')
          .first
          .split(' ')
          .first;
      status = stringValue(data, 'budget_status', 'draft');
      notesController.text = stringValue(data, 'notes');
      isActive = boolValue(data, 'is_active', fallback: true);
      _replaceLines(
        lineMaps
            .map(
              (entry) => BudgetLineDraft(
                accountId: intValue(entry, 'account_id'),
                amount: stringValue(entry, 'budget_amount'),
                remarks: stringValue(entry, 'remarks'),
              ),
            )
            .toList(growable: true),
        notify: false,
      );
      formError = null;
    } catch (errorValue) {
      formError = errorValue.toString();
    }

    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedBudget = null;
    codeController.clear();
    nameController.clear();
    dateFromController.text = DateTime.now().toIso8601String().split('T').first;
    dateToController.text = DateTime.now().toIso8601String().split('T').first;
    status = 'draft';
    notesController.clear();
    isActive = true;
    _replaceLines(const <BudgetLineDraft>[], notify: false);
    formError = null;
    if (notify) {
      update();
    }
  }

  void addLine() {
    lines = List<BudgetLineDraft>.from(lines)..add(BudgetLineDraft());
    update();
  }

  void removeLine(int index) {
    final next = List<BudgetLineDraft>.from(lines)..removeAt(index);
    _replaceLines(next);
  }

  void setFinancialYearId(int? value) {
    financialYearId = value;
    update();
  }

  void setStatus(String? value) {
    status = value ?? 'draft';
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  void setLineAccountId(int index, int? value) {
    lines[index].accountId = value;
    update();
  }

  Map<String, dynamic> _payload() {
    final payloadLines = <Map<String, dynamic>>[];
    for (final line in lines) {
      final amount = double.tryParse(line.amountController.text.trim()) ?? 0;
      if (line.accountId == null || amount <= 0) {
        continue;
      }
      payloadLines.add(<String, dynamic>{
        'account_id': line.accountId,
        'budget_amount': amount,
        'remarks': nullIfEmpty(line.remarksController.text),
      });
    }
    return <String, dynamic>{
      'company_id': companyId,
      'financial_year_id': financialYearId,
      'budget_code': codeController.text.trim(),
      'budget_name': nameController.text.trim(),
      'date_from': dateFromController.text.trim(),
      'date_to': dateToController.text.trim(),
      'budget_status': status,
      'notes': nullIfEmpty(notesController.text),
      'is_active': isActive,
      'lines': payloadLines,
    };
  }

  Future<void> saveBudget() async {
    if (formKey.currentState?.validate() != true) {
      return;
    }
    if (companyId == null) {
      formError = 'Company is required.';
      update();
      return;
    }
    final payloadLines = _payload()['lines'] as List<dynamic>;
    if (payloadLines.isEmpty) {
      formError = 'Add at least one budget line with amount.';
      update();
      return;
    }

    saving = true;
    formError = null;
    update();

    final body = BudgetModel.fromJson(_payload());
    try {
      final ApiResponse<BudgetModel> response;
      final selectedId = intValue(json(selectedBudget), 'id');
      if (selectedId == null) {
        response = await _accountsService.createBudget(body);
      } else {
        response = await _accountsService.updateBudget(selectedId, body);
      }
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage(
        selectId: intValue(json(response.data), 'id') ?? selectedId,
      );
    } catch (errorValue) {
      formError = errorValue.toString();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> deleteBudget() async {
    final id = intValue(json(selectedBudget), 'id');
    if (id == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _accountsService.deleteBudget(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage();
    } catch (errorValue) {
      formError = errorValue.toString();
    } finally {
      saving = false;
      update();
    }
  }

  Future<BudgetVsActualModel?> loadBudgetVsActual() async {
    final id = intValue(json(selectedBudget), 'id');
    if (id == null) {
      return null;
    }
    final response = await _accountsService.budgetVsActual(id);
    return response.data;
  }

  void startNewBudget({required bool isDesktop}) {
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }

  void _replaceLines(List<BudgetLineDraft> nextLines, {bool notify = true}) {
    replaceDisposableDraftEntries<BudgetLineDraft>(
      previous: lines,
      next: nextLines,
      createEmpty: () => BudgetLineDraft(),
      assign: (entries) => lines = entries,
      dispose: (entry) => entry.dispose(),
      notify: notify ? update : null,
    );
  }

  void _disposeLines(List<BudgetLineDraft> values) {
    for (final line in values) {
      line.dispose();
    }
  }
}
