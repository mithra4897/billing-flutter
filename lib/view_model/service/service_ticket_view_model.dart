import '../../screen.dart';
import 'service_module_refresh_controller.dart';

class ServiceTicketViewModel extends GetxController {
  ServiceTicketViewModel() {
    searchController.addListener(update);
  }

  final ServiceModuleRefreshController _refreshController =
      ServiceModuleRefreshController.ensureRegistered();
  final ServiceModuleService _service = ServiceModuleService();
  final AuthService _authService = AuthService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController ticketNoController = TextEditingController();
  final TextEditingController ticketDateController = TextEditingController();
  final TextEditingController issueTitleController = TextEditingController();
  final TextEditingController issueDescriptionController =
      TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController contactPersonController = TextEditingController();
  final TextEditingController contactMobileController = TextEditingController();
  final TextEditingController contactEmailController = TextEditingController();
  final TextEditingController itemIdController = TextEditingController();
  final TextEditingController serialIdController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<ServiceTicketModel> rows = const <ServiceTicketModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<PartyModel> parties = const <PartyModel>[];
  List<BranchModel> branches = const <BranchModel>[];
  List<BusinessLocationModel> locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<UserModel> users = const <UserModel>[];
  List<ServiceContractModel> contracts = const <ServiceContractModel>[];
  List<ServiceContractAssetModel> contractAssets =
      const <ServiceContractAssetModel>[];

  ServiceTicketModel? selected;

  int? companyId;
  int? documentSeriesId;
  int? customerPartyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? serviceContractId;
  int? serviceContractAssetId;
  String ticketType = 'complaint';
  String priorityLevel = 'normal';

  int? _sessionCompanyId;
  int? _contextFinancialYearId;

  @override
  void onInit() {
    super.onInit();
    WorkingContextService.version.addListener(_handleWorkingContextChanged);
  }

  String get ticketStatus => stringValue(
    selected?.toJson() ?? const <String, dynamic>{},
    'ticket_status',
  );

  bool get canEdit {
    if (selected == null) {
      return true;
    }
    const blocked = {'closed', 'cancelled', 'rejected'};
    return !blocked.contains(ticketStatus);
  }

  bool get canAssign =>
      selected != null &&
      !['closed', 'cancelled', 'rejected'].contains(ticketStatus);

  bool get canResolve =>
      selected != null &&
      !['closed', 'cancelled', 'rejected', 'resolved'].contains(ticketStatus);

  bool get canClose =>
      selected != null &&
      ['resolved', 'open', 'assigned', 'in_progress'].contains(ticketStatus);

  bool get canCancel => selected != null && ticketStatus != 'closed';

  bool get canDelete =>
      selected != null && (ticketStatus == 'draft' || ticketStatus == 'open');

  int? get selectedId =>
      intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');

