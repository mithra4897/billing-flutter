import 'package:billing/screen.dart';
import 'package:billing/view/purchase/purchase_support.dart';

class JobworkReceiptLineDraft {
  JobworkReceiptLineDraft({
    this.jobworkOrderOutputId,
    this.itemId,
    this.uomId,
    this.warehouseId,
    this.outputType = 'processed_material',
    String? receiptQty,
    String? acceptedQty,
    String? rejectedQty,
    String? unitCost,
    String? remarks,
  }) : receiptQtyController = TextEditingController(text: receiptQty ?? '1'),
       acceptedQtyController = TextEditingController(text: acceptedQty ?? '1'),
       rejectedQtyController = TextEditingController(text: rejectedQty ?? '0'),
       unitCostController = TextEditingController(text: unitCost ?? '0'),
       remarksController = TextEditingController(text: remarks ?? '');

  factory JobworkReceiptLineDraft.fromModel(JobworkReceiptLineModel m) {
    return JobworkReceiptLineDraft(
      jobworkOrderOutputId: m.jobworkOrderOutputId,
      itemId: m.itemId,
      uomId: m.uomId,
      warehouseId: m.warehouseId,
      outputType: m.outputType,
      receiptQty: m.receiptQty.toString(),
      acceptedQty: m.acceptedQty.toString(),
      rejectedQty: m.rejectedQty.toString(),
      unitCost: m.unitCost.toString(),
      remarks: m.remarks,
    );
  }

  int? jobworkOrderOutputId;
  int? itemId;
  int? uomId;
  int? warehouseId;
  String outputType;

  final TextEditingController receiptQtyController;
  final TextEditingController acceptedQtyController;
  final TextEditingController rejectedQtyController;
  final TextEditingController unitCostController;
  final TextEditingController remarksController;

  JobworkReceiptLineModel toModel({required int? headerWarehouseId}) {
    final rq = double.tryParse(receiptQtyController.text.trim()) ?? 0;
    final aq = double.tryParse(acceptedQtyController.text.trim()) ?? rq;
    final rjq = double.tryParse(rejectedQtyController.text.trim()) ?? 0;
    final uc = double.tryParse(unitCostController.text.trim()) ?? 0;
    final tc = (aq * uc).toStringAsFixed(2);
    return JobworkReceiptLineModel(
      jobworkOrderOutputId: jobworkOrderOutputId,
      itemId: itemId,
      uomId: uomId,
      warehouseId: warehouseId ?? headerWarehouseId,
      receiptQty: rq,
      acceptedQty: aq,
      rejectedQty: rjq,
      outputType: outputType,
      unitCost: uc,
      totalCost: double.tryParse(tc) ?? 0,
      remarks: nullIfEmpty(remarksController.text),
    );
  }

  void dispose() {
    receiptQtyController.dispose();
    acceptedQtyController.dispose();
    rejectedQtyController.dispose();
    unitCostController.dispose();
    remarksController.dispose();
  }
}

class JobworkReceiptViewModel extends ChangeNotifier {
  JobworkReceiptViewModel() {
    searchController.addListener(notifyListeners);
  }

  final JobworkService _service = JobworkService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final InventoryService _inventoryService = InventoryService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController receiptNoController = TextEditingController();
  final TextEditingController receiptDateController = TextEditingController();
  final TextEditingController supplierDcNoController = TextEditingController();
  final TextEditingController supplierDcDateController = TextEditingController();
  final TextEditingController vehicleNoController = TextEditingController();
  final TextEditingController lrNoController = TextEditingController();
  final TextEditingController lrDateController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<JobworkReceiptModel> rows = const <JobworkReceiptModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<BranchModel> branches = const <BranchModel>[];
  List<BusinessLocationModel> locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<PartyModel> parties = const <PartyModel>[];
  List<PartyTypeModel> partyTypes = const <PartyTypeModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  List<ItemModel> items = const <ItemModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<UomConversionModel> uomConversions = const <UomConversionModel>[];
  List<JobworkOrderModel> jobworkOrders = const <JobworkOrderModel>[];

