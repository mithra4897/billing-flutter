import '../../screen.dart';
import 'crm_module_refresh_controller.dart';

class CrmOpportunitiesController extends GetxController {
  static const int allFilterIntValue = 0;
  static const String allFilterStringValue = '__all__';
  static const List<AppDropdownItem<String>> filterStatusItems =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'open', label: 'Open'),
        AppDropdownItem(value: 'lost', label: 'Lost'),
        AppDropdownItem(value: 'won', label: 'Won'),
      ];
  static const List<AppDropdownItem<String>> followupStatuses =
      <AppDropdownItem<String>>[
        AppDropdownItem(value: 'pending', label: 'Pending'),
        AppDropdownItem(value: 'done', label: 'Done'),
        AppDropdownItem(value: 'skipped', label: 'Skipped'),
      ];

  CrmOpportunitiesController({
    required this.instanceTag,
    required this.startInNewMode,
    required this.initialSelectId,
    required this.initialLeadId,
    required this.initialCompanyId,
    required this.initialAssignedTo,
  });

  final String instanceTag;
  final bool startInNewMode;
  final int? initialSelectId;
  final int? initialLeadId;
  final int? initialCompanyId;
  final int? initialAssignedTo;

  final CrmService _crmService = CrmService();
  final AuthService _authService = AuthService();
  final CrmModuleRefreshController _refreshController =
      CrmModuleRefreshController.ensureRegistered();
  final ScrollController pageScrollController = ScrollController();
  final SettingsWorkspaceController workspaceController =
      SettingsWorkspaceController();
  final TextEditingController searchController = TextEditingController();
  GlobalKey<FormState>? formKey;
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController expectedValueController = TextEditingController();
  final TextEditingController probabilityController = TextEditingController();
  final TextEditingController expectedCloseDateController =
      TextEditingController();
  final TextEditingController filterCloseFromController =
      TextEditingController();
  final TextEditingController filterCloseToController = TextEditingController();

  int activeTabIndex = 0;
  bool initialLoading = true;
  bool saving = false;
  String? pageError;
  String? formError;
  List<CrmOpportunityModel> items = const <CrmOpportunityModel>[];
  List<CrmOpportunityModel> filteredItems = const <CrmOpportunityModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<CrmLeadModel> leads = const <CrmLeadModel>[];
  List<PartyModel> customers = const <PartyModel>[];
  List<CrmStageModel> stages = const <CrmStageModel>[];
  List<UserModel> users = const <UserModel>[];
  List<ItemModel> itemsLookup = const <ItemModel>[];
  CrmOpportunityModel? selectedItem;
  int? contextCompanyId;
  int? companyId;
  int? leadId;
  int? customerPartyId;
  int? stageId;
  int? assignedTo;
  Set<int> filterStageIds = <int>{};
  Set<String> filterStatuses = <String>{'open'};
  String status = 'open';
  List<OpportunityLineDraft> lines = <OpportunityLineDraft>[];
  List<OpportunityFollowupDraft> followups = <OpportunityFollowupDraft>[];
  List<OpportunityProductDraft> products = <OpportunityProductDraft>[];
  int? expandedLineIndex;
  int? expandedFollowupIndex;
  int? expandedProductIndex;
  Map<String, dynamic>? salesChain;
  bool appliedInitialNewMode = false;
  bool filtersApplied = false;
  Worker? _refreshWorker;
  String? _autofilledOpportunityName;
  String? _autofilledRemarks;

  String _displayExpectedValue(Map<String, dynamic> data) {
    final raw = stringValue(data, 'expected_value');
    final parsed = double.tryParse(raw.trim());
    if (parsed != null && parsed == 0) {
      return '';
    }
    return raw;
  }

  bool get isSelectedOpportunityReadOnly {
    final data = selectedItem?.toJson() ?? const <String, dynamic>{};
    final lifecycleStatus = stringValue(
      data,
      'status',
      status,
    ).trim().toLowerCase();
    return lifecycleStatus == 'won' ||
        lifecycleStatus == 'lost' ||
        lifecycleStatus == 'converted';
  }

  bool get canManageFollowups => selectedItem != null;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(applySearch);
    _refreshWorker = ever<CrmModuleRefreshEvent?>(
      _refreshController.lastEvent,
      (event) {
        if (event == null || event.source == 'crm_opportunities') {
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
    pageScrollController.dispose();
    workspaceController.dispose();
    searchController
      ..removeListener(applySearch)
      ..dispose();
    remarksController.dispose();
    nameController.dispose();
    expectedValueController.dispose();
    probabilityController.dispose();
    expectedCloseDateController.dispose();
    filterCloseFromController.dispose();
    filterCloseToController.dispose();
    disposeLines(lines);
    disposeFollowups(followups);
    disposeProducts(products);
    super.onClose();
  }

  String normalizedStageType(CrmStageModel stage) =>
      stringValue(stage.toJson(), 'stage_type').trim().toLowerCase();

  bool isAllowedOpportunityStage(CrmStageModel stage) {
    final type = normalizedStageType(stage);
    return type == 'opportunity' ||
        type == 'closed_won' ||
        type == 'closed_lost' ||
        type == 'closed won' ||
        type == 'closed lost';
  }

  Future<void> loadPage({int? selectId}) async {
    initialLoading = items.isEmpty;
    pageError = null;
    update();

    try {
      await MasterDataCache.to.ensureLoaded();
      final cache = MasterDataCache.to;
      final responses = await Future.wait<dynamic>([
        _crmService.opportunities(
          filters: const {'per_page': 200, 'sort_by': 'opportunity_name'},
        ),
        _crmService.leads(
          filters: const {'per_page': 300, 'sort_by': 'lead_name'},
        ),
        _crmService.stages(
          filters: const {'per_page': 200, 'sort_by': 'sequence_no'},
        ),
        _authService.users(
          filters: const {'per_page': 200, 'sort_by': 'username'},
        ),
      ]);

      items =
          (responses[0] as PaginatedResponse<CrmOpportunityModel>).data ??
          const <CrmOpportunityModel>[];
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: cache.activeCompanies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );
      companies = cache.activeCompanies;
      leads =
          (responses[1] as PaginatedResponse<CrmLeadModel>).data ??
          const <CrmLeadModel>[];
      customers = cache.activeParties;
      stages = () {
        final allStages =
            ((responses[2] as PaginatedResponse<CrmStageModel>).data ??
                    const <CrmStageModel>[])
                .where(
                  (item) =>
                      boolValue(item.toJson(), 'is_active', fallback: true),
                )
                .toList(growable: false);
        final filtered = allStages
            .where(isAllowedOpportunityStage)
            .toList(growable: false);
        return filtered.isNotEmpty ? filtered : allStages;
      }();
      users =
          ((responses[3] as PaginatedResponse<UserModel>).data ??
                  const <UserModel>[])
              .where((item) => (item.status ?? 'active') == 'active')
              .toList();
      itemsLookup = cache.activeItems;
      contextCompanyId = contextSelection.companyId;
      initialLoading = false;
      applySearch(notify: false);

      if (startInNewMode && selectId == null && !appliedInitialNewMode) {
        appliedInitialNewMode = true;
        await startNewDraft(notify: false);
        update();
        return;
      }

      final selected = selectId != null
          ? items.cast<CrmOpportunityModel?>().firstWhere(
              (item) => intValue(item?.toJson() ?? const {}, 'id') == selectId,
              orElse: () => null,
            )
          : (selectedItem == null
                ? (items.isNotEmpty ? items.first : null)
                : items.cast<CrmOpportunityModel?>().firstWhere(
                    (item) =>
                        intValue(item?.toJson() ?? const {}, 'id') ==
                        intValue(selectedItem!.toJson(), 'id'),
                    orElse: () => items.isNotEmpty ? items.first : null,
                  ));

      if (selected == null && selectId != null) {
        try {
          final detail = (await _crmService.opportunity(selectId)).data;
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

  void applySearch({bool notify = true}) {
    filteredItems =
        filterMasterList(items, searchController.text, (item) {
              final data = item.toJson();
              final customer =
                  JsonModel.mapOf(data['customer']) ??
                  const <String, dynamic>{};
              final stage =
                  JsonModel.mapOf(data['stage']) ?? const <String, dynamic>{};
              final lead =
                  JsonModel.mapOf(data['lead']) ?? const <String, dynamic>{};
              return [
                stringValue(data, 'opportunity_name'),
                stringValue(data, 'enquiry_no'),
                stringValue(data, 'status'),
                stringValue(data, 'expected_value'),
                stringValue(customer, 'display_name'),
                stringValue(customer, 'party_name'),
                stringValue(stage, 'stage_name'),
                stringValue(lead, 'lead_name'),
              ];
            })
            .where((item) {
              final data = item.toJson();
              final closeDate = displayDate(
                nullableStringValue(data, 'expected_close_date'),
              );
              final filterFrom = filterCloseFromController.text.trim();
              final filterTo = filterCloseToController.text.trim();
              if (filterStageIds.isNotEmpty &&
                  !filterStageIds.contains(intValue(data, 'stage_id'))) {
                return false;
              }
              if (filterStatuses.isNotEmpty &&
                  !filterStatuses.contains(
                    stringValue(data, 'status').trim().toLowerCase(),
                  )) {
                return false;
              }
              if (filterFrom.isNotEmpty &&
                  (closeDate.isEmpty || closeDate.compareTo(filterFrom) < 0)) {
                return false;
              }
              if (filterTo.isNotEmpty &&
                  (closeDate.isEmpty || closeDate.compareTo(filterTo) > 0)) {
                return false;
              }
              return true;
            })
            .toList(growable: false);
    if (notify) update();
  }

  List<ErpLinkFieldOption<int>> get itemPickerOptions => itemsLookup
      .where((item) => item.id != null)
      .map(itemOption)
      .toList(growable: false);

  ErpLinkFieldOption<int>? selectedItemOption(int? itemId) {
    if (itemId == null) {
      return null;
    }

    final item = itemsLookup.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );

    return item == null ? null : itemOption(item);
  }

  ErpLinkFieldOption<int> itemOption(ItemModel item) {
    final subtitleParts = <String>[
      item.itemCode,
      item.itemType ?? '',
    ].where((value) => value.trim().isNotEmpty).toList(growable: false);

    return ErpLinkFieldOption<int>(
      value: item.id!,
      label: item.toString(),
      subtitle: subtitleParts.isEmpty ? null : subtitleParts.join(' • '),
      searchText: item.pickerSearchText,
    );
  }

  Future<void> selectItem(
    CrmOpportunityModel item, {
    bool notify = true,
  }) async {
    final id = intValue(item.toJson(), 'id');
    if (id == null) return;
    final response = await _crmService.opportunity(id);
    final full = response.data ?? item;
    final data = full.toJson();
    final nextLines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(OpportunityLineDraft.fromJson)
        .toList(growable: true);
    final nextFollowups =
        (data['followups'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(OpportunityFollowupDraft.fromJson)
            .toList(growable: true);
    final nextProducts =
        (data['products'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(OpportunityProductDraft.fromJson)
            .toList(growable: true);

    selectedItem = full;
    companyId = intValue(data, 'company_id');
    leadId = intValue(data, 'lead_id');
    customerPartyId = intValue(data, 'customer_party_id');
    stageId = intValue(data, 'stage_id');
    assignedTo = intValue(data, 'assigned_to');
    status = stringValue(data, 'status', 'open');
    remarksController.text = stringValue(data, 'remarks');
    nameController.text = stringValue(data, 'opportunity_name');
    expectedValueController.text = _displayExpectedValue(data);
    probabilityController.text = stringValue(data, 'probability_percent');
    expectedCloseDateController.text = displayDate(
      nullableStringValue(data, 'expected_close_date'),
    );
    _autofilledOpportunityName = null;
    _autofilledRemarks = null;
    _replaceLines(nextLines, notify: false);
    _replaceFollowups(nextFollowups, notify: false);
    _replaceProducts(nextProducts, notify: false);
    expandedLineIndex = null;
    expandedFollowupIndex = null;
    expandedProductIndex = null;
    formError = null;
    await refreshSalesChainForOpportunity(id);
    if (notify) update();
  }

  int? selectedOpportunityId() =>
      intValue(selectedItem?.toJson() ?? const {}, 'id');

  Future<void> refreshSalesChainForOpportunity(int opportunityId) async {
    try {
      final response = await _crmService.salesChain(
        opportunityId: opportunityId,
      );
      salesChain = response.data;
    } catch (_) {
      salesChain = null;
    }
  }

  void resetForm({bool notify = true}) {
    selectedItem = null;
    companyId = contextCompanyId;
    leadId = null;
    customerPartyId = null;
    stageId = null;
    assignedTo = null;
    status = 'open';
    remarksController.clear();
    nameController.clear();
    expectedValueController.clear();
    probabilityController.clear();
    expectedCloseDateController.clear();
    _autofilledOpportunityName = null;
    _autofilledRemarks = null;
    _replaceLines(const <OpportunityLineDraft>[], notify: false);
    _replaceFollowups(const <OpportunityFollowupDraft>[], notify: false);
    _replaceProducts(const <OpportunityProductDraft>[], notify: false);
    expandedLineIndex = null;
    expandedFollowupIndex = null;
    expandedProductIndex = null;
    formError = null;
    activeTabIndex = 0;
    salesChain = null;
    if (notify) update();
  }

  Future<void> startNewDraft({int? leadId, bool notify = true}) async {
    resetForm(notify: false);
    await applyInitialOpportunityDraft(leadId: leadId, notify: false);
    if (notify) {
      update();
    }
  }

  Future<void> applyInitialOpportunityDraft({
    int? leadId,
    bool notify = true,
  }) async {
    final lead = await _resolveInitialLead(leadId: leadId);
    selectedItem = null;
    companyId =
        initialCompanyId ?? lead?.companyId ?? companyId ?? contextCompanyId;
    this.leadId = leadId ?? initialLeadId ?? this.leadId;
    assignedTo = initialAssignedTo ?? lead?.assignedTo ?? assignedTo;
    _applyLeadAutofill(lead, forceTextValues: true);
    formError = null;
    if (notify) {
      update();
    }
  }

  Future<CrmLeadModel?> _resolveInitialLead({int? leadId}) async {
    final requestedLeadId = leadId ?? initialLeadId;
    if (requestedLeadId == null) {
      return null;
    }

    final listLead = leads.cast<CrmLeadModel?>().firstWhere(
      (item) =>
          intValue(item?.toJson() ?? const <String, dynamic>{}, 'id') ==
          requestedLeadId,
      orElse: () => null,
    );
    if (listLead != null) {
      return listLead;
    }

    try {
      return (await _crmService.lead(requestedLeadId)).data;
    } catch (_) {
      return null;
    }
  }

  CrmLeadModel? _leadById(int? id) {
    if (id == null) {
      return null;
    }

    return leads.cast<CrmLeadModel?>().firstWhere(
      (item) =>
          intValue(item?.toJson() ?? const <String, dynamic>{}, 'id') == id,
      orElse: () => null,
    );
  }

  void _applyLeadAutofill(CrmLeadModel? lead, {bool forceTextValues = false}) {
    if (lead == null) {
      _autofilledOpportunityName = null;
      _autofilledRemarks = null;
      return;
    }

    final data = lead.toJson();
    final nextCompanyId = intValue(data, 'company_id');
    final nextAssignedTo = intValue(data, 'assigned_to');
    final nextOpportunityName = stringValue(data, 'lead_name');
    final nextRemarks = stringValue(data, 'remarks');

    if (nextCompanyId != null) {
      companyId = nextCompanyId;
    }
    if (nextAssignedTo != null) {
      assignedTo = nextAssignedTo;
    }

    final currentOpportunityName = nameController.text.trim();
    final previousAutofilledName = (_autofilledOpportunityName ?? '').trim();
    if (forceTextValues ||
        currentOpportunityName.isEmpty ||
        (previousAutofilledName.isNotEmpty &&
            currentOpportunityName == previousAutofilledName)) {
      nameController.text = nextOpportunityName;
    }

    final currentRemarks = remarksController.text.trim();
    final previousAutofilledRemarks = (_autofilledRemarks ?? '').trim();
    if (forceTextValues ||
        currentRemarks.isEmpty ||
        (previousAutofilledRemarks.isNotEmpty &&
            currentRemarks == previousAutofilledRemarks)) {
      remarksController.text = nextRemarks;
    }

    _autofilledOpportunityName = nextOpportunityName;
    _autofilledRemarks = nextRemarks;
  }

  void disposeLines(List<OpportunityLineDraft> source) {
    for (final line in source) {
      line.dispose();
    }
  }

  void disposeFollowups(List<OpportunityFollowupDraft> source) {
    for (final followup in source) {
      followup.dispose();
    }
  }

  void addLine() {
    lines = List<OpportunityLineDraft>.from(lines)..add(OpportunityLineDraft());
    expandedLineIndex = lines.length - 1;
    update();
  }

  void removeLine(int index) {
    final nextLines = List<OpportunityLineDraft>.from(lines);
    nextLines.removeAt(index);
    _replaceLines(nextLines, notify: false);
    if (expandedLineIndex == index) {
      expandedLineIndex = null;
    } else if ((expandedLineIndex ?? -1) > index) {
      expandedLineIndex = expandedLineIndex! - 1;
    }
    update();
  }

  void addFollowup() {
    followups = List<OpportunityFollowupDraft>.from(followups)
      ..add(OpportunityFollowupDraft(assignedTo: assignedTo));
    expandedFollowupIndex = followups.length - 1;
    update();
  }

  void removeFollowup(int index) {
    final nextFollowups = List<OpportunityFollowupDraft>.from(followups);
    nextFollowups.removeAt(index);
    _replaceFollowups(nextFollowups, notify: false);
    if (expandedFollowupIndex == index) {
      expandedFollowupIndex = null;
    } else if ((expandedFollowupIndex ?? -1) > index) {
      expandedFollowupIndex = expandedFollowupIndex! - 1;
    }
    update();
  }

  void disposeProducts(List<OpportunityProductDraft> source) {
    for (final product in source) {
      product.dispose();
    }
  }

  void addProduct() {
    products = List<OpportunityProductDraft>.from(products)
      ..add(OpportunityProductDraft());
    expandedProductIndex = products.length - 1;
    update();
  }

  void removeProduct(int index) {
    final nextProducts = List<OpportunityProductDraft>.from(products);
    nextProducts.removeAt(index);
    _replaceProducts(nextProducts, notify: false);
    if (expandedProductIndex == index) {
      expandedProductIndex = null;
    } else if ((expandedProductIndex ?? -1) > index) {
      expandedProductIndex = expandedProductIndex! - 1;
    }
    update();
  }

  void _replaceLines(
    List<OpportunityLineDraft> nextLines, {
    bool notify = true,
  }) {
    replaceDisposableDraftEntries<OpportunityLineDraft>(
      previous: lines,
      next: nextLines,
      createEmpty: () => OpportunityLineDraft(),
      assign: (entries) => lines = entries,
      dispose: (entry) => entry.dispose(),
      notify: notify ? update : null,
    );
  }

  void _replaceFollowups(
    List<OpportunityFollowupDraft> nextFollowups, {
    bool notify = true,
  }) {
    replaceDisposableDraftEntries<OpportunityFollowupDraft>(
      previous: followups,
      next: nextFollowups,
      createEmpty: () => OpportunityFollowupDraft(),
      assign: (entries) => followups = entries,
      dispose: (entry) => entry.dispose(),
      notify: notify ? update : null,
    );
  }

  void _replaceProducts(
    List<OpportunityProductDraft> nextProducts, {
    bool notify = true,
  }) {
    replaceDisposableDraftEntries<OpportunityProductDraft>(
      previous: products,
      next: nextProducts,
      createEmpty: () => OpportunityProductDraft(),
      assign: (entries) => products = entries,
      dispose: (entry) => entry.dispose(),
      notify: notify ? update : null,
    );
  }

  Future<void> save() async {
    final activeFormState = formKey?.currentState;
    if (activeFormState != null && !activeFormState.validate()) {
      return;
    }
    if (selectedItem != null) {
      final followupValidationError = _validateFollowups();
      if (followupValidationError != null) {
        formError = followupValidationError;
        appScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(followupValidationError)),
        );
        update();
        return;
      }
    }
    saving = true;
    formError = null;
    update();

    final payload = <String, dynamic>{
      'company_id': companyId,
      'lead_id': leadId,
      'customer_party_id': customerPartyId,
      'opportunity_name': nameController.text.trim(),
      'expected_value':
          double.tryParse(expectedValueController.text.trim()) ?? 0,
      'stage_id': stageId,
      'assigned_to': assignedTo,
      'remarks': nullIfEmpty(remarksController.text),
      'probability_percent':
          double.tryParse(probabilityController.text.trim()) ?? 0,
      'expected_close_date': nullIfEmpty(expectedCloseDateController.text),
      'status': status,
      'lines': lines.map((item) => item.toJson()).toList(growable: false),
      'products': products.map((item) => item.toJson()).toList(growable: false),
    };

    if (selectedItem != null) {
      payload['followups'] = followups
          .map((item) => item.toJson())
          .toList(growable: false);
    }

    try {
      final response = selectedItem == null
          ? await _crmService.createOpportunity(normalizeDatePayload(payload))
          : await _crmService.updateOpportunity(
              intValue(selectedItem!.toJson(), 'id')!,
              normalizeDatePayload(payload),
            );
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage(
        selectId: intValue(response.data?.toJson() ?? const {}, 'id'),
      );
      _refreshController.notifyChanged(source: 'crm_opportunities');
    } catch (error) {
      formError = error.toString();
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(formError!)),
      );
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
      final response = await _crmService.deleteOpportunity(id);
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage();
      _refreshController.notifyChanged(source: 'crm_opportunities');
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
      await loadPage(selectId: _filterAllowsStatus('won') ? id : null);
      _refreshController.notifyChanged(source: 'crm_opportunities');
    } catch (error) {
      formError = error.toString();
      update();
    }
  }

  Future<void> lose() async {
    final id = intValue(selectedItem?.toJson() ?? const {}, 'id');
    if (id == null) return;
    try {
      final response = await _crmService.loseOpportunity(
        id,
        CrmOpportunityModel.fromJson(const <String, dynamic>{}),
      );
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(response.message)),
      );
      await loadPage(selectId: _filterAllowsStatus('lost') ? id : null);
      _refreshController.notifyChanged(source: 'crm_opportunities');
    } catch (error) {
      formError = error.toString();
      update();
    }
  }

  void setFilterStageIds(Set<int> values) {
    filterStageIds = Set<int>.from(values);
    update();
  }

  void setFilterStatuses(Set<String> values) {
    filterStatuses = values
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();
    update();
  }

  void clearFilters() {
    filterStageIds = <int>{};
    filterStatuses = <String>{'open'};
    filtersApplied = false;
    filterCloseFromController.clear();
    filterCloseToController.clear();
    applySearch();
  }

  void markFiltersApplied() {
    filtersApplied = true;
    applySearch();
  }

  void setStageId(int? value) {
    stageId = value;
    update();
  }

  Future<void> setLeadId(int? value) async {
    leadId = value;
    _applyLeadAutofill(_leadById(value), forceTextValues: false);
    update();
  }

  void setCustomerPartyId(int? value) {
    customerPartyId = value;
    update();
  }

  void setAssignedTo(int? value) {
    assignedTo = value;
    for (final followup in followups) {
      followup.assignedTo ??= value;
    }
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

  void setFollowupAssignedTo(OpportunityFollowupDraft followup, int? value) {
    followup.assignedTo = value;
    update();
  }

  void setFollowupStatus(OpportunityFollowupDraft followup, String? value) {
    followup.status = value ?? 'pending';
    update();
  }

  void setExpandedProductIndex(int? value) {
    expandedProductIndex = value;
    update();
  }

  void setActiveTabIndex(int index) {
    activeTabIndex = index;
    update();
  }

  String? _validateFollowups() {
    for (var index = 0; index < followups.length; index++) {
      final followup = followups[index];
      final rowNumber = index + 1;
      if (followup.followupDateController.text.trim().isEmpty) {
        return 'Followup date is required for followup $rowNumber.';
      }
      if ((followup.assignedTo ?? assignedTo) == null) {
        return 'Assigned To is required for followup $rowNumber.';
      }
      if (followup.notesController.text.trim().isEmpty) {
        return 'Notes are required for followup $rowNumber.';
      }
    }
    return null;
  }

  bool _filterAllowsStatus(String statusValue) {
    final normalized = statusValue.trim().toLowerCase();
    if (filterStatuses.isEmpty) {
      return true;
    }
    return filterStatuses.contains(normalized);
  }
}

class OpportunityProductDraft {
  OpportunityProductDraft({
    this.id,
    this.itemId,
    String? qty,
    String? estimatedPrice,
  }) : qtyController = TextEditingController(text: qty ?? ''),
       estimatedPriceController = TextEditingController(
         text: estimatedPrice ?? '',
       );

  factory OpportunityProductDraft.fromJson(Map<String, dynamic> json) {
    return OpportunityProductDraft(
      id: intValue(json, 'id'),
      itemId: intValue(json, 'item_id'),
      qty: stringValue(json, 'qty'),
      estimatedPrice: stringValue(json, 'estimated_price'),
    );
  }

  int? id;
  int? itemId;
  final TextEditingController qtyController;
  final TextEditingController estimatedPriceController;

  String itemLabel(List<ItemModel> items) {
    final item = items.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );
    return item?.toString() ?? 'Enquiry Product';
  }

  String get qtySummary {
    final qty = qtyController.text.trim();
    return qty.isNotEmpty ? 'Qty $qty' : '';
  }

  String get priceSummary {
    final price = estimatedPriceController.text.trim();
    return price.isNotEmpty ? 'Price $price' : '';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'qty': double.tryParse(qtyController.text.trim()) ?? 0,
      'estimated_price':
          double.tryParse(estimatedPriceController.text.trim()) ?? 0,
    };
  }

  void dispose() {
    qtyController.dispose();
    estimatedPriceController.dispose();
  }
}