  List<DocumentSeriesModel> get ticketSeriesOptions {
    final cid = companyId;
    return documentSeries
        .where((s) {
          if (!s.isActive) {
            return false;
          }
          if (s.documentType != 'SERVICE_TICKET') {
            return false;
          }
          if (cid != null && s.companyId != null && s.companyId != cid) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  List<ServiceTicketModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows
        .where((row) {
          if (q.isEmpty) {
            return true;
          }
          final data = row.toJson();
          return [
            stringValue(data, 'ticket_no'),
            stringValue(data, 'issue_title'),
            stringValue(data, 'ticket_status'),
            _customerLabel(data),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  String _customerLabel(Map<String, dynamic> data) {
    final raw = data['customer'];
    if (raw is Map<String, dynamic>) {
      final d = stringValue(raw, 'display_name');
      if (d.isNotEmpty) {
        return d;
      }
      return stringValue(raw, 'party_name');
    }
    return '';
  }

  String customerLabelFor(Map<String, dynamic> data) => _customerLabel(data);

  String? consumeActionMessage() {
    final message = actionMessage;
    actionMessage = null;
    return message;
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    update();
    try {
      final info = await hrSessionCompanyInfo();
      _sessionCompanyId = info.companyId;
      await MasterDataCache.to.ensureLoaded();
      final cache = MasterDataCache.to;

      final filters = <String, dynamic>{'per_page': 200};
      if (_sessionCompanyId != null) {
        filters['company_id'] = _sessionCompanyId;
      }

      final responses = await Future.wait<dynamic>([
        _service.tickets(filters: filters),
        _authService.users(filters: const {'per_page': 500}),
        _service.contracts(filters: filters),
      ]);

      var rawRows =
          (responses[0] as PaginatedResponse<ServiceTicketModel>).data ??
          const <ServiceTicketModel>[];
      rows = rawRows
          .where(
            (r) => stringValue(r.toJson(), 'ticket_type') != 'warranty_claim',
          )
          .toList(growable: false);

      companies = cache.activeCompanies;
      documentSeries = cache.activeDocumentSeries;
      parties = cache.activeParties;
      branches = cache.activeBranches;
      locations = cache.activeLocations;
      financialYears = cache.activeFinancialYears;
      users =
          ((responses[1] as PaginatedResponse<UserModel>).data ??
                  const <UserModel>[])
              .where((x) => (x.status ?? '').toLowerCase() != 'inactive')
              .toList(growable: false);
      contracts =
          ((responses[2] as PaginatedResponse<ServiceContractModel>).data ??
                  const <ServiceContractModel>[])
              .where((x) {
                final status = (x.contractStatus ?? '').toLowerCase();
                return status == 'active';
              })
              .toList(growable: false);
      _contextFinancialYearId = await _resolveContextFinancialYearId();

      loading = false;

      if (selectId != null) {
        ServiceTicketModel? match;
        for (final r in rows) {
          if (intValue(r.toJson(), 'id') == selectId) {
            match = r;
            break;
          }
        }
        if (match != null) {
          await select(match);
          return;
        }
        if (await restoreSelectionAfterReload<ServiceTicketModel>(
          selectId: selectId,
          rows: rows,
          selected: selected,
          onSelect: select,
          replaceRows: (nextRows) => rows = nextRows,
          notify: update,
          placeholderBuilder: (id) =>
              ServiceTicketModel.fromJson(<String, dynamic>{'id': id}),
        )) {
          return;
        }
      }
      resetDraft();
      update();
    } catch (e) {
      pageError = e.toString();
      loading = false;
      update();
    }
  }

  void resetDraft() {
    selected = null;
    formError = null;
    companyId =
        _sessionCompanyId ?? (companies.isNotEmpty ? companies.first.id : null);
    financialYearId = _defaultFinancialYearId(companyId);
    documentSeriesId = ticketSeriesOptions.isNotEmpty
        ? ticketSeriesOptions.first.id
        : null;
    customerPartyId = null;
    branchId = null;
    locationId = null;
    serviceContractId = null;
    serviceContractAssetId = null;
    contractAssets = const <ServiceContractAssetModel>[];
    ticketType = 'complaint';
    priorityLevel = 'normal';
    ticketNoController.clear();
    ticketDateController.text = displayTodayDate();
    issueTitleController.clear();
    issueDescriptionController.clear();
    notesController.clear();
    contactPersonController.clear();
    contactMobileController.clear();
    contactEmailController.clear();
    itemIdController.clear();
    serialIdController.clear();
    update();
  }

  void setCompanyId(int? value) {
    if (!canEdit) {
      return;
    }
    companyId = value;
    if (documentSeriesId != null) {
      final ok = ticketSeriesOptions.any((s) => s.id == documentSeriesId);
      if (!ok) {
        documentSeriesId = ticketSeriesOptions.isNotEmpty
            ? ticketSeriesOptions.first.id
            : null;
      }
    }
    update();
  }

  void setDocumentSeriesId(int? value) {
    if (!canEdit) {
      return;
    }
    documentSeriesId = value;
    update();
  }

  void setCustomerPartyId(int? value) {
    if (!canEdit) {
      return;
    }
    customerPartyId = value;
    final contractOk =
        serviceContractId == null ||
        contractOptions.any((contract) => contract.id == serviceContractId);
    if (!contractOk) {
      unawaited(setServiceContractId(null));
    }
    update();
  }

  void setTicketType(String? value) {
    if (!canEdit || value == null) {
      return;
    }
    ticketType = value;
    update();
  }

  void setPriorityLevel(String? value) {
    if (!canEdit || value == null) {
      return;
    }
    priorityLevel = value;
    update();
  }

  void setBranchId(int? value) {
    if (!canEdit) {
      return;
    }
    branchId = value;
    update();
  }

  void setLocationId(int? value) {
    if (!canEdit) {
      return;
    }
    locationId = value;
    update();
  }

  void setFinancialYearId(int? value) {
    if (!canEdit) {
      return;
    }
    financialYearId = value;
    update();
  }

  Future<void> setServiceContractId(int? value) async {
    serviceContractId = value;
    serviceContractAssetId = null;
    contractAssets = const <ServiceContractAssetModel>[];
    update();

    if (value == null) {
      return;
    }

    try {
      final response = await _service.contract(value);
      final data = response.data?.toJson() ?? const <String, dynamic>{};
      final rawAssets = data['assets'];
      if (rawAssets is List) {
        contractAssets = rawAssets
            .whereType<Map>()
            .map(
              (item) => ServiceContractAssetModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((asset) => asset.id != null && asset.isActive != false)
            .toList(growable: false);
      }
    } catch (e) {
      formError = e.toString();
    }
    update();
  }

  void setServiceContractAssetId(int? value) {
    if (!canEdit) {
      return;
    }
    serviceContractAssetId = value;
    final asset = contractAssets.cast<ServiceContractAssetModel?>().firstWhere(
      (item) => item?.id == value,
      orElse: () => null,
    );
    if (asset != null) {
      itemIdController.text = asset.itemId?.toString() ?? itemIdController.text;
      serialIdController.text =
          asset.serialId?.toString() ?? serialIdController.text;
    }
    update();
  }

  void _handleWorkingContextChanged() {
    unawaited(load(selectId: selectedId));
  }

  Future<int?> _resolveContextFinancialYearId() async {
    final selection = await WorkingContextService.instance.resolveSelection(
      companies: companies,
      branches: branches,
      locations: locations,
      financialYears: financialYears,
    );
    return selection.financialYearId;
  }

  int? _defaultFinancialYearId(int? companyId) {
    final contextFinancialYearId = _contextFinancialYearId;
    if (contextFinancialYearId != null &&
        financialYears.any(
          (item) =>
              item.id == contextFinancialYearId &&
              (companyId == null || item.companyId == companyId),
        )) {
      return contextFinancialYearId;
    }

    final current = financialYears.cast<FinancialYearModel?>().firstWhere(
      (item) => item?.companyId == companyId && item?.isCurrent == true,
      orElse: () => null,
    );
    if (current?.id != null) {
      return current!.id;
    }

    final fallback = financialYears.cast<FinancialYearModel?>().firstWhere(
      (item) => companyId == null || item?.companyId == companyId,
      orElse: () => null,
    );
    return fallback?.id;
  }

  List<BranchModel> get branchOptions {
    final cid = companyId;
    return branches
        .where((b) {
          if (b.id == null) {
            return false;
          }
          return cid == null || b.companyId == cid;
        })
        .toList(growable: false);
  }

  List<BusinessLocationModel> get locationOptions {
    final cid = companyId;
    final bid = branchId;
    return locations
        .where((l) {
          if (l.id == null) {
            return false;
          }
          if (cid != null && l.companyId != cid) {
            return false;
          }
          if (bid != null && l.branchId != null && l.branchId != bid) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  List<ServiceContractModel> get contractOptions {
    final cid = companyId;
    final customerId = customerPartyId;
    return contracts
        .where((contract) {
          if (contract.id == null) {
            return false;
          }
          if (cid != null && contract.companyId != cid) {
            return false;
          }
          if (customerId != null && contract.customerPartyId != customerId) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
  }

  List<ServiceContractAssetModel> get contractAssetOptions {
    return contractAssets
        .where((asset) => asset.id != null && asset.isActive != false)
        .toList(growable: false);
  }

  List<FinancialYearModel> get financialYearOptions {
    final cid = companyId;
    return financialYears
        .where((f) {
          if (f.id == null) {
            return false;
          }
          return cid == null || f.companyId == cid;
        })
        .toList(growable: false);
  }

  Future<void> select(ServiceTicketModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    formError = null;
    update();
    try {
      final response = await _service.ticket(id);
      final doc = response.data ?? row;
      selected = doc;
      _applyDetail(doc.toJson());
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      update();
    }
  }

  void _applyDetail(Map<String, dynamic> data) {
    companyId = intValue(data, 'company_id');
    customerPartyId = intValue(data, 'customer_party_id');
    branchId = intValue(data, 'branch_id');
    locationId = intValue(data, 'location_id');
    financialYearId = intValue(data, 'financial_year_id');
    documentSeriesId = null;
    ticketNoController.text = stringValue(data, 'ticket_no');
    ticketDateController.text = displayDate(
      nullableStringValue(data, 'ticket_date'),
    );
    issueTitleController.text = stringValue(data, 'issue_title');
    issueDescriptionController.text = stringValue(data, 'issue_description');
    ticketType = stringValue(data, 'ticket_type');
    if (ticketType.trim().isEmpty) {
      ticketType = 'complaint';
    }
    priorityLevel = stringValue(data, 'priority_level');
    if (priorityLevel.trim().isEmpty) {
      priorityLevel = 'normal';
    }
    serviceContractId = intValue(data, 'service_contract_id');
    serviceContractAssetId = intValue(data, 'service_contract_asset_id');
    if (serviceContractId != null) {
      unawaited(
        setServiceContractId(serviceContractId).then((_) {
          serviceContractAssetId = intValue(data, 'service_contract_asset_id');
          update();
        }),
      );
    } else {
      contractAssets = const <ServiceContractAssetModel>[];
    }
    notesController.text = stringValue(data, 'notes');
    contactPersonController.text = stringValue(data, 'contact_person_name');
    contactMobileController.text = stringValue(data, 'contact_mobile');
    contactEmailController.text = stringValue(data, 'contact_email');
    itemIdController.text = intValue(data, 'item_id')?.toString() ?? '';
    serialIdController.text = intValue(data, 'serial_id')?.toString() ?? '';
  }

  String? _validateSave() {
    if (companyId == null) {
      return 'Company is required.';
    }
    if (customerPartyId == null) {
      return 'Customer is required.';
    }
    if (ticketDateController.text.trim().isEmpty) {
      return 'Ticket date is required.';
    }
    if (issueTitleController.text.trim().isEmpty) {
      return 'Issue title is required.';
    }
    final manualNo = ticketNoController.text.trim();
    if (manualNo.isEmpty && documentSeriesId == null) {
      return 'Enter a ticket number or select a document series.';
    }
    return null;
  }

  Map<String, dynamic> _buildCreatePayload() {
    final itemId = int.tryParse(itemIdController.text.trim());
    final serialId = int.tryParse(serialIdController.text.trim());
    final ticketNo = ticketNoController.text.trim();
    return <String, dynamic>{
      'company_id': companyId,
      'customer_party_id': customerPartyId,
      'ticket_date': ticketDateController.text.trim(),
      'issue_title': issueTitleController.text.trim(),
      'ticket_type': ticketType,
      'priority_level': priorityLevel,
      'issue_description': nullIfEmpty(issueDescriptionController.text),
      'notes': nullIfEmpty(notesController.text),
      'contact_person_name': nullIfEmpty(contactPersonController.text),
      'contact_mobile': nullIfEmpty(contactMobileController.text),
      'contact_email': nullIfEmpty(contactEmailController.text),
      if (branchId != null) 'branch_id': branchId,
      if (locationId != null) 'location_id': locationId,
      if (financialYearId != null) 'financial_year_id': financialYearId,
      'service_contract_id': ?serviceContractId,
      'service_contract_asset_id': ?serviceContractAssetId,
      'item_id': ?itemId,
      'serial_id': ?serialId,
      'document_series_id': ?documentSeriesId,
      if (ticketNo.isNotEmpty) 'ticket_no': ticketNo,
    };
  }

  Map<String, dynamic> _buildUpdatePayload() {
    final itemId = int.tryParse(itemIdController.text.trim());
    final serialId = int.tryParse(serialIdController.text.trim());
    final data = selected?.toJson() ?? const <String, dynamic>{};
    final ticketNo = ticketNoController.text.trim();
    return <String, dynamic>{
      'company_id': companyId,
      'customer_party_id': customerPartyId,
      'ticket_date': ticketDateController.text.trim(),
      'issue_title': issueTitleController.text.trim(),
      'ticket_type': ticketType,
      'ticket_status': stringValue(data, 'ticket_status'),
      'priority_level': priorityLevel,
      'issue_description': nullIfEmpty(issueDescriptionController.text),
      'notes': nullIfEmpty(notesController.text),
      'contact_person_name': nullIfEmpty(contactPersonController.text),
      'contact_mobile': nullIfEmpty(contactMobileController.text),
      'contact_email': nullIfEmpty(contactEmailController.text),
      if (branchId != null) 'branch_id': branchId,
      if (locationId != null) 'location_id': locationId,
      if (financialYearId != null) 'financial_year_id': financialYearId,
      'service_contract_id': ?serviceContractId,
      'service_contract_asset_id': ?serviceContractAssetId,
      'item_id': ?itemId,
      'serial_id': ?serialId,
      if (ticketNo.isNotEmpty) 'ticket_no': ticketNo,
    };
  }

  Future<void> save() async {
    final err = _validateSave();
    if (err != null) {
      formError = err;
      update();
      return;
    }
    saving = true;
    formError = null;
    actionMessage = null;
    update();
    try {
      if (selected == null) {
        final response = await _service.createTicket(
          ServiceTicketModel.fromJson(_buildCreatePayload()),
        );
        actionMessage = response.message;
        await load(selectId: intValue(response.data?.toJson() ?? {}, 'id'));
        _refreshController.notifyChanged(source: 'service_ticket');
      } else {
        final id = selectedId;
        if (id == null) {
          formError = 'Missing ticket id.';
          update();
          return;
        }
        final response = await _service.updateTicket(
          id,
          ServiceTicketModel.fromJson(_buildUpdatePayload()),
        );
        actionMessage = response.message;
        await load(selectId: id);
        _refreshController.notifyChanged(source: 'service_ticket');
      }
    } catch (e) {
      formError = e.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> assignTicket({int? assignedToUserId}) async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.assignTicket(
        id,
        assignedToUserId: assignedToUserId,
      );
      actionMessage = response.message;
      await load(selectId: id);
      _refreshController.notifyChanged(source: 'service_ticket');
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  Future<void> resolveTicket() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.resolveTicket(id);
      actionMessage = response.message;
      await load(selectId: id);
      _refreshController.notifyChanged(source: 'service_ticket');
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  Future<void> closeTicket() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.closeTicket(id);
      actionMessage = response.message;
      await load(selectId: id);
      _refreshController.notifyChanged(source: 'service_ticket');
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  Future<void> cancelTicket() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.cancelTicket(id);
      actionMessage = response.message;
      await load(selectId: id);
      _refreshController.notifyChanged(source: 'service_ticket');
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  Future<void> deleteTicket() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      await _service.deleteTicket(id);
      actionMessage = 'Ticket deleted.';
      await load();
      _refreshController.notifyChanged(source: 'service_ticket');
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  @override
  void onClose() {
    WorkingContextService.version.removeListener(_handleWorkingContextChanged);
    searchController.dispose();
    ticketNoController.dispose();
    ticketDateController.dispose();
    issueTitleController.dispose();
    issueDescriptionController.dispose();
    notesController.dispose();
    contactPersonController.dispose();
    contactMobileController.dispose();
    contactEmailController.dispose();
    itemIdController.dispose();
    serialIdController.dispose();
    super.onClose();
  }
}
