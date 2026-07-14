import '../../screen.dart';

class WorkingContextSelection {
  const WorkingContextSelection({
    required this.companyId,
    required this.branchId,
    required this.locationId,
    required this.financialYearId,
    this.warehouseId,
  });

  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final int? warehouseId;
}

class WorkingContextSnapshot {
  const WorkingContextSnapshot({
    required this.selection,
    required this.companies,
    required this.branches,
    required this.locations,
    required this.warehouses,
    required this.financialYears,
  });

  final WorkingContextSelection selection;
  final List<CompanyModel> companies;
  final List<BranchModel> branches;
  final List<BusinessLocationModel> locations;
  final List<WarehouseModel> warehouses;
  final List<FinancialYearModel> financialYears;
}

class WorkingContextService {
  WorkingContextService._();

  static final WorkingContextService instance = WorkingContextService._();
  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  final MasterService _masterService = MasterService();

  Future<WorkingContextSnapshot> loadSnapshot() async {
    List<CompanyModel> companies;
    List<BranchModel> branches;
    List<BusinessLocationModel> locations;
    List<WarehouseModel> warehouses;
    List<FinancialYearModel> financialYears;

    try {
      await MasterDataCache.to.ensureLoaded();
      companies = MasterDataCache.to.activeCompanies;
      branches = MasterDataCache.to.activeBranches;
      locations = MasterDataCache.to.activeLocations;
      warehouses = await filterWarehousesByAccess(
        MasterDataCache.to.activeWarehouses,
      );
      financialYears = MasterDataCache.to.activeFinancialYears;
    } catch (_) {
      final responses = await Future.wait<dynamic>([
        _masterService.companies(
          filters: const {'per_page': 200, 'sort_by': 'legal_name'},
        ),
        _masterService.branches(
          filters: const {'per_page': 300, 'sort_by': 'name'},
        ),
        _masterService.businessLocations(
          filters: const {'per_page': 300, 'sort_by': 'name'},
        ),
        _masterService.warehouses(
          filters: const {'per_page': 500, 'sort_by': 'name'},
        ),
        _masterService.financialYears(
          filters: const {'per_page': 300, 'sort_by': 'fy_name'},
        ),
      ]);

      companies = responses[0].data
          .whereType<CompanyModel>()
          .where((CompanyModel item) => item.isActive)
          .toList(growable: false);
      branches = responses[1].data
          .whereType<BranchModel>()
          .where((BranchModel item) => item.isActive)
          .toList(growable: false);
      locations = responses[2].data
          .whereType<BusinessLocationModel>()
          .where((BusinessLocationModel item) => item.isActive)
          .toList(growable: false);
      warehouses = await filterWarehousesByAccess(
        responses[3].data
            .whereType<WarehouseModel>()
            .where((WarehouseModel item) => item.isActive)
            .toList(growable: false),
      );
      financialYears = responses[4].data
          .whereType<FinancialYearModel>()
          .where((FinancialYearModel item) => item.isActive)
          .toList(growable: false);
    }

    final selection = await resolveSelection(
      companies: companies,
      branches: branches,
      locations: locations,
      warehouses: warehouses,
      financialYears: financialYears,
    );

    return WorkingContextSnapshot(
      selection: selection,
      companies: companies,
      branches: branches,
      locations: locations,
      warehouses: warehouses,
      financialYears: financialYears,
    );
  }

  Future<WorkingContextSelection> resolveSelection({
    required List<CompanyModel> companies,
    required List<BranchModel> branches,
    required List<BusinessLocationModel> locations,
    List<WarehouseModel>? warehouses,
    required List<FinancialYearModel> financialYears,
    int? companyId,
    int? branchId,
    int? locationId,
    int? warehouseId,
    int? financialYearId,
    bool persist = true,
  }) async {
    final storedCompanyId =
        companyId ?? await SessionStorage.getCurrentCompanyId();
    final storedBranchId =
        branchId ?? await SessionStorage.getCurrentBranchId();
    final storedLocationId =
        locationId ?? await SessionStorage.getCurrentLocationId();
    final storedWarehouseId =
        warehouseId ?? await SessionStorage.getCurrentWarehouseId();
    final storedFinancialYearId =
        financialYearId ?? await SessionStorage.getCurrentFinancialYearId();
    final availableWarehouses =
        warehouses ??
        (await SessionStorage.getAuthContext())?.warehouses ??
        const <WarehouseModel>[];

    final resolvedCompanyId = _resolveCompanyId(companies, storedCompanyId);
    final scopedBranches = branches
        .where(
          (BranchModel item) =>
              resolvedCompanyId == null || item.companyId == resolvedCompanyId,
        )
        .toList(growable: false);
    final resolvedBranchId = _resolveBranchId(
      scopedBranches,
      storedBranchId,
      forceSingleOption: resolvedCompanyId != null,
    );
    final scopedLocations = locations
        .where(
          (BusinessLocationModel item) => _locationMatchesScope(
            item,
            companyId: resolvedCompanyId,
            branchId: resolvedBranchId,
          ),
        )
        .toList(growable: false);
    final resolvedLocationId = _resolveLocationId(
      scopedLocations,
      storedLocationId,
      forceSingleOption: resolvedBranchId != null || resolvedCompanyId != null,
    );
    final scopedWarehouses = availableWarehouses
        .where(
          (WarehouseModel item) => _warehouseMatchesScope(
            item,
            companyId: resolvedCompanyId,
            branchId: resolvedBranchId,
            locationId: resolvedLocationId,
          ),
        )
        .toList(growable: false);
    final resolvedWarehouseId = _resolveWarehouseId(
      scopedWarehouses,
      storedWarehouseId,
    );
    final scopedFinancialYears = financialYears
        .where(
          (FinancialYearModel item) =>
              resolvedCompanyId == null || item.companyId == resolvedCompanyId,
        )
        .toList(growable: false);
    final resolvedFinancialYearId = _resolveFinancialYearId(
      scopedFinancialYears,
      storedFinancialYearId,
    );

    if (persist) {
      await SessionStorage.replaceSelectedContext(
        companyId: resolvedCompanyId,
        branchId: resolvedBranchId,
        locationId: resolvedLocationId,
        warehouseId: resolvedWarehouseId,
        financialYearId: resolvedFinancialYearId,
      );
    }

    return WorkingContextSelection(
      companyId: resolvedCompanyId,
      branchId: resolvedBranchId,
      locationId: resolvedLocationId,
      warehouseId: resolvedWarehouseId,
      financialYearId: resolvedFinancialYearId,
    );
  }

