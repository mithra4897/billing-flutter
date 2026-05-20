import '../../../screen.dart';

class BranchManagementController extends GetxController {
  static const List<AppDropdownItem<String>> branchTypeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'head_office', label: 'Head Office'),
        AppDropdownItem(value: 'branch_office', label: 'Branch Office'),
        AppDropdownItem(value: 'factory', label: 'Factory'),
        AppDropdownItem(value: 'warehouse_office', label: 'Warehouse Office'),
        AppDropdownItem(value: 'retail_outlet', label: 'Retail Outlet'),
        AppDropdownItem(value: 'service_center', label: 'Service Center'),
        AppDropdownItem(value: 'other', label: 'Other'),
      ];

  BranchManagementController({required this.initialTabIndex});

  final MasterService _masterService = MasterService();
  final int initialTabIndex;

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<BranchModel> branches = const <BranchModel>[];
  List<BranchModel> filteredBranches = const <BranchModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  BranchModel? selectedBranch;
  int? contextCompanyId;
  int? companyId;
  String branchType = 'branch_office';
  bool isHeadOffice = false;
  bool isActive = true;
  int activeTabIndex = 0;

  @override
  void onInit() {
    super.onInit();
    activeTabIndex = initialTabIndex.clamp(0, 3);
    searchController.addListener(_applySearch);
    loadData();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    codeController.dispose();
    nameController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  Future<void> loadData({int? selectId, int? companyIdHint}) async {
    initialLoading = branches.isEmpty;
    pageError = null;
    update();

    try {
      final companiesResponse = await _masterService.companies(
        filters: const {'per_page': 100, 'sort_by': 'legal_name'},
      );
      final nextCompanies = companiesResponse.data ?? const <CompanyModel>[];
      final activeCompanies = nextCompanies
          .where((company) => company.isActive)
          .toList(growable: false);
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );

      final filterCompanyId = companyIdHint ?? contextSelection.companyId;
      final branchFilters = <String, dynamic>{
        'per_page': 500,
        'sort_by': 'name',
      };
      if (filterCompanyId != null) {
        branchFilters['company_id'] = filterCompanyId;
      }

      final branchesResponse = await _masterService.branches(
        filters: branchFilters,
      );
      List<BranchModel> nextBranches =
          branchesResponse.data ?? const <BranchModel>[];

      BranchModel? selectTarget;
      if (selectId != null) {
        for (final branch in nextBranches) {
          if (branch.id == selectId) {
            selectTarget = branch;
            break;
          }
        }
        if (selectTarget == null) {
          try {
            final detailResp = await _masterService.branch(selectId);
            final detail = detailResp.data;
            if (detail != null) {
              nextBranches = [...nextBranches, detail];
              selectTarget = detail;
            }
          } catch (_) {}
        }
      }

      final resolvedContextCompanyId =
          selectTarget?.companyId ?? companyIdHint ?? contextSelection.companyId;

      branches = nextBranches;
      companies = activeCompanies;
      contextCompanyId = resolvedContextCompanyId;
      filteredBranches = _filterBranches(nextBranches);
      initialLoading = false;

      final visibleBranches = _filterBranches(nextBranches);
      final selected = selectId != null
          ? visibleBranches.cast<BranchModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedBranch == null
                ? (visibleBranches.isNotEmpty ? visibleBranches.first : null)
                : visibleBranches.cast<BranchModel?>().firstWhere(
                    (item) => item?.id == selectedBranch?.id,
                    orElse: () => visibleBranches.isNotEmpty
                        ? visibleBranches.first
                        : null,
                  ));

      if (selected != null) {
        selectBranch(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (error) {
      initialLoading = false;
      pageError = error.toString();
    }

    update();
  }

  void _applySearch() {
    filteredBranches = _filterBranches(branches);
    update();
  }

  List<BranchModel> _filterBranches(List<BranchModel> items) {
    final scoped = items
        .where(
          (branch) =>
              contextCompanyId == null || branch.companyId == contextCompanyId,
        )
        .toList(growable: false);

    return filterMasterList(scoped, searchController.text, (branch) {
      return [branch.code ?? '', branch.name ?? ''];
    });
  }

  void selectBranch(BranchModel branch, {bool notify = true}) {
    selectedBranch = branch;
    companyId = branch.companyId;
    _setCode(branch.code ?? '');
    nameController.text = branch.name ?? '';
    branchType = branch.branchType ?? 'branch_office';
    isHeadOffice = branch.isHeadOffice;
    isActive = branch.isActive;
    remarksController.text = branch.remarks ?? '';
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedBranch = null;
    companyId = contextCompanyId ?? (companies.isNotEmpty ? companies.first.id : null);
    _setCode('');
    nameController.clear();
    branchType = 'branch_office';
    isHeadOffice = false;
    isActive = true;
    remarksController.clear();
    formError = null;
    unawaited(_primeCodeSuggestion());
    if (notify) {
      update();
    }
  }

  bool get isNewBranch => selectedBranch?.id == null;

  void _setCode(String value) {
    codeController.value = codeController.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _primeCodeSuggestion() async {
    if (!isNewBranch || companyId == null) {
      return;
    }

    final nextCompanyId = companyId!;
    final nextBranchType = branchType;
    try {
      final code = await _masterService.nextBranchCode(
        companyId: nextCompanyId,
        branchType: nextBranchType,
      );
      if (!isNewBranch ||
          companyId != nextCompanyId ||
          branchType != nextBranchType) {
        return;
      }
      if (code != null && code.trim().isNotEmpty) {
        _setCode(code.trim());
        update();
      }
    } catch (_) {}
  }

  void refreshAutoGeneratedCode() {
    if (!isNewBranch) {
      return;
    }
    _setCode('');
    unawaited(_primeCodeSuggestion());
    update();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    saving = true;
    formError = null;
    update();

    final model = BranchModel(
      id: selectedBranch?.id,
      companyId: companyId,
      code: codeController.text.trim(),
      name: nameController.text.trim(),
      branchType: branchType,
      isHeadOffice: isHeadOffice,
      isActive: isActive,
      remarks: nullIfEmpty(remarksController.text),
    );

    try {
      final response = selectedBranch == null
          ? await _masterService.createBranch(model)
          : await _masterService.updateBranch(selectedBranch!.id!, model);
      final saved = response.data;
      if (saved == null) {
        formError = response.message;
        update();
        return;
      }
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadData(selectId: saved.id, companyIdHint: saved.companyId);
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  void startNewBranch({required bool isDesktop}) {
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }

  void setCompanyId(int? value) {
    companyId = value;
    refreshAutoGeneratedCode();
  }

  void setBranchType(String? value) {
    branchType = value ?? branchType;
    refreshAutoGeneratedCode();
  }

  void setIsHeadOffice(bool value) {
    isHeadOffice = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  void setActiveTabIndex(int index) {
    activeTabIndex = index;
    update();
  }
}
