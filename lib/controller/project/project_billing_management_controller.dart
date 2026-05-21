import '../../screen.dart';

class ProjectBillingManagementController extends GetxController {
  ProjectBillingManagementController();

  final ProjectService _projectService = ProjectService();
  final SalesService _salesService = SalesService();
  final MasterService _masterService = MasterService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController billingDateController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  int? projectId;
  int? milestoneId;
  int? salesInvoiceId;
  String basis = 'fixed';
  String status = 'draft';

  List<ProjectModel> projects = const <ProjectModel>[];
  List<SalesInvoiceModel> salesInvoices = const <SalesInvoiceModel>[];
  List<ProjectBillingRow> rows = const <ProjectBillingRow>[];
  List<ProjectBillingRow> filteredRows = const <ProjectBillingRow>[];
  ProjectBillingRow? selectedRow;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    loadData();
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(_applySearch)
      ..dispose();
    billingDateController.dispose();
    amountController.dispose();
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
        _salesService.invoices(
          filters: const {'per_page': 300, 'sort_by': 'invoice_date'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
      ]);
      final nextProjects =
          (responses[0] as PaginatedResponse<ProjectModel>).data ??
          const <ProjectModel>[];
      final nextSalesInvoices =
          (responses[1] as PaginatedResponse<SalesInvoiceModel>).data ??
          const <SalesInvoiceModel>[];
      final companies =
          (responses[2] as PaginatedResponse<CompanyModel>).data ??
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
            (project) => project.billings.map(
              (billing) => ProjectBillingRow(project: project, billing: billing),
            ),
          )
          .toList(growable: false);

      projects = scopedProjects;
      salesInvoices = nextSalesInvoices;
      rows = nextRows;
      filteredRows = _filterRows(nextRows, searchController.text);
      initialLoading = false;
      update();

      final selected = selectId == null
          ? null
          : nextRows.cast<ProjectBillingRow?>().firstWhere(
              (item) => item?.billing.id == selectId,
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

  List<ProjectBillingRow> _filterRows(
    List<ProjectBillingRow> items,
    String query,
  ) {
    return filterMasterList(items, query, (row) {
      return [
        row.project.projectName ?? '',
        row.billing.billingDate ?? '',
        row.billing.billingBasis ?? '',
        row.billing.billingStatus ?? '',
      ];
    });
  }

  void _applySearch() {
    filteredRows = _filterRows(rows, searchController.text);
    update();
  }

  void selectRow(ProjectBillingRow row, {bool notify = true}) {
    selectedRow = row;
    projectId = row.project.id;
    milestoneId = row.billing.projectMilestoneId;
    salesInvoiceId = row.billing.salesInvoiceId;
    billingDateController.text = row.billing.billingDate ?? '';
    amountController.text = decimalText(row.billing.billingAmount);
    remarksController.text = row.billing.remarks ?? '';
    basis = row.billing.billingBasis ?? 'fixed';
    status = row.billing.billingStatus ?? 'draft';
    formError = null;
    if (notify) update();
  }

  void resetForm({bool notify = true}) {
    selectedRow = null;
    projectId = projects.isNotEmpty ? projects.first.id : null;
    milestoneId = null;
    salesInvoiceId = null;
    billingDateController.clear();
    amountController.clear();
    remarksController.clear();
    basis = 'fixed';
    status = 'draft';
    formError = null;
    if (notify) update();
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

  List<AppDropdownItem<int>> get milestoneItems {
    final project = projects.cast<ProjectModel?>().firstWhere(
      (item) => item?.id == projectId,
      orElse: () => null,
    );
    return (project?.milestones ?? const <ProjectMilestoneModel>[])
        .map(
          (item) => AppDropdownItem<int>(
            value: item.id ?? 0,
            label: item.milestoneName ?? 'Milestone',
          ),
        )
        .where((item) => item.value != 0)
        .toList(growable: false);
  }

  ProjectModel? projectById(int? id) {
    return projects.cast<ProjectModel?>().firstWhere(
      (item) => item?.id == id,
      orElse: () => null,
    );
  }

  SalesInvoiceModel? salesInvoiceById(int? id) {
    return salesInvoices.cast<SalesInvoiceModel?>().firstWhere(
      (item) => item?.id == id,
      orElse: () => null,
    );
  }

  String? salesInvoiceLabel(int? id) {
    final invoice = salesInvoiceById(id);
    if (invoice == null) return null;
    final invoiceNo = invoice.invoiceNo?.trim();
    if ((invoiceNo ?? '').isNotEmpty) return invoiceNo;
    return 'Invoice #${invoice.id}';
  }

  void applySalesInvoice(int? invoiceId) {
    final invoice = salesInvoiceById(invoiceId);
    int? resolvedProjectId = projectId;
    int? resolvedMilestoneId = milestoneId;

    if (invoice != null) {
      final projectCandidates = projects
          .where((item) => item.customerPartyId == invoice.customerPartyId)
          .toList(growable: false);
      if (resolvedProjectId == null ||
          !projectCandidates.any((item) => item.id == resolvedProjectId)) {
        if (projectCandidates.length == 1) {
          resolvedProjectId = projectCandidates.first.id;
        }
      }

      final resolvedProject = projectById(resolvedProjectId);
      final billingAmount = invoice.totalAmount;
      if (billingAmount != null) {
        amountController.text = decimalText(billingAmount);
      }
      if (resolvedProject != null && billingAmount != null) {
        final milestoneMatches = resolvedProject.milestones
            .where((milestone) {
              final milestoneAmount = milestone.milestoneAmount;
              if (milestone.id == null || milestoneAmount == null) {
                return false;
              }
              return (milestoneAmount - billingAmount).abs() < 0.01;
            })
            .toList(growable: false);
        if (milestoneMatches.length == 1) {
          resolvedMilestoneId = milestoneMatches.first.id;
        } else if (!milestoneItems.any(
          (item) => item.value == resolvedMilestoneId,
        )) {
          resolvedMilestoneId = null;
        }
      }
    }

    salesInvoiceId = invoiceId;
    projectId = resolvedProjectId;
    milestoneId = resolvedMilestoneId;
    if (invoice != null && resolvedMilestoneId != null && basis == 'fixed') {
      basis = 'milestone';
    }
    update();
  }

  void openSalesInvoicePage(BuildContext context) {
    Navigator.of(context).pushNamed('/sales/invoices');
  }

  void setProjectId(int? value) {
    projectId = value;
    milestoneId = null;
    update();
  }

  void setMilestoneId(int? value) {
    milestoneId = value;
    update();
  }

  void setBasis(String value) {
    basis = value;
    update();
  }

  void setStatus(String value) {
    status = value;
    update();
  }

  double? doubleValue(String text) => double.tryParse(text.trim());

  String decimalText(double? value) => value == null
      ? ''
      : (value == value.roundToDouble()
            ? value.toInt().toString()
            : value.toString());

  Future<String?> saveBilling() async {
    if (!formKey.currentState!.validate()) return null;
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
      final model = ProjectBillingModel(
        id: selectedRow?.billing.id,
        projectId: resolvedProjectId,
        projectMilestoneId: milestoneId,
        billingDate: billingDateController.text.trim(),
        billingBasis: basis,
        billingAmount: doubleValue(amountController.text),
        salesInvoiceId: salesInvoiceId,
        billingStatus: status,
        remarks: nullIfEmpty(remarksController.text),
      );
      final response = selectedRow?.billing.id == null
          ? await _projectService.createBilling(resolvedProjectId, model)
          : await _projectService.updateBilling(
              selectedRow!.billing.id!,
              model,
            );
      await loadData(selectId: response.data?.id ?? selectedRow?.billing.id);
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

  Future<String?> deleteBilling() async {
    final row = selectedRow;
    if (row?.billing.id == null) return null;
    final response = await _projectService.deleteBilling(row!.billing.id!);
    await loadData();
    return response.message;
  }

  void startNewBilling({required bool isDesktop}) {
    resetForm();
    if (!isDesktop) workspaceController.openEditor();
  }
}

class ProjectBillingRow {
  const ProjectBillingRow({required this.project, required this.billing});

  final ProjectModel project;
  final ProjectBillingModel billing;
}