class OpportunityLineDraft {
  OpportunityLineDraft({this.id, this.itemId, String? description, String? qty})
    : descriptionController = TextEditingController(text: description ?? ''),
      qtyController = TextEditingController(text: qty ?? '');

  factory OpportunityLineDraft.fromJson(Map<String, dynamic> json) {
    return OpportunityLineDraft(
      id: intValue(json, 'id'),
      itemId: intValue(json, 'item_id'),
      description: stringValue(json, 'description'),
      qty: stringValue(json, 'qty'),
    );
  }

  int? id;
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
    return description.isNotEmpty ? description : 'Enquiry Line';
  }

  String get qtySummary {
    final qty = qtyController.text.trim();
    return qty.isNotEmpty ? 'Qty $qty' : '';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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

class OpportunityFollowupDraft {
  OpportunityFollowupDraft({
    this.id,
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

  factory OpportunityFollowupDraft.fromJson(Map<String, dynamic> json) {
    return OpportunityFollowupDraft(
      id: intValue(json, 'id'),
      assignedTo: intValue(json, 'assigned_to'),
      status: stringValue(json, 'status', 'pending'),
      followupDate: stringValue(json, 'followup_date'),
      notes: stringValue(json, 'notes'),
      nextFollowup: stringValue(json, 'next_followup'),
    );
  }

  int? id;
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
      'id': id,
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
