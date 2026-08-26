import '../../../screen.dart';
import 'settings_accounting_module_refresh_controller.dart';

class AccountGroupManagementController extends GetxController {
  AccountGroupManagementController();

  static const String _refreshSource = 'AccountGroupManagementController';

  final AccountsService _accountsService = AccountsService();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController groupCodeController = TextEditingController();
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  late final SettingsAccountingModuleRefreshController _moduleRefresh;
  Worker? _refreshWorker;

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<AccountGroupModel> groups = const <AccountGroupModel>[];
  List<AccountGroupModel> allGroups = const <AccountGroupModel>[];
  List<AccountGroupModel> filteredGroups = const <AccountGroupModel>[];
  PaginationMeta? paginationMeta;
  int currentPage = 1;
  static const int pageSize = 20;
  Timer? _searchDebounce;
  AccountGroupModel? selectedGroup;
  int? parentGroupId;
  String groupNature = 'asset';
  String groupCategory = 'other';
  bool affectsProfitLoss = true;
  bool isActive = true;

  @override
  void onInit() {
    super.onInit();
    _moduleRefresh =
        SettingsAccountingModuleRefreshController.ensureRegistered();
    _refreshWorker = ever<SettingsAccountingModuleRefreshEvent?>(
      _moduleRefresh.lastEvent,
      (event) {
        if (event == null || event.source == _refreshSource) {
          return;
        }
        unawaited(loadGroups());
      },
    );
    searchController.addListener(_applySearch);
    loadGroups();
  }

  @override
  void onClose() {
    _refreshWorker?.dispose();
    _searchDebounce?.cancel();
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    groupCodeController.dispose();
    groupNameController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  List<AccountGroupModel> get parentOptions {
    final selectedId = selectedGroup?.id;
    return allGroups
        .where((item) => item.id != null && item.id != selectedId)
        .toList(growable: false);
  }

  Future<void> loadGroups({int? selectId, bool resetPage = false}) async {
    if (resetPage) currentPage = 1;
    initialLoading = groups.isEmpty;
    pageError = null;
    update();

    try {
      final results = await Future.wait<dynamic>([
        _accountsService.accountGroups(filters: <String, dynamic>{
          'page': currentPage,
          'per_page': pageSize,
          'sort_by': 'group_name',
          'sort_order': 'asc',
          if (searchController.text.trim().isNotEmpty)
            'search': searchController.text.trim(),
        }),
        _accountsService.accountGroupsAll(
          filters: const {'sort_by': 'group_name'},
        ),
      ]);
      final response = results[0] as PaginatedResponse<AccountGroupModel>;
      final items = response.data ?? const <AccountGroupModel>[];

      groups = items;
      allGroups =
          (results[1] as ApiResponse<List<AccountGroupModel>>).data ??
          const <AccountGroupModel>[];
      paginationMeta = response.meta;
      filteredGroups = items;
      initialLoading = false;

      final selected = selectId != null
          ? items.cast<AccountGroupModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedGroup == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<AccountGroupModel?>().firstWhere(
                    (item) => item?.id == selectedGroup?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        selectGroup(selected, notify: false);
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
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(loadGroups(resetPage: true)),
    );
  }

  Future<void> setPage(int page) async {
    final lastPage = paginationMeta?.lastPage ?? 1;
    if (page < 1 || page > lastPage || page == currentPage) return;
    currentPage = page;
    await loadGroups();
  }

  void selectGroup(AccountGroupModel item, {bool notify = true}) {
    selectedGroup = item;
    groupCodeController.text = item.groupCode ?? '';
    groupNameController.text = item.groupName ?? '';
    parentGroupId = item.parentGroupId;
    groupNature = item.groupNature ?? 'asset';
    groupCategory = item.groupCategory ?? 'other';
    affectsProfitLoss = item.affectsProfitLoss;
    isActive = item.isActive;
    remarksController.text = item.remarks ?? '';
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedGroup = null;
    groupCodeController.clear();
    groupNameController.clear();
    parentGroupId = null;
    groupNature = 'asset';
    groupCategory = 'other';
    affectsProfitLoss = true;
    isActive = true;
    remarksController.clear();
    formError = null;
    if (notify) {
      update();
    }
  }

  void setParentGroupId(int? value) {
    parentGroupId = value;
    update();
  }

  void setGroupNature(String? value) {
    groupNature = value ?? 'asset';
    update();
  }

  void setGroupCategory(String? value) {
    groupCategory = value ?? 'other';
    update();
  }

  void setAffectsProfitLoss(bool value) {
    affectsProfitLoss = value;
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

    final model = AccountGroupModel(
      id: selectedGroup?.id,
      groupCode: groupCodeController.text.trim(),
      groupName: groupNameController.text.trim(),
      parentGroupId: parentGroupId,
      groupNature: groupNature,
      groupCategory: groupCategory,
      affectsProfitLoss: affectsProfitLoss,
      isSystemGroup: selectedGroup?.isSystemGroup ?? false,
      isActive: isActive,
      remarks: nullIfEmpty(remarksController.text),
    );

    try {
      final response = selectedGroup == null
          ? await _accountsService.createAccountGroup(model)
          : await _accountsService.updateAccountGroup(
              selectedGroup!.id!,
              model,
            );
      final saved = response.data;
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      _moduleRefresh.notifyChanged(source: _refreshSource);
      await loadGroups(selectId: saved?.id);
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> delete() async {
    final id = selectedGroup?.id;
    if (id == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _accountsService.deleteAccountGroup(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      _moduleRefresh.notifyChanged(source: _refreshSource);
      await loadGroups();
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }
}
