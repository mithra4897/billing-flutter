import '../../screen.dart';

class CrmEnquiriesController extends GetxController {
  static const int allFilterIntValue = 0;
  static const String allFilterStringValue = '__all__';
  static const List<AppDropdownItem<String>> filterStatusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'open', label: 'Open'),
        AppDropdownItem(value: 'in_progress', label: 'In Progress'),
        AppDropdownItem(value: 'converted', label: 'Won'),
        AppDropdownItem(value: 'lost', label: 'Lost'),
      ];
  static const List<AppDropdownItem<String>> followupStatuses =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'pending', label: 'Pending'),
        AppDropdownItem(value: 'done', label: 'Done'),
        AppDropdownItem(value: 'skipped', label: 'Skipped'),
      ];

  CrmEnquiriesController({
    required this.startInNewMode,
    required this.initialSelectId,
  });

  final bool startInNewMode;
  final int? initialSelectId;

  final CrmService _crmService = CrmService();
  final MasterService _masterService = MasterService();
  final AuthService _authService = AuthService();
  final PartiesService _partiesService = PartiesService();
  final InventoryService _inventoryService = InventoryService();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController enquiryNoController = TextEditingController();
  final TextEditingController enquiryDateController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController filterDateFromController =
      TextEditingController();
  final TextEditingController filterDateToController = TextEditingController();

  int activeTabIndex = 0;
  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<CrmEnquiryModel> items = const <CrmEnquiryModel>[];
  List<CrmEnquiryModel> filteredItems = const <CrmEnquiryModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<CrmLeadModel> leads = const <CrmLeadModel>[];
  List<PartyModel> customers = const <PartyModel>[];
  List<CrmStageModel> stages = const <CrmStageModel>[];
  List<UserModel> users = const <UserModel>[];
  List<ItemModel> itemsLookup = const <ItemModel>[];
  CrmEnquiryModel? selectedItem;
  int? contextCompanyId;
  int? companyId;
  int? leadId;
  int? customerPartyId;
  int? stageId;
  int? assignedTo;
  int? filterCustomerPartyId;
  int? filterStageId;
  int? filterAssignedTo;
  String? filterEnquiryStatus;
  String enquiryStatus = 'open';
  String opportunityStatus = 'open';
  List<EnquiryLineDraft> lines = <EnquiryLineDraft>[];
  List<FollowupDraft> followups = <FollowupDraft>[];
  int? expandedLineIndex;
  int? expandedFollowupIndex;
  Map<String, dynamic>? salesChain;
  bool appliedInitialNewMode = false;
  bool filtersApplied = false;

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
    enquiryNoController.dispose();
    enquiryDateController.dispose();
    remarksController.dispose();
    filterDateFromController.dispose();
    filterDateToController.dispose();
    disposeLines(lines);
    disposeFollowups(followups);
    super.onClose();
  }

  static bool isHiddenByDefaultEnquiry(CrmEnquiryModel item) {
    final data = item.toJson();
    final lifecycleStatus = stringValue(data, 'status') == 'won'
        ? 'won'
        : stringValue(data, 'enquiry_status');
    return lifecycleStatus == 'won' || lifecycleStatus == 'lost';
  }

  static bool isLockedEnquiryStatus(String status) => status == 'lost';

  String normalizedStageType(CrmStageModel stage) {
    return stringValue(stage.toJson(), 'stage_type').trim().toLowerCase();
  }

  bool isAllowedEnquiryStage(CrmStageModel stage) {
    final type = normalizedStageType(stage);
    return type == 'enquiry' ||
        type == 'opportunity' ||
        type == 'closed_won' ||
        type == 'closed_lost' ||
        type == 'closed won' ||
        type == 'closed lost';
  }

  String lifecycleStatusForStageType(String type) {
    switch (type.trim().toLowerCase()) {
      case 'opportunity':
        return 'in_progress';
      case 'closed_won':
      case 'closed won':
        return 'won';
      case 'closed_lost':
      case 'closed lost':
        return 'lost';
      default:
        return 'open';
    }
  }

  String effectiveLifecycleStatus() {
    final nextOpportunityStatus = opportunityStatus.trim().toLowerCase();
    if (nextOpportunityStatus == 'won' || nextOpportunityStatus == 'lost') {
      return nextOpportunityStatus;
    }
    final nextEnquiryStatus = enquiryStatus.trim().toLowerCase();
    if (nextEnquiryStatus == 'lost') {
      return nextEnquiryStatus;
    }
    final selectedStage = stages.cast<CrmStageModel?>().firstWhere(
      (item) => intValue(item?.toJson() ?? const {}, 'id') == stageId,
      orElse: () => null,
    );
    if (selectedStage != null) {
      return lifecycleStatusForStageType(normalizedStageType(selectedStage));
    }
    if (nextEnquiryStatus == 'in_progress') {
      return nextEnquiryStatus;
    }
    return nextOpportunityStatus == 'open' ? nextEnquiryStatus : nextOpportunityStatus;
  }

  String lifecycleStatusLabel([String? status]) {
    final value = (status ?? effectiveLifecycleStatus()).trim().toLowerCase();
    switch (value) {
      case 'in_progress':
        return 'In Progress';
      case 'won':
        return 'Won';
      case 'lost':
        return 'Lost';
      default:
        return 'Open';
    }
  }

  Future<void> loadPage({int? selectId}) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();

    try {
      final responses = await Future.wait<dynamic>([
        _crmService.enquiries(
          filters: const {'per_page': 200, 'sort_by': 'enquiry_date'},
        ),
        _masterService.companies(
          filters: const {'per_page': 100, 'sort_by': 'legal_name'},
        ),
        _crmService.leads(
          filters: const {'per_page': 300, 'sort_by': 'lead_name'},
        ),
        _partiesService.parties(
          filters: const {'per_page': 300, 'sort_by': 'party_name'},
        ),
        _crmService.stages(
          filters: const {'per_page': 200, 'sort_by': 'sequence_no'},
        ),
        _authService.users(
          filters: const {'per_page': 200, 'sort_by': 'username'},
        ),
        _inventoryService.items(
          filters: const {'per_page': 300, 'sort_by': 'item_name'},
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
          (responses[0] as PaginatedResponse<CrmEnquiryModel>).data ??
              const <CrmEnquiryModel>[];
      companies = nextCompanies.where((item) => item.isActive).toList();
      leads = (responses[2] as PaginatedResponse<CrmLeadModel>).data ??
          const <CrmLeadModel>[];
      customers =
          ((responses[3] as PaginatedResponse<PartyModel>).data ??
                  const <PartyModel>[])
              .where((item) => item.isActive)
              .toList();
      stages = () {
        final allStages =
            ((responses[4] as PaginatedResponse<CrmStageModel>).data ??
                    const <CrmStageModel>[])
                .where((item) => boolValue(item.toJson(), 'is_active', fallback: true))
                .toList(growable: false);
        final filtered =
            allStages.where(isAllowedEnquiryStage).toList(growable: false);
        return filtered.isNotEmpty ? filtered : allStages;
      }();
      users = ((responses[5] as PaginatedResponse<UserModel>).data ??
              const <UserModel>[])
          .where((item) => (item.status ?? 'active') == 'active')
          .toList();
      itemsLookup = ((responses[6] as PaginatedResponse<ItemModel>).data ??
              const <ItemModel>[])
          .where((item) => item.isActive)
          .toList();
      contextCompanyId = contextSelection.companyId;
      initialLoading = false;
      applySearch(notify: false);

      if (startInNewMode && selectId == null && !appliedInitialNewMode) {
        appliedInitialNewMode = true;
        resetForm(notify: false);
        update();
        return;
      }

      final selected = selectId != null
          ? items.cast<CrmEnquiryModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (selectedItem == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<CrmEnquiryModel?>().firstWhere(
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

  void applySearch({bool notify = true}) {
    filteredItems = filterMasterList(items, searchController.text, (item) {
          final data = item.toJson();
          return [
            stringValue(data, 'enquiry_no'),
            displayDate(nullableStringValue(data, 'enquiry_date')),
            lifecycleStatusLabel(
              stringValue(data, 'status') == 'won'
                  ? 'won'
                  : stringValue(data, 'enquiry_status'),
            ),
            stringValue(data, 'remarks'),
          ];
        })
        .where((item) {
          final data = item.toJson();
          final hidden = isHiddenByDefaultEnquiry(item);
          final rowStatus = stringValue(data, 'status') == 'won'
              ? 'converted'
              : stringValue(data, 'enquiry_status');
          final requestedStatus =
              (filtersApplied ? (filterEnquiryStatus ?? allFilterStringValue) : (filterEnquiryStatus ?? ''))
                  .trim();
          final showAllStatuses =
              filtersApplied && requestedStatus == allFilterStringValue;
          if (hidden && !showAllStatuses && requestedStatus != rowStatus) {
            return false;
          }
          final enquiryDate = displayDate(
            nullableStringValue(data, 'enquiry_date'),
          );
          final filterFrom = filterDateFromController.text.trim();
          final filterTo = filterDateToController.text.trim();
          if (filterCustomerPartyId != null &&
              intValue(data, 'customer_party_id') != filterCustomerPartyId) {
            return false;
          }
          if (filterStageId != null &&
              intValue(data, 'stage_id') != filterStageId) {
            return false;
          }
          if (filterAssignedTo != null &&
              intValue(data, 'assigned_to') != filterAssignedTo) {
            return false;
          }
          if ((filterEnquiryStatus ?? '').isNotEmpty &&
              filterEnquiryStatus != allFilterStringValue &&
              rowStatus != filterEnquiryStatus) {
            return false;
          }
          if (filterFrom.isNotEmpty &&
              (enquiryDate.isEmpty || enquiryDate.compareTo(filterFrom) < 0)) {
            return false;
          }
          if (filterTo.isNotEmpty &&
              (enquiryDate.isEmpty || enquiryDate.compareTo(filterTo) > 0)) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
    if (notify) update();
  }

  ErpLinkFieldOption<int>? selectedLeadOption() {
    final selectedId = leadId;
    if (selectedId == null) return null;
    final lead = leads.cast<CrmLeadModel?>().firstWhere(
      (item) => intValue(item?.toJson() ?? const {}, 'id') == selectedId,
      orElse: () => null,
    );
    return lead == null ? null : leadOption(lead);
  }

  ErpLinkFieldOption<int> leadOption(CrmLeadModel lead) {
    final data = lead.toJson();
    final label = lead.toString();
    final companyName = stringValue(data, 'company_name');
    final mobile = stringValue(data, 'mobile');
    final email = stringValue(data, 'email');
    final subtitle = [companyName, mobile, email]
        .where((value) => value.trim().isNotEmpty)
        .join(' • ');
    return ErpLinkFieldOption<int>(
      value: intValue(data, 'id')!,
      label: label,
      subtitle: subtitle.isEmpty ? null : subtitle,
      searchText: [label, companyName, mobile, email].join(' '),
    );
  }

  int? assignedToFromLead(int? id) {
    final lead = leads.cast<CrmLeadModel?>().firstWhere(
      (item) => intValue(item?.toJson() ?? const {}, 'id') == id,
      orElse: () => null,
    );
    if (lead == null) return null;
    return intValue(lead.toJson(), 'assigned_to');
  }

  Future<List<ErpLinkFieldOption<int>>> searchLeadOptions(String query) async {
    final normalized = query.trim().toLowerCase();
    return leads
        .where((lead) => intValue(lead.toJson(), 'id') != null)
        .where((lead) {
          if (normalized.isEmpty) return true;
          final data = lead.toJson();
          final haystack = [
            lead.toString(),
            stringValue(data, 'company_name'),
            stringValue(data, 'mobile'),
            stringValue(data, 'email'),
            stringValue(data, 'lead_status'),
          ].join(' ').toLowerCase();
          return haystack.contains(normalized);
        })
        .map(leadOption)
        .toList(growable: false);
  }

  Future<void> selectItem(
    CrmEnquiryModel item, {
    bool notify = true,
  }) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) return;
    final response = await _crmService.enquiry(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final nextLines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(EnquiryLineDraft.fromJson)
        .toList(growable: true);
    final nextFollowups =
        (data['followups'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(FollowupDraft.fromJson)
            .toList(growable: true);

    disposeLines(lines);
    disposeFollowups(followups);
    selectedItem = full;
    companyId = intValue(data, 'company_id');
    leadId = intValue(data, 'lead_id');
    customerPartyId = intValue(data, 'customer_party_id');
    stageId = intValue(data, 'stage_id');
    assignedTo = intValue(data, 'assigned_to');
    enquiryStatus = stringValue(data, 'enquiry_status', 'open');
    opportunityStatus = stringValue(data, 'status', 'open');
    enquiryNoController.text = stringValue(data, 'enquiry_no');
    enquiryDateController.text = displayDate(
      nullableStringValue(data, 'enquiry_date'),
    );
    remarksController.text = stringValue(data, 'remarks');
    lines = nextLines;
    followups = nextFollowups;
    expandedLineIndex = null;
    expandedFollowupIndex = null;
    formError = null;
    await refreshSalesChainForEnquiry(id);
    if (notify) update();
  }

  int? pipelineOpportunityId() {
    final lifecycleStatus = effectiveLifecycleStatus();
    if (lifecycleStatus == 'in_progress' || lifecycleStatus == 'won') {
      final selectedId = intValue(selectedItem?.toJson() ?? const {}, 'id');
      if (selectedId != null) return selectedId;
    }
    final raw = salesChain?['opportunity'];
    if (raw is Map &&
        (lifecycleStatus == 'in_progress' || lifecycleStatus == 'won')) {
      return intValue(Map<String, dynamic>.from(raw), 'id');
    }
    return null;
  }

  bool isSelectedEnquiryLocked() {
    final status = stringValue(
      selectedItem?.toJson() ?? const <String, dynamic>{},
      'enquiry_status',
      enquiryStatus,
    );
    return isLockedEnquiryStatus(status) ||
        opportunityStatus == 'won' ||
        opportunityStatus == 'lost';
  }

  Future<void> refreshSalesChainForEnquiry(int enquiryId) async {
    try {
      final response = await _crmService.salesChain(enquiryId: enquiryId);
      salesChain = response.data;
    } catch (_) {
      salesChain = null;
    }
  }

  void resetForm({bool notify = true}) {
    disposeLines(lines);
    disposeFollowups(followups);
    selectedItem = null;
    companyId = contextCompanyId;
    leadId = null;
    customerPartyId = null;
    stageId = null;
    assignedTo = null;
    enquiryStatus = 'open';
    opportunityStatus = 'open';
    enquiryNoController.clear();
    enquiryDateController.text = DateTime.now().toIso8601String().split('T').first;
    remarksController.clear();
    lines = <EnquiryLineDraft>[];
    followups = <FollowupDraft>[];
    expandedLineIndex = null;
    expandedFollowupIndex = null;
    formError = null;
    activeTabIndex = 0;
    salesChain = null;
    if (notify) update();
  }

  void disposeLines(List<EnquiryLineDraft> source) {
    for (final line in source) {
      line.dispose();
    }
  }

  void disposeFollowups(List<FollowupDraft> source) {
    for (final followup in source) {
      followup.dispose();
    }
  }

  void addLine() {
    lines = List<EnquiryLineDraft>.from(lines)..add(EnquiryLineDraft());
    expandedLineIndex = lines.length - 1;
    update();
  }

  void removeLine(int index) {
    final nextLines = List<EnquiryLineDraft>.from(lines);
    nextLines.removeAt(index).dispose();
    lines = nextLines;
    if (expandedLineIndex == index) {
      expandedLineIndex = null;
    } else if ((expandedLineIndex ?? -1) > index) {
      expandedLineIndex = expandedLineIndex! - 1;
    }
    update();
  }

  void addFollowup() {
    followups = List<FollowupDraft>.from(followups)..add(FollowupDraft());
    expandedFollowupIndex = followups.length - 1;
    update();
  }

  void removeFollowup(int index) {
    final nextFollowups = List<FollowupDraft>.from(followups);
    nextFollowups.removeAt(index).dispose();
    followups = nextFollowups;
    if (expandedFollowupIndex == index) {
      expandedFollowupIndex = null;
    } else if ((expandedFollowupIndex ?? -1) > index) {
      expandedFollowupIndex = expandedFollowupIndex! - 1;
    }
    update();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    saving = true;
    formError = null;
    update();

    final payload = CrmEnquiryModel.fromJson({
      'company_id': companyId,
      'enquiry_no': nullIfEmpty(enquiryNoController.text),
      'enquiry_date': nullIfEmpty(enquiryDateController.text),
      'lead_id': leadId,
      'customer_party_id': customerPartyId,
      'stage_id': stageId,
      'assigned_to': assignedTo,
      'remarks': nullIfEmpty(remarksController.text),
      'lines': lines.map((item) => item.toJson()).toList(growable: false),
      'followups':
          followups.map((item) => item.toJson()).toList(growable: false),
    });

    try {
      final response = selectedItem == null
          ? await _crmService.createEnquiry(payload)
          : await _crmService.updateEnquiry(
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
      final response = await _crmService.deleteEnquiry(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage();
    } catch (error) {
      formError = error.toString();
      update();
    }
  }

  Future<void> lose() async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) return;
    try {
      final response = await _crmService.loseEnquiry(
        id,
        CrmEnquiryModel.fromJson(const <String, dynamic>{}),
      );
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage(selectId: id);
    } catch (error) {
      formError = error.toString();
      update();
    }
  }

  Future<void> win() async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) return;
    try {
      final response = await _crmService.winOpportunity(
        id,
        CrmOpportunityModel.fromJson(const <String, dynamic>{}),
      );
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage(selectId: id);
    } catch (error) {
      formError = error.toString();
      update();
    }
  }

  void setLeadId(int? value) {
    leadId = value;
    assignedTo = assignedToFromLead(value);
    formError = null;
    update();
  }

  void setCustomerPartyId(int? value) {
    customerPartyId = value;
    update();
  }

  void setStageId(int? value) {
    stageId = value;
    update();
  }

  void setAssignedTo(int? value) {
    assignedTo = value;
    update();
  }

  void setExpandedLineIndex(int? value) {
    expandedLineIndex = value;
    update();
  }

  void setExpandedFollowupIndex(int? value) {
    expandedFollowupIndex = value;
    update();
  }

  void setFollowupAssignedTo(FollowupDraft followup, int? value) {
    followup.assignedTo = value;
    update();
  }

  void setFollowupStatus(FollowupDraft followup, String? value) {
    followup.status = value ?? 'pending';
    update();
  }

  void setFilterCustomerPartyId(int? value) {
    filterCustomerPartyId = value == allFilterIntValue ? null : value;
    update();
  }

  void setFilterStageId(int? value) {
    filterStageId = value == allFilterIntValue ? null : value;
    update();
  }

  void setFilterAssignedTo(int? value) {
    filterAssignedTo = value == allFilterIntValue ? null : value;
    update();
  }

  void setFilterEnquiryStatus(String? value) {
    filterEnquiryStatus = value;
    update();
  }

  void clearFilters() {
    filterCustomerPartyId = null;
    filterStageId = null;
    filterAssignedTo = null;
    filterEnquiryStatus = null;
    filtersApplied = false;
    filterDateFromController.clear();
    filterDateToController.clear();
    applySearch();
  }

  void markFiltersApplied() {
    filtersApplied = true;
    applySearch();
  }

  void setActiveTabIndex(int index) {
    activeTabIndex = index;
    update();
  }
}

class EnquiryLineDraft {
  EnquiryLineDraft({this.itemId, String? description, String? qty})
    : descriptionController = TextEditingController(text: description ?? ''),
      qtyController = TextEditingController(text: qty ?? '');

  factory EnquiryLineDraft.fromJson(Map<String, dynamic> json) {
    return EnquiryLineDraft(
      itemId: intValue(json, 'item_id'),
      description: stringValue(json, 'description'),
      qty: stringValue(json, 'qty'),
    );
  }

  int? itemId;
  final TextEditingController descriptionController;
  final TextEditingController qtyController;

  String itemLabel(List<ItemModel> items) {
    final item = items.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );
    final itemLabel = item?.toString();
    if ((itemLabel ?? '').trim().isNotEmpty) {
      return itemLabel!.trim();
    }
    final description = descriptionController.text.trim();
    return description.isNotEmpty ? description : 'Opportunity Line';
  }

  String get qtySummary {
    final qty = qtyController.text.trim();
    return qty.isNotEmpty ? 'Qty $qty' : '';
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'description': nullIfEmpty(descriptionController.text),
      'qty': double.tryParse(qtyController.text.trim()) ?? 0,
    };
  }

  void dispose() {
    descriptionController.dispose();
    qtyController.dispose();
  }
}

class FollowupDraft {
  FollowupDraft({
    this.assignedTo,
    this.status = 'pending',
    String? followupDate,
    String? notes,
    String? nextFollowup,
  }) : followupDateController = TextEditingController(
         text: displayDateTime(followupDate) == ''
             ? currentDateTimeInput()
             : displayDateTime(followupDate),
       ),
       notesController = TextEditingController(text: notes ?? ''),
       nextFollowupController = TextEditingController(
         text: displayDateTime(nextFollowup),
       );

  factory FollowupDraft.fromJson(Map<String, dynamic> json) {
    return FollowupDraft(
      assignedTo: intValue(json, 'assigned_to'),
      status: stringValue(json, 'status', 'pending'),
      followupDate: stringValue(json, 'followup_date'),
      notes: stringValue(json, 'notes'),
      nextFollowup: stringValue(json, 'next_followup'),
    );
  }

  int? assignedTo;
  String status;
  final TextEditingController followupDateController;
  final TextEditingController notesController;
  final TextEditingController nextFollowupController;

  String get statusLabel {
    switch (status) {
      case 'done':
        return 'Done';
      case 'skipped':
        return 'Skipped';
      default:
        return 'Pending';
    }
  }

  String assigneeLabel(List<UserModel> users) {
    final user = users.cast<UserModel?>().firstWhere(
      (entry) => entry?.id == assignedTo,
      orElse: () => null,
    );
    return user?.displayName ?? user?.username ?? '';
  }

  Map<String, dynamic> toJson() {
    return {
      'assigned_to': assignedTo,
      'status': status,
      'followup_date': nullIfEmpty(followupDateController.text),
      'notes': nullIfEmpty(notesController.text),
      'next_followup': nullIfEmpty(nextFollowupController.text),
    };
  }

  void dispose() {
    followupDateController.dispose();
    notesController.dispose();
    nextFollowupController.dispose();
  }
}
