import 'package:billing/screen.dart';
import 'package:billing/view/hr/hr_workflow_dialogs.dart';
import 'package:billing/view/purchase/purchase_support.dart';

class ServiceWorkOrderViewModel extends ChangeNotifier {
  ServiceWorkOrderViewModel() {
    searchController.addListener(notifyListeners);
  }

  final ServiceModuleService _service = ServiceModuleService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController workOrderNoController = TextEditingController();
  final TextEditingController workOrderDateController = TextEditingController();
  final TextEditingController diagnosisNotesController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController resolutionSummaryController =
      TextEditingController();
  final TextEditingController actionTakenController = TextEditingController();
  final TextEditingController customerSiteAddressController =
      TextEditingController();
  final TextEditingController technicianUserIdController =
      TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<ServiceWorkOrderModel> rows = const <ServiceWorkOrderModel>[];
  List<ServiceTicketModel> ticketOptions = const <ServiceTicketModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<PartyModel> parties = const <PartyModel>[];
  List<BranchModel> branches = const <BranchModel>[];
  List<BusinessLocationModel> locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];

  ServiceWorkOrderModel? selected;

  int? companyId;
  int? documentSeriesId;
  int? serviceTicketId;
  int? customerPartyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  String executionMode = 'onsite';

  int? _sessionCompanyId;

  String get workOrderStatus =>
      stringValue(selected?.toJson() ?? const <String, dynamic>{}, 'work_order_status');

  bool get canEdit {
    if (selected == null) {
      return true;
    }
    return workOrderStatus != 'closed' && workOrderStatus != 'cancelled';
  }

  bool get canStart =>
      selected != null &&
      (workOrderStatus == 'draft' || workOrderStatus == 'assigned');

  bool get canComplete =>
      selected != null &&
      [
        'assigned',
        'in_progress',
        'waiting_parts',
        'waiting_customer',
      ].contains(workOrderStatus);

  bool get canClose => selected != null && workOrderStatus == 'completed';

  bool get canCancel =>
      selected != null &&
      workOrderStatus != 'completed' &&
      workOrderStatus != 'closed';

  bool get canDelete => selected != null && workOrderStatus == 'draft';

  int? get selectedId =>
      intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');

  List<DocumentSeriesModel> get woSeriesOptions {
    final cid = companyId;
    return documentSeries.where((s) {
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
    }).toList(growable: false);
  }

  List<ServiceWorkOrderModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows.where((row) {
      if (q.isEmpty) {
        return true;
      }
      final data = row.toJson();
      return [
        stringValue(data, 'work_order_no'),
        stringValue(data, 'work_order_status'),
        _customerLabel(data),
      ].join(' ').toLowerCase().contains(q);
    }).toList(growable: false);
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

  String ticketLabel(ServiceTicketModel t) {
    final d = t.toJson();
    final no = stringValue(d, 'ticket_no');
    final title = stringValue(d, 'issue_title');
    if (no.isNotEmpty && title.isNotEmpty) {
      return '$no · $title';
    }
    if (no.isNotEmpty) {
      return no;
    }
    final id = intValue(d, 'id');
    return id != null ? 'Ticket #$id' : 'Ticket';
  }

  String? consumeActionMessage() {
    final message = actionMessage;
    actionMessage = null;
    return message;
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    notifyListeners();
    try {
      final info = await hrSessionCompanyInfo();
      _sessionCompanyId = info.companyId;

      final filters = <String, dynamic>{'per_page': 200};
      if (_sessionCompanyId != null) {
        filters['company_id'] = _sessionCompanyId;
      }

      final responses = await Future.wait<dynamic>([
        _service.workOrders(filters: filters),
        _service.tickets(filters: filters),
        _masterService.companies(filters: const {'per_page': 200}),
        _masterService.documentSeries(filters: const {'per_page': 400}),
        _partiesService.parties(filters: const {'per_page': 500}),
        _masterService.branches(filters: const {'per_page': 400}),
        _masterService.businessLocations(filters: const {'per_page': 400}),
        _masterService.financialYears(filters: const {'per_page': 100}),
      ]);

      rows =
          (responses[0] as PaginatedResponse<ServiceWorkOrderModel>).data ??
              const <ServiceWorkOrderModel>[];

      final rawTickets =
          (responses[1] as PaginatedResponse<ServiceTicketModel>).data ??
              const <ServiceTicketModel>[];
      ticketOptions = rawTickets
          .where(
            (t) => stringValue(t.toJson(), 'ticket_type') != 'warranty_claim',
          )
          .toList(growable: false);

      companies = ((responses[2] as PaginatedResponse<CompanyModel>).data ??
              const <CompanyModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      documentSeries =
          ((responses[3] as PaginatedResponse<DocumentSeriesModel>).data ??
                  const <DocumentSeriesModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      parties = ((responses[4] as PaginatedResponse<PartyModel>).data ??
              const <PartyModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      branches = ((responses[5] as PaginatedResponse<BranchModel>).data ??
              const <BranchModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      locations =
          ((responses[6] as PaginatedResponse<BusinessLocationModel>).data ??
                  const <BusinessLocationModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      financialYears =
          ((responses[7] as PaginatedResponse<FinancialYearModel>).data ??
                  const <FinancialYearModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);

      loading = false;

      if (selectId != null) {
        ServiceWorkOrderModel? match;
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
        await select(ServiceWorkOrderModel(<String, dynamic>{'id': selectId}));
        return;
      }
      resetDraft();
      notifyListeners();
    } catch (e) {
      pageError = e.toString();
      loading = false;
      notifyListeners();
    }
  }

  void resetDraft() {
    selected = null;
    formError = null;
    companyId = _sessionCompanyId ??
        (companies.isNotEmpty ? companies.first.id : null);
    documentSeriesId =
        woSeriesOptions.isNotEmpty ? woSeriesOptions.first.id : null;
    serviceTicketId =
        ticketOptions.isNotEmpty ? intValue(ticketOptions.first.toJson(), 'id') : null;
    customerPartyId = null;
    branchId = null;
    locationId = null;
    financialYearId = null;
    executionMode = 'onsite';
    workOrderNoController.clear();
    workOrderDateController.text =
        DateTime.now().toIso8601String().split('T').first;
    diagnosisNotesController.clear();
    remarksController.clear();
    resolutionSummaryController.clear();
    actionTakenController.clear();
    customerSiteAddressController.clear();
    technicianUserIdController.clear();
    _syncCustomerFromTicket();
    notifyListeners();
  }

  void _syncCustomerFromTicket() {
    final tid = serviceTicketId;
    if (tid == null) {
      return;
    }
    for (final t in ticketOptions) {
      if (intValue(t.toJson(), 'id') == tid) {
        customerPartyId = intValue(t.toJson(), 'customer_party_id');
        companyId = intValue(t.toJson(), 'company_id');
        return;
      }
    }
  }

  void setServiceTicketId(int? value) {
    if (!canEdit) {
      return;
    }
    serviceTicketId = value;
    if (value == null) {
      notifyListeners();
      return;
    }
    _service.ticket(value).then((response) {
      final doc = response.data;
      if (doc != null) {
        final data = doc.toJson();
        companyId = intValue(data, 'company_id');
        customerPartyId = intValue(data, 'customer_party_id');
        branchId = intValue(data, 'branch_id');
        locationId = intValue(data, 'location_id');
        financialYearId = intValue(data, 'financial_year_id');
        diagnosisNotesController.text = stringValue(data, 'issue_description');
      }
      notifyListeners();
    }).catchError((_) {
      notifyListeners();
    });
  }

  void setCompanyId(int? value) {
    if (!canEdit) {
      return;
    }
    companyId = value;
    if (documentSeriesId != null) {
      final ok = woSeriesOptions.any((s) => s.id == documentSeriesId);
      if (!ok) {
        documentSeriesId =
            woSeriesOptions.isNotEmpty ? woSeriesOptions.first.id : null;
      }
    }
    notifyListeners();
  }

  void setDocumentSeriesId(int? value) {
    if (!canEdit) {
      return;
    }
    documentSeriesId = value;
    notifyListeners();
  }

  void setCustomerPartyId(int? value) {
    if (!canEdit) {
      return;
    }
    customerPartyId = value;
    notifyListeners();
  }

  void setBranchId(int? value) {
    if (!canEdit) {
      return;
    }
    branchId = value;
    notifyListeners();
  }

  void setLocationId(int? value) {
    if (!canEdit) {
      return;
    }
    locationId = value;
    notifyListeners();
  }

  void setFinancialYearId(int? value) {
    if (!canEdit) {
      return;
    }
    financialYearId = value;
    notifyListeners();
  }

  void setExecutionMode(String value) {
    if (!canEdit) {
      return;
    }
    executionMode = value;
    notifyListeners();
  }

  List<BranchModel> get branchOptions {
    final cid = companyId;
    return branches.where((b) {
      if (b.id == null) {
        return false;
      }
      return cid == null || b.companyId == cid;
    }).toList(growable: false);
  }

  List<BusinessLocationModel> get locationOptions {
    final cid = companyId;
    final bid = branchId;
    return locations.where((l) {
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
    }).toList(growable: false);
  }

  List<FinancialYearModel> get financialYearOptions {
    final cid = companyId;
    return financialYears.where((f) {
      if (f.id == null) {
        return false;
      }
      return cid == null || f.companyId == cid;
    }).toList(growable: false);
  }

  Future<void> select(ServiceWorkOrderModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _service.workOrder(id);
      final doc = response.data ?? row;
      selected = doc;
      _applyDetail(doc.toJson());
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      notifyListeners();
    }
  }

  void _applyDetail(Map<String, dynamic> data) {
    companyId = intValue(data, 'company_id');
    customerPartyId = intValue(data, 'customer_party_id');
    serviceTicketId = intValue(data, 'service_ticket_id');
    branchId = intValue(data, 'branch_id');
    locationId = intValue(data, 'location_id');
    financialYearId = intValue(data, 'financial_year_id');
    documentSeriesId = null;
    workOrderNoController.text = stringValue(data, 'work_order_no');
    workOrderDateController.text =
        displayDate(nullableStringValue(data, 'work_order_date'));
    executionMode = stringValue(data, 'execution_mode');
    if (executionMode.isEmpty) {
      executionMode = 'onsite';
    }
    technicianUserIdController.text =
        intValue(data, 'technician_user_id')?.toString() ?? '';
    diagnosisNotesController.text = stringValue(data, 'diagnosis_notes');
    remarksController.text = stringValue(data, 'remarks');
    resolutionSummaryController.text =
        stringValue(data, 'resolution_summary');
    actionTakenController.text = stringValue(data, 'action_taken');
    customerSiteAddressController.text =
        stringValue(data, 'customer_site_address');
  }

  String? _validateSave() {
    if (companyId == null) {
      return 'Company is required.';
    }
    if (serviceTicketId == null) {
      return 'Service ticket is required.';
    }
    if (customerPartyId == null) {
      return 'Customer is required.';
    }
    if (workOrderDateController.text.trim().isEmpty) {
      return 'Work order date is required.';
    }
    final manualNo = workOrderNoController.text.trim();
    if (manualNo.isEmpty && documentSeriesId == null) {
      return 'Enter a work order number or select a document series.';
    }
    return null;
  }

  Map<String, dynamic> _buildCreatePayload() {
    final techId = int.tryParse(technicianUserIdController.text.trim());
    return <String, dynamic>{
      'company_id': companyId,
      'service_ticket_id': serviceTicketId,
      'customer_party_id': customerPartyId,
      'work_order_date': workOrderDateController.text.trim(),
      'execution_mode': executionMode,
      'diagnosis_notes': nullIfEmpty(diagnosisNotesController.text),
      'remarks': nullIfEmpty(remarksController.text),
      'resolution_summary': nullIfEmpty(resolutionSummaryController.text),
      'action_taken': nullIfEmpty(actionTakenController.text),
      'customer_site_address':
          nullIfEmpty(customerSiteAddressController.text),
      if (branchId != null) 'branch_id': branchId,
      if (locationId != null) 'location_id': locationId,
      if (financialYearId != null) 'financial_year_id': financialYearId,
      if (techId != null) 'technician_user_id': techId,
      if (documentSeriesId != null) 'document_series_id': documentSeriesId,
      if (workOrderNoController.text.trim().isNotEmpty)
        'work_order_no': workOrderNoController.text.trim(),
    };
  }

  Map<String, dynamic> _buildUpdatePayload() {
    final techId = int.tryParse(technicianUserIdController.text.trim());
    final data = selected?.toJson() ?? const <String, dynamic>{};
    return <String, dynamic>{
      'company_id': companyId,
      'service_ticket_id': serviceTicketId,
      'customer_party_id': customerPartyId,
      'work_order_date': workOrderDateController.text.trim(),
      'work_order_status': stringValue(data, 'work_order_status'),
      'execution_mode': executionMode,
      'diagnosis_notes': nullIfEmpty(diagnosisNotesController.text),
      'remarks': nullIfEmpty(remarksController.text),
      'resolution_summary': nullIfEmpty(resolutionSummaryController.text),
      'action_taken': nullIfEmpty(actionTakenController.text),
      'customer_site_address':
          nullIfEmpty(customerSiteAddressController.text),
      if (branchId != null) 'branch_id': branchId,
      if (locationId != null) 'location_id': locationId,
      if (financialYearId != null) 'financial_year_id': financialYearId,
      if (techId != null) 'technician_user_id': techId,
      if (workOrderNoController.text.trim().isNotEmpty)
        'work_order_no': workOrderNoController.text.trim(),
    };
  }

  Future<void> save() async {
    final err = _validateSave();
    if (err != null) {
      formError = err;
      notifyListeners();
      return;
    }
    saving = true;
    formError = null;
    actionMessage = null;
    notifyListeners();
    try {
      if (selected == null) {
        final response = await _service.createWorkOrder(
          ServiceWorkOrderModel(_buildCreatePayload()),
        );
        actionMessage = response.message;
        await load(selectId: intValue(response.data?.toJson() ?? {}, 'id'));
      } else {
        final id = selectedId;
        if (id == null) {
          formError = 'Missing work order id.';
          notifyListeners();
          return;
        }
        final response = await _service.updateWorkOrder(
          id,
          ServiceWorkOrderModel(_buildUpdatePayload()),
        );
        actionMessage = response.message;
        await load(selectId: id);
      }
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> startWorkOrder() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.startWorkOrder(id);
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> completeWorkOrder() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.completeWorkOrder(id);
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> closeWorkOrder() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.closeWorkOrder(id);
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> cancelWorkOrder() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.cancelWorkOrder(id);
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteWorkOrder() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      await _service.deleteWorkOrder(id);
      actionMessage = 'Work order deleted.';
      await load();
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    workOrderNoController.dispose();
    workOrderDateController.dispose();
    diagnosisNotesController.dispose();
    remarksController.dispose();
    resolutionSummaryController.dispose();
    actionTakenController.dispose();
    customerSiteAddressController.dispose();
    technicianUserIdController.dispose();
    super.dispose();
  }
}
