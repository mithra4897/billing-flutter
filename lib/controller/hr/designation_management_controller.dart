import '../../screen.dart';

class DesignationManagementController extends GetxController {
  DesignationManagementController();

  final HrService _hrService = HrService();

  final ScrollController pageScrollController = ScrollController();
  final GlobalKey<FormState> designationFormKey = GlobalKey<FormState>();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<DesignationModel> designations = const <DesignationModel>[];
  List<DesignationModel> filteredDesignations = const <DesignationModel>[];
  List<EmployeeModel> employees = const <EmployeeModel>[];
  DesignationModel? selectedDesignation;
  bool isActive = true;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    loadDesignations();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    nameController.dispose();
    super.onClose();
  }

  Future<void> loadDesignations({int? selectId}) async {
    initialLoading = designations.isEmpty;
    pageError = null;
    update();

    try {
      final responses = await Future.wait<dynamic>([
        _hrService.designations(
          filters: const {'per_page': 200, 'sort_by': 'designation_name'},
        ),
        _hrService.employees(
          filters: const {'per_page': 300, 'sort_by': 'employee_name'},
        ),
      ]);
      final items =
          (responses[0] as PaginatedResponse<DesignationModel>).data ??
          const <DesignationModel>[];
      final employeeItems =
          (responses[1] as PaginatedResponse<EmployeeModel>).data ??
          const <EmployeeModel>[];

      designations = items;
      employees = employeeItems;
      filteredDesignations = _filterDesignations(items, searchController.text);
      initialLoading = false;

      final selected = selectId != null
          ? items.cast<DesignationModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedDesignation == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<DesignationModel?>().firstWhere(
                    (item) => item?.id == selectedDesignation?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        selectDesignation(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (error) {
      pageError = error.toString();
      initialLoading = false;
    }

    update();
  }

  List<DesignationModel> _filterDesignations(
    List<DesignationModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (item) {
      return [item.designationName ?? ''];
    });
  }

  void _applySearch() {
    filteredDesignations = _filterDesignations(
      designations,
      searchController.text,
    );
    update();
  }

  void selectDesignation(DesignationModel item, {bool notify = true}) {
    selectedDesignation = item;
    nameController.text = item.designationName ?? '';
    isActive = item.isActive;
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedDesignation = null;
    nameController.clear();
    isActive = true;
    formError = null;
    if (notify) {
      update();
    }
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

  List<EmployeeModel> get designationEmployees {
    final designationId = selectedDesignation?.id;
    if (designationId == null) {
      return const <EmployeeModel>[];
    }

    return employees
        .where((item) => item.designationId == designationId)
        .toList(growable: false);
  }

  Future<void> save() async {
    final form = designationFormKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    saving = true;
    formError = null;
    update();

    final model = DesignationModel(
      id: selectedDesignation?.id,
      designationName: nameController.text.trim(),
      isActive: isActive,
    );

    try {
      final response = selectedDesignation == null
          ? await _hrService.createDesignation(model)
          : await _hrService.updateDesignation(selectedDesignation!.id!, model);
      final saved = response.data;
      if (saved == null) {
        formError = response.message;
        update();
        return;
      }

      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadDesignations(selectId: saved.id);
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> delete() async {
    final id = selectedDesignation?.id;
    if (id == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _hrService.deleteDesignation(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadDesignations();
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }
}
