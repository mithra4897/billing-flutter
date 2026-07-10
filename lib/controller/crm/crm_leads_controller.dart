import '../../screen.dart';
import 'crm_module_refresh_controller.dart';

class CrmLeadsController extends GetxController {
  static const int allFilterIntValue = 0;
  static const String allFilterStringValue = '__all__';
  static const List<AppDropdownItem<String>> leadFilterStatuses =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'draft', label: 'Draft'),
        AppDropdownItem(value: 'in_progress', label: 'In Progress'),
        AppDropdownItem(value: 'converted', label: 'Own'),
        AppDropdownItem(value: 'lost', label: 'Lost'),
      ];
  static const List<AppDropdownItem<String>> activityTypes =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'call', label: 'Call'),
        AppDropdownItem(value: 'email', label: 'Email'),
        AppDropdownItem(value: 'meeting', label: 'Meeting'),
        AppDropdownItem(value: 'note', label: 'Note'),
        AppDropdownItem(value: 'whatsapp', label: 'WhatsApp'),
      ];
  static const List<AppDropdownItem<String>> activityStatuses =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'pending', label: 'Pending'),
        AppDropdownItem(value: 'done', label: 'Done'),
      ];

  CrmLeadsController({
    required this.startInNewMode,
    required this.initialSelectId,
    required this.initialLeadName,
    required this.initialCompanyId,
  });

  final bool startInNewMode;
  final int? initialSelectId;
  final String? initialLeadName;
  final int? initialCompanyId;

  final CrmService _crmService = CrmService();
  final MasterService _masterService = MasterService();
  final AuthService _authService = AuthService();
  final CrmModuleRefreshController _refreshController =
      CrmModuleRefreshController.ensureRegistered();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController leadNameController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  int activeTabIndex = 0;
  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<CrmLeadModel> items = const <CrmLeadModel>[];
  List<CrmLeadModel> filteredItems = const <CrmLeadModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<CrmSourceModel> sources = const <CrmSourceModel>[];
  List<UserModel> users = const <UserModel>[];
  CrmLeadModel? selectedItem;
  int? contextCompanyId;
  int? companyId;
  int? sourceId;
  int? assignedTo;
  int? filterCompanyId;
  Set<int> filterSourceIds = <int>{};
  Set<int> filterAssignedToIds = <int>{};
  Set<String> filterLeadStatuses = <String>{};
  String leadStatus = 'new';
  List<LeadActivityDraft> activities = <LeadActivityDraft>[];
  int? expandedActivityIndex;
  Map<String, dynamic>? salesChain;
  bool appliedInitialNewMode = false;
  bool filtersApplied = false;
  Worker? _refreshWorker;

  bool get hasLinkedOpportunity =>
      (opportunityIdFromSalesChain() ?? enquiryIdFromSalesChain()) != null;

  bool get isSelectedLeadReadOnly =>
      selectedItem != null &&
      (isLockedLeadStatus(leadStatus) || hasLinkedOpportunity);

  bool get canDeleteSelectedLead {
    if (selectedItem == null) {
      return false;
    }

    return const {
      'draft',
      'new',
      'in_progress',
    }.contains(effectiveLeadStatus());
  }

  bool get canCreateOpportunityForSelectedLead {
    if (selectedItem == null || isSelectedLeadReadOnly) {
      return false;
    }

    return !hasLinkedOpportunity;
  }

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(applySearch);
    _refreshWorker = ever<CrmModuleRefreshEvent?>(
      _refreshController.lastEvent,
      (event) {
        if (event == null || event.source == 'crm_leads') {
          return;
        }
        unawaited(
          loadPage(
            selectId: intValue(selectedItem?.toJson() ?? const {}, 'id'),
          ),
        );
      },
    );
    loadPage(selectId: initialSelectId);
  }

  @override
  void onClose() {
    _refreshWorker?.dispose();
    FocusManager.instance.primaryFocus?.unfocus();
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController.removeListener(applySearch);
    disposeChangeNotifiersNextFrame<TextEditingController>([
      searchController,
      leadNameController,
      companyNameController,
      mobileController,
      emailController,
      remarksController,
    ]);
    disposeDraftEntriesNextFrame<LeadActivityDraft>(
      List<LeadActivityDraft>.from(activities),
      (entry) => entry.dispose(),
    );
    super.onClose();
  }

  static bool isCompletedLead(CrmLeadModel item) {
    final status = stringValue(item.toJson(), 'lead_status');
    return status == 'own' || status == 'converted' || status == 'lost';
  }

  static bool isLockedLeadStatus(String status) =>
      status == 'own' || status == 'converted' || status == 'lost';

  static bool matchesLeadFilterStatus(
    String? rowStatus,
    Iterable<String> requested,
  ) {
    final normalizedRow = (rowStatus ?? '').trim().toLowerCase();
    final normalizedRequested = requested
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty && item != allFilterStringValue)
        .toSet();

    if (normalizedRequested.isEmpty) {
      return true;
    }

    for (final status in normalizedRequested) {
      if (status == 'draft' &&
          (normalizedRow == 'draft' || normalizedRow == 'new')) {
        return true;
      }

      if ((status == 'converted' || status == 'own') &&
          (normalizedRow == 'converted' || normalizedRow == 'own')) {
        return true;
      }

      if (normalizedRow == status) {
        return true;
      }
    }

    return false;
  }

  String effectiveLeadStatus() {
    final status = leadStatus.trim().toLowerCase();
    if (status == 'own' || status == 'converted') {
      return 'converted';
    }
    if (status == 'lost') {
      return 'lost';
    }
    if (activities.isNotEmpty) {
      return 'in_progress';
    }
    return 'draft';
  }

  String leadStatusLabel([String? status]) {
    switch ((status ?? effectiveLeadStatus()).trim().toLowerCase()) {
      case 'draft':
      case 'new':
        return 'Draft';
      case 'in_progress':
        return 'In Progress';
      case 'own':
      case 'converted':
        return 'Own';
      case 'lost':
        return 'Lost';
      default:
        return 'Draft';
    }
  }

  Future<void> loadPage({int? selectId}) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();

    try {
      final responses = await Future.wait<dynamic>([
        _crmService.leads(
          filters: const {'per_page': 200, 'sort_by': 'lead_name'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
        _crmService.sources(
          filters: const {'per_page': 200, 'sort_by': 'source_name'},
        ),
        _authService.users(
          filters: const {'per_page': 200, 'sort_by': 'username'},
        ),
      ]);

      final nextCompanies =
          (responses[1] as PaginatedResponse<CompanyModel>).data ??
          const <CompanyModel>[];
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: nextCompanies
                .where((item) => item.isActive)
                .toList(growable: false),
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );

      items =
          (responses[0] as PaginatedResponse<CrmLeadModel>).data ??
          const <CrmLeadModel>[];
      companies = nextCompanies.where((item) => item.isActive).toList();
      sources =
          ((responses[2] as PaginatedResponse<CrmSourceModel>).data ??
                  const <CrmSourceModel>[])
              .where(
                (item) => boolValue(item.toJson(), 'is_active', fallback: true),
              )
              .toList();
      users =
          ((responses[3] as PaginatedResponse<UserModel>).data ??
                  const <UserModel>[])
              .where((item) => (item.status ?? 'active') == 'active')
              .toList();
      contextCompanyId = contextSelection.companyId;
      initialLoading = false;
      applySearch(notify: false);

      if (startInNewMode && !appliedInitialNewMode) {
        appliedInitialNewMode = true;
        resetForm(notify: false);
        applyInitialLeadDraft(notify: false);
        update();
        return;
      }

      final selected = selectId != null
          ? items.cast<CrmLeadModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (selectedItem == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<CrmLeadModel?>().firstWhere(
                    (item) =>
                        intValue(item?.toJson() ?? const {}, 'id') ==
                        intValue(selectedItem!.toJson(), 'id'),
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected == null && selectId != null) {
        try {
          final detail = (await _crmService.lead(selectId)).data;
          if (detail != null) {
            await selectItem(detail, notify: false);
            update();
            return;
          }
        } catch (_) {}
      }

      if (selected != null) {
        await selectItem(selected, notify: false);
      } else {
        resetForm(notify: false);
      }
    } catch (error) {
      initialLoading = false;
      pageError = error.toString();
    }

    update();
  }

  void applyInitialLeadDraft({bool notify = true}) {
    final leadName = (initialLeadName ?? '').trim();
    selectedItem = null;
    companyId = initialCompanyId ?? contextCompanyId;
    if (leadName.isNotEmpty) {
      leadNameController
        ..text = leadName
        ..selection = TextSelection.collapsed(offset: leadName.length);
    }
    formError = null;
    if (notify) {
      update();
    }
  }

  void applySearch({bool notify = true}) {
    filteredItems =
        filterMasterList(items, searchController.text, (item) {
              final data = item.toJson();
              return [
                stringValue(data, 'lead_name'),
                stringValue(data, 'company_name'),
                stringValue(data, 'mobile'),
                stringValue(data, 'email'),
                leadStatusLabel(stringValue(data, 'lead_status')),
              ];
            })
            .where((item) {
              final data = item.toJson();
              final completed = isCompletedLead(item);
              final rowStatus = stringValue(data, 'lead_status', 'new');
              final hasStatusFilters = filterLeadStatuses.isNotEmpty;
              final showAllStatuses = filtersApplied && !hasStatusFilters;
              if (completed &&
                  !showAllStatuses &&
                  !matchesLeadFilterStatus(rowStatus, filterLeadStatuses)) {
                return false;
              }
              if (filterCompanyId != null &&
                  intValue(data, 'company_id') != filterCompanyId) {
                return false;
              }
              if (filterSourceIds.isNotEmpty &&
                  !filterSourceIds.contains(intValue(data, 'source_id'))) {
                return false;
              }
              if (filterAssignedToIds.isNotEmpty &&
                  !filterAssignedToIds.contains(intValue(data, 'assigned_to'))) {
                return false;
              }
              if (!matchesLeadFilterStatus(rowStatus, filterLeadStatuses)) {
                return false;
              }
              return true;
            })
            .toList(growable: false);
    if (notify) {
      update();
    }
  }

  Future<void> selectItem(CrmLeadModel item, {bool notify = true}) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) {
      return;
    }
    final response = await _crmService.lead(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final nextActivities = JsonModel.mapListOf(
      data['activities'],
    ).map(LeadActivityDraft.fromJson).toList(growable: true);

    selectedItem = full;
    companyId = intValue(data, 'company_id');
    sourceId = intValue(data, 'source_id');
    assignedTo = intValue(data, 'assigned_to');
    leadStatus = stringValue(data, 'lead_status', 'new');
    if (leadStatus == 'new') {
      leadStatus = 'draft';
    }
    leadNameController.text = stringValue(data, 'lead_name');
    companyNameController.text = stringValue(data, 'company_name');
    mobileController.text = stringValue(data, 'mobile');
    emailController.text = stringValue(data, 'email');
    remarksController.text = stringValue(data, 'remarks');
    _replaceActivities(nextActivities, notify: false);
    expandedActivityIndex = null;
    formError = null;
    await refreshSalesChainForLead(id);
    if (notify) {
      update();
    }
  }

  Future<void> refreshSalesChainForLead(int leadId) async {
    try {
      final response = await _crmService.salesChain(leadId: leadId);
      salesChain = response.data;
    } catch (_) {
      salesChain = null;
    }
  }

  int? enquiryIdFromSalesChain() {
    final chain = salesChain;
    if (chain == null) return null;
    final raw = chain['enquiry'];
    if (raw is! Map) return null;
    return intValue(Map<String, dynamic>.from(raw), 'id');
  }

  int? opportunityIdFromSalesChain() {
    final chain = salesChain;
    if (chain == null) return null;
    final raw = chain['opportunity'];
    if (raw is! Map) return null;
    return intValue(Map<String, dynamic>.from(raw), 'id');
  }

  void resetForm({bool notify = true}) {
    selectedItem = null;
    companyId = contextCompanyId;
    sourceId = null;
    assignedTo = null;
    leadStatus = 'new';
    leadStatus = 'draft';
    leadNameController.clear();
    companyNameController.clear();
    mobileController.clear();
    emailController.clear();
    remarksController.clear();
    _replaceActivities(const <LeadActivityDraft>[], notify: false);
    expandedActivityIndex = null;
    formError = null;
    activeTabIndex = 0;
    salesChain = null;
    if (notify) {
      update();
    }
  }

  void disposeActivities(List<LeadActivityDraft> source) {
    for (final activity in source) {
      activity.dispose();
    }
  }

  void addActivity() {
    activities = List<LeadActivityDraft>.from(activities)
      ..add(LeadActivityDraft());
    expandedActivityIndex = activities.length - 1;
    update();
  }

  void removeActivity(int index) {
    final nextActivities = List<LeadActivityDraft>.from(activities);
    nextActivities.removeAt(index);
    _replaceActivities(nextActivities, notify: false);
    if (expandedActivityIndex == index) {
      expandedActivityIndex = null;
    } else if ((expandedActivityIndex ?? -1) > index) {
      expandedActivityIndex = expandedActivityIndex! - 1;
    }
    update();
  }

  void _replaceActivities(
    List<LeadActivityDraft> nextActivities, {
    bool notify = true,
  }) {
    final previousActivities = activities;
    activities = List<LeadActivityDraft>.from(nextActivities);
    if (notify) {
      update();
    }
    final removedActivities = previousActivities
        .where(
          (previousActivity) => !activities.any(
            (nextActivity) => identical(previousActivity, nextActivity),
          ),
        )
        .toList(growable: false);
    disposeDraftEntriesNextFrame<LeadActivityDraft>(
      removedActivities,
      (entry) => entry.dispose(),
    );
  }

  String? _validateLeadForm() {
    if (companyId == null) {
      return 'Company is required.';
    }
    if (leadNameController.text.trim().isEmpty) {
      return 'Lead Name is required.';
    }
    if (assignedTo == null) {
      return 'Assigned To is required.';
    }
    return null;
  }

  Future<void> save() async {
    final validationError = _validateLeadForm();
    if (validationError != null) {
      formError = validationError;
      update();
      return;
    }

    saving = true;
    formError = null;
    update();

    final payload = CrmLeadModel.fromJson(normalizeDatePayload({
      'company_id': companyId,
      'lead_name': leadNameController.text.trim(),
      'company_name': nullIfEmpty(companyNameController.text),
      'mobile': nullIfEmpty(mobileController.text),
      'email': nullIfEmpty(emailController.text),
      'source_id': sourceId,
      'assigned_to': assignedTo,
      'lead_status': effectiveLeadStatus(),
      'remarks': nullIfEmpty(remarksController.text),
      'activities': activities
          .map((item) => item.toJson())
          .toList(growable: false),
    }));

    try {
      final response = selectedItem == null
          ? await _crmService.createLead(payload)
          : await _crmService.updateLead(
              intValue(selectedItem!.toJson(), 'id')!,
              payload,
            );
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage(
        selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
      );
      _refreshController.notifyChanged(source: 'crm_leads');
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<bool> delete() async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) return false;
    try {
      final response = await _crmService.deleteLead(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      resetForm();
      _refreshController.notifyChanged(source: 'crm_leads');
      return true;
    } catch (error) {
      formError = error.toString();
      update();
      return false;
    }
  }

  Future<void> markLost() async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) return;

    final validationError = _validateLeadForm();
    if (validationError != null) {
      formError = validationError;
      update();
      return;
    }

    saving = true;
    formError = null;
    update();

    final payload = CrmLeadModel.fromJson(normalizeDatePayload({
      'company_id': companyId,
      'lead_name': leadNameController.text.trim(),
      'company_name': nullIfEmpty(companyNameController.text),
      'mobile': nullIfEmpty(mobileController.text),
      'email': nullIfEmpty(emailController.text),
      'source_id': sourceId,
      'assigned_to': assignedTo,
      'lead_status': 'lost',
      'remarks': nullIfEmpty(remarksController.text),
      'activities': activities
          .map((item) => item.toJson())
          .toList(growable: false),
    }));

    try {
      final response = await _crmService.updateLead(id, payload);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage(selectId: id);
      _refreshController.notifyChanged(source: 'crm_leads');
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<int?> convert({required bool createEnquiry}) async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) return null;
    try {
      final response = await _crmService.convertLead(
        id,
        createEnquiry: createEnquiry,
      );
      final payload = response.data ?? const <String, dynamic>{};
      final enquiryRaw = payload['enquiry'];
      Map<String, dynamic>? enquiryMap;
      if (enquiryRaw is Map) {
        enquiryMap = Map<String, dynamic>.from(enquiryRaw);
      }
      final enquiryId = enquiryMap != null ? intValue(enquiryMap, 'id') : null;
      await loadPage(selectId: id);
      _refreshController.notifyChanged(source: 'crm_leads');
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      return enquiryId;
    } catch (error) {
      formError = error.toString();
      update();
      return null;
    }
  }

  void setFilterSourceIds(Set<int> values) {
    filterSourceIds = Set<int>.from(values);
    update();
  }

  void setFilterAssignedToIds(Set<int> values) {
    filterAssignedToIds = Set<int>.from(values);
    update();
  }

  void setFilterLeadStatuses(Set<String> values) {
    filterLeadStatuses = values;
    update();
  }

  void clearFilters() {
    filterSourceIds = <int>{};
    filterAssignedToIds = <int>{};
    filterLeadStatuses = <String>{};
    filtersApplied = false;
    applySearch();
  }

  void markFiltersApplied() {
    filtersApplied = true;
    applySearch();
  }

  void setSourceId(int? value) {
    sourceId = value;
    update();
  }

  void setAssignedTo(int? value) {
    assignedTo = value;
    update();
  }

  void setExpandedActivityIndex(int? value) {
    expandedActivityIndex = value;
    update();
  }

  void setLeadActivityType(LeadActivityDraft activity, String? value) {
    activity.activityType = value ?? activity.activityType;
    update();
  }

  void setLeadActivityStatus(LeadActivityDraft activity, String? value) {
    activity.status = value ?? activity.status;
    update();
  }

  void setActiveTabIndex(int index) {
    activeTabIndex = index;
    update();
  }
}

