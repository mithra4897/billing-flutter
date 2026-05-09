import 'package:billing/screen.dart';
import 'package:billing/view/hr/hr_workflow_dialogs.dart';
import 'package:billing/view/purchase/purchase_support.dart';

class ServiceTicketViewModel extends ChangeNotifier {
  ServiceTicketViewModel() {
    searchController.addListener(notifyListeners);
  }

  final ServiceModuleService _service = ServiceModuleService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();

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

  ServiceTicketModel? selected;

  int? companyId;
  int? documentSeriesId;
  int? customerPartyId;
  int? branchId;
  int? locationId;
  int? financialYearId;

  int? _sessionCompanyId;

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
    notifyListeners();
    try {
      final info = await hrSessionCompanyInfo();
      _sessionCompanyId = info.companyId;

      final filters = <String, dynamic>{'per_page': 200};
      if (_sessionCompanyId != null) {
        filters['company_id'] = _sessionCompanyId;
      }

      final responses = await Future.wait<dynamic>([
        _service.tickets(filters: filters),
        _masterService.companies(filters: const {'per_page': 200}),
        _masterService.documentSeries(filters: const {'per_page': 400}),
        _partiesService.parties(filters: const {'per_page': 500}),
        _masterService.branches(filters: const {'per_page': 400}),
        _masterService.businessLocations(filters: const {'per_page': 400}),
        _masterService.financialYears(filters: const {'per_page': 100}),
      ]);

      var rawRows =
          (responses[0] as PaginatedResponse<ServiceTicketModel>).data ??
          const <ServiceTicketModel>[];
      rows = rawRows
          .where(
            (r) => stringValue(r.toJson(), 'ticket_type') != 'warranty_claim',
          )
          .toList(growable: false);

      companies =
          ((responses[1] as PaginatedResponse<CompanyModel>).data ??
                  const <CompanyModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      documentSeries =
          ((responses[2] as PaginatedResponse<DocumentSeriesModel>).data ??
                  const <DocumentSeriesModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      parties =
          ((responses[3] as PaginatedResponse<PartyModel>).data ??
                  const <PartyModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      branches =
          ((responses[4] as PaginatedResponse<BranchModel>).data ??
                  const <BranchModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      locations =
          ((responses[5] as PaginatedResponse<BusinessLocationModel>).data ??
                  const <BusinessLocationModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      financialYears =
          ((responses[6] as PaginatedResponse<FinancialYearModel>).data ??
                  const <FinancialYearModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);

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
        await select(ServiceTicketModel(<String, dynamic>{'id': selectId}));
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
    companyId =
        _sessionCompanyId ?? (companies.isNotEmpty ? companies.first.id : null);
    documentSeriesId = ticketSeriesOptions.isNotEmpty
        ? ticketSeriesOptions.first.id
        : null;
    customerPartyId = null;
    branchId = null;
    locationId = null;
    financialYearId = null;
    ticketNoController.clear();
    ticketDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    issueTitleController.clear();
    issueDescriptionController.clear();
    priorityController.text = 'medium';
    notesController.clear();
    contactPersonController.clear();
    contactMobileController.clear();
    contactEmailController.clear();
    itemIdController.clear();
    serialIdController.clear();
    notifyListeners();
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
    notifyListeners();
    try {
      final response = await _service.ticket(id);
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
      priorityController.text = 'medium';
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
      'ticket_type': 'support',
      'priority_level': nullIfEmpty(priorityController.text) ?? 'medium',
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
      'ticket_type': stringValue(data, 'ticket_type'),
      'ticket_status': stringValue(data, 'ticket_status'),
      'priority_level': nullIfEmpty(priorityController.text) ?? 'medium',
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
      if (ticketNo.isNotEmpty) 'ticket_no': ticketNo,
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
        final response = await _service.createTicket(
          ServiceTicketModel(_buildCreatePayload()),
        );
        actionMessage = response.message;
        await load(selectId: intValue(response.data?.toJson() ?? {}, 'id'));
      } else {
        final id = selectedId;
        if (id == null) {
          formError = 'Missing ticket id.';
          notifyListeners();
          return;
        }
        final response = await _service.updateTicket(
          id,
          ServiceTicketModel(_buildUpdatePayload()),
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
    } catch (e) {
      formError = e.toString();
      notifyListeners();
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
    } catch (e) {
      formError = e.toString();
      notifyListeners();
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
    } catch (e) {
      formError = e.toString();
      notifyListeners();
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
    } catch (e) {
      formError = e.toString();
      notifyListeners();
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
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
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
    super.dispose();
  }
}
