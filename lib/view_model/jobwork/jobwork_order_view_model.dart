import '../../../screen.dart';
import 'jobwork_module_refresh_controller.dart';

class JobworkMaterialDraft {
  JobworkMaterialDraft({
    this.itemId,
    this.uomId,
    this.lineType = 'raw_material',
    String? plannedQty,
    String? remarks,
    this.dispatchedQty = 0,
    this.receivedBackQty = 0,
    this.consumedQty = 0,
    this.pendingWithVendorQty = 0,
    this.standardRate = 0,
    this.standardAmount = 0,
  }) : plannedQtyController = TextEditingController(text: plannedQty ?? '1'),
       remarksController = TextEditingController(text: remarks ?? '');

  factory JobworkMaterialDraft.fromModel(JobworkOrderMaterialModel m) {
    return JobworkMaterialDraft(
      itemId: m.itemId,
      uomId: m.uomId,
      lineType: m.lineType,
      plannedQty: m.plannedQty.toString(),
      remarks: m.remarks,
      dispatchedQty: m.dispatchedQty,
      receivedBackQty: m.receivedBackQty,
      consumedQty: m.consumedQty,
      pendingWithVendorQty: m.pendingWithVendorQty > 0
          ? m.pendingWithVendorQty
          : m.plannedQty,
      standardRate: m.standardRate,
      standardAmount: m.standardAmount,
    );
  }

  int? itemId;
  int? uomId;
  String lineType;

  final TextEditingController plannedQtyController;
  final TextEditingController remarksController;

  double dispatchedQty;
  double receivedBackQty;
  double consumedQty;
  double pendingWithVendorQty;
  double standardRate;
  double standardAmount;

  JobworkOrderMaterialModel toModel() {
    final planned =
        Validators.parseFlexibleNumber(plannedQtyController.text) ?? 0;
    final pending = pendingWithVendorQty > 0 ? pendingWithVendorQty : planned;
    return JobworkOrderMaterialModel(
      itemId: itemId,
      uomId: uomId,
      lineType: lineType,
      plannedQty: planned,
      dispatchedQty: dispatchedQty,
      receivedBackQty: receivedBackQty,
      consumedQty: consumedQty,
      pendingWithVendorQty: pending,
      standardRate: standardRate,
      standardAmount: standardAmount,
      remarks: nullIfEmpty(remarksController.text),
    );
  }

  void dispose() {
    plannedQtyController.dispose();
    remarksController.dispose();
  }
}

class JobworkOutputDraft {
  JobworkOutputDraft({
    this.itemId,
    this.uomId,
    this.outputType = 'processed_material',
    String? plannedQty,
    String? remarks,
    this.receivedQty = 0,
    this.rejectedQty = 0,
    this.acceptedQty = 0,
    this.standardRate = 0,
    this.standardAmount = 0,
  }) : plannedQtyController = TextEditingController(text: plannedQty ?? '1'),
       remarksController = TextEditingController(text: remarks ?? '');

  factory JobworkOutputDraft.fromModel(JobworkOrderOutputModel m) {
    return JobworkOutputDraft(
      itemId: m.itemId,
      uomId: m.uomId,
      outputType: m.outputType,
      plannedQty: m.plannedQty.toString(),
      remarks: m.remarks,
      receivedQty: m.receivedQty,
      rejectedQty: m.rejectedQty,
      acceptedQty: m.acceptedQty,
      standardRate: m.standardRate,
      standardAmount: m.standardAmount,
    );
  }

  int? itemId;
  int? uomId;
  String outputType;

  final TextEditingController plannedQtyController;
  final TextEditingController remarksController;

  double receivedQty;
  double rejectedQty;
  double acceptedQty;
  double standardRate;
  double standardAmount;

  JobworkOrderOutputModel toModel() {
    final planned =
        Validators.parseFlexibleNumber(plannedQtyController.text) ?? 0;
    final acc = acceptedQty > 0 ? acceptedQty : planned;
    return JobworkOrderOutputModel(
      itemId: itemId,
      uomId: uomId,
      outputType: outputType,
      plannedQty: planned,
      receivedQty: receivedQty,
      rejectedQty: rejectedQty,
      acceptedQty: acc,
      standardRate: standardRate,
      standardAmount: standardAmount,
      remarks: nullIfEmpty(remarksController.text),
    );
  }

