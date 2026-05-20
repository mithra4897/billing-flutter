import '../../../screen.dart';

class WarehouseManagementController extends GetxController {
  WarehouseManagementController({
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
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  bool showDraftTile = false;
  String? pageError;
  String? formError;
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  List<WarehouseModel> filteredWarehouses = const <WarehouseModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<BranchModel> branches = const <BranchModel>[];
  List<BusinessLocationModel> locations = const <BusinessLocationModel>[];
  WarehouseModel? selectedWarehouse;
  int? companyId;
  int? branchId;
  int? locationId;
  int? parentWarehouseId;
  String warehouseType = 'main';
  bool allowNegativeStock = false;
  bool isSellableStock = true;
  bool isReservedOnly = false;
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
    remarksController.dispose();
    super.onClose();
  }

  Future<void> reloadForScope() async {
    selectedWarehouse = null;
    await loadData();
  }

  Future<void> loadData({int? selectId}) async {
    initialLoading = warehouses.isEmpty;
    pageError = null;
    update();

    try {
      final responses = await Future.wait<dynamic>([
        _masterService.warehouses(
          filters: const {'per_page': 100, 'sort_by': 'name'},
        ),
        _masterService.companies(filters: const {'per_page': 100}),
        _masterService.branches(filters: const {'per_page': 100}),
        _masterService.businessLocations(filters: const {'per_page': 100}),
      ]);

      final nextWarehouses =
          (responses[0] as PaginatedResponse<WarehouseModel>).data ??
          const <WarehouseModel>[];
      final nextCompanies =
          (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final nextBranches =
          (responses[2] as PaginatedResponse<BranchModel>).data ??
          const <BranchModel>[];
      final nextLocations =
          (responses[3] as PaginatedResponse<BusinessLocationModel>).data ??
          const <BusinessLocationModel>[];

      warehouses = nextWarehouses;
      companies = nextCompanies;
      branches = nextBranches;
      locations = nextLocations;
      filteredWarehouses = filterWarehouses(nextWarehouses);
      initialLoading = false;
      update();

      final selected = selectId != null
          ? nextWarehouses.cast<WarehouseModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedWarehouse == null
                ? (nextWarehouses.isNotEmpty ? nextWarehouses.first : null)
                : nextWarehouses.cast<WarehouseModel?>().firstWhere(
                    (item) => item?.id == selectedWarehouse?.id,
                    orElse: () =>
                        nextWarehouses.isNotEmpty ? nextWarehouses.first : null,
                  ));

      if (selected != null) {
        selectWarehouse(selected, notify: false);
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
    filteredWarehouses = filterWarehouses(warehouses);
    update();
  }

  List<WarehouseModel> filterWarehouses(List<WarehouseModel> items) {
    final scoped = items
        .where((warehouse) {
          if (fixedCompanyId != null && warehouse.companyId != fixedCompanyId) {
            return false;
          }
          if (fixedBranchId != null && warehouse.branchId != fixedBranchId) {
            return false;
          }
          return true;
        })
        .toList(growable: false);

    return filterMasterList(scoped, searchController.text, (warehouse) {
      return [warehouse.code ?? '', warehouse.name ?? ''];
    });
  }

  void selectWarehouse(WarehouseModel warehouse, {bool notify = true}) {
    selectedWarehouse = warehouse;
    showDraftTile = false;
    companyId = fixedCompanyId ?? warehouse.companyId;
    branchId = fixedBranchId ?? warehouse.branchId;
    locationId = warehouse.locationId;
    parentWarehouseId = warehouse.parentWarehouseId;
    _setCode(warehouse.code ?? '');
    nameController.text = warehouse.name ?? '';
    warehouseType = warehouse.warehouseType ?? 'main';
    allowNegativeStock = warehouse.allowNegativeStock;
    isSellableStock = warehouse.isSellableStock;
    isReservedOnly = warehouse.isReservedOnly;
    isDefault = warehouse.isDefault;
    isActive = warehouse.isActive;
    remarksController.text = warehouse.remarks ?? '';
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedWarehouse = null;
    companyId =
        fixedCompanyId ?? (companies.isNotEmpty ? companies.first.id : null);
    final scopedBranches = branchesForCompany(branches, companyId)
        .where((branch) => fixedBranchId == null || branch.id == fixedBranchId)
        .toList(growable: false);
    branchId =
        fixedBranchId ??
        (scopedBranches.isNotEmpty ? scopedBranches.first.id : null);
    final scopedLocations = locationsForBranch(locations, branchId);
    locationId = scopedLocations.isNotEmpty ? scopedLocations.first.id : null;
    parentWarehouseId = null;
    _setCode('');
    nameController.clear();
    warehouseType = 'main';
    allowNegativeStock = false;
    isSellableStock = true;
    isReservedOnly = false;
    isDefault = false;
    isActive = true;
    remarksController.clear();
    formError = null;
    unawaited(_primeCodeSuggestion());
    if (notify) {
      update();
    }
  }

  bool get isNewWarehouse => selectedWarehouse?.id == null;

  void _setCode(String value) {
    codeController.value = codeController.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _primeCodeSuggestion() async {
    if (!isNewWarehouse || locationId == null) {
      return;
    }

    final nextLocationId = locationId!;
    final nextWarehouseType = warehouseType;
    try {
      final code = await _masterService.nextWarehouseCode(
        locationId: nextLocationId,
        warehouseType: nextWarehouseType,
      );
      if (!isNewWarehouse ||
          locationId != nextLocationId ||
          warehouseType != nextWarehouseType) {
        return;
      }
      if (code != null && code.trim().isNotEmpty) {
        _setCode(code.trim());
        update();
      }
    } catch (_) {}
  }

  void refreshAutoGeneratedCode() {
    if (!isNewWarehouse) {
      return;
    }
    _setCode('');
    unawaited(_primeCodeSuggestion());
    update();
  }

  List<BranchModel> get scopedBranches =>
      branchesForCompany(branches, fixedCompanyId ?? companyId)
          .where((branch) {
            return fixedBranchId == null || branch.id == fixedBranchId;
          })
          .toList(growable: false);

  List<BusinessLocationModel> get scopedLocations =>
      locationsForBranch(locations, branchId);

  List<WarehouseModel> get parentOptions => warehouses
      .where(
        (item) =>
            item.locationId == locationId && item.id != selectedWarehouse?.id,
      )
      .toList(growable: false);

  void setCompanyId(int? value) {
    companyId = value;
    final nextBranches = branchesForCompany(branches, value)
        .where((branch) => fixedBranchId == null || branch.id == fixedBranchId)
        .toList(growable: false);
    branchId = nextBranches.isNotEmpty ? nextBranches.first.id : null;
    final nextLocations = locationsForBranch(locations, branchId);
    locationId = nextLocations.isNotEmpty ? nextLocations.first.id : null;
    parentWarehouseId = null;
    update();
    refreshAutoGeneratedCode();
  }

  void setBranchId(int? value) {
    branchId = value;
    final nextLocations = locationsForBranch(locations, value);
    locationId = nextLocations.isNotEmpty ? nextLocations.first.id : null;
    parentWarehouseId = null;
    update();
    refreshAutoGeneratedCode();
  }

  void setLocationId(int? value) {
    locationId = value;
    parentWarehouseId = null;
    update();
    refreshAutoGeneratedCode();
  }

  void setWarehouseType(String? value) {
    warehouseType = value ?? warehouseType;
    update();
    refreshAutoGeneratedCode();
  }

  void setParentWarehouseId(int? value) {
    parentWarehouseId = value;
    update();
  }

  void setAllowNegativeStock(bool value) {
    allowNegativeStock = value;
    update();
  }

  void setIsSellableStock(bool value) {
    isSellableStock = value;
    update();
  }

  void setIsReservedOnly(bool value) {
    isReservedOnly = value;
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

    final model = WarehouseModel(
      id: selectedWarehouse?.id,
      companyId: companyId,
      branchId: branchId,
      locationId: locationId,
      code: codeController.text.trim(),
      name: nameController.text.trim(),
      warehouseType: warehouseType,
      parentWarehouseId: parentWarehouseId,
      allowNegativeStock: allowNegativeStock,
      isSellableStock: isSellableStock,
      isReservedOnly: isReservedOnly,
      isDefault: isDefault,
      isActive: isActive,
      remarks: nullIfEmpty(remarksController.text),
    );

    try {
      final response = selectedWarehouse == null
          ? await _masterService.createWarehouse(model)
          : await _masterService.updateWarehouse(selectedWarehouse!.id!, model);
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

  void startNewWarehouse({required bool isDesktop}) {
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
