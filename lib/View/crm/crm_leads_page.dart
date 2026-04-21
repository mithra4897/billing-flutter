import '../../screen.dart';
import '../purchase/purchase_support.dart';

void _openCrmShellRoute(BuildContext context, String route) {
  final navigate = ShellRouteScope.maybeOf(context);
  if (navigate != null) {
    navigate(route);
    return;
  }
  Navigator.of(context).pushNamed(route);
}

class CrmLeadsPage extends StatefulWidget {
  const CrmLeadsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<CrmLeadsPage> createState() => _CrmLeadsPageState();
}

class _CrmLeadsPageState extends State<CrmLeadsPage>
    with SingleTickerProviderStateMixin {
  static const List<AppDropdownItem<String>> _leadStatuses =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'new', label: 'New'),
        AppDropdownItem(value: 'contacted', label: 'Contacted'),
        AppDropdownItem(value: 'qualified', label: 'Qualified'),
        AppDropdownItem(value: 'unqualified', label: 'Unqualified'),
        AppDropdownItem(value: 'converted', label: 'Converted'),
        AppDropdownItem(value: 'lost', label: 'Lost'),
      ];
  static const List<AppDropdownItem<String>> _activityTypes =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'call', label: 'Call'),
        AppDropdownItem(value: 'email', label: 'Email'),
        AppDropdownItem(value: 'meeting', label: 'Meeting'),
        AppDropdownItem(value: 'note', label: 'Note'),
        AppDropdownItem(value: 'whatsapp', label: 'WhatsApp'),
      ];

  final CrmService _crmService = CrmService();
  final MasterService _masterService = MasterService();
  final AuthService _authService = AuthService();
  final ScrollController _pageScrollController = ScrollController();
  final SettingsWorkspaceController _workspaceController =
      SettingsWorkspaceController();
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _leadNameController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  late final TabController _tabController;
  int _activeTabIndex = 0;
  bool _initialLoading = true;
  bool _saving = false;
  String? _pageError;
  String? _formError;
  List<CrmLeadModel> _items = const <CrmLeadModel>[];
  List<CrmLeadModel> _filteredItems = const <CrmLeadModel>[];
  List<CompanyModel> _companies = const <CompanyModel>[];
  List<CrmSourceModel> _sources = const <CrmSourceModel>[];
  List<UserModel> _users = const <UserModel>[];
  CrmLeadModel? _selectedItem;
  int? _contextCompanyId;
  int? _companyId;
  int? _sourceId;
  int? _assignedTo;
  String _leadStatus = 'new';
  List<_LeadActivityDraft> _activities = <_LeadActivityDraft>[];
  int? _expandedActivityIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!mounted || _tabController.indexIsChanging) {
        return;
      }
      _activeTabIndex = _tabController.index;
      setState(() {});
    });
    _searchController.addListener(_applySearch);
    _loadPage();
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _workspaceController.dispose();
    _searchController.dispose();
    _tabController.dispose();
    _leadNameController.dispose();
    _companyNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _remarksController.dispose();
    _disposeActivities(_activities);
    super.dispose();
  }

  Future<void> _loadPage({int? selectId}) async {
    setState(() {
      _initialLoading = _items.isEmpty;
      _pageError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _crmService.leads(filters: const {'per_page': 200, 'sort_by': 'lead_name'}),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
        _crmService.sources(filters: const {'per_page': 200, 'sort_by': 'source_name'}),
        _authService.users(filters: const {'per_page': 200, 'sort_by': 'username'}),
      ]);

      final companies =
          (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: companies
                .where((item) => item.isActive)
                .toList(growable: false),
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _items =
            (responses[0] as PaginatedResponse<CrmLeadModel>).data ??
            const <CrmLeadModel>[];
        _companies = companies.where((item) => item.isActive).toList();
        _sources =
            ((responses[2] as PaginatedResponse<CrmSourceModel>).data ??
                    const <CrmSourceModel>[])
                .where((item) => boolValue(item.toJson(), 'is_active', fallback: true))
                .toList();
        _users =
            ((responses[3] as PaginatedResponse<UserModel>).data ??
                    const <UserModel>[])
                .where((item) => (item.status ?? 'active') == 'active')
                .toList();
        _contextCompanyId = contextSelection.companyId;
        _initialLoading = false;
      });
      _applySearch();

      final selected = selectId != null
          ? _items.cast<CrmLeadModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (_selectedItem == null
                ? (_items.isNotEmpty ? _items.first : null)
                : _items.cast<CrmLeadModel?>().firstWhere(
                    (item) =>
                        intValue(item?.toJson() ?? const {}, 'id') ==
                        intValue(_selectedItem!.toJson(), 'id'),
                    orElse: () => _items.isNotEmpty ? _items.first : null,
                  ));

      if (selected != null) {
        await _selectItem(selected);
      } else {
        _resetForm();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initialLoading = false;
        _pageError = error.toString();
      });
    }
  }

  void _applySearch() {
    setState(() {
      _filteredItems = filterMasterList(_items, _searchController.text, (item) {
        final data = item.toJson();
        return [
          stringValue(data, 'lead_name'),
          stringValue(data, 'company_name'),
          stringValue(data, 'mobile'),
          stringValue(data, 'email'),
          stringValue(data, 'lead_status'),
        ];
      });
    });
  }

  Future<void> _selectItem(CrmLeadModel item) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) {
      return;
    }
    final response = await _crmService.lead(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final activities = (data['activities'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(_LeadActivityDraft.fromJson)
        .toList(growable: true);

    _disposeActivities(_activities);
    setState(() {
      _selectedItem = full;
      _companyId = intValue(data, 'company_id');
      _sourceId = intValue(data, 'source_id');
      _assignedTo = intValue(data, 'assigned_to');
      _leadStatus = stringValue(data, 'lead_status', 'new');
      _leadNameController.text = stringValue(data, 'lead_name');
      _companyNameController.text = stringValue(data, 'company_name');
      _mobileController.text = stringValue(data, 'mobile');
      _emailController.text = stringValue(data, 'email');
      _remarksController.text = stringValue(data, 'remarks');
      _activities = activities;
      _expandedActivityIndex = null;
      _formError = null;
    });
  }

  void _resetForm() {
    _disposeActivities(_activities);
    setState(() {
      _selectedItem = null;
      _companyId = _contextCompanyId;
      _sourceId = null;
      _assignedTo = null;
      _leadStatus = 'new';
      _leadNameController.clear();
      _companyNameController.clear();
      _mobileController.clear();
      _emailController.clear();
      _remarksController.clear();
      _activities = <_LeadActivityDraft>[];
      _expandedActivityIndex = null;
      _formError = null;
      _tabController.index = 0;
      _activeTabIndex = 0;
    });
  }

  void _disposeActivities(List<_LeadActivityDraft> activities) {
    for (final activity in activities) {
      activity.dispose();
    }
  }

  void _addActivity() {
    setState(() {
      _activities = List<_LeadActivityDraft>.from(_activities)
        ..add(_LeadActivityDraft());
      _expandedActivityIndex = _activities.length - 1;
    });
  }

  void _removeActivity(int index) {
    setState(() {
      final activities = List<_LeadActivityDraft>.from(_activities);
      activities.removeAt(index).dispose();
      _activities = activities;
      if (_expandedActivityIndex == index) {
        _expandedActivityIndex = null;
      } else if ((_expandedActivityIndex ?? -1) > index) {
        _expandedActivityIndex = _expandedActivityIndex! - 1;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _formError = null;
    });

    final payload = CrmLeadModel({
      'company_id': _companyId,
      'lead_name': _leadNameController.text.trim(),
      'company_name': nullIfEmpty(_companyNameController.text),
      'mobile': nullIfEmpty(_mobileController.text),
      'email': nullIfEmpty(_emailController.text),
      'source_id': _sourceId,
      'assigned_to': _assignedTo,
      'lead_status': _leadStatus,
      'remarks': nullIfEmpty(_remarksController.text),
      'activities': _activities.map((item) => item.toJson()).toList(growable: false),
    });

    try {
      final response = _selectedItem == null
          ? await _crmService.createLead(payload)
          : await _crmService.updateLead(
              intValue(_selectedItem!.toJson(), 'id')!,
              payload,
            );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage(selectId: intValue(response.data?.toJson() ?? const {}, 'id'));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete() async {
    final id = intValue(_selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }
    try {
      final response = await _crmService.deleteLead(id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
      await _loadPage();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = error.toString());
    }
  }

  Future<void> _convert({required bool createEnquiry}) async {
    final id = intValue(_selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) {
      return;
    }
    try {
      final response = await _crmService.convertLead(
        id,
        createEnquiry: createEnquiry,
      );
      if (!mounted) {
        return;
      }
      final payload = response.data ?? const <String, dynamic>{};
      final enquiryRaw = payload['enquiry'];
      Map<String, dynamic>? enquiryMap;
      if (enquiryRaw is Map) {
        enquiryMap = Map<String, dynamic>.from(enquiryRaw);
      }
      final enquiryId = enquiryMap != null ? intValue(enquiryMap, 'id') : null;

      await _loadPage(selectId: id);

      if (!mounted) {
        return;
      }

      if (enquiryId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            action: SnackBarAction(
              label: 'Open enquiry',
              onPressed: () => _openCrmShellRoute(
                context,
                '/crm/enquiries?select_id=$enquiryId',
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(response.message)));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _formError = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      AdaptiveShellActionButton(
        onPressed: () {
          _resetForm();
          if (!Responsive.isDesktop(context)) {
            _workspaceController.openEditor();
          }
        },
        icon: Icons.add_outlined,
        label: 'New Lead',
      ),
    ];

    final content = _buildContent();
    if (widget.embedded) {
      return ShellPageActions(actions: actions, child: content);
    }
    return AppStandaloneShell(
      title: 'CRM Leads',
      scrollController: _pageScrollController,
      actions: actions,
      child: content,
    );
  }

  Widget _buildContent() {
    if (_initialLoading) {
      return const AppLoadingView(message: 'Loading CRM leads...');
    }
    if (_pageError != null) {
      return AppErrorStateView(
        title: 'Unable to load CRM leads',
        message: _pageError!,
        onRetry: _loadPage,
      );
    }

    return SettingsWorkspace(
      title: 'CRM Leads',
      scrollController: _pageScrollController,
      controller: _workspaceController,
      editorTitle: _selectedItem?.toString() ?? 'New Lead',
      list: SettingsListCard<CrmLeadModel>(
        searchController: _searchController,
        searchHint: 'Search leads',
        items: _filteredItems,
        selectedItem: _selectedItem,
        emptyMessage: 'No CRM leads found.',
        itemBuilder: (item, selected) {
          final data = item.toJson();
          return SettingsListTile(
            title: item.toString(),
            subtitle: [
              stringValue(data, 'company_name'),
              stringValue(data, 'mobile'),
              stringValue(data, 'lead_status'),
            ].where((value) => value.trim().isNotEmpty).join(' • '),
            selected: selected,
            onTap: () => _selectItem(item),
            trailing: SettingsStatusPill(
              label: stringValue(data, 'lead_status', 'new'),
              active: stringValue(data, 'lead_status', 'new') != 'lost',
            ),
          );
        },
      ),
      editor: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Primary'),
                  Tab(text: 'Activities'),
                ],
              ),
              const SizedBox(height: AppUiConstants.spacingMd),
              IndexedStack(
                index: _activeTabIndex,
                children: [
                  _buildPrimaryTab(),
                  _selectedItem?.toJson()['id'] == null
                      ? _buildDependentTabPlaceholder(
                          title: 'Activities',
                          message:
                              'Save this lead first to manage calls, emails, meetings, and follow-up notes.',
                        )
                      : _buildActivitiesTab(),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPrimaryTab() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_formError != null) ...[
            AppErrorStateView.inline(message: _formError!),
            const SizedBox(height: AppUiConstants.spacingSm),
          ],
          SettingsFormWrap(
            children: [
              AppDropdownField<int>.fromMapped(
                labelText: 'Company',
                mappedItems: _companies
                    .where((item) => item.id != null)
                    .map(
                      (item) => AppDropdownItem(
                        value: item.id!,
                        label: item.toString(),
                      ),
                    )
                    .toList(growable: false),
                initialValue: _companyId,
                onChanged: (value) => setState(() => _companyId = value),
                validator: Validators.requiredSelection('Company'),
              ),
              AppFormTextField(
                controller: _leadNameController,
                labelText: 'Lead Name',
                validator: Validators.required('Lead Name'),
              ),
              AppFormTextField(
                controller: _companyNameController,
                labelText: 'Company Name',
              ),
              AppFormTextField(
                controller: _mobileController,
                labelText: 'Mobile',
              ),
              AppFormTextField(
                controller: _emailController,
                labelText: 'Email',
              ),
              AppDropdownField<int>.fromMapped(
                labelText: 'Source',
                mappedItems: _sources
                    .where((item) => intValue(item.toJson(), 'id') != null)
                    .map(
                      (item) => AppDropdownItem(
                        value: intValue(item.toJson(), 'id')!,
                        label: item.toString(),
                      ),
                    )
                    .toList(growable: false),
                initialValue: _sourceId,
                onChanged: (value) => setState(() => _sourceId = value),
              ),
              AppDropdownField<int>.fromMapped(
                labelText: 'Assigned To',
                mappedItems: _users
                    .where((item) => item.id != null)
                    .map(
                      (item) => AppDropdownItem(
                        value: item.id!,
                        label: item.displayName ?? item.username ?? '',
                      ),
                    )
                    .toList(growable: false),
                initialValue: _assignedTo,
                onChanged: (value) => setState(() => _assignedTo = value),
              ),
              AppDropdownField<String>.fromMapped(
                labelText: 'Status',
                mappedItems: _leadStatuses,
                initialValue: _leadStatus,
                onChanged: (value) =>
                    setState(() => _leadStatus = value ?? _leadStatus),
              ),
              AppFormTextField(
                controller: _remarksController,
                labelText: 'Remarks',
                maxLines: 3,
              ),
            ],
          ),
          const SizedBox(height: AppUiConstants.spacingMd),
          Wrap(
            spacing: AppUiConstants.spacingSm,
            runSpacing: AppUiConstants.spacingSm,
            children: [
              AppActionButton(
                icon: Icons.save_outlined,
                label: _selectedItem == null ? 'Save Lead' : 'Update Lead',
                onPressed: _save,
                busy: _saving,
              ),
              if (_selectedItem != null) ...[
                AppActionButton(
                  icon: Icons.forward_outlined,
                  label: 'Create enquiry',
                  onPressed: () => _convert(createEnquiry: true),
                ),
                AppActionButton(
                  icon: Icons.check_circle_outline,
                  label: 'Mark converted only',
                  filled: false,
                  onPressed: () => _convert(createEnquiry: false),
                ),
                AppActionButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  filled: false,
                  onPressed: _delete,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Activities',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            AppActionButton(
              icon: Icons.add_outlined,
              label: 'Add Activity',
              filled: false,
              onPressed: _addActivity,
            ),
          ],
        ),
        const SizedBox(height: AppUiConstants.spacingSm),
        if (_activities.isEmpty)
          const SettingsEmptyState(
            icon: Icons.event_note_outlined,
            title: 'No Activities',
            message: 'Add calls, emails, meetings, notes, and follow-up entries.',
            minHeight: 180,
          )
        else
          ...List<Widget>.generate(_activities.length, (index) {
            final activity = _activities[index];
            final expanded = _expandedActivityIndex == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppUiConstants.spacingSm),
              child: SettingsExpandableTile(
                title: activity.activityTypeLabel,
                subtitle: [
                  activity.activityDateTimeController.text.trim(),
                  activity.nextFollowupController.text.trim(),
                ].where((value) => value.isNotEmpty).join(' • '),
                detail: activity.notesController.text.trim(),
                expanded: expanded,
                highlighted: expanded,
                leadingIcon: Icons.event_note_outlined,
                trailing: IconButton(
                  onPressed: () => _removeActivity(index),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline),
                ),
                onToggle: () {
                  setState(() {
                    _expandedActivityIndex = expanded ? null : index;
                  });
                },
                child: PurchaseCompactFieldGrid(
                  children: [
                    AppDropdownField<String>.fromMapped(
                      labelText: 'Type',
                      mappedItems: _activityTypes,
                      initialValue: activity.activityType,
                      onChanged: (value) => setState(
                        () => activity.activityType =
                            value ?? activity.activityType,
                      ),
                    ),
                    AppFormTextField(
                      controller: activity.activityDateTimeController,
                      labelText: 'Activity Date Time',
                      hintText: 'YYYY-MM-DD HH:MM:SS',
                      keyboardType: TextInputType.datetime,
                      inputFormatters: const [DateTimeInputFormatter()],
                    ),
                    AppFormTextField(
                      controller: activity.nextFollowupController,
                      labelText: 'Next Follow-up',
                      hintText: 'YYYY-MM-DD HH:MM:SS',
                      keyboardType: TextInputType.datetime,
                      inputFormatters: const [DateTimeInputFormatter()],
                    ),
                    AppFormTextField(
                      controller: activity.notesController,
                      labelText: 'Notes',
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: AppUiConstants.spacingMd),
        Wrap(
          spacing: AppUiConstants.spacingSm,
          runSpacing: AppUiConstants.spacingSm,
          children: [
            AppActionButton(
              icon: Icons.save_outlined,
              label: _selectedItem == null ? 'Save Lead' : 'Update Lead',
              onPressed: _save,
              busy: _saving,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDependentTabPlaceholder({
    required String title,
    required String message,
  }) {
    return SettingsEmptyState(
      icon: Icons.link_outlined,
      title: title,
      message: message,
      minHeight: 240,
    );
  }
}

class _LeadActivityDraft {
  _LeadActivityDraft({
    this.activityType = 'call',
    String? activityDateTime,
    String? notes,
    String? nextFollowup,
  }) : activityDateTimeController = TextEditingController(
         text: displayDateTime(activityDateTime) == ''
             ? currentDateTimeInput()
             : displayDateTime(activityDateTime),
       ),
       notesController = TextEditingController(text: notes ?? ''),
       nextFollowupController = TextEditingController(
         text: displayDateTime(nextFollowup),
       );

  factory _LeadActivityDraft.fromJson(Map<String, dynamic> json) {
    return _LeadActivityDraft(
      activityType: stringValue(json, 'activity_type', 'call'),
      activityDateTime: stringValue(json, 'activity_datetime'),
      notes: stringValue(json, 'notes'),
      nextFollowup: stringValue(json, 'next_followup'),
    );
  }

  String activityType;
  final TextEditingController activityDateTimeController;
  final TextEditingController notesController;
  final TextEditingController nextFollowupController;

  String get activityTypeLabel {
    switch (activityType) {
      case 'call':
        return 'Call';
      case 'email':
        return 'Email';
      case 'meeting':
        return 'Meeting';
      case 'note':
        return 'Note';
      case 'whatsapp':
        return 'WhatsApp';
      default:
        return activityType;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'activity_type': activityType,
      'activity_datetime': nullIfEmpty(activityDateTimeController.text),
      'notes': nullIfEmpty(notesController.text),
      'next_followup': nullIfEmpty(nextFollowupController.text),
    };
  }

  void dispose() {
    activityDateTimeController.dispose();
    notesController.dispose();
    nextFollowupController.dispose();
  }
}
