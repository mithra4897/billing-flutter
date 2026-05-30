import '../../../screen.dart';
import '../../../helper/settings_register_reload_helper.dart';

class AccountManagementController extends GetxController {
  static const List<AppDropdownItem<String>> accountTypeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'general', label: 'General'),
        AppDropdownItem(value: 'party', label: 'Party'),
        AppDropdownItem(value: 'cash', label: 'Cash'),
        AppDropdownItem(value: 'bank', label: 'Bank'),
        AppDropdownItem(value: 'tax', label: 'Tax'),
        AppDropdownItem(value: 'employee', label: 'Employee'),
        AppDropdownItem(value: 'customer', label: 'Customer'),
        AppDropdownItem(value: 'supplier', label: 'Supplier'),
        AppDropdownItem(value: 'job_worker', label: 'Job Worker'),
        AppDropdownItem(value: 'transporter', label: 'Transporter'),
      ];
  static const List<AppDropdownItem<String>> openingBalanceTypeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'debit', label: 'Debit'),
        AppDropdownItem(value: 'credit', label: 'Credit'),
      ];

  AccountManagementController();

  final AccountsService _accountsService = AccountsService();
  final MasterService _masterService = MasterService();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController accountCodeController = TextEditingController();
  final TextEditingController accountNameController = TextEditingController();
  final TextEditingController openingBalanceController =
      TextEditingController();
  final TextEditingController currencyCodeController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<AccountModel> accounts = const <AccountModel>[];
  List<AccountModel> filteredAccounts = const <AccountModel>[];
  List<AccountGroupModel> groups = const <AccountGroupModel>[];
  AccountModel? selectedAccount;
  int? contextCompanyId;
  int? contextBranchId;
  int? companyId;
  int? branchId;
  int? accountGroupId;
  String accountType = 'general';
  String openingBalanceType = 'debit';
  bool allowManualEntries = true;
  bool allowReconciliation = false;
  bool isControlAccount = false;
  bool isActive = true;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    loadPage();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    accountCodeController.dispose();
    accountNameController.dispose();
    openingBalanceController.dispose();
    currencyCodeController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  Future<void> loadPage({int? selectId}) async {
    initialLoading = accounts.isEmpty;
    pageError = null;
    update();

    try {
      final responses = await Future.wait<dynamic>([
        _accountsService.accounts(
          filters: const {'per_page': 300, 'sort_by': 'account_name'},
        ),
        _masterService.companies(
          filters: const {'per_page': 200, 'sort_by': 'legal_name'},
        ),
        _masterService.branches(
          filters: const {'per_page': 300, 'sort_by': 'name'},
        ),
        _accountsService.accountGroupsAll(
          filters: const {'sort_by': 'group_name'},
        ),
      ]);

      final nextAccounts =
          (responses[0] as PaginatedResponse<AccountModel>).data ??
          const <AccountModel>[];
      final companies =
          (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final branches =
          (responses[2] as PaginatedResponse<BranchModel>).data ??
          const <BranchModel>[];
      final nextGroups =
          (responses[3] as ApiResponse<List<AccountGroupModel>>).data ??
          const <AccountGroupModel>[];

      final activeCompanies = companies
          .where((item) => item.isActive)
          .toList(growable: false);
      final activeBranches = branches
          .where((item) => item.isActive)
          .toList(growable: false);
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: activeBranches,
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );

      accounts = nextAccounts;
      filteredAccounts = _filterAccounts(nextAccounts, searchController.text);
      contextCompanyId = contextSelection.companyId;
      contextBranchId = contextSelection.branchId;
      groups = nextGroups.where((item) => item.isActive).toList(growable: false);
      initialLoading = false;

      final selected = selectId != null
          ? nextAccounts.cast<AccountModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedAccount == null
                ? (nextAccounts.isNotEmpty ? nextAccounts.first : null)
                : nextAccounts.cast<AccountModel?>().firstWhere(
                    (item) => item?.id == selectedAccount?.id,
                    orElse: () =>
                        nextAccounts.isNotEmpty ? nextAccounts.first : null,
                  ));

      if (selected != null) {
        selectAccount(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (error) {
      initialLoading = false;
      pageError = error.toString();
    }

    update();
  }

  List<AccountModel> _filterAccounts(List<AccountModel> source, String query) {
    return filterMasterList(source, query, (item) {
      return [
        item.accountCode ?? '',
        item.accountName ?? '',
        item.accountType ?? '',
        item.accountGroupName ?? '',
        item.companyName ?? '',
      ];
    });
  }

  void _applySearch() {
    filteredAccounts = _filterAccounts(accounts, searchController.text);
    update();
  }

  void selectAccount(AccountModel item, {bool notify = true}) {
    selectedAccount = item;
    companyId = item.companyId;
    branchId = item.branchId;
    accountCodeController.text = item.accountCode ?? '';
    accountNameController.text = item.accountName ?? '';
    accountGroupId = item.accountGroupId;
    accountType = item.accountType ?? 'general';
    openingBalanceController.text = item.openingBalance?.toString() ?? '';
    openingBalanceType = item.openingBalanceType ?? 'debit';
    currencyCodeController.text = item.currencyCode ?? 'INR';
    allowManualEntries = item.allowManualEntries;
    allowReconciliation = item.allowReconciliation;
    isControlAccount = item.isControlAccount;
    isActive = item.isActive;
    remarksController.text = item.remarks ?? '';
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedAccount = null;
    companyId = contextCompanyId;
    branchId = contextBranchId;
    accountCodeController.clear();
    accountNameController.clear();
    accountGroupId = null;
    accountType = 'general';
    openingBalanceController.text = '0';
    openingBalanceType = 'debit';
    currencyCodeController.text = 'INR';
    allowManualEntries = true;
    allowReconciliation = false;
    isControlAccount = false;
    isActive = true;
    remarksController.clear();
    formError = null;
    if (notify) {
      update();
    }
  }

  void startNew({required bool isDesktop}) {
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }

  void setAccountGroupId(int? value) {
    accountGroupId = value;
    update();
  }

  void setAccountType(String? value) {
    accountType = value ?? 'general';
    update();
  }

  void setOpeningBalanceType(String? value) {
    openingBalanceType = value ?? 'debit';
    update();
  }

  void setAllowManualEntries(bool value) {
    allowManualEntries = value;
    update();
  }

  void setAllowReconciliation(bool value) {
    allowReconciliation = value;
    update();
  }

  void setIsControlAccount(bool value) {
    isControlAccount = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    saving = true;
    formError = null;
    update();

    final model = AccountModel(
      id: selectedAccount?.id,
      companyId: companyId,
      branchId: branchId,
      accountCode: accountCodeController.text.trim(),
      accountName: accountNameController.text.trim(),
      accountGroupId: accountGroupId,
      accountType: accountType,
      openingBalance:
          double.tryParse(openingBalanceController.text.trim()) ?? 0,
      openingBalanceType: openingBalanceType,
      currencyCode: currencyCodeController.text.trim(),
      allowManualEntries: allowManualEntries,
      allowReconciliation: allowReconciliation,
      isControlAccount: isControlAccount,
      isSystemAccount: selectedAccount?.isSystemAccount ?? false,
      isActive: isActive,
      remarks: nullIfEmpty(remarksController.text),
    );

    try {
      final response = selectedAccount == null
          ? await _accountsService.createAccount(model)
          : await _accountsService.updateAccount(selectedAccount!.id!, model);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage(selectId: response.data?.id);
      reloadPartyAccountRegister();
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> delete() async {
    final id = selectedAccount?.id;
    if (id == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _accountsService.deleteAccount(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage();
      reloadPartyAccountRegister();
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }
}
