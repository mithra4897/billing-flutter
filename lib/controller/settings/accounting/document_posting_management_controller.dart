import '../../../screen.dart';

class DocumentPostingLineDraft {
  DocumentPostingLineDraft({
    this.lineNo,
    this.accountId,
    this.entrySide = 'debit',
    String? amount,
    String? narration,
  }) : amountController = TextEditingController(text: amount ?? ''),
       narrationController = TextEditingController(text: narration ?? '');

  int? lineNo;
  int? accountId;
  String entrySide;
  final TextEditingController amountController;
  final TextEditingController narrationController;

  void dispose() {
    amountController.dispose();
    narrationController.dispose();
  }
}

class DocumentPostingManagementController extends GetxController {
  DocumentPostingManagementController();

  static const List<AppDropdownItem<String>> statusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'pending', label: 'Pending'),
        AppDropdownItem(value: 'posted', label: 'Posted'),
        AppDropdownItem(value: 'reversed', label: 'Reversed'),
        AppDropdownItem(value: 'failed', label: 'Failed'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  static const List<AppDropdownItem<String>> entryItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'debit', label: 'Debit'),
        AppDropdownItem(value: 'credit', label: 'Credit'),
      ];

  final AccountsService _accountsService = AccountsService();
  final MasterService _masterService = MasterService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController moduleController = TextEditingController();
  final TextEditingController tableController = TextEditingController();
  final TextEditingController documentIdController = TextEditingController();
  final TextEditingController documentNoController = TextEditingController();
  final TextEditingController documentDateController = TextEditingController();
  final TextEditingController voucherIdController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<DocumentPostingModel> rows = const <DocumentPostingModel>[];
  List<DocumentPostingModel> filteredRows = const <DocumentPostingModel>[];
  DocumentPostingModel? selectedPosting;

  List<FinancialYearModel> years = const <FinancialYearModel>[];
  List<PostingRuleGroupModel> groups = const <PostingRuleGroupModel>[];
  List<AccountModel> accounts = const <AccountModel>[];

  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? postingRuleGroupId;
  String postingStatus = 'pending';
  List<DocumentPostingLineDraft> lines = <DocumentPostingLineDraft>[
    DocumentPostingLineDraft(),
  ];

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
    moduleController.dispose();
    tableController.dispose();
    documentIdController.dispose();
    documentNoController.dispose();
    documentDateController.dispose();
    voucherIdController.dispose();
    remarksController.dispose();
    _disposeLines(lines);
    super.onClose();
  }

  void _handleWorkingContextChanged() {
    unawaited(loadPage(selectId: intValue(json(selectedPosting), 'id')));
  }

  Map<String, dynamic> json(DocumentPostingModel? model) =>
      model?.toJson() ?? const <String, dynamic>{};

  Future<void> loadPage({int? selectId}) async {
    initialLoading = rows.isEmpty;
    pageError = null;
    update();

    try {
      final results = await Future.wait<dynamic>([
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
        _masterService.branches(
          filters: const {'per_page': 500, 'sort_by': 'name'},
        ),
        _masterService.businessLocations(
          filters: const {'per_page': 500, 'sort_by': 'name'},
        ),
        _masterService.financialYears(
          filters: const {'per_page': 100, 'sort_by': 'fy_name'},
        ),
        _accountsService.postingRuleGroupsAll(
          filters: const {'sort_by': 'group_name', 'per_page': 200},
        ),
        _accountsService.accountsAll(
          filters: const {'sort_by': 'account_name'},
        ),
      ]);

      final companies =
          (results[0] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final branches =
          (results[1] as PaginatedResponse<BranchModel>).data ??
          const <BranchModel>[];
      final locations =
          (results[2] as PaginatedResponse<BusinessLocationModel>).data ??
          const <BusinessLocationModel>[];
      final nextYears =
          (results[3] as PaginatedResponse<FinancialYearModel>).data ??
          const <FinancialYearModel>[];
      final nextGroups =
          (results[4] as ApiResponse<List<PostingRuleGroupModel>>).data ??
          const <PostingRuleGroupModel>[];
      final nextAccounts =
          (results[5] as ApiResponse<List<AccountModel>>).data ??
          const <AccountModel>[];

      final activeCompanies = companies
          .where((item) => item.isActive)
          .toList(growable: false);
      final activeBranches = branches
          .where((item) => item.isActive)
          .toList(growable: false);
      final activeLocations = locations
          .where((item) => item.isActive)
          .toList(growable: false);
      final activeYears = nextYears
          .where((item) => item.isActive)
          .toList(growable: false);

      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: activeBranches,
            locations: activeLocations,
            financialYears: activeYears,
          );

      final postings = await _accountsService.documentPostings(
        filters: <String, dynamic>{
          'per_page': 200,
          'sort_by': 'document_date',
          if (contextSelection.companyId != null)
            'company_id': contextSelection.companyId,
        },
      );

      years = activeYears;
      companyId ??= contextSelection.companyId;
      branchId ??= contextSelection.branchId;
      locationId ??= contextSelection.locationId;
      financialYearId ??= contextSelection.financialYearId;
      groups = nextGroups;
      accounts = nextAccounts.where((item) => item.isActive).toList();
      rows = postings.data ?? const <DocumentPostingModel>[];
      filteredRows = _filter(rows, searchController.text);
      initialLoading = false;

      final selected = selectId != null
          ? rows.cast<DocumentPostingModel?>().firstWhere(
              (item) => intValue(json(item), 'id') == selectId,
              orElse: () => null,
            )
          : (selectedPosting == null
                ? (rows.isNotEmpty ? rows.first : null)
                : rows.cast<DocumentPostingModel?>().firstWhere(
                    (item) =>
                        intValue(json(item), 'id') ==
                        intValue(json(selectedPosting), 'id'),
                    orElse: () => rows.isNotEmpty ? rows.first : null,
                  ));

      if (selected != null) {
        await selectPosting(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (errorValue) {
      pageError = errorValue.toString();
      initialLoading = false;
    }

    update();
  }

  List<DocumentPostingModel> _filter(
    List<DocumentPostingModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (item) {
      final data = item.toJson();
      return [
        stringValue(data, 'document_module'),
        stringValue(data, 'document_table'),
        stringValue(data, 'document_no'),
        stringValue(data, 'posting_status'),
      ];
    });
  }

  void _applySearch() {
    filteredRows = _filter(rows, searchController.text);
    update();
  }

  Future<void> selectPosting(
    DocumentPostingModel item, {
    bool notify = true,
  }) async {
    final id = intValue(json(item), 'id');
    if (id == null) {
      return;
    }

    try {
      final response = await _accountsService.documentPosting(id);
      final full = response.data ?? item;
      final data = full.toJson();
      final rawLines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: false);

      selectedPosting = full;
      companyId = intValue(data, 'company_id');
      branchId = intValue(data, 'branch_id');
      locationId = intValue(data, 'location_id');
      financialYearId = intValue(data, 'financial_year_id');
      moduleController.text = stringValue(data, 'document_module');
      tableController.text = stringValue(data, 'document_table');
      documentIdController.text = stringValue(data, 'document_id');
      documentNoController.text = stringValue(data, 'document_no');
      documentDateController.text = (data['document_date'] ?? '')
          .toString()
          .split('T')
          .first
          .split(' ')
          .first;
      postingRuleGroupId = intValue(data, 'posting_rule_group_id');
      voucherIdController.text = stringValue(data, 'voucher_id');
      postingStatus = stringValue(data, 'posting_status', 'pending');
      remarksController.text = stringValue(data, 'remarks');
      _replaceLines(
        rawLines
            .map(
              (entry) => DocumentPostingLineDraft(
                lineNo: intValue(entry, 'line_no'),
                accountId: intValue(entry, 'account_id'),
                entrySide: stringValue(entry, 'entry_side', 'debit'),
                amount: stringValue(entry, 'amount'),
                narration: stringValue(entry, 'narration'),
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
    selectedPosting = null;
    moduleController.clear();
    tableController.clear();
    documentIdController.clear();
    documentNoController.clear();
    documentDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    postingRuleGroupId = null;
    voucherIdController.clear();
    postingStatus = 'pending';
    remarksController.clear();
    _replaceLines(const <DocumentPostingLineDraft>[], notify: false);
    formError = null;
    if (notify) {
      update();
    }
  }

  void addLine() {
    lines = List<DocumentPostingLineDraft>.from(lines)
      ..add(DocumentPostingLineDraft());
    update();
  }

  void removeLine(int index) {
    final next = List<DocumentPostingLineDraft>.from(lines)..removeAt(index);
    _replaceLines(next);
  }

  void setFinancialYearId(int? value) {
    financialYearId = value;
    update();
  }

  void setPostingRuleGroupId(int? value) {
    postingRuleGroupId = value;
    update();
  }

  void setPostingStatus(String? value) {
    postingStatus = value ?? 'pending';
    update();
  }

  void setLineAccountId(int index, int? value) {
    lines[index].accountId = value;
    update();
  }

  void setLineEntrySide(int index, String? value) {
    lines[index].entrySide = value ?? 'debit';
    update();
  }

  Map<String, dynamic> _payload() {
    final payloadLines = <Map<String, dynamic>>[];
    var index = 1;
    for (final line in lines) {
      final amount = double.tryParse(line.amountController.text.trim()) ?? 0;
      if (line.accountId == null || amount <= 0) {
        continue;
      }
      payloadLines.add(<String, dynamic>{
        'line_no': line.lineNo ?? index,
        'account_id': line.accountId,
        'entry_side': line.entrySide,
        'amount': amount,
        'narration': nullIfEmpty(line.narrationController.text),
      });
      index++;
    }

    final voucherRaw = voucherIdController.text.trim();
    final voucherId = int.tryParse(voucherRaw);

    return <String, dynamic>{
      'company_id': companyId,
      'branch_id': branchId,
      'location_id': locationId,
      'financial_year_id': financialYearId,
      'document_module': moduleController.text.trim(),
      'document_table': tableController.text.trim(),
      'document_id': int.tryParse(documentIdController.text.trim()) ?? 0,
      'document_no': nullIfEmpty(documentNoController.text),
      'document_date': documentDateController.text.trim(),
      'posting_rule_group_id': postingRuleGroupId,
      if (voucherRaw.isNotEmpty && voucherId != null) 'voucher_id': voucherId,
      'posting_status': postingStatus,
      'remarks': nullIfEmpty(remarksController.text),
      'lines': payloadLines,
    };
  }

  Future<void> savePosting() async {
    if (formKey.currentState?.validate() != true) {
      return;
    }
    if (companyId == null ||
        branchId == null ||
        locationId == null ||
        financialYearId == null) {
      formError = 'Company, branch, location and year required.';
      update();
      return;
    }

    final documentId = int.tryParse(documentIdController.text.trim());
    if (documentId == null || documentId < 1) {
      formError = 'Document ID must be a positive integer.';
      update();
      return;
    }

    saving = true;
    formError = null;
    update();

    final body = DocumentPostingModel.fromJson(_payload());

    try {
      final ApiResponse<DocumentPostingModel> response;
      final selectedId = intValue(json(selectedPosting), 'id');
      if (selectedId == null) {
        response = await _accountsService.createDocumentPosting(body);
      } else {
        response = await _accountsService.updateDocumentPosting(
          selectedId,
          body,
        );
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

  Future<void> deletePosting() async {
    final id = intValue(json(selectedPosting), 'id');
    if (id == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _accountsService.deleteDocumentPosting(id);
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

  void startNewPosting({required bool isDesktop}) {
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }

  void _replaceLines(
    List<DocumentPostingLineDraft> nextLines, {
    bool notify = true,
  }) {
    replaceDisposableDraftEntries<DocumentPostingLineDraft>(
      previous: lines,
      next: nextLines,
      createEmpty: () => DocumentPostingLineDraft(),
      assign: (entries) => lines = entries,
      dispose: (entry) => entry.dispose(),
      notify: notify ? update : null,
    );
  }

  void _disposeLines(List<DocumentPostingLineDraft> values) {
    for (final line in values) {
      line.dispose();
    }
  }
}
