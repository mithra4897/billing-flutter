import 'package:billing/screen.dart';

const List<AppDropdownItem<String>> kQcInspectionScopeItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'purchase_receipt', label: 'Purchase receipt'),
      AppDropdownItem(value: 'production_receipt', label: 'Production receipt'),
      AppDropdownItem(value: 'jobwork_receipt', label: 'Jobwork receipt'),
      AppDropdownItem(value: 'stock_receipt', label: 'Stock receipt'),
      AppDropdownItem(value: 'sales_return', label: 'Sales return'),
    ];

/// Maps API source_document_type to inspection_scope (bucket).
const Map<String, String> _sourceTypeToInspectionScope = <String, String>{
  'purchase_receipt': 'purchase_receipt',
  'purchase_receipt_line': 'purchase_receipt',
  'production_receipt': 'production_receipt',
  'production_receipt_line': 'production_receipt',
  'jobwork_receipt': 'jobwork_receipt',
  'jobwork_receipt_line': 'jobwork_receipt',
  'stock_receipt': 'stock_receipt',
  'stock_receipt_line': 'stock_receipt',
  'sales_return': 'sales_return',
  'sales_return_line': 'sales_return',
};

const List<AppDropdownItem<String>> kQcInspectionSourceTypeItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'purchase_receipt', label: 'Purchase receipt'),
      AppDropdownItem(value: 'purchase_receipt_line', label: 'Purchase receipt line'),
      AppDropdownItem(value: 'production_receipt', label: 'Production receipt'),
      AppDropdownItem(
        value: 'production_receipt_line',
        label: 'Production receipt line',
      ),
      AppDropdownItem(value: 'jobwork_receipt', label: 'Jobwork receipt'),
      AppDropdownItem(value: 'jobwork_receipt_line', label: 'Jobwork receipt line'),
      AppDropdownItem(value: 'stock_receipt', label: 'Stock receipt'),
      AppDropdownItem(value: 'stock_receipt_line', label: 'Stock receipt line'),
      AppDropdownItem(value: 'sales_return', label: 'Sales return'),
      AppDropdownItem(value: 'sales_return_line', label: 'Sales return line'),
    ];

String? _scopeForSourceType(String type) => _sourceTypeToInspectionScope[type];

class QcInspectionViewModel extends ChangeNotifier {
  QcInspectionViewModel();

  final QualityService _service = QualityService();
  final MasterService _masterService = MasterService();
  final InventoryService _inventoryService = InventoryService();

