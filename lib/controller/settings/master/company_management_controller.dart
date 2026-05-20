import '../../../screen.dart';

class CompanyManagementController extends GetxController {
  static const List<AppDropdownItem<String>> companyTypeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'private_limited', label: 'Private Limited'),
        AppDropdownItem(value: 'proprietorship', label: 'Proprietorship'),
        AppDropdownItem(value: 'partnership', label: 'Partnership'),
        AppDropdownItem(value: 'llp', label: 'LLP'),
        AppDropdownItem(value: 'public_limited', label: 'Public Limited'),
        AppDropdownItem(value: 'trust', label: 'Trust'),
        AppDropdownItem(value: 'society', label: 'Society'),
        AppDropdownItem(value: 'other', label: 'Other'),
      ];

  CompanyManagementController({required this.initialTabIndex});

  final MasterService _masterService = MasterService();
  final int initialTabIndex;

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController legalNameController = TextEditingController();
  final TextEditingController tradeNameController = TextEditingController();
  final TextEditingController gstinController = TextEditingController();
  final TextEditingController panController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController currencyController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<CompanyModel> companies = const <CompanyModel>[];
  List<CompanyModel> filteredCompanies = const <CompanyModel>[];
  CompanyModel? selectedCompany;
  bool isActive = true;
  String companyType = 'private_limited';
  int activeTabIndex = 0;

  @override
  void onInit() {
    super.onInit();
    activeTabIndex = initialTabIndex.clamp(0, 1);
    searchController.addListener(_applySearch);
    loadCompanies();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    codeController.dispose();
    legalNameController.dispose();
    tradeNameController.dispose();
    gstinController.dispose();
    panController.dispose();
    phoneController.dispose();
    emailController.dispose();
    websiteController.dispose();
    cityController.dispose();
    stateController.dispose();
    currencyController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  Future<void> loadCompanies({int? selectId}) async {
    initialLoading = companies.isEmpty;
    pageError = null;
    update();

    try {
      final response = await _masterService.companies(
        filters: const {'per_page': 100, 'sort_by': 'legal_name'},
      );
      final items = response.data ?? const <CompanyModel>[];

      companies = items;
      filteredCompanies = _filterCompanies(items, searchController.text);
      initialLoading = false;

      final selected = selectId != null
          ? items.cast<CompanyModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedCompany == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<CompanyModel?>().firstWhere(
                    (item) => item?.id == selectedCompany?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        selectCompany(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (error) {
      initialLoading = false;
      pageError = error.toString();
    }

    update();
  }

  List<CompanyModel> _filterCompanies(List<CompanyModel> source, String query) {
    return filterMasterList(source, query, (company) {
      return [
        company.code ?? '',
        company.legalName ?? '',
        company.tradeName ?? '',
        company.city ?? '',
      ];
    });
  }

  void _applySearch() {
    filteredCompanies = _filterCompanies(companies, searchController.text);
    update();
  }

  void selectCompany(CompanyModel company, {bool notify = true}) {
    selectedCompany = company;
    _setCode(company.code ?? '');
    legalNameController.text = company.legalName ?? '';
    tradeNameController.text = company.tradeName ?? '';
    gstinController.text = company.gstin ?? '';
    panController.text = company.pan ?? '';
    phoneController.text = company.phone ?? '';
    emailController.text = company.email ?? '';
    websiteController.text = company.website ?? '';
    cityController.text = company.city ?? '';
    stateController.text = company.stateName ?? company.stateCode ?? '';
    currencyController.text = company.baseCurrency ?? 'INR';
    remarksController.text = company.remarks ?? '';
    companyType = company.companyType ?? 'private_limited';
    isActive = company.isActive;
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedCompany = null;
    _setCode('');
    legalNameController.clear();
    tradeNameController.clear();
    gstinController.clear();
    panController.clear();
    phoneController.clear();
    emailController.clear();
    websiteController.clear();
    cityController.clear();
    stateController.clear();
    currencyController.text = 'INR';
    remarksController.clear();
    companyType = 'private_limited';
    isActive = true;
    formError = null;
    unawaited(_primeCodeSuggestion());
    if (notify) {
      update();
    }
  }

  bool get isNewCompany => selectedCompany?.id == null;

  void _setCode(String value) {
    codeController.value = codeController.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _primeCodeSuggestion() async {
    if (!isNewCompany) {
      return;
    }

    try {
      final code = await _masterService.nextCompanyCode(prefix: 'CMP');
      if (!isNewCompany) {
        return;
      }
      if (code != null && code.trim().isNotEmpty) {
        _setCode(code.trim());
        update();
      }
    } catch (_) {}
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    saving = true;
    formError = null;
    update();

    final model = CompanyModel(
      id: selectedCompany?.id,
      code: codeController.text.trim(),
      legalName: legalNameController.text.trim(),
      tradeName: nullIfEmpty(tradeNameController.text),
      companyType: companyType,
      gstin: nullIfEmpty(gstinController.text),
      pan: nullIfEmpty(panController.text),
      phone: nullIfEmpty(phoneController.text),
      email: nullIfEmpty(emailController.text),
      website: nullIfEmpty(websiteController.text),
      city: nullIfEmpty(cityController.text),
      stateName: nullIfEmpty(stateController.text),
      baseCurrency: nullIfEmpty(currencyController.text) ?? 'INR',
      remarks: nullIfEmpty(remarksController.text),
      isActive: isActive,
    );

    try {
      final response = selectedCompany == null
          ? await _masterService.createCompany(model)
          : await _masterService.updateCompany(selectedCompany!.id!, model);
      final saved = response.data;
      if (saved == null) {
        formError = response.message;
        update();
        return;
      }

      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadCompanies(selectId: saved.id);
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  void startNewCompany({required bool isDesktop}) {
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }

  void setCompanyType(String? value) {
    companyType = value ?? companyType;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  void setActiveTabIndex(int index) {
    activeTabIndex = index;
    update();
  }
}
