import '../../screen.dart';
import 'project_module_refresh_controller.dart';

class ProjectVendorWorkManagementController extends GetxController {
  ProjectVendorWorkManagementController();

  final ProjectService _projectService = ProjectService();
  final PartiesService _partiesService = PartiesService();
  final PurchaseService _purchaseService = PurchaseService();
  final MasterService _masterService = MasterService();
  final ProjectModuleRefreshController _refreshController =
      ProjectModuleRefreshController.ensureRegistered();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController voucherIdController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  int? filterProjectId;
  int? filterTaskId;
  int? filterVendorPartyId;
  int? projectId;
  int? taskId;
  int? vendorPartyId;
  int? purchaseOrderId;
  int? purchaseInvoiceId;
  String status = 'open';
  Worker? _refreshWorker;

  List<ProjectModel> projects = const <ProjectModel>[];
  List<PartyModel> parties = const <PartyModel>[];
  List<PurchaseOrderModel> purchaseOrders = const <PurchaseOrderModel>[];
  List<PurchaseInvoiceModel> purchaseInvoices = const <PurchaseInvoiceModel>[];
  List<ProjectVendorWorkRow> rows = const <ProjectVendorWorkRow>[];
  List<ProjectVendorWorkRow> filteredRows = const <ProjectVendorWorkRow>[];
  ProjectVendorWorkRow? selectedRow;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applyFilters);
    _refreshWorker = ever<ProjectModuleRefreshEvent?>(
      _refreshController.lastEvent,
      (event) {
        if (event == null || event.source == 'project_vendor_work') {
          return;
        }
        unawaited(loadData(selectId: selectedRow?.work.id));
      },
    );
    loadData();
  }

  @override
  void onClose() {
    _refreshWorker?.dispose();
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applyFilters)
      ..dispose();
    descriptionController.dispose();
    amountController.dispose();
    voucherIdController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  Future<void> loadData({int? selectId}) async {
    initialLoading = rows.isEmpty;
    pageError = null;
    update();
    try {
      final responses = await Future.wait<dynamic>([
        _projectService.projects(
          filters: const {'per_page': 200, 'sort_by': 'project_name'},
        ),
        _partiesService.parties(
          filters: const {'per_page': 300, 'sort_by': 'display_name'},
        ),
        _purchaseService.orders(
          filters: const {'per_page': 300, 'sort_by': 'order_date'},
        ),
        _purchaseService.invoices(
          filters: const {'per_page': 300, 'sort_by': 'invoice_date'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
      ]);
      final nextProjects =
          (responses[0] as PaginatedResponse<ProjectModel>).data ??
          const <ProjectModel>[];
      final nextParties =
          (responses[1] as PaginatedResponse<PartyModel>).data ??
          const <PartyModel>[];
      final nextPurchaseOrders =
          (responses[2] as PaginatedResponse<PurchaseOrderModel>).data ??
          const <PurchaseOrderModel>[];
      final nextPurchaseInvoices =
          (responses[3] as PaginatedResponse<PurchaseInvoiceModel>).data ??
          const <PurchaseInvoiceModel>[];
      final companies =
          (responses[4] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final activeCompanies = companies.where((item) => item.isActive).toList();
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );
      final scopedProjects = contextSelection.companyId == null
          ? nextProjects
          : nextProjects
                .where((item) => item.companyId == contextSelection.companyId)
                .toList(growable: false);
      final nextRows = scopedProjects
          .expand(
            (project) => project.vendorWorks.map(
              (work) => ProjectVendorWorkRow(project: project, work: work),
            ),
          )
          .toList(growable: false);

      projects = scopedProjects;
      parties = nextParties
          .where((item) => item.isActive)
          .toList(growable: false);
      purchaseOrders = nextPurchaseOrders;
      purchaseInvoices = nextPurchaseInvoices;
      rows = nextRows;
      filteredRows = filterRows(nextRows);
      initialLoading = false;
      update();

      final selected = selectId == null
          ? null
          : nextRows.cast<ProjectVendorWorkRow?>().firstWhere(
              (item) => item?.work.id == selectId,
              orElse: () => null,
            );
      if (selected != null) {
        selectRow(selected, notify: false);
      } else if (filteredRows.isNotEmpty) {
        selectRow(filteredRows.first, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (errorValue) {
      pageError = errorValue.toString();
      initialLoading = false;
      update();
    }
  }

  List<ProjectVendorWorkRow> filterRows(List<ProjectVendorWorkRow> items) {
    final scoped = items
        .where((row) {
          if (filterProjectId != null && row.project.id != filterProjectId) {
            return false;
          }
          if (filterTaskId != null && row.work.projectTaskId != filterTaskId) {
            return false;
          }
          if (filterVendorPartyId != null &&
              row.work.vendorPartyId != filterVendorPartyId) {
            return false;
          }
          return true;
        })
        .toList(growable: false);

    return filterMasterList(scoped, searchController.text, (row) {
      return [
        row.project.projectName ?? '',
        taskName(row.project, row.work.projectTaskId),
        partyName(row.work.vendorPartyId),
        row.work.workStatus ?? '',
        row.work.workDescription ?? '',
      ];
    });
  }

  void _applyFilters() {
    filteredRows = filterRows(rows);
    update();
  }

  void applyFilters() {
    _applyFilters();
  }

  void selectRow(ProjectVendorWorkRow row, {bool notify = true}) {
    selectedRow = row;
    projectId = row.project.id;
    taskId = row.work.projectTaskId;
    vendorPartyId = row.work.vendorPartyId;
    purchaseOrderId = row.work.purchaseOrderId;
    purchaseInvoiceId = row.work.purchaseInvoiceId;
    descriptionController.text = row.work.workDescription ?? '';
    amountController.text = decimalText(row.work.amount);
    voucherIdController.text = row.work.voucherId?.toString() ?? '';
    remarksController.text = row.work.remarks ?? '';
    status = row.work.workStatus ?? 'open';
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedRow = null;
    projectId = projects.isNotEmpty ? projects.first.id : null;
    taskId = null;
    vendorPartyId = null;
    purchaseOrderId = null;
    purchaseInvoiceId = null;
    descriptionController.clear();
    amountController.clear();
    voucherIdController.clear();
    remarksController.clear();
    status = 'open';
    formError = null;
    if (notify) {
      update();
    }
  }

  List<AppDropdownItem<int>> get projectItems => projects
      .map(
        (item) => AppDropdownItem<int>(
          value: item.id ?? 0,
          label: item.projectName ?? item.projectCode ?? 'Project',
        ),
      )
      .where((item) => item.value != 0)
      .toList(growable: false);

  List<AppDropdownItem<int>> get taskItems {
    final project = projects.cast<ProjectModel?>().firstWhere(
      (item) => item?.id == projectId,
      orElse: () => null,
    );
    return (project?.tasks ?? const <ProjectTaskModel>[])
        .map(
          (item) => AppDropdownItem<int>(
            value: item.id ?? 0,
            label: item.taskName ?? item.taskCode ?? 'Task',
          ),
        )
        .where((item) => item.value != 0)
        .toList(growable: false);
  }

  List<AppDropdownItem<int>> get partyItems => parties
      .map(
        (item) =>
            AppDropdownItem<int>(value: item.id ?? 0, label: item.toString()),
      )
      .where((item) => item.value != 0)
      .toList(growable: false);

  List<AppDropdownItem<int>> get purchaseOrderItems => purchaseOrders
      .map(
        (item) => AppDropdownItem<int>(
          value: item.id ?? 0,
          label: item.orderNo?.trim().isNotEmpty == true
              ? item.orderNo!
              : 'Order #${item.id}',
        ),
      )
      .where((item) => item.value != 0)
      .toList(growable: false);

  List<AppDropdownItem<int>> get purchaseInvoiceItems => purchaseInvoices
      .where((item) => item.id != null)
      .map(
        (item) => AppDropdownItem<int>(
          value: item.id!,
          label: item.invoiceNo?.trim().isNotEmpty == true
              ? item.invoiceNo!
              : 'Invoice #${item.id}',
        ),
      )
      .where((item) => item.value != 0)
      .toList(growable: false);

  String partyName(int? id) {
    return parties
            .cast<PartyModel?>()
            .firstWhere((item) => item?.id == id, orElse: () => null)
            ?.toString() ??
        '';
  }

  String taskName(ProjectModel project, int? id) {
    return project.tasks
            .cast<ProjectTaskModel?>()
            .firstWhere((item) => item?.id == id, orElse: () => null)
            ?.taskName ??
        project.tasks
            .cast<ProjectTaskModel?>()
            .firstWhere((item) => item?.id == id, orElse: () => null)
            ?.taskCode ??
        '';
  }

  List<AppDropdownItem<int>> get filterProjectItems => projects
      .map(
        (item) => AppDropdownItem<int>(
          value: item.id ?? 0,
          label: item.projectName ?? item.projectCode ?? 'Project',
        ),
      )
      .where((item) => item.value != 0)
      .toList(growable: false);

  List<AppDropdownItem<int>> get filterTaskItems {
    final project = projects.cast<ProjectModel?>().firstWhere(
      (item) => item?.id == filterProjectId,
      orElse: () => null,
    );
    final source = project == null
        ? projects.expand((item) => item.tasks).toList(growable: false)
        : project.tasks;
    return source
        .map(
          (item) => AppDropdownItem<int>(
            value: item.id ?? 0,
            label: item.taskName ?? item.taskCode ?? 'Task',
          ),
        )
        .where((item) => item.value != 0)
        .toList(growable: false);
  }

  void setFilterProjectId(int? value) {
    filterProjectId = value;
    final taskExists = filterTaskItems.any(
      (item) => item.value == filterTaskId,
    );
    if (!taskExists) {
      filterTaskId = null;
    }
    update();
  }

  void setFilterTaskId(int? value) {
    filterTaskId = value;
    update();
  }

  void setFilterVendorPartyId(int? value) {
    filterVendorPartyId = value;
    update();
  }

  void clearFilters() {
    searchController.clear();
    filterProjectId = null;
    filterTaskId = null;
    filterVendorPartyId = null;
    _applyFilters();
  }

  void setProjectId(int? value) {
    projectId = value;
    taskId = null;
    update();
  }

  void setTaskId(int? value) {
    taskId = value;
    update();
  }

  void setVendorPartyId(int? value) {
    vendorPartyId = value;
    update();
  }

  void setPurchaseOrderId(int? value) {
    purchaseOrderId = value;
    update();
  }

  void setPurchaseInvoiceId(int? value) {
    purchaseInvoiceId = value;
    update();
  }

  void setStatus(String value) {
    status = value;
    update();
  }

  int? intValue(String text) => int.tryParse(text.trim());

  double? doubleValue(String text) => double.tryParse(text.trim());

  String decimalText(double? value) => value == null
      ? ''
      : (value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toString());

  Future<String?> saveVendorWork() async {
    if (!formKey.currentState!.validate()) {
      return null;
    }
    final resolvedProjectId = projectId;
    if (resolvedProjectId == null) {
      formError = 'Project is required.';
      update();
      return null;
    }
    saving = true;
    formError = null;
    update();
    try {
      final model = ProjectVendorWorkModel(
        id: selectedRow?.work.id,
        projectId: resolvedProjectId,
        projectTaskId: taskId,
        vendorPartyId: vendorPartyId,
        purchaseOrderId: purchaseOrderId,
        purchaseInvoiceId: purchaseInvoiceId,
        workDescription: descriptionController.text.trim(),
        amount: doubleValue(amountController.text),
        voucherId: intValue(voucherIdController.text),
        workStatus: status,
        remarks: nullIfEmpty(remarksController.text),
      );
      final response = selectedRow?.work.id == null
          ? await _projectService.createVendorWork(resolvedProjectId, model)
          : await _projectService.updateVendorWork(
              selectedRow!.work.id!,
              model,
            );
      await loadData(selectId: response.data?.id ?? selectedRow?.work.id);
      _refreshController.notifyChanged(source: 'project_vendor_work');
      return response.message;
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
      return null;
    } finally {
      saving = false;
      update();
    }
  }

  Future<String?> deleteVendorWork() async {
    final row = selectedRow;
    if (row?.work.id == null) {
      return null;
    }
    final response = await _projectService.deleteVendorWork(row!.work.id!);
    await loadData();
    _refreshController.notifyChanged(source: 'project_vendor_work');
    return response.message;
  }

  void startNewVendorWork({required bool isDesktop}) {
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }
}

class ProjectVendorWorkRow {
  const ProjectVendorWorkRow({required this.project, required this.work});

  final ProjectModel project;
  final ProjectVendorWorkModel work;
}
