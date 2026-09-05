import '../../screen.dart';
import 'hr_module_refresh_controller.dart';

class GlobalSalaryComponentController extends GetxController {
  GlobalSalaryComponentController();

  final HrService _hrService = HrService();
  final HrModuleRefreshController _refreshController =
      HrModuleRefreshController.ensureRegistered();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();

  // ─── Form field controllers ───────────────────────────────────────────────
  final TextEditingController nameController = TextEditingController();
  final TextEditingController percentController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController sortOrderController = TextEditingController();

  // ─── Page state ───────────────────────────────────────────────────────────
  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;

  List<GlobalSalaryComponentModel> components =
      const <GlobalSalaryComponentModel>[];
  List<GlobalSalaryComponentModel> filteredComponents =
      const <GlobalSalaryComponentModel>[];
  GlobalSalaryComponentModel? selectedComponent;
  PaginationMeta? paginationMeta;

  // ─── Form values ─────────────────────────────────────────────────────────
  String componentType = 'earning';
  String componentRole = 'standard';
  String calculationBasis = 'fixed';
  String contributionRole = 'employee';
  bool isActive = true;

  // ─── Dropdown metadata lists ──────────────────────────────────────────────
  List<CompanyModel> companies = const <CompanyModel>[];
  int? selectedCompanyId;

  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_scheduleReload);
    unawaited(_loadCompanyAndComponents());
  }

  Future<void> _loadCompanyAndComponents() async {
    final info = await hrSessionCompanyInfo();
    selectedCompanyId = info.companyId;
    if (selectedCompanyId == null) {
      initialLoading = false;
      pageError =
          'Select a company in the session header to manage salary components.';
      update();
      return;
    }
    await loadComponents();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_scheduleReload)
      ..dispose();
    nameController.dispose();
    percentController.dispose();
    amountController.dispose();
    sortOrderController.dispose();
    _searchDebounce?.cancel();
    super.onClose();
  }

  // ─── Data Loading ─────────────────────────────────────────────────────────

  Future<void> loadComponents({int? selectId, int page = 1}) async {
    _searchDebounce?.cancel();
    initialLoading = components.isEmpty;
    pageError = null;
    update();

    try {
      final response = await _hrService.globalSalaryComponents(
        filters: {
          'page': page,
          'per_page': 200,
          'sort_by': 'sort_order',
          'sort_order': 'asc',
          if (searchController.text.trim().isNotEmpty)
            'search': searchController.text.trim(),
          if (selectedCompanyId != null) 'company_id': selectedCompanyId,
        },
      );

      final items = response.data ?? const <GlobalSalaryComponentModel>[];
      components = items;
      paginationMeta = response.meta;
      filteredComponents = items;
      initialLoading = false;

      final selected = selectId != null
          ? items.cast<GlobalSalaryComponentModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedComponent == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<GlobalSalaryComponentModel?>().firstWhere(
                    (item) => item?.id == selectedComponent?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        selectComponent(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (error) {
      pageError = error.toString();
      initialLoading = false;
    }

    update();
  }

  void _scheduleReload() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 450),
      () => unawaited(loadComponents(page: 1)),
    );
  }

  void goToPage(int page) {
    if (page >= 1 && page != paginationMeta?.currentPage) {
      unawaited(loadComponents(page: page));
    }
  }

  // ─── Selection & Form ─────────────────────────────────────────────────────

  void selectComponent(GlobalSalaryComponentModel item, {bool notify = true}) {
    selectedComponent = item;
    nameController.text = item.componentName ?? '';
    componentType = item.componentType ?? 'earning';
    componentRole = item.componentRole ?? 'standard';
    calculationBasis = item.calculationBasis ?? 'fixed';
    contributionRole = item.contributionRole ?? 'employee';
    percentController.text = item.percentValue != null
        ? item.percentValue!.toStringAsFixed(2)
        : '';
    amountController.text = item.amount != null
        ? item.amount!.toStringAsFixed(2)
        : '';
    sortOrderController.text = item.sortOrder?.toString() ?? '';
    isActive = item.isActive;
    formError = null;
    if (notify) update();
  }

  void resetForm({bool notify = true}) {
    selectedComponent = null;
    nameController.clear();
    componentType = 'earning';
    componentRole = 'standard';
    calculationBasis = 'fixed';
    contributionRole = 'employee';
    percentController.clear();
    amountController.clear();
    sortOrderController.clear();
    isActive = true;
    formError = null;
    if (notify) update();
  }

  void startNew({required bool isDesktop}) {
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }

  void setComponentType(String value) {
    componentType = value;
    update();
  }

  void setComponentRole(String value) {
    componentRole = value;
    update();
  }

  void setCalculationBasis(String value) {
    calculationBasis = value;
    if (value == 'fixed') percentController.clear();
    update();
  }

  void setContributionRole(String value) {
    contributionRole = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  // ─── Persistence ─────────────────────────────────────────────────────────

  Future<void> save({FormState? formState}) async {
    if (formState == null || !formState.validate()) return;

    saving = true;
    formError = null;
    update();

    final double? parsedPercent = double.tryParse(
      percentController.text.trim(),
    );
    final double? parsedAmount = double.tryParse(amountController.text.trim());
    final int? parsedOrder = int.tryParse(sortOrderController.text.trim());

    final model = GlobalSalaryComponentModel(
      id: selectedComponent?.id,
      companyId: selectedCompanyId,
      componentName: nameController.text.trim(),
      componentType: componentType,
      componentRole: componentRole,
      calculationBasis: calculationBasis,
      percentValue: calculationBasis != 'fixed' ? parsedPercent : null,
      amount: parsedAmount,
      contributionRole: contributionRole,
      sortOrder: parsedOrder,
      isActive: isActive,
    );

    try {
      final response = selectedComponent?.id == null
          ? await _hrService.createGlobalSalaryComponent(model)
          : await _hrService.updateGlobalSalaryComponent(
              selectedComponent!.id!,
              model,
            );

      final saved = response.data;
      if (saved == null) {
        formError = response.message;
        update();
        return;
      }

      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadComponents(selectId: saved.id);
      _refreshController.notifyChanged(source: 'global_salary_component');
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> delete() async {
    final id = selectedComponent?.id;
    if (id == null) return;

    saving = true;
    formError = null;
    update();

    try {
      final response = await _hrService.deleteGlobalSalaryComponent(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadComponents();
      _refreshController.notifyChanged(source: 'global_salary_component');
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }
}
