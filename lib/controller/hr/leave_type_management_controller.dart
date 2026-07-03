import '../../screen.dart';
import 'hr_module_refresh_controller.dart';

class LeaveTypeManagementController extends GetxController {
  LeaveTypeManagementController();

  final HrService _hrService = HrService();
  final HrModuleRefreshController _refreshController =
      HrModuleRefreshController.ensureRegistered();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController leaveNameController = TextEditingController();
  final TextEditingController maxDaysController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  bool isPaid = true;
  List<LeaveTypeModel> leaveTypes = const <LeaveTypeModel>[];
  List<LeaveTypeModel> filteredLeaveTypes = const <LeaveTypeModel>[];
  LeaveTypeModel? selectedLeaveType;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    loadLeaveTypes();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    leaveNameController.dispose();
    maxDaysController.dispose();
    super.onClose();
  }

  Future<void> loadLeaveTypes({int? selectId}) async {
    initialLoading = leaveTypes.isEmpty;
    pageError = null;
    update();

    try {
      final response = await _hrService.leaveTypes(
        filters: const {'per_page': 200, 'sort_by': 'leave_name'},
      );
      final items = response.data ?? const <LeaveTypeModel>[];

      leaveTypes = items;
      filteredLeaveTypes = _filterLeaveTypes(items, searchController.text);
      initialLoading = false;

      final selected = selectId != null
          ? items.cast<LeaveTypeModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedLeaveType == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<LeaveTypeModel?>().firstWhere(
                    (item) => item?.id == selectedLeaveType?.id,
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected != null) {
        selectLeaveType(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (errorValue) {
      pageError = errorValue.toString();
      initialLoading = false;
    }

    update();
  }

  List<LeaveTypeModel> _filterLeaveTypes(
    List<LeaveTypeModel> source,
    String query,
  ) {
    return filterMasterList(source, query, (item) {
      return [item.leaveName ?? '', item.maxDaysPerYear?.toString() ?? ''];
    });
  }

  void _applySearch() {
    filteredLeaveTypes = _filterLeaveTypes(leaveTypes, searchController.text);
    update();
  }

  void selectLeaveType(LeaveTypeModel item, {bool notify = true}) {
    selectedLeaveType = item;
    leaveNameController.text = item.leaveName ?? '';
    maxDaysController.text = item.maxDaysPerYear == null
        ? ''
        : (item.maxDaysPerYear! % 1 == 0
              ? item.maxDaysPerYear!.toStringAsFixed(0)
              : item.maxDaysPerYear!.toStringAsFixed(2));
    isPaid = item.isPaid;
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedLeaveType = null;
    leaveNameController.clear();
    maxDaysController.clear();
    isPaid = true;
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

  void setIsPaid(bool value) {
    isPaid = value;
    update();
  }

  Future<void> save({FormState? formState}) async {
    final form = formState;
    if (form == null || !form.validate()) {
      return;
    }

    saving = true;
    formError = null;
    update();

    final model = LeaveTypeModel(
      id: selectedLeaveType?.id,
      leaveName: leaveNameController.text.trim(),
      maxDaysPerYear: Validators.parseFlexibleNumber(maxDaysController.text),
      isPaid: isPaid,
    );

    try {
      final response = selectedLeaveType == null
          ? await _hrService.createLeaveType(model)
          : await _hrService.updateLeaveType(selectedLeaveType!.id!, model);
      final saved = response.data;
      if (saved == null) {
        formError = response.message;
        update();
        return;
      }

      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadLeaveTypes(selectId: saved.id);
      _refreshController.notifyChanged(source: 'leave_type_management');
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> delete() async {
    final id = selectedLeaveType?.id;
    if (id == null) {
      return;
    }

    saving = true;
    formError = null;
    update();

    try {
      final response = await _hrService.deleteLeaveType(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadLeaveTypes();
      _refreshController.notifyChanged(source: 'leave_type_management');
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }
}
