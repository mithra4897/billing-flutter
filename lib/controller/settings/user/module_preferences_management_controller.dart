import '../../../screen.dart';

class ModulePreferencesManagementController extends GetxController {
  ModulePreferencesManagementController();

  final AuthService _authService = AuthService();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController sortOrderController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<ModuleModel> modules = const <ModuleModel>[];
  List<ModuleModel> filteredModules = const <ModuleModel>[];
  ModuleModel? selectedModule;
  bool isHidden = false;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    loadModules();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    sortOrderController.dispose();
    super.onClose();
  }

  Future<void> loadModules({String? selectCode}) async {
    initialLoading = modules.isEmpty;
    pageError = null;
    update();

    try {
      final response = await _authService.menuPreferences();
      final items = response.data ?? const <ModuleModel>[];
      final sorted = [...items]
        ..sort((left, right) {
          final leftOrder = left.effectiveSortOrder ?? left.sortOrder ?? 0;
          final rightOrder = right.effectiveSortOrder ?? right.sortOrder ?? 0;
          final byOrder = leftOrder.compareTo(rightOrder);
          if (byOrder != 0) {
            return byOrder;
          }
          return (left.moduleName ?? '').compareTo(right.moduleName ?? '');
        });

      modules = sorted;
      filteredModules = _filterModules(sorted, searchController.text);
      initialLoading = false;

      final selected = selectCode != null
          ? sorted.cast<ModuleModel?>().firstWhere(
              (item) => item?.moduleCode == selectCode,
              orElse: () => null,
            )
          : (selectedModule == null
                ? (sorted.isNotEmpty ? sorted.first : null)
                : sorted.cast<ModuleModel?>().firstWhere(
                    (item) => item?.moduleCode == selectedModule?.moduleCode,
                    orElse: () => sorted.isNotEmpty ? sorted.first : null,
                  ));

      if (selected != null) {
        selectModule(selected, notify: false);
      } else {
        clearSelection(notify: false);
      }
    } catch (error) {
      initialLoading = false;
      pageError = error.toString();
    }

    update();
  }

  List<ModuleModel> _filterModules(List<ModuleModel> source, String query) {
    return filterMasterList(source, query, (item) {
      return [
        item.moduleName ?? '',
        item.moduleCode ?? '',
        item.moduleGroup ?? '',
      ];
    });
  }

  void _applySearch() {
    filteredModules = _filterModules(modules, searchController.text);
    update();
  }

  void selectModule(ModuleModel module, {bool notify = true}) {
    selectedModule = module;
    sortOrderController.text = (module.userSortOrder ?? module.sortOrder ?? 0)
        .toString();
    isHidden = module.isHidden ?? false;
    formError = null;
    if (notify) {
      update();
    }
  }

  void clearSelection({bool notify = true}) {
    selectedModule = null;
    sortOrderController.clear();
    isHidden = false;
    formError = null;
    if (notify) {
      update();
    }
  }

  void setIsHidden(bool value) {
    isHidden = value;
    update();
  }

  Future<void> save() async {
    final selected = selectedModule;
    if (selected == null) {
      return;
    }

    final sortOrder = int.tryParse(sortOrderController.text.trim());
    if (sortOrder == null) {
      formError = 'Menu sort order must be a valid number.';
      update();
      return;
    }

    saving = true;
    formError = null;
    update();

    final updatedModules = modules
        .map((item) {
          if (item.moduleCode != selected.moduleCode) {
            return ModuleModel(
              moduleCode: item.moduleCode,
              moduleName: item.moduleName,
              moduleGroup: item.moduleGroup,
              routePath: item.routePath,
              iconKey: item.iconKey,
              description: item.description,
              sortOrder: item.sortOrder,
              userSortOrder: item.userSortOrder ?? item.sortOrder,
              effectiveSortOrder:
                  item.userSortOrder ??
                  item.effectiveSortOrder ??
                  item.sortOrder,
              isHidden: item.isHidden ?? false,
              isActive: item.isActive,
            );
          }

          return ModuleModel(
            moduleCode: item.moduleCode,
            moduleName: item.moduleName,
            moduleGroup: item.moduleGroup,
            routePath: item.routePath,
            iconKey: item.iconKey,
            description: item.description,
            sortOrder: item.sortOrder,
            userSortOrder: sortOrder,
            effectiveSortOrder: sortOrder,
            isHidden: isHidden,
            isActive: item.isActive,
          );
        })
        .toList(growable: false);

    try {
      final response = await _authService.syncMenuPreferences(updatedModules);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadModules(selectCode: selected.moduleCode);
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }
}
