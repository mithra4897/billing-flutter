import '../../screen.dart';

class ProjectManagementController extends GetxController {
  ProjectManagementController();

  final ProjectService _projectService = ProjectService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final MediaService _mediaService = MediaService();

  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

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

  List<ProjectModel> projects = const <ProjectModel>[];
  List<ProjectModel> filteredProjects = const <ProjectModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<PartyModel> parties = const <PartyModel>[];

  ProjectModel? selectedProject;
  int? contextCompanyId;
  int? companyId;
  int? customerPartyId;
  String billingMethod = 'fixed';
  String projectStatus = 'draft';
  bool isActive = true;

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
        _projectService.projects(
          filters: const {'per_page': 200, 'sort_by': 'project_name'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
        _partiesService.parties(
          filters: const {'per_page': 300, 'sort_by': 'display_name'},
        ),
      ]);

      final nextProjects =
          (responses[0] as PaginatedResponse<ProjectModel>).data ??
          const <ProjectModel>[];
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

      projects = nextProjects;
      companies = nextCompanies;
      parties = nextParties
          .where((item) => item.isActive)
          .toList(growable: false);
      contextCompanyId = contextSelection.companyId;
      filteredProjects = filterProjects(nextProjects, searchController.text);
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

  void _applySearch() {
    filteredProjects = filterProjects(projects, searchController.text);
    update();
  }

  List<ProjectModel> filterProjects(List<ProjectModel> items, String query) {
    final scoped = contextCompanyId == null
        ? items
        : items.where((item) => item.companyId == contextCompanyId).toList();
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
    expectedStartDateController.text = project.expectedStartDate ?? '';
    expectedEndDateController.text = project.expectedEndDate ?? '';
    actualStartDateController.text = project.actualStartDate ?? '';
    actualEndDateController.text = project.actualEndDate ?? '';
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
    if (!formKey.currentState!.validate()) {
      return null;
    }

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
      await loadData(selectId: saved.id);
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

  double? _doubleValue(String text) => double.tryParse(text.trim());

  String _decimalText(double? value) {
    if (value == null) {
      return '';
    }
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }
}
