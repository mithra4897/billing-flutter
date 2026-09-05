import '../../screen.dart';
import 'project_module_refresh_controller.dart';

Map<int, List<String>> buildProjectEmployeeNamesById(
  Iterable<ProjectModel> sourceProjects,
) {
  final result = <int, List<String>>{};
  for (final project in sourceProjects) {
    final projectId = project.id;
    if (projectId == null) continue;
    final assignedIds = <int>{};
    final names = <String>[];
    for (final task in project.tasks) {
      final assignedEmployeeId = task.assignedEmployeeId;
      final assignedEmployeeName = task.assignedEmployeeName?.trim() ?? '';
      if (assignedEmployeeId != null &&
          assignedIds.add(assignedEmployeeId) &&
          assignedEmployeeName.isNotEmpty) {
        names.add(assignedEmployeeName);
      }
    }
    result[projectId] = names;
  }
  return result;
}

class ProjectManagementController extends GetxController {
  ProjectManagementController({this.initialDashboardFilter = ''});

  final String initialDashboardFilter;

  final ProjectService _projectService = ProjectService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final MediaService _mediaService = MediaService();
  final ProjectModuleRefreshController _refreshController =
      ProjectModuleRefreshController.ensureRegistered();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController dateFromController = TextEditingController();
  final TextEditingController dateToController = TextEditingController();
  Set<int> filterCustomerIds = const <int>{};
  Set<String> selectedStatuses = const <String>{};
  Set<String> selectedProjectTypes = const <String>{};
  Set<String> selectedBillingMethods = const <String>{};

  final TextEditingController projectCodeController = TextEditingController();
  final TextEditingController projectNameController = TextEditingController();
  final TextEditingController projectTypeController = TextEditingController();
  final TextEditingController expectedStartDateController =
      TextEditingController();
  final TextEditingController expectedEndDateController =
      TextEditingController();
  final TextEditingController actualStartDateController =
      TextEditingController();
  final TextEditingController actualEndDateController = TextEditingController();
  final TextEditingController budgetAmountController = TextEditingController();
  final TextEditingController percentCompletionController =
      TextEditingController();
  final TextEditingController imagePathController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool initialLoading = true;
  bool saving = false;
  bool uploadingImage = false;
  bool loadingProjectCode = false;
  String? pageError;
  String? formError;
  Worker? _refreshWorker;

  List<ProjectModel> projects = const <ProjectModel>[];
  List<ProjectModel> filteredProjects = const <ProjectModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<PartyModel> parties = const <PartyModel>[];
  Map<int, List<String>> projectEmployeeNamesById = const <int, List<String>>{};

  ProjectModel? selectedProject;
  int? contextCompanyId;
  int? companyId;
  int? customerPartyId;
  String billingMethod = 'fixed';
  String projectStatus = 'draft';
  bool isActive = true;

  bool canViewAllProjects = false;
  Set<String> permissionCodes = const <String>{};

