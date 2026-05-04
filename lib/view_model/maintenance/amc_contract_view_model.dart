import 'package:billing/screen.dart';
import 'package:billing/view/hr/hr_workflow_dialogs.dart';
import 'package:billing/view/purchase/purchase_support.dart';

class AmcContractViewModel extends ChangeNotifier {
  AmcContractViewModel() {
    searchController.addListener(notifyListeners);
  }

  final MaintenanceService _maintenance = MaintenanceService();
  final MasterService _master = MasterService();
  final PartiesService _parties = PartiesService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController contractNoController = TextEditingController();
  final TextEditingController contractDateController = TextEditingController();
  final TextEditingController contractTypeController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController coverageController = TextEditingController();
  final TextEditingController visitFrequencyController = TextEditingController();
  final TextEditingController responseTimeController = TextEditingController();
  final TextEditingController resolutionTimeController = TextEditingController();
  final TextEditingController contractValueController = TextEditingController();
  final TextEditingController taxAmountController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<AmcContractModel> rows = const <AmcContractModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<PartyModel> parties = const <PartyModel>[];
  List<PartyTypeModel> partyTypes = const <PartyTypeModel>[];

  AmcContractModel? selected;

  int? companyId;
  int? documentSeriesId;
  int? vendorPartyId;

  int? _sessionCompanyId;

  int? get selectedId =>
      intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');

  String get contractStatus =>
      stringValue(selected?.toJson() ?? const <String, dynamic>{}, 'contract_status');

  bool get canEdit {
    if (selected == null) {
      return true;
    }
    return !const {'expired', 'terminated', 'cancelled'}
        .contains(contractStatus);
  }

  bool get canApprove => selected != null && contractStatus == 'draft';

  bool get canTerminate =>
      selected != null &&
      (contractStatus == 'draft' || contractStatus == 'active');

  bool get canCancel => selected != null && contractStatus != 'active';

  bool get canDelete => selected != null && contractStatus == 'draft';

