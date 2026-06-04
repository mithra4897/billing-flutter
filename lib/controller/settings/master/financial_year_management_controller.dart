import '../../../screen.dart';

class FinancialYearManagementController extends GetxController {
  FinancialYearManagementController({
    required this.embedded,
    required int? fixedCompanyId,
  }) : _fixedCompanyId = fixedCompanyId;

  final MasterService _masterService = MasterService();
  final bool embedded;

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController fyCodeController = TextEditingController();
  final TextEditingController fyNameController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController lockDateController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  int? _fixedCompanyId;
  int? get fixedCompanyId => _fixedCompanyId;

  bool initialLoading = true;
  bool saving = false;
  bool activating = false;
  bool showDraftTile = false;
  String? pageError;
  String? formError;
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<FinancialYearModel> filteredFinancialYears =
      const <FinancialYearModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  FinancialYearModel? selectedFinancialYear;
  int? companyId;
  bool isCurrent = false;
  bool isLocked = false;
  bool isActive = true;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    startDateController.addListener(_syncGeneratedNames);
    endDateController.addListener(_syncGeneratedNames);
    loadData();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    startDateController.removeListener(_syncGeneratedNames);
    endDateController.removeListener(_syncGeneratedNames);
    fyCodeController.dispose();
    fyNameController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    lockDateController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  Future<void> updateFixedCompanyId(int? value) async {
    if (_fixedCompanyId == value) {
      return;
    }
    _fixedCompanyId = value;
    selectedFinancialYear = null;
    await loadData();
  }

