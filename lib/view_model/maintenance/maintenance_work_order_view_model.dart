import 'package:billing/screen.dart';
import 'package:billing/view/hr/hr_workflow_dialogs.dart';
import 'package:billing/view/purchase/purchase_support.dart';

class MaintenanceWorkOrderViewModel extends ChangeNotifier {
  MaintenanceWorkOrderViewModel() {
    searchController.addListener(notifyListeners);
  }

  final MaintenanceService _maintenance = MaintenanceService();
  final MasterService _master = MasterService();
  final AssetsService _assets = AssetsService();
  final PartiesService _parties = PartiesService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController workOrderNoController = TextEditingController();
  final TextEditingController workOrderDateController = TextEditingController();
  final TextEditingController workOrderTypeController = TextEditingController();
  final TextEditingController executionModeController = TextEditingController();
  final TextEditingController assignedTechnicianController =
      TextEditingController();
  final TextEditingController assignedTeamController = TextEditingController();
  final TextEditingController faultDescriptionController =
      TextEditingController();
  final TextEditingController actionTakenController = TextEditingController();
  final TextEditingController resolutionSummaryController =
      TextEditingController();
  final TextEditingController plannedStartController = TextEditingController();
  final TextEditingController plannedEndController = TextEditingController();
  final TextEditingController actualStartController = TextEditingController();
  final TextEditingController actualEndController = TextEditingController();
  final TextEditingController downtimeMinutesController =
      TextEditingController();
  final TextEditingController laborCostController = TextEditingController();
  final TextEditingController otherCostController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<MaintenanceWorkOrderModel> rows = const <MaintenanceWorkOrderModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<BranchModel> branches = const <BranchModel>[];
  List<BusinessLocationModel> locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<PartyModel> parties = const <PartyModel>[];
  List<PartyTypeModel> partyTypes = const <PartyTypeModel>[];
  List<AssetModel> assets = const <AssetModel>[];
  List<MaintenancePlanModel> maintenancePlans =
      const <MaintenancePlanModel>[];
  List<MaintenanceRequestModel> maintenanceRequests =
      const <MaintenanceRequestModel>[];

  MaintenanceWorkOrderModel? selected;

  int? companyId;
  int? documentSeriesId;
  int? assetId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? maintenanceRequestId;
  int? maintenancePlanId;
  int? vendorPartyId;

  int? _sessionCompanyId;

  int? get selectedId =>
      intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');

  String get workOrderStatus =>
      stringValue(selected?.toJson() ?? const <String, dynamic>{}, 'work_order_status');

  bool get canEdit {
    if (selected == null) {
      return true;
    }
    return !const {'closed', 'cancelled'}.contains(workOrderStatus);
  }

  bool get canApprove => selected != null && workOrderStatus == 'draft';

  bool get canStart =>
      selected != null &&
      const {'draft', 'approved', 'assigned'}.contains(workOrderStatus);

  bool get canComplete =>
      selected != null &&
      const {
        'approved',
        'assigned',
        'in_progress',
        'waiting_parts',
        'waiting_vendor',
      }.contains(workOrderStatus);

  bool get canClose => selected != null && workOrderStatus == 'completed';

  bool get canCancel =>
      selected != null &&
      !const {'completed', 'closed', 'cancelled'}.contains(workOrderStatus);

  bool get canDelete => selected != null && workOrderStatus == 'draft';

