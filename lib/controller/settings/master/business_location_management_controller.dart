import '../../../screen.dart';

class BusinessLocationManagementController extends GetxController {
  BusinessLocationManagementController({
    required this.fixedCompanyId,
    required this.fixedBranchId,
  });

  final int? fixedCompanyId;
  final int? fixedBranchId;

  final MasterService _masterService = MasterService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  bool showDraftTile = false;
  String? pageError;
  String? formError;
  List<BusinessLocationModel> locations = const <BusinessLocationModel>[];
  List<BusinessLocationModel> filteredLocations =
      const <BusinessLocationModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<BranchModel> branches = const <BranchModel>[];
  BusinessLocationModel? selectedLocation;
  int? companyId;
  int? branchId;
  String locationType = 'billing';
  bool allowSales = true;
  bool allowPurchase = true;
  bool allowStock = true;
  bool allowAccounts = true;
  bool allowHr = true;
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
    codeController.dispose();
    nameController.dispose();
    contactController.dispose();
    phoneController.dispose();
    emailController.dispose();
    cityController.dispose();
    stateController.dispose();
    addressController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  Future<void> reloadForScope({
    required int? nextFixedCompanyId,
    required int? nextFixedBranchId,
  }) async {
    selectedLocation = null;
    await loadData();
  }