  Future<void> loadData({int? selectId}) async {
    initialLoading = financialYears.isEmpty;
    pageError = null;
    update();

    try {
      final responses = await Future.wait([
        _masterService.financialYears(
          filters: {
            'per_page': 200,
            'sort_by': 'start_date',
            'sort_order': 'desc',
          },
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
      ]);

      final nextFinancialYears =
          (responses[0].data as List<FinancialYearModel>?) ??
          const <FinancialYearModel>[];
      final nextCompanies =
          (responses[1].data as List<CompanyModel>?) ?? const <CompanyModel>[];

      financialYears = nextFinancialYears;
      companies = nextCompanies;
      filteredFinancialYears = _filteredItems(nextFinancialYears);
      initialLoading = false;

      final selected = selectId != null
          ? nextFinancialYears.cast<FinancialYearModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedFinancialYear == null
                ? (filteredFinancialYears.isNotEmpty
                      ? filteredFinancialYears.first
                      : null)
                : nextFinancialYears.cast<FinancialYearModel?>().firstWhere(
                    (item) => item?.id == selectedFinancialYear?.id,
                    orElse: () => filteredFinancialYears.isNotEmpty
                        ? filteredFinancialYears.first
                        : null,
                  ));

      if (selected != null) {
        selectFinancialYear(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (error) {
      initialLoading = false;
      pageError = error.toString();
    }

    update();
  }

  List<FinancialYearModel> _filteredItems(List<FinancialYearModel> source) {
    final scoped = fixedCompanyId == null
        ? source
        : source
              .where((item) => item.companyId == fixedCompanyId)
              .toList(growable: false);

    if (embedded && fixedCompanyId != null) {
      return scoped;
    }

    return filterMasterList(scoped, searchController.text, (item) {
      return [
        item.fyCode ?? '',
        item.fyName ?? '',
        item.companyName ?? companyNameById(companies, item.companyId),
      ];
    });
  }

  void _applySearch() {
    if (embedded && fixedCompanyId != null) {
      return;
    }

    filteredFinancialYears = _filteredItems(financialYears);
    update();
  }

  void _syncGeneratedNames() {
    final start = startDateController.text.trim();
    final end = endDateController.text.trim();
    if (start.length != 10 || end.length != 10) {
      return;
    }

    final startYear = int.tryParse(start.substring(0, 4));
    final endYear = int.tryParse(end.substring(0, 4));
    if (startYear == null || endYear == null) {
      return;
    }

    final fyCode =
        'FY${startYear.toString().substring(2)}-${endYear.toString().substring(2)}';
    final fyName = '$startYear-$endYear';

    fyCodeController.value = fyCodeController.value.copyWith(
      text: fyCode,
      selection: TextSelection.collapsed(offset: fyCode.length),
    );
    fyNameController.value = fyNameController.value.copyWith(
      text: fyName,
      selection: TextSelection.collapsed(offset: fyName.length),
    );

    if (isLocked && lockDateController.text.trim().isEmpty) {
      lockDateController.text = end;
    }
  }

  void selectFinancialYear(FinancialYearModel item, {bool notify = true}) {
    selectedFinancialYear = item;
    showDraftTile = false;
    companyId = fixedCompanyId ?? item.companyId;
    fyCodeController.text = item.fyCode ?? '';
    fyNameController.text = item.fyName ?? '';
    startDateController.text = normalizeDateValue(item.startDate);
    endDateController.text = normalizeDateValue(item.endDate);
    lockDateController.text = normalizeDateValue(item.lockDate);
    remarksController.text = item.remarks ?? '';
    isCurrent = item.isCurrent;
    isLocked = item.isLocked;
    isActive = item.isActive;
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedFinancialYear = null;
    companyId =
        fixedCompanyId ?? (companies.isNotEmpty ? companies.first.id : null);
    fyCodeController.clear();
    fyNameController.clear();
    startDateController.clear();
    endDateController.clear();
    lockDateController.clear();
    remarksController.clear();
    isCurrent = false;
    isLocked = false;
    isActive = true;
    formError = null;
    _syncGeneratedNames();
    if (notify) {
      update();
    }
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    saving = true;
    formError = null;
    update();

    final model = FinancialYearModel(
      id: selectedFinancialYear?.id,
      companyId: companyId,
      fyCode: nullIfEmpty(fyCodeController.text),
      fyName: nullIfEmpty(fyNameController.text),
      startDate: nullIfEmpty(startDateController.text),
      endDate: nullIfEmpty(endDateController.text),
      isCurrent: isCurrent,
      isLocked: isLocked,
      lockDate: isLocked ? nullIfEmpty(lockDateController.text) : null,
      isActive: isCurrent ? true : isActive,
      remarks: nullIfEmpty(remarksController.text),
    );

    try {
      final response = selectedFinancialYear == null
          ? await _masterService.createFinancialYear(model)
          : await _masterService.updateFinancialYear(
              selectedFinancialYear!.id!,
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
      showDraftTile = false;
      resetForm(notify: false);
      await loadData();
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> setAsCurrent() async {
    final selected = selectedFinancialYear;
    if (selected?.id == null) {
      return;
    }

    activating = true;
    formError = null;
    update();

    try {
      final response = await _masterService.setActiveFinancialYear(
        selected!.id!,
      );
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      showDraftTile = false;
      resetForm(notify: false);
      await loadData();
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      activating = false;
      update();
    }
  }

  void startNewFinancialYear({required bool isDesktop}) {
    showDraftTile = true;
    resetForm();

    if (!embedded && !isDesktop) {
      workspaceController.openEditor();
    }
  }

  void setCompanyId(int? value) {
    companyId = value;
    update();
  }

  void setIsCurrent(bool value) {
    isCurrent = value;
    if (value) {
      isActive = true;
    }
    update();
  }

  void setIsLocked(bool value) {
    isLocked = value;
    if (!value) {
      lockDateController.clear();
    } else if (lockDateController.text.trim().isEmpty) {
      lockDateController.text = endDateController.text.trim();
    }
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  void hideDraftTile() {
    showDraftTile = false;
    resetForm();
  }

  void toggleEmbeddedSelection(FinancialYearModel item) {
    if (identical(item, selectedFinancialYear)) {
      resetForm();
    } else {
      selectFinancialYear(item);
    }
  }
}
