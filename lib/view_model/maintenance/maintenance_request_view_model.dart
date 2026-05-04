import 'package:billing/screen.dart';
import 'package:billing/view/hr/hr_workflow_dialogs.dart';
import 'package:billing/view/purchase/purchase_support.dart';

class MaintenanceRequestViewModel extends ChangeNotifier {
  MaintenanceRequestViewModel() {
    searchController.addListener(notifyListeners);
  }

  final MaintenanceService _maintenance = MaintenanceService();
  final MasterService _master = MasterService();
  final AssetsService _assets = AssetsService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController requestNoController = TextEditingController();
  final TextEditingController requestDateController = TextEditingController();
  final TextEditingController issueTitleController = TextEditingController();
  final TextEditingController issueDescriptionController =
      TextEditingController();
  final TextEditingController requestTypeController = TextEditingController();
  final TextEditingController priorityLevelController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController targetCompletionController =
      TextEditingController();
  final TextEditingController requestedByController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<MaintenanceRequestModel> rows = const <MaintenanceRequestModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<BranchModel> branches = const <BranchModel>[];
  List<BusinessLocationModel> locations = const <BusinessLocationModel>[];
  List<AssetModel> assets = const <AssetModel>[];
  List<MaintenancePlanModel> maintenancePlans = const <MaintenancePlanModel>[];

  MaintenanceRequestModel? selected;

  int? companyId;
  int? documentSeriesId;
  int? assetId;
  int? branchId;
  int? locationId;
  int? maintenancePlanId;

  int? _sessionCompanyId;

  int? get selectedId =>
      intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');

  String get requestStatus =>
      stringValue(selected?.toJson() ?? const <String, dynamic>{}, 'request_status');

  bool get canEdit {
    if (selected == null) {
      return true;
    }
    return !const {'completed', 'cancelled', 'rejected'}
        .contains(requestStatus);
  }

  bool get canApprove =>
      selected != null &&
      (requestStatus == 'draft' || requestStatus == 'open');

  bool get canCancel =>
      selected != null && requestStatus != 'completed';

  bool get canDelete =>
      selected != null &&
      (requestStatus == 'draft' || requestStatus == 'open');

