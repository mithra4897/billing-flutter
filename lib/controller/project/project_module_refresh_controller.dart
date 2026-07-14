import '../../core/models/paginated_response.dart';
import '../../core/storage/session_storage.dart';
import '../../model/project/project_model.dart';
import 'package:get/get.dart';

typedef ProjectPageLoader =
    Future<PaginatedResponse<ProjectModel>> Function({
      Map<String, dynamic>? filters,
    });

class ProjectModuleRefreshEvent {
  const ProjectModuleRefreshEvent({
    required this.sequence,
    required this.source,
  });

  final int sequence;
  final String source;
}

class ProjectModuleRefreshController extends GetxController {
  static const String tag = 'ProjectModuleRefreshController';

  final Rxn<ProjectModuleRefreshEvent> lastEvent =
      Rxn<ProjectModuleRefreshEvent>();
  int _sequence = 0;
  List<ProjectModel>? _projects;
  Future<List<ProjectModel>>? _projectsFuture;
  String? _scopeKey;
  int _cacheGeneration = 0;

  Future<List<ProjectModel>> projects({
    required ProjectPageLoader loader,
    bool forceRefresh = false,
  }) async {
    final scopeKey = await _currentScopeKey();
    if (_scopeKey != scopeKey) {
      invalidateProjects();
      _scopeKey = scopeKey;
    }
    if (forceRefresh) {
      invalidateProjects();
      _scopeKey = scopeKey;
    }

    final cached = _projects;
    if (cached != null) {
      return cached;
    }

    return _projectsFuture ??= _loadAllProjects(loader, _cacheGeneration);
  }

  void invalidateProjects() {
    _cacheGeneration++;
    _projects = null;
    _projectsFuture = null;
  }

  static void invalidateRegisteredCache() {
    if (Get.isRegistered<ProjectModuleRefreshController>(tag: tag)) {
      Get.find<ProjectModuleRefreshController>(tag: tag).invalidateProjects();
    }
  }

  void notifyChanged({required String source}) {
    lastEvent.value = ProjectModuleRefreshEvent(
      sequence: ++_sequence,
      source: source,
    );
  }

  Future<List<ProjectModel>> _loadAllProjects(
    ProjectPageLoader loader,
    int generation,
  ) async {
    try {
      final items = <ProjectModel>[];
      var page = 1;

      while (true) {
        final response = await loader(
          filters: <String, dynamic>{
            'per_page': 200,
            'sort_by': 'project_name',
            'page': page,
          },
        );
        items.addAll(response.data ?? const <ProjectModel>[]);

        final lastPage = response.meta?.lastPage ?? 1;
        if (page >= lastPage || lastPage <= 1) {
          break;
        }
        page++;
      }

      final result = List<ProjectModel>.unmodifiable(items);
      if (generation != _cacheGeneration) {
        return projects(loader: loader);
      }
      _projects = result;
      return result;
    } finally {
      if (generation == _cacheGeneration) {
        _projectsFuture = null;
      }
    }
  }

  Future<String> _currentScopeKey() async {
    final values = await Future.wait<Object?>([
      SessionStorage.getAuthToken(),
      SessionStorage.getCurrentCompanyId(),
      SessionStorage.getCurrentBranchId(),
      SessionStorage.getCurrentLocationId(),
      SessionStorage.getCurrentWarehouseId(),
      SessionStorage.getCurrentFinancialYearId(),
    ]);
    return Object.hashAll(values).toString();
  }

  static ProjectModuleRefreshController ensureRegistered() {
    if (Get.isRegistered<ProjectModuleRefreshController>(tag: tag)) {
      return Get.find<ProjectModuleRefreshController>(tag: tag);
    }
    return Get.put(ProjectModuleRefreshController(), tag: tag, permanent: true);
  }
}
