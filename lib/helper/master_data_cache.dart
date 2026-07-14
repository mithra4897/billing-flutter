import '../screen.dart';

typedef _PaginatedLoader<T> =
    Future<PaginatedResponse<T>> Function({Map<String, dynamic>? filters});

class MasterDataCache extends GetxController {
  MasterDataCache._();

  static MasterDataCache get to => Get.find<MasterDataCache>();

  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final InventoryService _inventoryService = InventoryService();
  final AccountsService _accountsService = AccountsService();
  final TaxesService _taxesService = TaxesService();

  Future<void>? _loadFuture;
  int _generation = 0;
  Future<void>? _settingsFuture;

  bool isLoaded = false;
  bool isEnabled = true;
  bool settingsLoaded = false;
  Object? lastError;
  DateTime? lastLoadedAt;

  List<CompanyModel> companies = const <CompanyModel>[];
  List<BranchModel> branches = const <BranchModel>[];
  List<BusinessLocationModel> locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  List<PartyModel> parties = const <PartyModel>[];
  List<PartyTypeModel> partyTypes = const <PartyTypeModel>[];
  List<ItemModel> items = const <ItemModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<UomConversionModel> uomConversions = const <UomConversionModel>[];
  List<TaxCodeModel> taxCodes = const <TaxCodeModel>[];
  List<AccountModel> accounts = const <AccountModel>[];
  List<GstRegistrationModel> gstRegistrations = const <GstRegistrationModel>[];

  List<CompanyModel> get activeCompanies => _active(companies);
  List<BranchModel> get activeBranches => _active(branches);
  List<BusinessLocationModel> get activeLocations => _active(locations);
  List<FinancialYearModel> get activeFinancialYears => _active(financialYears);
  List<DocumentSeriesModel> get activeDocumentSeries => _active(documentSeries);
  List<WarehouseModel> get activeWarehouses => _active(warehouses);
  List<PartyModel> get activeParties => _active(parties);
  List<PartyTypeModel> get activePartyTypes => _active(partyTypes);
  List<ItemModel> get activeItems => _active(items);
  List<UomModel> get activeUoms => _active(uoms);
  List<UomConversionModel> get activeUomConversions => _active(uomConversions);
  List<TaxCodeModel> get activeTaxCodes => _active(taxCodes);
  List<AccountModel> get activeAccounts => _active(accounts);
  List<GstRegistrationModel> get activeGstRegistrations =>
      _active(gstRegistrations);

  int get totalRecordCount =>
      companies.length +
      branches.length +
      locations.length +
      financialYears.length +
      documentSeries.length +
      warehouses.length +
      parties.length +
      partyTypes.length +
      items.length +
      uoms.length +
      uomConversions.length +
      taxCodes.length +
      accounts.length +
      gstRegistrations.length;

  Map<String, int> get datasetCounts => <String, int>{
    'Companies': companies.length,
    'Branches': branches.length,
    'Locations': locations.length,
    'Financial Years': financialYears.length,
    'Document Series': documentSeries.length,
    'Warehouses': warehouses.length,
    'Parties': parties.length,
    'Party Types': partyTypes.length,
    'Items': items.length,
    'UOMs': uoms.length,
    'UOM Conversions': uomConversions.length,
    'Tax Codes': taxCodes.length,
    'Accounts': accounts.length,
    'GST Registrations': gstRegistrations.length,
  };

  Future<void> ensureLoaded({bool forceRefresh = false}) async {
    await ensureSettingsLoaded();
    if (isEnabled && isLoaded && !forceRefresh) {
      return;
    }
    if (forceRefresh) {
      _loadFuture = null;
      isLoaded = false;
    }
    if (!isEnabled) {
      _loadFuture = null;
      isLoaded = false;
    }
    return _loadFuture ??= _loadImpl();
  }

  Future<void> ensureSettingsLoaded() {
    return _settingsFuture ??= _loadSettings();
  }

