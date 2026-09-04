import '../../screen.dart';
import 'project_module_refresh_controller.dart';

class ProjectExpenseManagementController extends GetxController {
  ProjectExpenseManagementController({
    this.constrainedProjectId,
    this.initialRecordId,
    this.startWithNewRecord = false,
  });

  final int? initialRecordId;
  final bool startWithNewRecord;

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
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();
  Set<String> selectedStatuses = const <String>{};
  final TextEditingController expenseDateController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController voucherIdController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  bool showDraftTile = false;
  String? pageError;
  String? formError;
  int? constrainedProjectId;
  int? projectId;
  int? taskId;
  int? supplierPartyId;
  int? purchaseInvoiceId;
  String status = 'draft';
  Worker? _refreshWorker;

  List<ProjectModel> projects = const <ProjectModel>[];
  List<PartyModel> parties = const <PartyModel>[];
  List<PurchaseInvoiceModel> purchaseInvoices = const <PurchaseInvoiceModel>[];
  List<ProjectExpenseRow> rows = const <ProjectExpenseRow>[];
  List<ProjectExpenseRow> filteredRows = const <ProjectExpenseRow>[];
  ProjectExpenseRow? selectedRow;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applyFilters);
    dateFromController.addListener(_applyFilters);
    dateToController.addListener(_applyFilters);
    _refreshWorker = ever<ProjectModuleRefreshEvent?>(
      _refreshController.lastEvent,
      (event) {
        if (event == null || event.source == 'project_expense') {
          return;
        }
        unawaited(loadData(selectId: selectedRow?.expense.id));
      },
    );
    unawaited(_loadInitialData());
  }

  Future<void> _loadInitialData() async {
    await loadData(selectId: initialRecordId);
    if (!isClosed && startWithNewRecord) {
      resetForm();
    }
  }

  @override
  void onClose() {
    _refreshWorker?.dispose();
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applyFilters)
      ..dispose();
    dateFromController
      ..removeListener(_applyFilters)
      ..dispose();
    dateToController
      ..removeListener(_applyFilters)
      ..dispose();
    expenseDateController.dispose();
    categoryController.dispose();
    descriptionController.dispose();
    amountController.dispose();
    voucherIdController.dispose();
    remarksController.dispose();
    super.onClose();
  }

  bool get isProjectConstrained => constrainedProjectId != null;

  Future<void> applyProjectConstraint(int? value) async {
    if (constrainedProjectId == value) {
      return;
    }
    constrainedProjectId = value;
    await loadData();
  }

  Future<void> loadData({int? selectId}) async {
    initialLoading = rows.isEmpty;
    pageError = null;
    update();
    try {
      final responses = await Future.wait<dynamic>([
        _refreshController.projects(loader: _projectService.projects),
        _partiesService.parties(
          filters: const {'per_page': 300, 'sort_by': 'display_name'},
        ),
        _purchaseService.invoices(
          filters: const {'per_page': 300, 'sort_by': 'invoice_date'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
      ]);
      final nextProjects = responses[0] as List<ProjectModel>;
      final nextParties =
          (responses[1] as PaginatedResponse<PartyModel>).data ??
          const <PartyModel>[];
      final nextPurchaseInvoices =
          (responses[2] as PaginatedResponse<PurchaseInvoiceModel>).data ??
          const <PurchaseInvoiceModel>[];
      final companies =
          (responses[3] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final activeCompanies = companies.where((item) => item.isActive).toList();
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );
      var scopedProjects = contextSelection.companyId == null
          ? nextProjects
          : nextProjects
                .where((item) => item.companyId == contextSelection.companyId)
                .toList(growable: false);
      if (constrainedProjectId != null) {
        scopedProjects = scopedProjects
            .where((item) => item.id == constrainedProjectId)
            .toList(growable: false);
      }
      final nextRows = scopedProjects
          .expand(
            (project) => project.expenses.map(
              (expense) =>
                  ProjectExpenseRow(project: project, expense: expense),
            ),
          )
          .toList(growable: false);

      projects = scopedProjects;
      parties = nextParties
          .where((item) => item.isActive)
          .toList(growable: false);
      purchaseInvoices = nextPurchaseInvoices;
      rows = nextRows;
      filteredRows = _filterRows(nextRows);
      initialLoading = false;
      update();

      final selected = selectId == null
          ? null
          : nextRows.cast<ProjectExpenseRow?>().firstWhere(
              (item) => item?.expense.id == selectId,
              orElse: () => null,
            );
      if (selected != null) {
        selectRow(selected, notify: false);
      } else {
        if (!isProjectConstrained && filteredRows.isNotEmpty) {
          selectRow(filteredRows.first, notify: false);
        } else {
          resetForm(notify: false);
        }
      }
    } catch (errorValue) {
      pageError = errorValue.toString();
      initialLoading = false;
      update();
    }
  }

  List<ProjectExpenseRow> _filterRows(List<ProjectExpenseRow> items) {
    var result = filterMasterList(items, searchController.text, (row) {
      return [
        row.expense.expenseCategory ?? '',
        row.project.projectName ?? '',
        row.expense.expenseDate ?? '',
        row.expense.expenseStatus ?? '',
      ];
    });
    if (selectedStatuses.isNotEmpty) {
      result = result
          .where(
            (row) => selectedStatuses.contains(row.expense.expenseStatus ?? ''),
          )
          .toList(growable: false);
    }
    final from = dateFromController.text.trim();
    final to = dateToController.text.trim();
    if (from.isNotEmpty) {
      result = result
          .where((row) => (row.expense.expenseDate ?? '').compareTo(from) >= 0)
          .toList(growable: false);
    }
    if (to.isNotEmpty) {
      result = result
          .where((row) => (row.expense.expenseDate ?? '').compareTo(to) <= 0)
          .toList(growable: false);
    }
    return result;
  }

  void _applyFilters() {
    filteredRows = _filterRows(rows);
    update();
  }

  void setStatuses(Set<String> values) {
    selectedStatuses = values;
    _applyFilters();
  }

  void clearFilters() {
    dateFromController.clear();
    dateToController.clear();
    selectedStatuses = const <String>{};
    _applyFilters();
  }

  void selectRow(ProjectExpenseRow row, {bool notify = true}) {
    if (selectedRow?.expense.id == row.expense.id) {
      resetForm(notify: notify);
      return;
    }
    showDraftTile = false;
    selectedRow = row;
    projectId = row.project.id;
    taskId = row.expense.projectTaskId;
    supplierPartyId = row.expense.supplierPartyId;
    purchaseInvoiceId = row.expense.purchaseInvoiceId;
    expenseDateController.text = normalizeDateValue(row.expense.expenseDate);
    categoryController.text = row.expense.expenseCategory ?? '';
    descriptionController.text = row.expense.description ?? '';
    amountController.text = decimalText(row.expense.amount);
    voucherIdController.text = row.expense.voucherId?.toString() ?? '';
    remarksController.text = row.expense.remarks ?? '';
    status = row.expense.expenseStatus ?? 'draft';
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedRow = null;
    projectId =
        constrainedProjectId ??
        (projects.isNotEmpty ? projects.first.id : null);
    taskId = null;
    supplierPartyId = null;
    purchaseInvoiceId = null;
    expenseDateController.clear();
    categoryController.clear();
    descriptionController.clear();
    amountController.clear();
    voucherIdController.clear();
    remarksController.clear();
    status = 'draft';
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

  PurchaseInvoiceModel? purchaseInvoiceById(int? id) {
    return purchaseInvoices.cast<PurchaseInvoiceModel?>().firstWhere(
      (item) => item?.id == id,
      orElse: () => null,
    );
  }

  String? purchaseInvoiceLabel(int? id) {
    final invoice = purchaseInvoiceById(id);
    if (invoice == null) {
      return null;
    }
    return invoice.invoiceNo?.trim().isNotEmpty == true
        ? invoice.invoiceNo
        : 'Invoice #${invoice.id}';
  }

  void applyPurchaseInvoice(int? invoiceId) {
    final invoice = purchaseInvoiceById(invoiceId);
    purchaseInvoiceId = invoiceId;
    if (invoice != null) {
      supplierPartyId = invoice.supplierPartyId;
      amountController.text = decimalText(invoice.totalAmount);
    }
    update();
  }

  Future<String?> saveExpense() async {
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
      final model = ProjectExpenseModel(
        id: selectedRow?.expense.id,
        projectId: resolvedProjectId,
        projectTaskId: taskId,
        expenseDate: expenseDateController.text.trim(),
        expenseCategory: categoryController.text.trim(),
        description: descriptionController.text.trim(),
        supplierPartyId: supplierPartyId,
        purchaseInvoiceId: purchaseInvoiceId,
        amount: _doubleValue(amountController.text),
        voucherId: _intValue(voucherIdController.text),
        expenseStatus: status,
        remarks: nullIfEmpty(remarksController.text),
      );
      final response = selectedRow?.expense.id == null
          ? await _projectService.createExpense(resolvedProjectId, model)
          : await _projectService.updateExpense(
              selectedRow!.expense.id!,
              model,
            );
      final savedId = response.data?.id ?? selectedRow?.expense.id;
      showDraftTile = false;
      resetForm(notify: false);
      _refreshController.invalidateProjects();
      await loadData(selectId: savedId);
      _refreshController.notifyChanged(source: 'project_expense');
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

  Future<String?> deleteExpense() async {
    final row = selectedRow;
    if (row?.expense.id == null) {
      return null;
    }
    try {
      final response = await _projectService.deleteExpense(row!.expense.id!);
      formError = null;
      _refreshController.invalidateProjects();
      await loadData();
      _refreshController.notifyChanged(source: 'project_expense');
      return response.message;
    } on ApiException catch (errorValue) {
      formError = errorValue.displayMessage;
      update();
      return errorValue.displayMessage;
    } catch (errorValue) {
      formError = errorValue.toString();
      update();
      return formError;
    }
  }

  void setProjectId(int? value) {
    if (isProjectConstrained) {
      projectId = constrainedProjectId;
      taskId = null;
      update();
      return;
    }
    projectId = value;
    taskId = null;
    update();
  }

  void setTaskId(int? value) {
    taskId = value;
    update();
  }

  void setSupplierPartyId(int? value) {
    supplierPartyId = value;
    update();
  }

  void clearFormError() {
    if ((formError ?? '').isEmpty) {
      return;
    }
    formError = null;
    update();
  }

  void setStatus(String value) {
    status = value;
    update();
  }

  void startNewExpense({required bool isDesktop}) {
    showDraftTile = true;
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }

  void hideDraftTile() {
    showDraftTile = false;
    resetForm();
    update();
  }

  double? _doubleValue(String text) => Validators.parseFlexibleNumber(text);

  int? _intValue(String text) => int.tryParse(text.trim());

  String decimalText(double? value) => value == null
      ? ''
      : (value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toString());
}

class ProjectExpenseRow {
  const ProjectExpenseRow({required this.project, required this.expense});

  final ProjectModel project;
  final ProjectExpenseModel expense;
}
