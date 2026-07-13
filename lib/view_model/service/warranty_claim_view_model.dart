import '../../screen.dart';
import 'service_module_refresh_controller.dart';

class WarrantyClaimViewModel extends GetxController {
  WarrantyClaimViewModel() {
    searchController.addListener(update);
  }

  final ServiceModuleRefreshController _refreshController =
      ServiceModuleRefreshController.ensureRegistered();
  final ServiceModuleService _service = ServiceModuleService();
  final AuthService _authService = AuthService();
  final InventoryService _inventoryService = InventoryService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController ticketNoController = TextEditingController();
  final TextEditingController ticketDateController = TextEditingController();
  final TextEditingController issueTitleController = TextEditingController();
  final TextEditingController issueDescriptionController =
      TextEditingController();
  final TextEditingController priorityController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController contactPersonController = TextEditingController();
  final TextEditingController contactMobileController = TextEditingController();
  final TextEditingController contactEmailController = TextEditingController();
  final TextEditingController itemIdController = TextEditingController();
  final TextEditingController serialIdController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  bool actionBusy = false;
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
  List<ItemModel> items = const <ItemModel>[];
  List<StockSerialModel> serials = const <StockSerialModel>[];
  List<ServiceWorkOrderModel> workOrders = const <ServiceWorkOrderModel>[];

  ServiceTicketModel? selected;

  int? companyId;
  int? documentSeriesId;
  int? customerPartyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? serviceContractId;
  int? serviceContractAssetId;

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

  List<ServiceWorkOrderModel> get selectedWorkOrders {
    final id = selectedId;
    if (id == null) {
      return const <ServiceWorkOrderModel>[];
    }
    return workOrders
        .where((workOrder) => workOrder.serviceTicketId == id)
        .toList(growable: false);
  }

  ServiceWorkOrderModel? get selectedWorkOrder => selectedWorkOrders
      .cast<ServiceWorkOrderModel?>()
      .firstWhere((workOrder) => workOrder != null, orElse: () => null);

  bool get hasWorkOrder => selectedWorkOrder != null;

  String get workOrderButtonLabel {
    final workOrder = selectedWorkOrder;
    if (workOrder == null) {
      return 'Create work order';
    }
    final no = (workOrder.workOrderNo ?? '').trim();
    return no.isEmpty ? 'Work order created' : 'Work order $no created';
  }

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

  List<DocumentSeriesModel> get woSeriesOptions {
    final cid = companyId;
    return documentSeries
        .where((s) {
          if (!s.isActive) {
            return false;
          }
          if (s.documentType != 'SERVICE_WORK_ORDER') {
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
        _service.warrantyClaims(filters: filters),
        _authService.users(filters: const {'per_page': 500}),
        _service.contracts(filters: filters),
        _inventoryService.stockSerials(filters: filters),
        _service.workOrders(filters: filters),
      ]);

      rows =
          (responses[0] as PaginatedResponse<ServiceTicketModel>).data ??
          const <ServiceTicketModel>[];

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
              .where((x) => x.contractStatus == 'active')
              .toList(growable: false);
      items = cache.activeItems;
      serials =
          (responses[3] as PaginatedResponse<StockSerialModel>).data ??
          const <StockSerialModel>[];
      workOrders =
          (responses[4] as PaginatedResponse<ServiceWorkOrderModel>).data ??
          const <ServiceWorkOrderModel>[];
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
    ticketNoController.clear();
    ticketDateController.text = displayTodayDate();
    issueTitleController.clear();
    issueDescriptionController.clear();
    priorityController.text = 'normal';
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

  void setItemId(int? value) {
    if (!canEdit) {
      return;
    }
    itemIdController.text = value?.toString() ?? '';
    final currentSerialId = serialId;
    if (currentSerialId != null &&
        !serialOptions.any((serial) => serial.id == currentSerialId)) {
      serialIdController.clear();
    }
    update();
  }

  void setSerialId(int? value) {
    if (!canEdit) {
      return;
    }
    serialIdController.text = value?.toString() ?? '';
    final serial = selectedSerial;
    if (serial?.itemId != null && itemId == null) {
      itemIdController.text = serial!.itemId!.toString();
    }
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
          final type = (contract.contractType ?? '').toLowerCase();
          return type == 'warranty' || type == 'extended_warranty';
        })
        .toList(growable: false);
  }

  List<ServiceContractAssetModel> get contractAssetOptions {
    return contractAssets
        .where((asset) => asset.id != null && asset.isActive != false)
        .toList(growable: false);
  }

  int? get itemId => int.tryParse(itemIdController.text.trim());
  int? get serialId => int.tryParse(serialIdController.text.trim());

  ItemModel? get selectedItem => items.cast<ItemModel?>().firstWhere(
    (item) => item?.id == itemId,
    orElse: () => null,
  );

  StockSerialModel? get selectedSerial => serials
      .cast<StockSerialModel?>()
      .firstWhere((serial) => serial?.id == serialId, orElse: () => null);

  List<ItemModel> get itemOptions {
    final cid = companyId;
    return items
        .where((item) {
          if (item.id == null || !item.isActive) {
            return false;
          }
          return cid == null || item.companyId == cid;
        })
        .toList(growable: false);
  }

