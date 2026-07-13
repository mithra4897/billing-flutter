import '../../../screen.dart';
import 'settings_accounting_module_refresh_controller.dart';

class PostingRuleGroupManagementController extends GetxController {
  PostingRuleGroupManagementController();

  static const String _refreshSource = 'PostingRuleGroupManagementController';

  final AccountsService _accountsService = AccountsService();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  late final SettingsAccountingModuleRefreshController _moduleRefresh;
  Worker? _refreshWorker;

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<PostingRuleGroupModel> rows = const <PostingRuleGroupModel>[];
  List<PostingRuleGroupModel> filtered = const <PostingRuleGroupModel>[];
  List<AppDropdownItem<String>> documentTypeItems =
      const <AppDropdownItem<String>>[];
  PostingRuleGroupModel? selected;
  String? documentType;
  String triggerEvent = 'on_post';
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
        unawaited(load());
      },
    );
    searchController.addListener(_applySearch);
    load();
  }

  @override
  void onClose() {
    _refreshWorker?.dispose();
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    codeController.dispose();
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  Map<String, dynamic> json(PostingRuleGroupModel? model) =>
      model?.toJson() ?? const <String, dynamic>{};

  Future<void> load({int? selectId}) async {
    initialLoading = rows.isEmpty;
    pageError = null;
    update();
    try {
      await MasterDataCache.to.ensureLoaded();
      final cache = MasterDataCache.to;
      final responses = await Future.wait([
        _accountsService.postingRuleGroups(
          filters: const {'per_page': 300, 'sort_by': 'group_name'},
        ),
      ]);
      final items = responses[0].data ?? const <PostingRuleGroupModel>[];
      rows = items;
      filtered = _filter(items, searchController.text);
      documentTypeItems = buildDocumentTypeDropdownItems(
        cache.activeDocumentSeries,
      );

      final nextSelected = selectId != null
          ? items.cast<PostingRuleGroupModel?>().firstWhere(
              (element) => intValue(json(element), 'id') == selectId,
              orElse: () => null,
            )
          : (selected == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<PostingRuleGroupModel?>().firstWhere(
                    (element) =>
                        intValue(json(element), 'id') ==
                        intValue(json(selected), 'id'),
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (nextSelected != null) {
        applySelection(nextSelected, notify: false);
      } else {
        resetForm(notify: false);
      }
      initialLoading = false;
    } catch (error) {
      pageError = error.toString();
      initialLoading = false;
    }
    update();
  }

  List<PostingRuleGroupModel> _filter(
    List<PostingRuleGroupModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (item) {
      final data = item.toJson();
      return [
        stringValue(data, 'group_code'),
        stringValue(data, 'group_name'),
        stringValue(data, 'document_type'),
      ];
    });
  }

  void _applySearch() {
    filtered = _filter(rows, searchController.text);
    update();
  }

  void applySelection(PostingRuleGroupModel item, {bool notify = true}) {
    final data = item.toJson();
    selected = item;
    codeController.text = stringValue(data, 'group_code');
    nameController.text = stringValue(data, 'group_name');
    _setDocumentType(stringValue(data, 'document_type'));
    descriptionController.text = stringValue(data, 'description');
    triggerEvent = stringValue(data, 'trigger_event', 'on_post');
    isActive = boolValue(data, 'is_active', fallback: true);
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selected = null;
    codeController.clear();
    nameController.clear();
    documentType = null;
    descriptionController.clear();
    triggerEvent = 'on_post';
    isActive = true;
    formError = null;
    if (notify) {
      update();
    }
  }

  void setTriggerEvent(String? value) {
    triggerEvent = value ?? 'on_post';
    update();
  }

  void setDocumentType(String? value) {
    _setDocumentType(value);
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
    final body = PostingRuleGroupModel.fromJson(
      normalizeDatePayload(<String, dynamic>{
        'group_code': codeController.text.trim(),
        'group_name': nameController.text.trim(),
        'document_type': documentType,
        'trigger_event': triggerEvent,
        'description': nullIfEmpty(descriptionController.text),
        'is_active': isActive,
      }),
    );
    try {
      final ApiResponse<PostingRuleGroupModel> response;
      final selectedId = intValue(json(selected), 'id');
      if (selectedId == null) {
        response = await _accountsService.createPostingRuleGroup(body);
      } else {
        response = await _accountsService.updatePostingRuleGroup(
          selectedId,
          body,
        );
      }
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      _moduleRefresh.notifyChanged(source: _refreshSource);
      await load(selectId: intValue(json(response.data), 'id') ?? selectedId);
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> delete() async {
    final id = intValue(json(selected), 'id');
    if (id == null) {
      return;
    }
    saving = true;
    formError = null;
    update();
    try {
      final response = await _accountsService.deletePostingRuleGroup(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      _moduleRefresh.notifyChanged(source: _refreshSource);
      await load();
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  void _setDocumentType(String? value) {
    final resolved = resolveDocumentTypeSelection(
      items: documentTypeItems,
      value: value,
    );
    documentType = resolved.selectedValue;
    documentTypeItems = resolved.items;
  }
}
