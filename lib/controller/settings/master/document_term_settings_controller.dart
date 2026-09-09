import '../../../screen.dart';

class DocumentTermSettingsController extends GetxController {
  final MasterService _masterService = MasterService();
  final LatestRequestGuard _loadRequestGuard = LatestRequestGuard();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController termsController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  int? contextCompanyId;
  String companyName = '';
  List<DocumentTermSettingModel> records = const <DocumentTermSettingModel>[];
  List<DocumentTermSettingModel> filteredRecords =
      const <DocumentTermSettingModel>[];
  DocumentTermSettingModel? selectedRecord;
  String? documentType;
  bool isActive = true;

  bool get canCreate =>
      !initialLoading && records.any((record) => record.id == null);

  List<AppDropdownItem<String>> get documentTypeItems => records
      .where((record) => selectedRecord != null || record.id == null)
      .map(
        (record) => AppDropdownItem<String>(
          value: record.documentType,
          label: record.documentLabel,
        ),
      )
      .toList(growable: false);

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    WorkingContextService.version.addListener(_handleContextChanged);
    loadPage();
  }

  @override
  void onClose() {
    _loadRequestGuard.invalidate();
    WorkingContextService.version.removeListener(_handleContextChanged);
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    termsController.dispose();
    super.onClose();
  }

  Future<void> _handleContextChanged() => loadPage();

  Future<void> loadPage() async {
    final requestRevision = _loadRequestGuard.begin();
    initialLoading = records.isEmpty;
    pageError = null;
    update();

    try {
      await MasterDataCache.to.ensureLoaded();
      if (!_loadRequestGuard.isCurrent(requestRevision)) {
        return;
      }
      final cache = MasterDataCache.to;
      final context = await WorkingContextService.instance.resolveSelection(
        companies: cache.activeCompanies,
        branches: cache.activeBranches,
        locations: cache.activeLocations,
        financialYears: cache.activeFinancialYears,
      );
      if (!_loadRequestGuard.isCurrent(requestRevision)) {
        return;
      }
      contextCompanyId = context.companyId;
      final activeCompany = cache.companies.cast<CompanyModel?>().firstWhere(
        (company) => company?.id == context.companyId,
        orElse: () => null,
      );
      companyName = activeCompany?.legalName ?? 'Active company';
      final response = await _masterService.documentTerms();
      if (!_loadRequestGuard.isCurrent(requestRevision)) {
        return;
      }
      records = response.data ?? const <DocumentTermSettingModel>[];
      cache.replaceDocumentTerms(records, notify: false);
      filteredRecords = _filterRecords(records, searchController.text);
      final selectedType = selectedRecord?.documentType;
      final nextSelected = records.cast<DocumentTermSettingModel?>().firstWhere(
        (record) => record?.documentType == selectedType,
        orElse: () => records.isEmpty ? null : records.first,
      );
      if (nextSelected != null) {
        selectRecord(nextSelected, notify: false);
      } else {
        resetForm(notify: false);
      }
      initialLoading = false;
    } catch (error) {
      if (!_loadRequestGuard.isCurrent(requestRevision)) {
        return;
      }
      initialLoading = false;
      pageError = error is ApiException
          ? error.displayMessage
          : error.toString();
    }

    update();
  }

  List<DocumentTermSettingModel> _filterRecords(
    List<DocumentTermSettingModel> source,
    String query,
  ) => filterMasterList(
    source,
    query,
    (record) => <String>[record.documentLabel, record.documentType],
  );

  void _applySearch() {
    filteredRecords = _filterRecords(records, searchController.text);
    update();
  }

  void selectRecord(DocumentTermSettingModel record, {bool notify = true}) {
    selectedRecord = record;
    documentType = record.documentType;
    termsController.text = record.termsConditions;
    isActive = record.isActive;
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedRecord = null;
    documentType = null;
    termsController.clear();
    isActive = true;
    formError = null;
    if (notify) {
      update();
    }
  }

  void startNew({required bool isDesktop}) {
    if (!canCreate) {
      appScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('All supported document types already have terms.'),
        ),
      );
      return;
    }
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }

  void setDocumentType(String? value) {
    documentType = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  Future<void> save() async {
    final selectedDocumentType = documentType;
    if (selectedDocumentType == null || saving) {
      return;
    }

    final loadedCompanyId = contextCompanyId;
    final activeCompanyId = await SessionStorage.getCurrentCompanyId();
    if (loadedCompanyId == null || activeCompanyId != loadedCompanyId) {
      formError = 'Company context changed. Reloading document terms.';
      update();
      await loadPage();
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _masterService.updateDocumentTerms(
        selectedDocumentType,
        termsController.text,
        companyId: loadedCompanyId,
        isActive: isActive,
      );
      final saved = response.data;
      if (saved == null) {
        formError = response.message;
        return;
      }
      if (await SessionStorage.getCurrentCompanyId() != loadedCompanyId) {
        await loadPage();
        return;
      }

      MasterDataCache.to.replaceDocumentTerm(saved, notify: false);
      records = records
          .map(
            (record) =>
                record.documentType == saved.documentType ? saved : record,
          )
          .toList(growable: false);
      filteredRecords = _filterRecords(records, searchController.text);
      selectRecord(saved, notify: false);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    } catch (error) {
      formError = error is ApiException
          ? error.displayMessage
          : error.toString();
    } finally {
      saving = false;
      update();
    }
  }
}