  void dispose() {
    plannedQtyController.dispose();
    remarksController.dispose();
  }
}

class JobworkOrderViewModel extends GetxController {
  JobworkOrderViewModel() {
    searchController.addListener(update);
    WorkingContextService.version.addListener(_handleWorkingContextChanged);
  }

  final JobworkModuleRefreshController _refreshController =
      JobworkModuleRefreshController.ensureRegistered();
  final JobworkService _service = JobworkService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController jobworkNoController = TextEditingController();
  final TextEditingController jobworkDateController = TextEditingController();
  final TextEditingController processNameController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController expectedReturnDateController =
      TextEditingController();
  final TextEditingController sourceDocumentTypeController =
      TextEditingController();
  final TextEditingController sourceDocumentIdController =
      TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<JobworkOrderModel> rows = const <JobworkOrderModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<BranchModel> branches = const <BranchModel>[];
  List<BusinessLocationModel> locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<PartyModel> parties = const <PartyModel>[];
  List<PartyTypeModel> partyTypes = const <PartyTypeModel>[];
  List<ItemModel> items = const <ItemModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<UomConversionModel> uomConversions = const <UomConversionModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];

  JobworkOrderModel? selected;
  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? documentSeriesId;
  int? supplierPartyId;
  String processType = 'other';
  String sourceType = 'manual';
  int? issueWarehouseId;
  int? receiptWarehouseId;
  bool isActive = true;

  List<JobworkMaterialDraft> materialDrafts = <JobworkMaterialDraft>[];
  List<JobworkOutputDraft> outputDrafts = <JobworkOutputDraft>[];

  void _handleWorkingContextChanged() {
    load(selectId: selected?.id);
  }

  String get jobworkStatus => selected?.jobworkStatus ?? 'draft';

  bool get isLocked =>
      jobworkStatus == 'closed' || jobworkStatus == 'cancelled';

  bool get canEditLines => jobworkStatus == 'draft';

  bool get canRelease => selected != null && jobworkStatus == 'draft';

  bool get canClose =>
      selected != null &&
      (jobworkStatus == 'fully_received' ||
          jobworkStatus == 'partially_received');

  bool get canCancel => selected != null && jobworkStatus != 'closed';

  bool get canDelete => selected != null && jobworkStatus == 'draft';

  List<BranchModel> get branchOptions =>
      branchesForCompany(branches, companyId);

  List<BusinessLocationModel> get locationOptions =>
      locationsForBranch(locations, branchId);

  List<PartyModel> get supplierOptions =>
      purchaseSuppliers(parties: parties, partyTypes: partyTypes);

  List<DocumentSeriesModel> get seriesOptions {
    final filtered = documentSeries.where((s) {
      final dt = (s.documentType ?? '').trim().toUpperCase();
      final sameCompany = companyId == null || s.companyId == companyId;
      final fyOk =
          financialYearId == null || s.financialYearId == financialYearId;
      return sameCompany && fyOk && (dt == 'JOBWORK_ORDER' || dt == 'JOBWORK');
    }).toList();
    if (filtered.isNotEmpty) {
      return filtered;
    }
    return documentSeries
        .where(
          (s) =>
              (companyId == null || s.companyId == companyId) &&
              (financialYearId == null || s.financialYearId == financialYearId),
        )
        .toList();
  }

  List<WarehouseModel> get warehouseOptions => warehouses
      .where((w) {
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
      })
      .toList(growable: false);

  List<JobworkOrderModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows
        .where((row) {
          if (q.isEmpty) {
            return true;
          }
          return [
            row.jobworkNo,
            row.processName,
            row.jobworkStatus,
            row.supplierLabel,
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  String? consumeActionMessage() {
    final message = actionMessage;
    actionMessage = null;
    return message;
  }

  void _disposeLineDrafts() {
    for (final d in materialDrafts) {
      d.dispose();
    }
    for (final d in outputDrafts) {
      d.dispose();
    }
    materialDrafts = <JobworkMaterialDraft>[];
    outputDrafts = <JobworkOutputDraft>[];
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    update();
    try {
      await MasterDataCache.to.ensureLoaded();
      final cache = MasterDataCache.to;
      final responses = await Future.wait<dynamic>([
        _service.orders(
          filters: const {'per_page': 200, 'sort_by': 'jobwork_date'},
        ),
      ]);
      rows =
          (responses[0] as PaginatedResponse<JobworkOrderModel>).data ??
          const <JobworkOrderModel>[];
      companies = cache.activeCompanies;
      branches = cache.activeBranches;
      locations = cache.activeLocations;
      financialYears = cache.activeFinancialYears;
      documentSeries = cache.activeDocumentSeries;
      parties = cache.activeParties;
      partyTypes = cache.activePartyTypes;
      items = cache.activeItems;
      uoms = cache.activeUoms;
      uomConversions = cache.activeUomConversions;
      warehouses = cache.activeWarehouses;
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: companies,
            branches: branches,
            locations: locations,
            financialYears: financialYears,
          );
      companyId = contextSelection.companyId;
      branchId = contextSelection.branchId;
      locationId = contextSelection.locationId;
      financialYearId = contextSelection.financialYearId;

      loading = false;

      if (selectId != null) {
        final existing = rows.cast<JobworkOrderModel?>().firstWhere(
          (x) => x?.id == selectId,
          orElse: () => null,
        );
        if (existing != null) {
          await select(existing);
          return;
        }
        if (await restoreSelectionAfterReload<JobworkOrderModel>(
          selectId: selectId,
          rows: rows,
          selected: selected,
          onSelect: select,
          replaceRows: (nextRows) => rows = nextRows,
          notify: update,
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
    _disposeLineDrafts();
    final contextSelection = normalizedWorkingContextSelection(
      companies: companies,
      branches: branches,
      locations: locations,
      financialYears: financialYears,
      companyId: companyId,
      branchId: branchId,
      locationId: locationId,
      financialYearId: financialYearId,
    );
    companyId = contextSelection.companyId;
    branchId = contextSelection.branchId;
    locationId = contextSelection.locationId;
    financialYearId = contextSelection.financialYearId;
    documentSeriesId = seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    supplierPartyId = null;
    processType = 'other';
    sourceType = 'manual';
    issueWarehouseId = warehouseOptions.isNotEmpty
        ? warehouseOptions.first.id
        : null;
    receiptWarehouseId = warehouseOptions.isNotEmpty
        ? warehouseOptions.first.id
        : null;
    jobworkNoController.clear();
    jobworkDateController.text = displayTodayDate();
    processNameController.clear();
    notesController.clear();
    expectedReturnDateController.clear();
    sourceDocumentTypeController.clear();
    sourceDocumentIdController.clear();
    isActive = true;
    materialDrafts = <JobworkMaterialDraft>[JobworkMaterialDraft()];
    outputDrafts = <JobworkOutputDraft>[JobworkOutputDraft()];
    update();
  }

  Future<void> select(JobworkOrderModel row) async {
    final id = row.id;
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    formError = null;
    update();
    try {
      final response = await _service.order(id);
      final doc = response.data;
      final data = doc ?? row;
      companyId = data.companyId;
      branchId = data.branchId;
      locationId = data.locationId;
      financialYearId = data.financialYearId;
      documentSeriesId = data.documentSeriesId;
      supplierPartyId = data.supplierPartyId;
      processType = data.processType;
      sourceType = data.sourceType;
      issueWarehouseId = data.issueWarehouseId;
      receiptWarehouseId = data.receiptWarehouseId;
      jobworkNoController.text = data.jobworkNo;
      jobworkDateController.text = displayDate(
        data.jobworkDate.isNotEmpty ? data.jobworkDate : null,
      );
      processNameController.text = data.processName;
      notesController.text = data.notes ?? '';
      expectedReturnDateController.text = displayDate(
        data.expectedReturnDate ?? '',
      );
      sourceDocumentTypeController.text = data.sourceDocumentType ?? '';
      sourceDocumentIdController.text = data.sourceDocumentId?.toString() ?? '';
      isActive = data.isActive;

      _disposeLineDrafts();
      materialDrafts = data.materials.isEmpty
          ? <JobworkMaterialDraft>[JobworkMaterialDraft()]
          : data.materials
                .map(JobworkMaterialDraft.fromModel)
                .toList(growable: false);
      outputDrafts = data.outputs.isEmpty
          ? <JobworkOutputDraft>[JobworkOutputDraft()]
          : data.outputs
                .map(JobworkOutputDraft.fromModel)
                .toList(growable: false);
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      update();
    }
  }

  void onCompanyChanged(int? value) {
    if (isLocked) {
      return;
    }
    companyId = value;
    branchId = branchOptions.isNotEmpty ? branchOptions.first.id : null;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    documentSeriesId = seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    issueWarehouseId = warehouseOptions.isNotEmpty
        ? warehouseOptions.first.id
        : null;
    receiptWarehouseId = warehouseOptions.isNotEmpty
        ? warehouseOptions.first.id
        : null;
    update();
  }

  void onBranchChanged(int? value) {
    if (isLocked) {
      return;
    }
    branchId = value;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    issueWarehouseId = warehouseOptions.isNotEmpty
        ? warehouseOptions.first.id
        : null;
    receiptWarehouseId = warehouseOptions.isNotEmpty
        ? warehouseOptions.first.id
        : null;
    update();
  }

  void onLocationChanged(int? value) {
    if (isLocked) {
      return;
    }
    locationId = value;
    issueWarehouseId = warehouseOptions.isNotEmpty
        ? warehouseOptions.first.id
        : null;
    receiptWarehouseId = warehouseOptions.isNotEmpty
        ? warehouseOptions.first.id
        : null;
    update();
  }

  void setFinancialYearId(int? value) {
    if (isLocked) {
      return;
    }
    financialYearId = value;
    documentSeriesId = seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    update();
  }

  void setSupplierPartyId(int? value) {
    if (isLocked) {
      return;
    }
    supplierPartyId = value;
    update();
  }

  void setProcessType(String value) {
    if (isLocked) {
      return;
    }
    processType = value;
    update();
  }

  void setSourceType(String value) {
    if (isLocked) {
      return;
    }
    sourceType = value;
    update();
  }

  void setIssueWarehouseId(int? value) {
    if (isLocked) {
      return;
    }
    issueWarehouseId = value;
    update();
  }

  void setReceiptWarehouseId(int? value) {
    if (isLocked) {
      return;
    }
    receiptWarehouseId = value;
    update();
  }

  void setDocumentSeriesId(int? value) {
    if (isLocked) {
      return;
    }
    documentSeriesId = value;
    update();
  }

  List<UomModel> uomOptionsForItem(int? itemId) {
    final item = items.cast<ItemModel?>().firstWhere(
      (x) => x?.id == itemId,
      orElse: () => null,
    );
    return allowedUomsForItem(item, uoms, uomConversions);
  }

  void addMaterialLine() {
    if (!canEditLines) {
      return;
    }
    materialDrafts = List<JobworkMaterialDraft>.from(materialDrafts)
      ..add(JobworkMaterialDraft());
    update();
  }

  void removeMaterialLine(int index) {
    if (!canEditLines || materialDrafts.length <= 1) {
      return;
    }
    final copy = List<JobworkMaterialDraft>.from(materialDrafts);
    final removed = copy.removeAt(index);
    materialDrafts = copy;
    update();
    disposeDraftEntriesNextFrame<JobworkMaterialDraft>([
      removed,
    ], (entry) => entry.dispose());
  }

  void setMaterialItemId(int index, int? value) {
    if (!canEditLines) {
      return;
    }
    final line = materialDrafts[index];
    line.itemId = value;
    final item = items.cast<ItemModel?>().firstWhere(
      (x) => x?.id == value,
      orElse: () => null,
    );
    line.uomId = defaultUomIdForItem(
      item,
      uoms,
      uomConversions,
      current: line.uomId,
    );
    update();
  }

  void setMaterialUomId(int index, int? value) {
    if (!canEditLines) {
      return;
    }
    materialDrafts[index].uomId = value;
    update();
  }

  void setMaterialLineType(int index, String value) {
    if (!canEditLines) {
      return;
    }
    materialDrafts[index].lineType = value;
    update();
  }

  void addOutputLine() {
    if (!canEditLines) {
      return;
    }
    outputDrafts = List<JobworkOutputDraft>.from(outputDrafts)
      ..add(JobworkOutputDraft());
    update();
  }

  void removeOutputLine(int index) {
    if (!canEditLines || outputDrafts.length <= 1) {
      return;
    }
    final copy = List<JobworkOutputDraft>.from(outputDrafts);
    final removed = copy.removeAt(index);
    outputDrafts = copy;
    update();
    disposeDraftEntriesNextFrame<JobworkOutputDraft>([
      removed,
    ], (entry) => entry.dispose());
  }

  void setOutputItemId(int index, int? value) {
    if (!canEditLines) {
      return;
    }
    final line = outputDrafts[index];
    line.itemId = value;
    final item = items.cast<ItemModel?>().firstWhere(
      (x) => x?.id == value,
      orElse: () => null,
    );
    line.uomId = defaultUomIdForItem(
      item,
      uoms,
      uomConversions,
      current: line.uomId,
    );
    update();
  }

  void setOutputUomId(int index, int? value) {
    if (!canEditLines) {
      return;
    }
    outputDrafts[index].uomId = value;
    update();
  }

  void setOutputType(int index, String value) {
    if (!canEditLines) {
      return;
    }
    outputDrafts[index].outputType = value;
    update();
  }

  String? _validateForSave() {
    if (companyId == null ||
        branchId == null ||
        locationId == null ||
        financialYearId == null) {
      return 'Company, branch, location and financial year are required.';
    }
    if (supplierPartyId == null) {
      return 'Supplier is required.';
    }
    if (processNameController.text.trim().isEmpty) {
      return 'Process name is required.';
    }
    if (jobworkDateController.text.trim().isEmpty) {
      return 'Jobwork date is required.';
    }
    if (issueWarehouseId == null || receiptWarehouseId == null) {
      return 'Issue and receipt warehouses are required.';
    }
    if (documentSeriesId == null && jobworkNoController.text.trim().isEmpty) {
      return 'Document series is required when jobwork number is empty.';
    }
    if (canEditLines) {
      if (materialDrafts.isEmpty || outputDrafts.isEmpty) {
        return 'At least one material line and one output line are required.';
      }
      for (final d in materialDrafts) {
        if (d.itemId == null ||
            d.uomId == null ||
            (Validators.parseFlexibleNumber(d.plannedQtyController.text) ??
                    0) <=
                0) {
          return 'Each material line needs item, UOM and planned quantity.';
        }
      }
      for (final d in outputDrafts) {
        if (d.itemId == null ||
            d.uomId == null ||
            (Validators.parseFlexibleNumber(d.plannedQtyController.text) ??
                    0) <=
                0) {
          return 'Each output line needs item, UOM and planned quantity.';
        }
      }
    }
    return null;
  }

  JobworkOrderModel _buildFullDocument() {
    final sidText = sourceDocumentIdController.text.trim();
    final sid = int.tryParse(sidText);
    return JobworkOrderModel(
      companyId: companyId,
      branchId: branchId,
      locationId: locationId,
      financialYearId: financialYearId,
      documentSeriesId: documentSeriesId,
      jobworkNo: jobworkNoController.text.trim(),
      jobworkDate: jobworkDateController.text.trim(),
      supplierPartyId: supplierPartyId,
      processName: processNameController.text.trim(),
      processType: processType,
      sourceType: sourceType,
      sourceDocumentType: nullIfEmpty(sourceDocumentTypeController.text),
      sourceDocumentId: sid,
      issueWarehouseId: issueWarehouseId,
      receiptWarehouseId: receiptWarehouseId,
      expectedReturnDate: nullIfEmpty(expectedReturnDateController.text),
      notes: nullIfEmpty(notesController.text),
      isActive: isActive,
      materials: materialDrafts.map((d) => d.toModel()).toList(),
      outputs: outputDrafts.map((d) => d.toModel()).toList(),
    );
  }

  Map<String, dynamic> _buildHeaderOnlyPayload() {
    final sidText = sourceDocumentIdController.text.trim();
    final sid = int.tryParse(sidText);
    final payload = <String, dynamic>{
      'company_id': companyId,
      'branch_id': branchId,
      'location_id': locationId,
      'financial_year_id': financialYearId,
      'document_series_id': documentSeriesId,
      if (jobworkNoController.text.trim().isNotEmpty)
        'jobwork_no': jobworkNoController.text.trim(),
      'jobwork_date': jobworkDateController.text.trim(),
      'supplier_party_id': supplierPartyId,
      'process_name': processNameController.text.trim(),
      'process_type': processType,
      'source_type': sourceType,
      if (nullIfEmpty(sourceDocumentTypeController.text) != null)
        'source_document_type': nullIfEmpty(sourceDocumentTypeController.text),
      'issue_warehouse_id': issueWarehouseId,
      'receipt_warehouse_id': receiptWarehouseId,
      if (nullIfEmpty(expectedReturnDateController.text) != null)
        'expected_return_date': nullIfEmpty(expectedReturnDateController.text),
      if (notesController.text.trim().isNotEmpty)
        'notes': notesController.text.trim(),
      'is_active': isActive ? 1 : 0,
    };
    if (sid != null) {
      payload['source_document_id'] = sid;
    }
    return payload;
  }

  Future<void> save() async {
    final validationError = _validateForSave();
    if (validationError != null) {
      formError = validationError;
      update();
      return;
    }
    saving = true;
    formError = null;
    actionMessage = null;
    update();
    try {
      if (selected == null) {
        final doc = _buildFullDocument();
        final response = await _service.createOrder(doc);
        actionMessage = response.message;
        await load(selectId: response.data?.id);
        _refreshController.notifyChanged(source: 'jobwork_order');
      } else if (canEditLines) {
        final doc = _buildFullDocument();
        final response = await _service.updateOrder(selected!.id!, doc);
        actionMessage = response.message;
        await load(selectId: selected!.id);
        _refreshController.notifyChanged(source: 'jobwork_order');
      } else {
        final response = await _service.updateOrder(
          selected!.id!,
          _buildHeaderOnlyPayload(),
        );
        actionMessage = response.message;
        await load(selectId: selected!.id);
        _refreshController.notifyChanged(source: 'jobwork_order');
      }
    } catch (e) {
      formError = e.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> release() async {
    final id = selected?.id;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.releaseOrder(id);
      actionMessage = response.message;
      await load(selectId: id);
      _refreshController.notifyChanged(source: 'jobwork_order');
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  Future<void> closeOrder() async {
    final id = selected?.id;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.closeOrder(id);
      actionMessage = response.message;
      await load(selectId: id);
      _refreshController.notifyChanged(source: 'jobwork_order');
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  Future<void> cancelOrder() async {
    final id = selected?.id;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.cancelOrder(id);
      actionMessage = response.message;
      await load(selectId: id);
      _refreshController.notifyChanged(source: 'jobwork_order');
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  Future<void> deleteOrder() async {
    final id = selected?.id;
    if (id == null) {
      return;
    }
    try {
      await _service.deleteOrder(id);
      actionMessage = 'Jobwork order deleted.';
      await load();
      _refreshController.notifyChanged(source: 'jobwork_order');
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  @override
  void onClose() {
    WorkingContextService.version.removeListener(_handleWorkingContextChanged);
    searchController.dispose();
    jobworkNoController.dispose();
    jobworkDateController.dispose();
    processNameController.dispose();
    notesController.dispose();
    expectedReturnDateController.dispose();
    sourceDocumentTypeController.dispose();
    sourceDocumentIdController.dispose();
    _disposeLineDrafts();
    super.onClose();
  }
}