  int? linkedEmployeeId;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_applySearch);
    dateFromController.addListener(_applySearch);
    dateToController.addListener(_applySearch);
    _refreshWorker = ever<ProjectModuleRefreshEvent?>(
      _refreshController.lastEvent,
      (event) {
        if (event == null) {
          return;
        }
        unawaited(loadData(selectId: selectedProject?.id));
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
      ..removeListener(_applySearch)
      ..dispose();
    dateFromController
      ..removeListener(_applySearch)
      ..dispose();
    dateToController
      ..removeListener(_applySearch)
      ..dispose();
    projectCodeController.dispose();
    projectNameController.dispose();
    projectTypeController.dispose();
    expectedStartDateController.dispose();
    expectedEndDateController.dispose();
    actualStartDateController.dispose();
    actualEndDateController.dispose();
    budgetAmountController.dispose();
    percentCompletionController.dispose();
    imagePathController.dispose();
    notesController.dispose();
    super.onClose();
  }

  Future<void> loadData({int? selectId}) async {
    initialLoading = projects.isEmpty;
    pageError = null;
    update();
    try {
      final responses = await Future.wait<dynamic>([
        _refreshController.projects(loader: _projectService.projects),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
        _partiesService.parties(
          filters: const {'per_page': 300, 'sort_by': 'display_name'},
        ),
      ]);

      final nextProjects = responses[0] as List<ProjectModel>;
      final nextCompanies =
          (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final nextParties =
          (responses[2] as PaginatedResponse<PartyModel>).data ??
          const <PartyModel>[];

      final activeCompanies = nextCompanies
          .where((item) => item.isActive)
          .toList(growable: false);
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );
      final cid = contextSelection.companyId;
      if (cid != null) {
        try {
          final ctxRes = await _projectService.linkedEmployee(companyId: cid);
          final ctx = ctxRes.data ?? const <String, dynamic>{};
          canViewAllProjects =
              ctx['can_view_all_projects'] == true ||
              ctx['can_view_all_projects'] == 1;
          linkedEmployeeId = intValue(ctx, 'employee_id');
        } catch (_) {
          canViewAllProjects = false;
          linkedEmployeeId = null;
        }
      } else {
        canViewAllProjects = false;
        linkedEmployeeId = null;
      }

      projects = nextProjects;
      projectEmployeeNamesById = buildProjectEmployeeNamesById(nextProjects);
      companies = nextCompanies;
      parties = nextParties
          .where((item) => item.isActive)
          .toList(growable: false);
      contextCompanyId = cid;
      filteredProjects = filterProjects(nextProjects, searchController.text);
      permissionCodes = (await SessionStorage.getPermissionCodes()).toSet();
      initialLoading = false;
      update();

      final selected = selectId != null
          ? nextProjects.cast<ProjectModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (selectedProject == null
                ? (filteredProjects.isNotEmpty ? filteredProjects.first : null)
                : nextProjects.cast<ProjectModel?>().firstWhere(
                    (item) => item?.id == selectedProject?.id,
                    orElse: () => filteredProjects.isNotEmpty
                        ? filteredProjects.first
                        : null,
                  ));

      if (selected != null) {
        selectProject(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (errorValue) {
      initialLoading = false;
      pageError = errorValue.toString();
      update();
    }
  }

  List<String> projectEmployeeNames(ProjectModel project) =>
      projectEmployeeNamesById[project.id] ?? const <String>[];

  void _applySearch() {
    filteredProjects = filterProjects(projects, searchController.text);
    update();
  }

  List<ProjectModel> filterProjects(List<ProjectModel> items, String query) {
    var scoped = contextCompanyId == null
        ? items
        : items.where((item) => item.companyId == contextCompanyId).toList();
    if (!canViewAllProjects) {
      final empId = linkedEmployeeId;
      if (empId == null) {
        scoped = <ProjectModel>[];
      } else {
        scoped = scoped
            .where((project) {
              return project.tasks.any((task) {
                final ids = task.assignedEmployeeIds;
                return task.assignedEmployeeId == empId ||
                    (ids.isNotEmpty && ids.contains(empId));
              });
            })
            .toList(growable: false);
      }
    }

    if (initialDashboardFilter.trim() == 'active') {
      scoped = scoped
          .where((project) {
            final status = (project.projectStatus ?? '').trim().toLowerCase();
            return status == 'open' || status == 'working';
          })
          .toList(growable: false);
    }
    final from = dateFromController.text.trim();
    final to = dateToController.text.trim();
    scoped = scoped
        .where((project) {
          final date = project.expectedStartDate ?? '';
          return (filterCustomerIds.isEmpty ||
                  filterCustomerIds.contains(project.customerPartyId)) &&
              (selectedStatuses.isEmpty ||
                  selectedStatuses.contains(project.projectStatus ?? '')) &&
              (selectedProjectTypes.isEmpty ||
                  selectedProjectTypes.contains(project.projectType ?? '')) &&
              (selectedBillingMethods.isEmpty ||
                  selectedBillingMethods.contains(
                    project.billingMethod ?? '',
                  )) &&
              (from.isEmpty || date.compareTo(from) >= 0) &&
              (to.isEmpty || date.compareTo(to) <= 0);
        })
        .toList(growable: false);
    return filterMasterList(scoped, query, (project) {
      return [
        project.projectCode ?? '',
        project.projectName ?? '',
        project.projectType ?? '',
        companyName(project.companyId),
        partyName(project.customerPartyId),
      ];
    });
  }

  void selectProject(ProjectModel project, {bool notify = true}) {
    selectedProject = project;
    projectCodeController.text = project.projectCode ?? '';
    projectNameController.text = project.projectName ?? '';
    projectTypeController.text = project.projectType ?? '';
    expectedStartDateController.text = normalizeDateValue(
      project.expectedStartDate,
    );
    expectedEndDateController.text = normalizeDateValue(
      project.expectedEndDate,
    );
    actualStartDateController.text = normalizeDateValue(
      project.actualStartDate,
    );
    actualEndDateController.text = normalizeDateValue(project.actualEndDate);
    budgetAmountController.text = _decimalText(project.budgetAmount);
    percentCompletionController.text = _decimalText(project.percentCompletion);
    imagePathController.text = project.imagePath ?? '';
    notesController.text = project.notes ?? '';
    companyId = project.companyId ?? contextCompanyId;
    customerPartyId = project.customerPartyId;
    billingMethod = project.billingMethod ?? 'fixed';
    projectStatus = project.projectStatus ?? 'draft';
    isActive = project.isActive ?? true;
    loadingProjectCode = false;
    formError = null;
    if (notify) {
      update();
    }
  }

  void resetForm({bool notify = true}) {
    selectedProject = null;
    projectCodeController.clear();
    projectNameController.clear();
    projectTypeController.clear();
    expectedStartDateController.clear();
    expectedEndDateController.clear();
    actualStartDateController.clear();
    actualEndDateController.clear();
    budgetAmountController.clear();
    percentCompletionController.clear();
    imagePathController.clear();
    notesController.clear();
    companyId = contextCompanyId;
    customerPartyId = null;
    billingMethod = 'fixed';
    projectStatus = 'draft';
    isActive = true;
    loadingProjectCode = false;
    formError = null;
    if (notify) {
      update();
    }
    unawaited(refreshProjectCode());
  }

  Future<void> refreshProjectCode() async {
    final resolvedCompanyId = companyId ?? contextCompanyId;
    if (selectedProject?.id != null || resolvedCompanyId == null) {
      return;
    }

    loadingProjectCode = true;
    update();
    try {
      final code = await _projectService.nextProjectCode(
        companyId: resolvedCompanyId,
      );
      if (selectedProject?.id != null) {
        return;
      }
      projectCodeController.text = code ?? '';
    } catch (_) {
    } finally {
      loadingProjectCode = false;
      update();
    }
  }

  Future<String?> saveProject() async {
    saving = true;
    formError = null;
    update();

    final model = ProjectModel(
      id: selectedProject?.id,
      companyId: companyId,
      customerPartyId: customerPartyId,
      projectCode: projectCodeController.text.trim(),
      projectName: projectNameController.text.trim(),
      projectType: nullIfEmpty(projectTypeController.text),
      billingMethod: billingMethod,
      expectedStartDate: nullIfEmpty(expectedStartDateController.text),
      expectedEndDate: nullIfEmpty(expectedEndDateController.text),
      actualStartDate: nullIfEmpty(actualStartDateController.text),
      actualEndDate: nullIfEmpty(actualEndDateController.text),
      budgetAmount: _doubleValue(budgetAmountController.text),
      percentCompletion: _doubleValue(percentCompletionController.text),
      imagePath: nullIfEmpty(imagePathController.text),
      projectStatus: projectStatus,
      notes: nullIfEmpty(notesController.text),
      isActive: isActive,
    );

    try {
      final response = selectedProject?.id == null
          ? await _projectService.createProject(model)
          : await _projectService.updateProject(selectedProject!.id!, model);
      final saved = response.data;
      if (saved == null) {
        formError = response.message;
        update();
        return null;
      }
      _refreshController.invalidateProjects();
      await loadData(selectId: saved.id);
      _refreshController.notifyChanged(source: 'project_management');
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

  Future<String?> deleteProject(ProjectModel project) async {
    final projectId = project.id;
    if (projectId == null) {
      return null;
    }
    try {
      final response = await _projectService.deleteProject(projectId);
      _refreshController.invalidateProjects();
      await loadData();
      _refreshController.notifyChanged(source: 'project_management');
      return response.message;
    } catch (errorValue) {
      return 'Unable to delete project: $errorValue';
    }
  }

  Future<void> uploadProjectImage(BuildContext context) async {
    await MediaUploadHelper.uploadImage(
      context: context,
      mediaService: _mediaService,
      onLoading: (loading) {
        uploadingImage = loading;
        update();
      },
      onSuccess: (path) {
        imagePathController.text = path;
        update();
      },
      onError: (message) {
        appScaffoldMessengerKey.currentState
          ?..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      module: 'projects',
      documentType: 'projects',
      documentId: selectedProject?.id,
      purpose: 'project_image',
      folder: 'projects/images',
      isPublic: true,
    );
  }

  void setCompanyId(int? value) {
    if (companyId == value) {
      return;
    }
    companyId = value;
    if (selectedProject?.id == null) {
      projectCodeController.clear();
      unawaited(refreshProjectCode());
    }
    update();
  }

  void setCustomerPartyId(int? value) {
    customerPartyId = value;
    update();
  }

  void setBillingMethod(String value) {
    billingMethod = value;
    update();
  }

  void setProjectStatus(String value) {
    projectStatus = value;
    update();
  }

  void setIsActive(bool value) {
    isActive = value;
    update();
  }

  List<AppDropdownItem<int>> get partyItems => parties
      .map(
        (item) =>
            AppDropdownItem<int>(value: item.id ?? 0, label: item.toString()),
      )
      .where((item) => item.value != 0)
      .toList(growable: false);

  List<AppDropdownItem<int>> get customerFilterItems {
    final customerIds = projects
        .map((project) => project.customerPartyId)
        .whereType<int>()
        .toSet();
    return parties
        .where((party) => party.id != null && customerIds.contains(party.id))
        .map(
          (party) =>
              AppDropdownItem<int>(value: party.id!, label: party.toString()),
        )
        .toList(growable: false);
  }

  List<AppDropdownItem<String>> get projectTypeFilterItems => projects
      .map((project) => project.projectType?.trim() ?? '')
      .where((value) => value.isNotEmpty)
      .toSet()
      .map((value) => AppDropdownItem<String>(value: value, label: value))
      .toList(growable: false);

  List<AppDropdownItem<String>> get billingMethodFilterItems => projects
      .map((project) => project.billingMethod?.trim() ?? '')
      .where((value) => value.isNotEmpty)
      .toSet()
      .map(
        (value) => AppDropdownItem<String>(
          value: value,
          label: value.replaceAll('_', ' ').titleCase,
        ),
      )
      .toList(growable: false);

  void setFilterCustomerIds(Set<int> values) {
    filterCustomerIds = Set<int>.from(values);
    _applySearch();
  }

  void setSelectedStatuses(Set<String> values) {
    selectedStatuses = Set<String>.from(values);
    _applySearch();
  }

  void setSelectedProjectTypes(Set<String> values) {
    selectedProjectTypes = Set<String>.from(values);
    _applySearch();
  }

  void setSelectedBillingMethods(Set<String> values) {
    selectedBillingMethods = Set<String>.from(values);
    _applySearch();
  }

  void clearFilters() {
    dateFromController.clear();
    dateToController.clear();
    filterCustomerIds = const <int>{};
    selectedStatuses = const <String>{};
    selectedProjectTypes = const <String>{};
    selectedBillingMethods = const <String>{};
    _applySearch();
  }

  String companyName(int? id) {
    return companies
            .cast<CompanyModel?>()
            .firstWhere((item) => item?.id == id, orElse: () => null)
            ?.toString() ??
        '';
  }

  String partyName(int? id) {
    return parties
            .cast<PartyModel?>()
            .firstWhere((item) => item?.id == id, orElse: () => null)
            ?.toString() ??
        '';
  }

  void startNewProject({required bool isDesktop}) {
    resetForm();
    if (!isDesktop) {
      workspaceController.openEditor();
    }
  }

  double? _doubleValue(String text) => Validators.parseFlexibleNumber(text);

  String _decimalText(double? value) {
    if (value == null) {
      return '';
    }
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }
}
