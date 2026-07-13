import '../../../screen.dart';

class DocumentSeriesManagementController extends GetxController {
  DocumentSeriesManagementController();

  final MasterService _masterService = MasterService();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController documentTypeController = TextEditingController();
  final TextEditingController prefixController = TextEditingController();
  final TextEditingController suffixController = TextEditingController();
  final TextEditingController nextNumberController = TextEditingController();
  final TextEditingController numberLengthController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<DocumentSeriesModel> series = const <DocumentSeriesModel>[];
  List<DocumentSeriesModel> filteredSeries = const <DocumentSeriesModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  DocumentSeriesModel? selectedSeries;
  int? contextCompanyId;
  int? contextFinancialYearId;
  int? companyId;
  int? financialYearId;
  bool isDefault = false;
  bool isActive = true;

  @override
  void onInit() {
    super.onInit();
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
    nameController.dispose();
    documentTypeController.dispose();
    prefixController.dispose();
    suffixController.dispose();
    nextNumberController.dispose();
    numberLengthController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  Future<void> loadData({int? selectId}) async {
    initialLoading = series.isEmpty;
    pageError = null;
    update();

    try {
      await MasterDataCache.to.ensureLoaded();
      final cache = MasterDataCache.to;
      final responses = await Future.wait<dynamic>([
        _masterService.documentSeries(
          filters: const {'per_page': 200, 'sort_by': 'series_name'},
        ),
      ]);
      final items =
          (responses[0] as PaginatedResponse<DocumentSeriesModel>).data ??
          const <DocumentSeriesModel>[];
      final activeCompanies = cache.activeCompanies;
      final activeFinancialYears = cache.activeFinancialYears;
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: activeFinancialYears,
          );

      series = items;
      companies = activeCompanies;
      contextCompanyId = contextSelection.companyId;
      contextFinancialYearId = contextSelection.financialYearId;
      filteredSeries = _filterSeries(items);
      initialLoading = false;

      final visibleSeries = _filterSeries(items);
      final selected = selectId != null
          ? visibleSeries.cast<DocumentSeriesModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedSeries == null
                ? (visibleSeries.isNotEmpty ? visibleSeries.first : null)
                : visibleSeries.cast<DocumentSeriesModel?>().firstWhere(
                    (item) => item?.id == selectedSeries?.id,
                    orElse: () =>
                        visibleSeries.isNotEmpty ? visibleSeries.first : null,
                  ));

      if (selected != null) {
        selectSeries(selected, notify: false);
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
    filteredSeries = _filterSeries(series);
    update();
  }

  List<DocumentSeriesModel> _filterSeries(List<DocumentSeriesModel> items) {
    final scoped = items
        .where(
          (entry) =>
              (contextCompanyId == null ||
                  entry.companyId == contextCompanyId) &&
              (contextFinancialYearId == null ||
                  entry.financialYearId == contextFinancialYearId),
        )
        .toList(growable: false);

    return filterMasterList(scoped, searchController.text, (entry) {
      return [
        entry.seriesCode ?? '',
        entry.seriesName ?? '',
        entry.documentType ?? '',
      ];
    });
  }

  void selectSeries(DocumentSeriesModel item, {bool notify = true}) {
    selectedSeries = item;
    companyId = item.companyId;
    financialYearId = item.financialYearId;
    nameController.text = item.seriesName ?? '';
    documentTypeController.text = item.documentType ?? '';
    prefixController.text = item.prefix ?? '';
    suffixController.text = item.suffix ?? '';
    nextNumberController.text = item.nextNumber?.toString() ?? '';
    numberLengthController.text = item.numberLength?.toString() ?? '';
    remarksController.text = item.remarks ?? '';
    isDefault = item.isDefault;
    isActive = item.isActive;
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedSeries = null;
    companyId = contextCompanyId;
    financialYearId = contextFinancialYearId;
    nameController.clear();
    documentTypeController.clear();
    prefixController.clear();
    suffixController.clear();
    nextNumberController.text = '1';
    numberLengthController.text = '6';
    remarksController.clear();
    isDefault = false;
    isActive = true;
    formError = null;
    if (notify) {
      update();
    }
  }

  void setIsDefault(bool value) {
    isDefault = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  void startNew({required bool isDesktop}) {
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    saving = true;
    formError = null;
    update();

    final model = DocumentSeriesModel(
      id: selectedSeries?.id,
      companyId: companyId,
      financialYearId: financialYearId,
      seriesName: nameController.text.trim(),
      documentType: documentTypeController.text.trim(),
      prefix: nullIfEmpty(prefixController.text),
      suffix: nullIfEmpty(suffixController.text),
      nextNumber: int.tryParse(nextNumberController.text.trim()),
      numberLength: int.tryParse(numberLengthController.text.trim()),
      isDefault: isDefault,
      isActive: isActive,
      remarks: nullIfEmpty(remarksController.text),
    );

    try {
      final response = selectedSeries == null
          ? await _masterService.store(
              '/masters/document-series',
              model.toJson(),
            )
          : await _masterService.update(
              '/masters/document-series/${selectedSeries!.id}',
              model.toJson(),
            );

      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadData(selectId: response.data?.id);
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }
}