  JobworkReceiptModel? selected;
  JobworkOrderModel? selectedOrderDetail;

  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? documentSeriesId;
  int? jobworkOrderId;
  int? supplierPartyId;
  int? warehouseId;
  int? transporterPartyId;
  String receiptMode = 'processed_receipt';
  bool isActive = true;

  List<JobworkReceiptLineDraft> lineDrafts = <JobworkReceiptLineDraft>[];

  String get receiptStatus => selected?.receiptStatus ?? 'draft';

  bool get isLocked =>
      receiptStatus == 'posted' || receiptStatus == 'cancelled';

  bool get canEditLines => receiptStatus == 'draft';

  bool get canPost => selected != null && receiptStatus == 'draft';

  bool get canCancelReceipt =>
      selected != null && receiptStatus == 'draft';

  bool get canDelete => selected != null && receiptStatus == 'draft';

  List<BranchModel> get branchOptions => branchesForCompany(branches, companyId);
  List<BusinessLocationModel> get locationOptions =>
      locationsForBranch(locations, branchId);

  List<PartyModel> get supplierOptions =>
      purchaseSuppliers(parties: parties, partyTypes: partyTypes);

  List<DocumentSeriesModel> get seriesOptions {
    final filtered = documentSeries.where((s) {
      final dt = (s.documentType ?? '').trim().toUpperCase();
      final okCompany = companyId == null || s.companyId == companyId;
      final fyOk =
          financialYearId == null || s.financialYearId == financialYearId;
      return okCompany && fyOk && dt == 'JOBWORK_RECEIPT';
    }).toList();
    if (filtered.isNotEmpty) {
      return filtered;
    }
    return documentSeries
        .where(
          (s) =>
              (companyId == null || s.companyId == companyId) &&
              (financialYearId == null ||
                  s.financialYearId == financialYearId),
        )
        .toList();
  }

  List<JobworkOrderModel> get jobworkOrderOptions => jobworkOrders
      .where((o) => companyId == null || o.companyId == companyId)
      .toList(growable: false);

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

