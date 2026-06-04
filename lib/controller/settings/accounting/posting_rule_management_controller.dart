import '../../../screen.dart';
import 'settings_accounting_module_refresh_controller.dart';

class PostingRuleManagementController extends GetxController {
  PostingRuleManagementController();

  static const String _refreshSource = 'PostingRuleManagementController';

  final AccountsService _accountsService = AccountsService();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController lineNoController = TextEditingController(
    text: '1',
  );
  final TextEditingController narrationTemplateController =
      TextEditingController();
  final TextEditingController priorityController = TextEditingController(
    text: '1',
  );
  late final SettingsAccountingModuleRefreshController _moduleRefresh;
  Worker? _refreshWorker;

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<PostingRuleGroupModel> groups = const <PostingRuleGroupModel>[];
  List<PostingRuleModel> rows = const <PostingRuleModel>[];
  List<PostingRuleModel> filtered = const <PostingRuleModel>[];
  List<AccountModel> accounts = const <AccountModel>[];
  PostingRuleModel? selected;
  int? groupId;
  String entrySide = 'debit';
  String accountSourceType = 'fixed_account';
  int? fixedAccountId;
  String amountSource = 'total_amount';
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
    lineNoController.dispose();
    narrationTemplateController.dispose();
    priorityController.dispose();
    super.onClose();
  }

  Map<String, dynamic> json(PostingRuleModel? model) =>
      model?.toJson() ?? const <String, dynamic>{};

  Future<void> load({int? selectId}) async {
    initialLoading = rows.isEmpty && groups.isEmpty;
    pageError = null;
    update();
    try {
      final results = await Future.wait<dynamic>([
        _accountsService.postingRuleGroupsAll(
          filters: const {'sort_by': 'group_name', 'per_page': 500},
        ),
        _accountsService.postingRules(
          filters: const {'per_page': 500, 'sort_by': 'line_no'},
        ),
        _accountsService.accountsAll(
          filters: const {'sort_by': 'account_name'},
        ),
      ]);
      final nextGroups =
          (results[0] as ApiResponse<List<PostingRuleGroupModel>>).data ??
          const <PostingRuleGroupModel>[];
      final nextRows =
          (results[1] as PaginatedResponse<PostingRuleModel>).data ??
          const <PostingRuleModel>[];
      final nextAccounts =
          (results[2] as ApiResponse<List<AccountModel>>).data ??
          const <AccountModel>[];
      groups = nextGroups;
      rows = nextRows;
      filtered = _filter(nextRows, searchController.text);
      accounts = nextAccounts.where((account) => account.isActive).toList();
      initialLoading = false;
      if (groupId == null && nextGroups.isNotEmpty) {
        groupId = intValue(nextGroups.first.toJson(), 'id');
      }

      final nextSelected = selectId != null
          ? nextRows.cast<PostingRuleModel?>().firstWhere(
              (element) => intValue(json(element), 'id') == selectId,
              orElse: () => null,
            )
          : (selected == null
                ? (nextRows.isNotEmpty ? nextRows.first : null)
                : nextRows.cast<PostingRuleModel?>().firstWhere(
                    (element) =>
                        intValue(json(element), 'id') ==
                        intValue(json(selected), 'id'),
                    orElse: () => nextRows.isNotEmpty ? nextRows.first : null,
                  ));
      if (nextSelected != null) {
        applySelection(nextSelected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (error) {
      pageError = error.toString();
      initialLoading = false;
    }
    update();
  }

  List<PostingRuleModel> _filter(List<PostingRuleModel> source, String query) {
    return filterMasterList(source, query, (item) {
      final data = item.toJson();
      return [
        stringValue(data, 'entry_side'),
        stringValue(data, 'account_source_type'),
        stringValue(data, 'amount_source'),
      ];
    });
  }

  void _applySearch() {
    filtered = _filter(rows, searchController.text);
    update();
  }

  void applySelection(PostingRuleModel item, {bool notify = true}) {
    final data = item.toJson();
    selected = item;
    groupId = intValue(data, 'posting_rule_group_id');
    lineNoController.text = stringValue(data, 'line_no', '1');
    entrySide = stringValue(data, 'entry_side', 'debit');
    accountSourceType = stringValue(
      data,
      'account_source_type',
      'fixed_account',
    );
    fixedAccountId = intValue(data, 'fixed_account_id');
    amountSource = stringValue(data, 'amount_source', 'total_amount');
    narrationTemplateController.text = stringValue(data, 'narration_template');
    priorityController.text = stringValue(data, 'priority_order', '1');
    isActive = boolValue(data, 'is_active', fallback: true);
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selected = null;
    lineNoController.text = '1';
    entrySide = 'debit';
    accountSourceType = 'fixed_account';
    fixedAccountId = null;
    amountSource = 'total_amount';
    narrationTemplateController.clear();
    priorityController.text = '1';
    isActive = true;
    if (groups.isNotEmpty) {
      groupId = intValue(groups.first.toJson(), 'id');
    }
    formError = null;
    if (notify) {
      update();
    }
  }

  void setGroupId(int? value) {
    groupId = value;
    update();
  }

  void setEntrySide(String? value) {
    entrySide = value ?? 'debit';
    update();
  }

  void setAccountSourceType(String? value) {
    accountSourceType = value ?? 'fixed_account';
    if (accountSourceType != 'fixed_account') {
      fixedAccountId = null;
    }
    update();
  }

  void setFixedAccountId(int? value) {
    fixedAccountId = value;
    update();
  }

  void setAmountSource(String? value) {
    amountSource = value ?? 'total_amount';
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
    if (groupId == null) {
      formError = 'Select a posting rule group.';
      update();
      return;
    }
    saving = true;
    formError = null;
    update();
    final lineNo = int.tryParse(lineNoController.text.trim()) ?? 1;
    final priority = int.tryParse(priorityController.text.trim()) ?? 1;
    final body = PostingRuleModel.fromJson(<String, dynamic>{
      'posting_rule_group_id': groupId,
      'line_no': lineNo,
      'entry_side': entrySide,
      'account_source_type': accountSourceType,
      'fixed_account_id': accountSourceType == 'fixed_account'
          ? fixedAccountId
          : null,
      'amount_source': amountSource,
      'narration_template': nullIfEmpty(narrationTemplateController.text),
      'priority_order': priority,
      'is_active': isActive,
    });
    try {
      final ApiResponse<PostingRuleModel> response;
      final selectedId = intValue(json(selected), 'id');
      if (selectedId == null) {
        response = await _accountsService.createPostingRule(body);
      } else {
        response = await _accountsService.updatePostingRule(selectedId, body);
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
      final response = await _accountsService.deletePostingRule(id);
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
}