  List<DocumentSeriesModel> get seriesOptions {
    final cid = companyId;
    return documentSeries.where((s) {
      if (!s.isActive) {
        return false;
      }
      if ((s.documentType ?? '').trim() != 'AMC_CONTRACT') {
        return false;
      }
      if (cid != null && s.companyId != null && s.companyId != cid) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  List<PartyModel> get vendorOptions =>
      purchaseSuppliers(parties: parties, partyTypes: partyTypes);

  List<AmcContractModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows.where((row) {
      if (q.isEmpty) {
        return true;
      }
      final data = row.toJson();
      return [
        stringValue(data, 'contract_no'),
        stringValue(data, 'contract_status'),
        stringValue(data, 'contract_type'),
        _vendorLabel(data),
      ].join(' ').toLowerCase().contains(q);
    }).toList(growable: false);
  }

  String _vendorLabel(Map<String, dynamic> data) {
    final raw = data['vendor'];
    if (raw is Map<String, dynamic>) {
      final d = stringValue(raw, 'display_name');
      if (d.isNotEmpty) {
        return d;
      }
      return stringValue(raw, 'party_name');
    }
    return '';
  }

  String vendorLabelFor(Map<String, dynamic> data) => _vendorLabel(data);

  String listTitle(AmcContractModel row) {
    final data = row.toJson();
    final no = stringValue(data, 'contract_no');
    if (no.isNotEmpty) {
      return no;
    }
    final id = intValue(data, 'id');
    return id != null ? 'AMC #$id' : 'AMC contract';
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
        _maintenance.amcContracts(filters: filters),
        _master.companies(filters: const {'per_page': 200}),
        _master.documentSeries(filters: const {'per_page': 400}),
        _parties.parties(filters: const {'per_page': 500}),
        _parties.partyTypes(filters: const {'per_page': 200}),
      ]);

      rows =
          (responses[0] as PaginatedResponse<AmcContractModel>).data ??
              const <AmcContractModel>[];
      companies = ((responses[1] as PaginatedResponse<CompanyModel>).data ??
              const <CompanyModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      documentSeries =
          ((responses[2] as PaginatedResponse<DocumentSeriesModel>).data ??
                  const <DocumentSeriesModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      parties = ((responses[3] as PaginatedResponse<PartyModel>).data ??
              const <PartyModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      partyTypes =
          (responses[4] as PaginatedResponse<PartyTypeModel>).data ??
              const <PartyTypeModel>[];

      loading = false;

      if (selectId != null) {
        AmcContractModel? match;
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
        await select(AmcContractModel(<String, dynamic>{'id': selectId}));
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
        seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    vendorPartyId = null;
    contractNoController.clear();
    contractDateController.text =
        DateTime.now().toIso8601String().split('T').first;
    contractTypeController.clear();
    startDateController.text =
        DateTime.now().toIso8601String().split('T').first;
    endDateController.clear();
    coverageController.clear();
    visitFrequencyController.clear();
    responseTimeController.clear();
    resolutionTimeController.clear();
    contractValueController.text = '0';
    taxAmountController.text = '0';
    remarksController.clear();
    notifyListeners();
  }

  void setCompanyId(int? value) {
    if (!canEdit) {
      return;
    }
    companyId = value;
    if (documentSeriesId != null) {
      final stillValid =
          seriesOptions.any((s) => s.id == documentSeriesId);
      if (!stillValid) {
        documentSeriesId =
            seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
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

  void setVendorPartyId(int? value) {
    if (!canEdit) {
      return;
    }
    vendorPartyId = value;
    notifyListeners();
  }

  Future<void> select(AmcContractModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _maintenance.amcContract(id);
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
    vendorPartyId = intValue(data, 'vendor_party_id');
    contractNoController.text = stringValue(data, 'contract_no');
    contractDateController.text = displayDate(
      nullableStringValue(data, 'contract_date'),
    );
    contractTypeController.text = stringValue(data, 'contract_type');
    startDateController.text = displayDate(
      nullableStringValue(data, 'contract_start_date'),
    );
    endDateController.text = displayDate(
      nullableStringValue(data, 'contract_end_date'),
    );
    coverageController.text = stringValue(data, 'coverage_scope');
    visitFrequencyController.text = stringValue(data, 'visit_frequency');
    responseTimeController.text = _numString(data, 'response_time_hours');
    resolutionTimeController.text = _numString(data, 'resolution_time_hours');
    contractValueController.text = _numString(data, 'contract_value');
    taxAmountController.text = _numString(data, 'tax_amount');
    remarksController.text = stringValue(data, 'remarks');
    documentSeriesId = null;
  }

  String _numString(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v == null) {
      return '';
    }
    if (v is num) {
      return v.toString();
    }
    return v.toString();
  }

  Map<String, dynamic> _amounts() {
    final cv = double.tryParse(contractValueController.text.trim()) ?? 0;
    final tax = double.tryParse(taxAmountController.text.trim()) ?? 0;
    return <String, dynamic>{
      'contract_value': cv,
      'tax_amount': tax,
      'total_value': double.parse((cv + tax).toStringAsFixed(2)),
    };
  }

  String? _validateForSave() {
    if (companyId == null) {
      return 'Company is required.';
    }
    if (vendorPartyId == null) {
      return 'Vendor is required.';
    }
    if (contractDateController.text.trim().isEmpty) {
      return 'Contract date is required.';
    }
    if (startDateController.text.trim().isEmpty) {
      return 'Contract start date is required.';
    }
    if (endDateController.text.trim().isEmpty) {
      return 'Contract end date is required.';
    }
    final manualNo = contractNoController.text.trim();
    if (manualNo.isEmpty && documentSeriesId == null) {
      return 'Enter a contract number or select a document series.';
    }
    return null;
  }

  Map<String, dynamic> _buildCreatePayload() {
    final amounts = _amounts();
    return <String, dynamic>{
      'company_id': companyId,
      'vendor_party_id': vendorPartyId,
      'contract_date': contractDateController.text.trim(),
      'contract_start_date': startDateController.text.trim(),
      'contract_end_date': endDateController.text.trim(),
      'contract_type': nullIfEmpty(contractTypeController.text),
      'coverage_scope': nullIfEmpty(coverageController.text),
      'visit_frequency': nullIfEmpty(visitFrequencyController.text),
      'response_time_hours':
          double.tryParse(responseTimeController.text.trim()),
      'resolution_time_hours':
          double.tryParse(resolutionTimeController.text.trim()),
      'contract_value': amounts['contract_value'],
      'tax_amount': amounts['tax_amount'],
      'total_value': amounts['total_value'],
      'remarks': nullIfEmpty(remarksController.text),
      'contract_status': 'draft',
      if (documentSeriesId != null) 'document_series_id': documentSeriesId,
      if (contractNoController.text.trim().isNotEmpty)
        'contract_no': contractNoController.text.trim(),
    };
  }

  Map<String, dynamic> _buildUpdatePayload() {
    final amounts = _amounts();
    final data = selected?.toJson() ?? const <String, dynamic>{};
    return <String, dynamic>{
      'company_id': companyId,
      'vendor_party_id': vendorPartyId,
      'contract_date': contractDateController.text.trim(),
      'contract_start_date': startDateController.text.trim(),
      'contract_end_date': endDateController.text.trim(),
      'contract_type': nullIfEmpty(contractTypeController.text),
      'coverage_scope': nullIfEmpty(coverageController.text),
      'visit_frequency': nullIfEmpty(visitFrequencyController.text),
      'response_time_hours':
          double.tryParse(responseTimeController.text.trim()),
      'resolution_time_hours':
          double.tryParse(resolutionTimeController.text.trim()),
      'contract_value': amounts['contract_value'],
      'tax_amount': amounts['tax_amount'],
      'total_value': amounts['total_value'],
      'remarks': nullIfEmpty(remarksController.text),
      'contract_status': stringValue(data, 'contract_status'),
      if (contractNoController.text.trim().isNotEmpty)
        'contract_no': contractNoController.text.trim(),
    };
  }

  Future<void> save() async {
    final err = _validateForSave();
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
        final response = await _maintenance.createAmcContract(
          AmcContractModel(_buildCreatePayload()),
        );
        actionMessage = response.message;
        await load(selectId: intValue(response.data?.toJson() ?? {}, 'id'));
      } else {
        final id = selectedId;
        if (id == null) {
          formError = 'Missing contract id.';
          notifyListeners();
          return;
        }
        final response = await _maintenance.updateAmcContract(
          id,
          AmcContractModel(_buildUpdatePayload()),
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

  Future<void> approveContract() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    final empty = AmcContractModel(<String, dynamic>{});
    try {
      final response = await _maintenance.approveAmcContract(id, empty);
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> terminateContract() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    final empty = AmcContractModel(<String, dynamic>{});
    try {
      final response = await _maintenance.terminateAmcContract(id, empty);
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> cancelContract() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    final empty = AmcContractModel(<String, dynamic>{});
    try {
      final response = await _maintenance.cancelAmcContract(id, empty);
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteContract() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      await _maintenance.deleteAmcContract(id);
      actionMessage = 'AMC contract deleted.';
      await load();
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    contractNoController.dispose();
    contractDateController.dispose();
    contractTypeController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    coverageController.dispose();
    visitFrequencyController.dispose();
    responseTimeController.dispose();
    resolutionTimeController.dispose();
    contractValueController.dispose();
    taxAmountController.dispose();
    remarksController.dispose();
    super.dispose();
  }
}