  final TextEditingController inspectionDateController =
      TextEditingController();
  final TextEditingController sourceDocumentIdController =
      TextEditingController();
  final TextEditingController sourceLineIdController = TextEditingController();
  final TextEditingController inspectedQtyController = TextEditingController();
  final TextEditingController sampleSizeController = TextEditingController();
  final TextEditingController acceptedQtyController = TextEditingController();
  final TextEditingController rejectedQtyController = TextEditingController();
  final TextEditingController holdQtyController = TextEditingController();
  final TextEditingController reworkQtyController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController lotNoController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<CompanyModel> companies = const <CompanyModel>[];
  List<BranchModel> branches = const <BranchModel>[];
  List<BusinessLocationModel> locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<ItemModel> items = const <ItemModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  List<QcPlanModel> qcPlans = const <QcPlanModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];

  Map<String, dynamic>? _detail;

  int? selectedId;

  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? documentSeriesId;
  String inspectionScope = 'purchase_receipt';
  String sourceDocumentType = 'purchase_receipt';
  int? itemId;
  int? uomId;
  int? qcPlanId;
  int? warehouseId;
  bool isActive = true;

  String get inspectionStatus =>
      stringValue(_detail ?? const <String, dynamic>{}, 'inspection_status');

  String get inspectionNoLabel =>
      stringValue(_detail ?? const <String, dynamic>{}, 'inspection_no');

  bool get canEditHeader =>
      selectedId == null ||
      inspectionStatus == 'draft' ||
      inspectionStatus == 'in_progress';

  bool get canStart => selectedId != null && inspectionStatus == 'draft';

  bool get canComplete =>
      selectedId != null &&
      (inspectionStatus == 'draft' || inspectionStatus == 'in_progress');

  bool get canApprove => selectedId != null && inspectionStatus == 'completed';

  bool get canReject =>
      selectedId != null &&
      (inspectionStatus == 'completed' || inspectionStatus == 'approved');

  bool get canCancelInspection =>
      selectedId != null && inspectionStatus != 'approved';

  bool get canDelete => selectedId != null && inspectionStatus == 'draft';

  List<BranchModel> get branchOptions =>
      branchesForCompany(branches, companyId);

  List<BusinessLocationModel> get locationOptions =>
      locationsForBranch(locations, branchId);

  List<FinancialYearModel> get financialYearOptions =>
      financialYears.where((fy) {
        if (fy.id == null) {
          return false;
        }
        return companyId == null || fy.companyId == companyId;
      }).toList(growable: false);

  List<ItemModel> get itemOptions => items.where((i) {
    if (i.id == null) {
      return false;
    }
    return companyId == null || i.companyId == companyId;
  }).toList(growable: false);

  List<UomModel> get uomOptions => uoms.where((u) => u.id != null).toList(
    growable: false,
  );

  List<WarehouseModel> get warehouseOptions => warehouses.where((w) {
    if (w.id == null) {
      return false;
    }
    if (companyId != null && w.companyId != companyId) {
      return false;
    }
    if (branchId != null && w.branchId != branchId) {
      return false;
    }
    if (locationId != null && w.locationId != locationId) {
      return false;
    }
    return true;
  }).toList(growable: false);

  List<QcPlanModel> get qcPlanOptions => qcPlans.where((p) {
    if (p.id == null) {
      return false;
    }
    if (p.approvalStatus != 'approved' || !p.isActive) {
      return false;
    }
    if (companyId != null && p.companyId != companyId) {
      return false;
    }
    return p.qcScope == 'all';
  }).toList(growable: false);

  List<DocumentSeriesModel> get qcSeriesOptions => documentSeries.where((s) {
    if (s.id == null) {
      return false;
    }
    if (s.documentType != 'QC_INSPECTION') {
      return false;
    }
    return companyId == null || s.companyId == companyId;
  }).toList(growable: false);

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
      final responses = await Future.wait<dynamic>([
        _masterService.companies(filters: const {'per_page': 200}),
        _masterService.branches(filters: const {'per_page': 400}),
        _masterService.businessLocations(filters: const {'per_page': 400}),
        _masterService.financialYears(filters: const {'per_page': 150}),
        _inventoryService.items(filters: const {'per_page': 800}),
        _inventoryService.uoms(filters: const {'per_page': 400}),
        _masterService.warehouses(filters: const {'per_page': 400}),
        _service.qcPlans(filters: const {'per_page': 300}),
        _masterService.documentSeries(filters: const {'per_page': 300}),
      ]);

      companies = ((responses[0] as PaginatedResponse<CompanyModel>).data ??
              const <CompanyModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      branches = ((responses[1] as PaginatedResponse<BranchModel>).data ??
              const <BranchModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      locations =
          ((responses[2] as PaginatedResponse<BusinessLocationModel>).data ??
                  const <BusinessLocationModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      financialYears =
          ((responses[3] as PaginatedResponse<FinancialYearModel>).data ??
                  const <FinancialYearModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      items = ((responses[4] as PaginatedResponse<ItemModel>).data ??
              const <ItemModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      uoms = ((responses[5] as PaginatedResponse<UomModel>).data ??
              const <UomModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      warehouses = ((responses[6] as PaginatedResponse<WarehouseModel>).data ??
              const <WarehouseModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      qcPlans = ((responses[7] as PaginatedResponse<QcPlanModel>).data ??
              const <QcPlanModel>[])
          .toList(growable: false);
      documentSeries =
          ((responses[8] as PaginatedResponse<DocumentSeriesModel>).data ??
                  const <DocumentSeriesModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);

      loading = false;

      if (selectId != null) {
        await _loadDetail(selectId);
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
    selectedId = null;
    _detail = null;
    formError = null;
    companyId ??= companies.isNotEmpty ? companies.first.id : null;
    branchId = branchOptions.isNotEmpty ? branchOptions.first.id : null;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    financialYearId = financialYearOptions.isNotEmpty
        ? financialYearOptions.first.id
        : null;
    documentSeriesId = qcSeriesOptions.isNotEmpty
        ? qcSeriesOptions.first.id
        : null;
    inspectionDateController.text =
        DateTime.now().toIso8601String().split('T').first;
    inspectionScope = 'purchase_receipt';
    sourceDocumentType = 'purchase_receipt';
    sourceDocumentIdController.clear();
    sourceLineIdController.clear();
    final firstItem = itemOptions.isNotEmpty ? itemOptions.first : null;
    itemId = firstItem?.id;
    uomId = firstItem?.baseUomId ?? firstItem?.purchaseUomId;
    qcPlanId = qcPlanOptions.isNotEmpty ? qcPlanOptions.first.id : null;
    warehouseId = null;
    inspectedQtyController.text = '1';
    sampleSizeController.clear();
    acceptedQtyController.text = '0';
    rejectedQtyController.text = '0';
    holdQtyController.text = '0';
    reworkQtyController.text = '0';
    remarksController.clear();
    lotNoController.clear();
    isActive = true;
    notifyListeners();
  }

  Future<void> _loadDetail(int id) async {
    selectedId = id;
    _detail = null;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _service.qcInspection(id);
      final doc = response.data;
      if (doc == null) {
        formError = response.message;
        detailLoading = false;
        notifyListeners();
        return;
      }
      _detail = doc.toJson();
      companyId = intValue(_detail!, 'company_id');
      branchId = intValue(_detail!, 'branch_id');
      locationId = intValue(_detail!, 'location_id');
      financialYearId = intValue(_detail!, 'financial_year_id');
      documentSeriesId = intValue(_detail!, 'document_series_id');
      inspectionDateController.text =
          nullableStringValue(_detail!, 'inspection_date') ??
              DateTime.now().toIso8601String().split('T').first;
      inspectionScope =
          stringValue(_detail!, 'inspection_scope').isNotEmpty
              ? stringValue(_detail!, 'inspection_scope')
              : 'purchase_receipt';
      sourceDocumentType =
          stringValue(_detail!, 'source_document_type').isNotEmpty
              ? stringValue(_detail!, 'source_document_type')
              : 'purchase_receipt';
      sourceDocumentIdController.text =
          intValue(_detail!, 'source_document_id')?.toString() ?? '';
      sourceLineIdController.text =
          intValue(_detail!, 'source_line_id')?.toString() ?? '';
      itemId = intValue(_detail!, 'item_id');
      uomId = intValue(_detail!, 'uom_id');
      qcPlanId = intValue(_detail!, 'qc_plan_id');
      warehouseId = intValue(_detail!, 'warehouse_id');
      inspectedQtyController.text =
          _detail!['inspected_qty']?.toString() ?? '1';
      sampleSizeController.text = _detail!['sample_size']?.toString() ?? '';
      acceptedQtyController.text =
          _detail!['accepted_qty']?.toString() ?? '0';
      rejectedQtyController.text =
          _detail!['rejected_qty']?.toString() ?? '0';
      holdQtyController.text = _detail!['hold_qty']?.toString() ?? '0';
      reworkQtyController.text = _detail!['rework_qty']?.toString() ?? '0';
      remarksController.text = stringValue(_detail!, 'remarks');
      lotNoController.text = stringValue(_detail!, 'lot_no');
      isActive =
          _detail!['is_active'] == true ||
          _detail!['is_active'] == 1 ||
          _detail!['is_active'] == null;
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      notifyListeners();
    }
  }

  void setCompanyId(int? value) {
    if (!canEditHeader) {
      return;
    }
    companyId = value;
    branchId = branchOptions.isNotEmpty ? branchOptions.first.id : null;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    financialYearId = financialYearOptions.isNotEmpty
        ? financialYearOptions.first.id
        : null;
    documentSeriesId = qcSeriesOptions.isNotEmpty
        ? qcSeriesOptions.first.id
        : null;
    notifyListeners();
  }

  void setBranchId(int? value) {
    if (!canEditHeader) {
      return;
    }
    branchId = value;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    notifyListeners();
  }

  void setLocationId(int? value) {
    if (!canEditHeader) {
      return;
    }
    locationId = value;
    notifyListeners();
  }

  void setFinancialYearId(int? value) {
    if (!canEditHeader) {
      return;
    }
    financialYearId = value;
    notifyListeners();
  }

  void setDocumentSeriesId(int? value) {
    if (!canEditHeader) {
      return;
    }
    documentSeriesId = value;
    notifyListeners();
  }

  void setInspectionScope(String value) {
    if (!canEditHeader) {
      return;
    }
    inspectionScope = value;
    String? match;
    for (final e in _sourceTypeToInspectionScope.entries) {
      if (e.value == value) {
        match = e.key;
        break;
      }
    }
    if (match != null) {
      sourceDocumentType = match;
    }
    notifyListeners();
  }

  void setSourceDocumentType(String value) {
    if (!canEditHeader) {
      return;
    }
    sourceDocumentType = value;
    final scope = _scopeForSourceType(value);
    if (scope != null) {
      inspectionScope = scope;
    }
    notifyListeners();
  }

  void setItemId(int? value) {
    if (!canEditHeader) {
      return;
    }
    itemId = value;
    ItemModel? item;
    for (final x in items) {
      if (x.id == value) {
        item = x;
        break;
      }
    }
    if (item != null) {
      uomId = item.baseUomId ?? item.purchaseUomId ?? uomId;
    }
    notifyListeners();
  }

  void setUomId(int? value) {
    if (!canEditHeader) {
      return;
    }
    uomId = value;
    notifyListeners();
  }

  void setQcPlanId(int? value) {
    if (!canEditHeader) {
      return;
    }
    qcPlanId = value;
    notifyListeners();
  }

  void setWarehouseId(int? value) {
    if (!canEditHeader) {
      return;
    }
    warehouseId = value;
    notifyListeners();
  }

  void setIsActive(bool value) {
    if (!canEditHeader) {
      return;
    }
    isActive = value;
    notifyListeners();
  }

  List<Map<String, dynamic>> _fallbackLines() => <Map<String, dynamic>>[
    <String, dynamic>{
      'checkpoint_name': 'Inspection checkpoint',
      'checkpoint_type': 'visual',
      'result_status': 'pass',
      'is_critical': false,
      'is_mandatory': true,
    },
  ];

  Map<String, dynamic> _buildPayload({required bool forCreate}) {
    final srcId = int.tryParse(sourceDocumentIdController.text.trim());
    final lineId = int.tryParse(sourceLineIdController.text.trim());
    final iq = double.tryParse(inspectedQtyController.text.trim()) ?? 0;
    final payload = <String, dynamic>{
      'company_id': companyId,
      'branch_id': branchId,
      'location_id': locationId,
      'financial_year_id': financialYearId,
      'inspection_date': inspectionDateController.text.trim(),
      'inspection_scope': inspectionScope,
      'source_document_type': sourceDocumentType,
      'source_document_id': srcId,
      if (lineId != null) 'source_line_id': lineId,
      'item_id': itemId,
      'uom_id': uomId,
      'inspected_qty': iq,
      if (documentSeriesId != null) 'document_series_id': documentSeriesId,
      if (qcPlanId != null) 'qc_plan_id': qcPlanId,
      if (warehouseId != null) 'warehouse_id': warehouseId,
      if (lotNoController.text.trim().isNotEmpty)
        'lot_no': lotNoController.text.trim(),
      'sample_size': double.tryParse(sampleSizeController.text.trim()) ?? 0,
      'accepted_qty': double.tryParse(acceptedQtyController.text.trim()) ?? 0,
      'rejected_qty': double.tryParse(rejectedQtyController.text.trim()) ?? 0,
      'hold_qty': double.tryParse(holdQtyController.text.trim()) ?? 0,
      'rework_qty': double.tryParse(reworkQtyController.text.trim()) ?? 0,
      if (remarksController.text.trim().isNotEmpty)
        'remarks': remarksController.text.trim(),
      'is_active': isActive ? 1 : 0,
    };

    if (forCreate && qcPlanId == null) {
      payload['lines'] = _fallbackLines();
    }

    return payload;
  }

  Map<String, dynamic> _mergeForUpdate() {
    final base = Map<String, dynamic>.from(_detail ?? const <String, dynamic>{});
    base.addAll(_buildPayload(forCreate: false));
    return base;
  }

  String? _validateForSave() {
    if (companyId == null ||
        branchId == null ||
        locationId == null ||
        financialYearId == null) {
      return 'Company, branch, location and financial year are required.';
    }
    if (itemId == null || uomId == null) {
      return 'Item and UOM are required.';
    }
    final srcId = int.tryParse(sourceDocumentIdController.text.trim());
    if (srcId == null || srcId <= 0) {
      return 'Source document id is required.';
    }
    final iq = double.tryParse(inspectedQtyController.text.trim()) ?? 0;
    if (iq <= 0) {
      return 'Inspected quantity must be greater than zero.';
    }
    if (inspectionDateController.text.trim().isEmpty) {
      return 'Inspection date is required.';
    }
    if (qcPlanId == null && (selectedId == null)) {
      // Lines added in payload via _fallbackLines
    }
    return null;
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
      if (selectedId == null) {
        final body = QcInspectionModel(_buildPayload(forCreate: true));
        final response = await _service.createQcInspection(body);
        actionMessage = response.message;
        if (response.data != null) {
          final newId = intValue(response.data!.toJson(), 'id');
          if (newId != null) {
            await _loadDetail(newId);
            saving = false;
            notifyListeners();
            return;
          }
        }
        await load();
      } else {
        final response = await _service.updateQcInspection(
          selectedId!,
          QcInspectionModel(_mergeForUpdate()),
        );
        actionMessage = response.message;
        await _loadDetail(selectedId!);
      }
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> startInspection() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.startQcInspection(id);
      actionMessage = response.message;
      await _loadDetail(id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> completeInspection() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.completeQcInspection(id);
      actionMessage = response.message;
      await _loadDetail(id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> approveInspection() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.approveQcInspection(id);
      actionMessage = response.message;
      await _loadDetail(id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> rejectInspection() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.rejectQcInspection(id);
      actionMessage = response.message;
      await _loadDetail(id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> cancelInspection() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.cancelQcInspection(id);
      actionMessage = response.message;
      await _loadDetail(id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteInspection() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      await _service.deleteQcInspection(id);
      actionMessage = 'Inspection deleted.';
      selectedId = null;
      _detail = null;
      await load();
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    inspectionDateController.dispose();
    sourceDocumentIdController.dispose();
    sourceLineIdController.dispose();
    inspectedQtyController.dispose();
    sampleSizeController.dispose();
    acceptedQtyController.dispose();
    rejectedQtyController.dispose();
    holdQtyController.dispose();
    reworkQtyController.dispose();
    remarksController.dispose();
    lotNoController.dispose();
    super.dispose();
  }
}