  Future<void> _loadSettings() async {
    isEnabled = await SessionStorage.isMasterDataCacheEnabled();
    settingsLoaded = true;
    update();
  }

  Future<void> setEnabled(bool value) async {
    await SessionStorage.setMasterDataCacheEnabled(value);
    isEnabled = value;
    settingsLoaded = true;
    if (!value) {
      clearAllCaches(notify: false);
    } else {
      invalidate();
    }
    update();
  }

  void clearAllCaches({bool notify = true}) {
    invalidate(notify: false);
    ApiCacheStore.clear();
    if (notify) {
      update();
    }
  }

  Future<void> _loadImpl() async {
    final generation = _generation;
    lastError = null;
    update();

    try {
      final responses = await Future.wait<dynamic>([
        _loadCompanies(),
        _loadBranches(),
        _loadLocations(),
        _loadFinancialYears(),
        _loadDocumentSeries(),
        _loadWarehouses(),
        _loadParties(),
        _loadPartyTypes(),
        _loadItems(),
        _loadUoms(),
        _loadUomConversions(),
        _loadTaxCodes(),
        _loadAccounts(),
        _loadGstRegistrations(),
      ]);

      if (generation != _generation) {
        return;
      }

      companies = responses[0] as List<CompanyModel>;
      branches = responses[1] as List<BranchModel>;
      locations = responses[2] as List<BusinessLocationModel>;
      financialYears = responses[3] as List<FinancialYearModel>;
      documentSeries = responses[4] as List<DocumentSeriesModel>;
      warehouses = responses[5] as List<WarehouseModel>;
      parties = responses[6] as List<PartyModel>;
      partyTypes = responses[7] as List<PartyTypeModel>;
      items = responses[8] as List<ItemModel>;
      uoms = responses[9] as List<UomModel>;
      uomConversions = responses[10] as List<UomConversionModel>;
      taxCodes = responses[11] as List<TaxCodeModel>;
      accounts = responses[12] as List<AccountModel>;
      gstRegistrations = responses[13] as List<GstRegistrationModel>;
      isLoaded = true;
      lastLoadedAt = DateTime.now();
      update();
    } catch (error) {
      if (generation == _generation) {
        isLoaded = false;
        lastError = error;
        update();
      }
      rethrow;
    } finally {
      if (generation == _generation) {
        _loadFuture = null;
      }
    }
  }

  Future<void> refreshCompanies() async {
    companies = await _loadCompanies();
    _markRefreshed();
  }

  Future<void> refreshBranches() async {
    branches = await _loadBranches();
    _markRefreshed();
  }

  Future<void> refreshLocations() async {
    locations = await _loadLocations();
    _markRefreshed();
  }

  Future<void> refreshFinancialYears() async {
    financialYears = await _loadFinancialYears();
    _markRefreshed();
  }

  Future<void> refreshDocumentSeries() async {
    documentSeries = await _loadDocumentSeries();
    _markRefreshed();
  }

  Future<void> refreshWarehouses() async {
    warehouses = await _loadWarehouses();
    _markRefreshed();
  }

  Future<void> refreshParties() async {
    parties = await _loadParties();
    _markRefreshed();
  }

  Future<void> refreshPartyTypes() async {
    partyTypes = await _loadPartyTypes();
    _markRefreshed();
  }

  Future<void> refreshItems() async {
    items = await _loadItems();
    _markRefreshed();
  }

  Future<void> refreshUoms() async {
    uoms = await _loadUoms();
    _markRefreshed();
  }

  Future<void> refreshUomConversions() async {
    uomConversions = await _loadUomConversions();
    _markRefreshed();
  }

  Future<void> refreshTaxCodes() async {
    taxCodes = await _loadTaxCodes();
    _markRefreshed();
  }

  Future<void> refreshAccounts() async {
    accounts = await _loadAccounts();
    _markRefreshed();
  }

