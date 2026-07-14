import '../../../screen.dart';

class CacheControlsManagementController extends GetxController {
  CacheControlsManagementController();

  final AdminService _adminService = AdminService();
  final ScrollController pageScrollController = ScrollController();

  bool initialLoading = true;
  bool cacheToggleSaving = false;
  bool masterCacheClearing = false;
  bool apiCacheClearing = false;
  bool allCacheClearing = false;
  bool warmingCache = false;
  bool serverLoading = false;
  bool serverFlushing = false;
  bool serverWarming = false;
  String? error;
  bool cacheEnabled = true;
  DateTime? cacheLastLoadedAt;
  DateTime? apiCacheLastStoredAt;
  bool masterCacheLoaded = false;
  int masterCacheRecordCount = 0;
  int apiCacheEntryCount = 0;
  int apiCacheEtagCount = 0;
  int apiCacheBodyCharacters = 0;
  int apiCacheHits = 0;
  int apiCacheMisses = 0;
  int apiCacheEvictions = 0;
  List<MapEntry<String, int>> masterDatasetCounts = const [];
  List<MapEntry<String, int>> apiFamilyCounts = const [];
  String serverCacheDriver = 'unknown';
  List<Map<String, dynamic>> serverCacheGroups = const [];

  @override
  void onInit() {
    super.onInit();
    loadCacheSettings();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    super.onClose();
  }

  Future<void> loadCacheSettings() async {
    initialLoading = true;
    error = null;
    update();
    try {
      final cache = MasterDataCache.ensureRegistered();
      await cache.ensureSettingsLoaded();
      cacheEnabled = cache.isEnabled;
      cacheLastLoadedAt = cache.lastLoadedAt;
      masterCacheLoaded = cache.isLoaded;
      masterCacheRecordCount = cache.totalRecordCount;
      masterDatasetCounts = cache.datasetCounts.entries.toList(growable: false);
      apiCacheEntryCount = ApiCacheStore.entryCount;
      apiCacheEtagCount = ApiCacheStore.etagEntryCount;
      final apiDiagnostics = ApiCacheStore.diagnostics;
      apiCacheBodyCharacters = apiDiagnostics.bodyCharacters;
      apiCacheHits = apiDiagnostics.hits;
      apiCacheMisses = apiDiagnostics.misses;
      apiCacheEvictions = apiDiagnostics.evictions;
      apiCacheLastStoredAt = ApiCacheStore.lastStoredAt;
      apiFamilyCounts = ApiCacheStore.familyCounts().entries.toList(
        growable: false,
      );
      await loadServerCacheStatus(notify: false);
    } catch (err) {
      error = err.toString();
    } finally {
      initialLoading = false;
      update();
    }
  }

