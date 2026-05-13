import '../../screen.dart';

class ProjectManagementPage extends StatefulWidget {
  const ProjectManagementPage({
    super.key,
    this.embedded = false,
    this.initialTabIndex = 0,
    this.showOnlyTabIndex,
  });

  final bool embedded;
  final int initialTabIndex;
  final int? showOnlyTabIndex;

  @override
  State<ProjectManagementPage> createState() => _ProjectManagementPageState();
}

class _ProjectManagementPageState extends State<ProjectManagementPage> {
  static const List<AppDropdownItem<String>> _billingMethodItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'fixed', label: 'Fixed'),
        AppDropdownItem(value: 'time_and_material', label: 'Time And Material'),
        AppDropdownItem(value: 'milestone', label: 'Milestone'),
        AppDropdownItem(value: 'cost_plus', label: 'Cost Plus'),
      ];

  static const List<AppDropdownItem<String>> _projectStatusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'open', label: 'Open'),
        AppDropdownItem(value: 'working', label: 'Working'),
        AppDropdownItem(value: 'on_hold', label: 'On Hold'),
        AppDropdownItem(value: 'completed', label: 'Completed'),
        AppDropdownItem(value: 'cancelled', label: 'Cancelled'),
      ];

  final ProjectService _projectService = ProjectService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final MediaService _mediaService = MediaService();

  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _projectCodeController = TextEditingController();
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _projectTypeController = TextEditingController();
  final TextEditingController _expectedStartDateController =
      TextEditingController();
  final TextEditingController _expectedEndDateController =
      TextEditingController();
  final TextEditingController _actualStartDateController =
      TextEditingController();
  final TextEditingController _actualEndDateController =
      TextEditingController();
  final TextEditingController _budgetAmountController = TextEditingController();
  final TextEditingController _percentCompletionController =
      TextEditingController();
  final TextEditingController _imagePathController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _initialLoading = true;
  bool _saving = false;
  bool _uploadingImage = false;
  bool _loadingProjectCode = false;
  String? _pageError;
  String? _formError;

  List<ProjectModel> _projects = const <ProjectModel>[];
  List<ProjectModel> _filteredProjects = const <ProjectModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<PartyModel> _parties = const <PartyModel>[];

  ProjectModel? _selectedProject;
  int? _contextCompanyId;
  int? _companyId;
  int? _customerPartyId;
  String _billingMethod = 'fixed';
  String _projectStatus = 'draft';
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadData();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _projectCodeController.dispose();
    _projectNameController.dispose();
    _projectTypeController.dispose();
    _expectedStartDateController.dispose();
    _expectedEndDateController.dispose();
    _actualStartDateController.dispose();
    _actualEndDateController.dispose();
    _budgetAmountController.dispose();
    _percentCompletionController.dispose();
    _imagePathController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData({int? selectId}) async {
    setState(() {
      _initialLoading = _projects.isEmpty;
      _pageError = null;
    });
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

      final projects =
          (responses[0] as PaginatedResponse<ProjectModel>).data ??
          const <ProjectModel>[];
      final companies =
          (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final parties =
          (responses[2] as PaginatedResponse<PartyModel>).data ??
          const <PartyModel>[];

      final activeCompanies = companies.where((item) => item.isActive).toList();
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: activeCompanies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );

      if (!mounted) return;

      setState(() {
        _projects = projects;
        _companies = companies;
        _parties = parties.where((item) => item.isActive).toList();
        _contextCompanyId = contextSelection.companyId;
        _filteredProjects = _filterProjects(projects, _searchController.text);
        _initialLoading = false;
      });

      final selected = selectId != null
          ? projects.cast<ProjectModel?>().firstWhere(
              (item) => item?.id == selectId,
              orElse: () => null,
            )
          : (_selectedProject == null
                ? (_filteredProjects.isNotEmpty
                      ? _filteredProjects.first
                      : null)
                : projects.cast<ProjectModel?>().firstWhere(
                    (item) => item?.id == _selectedProject?.id,
                    orElse: () => _filteredProjects.isNotEmpty
                        ? _filteredProjects.first
                        : null,
                  ));

      if (selected != null) {
        _selectProject(selected);
      } else {
        _resetForm();
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _initialLoading = false;
        _pageError = error.toString();
      });
    }
  }

  void _applySearch() {
    setState(() {
      _filteredProjects = _filterProjects(_projects, _searchController.text);
    });
  }

  List<ProjectModel> _filterProjects(
    List<ProjectModel> projects,
    String query,
  ) {
    final companyId = _contextCompanyId;
    final scoped = companyId == null
        ? projects
        : projects.where((item) => item.companyId == companyId).toList();
    return filterMasterList(scoped, query, (project) {
      return [
        project.projectCode ?? '',
        project.projectName ?? '',
        project.projectType ?? '',
        _companyName(project.companyId),
        _partyName(project.customerPartyId),
      ];
    });
  }

  void _selectProject(ProjectModel project) {
    _selectedProject = project;
    _projectCodeController.text = project.projectCode ?? '';
    _projectNameController.text = project.projectName ?? '';
    _projectTypeController.text = project.projectType ?? '';
    _expectedStartDateController.text = project.expectedStartDate ?? '';
    _expectedEndDateController.text = project.expectedEndDate ?? '';
    _actualStartDateController.text = project.actualStartDate ?? '';
    _actualEndDateController.text = project.actualEndDate ?? '';
    _budgetAmountController.text = _decimalText(project.budgetAmount);
    _percentCompletionController.text = _decimalText(project.percentCompletion);
    _imagePathController.text = project.imagePath ?? '';
    _notesController.text = project.notes ?? '';
    _companyId = project.companyId ?? _contextCompanyId;
    _customerPartyId = project.customerPartyId;
    _billingMethod = project.billingMethod ?? 'fixed';
    _projectStatus = project.projectStatus ?? 'draft';
    _isActive = project.isActive ?? true;
    _loadingProjectCode = false;
    _formError = null;
    setState(() {});
  }

  void _resetForm() {
    _selectedProject = null;
    _projectCodeController.clear();
    _projectNameController.clear();
    _projectTypeController.clear();
    _expectedStartDateController.clear();
    _expectedEndDateController.clear();
    _actualStartDateController.clear();
    _actualEndDateController.clear();
    _budgetAmountController.clear();
    _percentCompletionController.clear();
    _imagePathController.clear();
    _notesController.clear();
    _companyId = _contextCompanyId;
    _customerPartyId = null;
    _billingMethod = 'fixed';
    _projectStatus = 'draft';
    _isActive = true;
    _loadingProjectCode = false;
    _formError = null;
    setState(() {});
    _refreshProjectCode();
  }

  Future<void> _refreshProjectCode() async {
    final companyId = _companyId ?? _contextCompanyId;
    if (_selectedProject?.id != null || companyId == null) {
      return;
    }

    setState(() => _loadingProjectCode = true);
    try {
      final code = await _projectService.nextProjectCode(companyId: companyId);
      if (!mounted || _selectedProject?.id != null) {
        return;
      }
      _projectCodeController.text = code ?? '';
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _loadingProjectCode = false);
      }
    }
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _formError = null;
    });

    final model = ProjectModel(
      id: _selectedProject?.id,
      companyId: _companyId,
      customerPartyId: _customerPartyId,
      projectCode: _projectCodeController.text.trim(),
      projectName: _projectNameController.text.trim(),
      projectType: nullIfEmpty(_projectTypeController.text),
      billingMethod: _billingMethod,
      expectedStartDate: nullIfEmpty(_expectedStartDateController.text),
      expectedEndDate: nullIfEmpty(_expectedEndDateController.text),
      actualStartDate: nullIfEmpty(_actualStartDateController.text),
      actualEndDate: nullIfEmpty(_actualEndDateController.text),
      budgetAmount: _doubleValue(_budgetAmountController.text),
      percentCompletion: _doubleValue(_percentCompletionController.text),
      imagePath: nullIfEmpty(_imagePathController.text),
      projectStatus: _projectStatus,
      notes: nullIfEmpty(_notesController.text),
      isActive: _isActive,
    );

    try {
      final response = _selectedProject?.id == null
          ? await _projectService.createProject(model)
          : await _projectService.updateProject(_selectedProject!.id!, model);
      final saved = response.data;
      if (!mounted) return;
      if (saved == null) {
        setState(() => _formError = response.message);
        return;
      }
      appScaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(response.message)));
      await _loadData(selectId: saved.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _uploadProjectImage() async {
    await MediaUploadHelper.uploadImage(
      context: context,
      mediaService: _mediaService,
      onLoading: (loading) {
        if (!mounted) return;
        setState(() => _uploadingImage = loading);
      },
      onSuccess: (path) {
        _imagePathController.text = path;
      },
      onError: (message) {
        if (!mounted) return;
        appScaffoldMessengerKey.currentState
          ?..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      module: 'projects',
      documentType: 'projects',
      documentId: _selectedProject?.id,
      purpose: 'project_image',
      folder: 'projects/images',
      isPublic: true,
    );
  }

  List<AppDropdownItem<int>> get _companyItems => _companies
      .map(
        (item) =>
            AppDropdownItem<int>(value: item.id ?? 0, label: item.toString()),
      )
      .where((item) => item.value != 0)
      .toList(growable: false);

  List<AppDropdownItem<int>> get _partyItems => _parties
      .map(
        (item) =>
            AppDropdownItem<int>(value: item.id ?? 0, label: item.toString()),
      )
      .where((item) => item.value != 0)
      .toList(growable: false);

  String _companyName(int? id) {
    return _companies
            .cast<CompanyModel?>()
            .firstWhere((item) => item?.id == id, orElse: () => null)
            ?.toString() ??
        '';
  }

  String _partyName(int? id) {
    return _parties
            .cast<PartyModel?>()
            .firstWhere((item) => item?.id == id, orElse: () => null)
            ?.toString() ??
        '';
  }

  double? _doubleValue(String text) => double.tryParse(text.trim());

  String _decimalText(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: _resetForm,
        icon: Icons.add_circle_outline,
        label: 'New Project',
      ),
    ];

    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading projects...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load projects',
        message: _pageError!,
        onRetry: _loadData,
      );
    }

    final content = SettingsWorkspace(
      controller: _workspaceController,
      title: 'Projects',
      editorTitle:
          _selectedProject?.projectName ?? _selectedProject?.projectCode,
      scrollController: _pageScrollController,
      list: SettingsListCard<ProjectModel>(
        searchController: _searchController,
        searchHint: 'Search projects',
        items: _filteredProjects,
        selectedItem: _selectedProject == null
            ? null
            : _filteredProjects.cast<ProjectModel?>().firstWhere(
                (item) => item?.id == _selectedProject?.id,
                orElse: () => null,
              ),
        emptyMessage: 'No projects found.',
        itemBuilder: (project, selected) => SettingsListTile(
          title: project.projectName ?? '',
          subtitle: [
            project.projectCode ?? '',
            _companyName(project.companyId),
            project.projectStatus ?? '',
          ].where((item) => item.isNotEmpty).join(' • '),
          selected: selected,
          trailing: SettingsStatusPill(
            label: (project.isActive ?? true) ? 'Active' : 'Inactive',
            active: project.isActive ?? true,
          ),
          onTap: () => _selectProject(project),
        ),
      ),
      editor: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsFormWrap(
              children: [
                AppFormTextField(
                  controller: _projectCodeController,
                  labelText: 'Project Code',
                  readOnly: true,
                  suffixIcon: _loadingProjectCode
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  validator: Validators.compose([
                    Validators.required('Project Code'),
                    Validators.optionalMaxLength(100, 'Project Code'),
                  ]),
                ),
                AppFormTextField(
                  controller: _projectNameController,
                  labelText: 'Project Name',
                  validator: Validators.compose([
                    Validators.required('Project Name'),
                    Validators.optionalMaxLength(255, 'Project Name'),
                  ]),
                ),

                AppDropdownField<int>.fromMapped(
                  initialValue: _customerPartyId,
                  labelText: 'Customer',
                  doctypeLabel: 'Customer',
                  allowCreate: true,
                  onNavigateToCreateNew: (name) {
                    final uri = Uri(
                      path: '/parties',
                      queryParameters: {
                        'new': '1',
                        if (name.trim().isNotEmpty) 'party_name': name.trim(),
                      },
                    );
                    final navigate = ShellRouteScope.maybeOf(context);
                    if (navigate != null) {
                      navigate(uri.toString());
                    } else {
                      Navigator.of(context).pushNamed(uri.toString());
                    }
                  },
                  mappedItems: _partyItems,
                  onChanged: (value) =>
                      setState(() => _customerPartyId = value),
                ),
                AppFormTextField(
                  controller: _projectTypeController,
                  labelText: 'Project Type',
                  validator: Validators.optionalMaxLength(100, 'Project Type'),
                ),
                AppDropdownField<String>.fromMapped(
                  initialValue: _billingMethod,
                  labelText: 'Billing Method',
                  mappedItems: _billingMethodItems,
                  onChanged: (value) =>
                      setState(() => _billingMethod = value ?? _billingMethod),
                ),
                AppFormTextField(
                  controller: _expectedStartDateController,
                  labelText: 'Expected Start Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('Expected Start Date'),
                ),
                AppFormTextField(
                  controller: _expectedEndDateController,
                  labelText: 'Expected End Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDateOnOrAfter(
                    'Expected End Date',
                    () => _expectedStartDateController.text,
                    startFieldName: 'Expected Start Date',
                  ),
                ),
                AppFormTextField(
                  controller: _actualStartDateController,
                  labelText: 'Actual Start Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDate('Actual Start Date'),
                ),
                AppFormTextField(
                  controller: _actualEndDateController,
                  labelText: 'Actual End Date',
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [DateInputFormatter()],
                  validator: Validators.optionalDateOnOrAfter(
                    'Actual End Date',
                    () => _actualStartDateController.text,
                    startFieldName: 'Actual Start Date',
                  ),
                ),
                AppFormTextField(
                  controller: _budgetAmountController,
                  labelText: 'Budget Amount',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Budget Amount',
                  ),
                ),
                AppFormTextField(
                  controller: _percentCompletionController,
                  labelText: 'Percent Completion',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validators.optionalNonNegativeNumber(
                    'Percent Completion',
                  ),
                ),
                AppDropdownField<String>.fromMapped(
                  initialValue: _projectStatus,
                  labelText: 'Project Status',
                  mappedItems: _projectStatusItems,
                  onChanged: (value) =>
                      setState(() => _projectStatus = value ?? _projectStatus),
                ),
                UploadPathField(
                  controller: _imagePathController,
                  labelText: 'Image Path',
                  onUpload: _uploadProjectImage,
                  isUploading: _uploadingImage,
                  previewUrl: AppConfig.resolvePublicFileUrl(
                    _imagePathController.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppSwitchTile(
              label: 'Active',
              subtitle:
                  'Inactive projects stay visible but should not accept new work.',
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 8),
            AppFormTextField(
              controller: _notesController,
              labelText: 'Notes',
              maxLines: 3,
            ),
            if ((_formError ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _formError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                AppActionButton(
                  onPressed: _saving ? null : _saveProject,
                  icon: _selectedProject?.id == null
                      ? Icons.add
                      : Icons.save_outlined,
                  label: _saving ? 'Saving...' : 'Save Project',
                  busy: _saving,
                ),
                AppActionButton(
                  onPressed: _saving ? null : _resetForm,
                  icon: Icons.refresh,
                  label: 'New',
                  filled: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }

    return AppStandaloneShell(
      title: 'Projects',
      actions: actions,
      scrollController: _pageScrollController,
      child: content,
    );
  }
}