  Future<void> refreshGstRegistrations() async {
    gstRegistrations = await _loadGstRegistrations();
    _markRefreshed();
  }
  Future<void> refreshForMutationPath(String path) async {
    if (!isEnabled) {
      return;
    }
    if (!isLoaded) {
      if (_loadFuture != null) {
        invalidate();
      }
      return;
    }

    if (path.startsWith('/masters/companies')) {
      await Future.wait<void>([
        refreshCompanies(),
        refreshBranches(),
        refreshLocations(),
        refreshWarehouses(),
      ]);
      return;
    }
    if (path.startsWith('/masters/branches')) {
      await Future.wait<void>([
        refreshBranches(),
        refreshLocations(),
        refreshWarehouses(),
      ]);
      return;
    }
    if (path.startsWith('/masters/business-locations')) {
      await Future.wait<void>([refreshLocations(), refreshWarehouses()]);
      return;
    }
    if (path.startsWith('/masters/warehouses')) {
      await refreshWarehouses();
      return;
    }
    if (path.startsWith('/masters/financial-years')) {
      await refreshFinancialYears();
      return;
    }
    if (path.startsWith('/masters/document-series')) {
      await refreshDocumentSeries();
      return;
    }
    if (path.startsWith('/masters/party-types')) {
      await refreshPartyTypes();
      return;
    }
    if (path.startsWith('/masters/parties')) {
      await refreshParties();
      return;
    }
    if (path.startsWith(ApiEndpoints.uomConversions)) {
      await refreshUomConversions();
      return;
    }
    if (path.startsWith(ApiEndpoints.uoms)) {
      await Future.wait<void>([refreshUoms(), refreshUomConversions()]);
      return;
    }
    if (path.startsWith(ApiEndpoints.taxCodes)) {
      await refreshTaxCodes();
      return;
    }
    if (path.startsWith(ApiEndpoints.items)) {
      await refreshItems();
      return;
    }
    if (path.startsWith(ApiEndpoints.accounts)) {
      await refreshAccounts();
      return;
    }
    if (path.startsWith('/tax/gst-registrations')) {
      await refreshGstRegistrations();
    }
  }

  void invalidate({bool notify = true}) {
    _generation++;
    _loadFuture = null;
    isLoaded = false;
    lastError = null;
    lastLoadedAt = null;
    companies = const <CompanyModel>[];
    branches = const <BranchModel>[];
    locations = const <BusinessLocationModel>[];
    financialYears = const <FinancialYearModel>[];
    documentSeries = const <DocumentSeriesModel>[];
    warehouses = const <WarehouseModel>[];
    parties = const <PartyModel>[];
    partyTypes = const <PartyTypeModel>[];
    items = const <ItemModel>[];
    uoms = const <UomModel>[];
    uomConversions = const <UomConversionModel>[];
    taxCodes = const <TaxCodeModel>[];
    accounts = const <AccountModel>[];
    gstRegistrations = const <GstRegistrationModel>[];
    if (notify) {
      update();
    }
  }

  void _markRefreshed() {
    isLoaded = true;
    lastError = null;
    lastLoadedAt = DateTime.now();
    update();
  }

  Future<List<CompanyModel>> _loadCompanies() {
    return _loadAllPages<CompanyModel>(
      baseFilters: const <String, dynamic>{
        'per_page': 200,
        'sort_by': 'legal_name',
      },
      loader: _masterService.companies,
    );
  }

  Future<List<BranchModel>> _loadBranches() {
    return _loadAllPages<BranchModel>(
      baseFilters: const <String, dynamic>{'per_page': 300, 'sort_by': 'name'},
      loader: _masterService.branches,
    );
  }

  Future<List<BusinessLocationModel>> _loadLocations() {
    return _loadAllPages<BusinessLocationModel>(
      baseFilters: const <String, dynamic>{'per_page': 300, 'sort_by': 'name'},
      loader: _masterService.businessLocations,
    );
  }

  Future<List<FinancialYearModel>> _loadFinancialYears() {
    return _loadAllPages<FinancialYearModel>(
      baseFilters: const <String, dynamic>{
        'per_page': 300,
        'sort_by': 'fy_name',
      },
      loader: _masterService.financialYears,
    );
  }

