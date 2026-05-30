import '../../screen.dart';
import '../../helper/hr_register_reload_helper.dart';

class DepartmentManagementController extends GetxController {
  DepartmentManagementController();

  final HrService _hrService = HrService();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<DepartmentModel> departments = const <DepartmentModel>[];
  List<DepartmentModel> filteredDepartments = const <DepartmentModel>[];
  List<EmployeeModel> employees = const <EmployeeModel>[];
  DepartmentModel? selectedDepartment;
  bool isActive = true;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    loadDepartments();
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

  Future<void> loadDepartments({int? selectId}) async {
    initialLoading = departments.isEmpty;
    pageError = null;
    update();

    try {
      final responses = await Future.wait<dynamic>([
        _hrService.departments(
          filters: const {'per_page': 200, 'sort_by': 'department_name'},
        ),
        _hrService.employees(
          filters: const {'per_page': 300, 'sort_by': 'employee_name'},
        ),
      ]);
      final items =
          (responses[0] as PaginatedResponse<DepartmentModel>).data ??
          const <DepartmentModel>[];
      final employeeItems =
          (responses[1] as PaginatedResponse<EmployeeModel>).data ??
          const <EmployeeModel>[];

      departments = items;
      employees = employeeItems;
      filteredDepartments = _filterDepartments(items, searchController.text);
      initialLoading = false;

      final selected = selectId != null
          ? items.cast<DepartmentModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedDepartment == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<DepartmentModel?>().firstWhere(
                    (item) => item?.id == selectedDepartment?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        selectDepartment(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (error) {
      pageError = error.toString();
      initialLoading = false;
    }

    update();
  }

  List<DepartmentModel> _filterDepartments(
    List<DepartmentModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (item) {
      return [item.departmentName ?? ''];
    });
  }

  void _applySearch() {
    filteredDepartments = _filterDepartments(
      departments,
      searchController.text,
    );
    update();
  }

  void selectDepartment(DepartmentModel item, {bool notify = true}) {
    selectedDepartment = item;
    nameController.text = item.departmentName ?? '';
    isActive = item.isActive;
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedDepartment = null;
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

  List<EmployeeModel> get departmentEmployees {
    final departmentId = selectedDepartment?.id;
    if (departmentId == null) {
      return const <EmployeeModel>[];
    }

    return employees
        .where((item) => item.departmentId == departmentId)
        .toList(growable: false);
  }

  Future<void> save({FormState? formState}) async {
    final form = formState;
    if (form == null || !form.validate()) {
      return;
    }

    saving = true;
    formError = null;
    update();

    final model = DepartmentModel(
      id: selectedDepartment?.id,
      departmentName: nameController.text.trim(),
      isActive: isActive,
    );

    try {
      final response = selectedDepartment == null
          ? await _hrService.createDepartment(model)
          : await _hrService.updateDepartment(selectedDepartment!.id!, model);
      final saved = response.data;
      if (saved == null) {
        formError = response.message;
        update();
        return;
      }

      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadDepartments(selectId: saved.id);
      reloadAttendanceRegister();
      reloadPayrollRunRegister();
      reloadPayslipRegister();
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> delete() async {
    final id = selectedDepartment?.id;
    if (id == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _hrService.deleteDepartment(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadDepartments();
      reloadAttendanceRegister();
      reloadPayrollRunRegister();
      reloadPayslipRegister();
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }
}