  Future<void> setCacheEnabled(bool value) async {
    if (cacheToggleSaving) {
      return;
    }
    cacheToggleSaving = true;
    error = null;
    update();
    try {
      final cache = MasterDataCache.ensureRegistered();
      await cache.setEnabled(value);
      cacheEnabled = cache.isEnabled;
      cacheLastLoadedAt = cache.lastLoadedAt;
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Master data cache enabled.'
                : 'Master data cache disabled and cleared.',
          ),
        ),
      );
      await loadCacheSettings();
    } catch (err) {
      error = err.toString();
    } finally {
      cacheToggleSaving = false;
      update();
    }
  }

  Future<void> loadServerCacheStatus({bool notify = true}) async {
    serverLoading = true;
    if (notify) {
      update();
    }
    try {
      final response = await _adminService.cacheStatus();
      final data = response.data;
      if (data is Map<String, dynamic>) {
        serverCacheDriver = data['driver']?.toString() ?? 'unknown';
        final groups = data['groups'];
        if (groups is Map<String, dynamic>) {
          serverCacheGroups = groups.entries
              .map((entry) {
                final value = entry.value;
                if (value is Map<String, dynamic>) {
                  return <String, dynamic>{'key': entry.key, ...value};
                }
                return <String, dynamic>{'key': entry.key};
              })
              .toList(growable: false);
        } else {
          serverCacheGroups = const [];
        }
      }
    } catch (err) {
      error = err.toString();
    } finally {
      serverLoading = false;
      if (notify) {
        update();
      }
    }
  }

  Future<void> flushServerGroup(String group) async {
    if (serverFlushing) {
      return;
    }
    serverFlushing = true;
    error = null;
    update();
    try {
      final response = await _adminService.flushCacheGroup(group);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadServerCacheStatus(notify: false);
    } catch (err) {
      error = err.toString();
    } finally {
      serverFlushing = false;
      update();
    }
  }

  Future<void> flushAllServerCaches() async {
    if (serverFlushing) {
      return;
    }
    serverFlushing = true;
    error = null;
    update();
    try {
      final response = await _adminService.flushAllCaches();
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadServerCacheStatus(notify: false);
    } catch (err) {
      error = err.toString();
    } finally {
      serverFlushing = false;
      update();
    }
  }

  Future<void> warmAllServerCaches() async {
    if (serverWarming) {
      return;
    }
    serverWarming = true;
    error = null;
    update();
    try {
      final response = await _adminService.warmAllCaches();
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadServerCacheStatus(notify: false);
    } catch (err) {
      error = err.toString();
    } finally {
      serverWarming = false;
      update();
    }
  }

  Future<void> warmMasterCache() async {
    if (warmingCache) {
      return;
    }
    warmingCache = true;
    error = null;
    update();
    try {
      final cache = MasterDataCache.ensureRegistered();
      await cache.ensureLoaded(forceRefresh: true);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Master data cache warmed successfully.')),
      );
      await loadCacheSettings();
    } catch (err) {
      error = err.toString();
    } finally {
      warmingCache = false;
      update();
    }
  }

  Future<void> clearMasterCache() async {
    if (masterCacheClearing) {
      return;
    }
    masterCacheClearing = true;
    error = null;
    update();
    try {
      final cache = MasterDataCache.ensureRegistered();
      cache.invalidate();
      appScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Master data cache cleared.')),
      );
      await loadCacheSettings();
    } catch (err) {
      error = err.toString();
    } finally {
      masterCacheClearing = false;
      update();
    }
  }

  Future<void> clearApiCache() async {
    if (apiCacheClearing) {
      return;
    }
    apiCacheClearing = true;
    error = null;
    update();
    try {
      ApiCacheStore.clear();
      appScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('HTTP API cache cleared.')),
      );
      await loadCacheSettings();
    } catch (err) {
      error = err.toString();
    } finally {
      apiCacheClearing = false;
      update();
    }
  }

  Future<void> clearAllCaches() async {
    if (allCacheClearing) {
      return;
    }
    allCacheClearing = true;
    error = null;
    update();
    try {
      final cache = MasterDataCache.ensureRegistered();
      cache.clearAllCaches();
      appScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('All client-side caches cleared.')),
      );
      await loadCacheSettings();
    } catch (err) {
      error = err.toString();
    } finally {
      allCacheClearing = false;
      update();
    }
  }

  String get cacheLastLoadedLabel {
    final value = cacheLastLoadedAt;
    if (value == null) {
      return 'Not loaded yet';
    }
    return value.toLocal().toString().split('.').first;
  }

  String get apiCacheLastStoredLabel {
    final value = apiCacheLastStoredAt;
    if (value == null) {
      return 'No cached HTTP responses yet';
    }
    return value.toLocal().toString().split('.').first;
  }

  String formatTimestamp(dynamic value, {String fallback = 'Never'}) {
    if (value == null) {
      return fallback;
    }
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) {
      return value.toString();
    }
    return parsed.toLocal().toString().split('.').first;
  }

  String serverGroupTitle(String group) {
    switch (group) {
      case 'auth_permissions':
        return 'Permissions Cache';
      case 'access_scopes':
        return 'Access Scope Cache';
      case 'user_context':
        return 'User Context Cache';
      default:
        return group.replaceAll('_', ' ').trim();
    }
  }

  String serverGroupDescription(String group) {
    switch (group) {
      case 'auth_permissions':
        return 'Stores resolved user permissions so access checks do not need to rebuild the same permission matrix on every request.';
      case 'access_scopes':
        return 'Stores the allowed companies, branches, locations, and warehouses for each user.';
      case 'user_context':
        return 'Stores the current user context used to build menu visibility, working context defaults, and shell data.';
      default:
        return 'Server-side cache group';
    }
  }

  String serverGroupStatusLine(Map<String, dynamic> group) {
    final hits = _asInt(group['hits']);
    final misses = _asInt(group['misses']);
    final total = hits + misses;
    final reuseRate = total == 0 ? 0 : ((hits / total) * 100).round();
    return '$hits reused • $misses rebuilt • $reuseRate% reuse';
  }

  int _asInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

  String get apiCacheReuseLabel {
    final total = apiCacheHits + apiCacheMisses;
    final rate = total == 0 ? 0 : ((apiCacheHits / total) * 100).round();
    return '$rate% (${apiCacheHits.toString()} reused)';
  }

  String get apiCacheStorageLabel {
    final kilobytes = apiCacheBodyCharacters / 1024;
    return '${kilobytes.toStringAsFixed(kilobytes >= 10 ? 0 : 1)} KB of 8 MB • $apiCacheEvictions removed';
  }

  String masterCacheStatusLabel() {
    if (!cacheEnabled) {
      return 'Disabled';
    }
    return masterCacheLoaded ? 'Ready' : 'Waiting';
  }

  String masterCacheStatusDetail() {
    if (!cacheEnabled) {
      return 'Pages will reload master data from the API';
    }
    if (masterCacheLoaded) {
      return '$masterCacheRecordCount reference records are loaded';
    }
    return 'Shared reference data has not been warmed yet';
  }

  String apiCacheStatusLabel() {
    if (apiCacheEntryCount <= 0) {
      return 'Empty';
    }
    return '$apiCacheEntryCount saved';
  }

  String apiCacheStatusDetail() {
    if (apiCacheEntryCount <= 0) {
      return 'No cached HTTP responses are stored';
    }
    return '$apiCacheEtagCount entries support ETag revalidation';
  }

  String readableEndpointFamily(String value) {
    switch (value) {
      case '/masters/companies':
        return 'Companies';
      case '/masters/branches':
        return 'Branches';
      case '/masters/business-locations':
        return 'Business Locations';
      case '/masters/warehouses':
        return 'Warehouses';
      case '/masters/financial-years':
        return 'Financial Years';
      case '/masters/document-series':
        return 'Document Series';
      case '/masters/party-types':
        return 'Party Types';
      case '/inventory/uoms':
        return 'UOMs';
      case '/inventory/tax-codes':
        return 'Tax Codes';
      default:
        return value.replaceAll('/', ' / ').trim();
    }
  }
}