  Future<List<DocumentSeriesModel>> _loadDocumentSeries() {
    return _loadAllPages<DocumentSeriesModel>(
      baseFilters: const <String, dynamic>{
        'per_page': 300,
        'sort_by': 'series_name',
      },
      loader: _masterService.documentSeries,
    );
  }

  Future<List<WarehouseModel>> _loadWarehouses() {
    return _loadAllPages<WarehouseModel>(
      baseFilters: const <String, dynamic>{'per_page': 300, 'sort_by': 'name'},
      loader: _masterService.warehouses,
    );
  }

  Future<List<PartyModel>> _loadParties() {
    return _loadAllPages<PartyModel>(
      baseFilters: const <String, dynamic>{
        'per_page': 500,
        'sort_by': 'party_name',
      },
      loader: _partiesService.parties,
    );
  }

  Future<List<PartyTypeModel>> _loadPartyTypes() {
    return _loadAllPages<PartyTypeModel>(
      baseFilters: const <String, dynamic>{'per_page': 100},
      loader: _partiesService.partyTypes,
    );
  }

  Future<List<ItemModel>> _loadItems() {
    return _loadAllPages<ItemModel>(
      baseFilters: const <String, dynamic>{
        'per_page': 500,
        'sort_by': 'item_name',
      },
      loader: _inventoryService.items,
    );
  }

  Future<List<UomModel>> _loadUoms() {
    return _loadAllPages<UomModel>(
      baseFilters: const <String, dynamic>{'per_page': 200, 'sort_by': 'name'},
      loader: _inventoryService.uoms,
    );
  }

  Future<List<UomConversionModel>> _loadUomConversions() {
    return _loadAllPages<UomConversionModel>(
      baseFilters: const <String, dynamic>{
        'per_page': 500,
        'sort_by': 'from_uom_id',
      },
      loader: _inventoryService.uomConversionsAll,
    );
  }

  Future<List<TaxCodeModel>> _loadTaxCodes() {
    return _loadAllPages<TaxCodeModel>(
      baseFilters: const <String, dynamic>{'per_page': 200, 'sort_by': 'name'},
      loader: _inventoryService.taxCodes,
    );
  }

  Future<List<AccountModel>> _loadAccounts() async {
    final response = await _accountsService.accountsAll(
      filters: const <String, dynamic>{'sort_by': 'account_name'},
    );
    return List<AccountModel>.unmodifiable(
      response.data ?? const <AccountModel>[],
    );
  }

  Future<List<GstRegistrationModel>> _loadGstRegistrations() async {
    final response = await _taxesService.gstRegistrationsAll(
      filters: const <String, dynamic>{'is_active': 1, 'sort_by': 'id'},
    );
    return List<GstRegistrationModel>.unmodifiable(
      response.data ?? const <GstRegistrationModel>[],
    );
  }

  Future<List<T>> _loadAllPages<T>({
    required Map<String, dynamic> baseFilters,
    required _PaginatedLoader<T> loader,
  }) async {
    final items = <T>[];
    var page = 1;

    while (true) {
      final filters = <String, dynamic>{...baseFilters, 'page': page};
      final response = await loader(filters: filters);
      items.addAll(response.data ?? <T>[]);

      final lastPage = response.meta?.lastPage ?? 1;
      if (page >= lastPage || lastPage <= 1) {
        break;
      }
      page++;
    }

    return List<T>.unmodifiable(items);
  }

  static List<T> _active<T>(List<T> items) {
    return items.where((item) => _isActive(item)).toList(growable: false);
  }

  static bool _isActive(Object? value) {
    if (value == null) {
      return false;
    }
    final dynamic dynamicValue = value;
    final active = dynamicValue.isActive;
    return active == true;
  }

  static MasterDataCache ensureRegistered() {
    if (!Get.isRegistered<MasterDataCache>()) {
      Get.put<MasterDataCache>(MasterDataCache._(), permanent: true);
    }
    return Get.find<MasterDataCache>();
  }
}