  List<StockSerialModel> get serialOptions {
    final selectedItemId = itemId;
    return serials
        .where((serial) {
          if (serial.id == null) {
            return false;
          }
          return selectedItemId == null || serial.itemId == selectedItemId;
        })
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
      final response = await _service.warrantyClaim(id);
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
    priorityController.text = stringValue(data, 'priority_level');
    if (priorityController.text.trim().isEmpty) {
      priorityController.text = 'normal';
    }
    notesController.text = stringValue(data, 'notes');
    contactPersonController.text = stringValue(data, 'contact_person_name');
    contactMobileController.text = stringValue(data, 'contact_mobile');
    contactEmailController.text = stringValue(data, 'contact_email');
    itemIdController.text = intValue(data, 'item_id')?.toString() ?? '';
    serialIdController.text = intValue(data, 'serial_id')?.toString() ?? '';
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
    final itemId = int.tryParse(itemIdController.text.trim());
    if (itemId == null) {
      return 'Item id is required for warranty claims.';
    }
    final manualNo = ticketNoController.text.trim();
    if (manualNo.isEmpty && documentSeriesId == null) {
      return 'Enter a ticket number or select a document series.';
    }
    return null;
  }

  Map<String, dynamic> _buildCreatePayload() {
    final itemId = int.tryParse(itemIdController.text.trim())!;
    final serialId = int.tryParse(serialIdController.text.trim());
    final ticketNo = ticketNoController.text.trim();
    return <String, dynamic>{
      'company_id': companyId,
      'customer_party_id': customerPartyId,
      'ticket_date': ticketDateController.text.trim(),
      'item_id': itemId,
      'priority_level': nullIfEmpty(priorityController.text) ?? 'normal',
      'issue_title': nullIfEmpty(issueTitleController.text),
      'issue_description': nullIfEmpty(issueDescriptionController.text),
      'notes': nullIfEmpty(notesController.text),
      'contact_person_name': nullIfEmpty(contactPersonController.text),
      'contact_mobile': nullIfEmpty(contactMobileController.text),
      'contact_email': nullIfEmpty(contactEmailController.text),
      if (branchId != null) 'branch_id': branchId,
      if (locationId != null) 'location_id': locationId,
      if (financialYearId != null) 'financial_year_id': financialYearId,
      'serial_id': ?serialId,
      'service_contract_id': ?serviceContractId,
      'service_contract_asset_id': ?serviceContractAssetId,
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
      'ticket_type': stringValue(data, 'ticket_type'),
      'ticket_status': stringValue(data, 'ticket_status'),
      'priority_level': nullIfEmpty(priorityController.text) ?? 'normal',
      'issue_title': nullIfEmpty(issueTitleController.text),
      'issue_description': nullIfEmpty(issueDescriptionController.text),
      'notes': nullIfEmpty(notesController.text),
      'contact_person_name': nullIfEmpty(contactPersonController.text),
      'contact_mobile': nullIfEmpty(contactMobileController.text),
      'contact_email': nullIfEmpty(contactEmailController.text),
      if (branchId != null) 'branch_id': branchId,
      if (locationId != null) 'location_id': locationId,
      if (financialYearId != null) 'financial_year_id': financialYearId,
      'item_id': ?itemId,
      'serial_id': ?serialId,
      'service_contract_id': ?serviceContractId,
      'service_contract_asset_id': ?serviceContractAssetId,
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
        final response = await _service.createWarrantyClaim(
          ServiceTicketModel.fromJson(_buildCreatePayload()),
        );
        actionMessage = response.message;
        _refreshController.notifyChanged(source: 'warranty_claim');
        await load(selectId: intValue(response.data?.toJson() ?? {}, 'id'));
      } else {
        final id = selectedId;
        if (id == null) {
          formError = 'Missing claim id.';
          update();
          return;
        }
        final response = await _service.updateWarrantyClaim(
          id,
          ServiceTicketModel.fromJson(_buildUpdatePayload()),
        );
        actionMessage = response.message;
        _refreshController.notifyChanged(source: 'warranty_claim');
        await load(selectId: id);
      }
    } catch (e) {
      formError = e.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> assignClaim({int? assignedToUserId}) async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.assignWarrantyClaim(
        id,
        assignedToUserId: assignedToUserId,
      );
      actionMessage = response.message;
      _refreshController.notifyChanged(source: 'warranty_claim');
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  Future<void> resolveClaim() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.resolveWarrantyClaim(id);
      actionMessage = response.message;
      _refreshController.notifyChanged(source: 'warranty_claim');
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  Future<void> closeClaim() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.closeWarrantyClaim(id);
      actionMessage = response.message;
      _refreshController.notifyChanged(source: 'warranty_claim');
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  Future<void> cancelClaim() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.cancelWarrantyClaim(id);
      actionMessage = response.message;
      _refreshController.notifyChanged(source: 'warranty_claim');
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  Future<void> deleteClaim() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      await _service.deleteWarrantyClaim(id);
      actionMessage = 'Warranty claim deleted.';
      _refreshController.notifyChanged(source: 'warranty_claim');
      await load();
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  Future<void> createWorkOrderFromClaim({Map<String, dynamic>? body}) async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    actionBusy = true;
    update();
    try {
      final seriesId = woSeriesOptions.isNotEmpty
          ? woSeriesOptions.first.id
          : null;
      final response = await _service.createWorkOrderFromWarrantyClaim(
        id,
        body: {'document_series_id': ?seriesId, ...?body},
      );
      if (response.success) {
        actionMessage = response.message.isNotEmpty
            ? response.message
            : 'Work order created.';
      } else {
        formError = response.message;
      }
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      update();
    } finally {
      actionBusy = false;
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
    priorityController.dispose();
    notesController.dispose();
    contactPersonController.dispose();
    contactMobileController.dispose();
    contactEmailController.dispose();
    itemIdController.dispose();
    serialIdController.dispose();
    super.onClose();
  }
}