class LeadActivityDraft {
  LeadActivityDraft({
    this.id,
    this.leadId,
    this.activityType = 'call',
    this.status = 'pending',
    String? activityDateTime,
    String? notes,
    String? nextFollowup,
    String? draftKey,
  }) : activityDateTimeController = TextEditingController(
         text: displayDateTime(activityDateTime) == ''
             ? currentDateTimeInput()
             : displayDateTime(activityDateTime),
       ),
       notesController = TextEditingController(text: notes ?? ''),
       nextFollowupController = TextEditingController(
         text: displayDateTime(nextFollowup),
       ),
       draftKey =
           draftKey ??
           '${DateTime.now().microsecondsSinceEpoch}-${_draftSequence++}';

  factory LeadActivityDraft.fromJson(Map<String, dynamic> json) {
    return LeadActivityDraft(
      id: intValue(json, 'id'),
      leadId: intValue(json, 'lead_id'),
      activityType: stringValue(json, 'activity_type', 'call'),
      status: stringValue(json, 'status', 'pending'),
      activityDateTime: stringValue(json, 'activity_datetime'),
      notes: stringValue(json, 'notes'),
      nextFollowup: stringValue(json, 'next_followup'),
    );
  }

  int? id;
  int? leadId;
  String activityType;
  String status;
  final TextEditingController activityDateTimeController;
  final TextEditingController notesController;
  final TextEditingController nextFollowupController;
  final String draftKey;

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
      if (id != null) 'id': id,
      if (leadId != null) 'lead_id': leadId,
      'activity_type': activityType,
      'status': status,
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

int _draftSequence = 0;