  List<DocumentSeriesModel> get seriesOptions {
    final cid = companyId;
    return documentSeries.where((s) {
      if (!s.isActive) {
        return false;
      }
      if ((s.documentType ?? '').trim() != 'MAINTENANCE_REQUEST') {
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

  List<MaintenanceRequestModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows.where((row) {
      if (q.isEmpty) {
        return true;
      }
      final data = row.toJson();
      return [
        stringValue(data, 'request_no'),
        stringValue(data, 'issue_title'),
        stringValue(data, 'request_status'),
        stringValue(data, 'request_type'),
      ].join(' ').toLowerCase().contains(q);
    }).toList(growable: false);
  }

  String listTitle(MaintenanceRequestModel row) {
    final data = row.toJson();
    final no = stringValue(data, 'request_no');
    if (no.isNotEmpty) {
      return no;
    }
    final title = stringValue(data, 'issue_title');
    if (title.isNotEmpty) {
      return title;
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
        _maintenance.requests(filters: filters),
        _master.companies(filters: const {'per_page': 200}),
        _master.documentSeries(filters: const {'per_page': 400}),
        _master.branches(filters: const {'per_page': 500}),
        _master.businessLocations(filters: const {'per_page': 800}),
      ]);

      rows =
          (responses[0] as PaginatedResponse<MaintenanceRequestModel>).data ??
              const <MaintenanceRequestModel>[];
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

      loading = false;

      if (selectId != null) {
        MaintenanceRequestModel? match;
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
          MaintenanceRequestModel(<String, dynamic>{'id': selectId}),
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
    } catch (_) {
      assets = const <AssetModel>[];
      maintenancePlans = const <MaintenancePlanModel>[];
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
    maintenancePlanId = null;
    requestNoController.clear();
    requestDateController.text =
        DateTime.now().toIso8601String().split('T').first;
    issueTitleController.clear();
    issueDescriptionController.clear();
    requestTypeController.clear();
    priorityLevelController.text = 'medium';
    remarksController.clear();
    targetCompletionController.clear();
    requestedByController.clear();
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

  void setMaintenancePlanId(int? value) {
    if (!canEdit) {
      return;
    }
    maintenancePlanId = value;
    notifyListeners();
  }

  Future<void> select(MaintenanceRequestModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _maintenance.request(id);
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

  void _applyDetail(Map<String, dynamic> data) {
    companyId = intValue(data, 'company_id');
    assetId = intValue(data, 'asset_id');
    branchId = intValue(data, 'branch_id');
    locationId = intValue(data, 'location_id');
    maintenancePlanId = intValue(data, 'maintenance_plan_id');
    requestNoController.text = stringValue(data, 'request_no');
    requestDateController.text = displayDate(
      nullableStringValue(data, 'request_date'),
    );
    issueTitleController.text = stringValue(data, 'issue_title');
    issueDescriptionController.text = stringValue(data, 'issue_description');
    requestTypeController.text = stringValue(data, 'request_type');
    priorityLevelController.text = stringValue(data, 'priority_level');
    remarksController.text = stringValue(data, 'remarks');
    targetCompletionController.text = displayDate(
      nullableStringValue(data, 'target_completion_date'),
    );
    requestedByController.text =
        intValue(data, 'requested_by')?.toString() ?? '';
    documentSeriesId = null;
  }

  String? _validateForSave() {
    if (companyId == null) {
      return 'Company is required.';
    }
    if (assetId == null) {
      return 'Asset is required.';
    }
    if (requestDateController.text.trim().isEmpty) {
      return 'Request date is required.';
    }
    if (issueTitleController.text.trim().isEmpty) {
      return 'Issue title is required.';
    }
    final manualNo = requestNoController.text.trim();
    if (manualNo.isEmpty && documentSeriesId == null) {
      return 'Enter a request number or select a document series.';
    }
    return null;
  }

  Map<String, dynamic> _buildCreatePayload() {
    final rb = int.tryParse(requestedByController.text.trim());
    return <String, dynamic>{
      'company_id': companyId,
      'asset_id': assetId,
      'request_date': requestDateController.text.trim(),
      'issue_title': issueTitleController.text.trim(),
      'issue_description': nullIfEmpty(issueDescriptionController.text),
      'request_type': nullIfEmpty(requestTypeController.text),
      'priority_level':
          nullIfEmpty(priorityLevelController.text.trim()) ?? 'medium',
      'request_status': 'draft',
      'branch_id': ?branchId,
      'location_id': ?locationId,
      'maintenance_plan_id': ?maintenancePlanId,
      'requested_by': ?rb,
      'target_completion_date':
          ?nullIfEmpty(targetCompletionController.text.trim()),
      'remarks': nullIfEmpty(remarksController.text),
      'document_series_id': ?documentSeriesId,
      'request_no': ?nullIfEmpty(requestNoController.text.trim()),
    };
  }

  Map<String, dynamic> _buildUpdatePayload() {
    final rb = int.tryParse(requestedByController.text.trim());
    final data = selected?.toJson() ?? const <String, dynamic>{};
    return <String, dynamic>{
      'company_id': companyId,
      'asset_id': assetId,
      'request_date': requestDateController.text.trim(),
      'issue_title': issueTitleController.text.trim(),
      'issue_description': nullIfEmpty(issueDescriptionController.text),
      'request_type': nullIfEmpty(requestTypeController.text),
      'priority_level':
          nullIfEmpty(priorityLevelController.text.trim()) ?? 'medium',
      'request_status': stringValue(data, 'request_status'),
      'branch_id': ?branchId,
      'location_id': ?locationId,
      'maintenance_plan_id': ?maintenancePlanId,
      'requested_by': ?rb,
      'target_completion_date':
          ?nullIfEmpty(targetCompletionController.text.trim()),
      'remarks': nullIfEmpty(remarksController.text),
      'request_no': ?nullIfEmpty(requestNoController.text.trim()),
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
        final response = await _maintenance.createRequest(
          MaintenanceRequestModel(_buildCreatePayload()),
        );
        actionMessage = response.message;
        await load(selectId: intValue(response.data?.toJson() ?? {}, 'id'));
      } else {
        final id = selectedId;
        if (id == null) {
          formError = 'Missing request id.';
          notifyListeners();
          return;
        }
        final response = await _maintenance.updateRequest(
          id,
          MaintenanceRequestModel(_buildUpdatePayload()),
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

  Future<void> approveRequest() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    final empty = MaintenanceRequestModel(<String, dynamic>{});
    try {
      final response = await _maintenance.approveRequest(id, empty);
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> cancelRequest() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    final empty = MaintenanceRequestModel(<String, dynamic>{});
    try {
      final response = await _maintenance.cancelRequest(id, empty);
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteRequest() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      await _maintenance.deleteRequest(id);
      actionMessage = 'Maintenance request deleted.';
      await load();
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  String assetLabel(AssetModel a) {
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
    requestNoController.dispose();
    requestDateController.dispose();
    issueTitleController.dispose();
    issueDescriptionController.dispose();
    requestTypeController.dispose();
    priorityLevelController.dispose();
    remarksController.dispose();
    targetCompletionController.dispose();
    requestedByController.dispose();
    super.dispose();
  }
}
