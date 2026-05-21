import '../../../screen.dart';

class GstRegistrationManagementController extends GetxController {
  GstRegistrationManagementController({
    this.embedded = false,
    this.fixedCompanyId,
    this.fixedBranchId,
  });

  final bool embedded;
  final int? fixedCompanyId;
  final int? fixedBranchId;

  static const List<AppDropdownItem<String>> registrationTypes =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'regular', label: 'Regular'),
        AppDropdownItem(value: 'composition', label: 'Composition'),
        AppDropdownItem(value: 'sez', label: 'SEZ'),
        AppDropdownItem(value: 'sez_unit', label: 'SEZ Unit'),
        AppDropdownItem(value: 'casual', label: 'Casual'),
        AppDropdownItem(value: 'non_resident', label: 'Non Resident'),
        AppDropdownItem(value: 'unregistered', label: 'Unregistered'),
      ];

  final TaxesService taxesService = TaxesService();
  final MasterService masterService = MasterService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController gstinController = TextEditingController();
  final TextEditingController panController = TextEditingController();
  final TextEditingController legalNameController = TextEditingController();
  final TextEditingController tradeNameController = TextEditingController();
  final TextEditingController effectiveFromController = TextEditingController();
  final TextEditingController effectiveToController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  bool showDraftTile = false;
  String? pageError;
  String? formError;
  List<GstRegistrationModel> items = const <GstRegistrationModel>[];
  List<GstRegistrationModel> filteredItems = const <GstRegistrationModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<BranchModel> branches = const <BranchModel>[];
  List<BusinessLocationModel> locations = const <BusinessLocationModel>[];
  List<StateModel> states = const <StateModel>[];
  GstRegistrationModel? selectedItem;
  int? contextCompanyId;
  int? contextBranchId;
  int? contextLocationId;
  int? companyId;
  int? branchId;
  int? locationId;
  int? stateId;
  String registrationType = 'regular';
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
    gstinController.dispose();
    panController.dispose();
    legalNameController.dispose();
    tradeNameController.dispose();
    effectiveFromController.dispose();
    effectiveToController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  Future<void> loadData({int? selectId}) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();

    try {
      final responses = await Future.wait<dynamic>([
        taxesService.gstRegistrations(filters: const {'per_page': 200}),
        masterService.companies(filters: const {'per_page': 200}),
        masterService.branches(filters: const {'per_page': 200}),
        masterService.businessLocations(filters: const {'per_page': 200}),
        taxesService.states(filters: const {'per_page': 200}),
      ]);

      final nextItems =
          (responses[0] as PaginatedResponse<GstRegistrationModel>).data ??
          const <GstRegistrationModel>[];
      final nextCompanies =
          (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final nextBranches =
          (responses[2] as PaginatedResponse<BranchModel>).data ??
          const <BranchModel>[];
      final nextLocations =
          (responses[3] as PaginatedResponse<BusinessLocationModel>).data ??
          const <BusinessLocationModel>[];
      final nextStates =
          (responses[4] as PaginatedResponse<StateModel>).data ??
          const <StateModel>[];

      final activeCompanies = nextCompanies
          .where((item) => item.isActive)
          .toList(growable: false);
      final activeBranches = nextBranches
          .where((item) => item.isActive)
          .toList(growable: false);
      final activeLocations = nextLocations
          .where((item) => item.isActive)
          .toList(growable: false);
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: activeBranches,
            locations: activeLocations,
            financialYears: const <FinancialYearModel>[],
          );

      items = nextItems;
      companies = activeCompanies;
      branches = activeBranches;
      locations = activeLocations;
      states = nextStates;
      contextCompanyId = contextSelection.companyId;
      contextBranchId = contextSelection.branchId;
      contextLocationId = contextSelection.locationId;
      filteredItems = filterItems(nextItems);
      initialLoading = false;

      final visibleItems = filterItems(nextItems);
      final selected = selectId != null
          ? visibleItems.cast<GstRegistrationModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedItem == null
                ? (visibleItems.isNotEmpty ? visibleItems.first : null)
                : visibleItems.cast<GstRegistrationModel?>().firstWhere(
                    (item) => item?.id == selectedItem?.id,
                    orElse: () =>
                        visibleItems.isNotEmpty ? visibleItems.first : null,
                  ));

      if (selected != null) {
        selectItem(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (error) {
      initialLoading = false;
      pageError = error.toString();
    }

    update();
  }

  List<GstRegistrationModel> scopedItems(List<GstRegistrationModel> source) {
    return source
        .where((item) {
          final scopedCompanyId = fixedCompanyId ?? contextCompanyId;
          final scopedBranchId = fixedBranchId ?? contextBranchId;
          final scopedLocationId = fixedBranchId == null
              ? contextLocationId
              : null;

          if (scopedCompanyId != null && item.companyId != scopedCompanyId) {
            return false;
          }
          if (scopedBranchId != null && item.branchId != scopedBranchId) {
            return false;
          }
          if (fixedBranchId == null &&
              scopedLocationId != null &&
              item.locationId != null &&
              item.locationId != scopedLocationId) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  List<GstRegistrationModel> filterItems(List<GstRegistrationModel> source) {
    final scoped = scopedItems(source);
    if (embedded && (fixedCompanyId != null || fixedBranchId != null)) {
      return scoped;
    }
    return filterMasterList(scoped, searchController.text, (item) {
      return [
        item.registrationName,
        item.gstin,
        companyNameById(companies, item.companyId),
        locationNameById(locations, item.locationId),
      ];
    });
  }

  void _applySearch() {
    if (embedded && (fixedCompanyId != null || fixedBranchId != null)) {
      return;
    }
    filteredItems = filterItems(items);
    update();
  }

  void selectItem(GstRegistrationModel item, {bool notify = true}) {
    selectedItem = item;
    showDraftTile = false;
    companyId = item.companyId;
    branchId = item.branchId;
    locationId = item.locationId;
    stateId = item.stateId;
    nameController.text = item.registrationName;
    gstinController.text = item.gstin;
    panController.text = item.panNo;
    legalNameController.text = item.legalName;
    tradeNameController.text = item.tradeName;
    effectiveFromController.text = item.effectiveFrom;
    effectiveToController.text = item.effectiveTo;
    remarksController.text = item.remarks ?? '';
    registrationType = item.registrationType.isEmpty
        ? 'regular'
        : item.registrationType;
    isDefault = item.isDefault;
    isActive = item.isActive;
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedItem = null;
    companyId =
        fixedCompanyId ??
        contextCompanyId ??
        (companies.isNotEmpty ? companies.first.id : null);
    final companyBranchItems = branchesForCompany(branches, companyId);
    branchId =
        fixedBranchId ??
        contextBranchId ??
        (companyBranchItems.isNotEmpty ? companyBranchItems.first.id : null);
    final branchLocationItems = locationsForBranch(locations, branchId);
    locationId =
        contextLocationId ??
        (branchLocationItems.isNotEmpty ? branchLocationItems.first.id : null);
    stateId = null;
    nameController.clear();
    gstinController.clear();
    panController.clear();
    legalNameController.clear();
    tradeNameController.clear();
    effectiveFromController.clear();
    effectiveToController.clear();
    remarksController.clear();
    registrationType = 'regular';
    isDefault = false;
    isActive = true;
    formError = null;
    if (notify) {
      update();
    }
  }

  void startNew({required bool isDesktop}) {
    showDraftTile = true;
    resetForm();
    if (!embedded && !isDesktop) {
      workspaceController.openEditor();
    }
  }

  void hideDraftAndReset() {
    showDraftTile = false;
    resetForm();
    update();
  }

  void setStateId(int? value) {
    stateId = value;
    update();
  }

  void setRegistrationType(String? value) {
    registrationType = value ?? 'regular';
    update();
  }

  void setIsDefault(bool value) {
    isDefault = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  Future<String?> save() async {
    saving = true;
    formError = null;
    update();

    final model = GstRegistrationModel(
      id: selectedItem?.id,
      companyId: companyId,
      branchId: branchId,
      locationId: locationId,
      registrationName: nameController.text.trim(),
      gstin: gstinController.text.trim(),
      panNo: panController.text.trim(),
      stateId: stateId,
      legalName: legalNameController.text.trim(),
      tradeName: tradeNameController.text.trim(),
      registrationType: registrationType,
      effectiveFrom: effectiveFromController.text.trim(),
      effectiveTo: effectiveToController.text.trim(),
      isDefault: isDefault,
      isActive: isActive,
      remarks: nullIfEmpty(remarksController.text),
    );

    try {
      final response = selectedItem == null
          ? await taxesService.createGstRegistration(model)
          : await taxesService.updateGstRegistration(selectedItem!.id!, model);
      final saved = response.data;
      showDraftTile = false;
      resetForm(notify: false);
      saving = false;
      await loadData(selectId: saved?.id);
      return response.message;
    } catch (error) {
      formError = error.toString();
      saving = false;
      update();
      return null;
    }
  }

  Future<String?> delete() async {
    final id = selectedItem?.id;
    if (id == null) {
      return null;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await taxesService.deleteGstRegistration(id);
      saving = false;
      await loadData();
      return response.message;
    } catch (error) {
      formError = error.toString();
      saving = false;
      update();
      return null;
    }
  }
}
