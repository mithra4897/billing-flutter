import '../../../screen.dart';
import '../../../helper/settings_register_reload_helper.dart';

class CashSessionManagementController extends GetxController {
  CashSessionManagementController();

  final AccountsService _accountsService = AccountsService();
  final MasterService _masterService = MasterService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> openFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> closeFormKey = GlobalKey<FormState>();
  final TextEditingController openingDatetimeController =
      TextEditingController();
  final TextEditingController openingBalanceController =
      TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController closingDatetimeController =
      TextEditingController();
  final TextEditingController expectedClosingController =
      TextEditingController();
  final TextEditingController actualClosingController = TextEditingController();
  final TextEditingController closingRemarksController =
      TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<CashSessionModel> sessions = const <CashSessionModel>[];
  List<CashSessionModel> filteredSessions = const <CashSessionModel>[];
  List<AccountModel> cashAccounts = const <AccountModel>[];
  CashSessionModel? selectedSession;
  int? contextCompanyId;
  int? contextBranchId;
  int? contextLocationId;
  int? companyId;
  int? branchId;
  int? locationId;
  int? cashAccountId;
  int? currentUserId;
  String? currentUserLabel;

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
    openingDatetimeController.dispose();
    openingBalanceController.dispose();
    remarksController.dispose();
    closingDatetimeController.dispose();
    expectedClosingController.dispose();
    actualClosingController.dispose();
    closingRemarksController.dispose();
    super.onClose();
  }

  Future<void> loadPage({int? selectId}) async {
    initialLoading = sessions.isEmpty;
    pageError = null;
    update();

    try {
      final currentUser = await SessionStorage.getCurrentUser();
      final responses = await Future.wait<dynamic>([
        _accountsService.cashSessions(),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
        _masterService.branches(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        _masterService.businessLocations(
          filters: const {'per_page': 200, 'sort_by': 'name'},
        ),
        _accountsService.accountsAll(
          filters: const {
            'account_type': 'cash',
            'is_active': 1,
            'sort_by': 'account_name',
          },
        ),
      ]);

      final nextSessions =
          (responses[0] as ApiResponse<List<CashSessionModel>>).data ??
          const <CashSessionModel>[];
      final companies =
          (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final branches =
          (responses[2] as PaginatedResponse<BranchModel>).data ??
          const <BranchModel>[];
      final locations =
          (responses[3] as PaginatedResponse<BusinessLocationModel>).data ??
          const <BusinessLocationModel>[];
      final accounts =
          (responses[4] as ApiResponse<List<AccountModel>>).data ??
          const <AccountModel>[];
      final activeCompanies = companies
          .where((item) => item.isActive)
          .toList(growable: false);
      final activeBranches = branches
          .where((item) => item.isActive)
          .toList(growable: false);
      final activeLocations = locations
          .where((item) => item.isActive)
          .toList(growable: false);
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: activeBranches,
            locations: activeLocations,
            financialYears: const <FinancialYearModel>[],
          );

      sessions = nextSessions;
      filteredSessions = _filterSessions(nextSessions, searchController.text);
      contextCompanyId = contextSelection.companyId;
      contextBranchId = contextSelection.branchId;
      contextLocationId = contextSelection.locationId;
      cashAccounts = accounts.where((item) => item.isActive).toList();
      currentUserId = int.tryParse(currentUser?['id']?.toString() ?? '');
      currentUserLabel =
          currentUser?['display_name']?.toString() ??
          currentUser?['username']?.toString();
      initialLoading = false;

      final selected = selectId != null
          ? nextSessions.cast<CashSessionModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedSession == null
                ? (nextSessions.isNotEmpty ? nextSessions.first : null)
                : nextSessions.cast<CashSessionModel?>().firstWhere(
                    (item) => item?.id == selectedSession?.id,
                    orElse: () =>
                        nextSessions.isNotEmpty ? nextSessions.first : null,
                  ));

      if (selected != null) {
        selectSession(selected, notify: false);
      } else {
        resetOpenForm(notify: false);
      }
    } catch (errorValue) {
      pageError = errorValue.toString();
      initialLoading = false;
    }

    update();
  }

  List<CashSessionModel> _filterSessions(
    List<CashSessionModel> items,
    String query,
  ) {
    return filterMasterList(items, query, (item) {
      return [
        item.cashAccountName ?? '',
        item.cashAccountCode ?? '',
        item.username ?? '',
        item.userDisplayName ?? '',
        item.status ?? '',
      ];
    });
  }

  void _applySearch() {
    filteredSessions = _filterSessions(sessions, searchController.text);
    update();
  }

  List<AccountModel> get cashAccountOptions {
    return cashAccounts
        .where((item) {
          final companyMatches =
              companyId == null ||
              item.companyId == null ||
              item.companyId == companyId;
          final branchMatches =
              branchId == null ||
              item.branchId == null ||
              item.branchId == branchId;
          return companyMatches && branchMatches;
        })
        .toList(growable: false);
  }

  void selectSession(CashSessionModel item, {bool notify = true}) {
    selectedSession = item;
    companyId = item.companyId;
    branchId = item.branchId;
    locationId = item.locationId;
    cashAccountId = item.cashAccountId;
    openingDatetimeController.text =
        item.openingDatetime?.split('.').first ?? '';
    openingBalanceController.text = item.openingBalance?.toString() ?? '0';
    remarksController.text = item.remarks ?? '';
    closingDatetimeController.text =
        item.closingDatetime?.split('.').first ??
        DateTime.now().toIso8601String().split('.').first;
    expectedClosingController.text =
        item.expectedClosingBalance?.toString() ?? '';
    actualClosingController.text = item.actualClosingBalance?.toString() ?? '';
    closingRemarksController.text = item.remarks ?? '';
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetOpenForm({bool notify = true}) {
    selectedSession = null;
    companyId = contextCompanyId;
    branchId = contextBranchId;
    locationId = contextLocationId;
    cashAccountId = cashAccountOptions.isNotEmpty
        ? cashAccountOptions.first.id
        : null;
    openingDatetimeController.text = DateTime.now()
        .toIso8601String()
        .split('.')
        .first;
    openingBalanceController.text = '0';
    remarksController.clear();
    closingDatetimeController.text = DateTime.now()
        .toIso8601String()
        .split('.')
        .first;
    expectedClosingController.clear();
    actualClosingController.clear();
    closingRemarksController.clear();
    formError = null;
    if (notify) {
      update();
    }
  }

  void setCashAccountId(int? value) {
    cashAccountId = value;
    update();
  }

  bool get isOpen => (selectedSession?.status ?? '') == 'open';

  Future<void> openSession() async {
    if (!openFormKey.currentState!.validate() || currentUserId == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _accountsService.openCashSession(
        CashSessionModel(
          companyId: companyId,
          branchId: branchId,
          locationId: locationId,
          userId: currentUserId,
          cashAccountId: cashAccountId,
          openingDatetime: openingDatetimeController.text.trim(),
          openingBalance:
              double.tryParse(openingBalanceController.text.trim()) ?? 0,
          remarks: nullIfEmpty(remarksController.text),
        ),
      );
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      reloadCashSessionRegister();
      await loadPage(selectId: response.data?.id);
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> closeSession() async {
    final id = selectedSession?.id;
    if (id == null || !closeFormKey.currentState!.validate()) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _accountsService.closeCashSession(
        id,
        CashSessionModel(
          closingDatetime: closingDatetimeController.text.trim(),
          expectedClosingBalance: double.tryParse(
            expectedClosingController.text.trim(),
          ),
          actualClosingBalance: double.tryParse(
            actualClosingController.text.trim(),
          ),
          remarks: nullIfEmpty(closingRemarksController.text),
        ),
      );
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      reloadCashSessionRegister();
      await loadPage(selectId: response.data?.id);
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> cancelSession() async {
    final id = selectedSession?.id;
    if (id == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _accountsService.cancelCashSession(
        id,
        CashSessionModel(remarks: nullIfEmpty(closingRemarksController.text)),
      );
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      reloadCashSessionRegister();
      await loadPage(selectId: response.data?.id);
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  void startNewSession({required bool isDesktop}) {
    resetOpenForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }
}
