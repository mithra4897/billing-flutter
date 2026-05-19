import '../../../screen.dart';

class AccountGroupManagementController extends GetxController {
  AccountGroupManagementController();

  final AccountsService _accountsService = AccountsService();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController groupCodeController = TextEditingController();
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<AccountGroupModel> groups = const <AccountGroupModel>[];
  List<AccountGroupModel> filteredGroups = const <AccountGroupModel>[];
  AccountGroupModel? selectedGroup;
  int? parentGroupId;
  String groupNature = 'asset';
  String groupCategory = 'other';
  bool affectsProfitLoss = true;
  bool isActive = true;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    loadGroups();
  }

  @override
  void onClose() {
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
    return groups
        .where((item) => item.id != null && item.id != selectedId)
        .toList(growable: false);
  }

  Future<void> loadGroups({int? selectId}) async {
    initialLoading = groups.isEmpty;
    pageError = null;
    update();

    try {
      final response = await _accountsService.accountGroups(
        filters: const {'per_page': 300, 'sort_by': 'group_name'},
      );
      final items = response.data ?? const <AccountGroupModel>[];

      groups = items;
      filteredGroups = _filterGroups(items, searchController.text);
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

  List<AccountGroupModel> _filterGroups(
    List<AccountGroupModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (item) {
      return [
        item.groupCode ?? '',
        item.groupName ?? '',
        item.groupNature ?? '',
        item.groupCategory ?? '',
      ];
    });
  }

  void _applySearch() {
    filteredGroups = _filterGroups(groups, searchController.text);
    update();
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