  List<JobworkReceiptModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows.where((row) {
      if (q.isEmpty) {
        return true;
      }
      return [
        row.receiptNo,
        row.receiptStatus,
        row.supplierLabel,
        row.jobworkOrderNoLabel,
      ].join(' ').toLowerCase().contains(q);
    }).toList(growable: false);
  }

  List<JobworkOrderOutputModel> get orderOutputOptions =>
      selectedOrderDetail?.outputs ?? const <JobworkOrderOutputModel>[];

  String? consumeActionMessage() {
    final message = actionMessage;
    actionMessage = null;
    return message;
  }

  void _disposeLines() {
    for (final d in lineDrafts) {
      d.dispose();
    }
    lineDrafts = <JobworkReceiptLineDraft>[];
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    notifyListeners();
    try {
      final responses = await Future.wait<dynamic>([
        _service.receipts(
          filters: const {'per_page': 200, 'sort_by': 'receipt_date'},
        ),
        _masterService.companies(filters: const {'per_page': 200}),
        _masterService.branches(filters: const {'per_page': 300}),
        _masterService.businessLocations(filters: const {'per_page': 300}),
        _masterService.financialYears(filters: const {'per_page': 100}),
        _masterService.documentSeries(filters: const {'per_page': 300}),
        _partiesService.parties(filters: const {'per_page': 500}),
        _partiesService.partyTypes(filters: const {'per_page': 100}),
        _masterService.warehouses(filters: const {'per_page': 300}),
        _inventoryService.items(filters: const {'per_page': 500}),
        _inventoryService.uoms(filters: const {'per_page': 300}),
        _inventoryService.uomConversionsAll(
          filters: const {'per_page': 500, 'sort_by': 'from_uom_id'},
        ),
        _service.orders(filters: const {'per_page': 300}),
      ]);
      rows =
          (responses[0] as PaginatedResponse<JobworkReceiptModel>).data ??
              const <JobworkReceiptModel>[];
      companies = ((responses[1] as PaginatedResponse<CompanyModel>).data ??
              const <CompanyModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      branches = ((responses[2] as PaginatedResponse<BranchModel>).data ??
              const <BranchModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      locations =
          ((responses[3] as PaginatedResponse<BusinessLocationModel>).data ??
                  const <BusinessLocationModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      financialYears =
          ((responses[4] as PaginatedResponse<FinancialYearModel>).data ??
                  const <FinancialYearModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      documentSeries =
          ((responses[5] as PaginatedResponse<DocumentSeriesModel>).data ??
                  const <DocumentSeriesModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      parties = ((responses[6] as PaginatedResponse<PartyModel>).data ??
              const <PartyModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      partyTypes =
          (responses[7] as PaginatedResponse<PartyTypeModel>).data ??
              const <PartyTypeModel>[];
      warehouses = ((responses[8] as PaginatedResponse<WarehouseModel>).data ??
              const <WarehouseModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      items = ((responses[9] as PaginatedResponse<ItemModel>).data ??
              const <ItemModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      uoms = ((responses[10] as PaginatedResponse<UomModel>).data ??
              const <UomModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      uomConversions =
          ((responses[11] as PaginatedResponse<UomConversionModel>).data ??
                  const <UomConversionModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      jobworkOrders =
          (responses[12] as PaginatedResponse<JobworkOrderModel>).data ??
              const <JobworkOrderModel>[];

      loading = false;

      if (selectId != null) {
        final existing = rows.cast<JobworkReceiptModel?>().firstWhere(
          (x) => x?.id == selectId,
          orElse: () => null,
        );
        if (existing != null) {
          await select(existing);
          return;
        }
      }
      resetDraft();
      notifyListeners();
    } catch (e) {
      pageError = e.toString();
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadOrderDetail(int? orderId) async {
    selectedOrderDetail = null;
    if (orderId == null) {
      notifyListeners();
      return;
    }
    try {
      final response = await _service.order(orderId);
      selectedOrderDetail = response.data;
      if (supplierPartyId == null &&
          selectedOrderDetail?.supplierPartyId != null) {
        supplierPartyId = selectedOrderDetail!.supplierPartyId;
      }
      if (warehouseId == null &&
          selectedOrderDetail?.receiptWarehouseId != null) {
        warehouseId = selectedOrderDetail!.receiptWarehouseId;
      }
    } catch (_) {
      selectedOrderDetail = null;
    }
    notifyListeners();
  }

  void resetDraft() {
    selected = null;
    selectedOrderDetail = null;
    formError = null;
    _disposeLines();
    companyId ??= companies.isNotEmpty ? companies.first.id : null;
    branchId = branchOptions.isNotEmpty ? branchOptions.first.id : null;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    financialYearId ??=
        financialYears.isNotEmpty ? financialYears.first.id : null;
    documentSeriesId = seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    jobworkOrderId = null;
    supplierPartyId = null;
    warehouseId =
        warehouseOptions.isNotEmpty ? warehouseOptions.first.id : null;
    transporterPartyId = null;
    receiptMode = 'processed_receipt';
    receiptNoController.clear();
    receiptDateController.text =
        DateTime.now().toIso8601String().split('T').first;
    supplierDcNoController.clear();
    supplierDcDateController.clear();
    vehicleNoController.clear();
    lrNoController.clear();
    lrDateController.clear();
    remarksController.clear();
    isActive = true;
    lineDrafts = <JobworkReceiptLineDraft>[JobworkReceiptLineDraft()];
    notifyListeners();
  }

  Future<void> select(JobworkReceiptModel row) async {
    final id = row.id;
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _service.receipt(id);
      final doc = response.data ?? row;
      companyId = doc.companyId;
      branchId = doc.branchId;
      locationId = doc.locationId;
      financialYearId = doc.financialYearId;
      documentSeriesId = doc.documentSeriesId;
      jobworkOrderId = doc.jobworkOrderId;
      supplierPartyId = doc.supplierPartyId;
      warehouseId = doc.warehouseId;
      transporterPartyId = doc.transporterPartyId;
      receiptMode = doc.receiptMode;
      receiptNoController.text = doc.receiptNo;
      receiptDateController.text =
          displayDate(doc.receiptDate.isNotEmpty ? doc.receiptDate : null);
      supplierDcNoController.text = doc.supplierDcNo ?? '';
      supplierDcDateController.text = displayDate(doc.supplierDcDate);
      vehicleNoController.text = doc.vehicleNo ?? '';
      lrNoController.text = doc.lrNo ?? '';
      lrDateController.text = displayDate(doc.lrDate);
      remarksController.text = doc.remarks ?? '';
      isActive = doc.isActive;
      await _loadOrderDetail(jobworkOrderId);
      _disposeLines();
      lineDrafts = doc.lines.isEmpty
          ? <JobworkReceiptLineDraft>[JobworkReceiptLineDraft()]
          : doc.lines.map(JobworkReceiptLineDraft.fromModel).toList();
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      notifyListeners();
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
    warehouseId =
        warehouseOptions.isNotEmpty ? warehouseOptions.first.id : null;
    notifyListeners();
  }

  void onBranchChanged(int? value) {
    if (isLocked) {
      return;
    }
    branchId = value;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    warehouseId =
        warehouseOptions.isNotEmpty ? warehouseOptions.first.id : null;
    notifyListeners();
  }

  void onLocationChanged(int? value) {
    if (isLocked) {
      return;
    }
    locationId = value;
    warehouseId =
        warehouseOptions.isNotEmpty ? warehouseOptions.first.id : null;
    notifyListeners();
  }

  void setFinancialYearId(int? value) {
    if (isLocked) {
      return;
    }
    financialYearId = value;
    documentSeriesId = seriesOptions.isNotEmpty ? seriesOptions.first.id : null;
    notifyListeners();
  }

  Future<void> setJobworkOrderId(int? value) async {
    if (isLocked) {
      return;
    }
    jobworkOrderId = value;
    await _loadOrderDetail(value);
    notifyListeners();
  }

  void setSupplierPartyId(int? value) {
    if (isLocked) {
      return;
    }
    supplierPartyId = value;
    notifyListeners();
  }

  void setWarehouseId(int? value) {
    if (isLocked) {
      return;
    }
    warehouseId = value;
    notifyListeners();
  }

  void setTransporterPartyId(int? value) {
    if (isLocked) {
      return;
    }
    transporterPartyId = value;
    notifyListeners();
  }

  void setDocumentSeriesId(int? value) {
    if (isLocked) {
      return;
    }
    documentSeriesId = value;
    notifyListeners();
  }

  void setReceiptMode(String value) {
    if (isLocked) {
      return;
    }
    receiptMode = value;
    notifyListeners();
  }

  List<UomModel> uomOptionsForItem(int? itemId) {
    final item = items.cast<ItemModel?>().firstWhere(
      (x) => x?.id == itemId,
      orElse: () => null,
    );
    return allowedUomsForItem(item, uoms, uomConversions);
  }

  void addLine() {
    if (!canEditLines) {
      return;
    }
    lineDrafts = List<JobworkReceiptLineDraft>.from(lineDrafts)
      ..add(JobworkReceiptLineDraft(warehouseId: warehouseId));
    notifyListeners();
  }

  void removeLine(int index) {
    if (!canEditLines || lineDrafts.length <= 1) {
      return;
    }
    final copy = List<JobworkReceiptLineDraft>.from(lineDrafts);
    copy[index].dispose();
    copy.removeAt(index);
    lineDrafts = copy;
    notifyListeners();
  }

  void setLineItemId(int index, int? value) {
    if (!canEditLines) {
      return;
    }
    final line = lineDrafts[index];
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
    notifyListeners();
  }

  void setLineUomId(int index, int? value) {
    if (!canEditLines) {
      return;
    }
    lineDrafts[index].uomId = value;
    notifyListeners();
  }

  void setLineWarehouseId(int index, int? value) {
    if (!canEditLines) {
      return;
    }
    lineDrafts[index].warehouseId = value;
    notifyListeners();
  }

  void setOutputTypeLine(int index, String value) {
    if (!canEditLines) {
      return;
    }
    lineDrafts[index].outputType = value;
    notifyListeners();
  }

  void applyOutputLink(int index, int? outputLineId) {
    if (!canEditLines) {
      return;
    }
    final line = lineDrafts[index];
    line.jobworkOrderOutputId = outputLineId;
    if (outputLineId == null) {
      notifyListeners();
      return;
    }
    final outs = orderOutputOptions;
    final o = outs.cast<JobworkOrderOutputModel?>().firstWhere(
      (x) => x?.id == outputLineId,
      orElse: () => null,
    );
    if (o != null) {
      line.itemId = o.itemId;
      line.uomId = o.uomId;
      line.outputType = o.outputType;
      line.receiptQtyController.text = o.plannedQty > 0
          ? o.plannedQty.toString()
          : '1';
      line.acceptedQtyController.text = line.receiptQtyController.text;
      setLineItemId(index, o.itemId);
    }
    notifyListeners();
  }

  String? _validate() {
    if (companyId == null ||
        branchId == null ||
        locationId == null ||
        financialYearId == null) {
      return 'Company, branch, location and financial year are required.';
    }
    if (jobworkOrderId == null ||
        supplierPartyId == null ||
        warehouseId == null) {
      return 'Jobwork order, supplier and warehouse are required.';
    }
    if (receiptDateController.text.trim().isEmpty) {
      return 'Receipt date is required.';
    }
    if (documentSeriesId == null && receiptNoController.text.trim().isEmpty) {
      return 'Document series is required when receipt number is empty.';
    }
    if (canEditLines) {
      for (final d in lineDrafts) {
        if (d.itemId == null ||
            d.uomId == null ||
            (double.tryParse(d.receiptQtyController.text.trim()) ?? 0) <= 0) {
          return 'Each line needs item, UOM and receipt quantity.';
        }
      }
    }
    return null;
  }

  JobworkReceiptModel _buildDocument() {
    final lines = lineDrafts
        .map((d) => d.toModel(headerWarehouseId: warehouseId))
        .toList();
    return JobworkReceiptModel(
      companyId: companyId,
      branchId: branchId,
      locationId: locationId,
      financialYearId: financialYearId,
      documentSeriesId: documentSeriesId,
      receiptNo: receiptNoController.text.trim(),
      receiptDate: receiptDateController.text.trim(),
      jobworkOrderId: jobworkOrderId,
      supplierPartyId: supplierPartyId,
      warehouseId: warehouseId,
      supplierDcNo: nullIfEmpty(supplierDcNoController.text),
      supplierDcDate: nullIfEmpty(supplierDcDateController.text),
      vehicleNo: nullIfEmpty(vehicleNoController.text),
      transporterPartyId: transporterPartyId,
      lrNo: nullIfEmpty(lrNoController.text),
      lrDate: nullIfEmpty(lrDateController.text),
      receiptMode: receiptMode,
      remarks: nullIfEmpty(remarksController.text),
      isActive: isActive,
      lines: lines,
    );
  }

  Future<void> save() async {
    final err = _validate();
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
      final doc = _buildDocument();
      if (selected == null) {
        final response = await _service.createReceipt(doc);
        actionMessage = response.message;
        await load(selectId: response.data?.id);
      } else {
        final response = await _service.updateReceipt(selected!.id!, doc);
        actionMessage = response.message;
        await load(selectId: selected!.id);
      }
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> postReceiptDoc() async {
    final id = selected?.id;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.postReceipt(id);
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> cancelReceiptDoc() async {
    final id = selected?.id;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.cancelReceipt(id);
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteReceipt() async {
    final id = selected?.id;
    if (id == null) {
      return;
    }
    try {
      await _service.deleteReceipt(id);
      actionMessage = 'Receipt deleted.';
      await load();
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    receiptNoController.dispose();
    receiptDateController.dispose();
    supplierDcNoController.dispose();
    supplierDcDateController.dispose();
    vehicleNoController.dispose();
    lrNoController.dispose();
    lrDateController.dispose();
    remarksController.dispose();
    _disposeLines();
    super.dispose();
  }
}