  List<DocumentSeriesModel> get seriesOptions {
    final cid = companyId;
    return documentSeries.where((s) {
      if (!s.isActive) {
        return false;
      }
      if ((s.documentType ?? '').trim() != 'MAINTENANCE_WORK_ORDER') {
        return false;
      }
      if (cid != null && s.companyId != null && s.companyId != cid) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  List<BranchModel> get branchOptions =>
      branchesForCompany(branches, companyId);

  List<BusinessLocationModel> get locationOptions =>
      locationsForBranch(locations, branchId);

  List<FinancialYearModel> get financialYearOptions {
    final cid = companyId;
    return financialYears.where((fy) {
      if (cid == null) {
        return true;
      }
      return fy.companyId == null || fy.companyId == cid;
    }).toList(growable: false);
  }

  List<PartyModel> get vendorOptions =>
      purchaseSuppliers(parties: parties, partyTypes: partyTypes);

  List<MaintenanceWorkOrderModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows.where((row) {
      if (q.isEmpty) {
        return true;
      }
      final data = row.toJson();
      return [
        stringValue(data, 'work_order_no'),
        stringValue(data, 'work_order_status'),
        stringValue(data, 'work_order_type'),
        listAssetSubtitle(data),
      ].join(' ').toLowerCase().contains(q);
    }).toList(growable: false);
  }

  String listAssetSubtitle(Map<String, dynamic> data) {
    final nested = data['asset'];
    if (nested is Map<String, dynamic>) {
      final code = stringValue(nested, 'asset_code');
      final name = stringValue(nested, 'asset_name');
      if (code.isNotEmpty && name.isNotEmpty) {
        return '$code — $name';
      }
      return code.isNotEmpty ? code : name;
    }
    return '';
  }

  String listTitle(MaintenanceWorkOrderModel row) {
    final data = row.toJson();
    final no = stringValue(data, 'work_order_no');
    if (no.isNotEmpty) {
      return no;
    }
    final id = intValue(data, 'id');
    return id != null ? 'WO #$id' : 'Work order';
  }

  String requestListLabel(MaintenanceRequestModel r) {
    final data = r.toJson();
    final no = stringValue(data, 'request_no');
    if (no.isNotEmpty) {
      return no;
    }
    final id = intValue(data, 'id');
    return id != null ? 'Request #$id' : 'Request';
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
        _maintenance.workOrders(filters: filters),
        _master.companies(filters: const {'per_page': 200}),
        _master.documentSeries(filters: const {'per_page': 400}),
        _master.branches(filters: const {'per_page': 500}),
        _master.businessLocations(filters: const {'per_page': 800}),
        _master.financialYears(filters: const {'per_page': 200}),
        _parties.parties(filters: const {'per_page': 500}),
        _parties.partyTypes(filters: const {'per_page': 200}),
      ]);

      rows =
          (responses[0] as PaginatedResponse<MaintenanceWorkOrderModel>).data ??
              const <MaintenanceWorkOrderModel>[];
      companies = ((responses[1] as PaginatedResponse<CompanyModel>).data ??
              const <CompanyModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      documentSeries =
          ((responses[2] as PaginatedResponse<DocumentSeriesModel>).data ??
                  const <DocumentSeriesModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      branches =
          ((responses[3] as PaginatedResponse<BranchModel>).data ??
                  const <BranchModel>[])
              .where((b) => b.id != null)
              .toList(growable: false);
      locations =
          ((responses[4] as PaginatedResponse<BusinessLocationModel>).data ??
                  const <BusinessLocationModel>[])
              .where((l) => l.id != null)
              .toList(growable: false);
      financialYears =
          ((responses[5] as PaginatedResponse<FinancialYearModel>).data ??
                  const <FinancialYearModel>[])
              .where((fy) => fy.id != null && fy.isActive)
              .toList(growable: false);
      parties = ((responses[6] as PaginatedResponse<PartyModel>).data ??
              const <PartyModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      partyTypes =
          (responses[7] as PaginatedResponse<PartyTypeModel>).data ??
              const <PartyTypeModel>[];

      loading = false;

      if (selectId != null) {
        MaintenanceWorkOrderModel? match;
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
        await select(
          MaintenanceWorkOrderModel(<String, dynamic>{'id': selectId}),
        );
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

  Future<void> refreshCompanyScoped() async {
    final cid = companyId;
    if (cid == null) {
      assets = const <AssetModel>[];
      maintenancePlans = const <MaintenancePlanModel>[];
      maintenanceRequests = const <MaintenanceRequestModel>[];
      notifyListeners();
      return;
    }
    try {
      final responses = await Future.wait<dynamic>([
        _assets.assets(filters: <String, dynamic>{
          'company_id': cid,
          'per_page': 200,
        }),
        _maintenance.plans(filters: <String, dynamic>{
          'company_id': cid,
          'per_page': 200,
        }),
        _maintenance.requests(filters: <String, dynamic>{
          'company_id': cid,
          'per_page': 200,
        }),
      ]);
      assets = ((responses[0] as PaginatedResponse<AssetModel>).data ??
              const <AssetModel>[])
          .where((a) => intValue(a.toJson(), 'id') != null)
          .toList(growable: false);
      maintenancePlans =
          ((responses[1] as PaginatedResponse<MaintenancePlanModel>).data ??
                  const <MaintenancePlanModel>[])
              .where((p) => intValue(p.toJson(), 'id') != null)
              .toList(growable: false);
      maintenanceRequests =
          ((responses[2] as PaginatedResponse<MaintenanceRequestModel>).data ??
                  const <MaintenanceRequestModel>[])
              .where((r) => intValue(r.toJson(), 'id') != null)
              .toList(growable: false);
    } catch (_) {
      assets = const <AssetModel>[];
      maintenancePlans = const <MaintenancePlanModel>[];
      maintenanceRequests = const <MaintenanceRequestModel>[];
    }
    notifyListeners();
  }

  void resetDraft() {
    selected = null;
    formError = null;
    companyId = _sessionCompanyId ??
        (companies.isNotEmpty ? companies.first.id : null);
    documentSeriesId =
        seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    assetId = null;
    branchId = null;
    locationId = null;
    financialYearId = null;
    maintenanceRequestId = null;
    maintenancePlanId = null;
    vendorPartyId = null;
    workOrderNoController.clear();
    workOrderDateController.text =
        DateTime.now().toIso8601String().split('T').first;
    workOrderTypeController.clear();
    executionModeController.clear();
    assignedTechnicianController.clear();
    assignedTeamController.clear();
    faultDescriptionController.clear();
    actionTakenController.clear();
    resolutionSummaryController.clear();
    plannedStartController.clear();
    plannedEndController.clear();
    actualStartController.clear();
    actualEndController.clear();
    downtimeMinutesController.clear();
    laborCostController.text = '0';
    otherCostController.text = '0';
    remarksController.clear();
    notifyListeners();
    Future<void>(() async {
      await refreshCompanyScoped();
    });
  }

  void _revalidateSeries() {
    if (documentSeriesId != null &&
        !seriesOptions.any((s) => s.id == documentSeriesId)) {
      documentSeriesId =
          seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    }
  }

  void setCompanyId(int? value) {
    if (!canEdit) {
      return;
    }
    companyId = value;
    assetId = null;
    branchId = null;
    locationId = null;
    maintenanceRequestId = null;
    maintenancePlanId = null;
    _revalidateSeries();
    notifyListeners();
    Future<void>(() async {
      await refreshCompanyScoped();
    });
  }

  void setDocumentSeriesId(int? value) {
    if (!canEdit) {
      return;
    }
    documentSeriesId = value;
    notifyListeners();
  }

  void setAssetId(int? value) {
    if (!canEdit) {
      return;
    }
    assetId = value;
    notifyListeners();
  }

  void setBranchId(int? value) {
    if (!canEdit) {
      return;
    }
    branchId = value;
    locationId = null;
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

  void setMaintenanceRequestId(int? value) {
    if (!canEdit) {
      return;
    }
    maintenanceRequestId = value;
    notifyListeners();
  }

  void setMaintenancePlanId(int? value) {
    if (!canEdit) {
      return;
    }
    maintenancePlanId = value;
    notifyListeners();
  }

  void setVendorPartyId(int? value) {
    if (!canEdit) {
      return;
    }
    vendorPartyId = value;
    notifyListeners();
  }

  Future<void> select(MaintenanceWorkOrderModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _maintenance.workOrder(id);
      final doc = response.data ?? row;
      selected = doc;
      _applyDetail(doc.toJson());
      await refreshCompanyScoped();
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      notifyListeners();
    }
  }

  String _numStr(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v == null) {
      return '';
    }
    if (v is num) {
      return v.toString();
    }
    return v.toString();
  }

  void _applyDetail(Map<String, dynamic> data) {
    companyId = intValue(data, 'company_id');
    assetId = intValue(data, 'asset_id');
    branchId = intValue(data, 'branch_id');
    locationId = intValue(data, 'location_id');
    financialYearId = intValue(data, 'financial_year_id');
    maintenanceRequestId = intValue(data, 'maintenance_request_id');
    maintenancePlanId = intValue(data, 'maintenance_plan_id');
    vendorPartyId = intValue(data, 'vendor_party_id');
    workOrderNoController.text = stringValue(data, 'work_order_no');
    workOrderDateController.text =
        displayDate(nullableStringValue(data, 'work_order_date'));
    workOrderTypeController.text = stringValue(data, 'work_order_type');
    executionModeController.text = stringValue(data, 'execution_mode');
    assignedTechnicianController.text =
        stringValue(data, 'assigned_technician');
    assignedTeamController.text = stringValue(data, 'assigned_team');
    faultDescriptionController.text = stringValue(data, 'fault_description');
    actionTakenController.text = stringValue(data, 'action_taken');
    resolutionSummaryController.text =
        stringValue(data, 'resolution_summary');
    plannedStartController.text =
        nullableStringValue(data, 'planned_start_datetime')?.trim() ?? '';
    plannedEndController.text =
        nullableStringValue(data, 'planned_end_datetime')?.trim() ?? '';
    actualStartController.text =
        nullableStringValue(data, 'actual_start_datetime')?.trim() ?? '';
    actualEndController.text =
        nullableStringValue(data, 'actual_end_datetime')?.trim() ?? '';
    downtimeMinutesController.text = _numStr(data, 'downtime_minutes');
    laborCostController.text = _numStr(data, 'labor_cost');
    otherCostController.text = _numStr(data, 'other_cost');
    remarksController.text = stringValue(data, 'remarks');
    documentSeriesId = null;
  }

  String? _validateForSave() {
    if (companyId == null) {
      return 'Company is required.';
    }
    if (assetId == null) {
      return 'Asset is required.';
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
    final labor = double.tryParse(laborCostController.text.trim()) ?? 0;
    final other = double.tryParse(otherCostController.text.trim()) ?? 0;
    return <String, dynamic>{
      'company_id': companyId,
      'asset_id': assetId,
      'work_order_date': workOrderDateController.text.trim(),
      'work_order_status': 'draft',
      'labor_cost': labor,
      'other_cost': other,
      'work_order_type': nullIfEmpty(workOrderTypeController.text),
      'execution_mode': nullIfEmpty(executionModeController.text),
      'assigned_technician': nullIfEmpty(assignedTechnicianController.text),
      'assigned_team': nullIfEmpty(assignedTeamController.text),
      'fault_description': nullIfEmpty(faultDescriptionController.text),
      'action_taken': nullIfEmpty(actionTakenController.text),
      'resolution_summary': nullIfEmpty(resolutionSummaryController.text),
      'remarks': nullIfEmpty(remarksController.text),
      'branch_id': ?branchId,
      'location_id': ?locationId,
      'financial_year_id': ?financialYearId,
      'document_series_id': ?documentSeriesId,
      'work_order_no': ?nullIfEmpty(workOrderNoController.text.trim()),
      'maintenance_request_id': ?maintenanceRequestId,
      'maintenance_plan_id': ?maintenancePlanId,
      'vendor_party_id': ?vendorPartyId,
      'planned_start_datetime':
          ?nullIfEmpty(plannedStartController.text.trim()),
      'planned_end_datetime':
          ?nullIfEmpty(plannedEndController.text.trim()),
      'actual_start_datetime':
          ?nullIfEmpty(actualStartController.text.trim()),
      'actual_end_datetime': ?nullIfEmpty(actualEndController.text.trim()),
      'downtime_minutes':
          ?double.tryParse(downtimeMinutesController.text.trim()),
    };
  }

  Map<String, dynamic> _buildUpdatePayload() {
    final data = selected?.toJson() ?? const <String, dynamic>{};
    final labor = double.tryParse(laborCostController.text.trim()) ??
        double.tryParse(_numStr(data, 'labor_cost')) ??
        0;
    final other = double.tryParse(otherCostController.text.trim()) ??
        double.tryParse(_numStr(data, 'other_cost')) ??
        0;
    final spare = double.tryParse(_numStr(data, 'spare_cost')) ?? 0;
    final ext = double.tryParse(_numStr(data, 'external_service_cost')) ?? 0;
    final total = double.tryParse(_numStr(data, 'total_cost')) ?? 0;
    final dm =
        double.tryParse(downtimeMinutesController.text.trim()) ??
            double.tryParse(_numStr(data, 'downtime_minutes'));

    return <String, dynamic>{
      'company_id': companyId,
      'asset_id': assetId,
      'work_order_date': workOrderDateController.text.trim(),
      'work_order_status': stringValue(data, 'work_order_status'),
      'work_order_type': nullIfEmpty(workOrderTypeController.text),
      'execution_mode': nullIfEmpty(executionModeController.text),
      'assigned_technician': nullIfEmpty(assignedTechnicianController.text),
      'assigned_team': nullIfEmpty(assignedTeamController.text),
      'fault_description': nullIfEmpty(faultDescriptionController.text),
      'action_taken': nullIfEmpty(actionTakenController.text),
      'resolution_summary': nullIfEmpty(resolutionSummaryController.text),
      'remarks': nullIfEmpty(remarksController.text),
      'labor_cost': labor,
      'other_cost': other,
      'spare_cost': spare,
      'external_service_cost': ext,
      'total_cost': total,
      'branch_id': ?branchId,
      'location_id': ?locationId,
      'financial_year_id': ?financialYearId,
      'work_order_no': ?nullIfEmpty(workOrderNoController.text.trim()),
      'maintenance_request_id': ?maintenanceRequestId,
      'maintenance_plan_id': ?maintenancePlanId,
      'vendor_party_id': ?vendorPartyId,
      'planned_start_datetime':
          ?nullIfEmpty(plannedStartController.text.trim()),
      'planned_end_datetime':
          ?nullIfEmpty(plannedEndController.text.trim()),
      'actual_start_datetime':
          ?nullIfEmpty(actualStartController.text.trim()),
      'actual_end_datetime': ?nullIfEmpty(actualEndController.text.trim()),
      'downtime_minutes': ?dm,
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
        final response = await _maintenance.createWorkOrder(
          MaintenanceWorkOrderModel(_buildCreatePayload()),
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
        final response = await _maintenance.updateWorkOrder(
          id,
          MaintenanceWorkOrderModel(_buildUpdatePayload()),
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

  MaintenanceWorkOrderModel get _emptyBody =>
      MaintenanceWorkOrderModel(<String, dynamic>{});

  Future<void> approveWorkOrder() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      final response =
          await _maintenance.approveWorkOrder(id, _emptyBody);
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> startWorkOrder() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      final response = await _maintenance.startWorkOrder(id, _emptyBody);
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
      final response =
          await _maintenance.completeWorkOrder(id, _emptyBody);
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
      final response = await _maintenance.closeWorkOrder(id, _emptyBody);
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
      final response =
          await _maintenance.cancelWorkOrder(id, _emptyBody);
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
      await _maintenance.deleteWorkOrder(id);
      actionMessage = 'Work order deleted.';
      await load();
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  String assetPickerLabel(AssetModel a) {
    final d = a.toJson();
    final code = stringValue(d, 'asset_code');
    final name = stringValue(d, 'asset_name');
    if (code.isNotEmpty && name.isNotEmpty) {
      return '$code — $name';
    }
    return code.isNotEmpty ? code : name;
  }

  @override
  void dispose() {
    searchController.dispose();
    workOrderNoController.dispose();
    workOrderDateController.dispose();
    workOrderTypeController.dispose();
    executionModeController.dispose();
    assignedTechnicianController.dispose();
    assignedTeamController.dispose();
    faultDescriptionController.dispose();
    actionTakenController.dispose();
    resolutionSummaryController.dispose();
    plannedStartController.dispose();
    plannedEndController.dispose();
    actualStartController.dispose();
    actualEndController.dispose();
    downtimeMinutesController.dispose();
    laborCostController.dispose();
    otherCostController.dispose();
    remarksController.dispose();
    super.dispose();
  }
}