  Future<void> loadData({int? selectId}) async {
    initialLoading = locations.isEmpty;
    pageError = null;
    update();

    try {
      final responses = await Future.wait<dynamic>([
        _masterService.businessLocations(
          filters: const {'per_page': 100, 'sort_by': 'name'},
        ),
        _masterService.companies(filters: const {'per_page': 100}),
        _masterService.branches(filters: const {'per_page': 100}),
      ]);

      final nextLocations =
          (responses[0] as PaginatedResponse<BusinessLocationModel>).data ??
          const <BusinessLocationModel>[];
      final nextCompanies =
          (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final nextBranches =
          (responses[2] as PaginatedResponse<BranchModel>).data ??
          const <BranchModel>[];

      locations = nextLocations;
      companies = nextCompanies;
      branches = nextBranches;
      filteredLocations = filterLocations(nextLocations);
      initialLoading = false;
      update();

      final selected = selectId != null
          ? nextLocations.cast<BusinessLocationModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedLocation == null
                ? (nextLocations.isNotEmpty ? nextLocations.first : null)
                : nextLocations.cast<BusinessLocationModel?>().firstWhere(
                    (item) => item?.id == selectedLocation?.id,
                    orElse: () =>
                        nextLocations.isNotEmpty ? nextLocations.first : null,
                  ));

      if (selected != null) {
        selectLocation(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (errorValue) {
      initialLoading = false;
      pageError = errorValue.toString();
      update();
    }
  }

  void _applySearch() {
    filteredLocations = filterLocations(locations);
    update();
  }

  List<BusinessLocationModel> filterLocations(
    List<BusinessLocationModel> items,
  ) {
    final scoped = items
        .where((location) {
          if (fixedCompanyId != null && location.companyId != fixedCompanyId) {
            return false;
          }
          if (fixedBranchId != null && location.branchId != fixedBranchId) {
            return false;
          }
          return true;
        })
        .toList(growable: false);

    return filterMasterList(scoped, searchController.text, (location) {
      return [location.code ?? '', location.name ?? '', location.city ?? ''];
    });
  }

  void selectLocation(BusinessLocationModel location, {bool notify = true}) {
    selectedLocation = location;
    showDraftTile = false;
    companyId = fixedCompanyId ?? location.companyId;
    branchId = fixedBranchId ?? location.branchId;
    _setCode(location.code ?? '');
    nameController.text = location.name ?? '';
    contactController.text = location.contactPerson ?? '';
    phoneController.text = location.phone ?? '';
    emailController.text = location.email ?? '';
    cityController.text = location.city ?? '';
    stateController.text = location.stateName ?? location.stateCode ?? '';
    addressController.text = location.addressLine1 ?? '';
    locationType = location.locationType ?? 'billing';
    allowSales = location.allowSales;
    allowPurchase = location.allowPurchase;
    allowStock = location.allowStock;
    allowAccounts = location.allowAccounts;
    allowHr = location.allowHr;
    isDefault = location.isDefault;
    isActive = location.isActive;
    remarksController.text = location.remarks ?? '';
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedLocation = null;
    companyId =
        fixedCompanyId ?? (companies.isNotEmpty ? companies.first.id : null);
    branchId =
        fixedBranchId ??
        (branchesForCompany(branches, companyId).isNotEmpty
            ? branchesForCompany(branches, companyId).first.id
            : null);
    _setCode('');
    nameController.clear();
    contactController.clear();
    phoneController.clear();
    emailController.clear();
    cityController.clear();
    stateController.clear();
    addressController.clear();
    locationType = 'billing';
    allowSales = true;
    allowPurchase = true;
    allowStock = true;
    allowAccounts = true;
    allowHr = true;
    isDefault = false;
    isActive = true;
    remarksController.clear();
    formError = null;
    unawaited(_primeCodeSuggestion());
    if (notify) {
      update();
    }
  }

  bool get isNewLocation => selectedLocation?.id == null;

  void _setCode(String value) {
    codeController.value = codeController.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _primeCodeSuggestion() async {
    if (!isNewLocation || branchId == null) {
      return;
    }

    final nextBranchId = branchId!;
    try {
      final code = await _masterService.nextBusinessLocationCode(
        branchId: nextBranchId,
      );
      if (!isNewLocation || branchId != nextBranchId) {
        return;
      }
      if (code != null && code.trim().isNotEmpty) {
        _setCode(code.trim());
        update();
      }
    } catch (_) {}
  }

  void refreshAutoGeneratedCode() {
    if (!isNewLocation) {
      return;
    }
    _setCode('');
    unawaited(_primeCodeSuggestion());
    update();
  }

  List<BranchModel> get filteredBranches =>
      branchesForCompany(branches, fixedCompanyId ?? companyId)
          .where((branch) {
            return fixedBranchId == null || branch.id == fixedBranchId;
          })
          .toList(growable: false);

  void setCompanyId(int? value) {
    companyId = value;
    final scopedBranches = branchesForCompany(branches, value)
        .where((branch) => fixedBranchId == null || branch.id == fixedBranchId)
        .toList(growable: false);
    branchId = scopedBranches.isNotEmpty ? scopedBranches.first.id : null;
    update();
    refreshAutoGeneratedCode();
  }

  void setBranchId(int? value) {
    branchId = value;
    update();
    refreshAutoGeneratedCode();
  }

  void setLocationType(String? value) {
    locationType = value ?? locationType;
    update();
  }

  void setAllowSales(bool value) {
    allowSales = value;
    update();
  }

  void setAllowPurchase(bool value) {
    allowPurchase = value;
    update();
  }

  void setAllowStock(bool value) {
    allowStock = value;
    update();
  }

  void setAllowAccounts(bool value) {
    allowAccounts = value;
    update();
  }

  void setAllowHr(bool value) {
    allowHr = value;
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

  Future<void> save() async {
    if (formKey.currentState?.validate() != true) {
      return;
    }

    saving = true;
    formError = null;
    update();

    final model = BusinessLocationModel(
      id: selectedLocation?.id,
      companyId: companyId,
      branchId: branchId,
      code: codeController.text.trim(),
      name: nameController.text.trim(),
      locationType: locationType,
      contactPerson: nullIfEmpty(contactController.text),
      phone: nullIfEmpty(phoneController.text),
      email: nullIfEmpty(emailController.text),
      addressLine1: nullIfEmpty(addressController.text),
      city: nullIfEmpty(cityController.text),
      stateName: nullIfEmpty(stateController.text),
      allowSales: allowSales,
      allowPurchase: allowPurchase,
      allowStock: allowStock,
      allowAccounts: allowAccounts,
      allowHr: allowHr,
      isDefault: isDefault,
      isActive: isActive,
      remarks: nullIfEmpty(remarksController.text),
    );

    try {
      final response = selectedLocation == null
          ? await _masterService.createBusinessLocation(model)
          : await _masterService.updateBusinessLocation(
              selectedLocation!.id!,
              model,
            );
      final saved = response.data;
      if (saved == null) {
        formError = response.message;
      } else {
        appScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(response.message)),
        );
        showDraftTile = false;
        resetForm();
        await loadData(selectId: saved.id);
      }
    } catch (errorValue) {
      formError = errorValue.toString();
    } finally {
      saving = false;
      update();
    }
  }

  void startNewLocation({required bool isDesktop}) {
    showDraftTile = true;
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }

  void hideDraftTile() {
    showDraftTile = false;
    resetForm();
    update();
  }
}