  Future<void> saveSelection(WorkingContextSelection selection) async {
    await SessionStorage.replaceSelectedContext(
      companyId: selection.companyId,
      branchId: selection.branchId,
      locationId: selection.locationId,
      warehouseId: selection.warehouseId,
      financialYearId: selection.financialYearId,
    );
    if (Get.isRegistered<MasterDataCache>()) {
      MasterDataCache.to.clearAllCaches();
    } else {
      ApiCacheStore.clear();
    }
    version.value++;
  }

  Future<List<WarehouseModel>> filterWarehousesByAccess(
    List<WarehouseModel> warehouses,
  ) async {
    final authContext = await SessionStorage.getAuthContext();
    final allowedWarehouseIds = authContext?.warehouses
        .where((item) => item.id != null)
        .map((item) => item.id!)
        .toSet();

    if (allowedWarehouseIds == null) {
      return warehouses;
    }

    if (allowedWarehouseIds.isEmpty) {
      return const <WarehouseModel>[];
    }

    return warehouses
        .where((item) => item.id != null)
        .where((item) => allowedWarehouseIds.contains(item.id))
        .toList(growable: false);
  }

  int? _resolveCompanyId(List<CompanyModel> companies, int? preferredId) {
    if (preferredId != null &&
        companies.any((CompanyModel item) => item.id == preferredId)) {
      return preferredId;
    }
    if (companies.isEmpty) {
      return null;
    }
    return companies.first.id;
  }

  int? _resolveBranchId(
    List<BranchModel> branches,
    int? preferredId, {
    bool forceSingleOption = false,
  }) {
    if (forceSingleOption && branches.length == 1) {
      return branches.first.id;
    }
    if (preferredId != null &&
        branches.any((BranchModel item) => item.id == preferredId)) {
      return preferredId;
    }
    if (branches.isEmpty) {
      return null;
    }
    return branches.first.id;
  }

  int? _resolveLocationId(
    List<BusinessLocationModel> locations,
    int? preferredId, {
    bool forceSingleOption = false,
  }) {
    if (forceSingleOption && locations.length == 1) {
      return locations.first.id;
    }
    if (preferredId != null &&
        locations.any((BusinessLocationModel item) => item.id == preferredId)) {
      return preferredId;
    }
    if (locations.isEmpty) {
      return null;
    }
    return locations.first.id;
  }

  int? _resolveFinancialYearId(
    List<FinancialYearModel> financialYears,
    int? preferredId,
  ) {
    if (preferredId != null &&
        financialYears.any(
          (FinancialYearModel item) => item.id == preferredId,
        )) {
      return preferredId;
    }
    final current = financialYears.cast<FinancialYearModel?>().firstWhere(
      (item) => item?.isCurrent == true,
      orElse: () => null,
    );
    if (current?.id != null) {
      return current!.id;
    }
    if (financialYears.isEmpty) {
      return null;
    }
    return financialYears.first.id;
  }

  int? _resolveWarehouseId(List<WarehouseModel> warehouses, int? preferredId) {
    if (preferredId != null &&
        warehouses.any((WarehouseModel item) => item.id == preferredId)) {
      return preferredId;
    }
    if (warehouses.isEmpty) {
      return null;
    }
    return warehouses.first.id;
  }

  bool _locationMatchesScope(
    BusinessLocationModel item, {
    required int? companyId,
    required int? branchId,
  }) {
    if (branchId != null) {
      return item.branchId == branchId;
    }
    if (companyId != null) {
      return item.companyId == companyId;
    }
    return true;
  }

  bool _warehouseMatchesScope(
    WarehouseModel item, {
    required int? companyId,
    required int? branchId,
    required int? locationId,
  }) {
    if (locationId != null) {
      return item.locationId == locationId;
    }
    if (branchId != null) {
      return item.branchId == branchId;
    }
    if (companyId != null) {
      return item.companyId == companyId;
    }
    return true;
  }
}
