import '../../screen.dart';

class CrmLeadsController extends GetxController {
  static const int allFilterIntValue = 0;
  static const String allFilterStringValue = '__all__';
  static const List<AppDropdownItem<String>> leadFilterStatuses =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'new', label: 'New'),
        AppDropdownItem(value: 'in_progress', label: 'In Progress'),
        AppDropdownItem(value: 'converted', label: 'Converted'),
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
  int? filterSourceId;
  int? filterAssignedTo;
  String? filterLeadStatus;
  String leadStatus = 'new';
  List<LeadActivityDraft> activities = <LeadActivityDraft>[];
  int? expandedActivityIndex;
  Map<String, dynamic>? salesChain;
  bool appliedInitialNewMode = false;
  bool filtersApplied = false;

  bool get isSelectedLeadReadOnly =>
      selectedItem != null && isLockedLeadStatus(leadStatus);

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(applySearch);
    loadPage(selectId: initialSelectId);
  }

  @override
  void onClose() {
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(applySearch)
      ..dispose();
    leadNameController.dispose();
    companyNameController.dispose();
    mobileController.dispose();
    emailController.dispose();
    remarksController.dispose();
    disposeActivities(activities);
    super.onClose();
  }

  static bool isCompletedLead(CrmLeadModel item) {
    final status = stringValue(item.toJson(), 'lead_status');
    return status == 'converted' || status == 'lost';
  }

  static bool isLockedLeadStatus(String status) =>
      status == 'converted' || status == 'lost';

  String effectiveLeadStatus() {
    final status = leadStatus.trim().toLowerCase();
    if (status == 'converted' || status == 'lost') {
      return status;
    }
    if (activities.isNotEmpty) {
      return 'in_progress';
    }
    return 'new';
  }

  String leadStatusLabel([String? status]) {
    switch ((status ?? effectiveLeadStatus()).trim().toLowerCase()) {
      case 'in_progress':
        return 'In Progress';
      case 'converted':
        return 'Converted';
      case 'lost':
        return 'Lost';
      case 'new':
      default:
        return 'New';
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
              final requestedStatus =
                  (filtersApplied
                          ? (filterLeadStatus ?? allFilterStringValue)
                          : (filterLeadStatus ?? ''))
                      .trim();
              final showAllStatuses =
                  filtersApplied && requestedStatus == allFilterStringValue;
              if (completed &&
                  !showAllStatuses &&
                  requestedStatus != rowStatus) {
                return false;
              }
              if (filterCompanyId != null &&
                  intValue(data, 'company_id') != filterCompanyId) {
                return false;
              }
              if (filterSourceId != null &&
                  filterSourceId != allFilterIntValue &&
                  intValue(data, 'source_id') != filterSourceId) {
                return false;
              }
              if (filterAssignedTo != null &&
                  filterAssignedTo != allFilterIntValue &&
                  intValue(data, 'assigned_to') != filterAssignedTo) {
                return false;
              }
              if ((filterLeadStatus ?? '').isNotEmpty &&
                  filterLeadStatus != allFilterStringValue &&
                  rowStatus != filterLeadStatus) {
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
    final nextActivities =
        (data['activities'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(LeadActivityDraft.fromJson)
            .toList(growable: true);

    disposeActivities(activities);
    selectedItem = full;
    companyId = intValue(data, 'company_id');
    sourceId = intValue(data, 'source_id');
    assignedTo = intValue(data, 'assigned_to');
    leadStatus = stringValue(data, 'lead_status', 'new');
    leadNameController.text = stringValue(data, 'lead_name');
    companyNameController.text = stringValue(data, 'company_name');
    mobileController.text = stringValue(data, 'mobile');
    emailController.text = stringValue(data, 'email');
    remarksController.text = stringValue(data, 'remarks');
    activities = nextActivities;
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
    disposeActivities(activities);
    selectedItem = null;
    companyId = contextCompanyId;
    sourceId = null;
    assignedTo = null;
    leadStatus = 'new';
    leadNameController.clear();
    companyNameController.clear();
    mobileController.clear();
    emailController.clear();
    remarksController.clear();
    activities = <LeadActivityDraft>[];
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
    nextActivities.removeAt(index).dispose();
    activities = nextActivities;
    if (expandedActivityIndex == index) {
      expandedActivityIndex = null;
    } else if ((expandedActivityIndex ?? -1) > index) {
      expandedActivityIndex = expandedActivityIndex! - 1;
    }
    update();
  }

  Future<void> save() async {
    saving = true;
    formError = null;
    update();

    final payload = CrmLeadModel.fromJson({
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
    });

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
    } catch (error) {
      formError = error.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> delete() async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) return;
    try {
      final response = await _crmService.deleteLead(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage();
    } catch (error) {
      formError = error.toString();
      update();
    }
  }

  Future<void> markLost() async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) return;

    saving = true;
    formError = null;
    update();

    final payload = CrmLeadModel.fromJson({
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
    });

    try {
      final response = await _crmService.updateLead(id, payload);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage(selectId: id);
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

  void setFilterSourceId(int? value) {
    filterSourceId = value;
    update();
  }

  void setFilterAssignedTo(int? value) {
    filterAssignedTo = value;
    update();
  }

  void setFilterLeadStatus(String? value) {
    filterLeadStatus = value;
    update();
  }

  void clearFilters() {
    filterSourceId = null;
    filterAssignedTo = null;
    filterLeadStatus = null;
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

  void setActiveTabIndex(int index) {
    activeTabIndex = index;
    update();
  }
}

class LeadActivityDraft {
  LeadActivityDraft({
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

  factory LeadActivityDraft.fromJson(Map<String, dynamic> json) {
    return LeadActivityDraft(
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
