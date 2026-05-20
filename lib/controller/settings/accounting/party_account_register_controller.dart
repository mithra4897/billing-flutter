import '../../../screen.dart';

class PartyAccountRegisterController extends GetxController {
  PartyAccountRegisterController({this.initialPartyId});

  final int? initialPartyId;

  static const List<AppDropdownItem<String>> accountPurposeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'primary', label: 'Primary'),
        AppDropdownItem(value: 'receivable', label: 'Receivable'),
        AppDropdownItem(value: 'payable', label: 'Payable'),
        AppDropdownItem(value: 'advance', label: 'Advance'),
        AppDropdownItem(value: 'salary', label: 'Salary'),
        AppDropdownItem(value: 'commission', label: 'Commission'),
        AppDropdownItem(value: 'other', label: 'Other'),
      ];

  static const List<AppDropdownItem<String?>> accountPurposeFilterItems =
      <AppDropdownItem<String?>>[
        AppDropdownItem<String?>(value: null, label: 'All purposes'),
        AppDropdownItem<String?>(value: 'primary', label: 'Primary'),
        AppDropdownItem<String?>(value: 'receivable', label: 'Receivable'),
        AppDropdownItem<String?>(value: 'payable', label: 'Payable'),
        AppDropdownItem<String?>(value: 'advance', label: 'Advance'),
        AppDropdownItem<String?>(value: 'salary', label: 'Salary'),
        AppDropdownItem<String?>(value: 'commission', label: 'Commission'),
        AppDropdownItem<String?>(value: 'other', label: 'Other'),
      ];

  static const List<AppDropdownItem<bool?>> activeFilterItems =
      <AppDropdownItem<bool?>>[
        AppDropdownItem<bool?>(value: null, label: 'All statuses'),
        AppDropdownItem<bool?>(value: true, label: 'Active'),
        AppDropdownItem<bool?>(value: false, label: 'Inactive'),
      ];

  final AccountsService _accountsService = AccountsService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final ScrollController pageScrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool initialLoading = true;
  bool loading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  List<PartyAccountModel> rows = const <PartyAccountModel>[];
  PaginationMeta? meta;
  int page = 1;
  int perPage = 20;

  List<PartyModel> parties = const <PartyModel>[];
  List<AccountModel> accounts = const <AccountModel>[];
  int? companyId;
  String? filterPurpose;
  bool? filterActive;

  PartyAccountModel? editing;
  int? formPartyId;
  int? formAccountId;
  String formPurpose = 'primary';
  bool formDefault = true;
  bool formActive = true;

  bool canCreate = false;
  bool canUpdate = false;
  bool canDelete = false;

  @override
  void onInit() {
    super.onInit();
    formPartyId = initialPartyId;
    bootstrap();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    searchController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  Future<void> loadPermissions() async {
    final codes = await SessionStorage.getPermissionCodes();
    canCreate = codes.contains('accounts.create');
    canUpdate = codes.contains('accounts.update');
    canDelete = codes.contains('accounts.delete');
    update();
  }

  Future<void> bootstrap() async {
    initialLoading = true;
    pageError = null;
    update();

    await loadPermissions();
    try {
      final companiesResponse = await _masterService.companies(
        filters: const {'per_page': 200, 'sort_by': 'legal_name'},
      );
      final partiesResponse = await _partiesService.parties(
        filters: const {'per_page': 500, 'sort_by': 'party_name'},
      );
      final companies = (companiesResponse.data ?? const <CompanyModel>[])
          .where((item) => item.isActive)
          .toList(growable: false);
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: companies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );

      companyId = contextSelection.companyId;
      parties =
          partiesResponse.data
              ?.where((item) => item.isActive)
              .toList(growable: false) ??
          const <PartyModel>[];
      initialLoading = false;
      update();

      await loadAccountsForCompany();
      await fetch(resetPage: true);
    } catch (errorValue) {
      initialLoading = false;
      pageError = errorValue.toString();
      update();
    }
  }

  Future<void> loadAccountsForCompany() async {
    final selectedCompanyId = companyId;
    if (selectedCompanyId == null) {
      accounts = const <AccountModel>[];
      update();
      return;
    }

    try {
      final response = await _accountsService.accountsAll(
        filters: <String, dynamic>{
          'company_id': selectedCompanyId,
          'is_active': 1,
          'sort_by': 'account_name',
        },
      );
      accounts = (response.data ?? const <AccountModel>[])
          .where((item) => item.id != null && item.isActive)
          .toList(growable: false);
    } catch (_) {
      accounts = const <AccountModel>[];
    }

    update();
  }

  Future<void> fetch({bool resetPage = false}) async {
    if (resetPage) {
      page = 1;
    }

    loading = true;
    pageError = null;
    update();

    try {
      final filters = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        'sort_by': 'id',
        'sort_order': 'desc',
      };
      if (companyId != null) {
        filters['company_id'] = companyId;
      }
      if ((filterPurpose ?? '').isNotEmpty) {
        filters['account_purpose'] = filterPurpose;
      }
      if (filterActive != null) {
        filters['is_active'] = filterActive! ? 1 : 0;
      }
      final query = searchController.text.trim();
      if (query.isNotEmpty) {
        filters['search'] = query;
      }
      final response = await _accountsService.partyAccountsRegister(
        filters: filters,
      );
      rows = response.data ?? const <PartyAccountModel>[];
      meta = response.meta;
      loading = false;
    } catch (errorValue) {
      loading = false;
      pageError = errorValue.toString();
    }

    update();
  }

  void syncInitialPartyId(int? value) {
    formPartyId = value;
    update();
  }

  void startNewMapping({int? preferredPartyId}) {
    editing = null;
    formError = null;
    formPartyId = preferredPartyId ?? formPartyId;
    formAccountId = null;
    formPurpose = 'primary';
    formDefault = true;
    formActive = true;
    remarksController.clear();
    update();
  }

  void editRow(PartyAccountModel row) {
    editing = row;
    formError = null;
    formPartyId = row.partyId;
    formAccountId = row.accountId;
    formPurpose = row.accountPurpose ?? 'primary';
    formDefault = row.isDefault;
    formActive = row.isActive;
    remarksController.text = row.remarks ?? '';
    update();
  }

  void setFilterPurpose(String? value) {
    filterPurpose = value;
    update();
  }

  void setFilterActive(bool? value) {
    filterActive = value;
    update();
  }

  void clearFilters() {
    searchController.clear();
    filterPurpose = null;
    filterActive = null;
    update();
  }

  void setFormPartyId(int? value) {
    formPartyId = value;
    update();
  }

  void setFormAccountId(int? value) {
    formAccountId = value;
    update();
  }

  void setFormPurpose(String? value) {
    formPurpose = value ?? 'primary';
    update();
  }

  void setFormDefault(bool value) {
    formDefault = value;
    update();
  }

  void setFormActive(bool value) {
    formActive = value;
    update();
  }

  void setPerPage(int value) {
    perPage = value;
    update();
    fetch(resetPage: true);
  }

  void setPage(int value) {
    page = value;
    update();
    fetch();
  }

  Future<void> saveMapping() async {
    if (!canCreate && editing == null) {
      return;
    }
    if (!canUpdate && editing != null) {
      return;
    }
    if (companyId == null) {
      formError = 'Select a company before saving.';
      update();
      return;
    }
    if (formKey.currentState?.validate() != true) {
      return;
    }
    final partyId = formPartyId;
    if (partyId == null) {
      formError = 'Party is required.';
      update();
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final model = PartyAccountModel(
        id: editing?.id,
        partyId: partyId,
        accountId: formAccountId,
        accountPurpose: formPurpose,
        isDefault: formDefault,
        isActive: formActive,
        remarks: nullIfEmpty(remarksController.text),
      );

      final ApiResponse<PartyAccountModel> response = editing == null
          ? await _accountsService.createPartyAccount(model)
          : await _accountsService.updatePartyAccount(editing!.id!, model);

      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await fetch(resetPage: true);
      startNewMapping(preferredPartyId: initialPartyId ?? formPartyId);
    } catch (errorValue) {
      formError = errorValue.toString();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> deleteMapping() async {
    final id = editing?.id;
    if (id == null || !canDelete) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _accountsService.deletePartyAccount(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await fetch(resetPage: true);
      startNewMapping(preferredPartyId: initialPartyId ?? formPartyId);
    } catch (errorValue) {
      formError = errorValue.toString();
    } finally {
      saving = false;
      update();
    }
  }

  PaginationMeta get effectiveMeta =>
      meta ??
      PaginationMeta(
        currentPage: page,
        lastPage: 1,
        perPage: perPage,
        total: rows.length,
      );

  bool get canEdit =>
      (editing == null && canCreate) || (editing != null && canUpdate);
}
