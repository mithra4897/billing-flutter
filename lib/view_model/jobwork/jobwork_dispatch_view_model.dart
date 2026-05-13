import 'package:billing/screen.dart';
import 'package:billing/view/purchase/purchase_support.dart';

class JobworkDispatchLineDraft {
  JobworkDispatchLineDraft({
    this.jobworkOrderMaterialId,
    this.itemId,
    this.uomId,
    this.warehouseId,
    String? qty,
    String? unitCost,
    String? remarks,
  }) : qtyController = TextEditingController(text: qty ?? '1'),
       unitCostController = TextEditingController(text: unitCost ?? '0'),
       remarksController = TextEditingController(text: remarks ?? '');

  factory JobworkDispatchLineDraft.fromModel(JobworkDispatchLineModel m) {
    return JobworkDispatchLineDraft(
      jobworkOrderMaterialId: m.jobworkOrderMaterialId,
      itemId: m.itemId,
      uomId: m.uomId,
      warehouseId: m.warehouseId,
      qty: m.dispatchQty.toString(),
      unitCost: m.unitCost.toString(),
      remarks: m.remarks,
    );
  }

  int? jobworkOrderMaterialId;
  int? itemId;
  int? uomId;
  int? warehouseId;

  final TextEditingController qtyController;
  final TextEditingController unitCostController;
  final TextEditingController remarksController;

  JobworkDispatchLineModel toModel({required int? headerWarehouseId}) {
    final qty = double.tryParse(qtyController.text.trim()) ?? 0;
    final uc = double.tryParse(unitCostController.text.trim()) ?? 0;
    final tc = (qty * uc).toStringAsFixed(2);
    return JobworkDispatchLineModel(
      jobworkOrderMaterialId: jobworkOrderMaterialId,
      itemId: itemId,
      uomId: uomId,
      warehouseId: warehouseId ?? headerWarehouseId,
      dispatchQty: qty,
      unitCost: uc,
      totalCost: double.tryParse(tc) ?? 0,
      remarks: nullIfEmpty(remarksController.text),
    );
  }

  void dispose() {
    qtyController.dispose();
    unitCostController.dispose();
    remarksController.dispose();
  }
}

class JobworkDispatchViewModel extends ChangeNotifier {
  JobworkDispatchViewModel() {
    searchController.addListener(notifyListeners);
    WorkingContextService.version.addListener(_handleWorkingContextChanged);
  }

  final JobworkService _service = JobworkService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final InventoryService _inventoryService = InventoryService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController dispatchNoController = TextEditingController();
  final TextEditingController dispatchDateController = TextEditingController();
  final TextEditingController dcNoController = TextEditingController();
  final TextEditingController dcDateController = TextEditingController();
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

  List<JobworkDispatchModel> rows = const <JobworkDispatchModel>[];
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

  JobworkDispatchModel? selected;
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
  bool isActive = true;

  List<JobworkDispatchLineDraft> lineDrafts = <JobworkDispatchLineDraft>[];

  void _handleWorkingContextChanged() {
    load(selectId: selected?.id);
  }

  String get dispatchStatus => selected?.dispatchStatus ?? 'draft';

  bool get isLocked =>
      dispatchStatus == 'posted' || dispatchStatus == 'cancelled';

  bool get canEditLines => dispatchStatus == 'draft';

  bool get canPost => selected != null && dispatchStatus == 'draft';

  bool get canCancelDispatch => selected != null && dispatchStatus == 'draft';

  bool get canDelete => selected != null && dispatchStatus == 'draft';

  List<BranchModel> get branchOptions =>
      branchesForCompany(branches, companyId);
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
      return okCompany && fyOk && dt == 'JOBWORK_DISPATCH';
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

  List<JobworkOrderModel> get jobworkOrderOptions => jobworkOrders
      .where((o) => companyId == null || o.companyId == companyId)
      .toList(growable: false);

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

  List<JobworkDispatchModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows
        .where((row) {
          if (q.isEmpty) {
            return true;
          }
          return [
            row.dispatchNo,
            row.dispatchStatus,
            row.supplierLabel,
            row.jobworkOrderNoLabel,
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  List<JobworkOrderMaterialModel> get orderMaterialOptions =>
      selectedOrderDetail?.materials ?? const <JobworkOrderMaterialModel>[];

  String? consumeActionMessage() {
    final message = actionMessage;
    actionMessage = null;
    return message;
  }

  void _disposeLines() {
    for (final d in lineDrafts) {
      d.dispose();
    }
    lineDrafts = <JobworkDispatchLineDraft>[];
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    notifyListeners();
    try {
      final responses = await Future.wait<dynamic>([
        _service.dispatches(
          filters: const {'per_page': 200, 'sort_by': 'dispatch_date'},
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
          (responses[0] as PaginatedResponse<JobworkDispatchModel>).data ??
          const <JobworkDispatchModel>[];
      companies =
          ((responses[1] as PaginatedResponse<CompanyModel>).data ??
                  const <CompanyModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      branches =
          ((responses[2] as PaginatedResponse<BranchModel>).data ??
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
      parties =
          ((responses[6] as PaginatedResponse<PartyModel>).data ??
                  const <PartyModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      partyTypes =
          (responses[7] as PaginatedResponse<PartyTypeModel>).data ??
          const <PartyTypeModel>[];
      warehouses =
          ((responses[8] as PaginatedResponse<WarehouseModel>).data ??
                  const <WarehouseModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      items =
          ((responses[9] as PaginatedResponse<ItemModel>).data ??
                  const <ItemModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      uoms =
          ((responses[10] as PaginatedResponse<UomModel>).data ??
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
      if (selectId != null) {
        final existing = rows.cast<JobworkDispatchModel?>().firstWhere(
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
          selectedOrderDetail?.issueWarehouseId != null) {
        warehouseId = selectedOrderDetail!.issueWarehouseId;
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
    jobworkOrderId = null;
    supplierPartyId = null;
    warehouseId = warehouseOptions.isNotEmpty
        ? warehouseOptions.first.id
        : null;
    transporterPartyId = null;
    dispatchNoController.clear();
    dispatchDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    dcNoController.clear();
    dcDateController.clear();
    vehicleNoController.clear();
    lrNoController.clear();
    lrDateController.clear();
    remarksController.clear();
    isActive = true;
    lineDrafts = <JobworkDispatchLineDraft>[JobworkDispatchLineDraft()];
    notifyListeners();
  }

  Future<void> select(JobworkDispatchModel row) async {
    final id = row.id;
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _service.dispatch(id);
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
      dispatchNoController.text = doc.dispatchNo;
      dispatchDateController.text = displayDate(
        doc.dispatchDate.isNotEmpty ? doc.dispatchDate : null,
      );
      dcNoController.text = doc.dcNo ?? '';
      dcDateController.text = displayDate(doc.dcDate);
      vehicleNoController.text = doc.vehicleNo ?? '';
      lrNoController.text = doc.lrNo ?? '';
      lrDateController.text = displayDate(doc.lrDate);
      remarksController.text = doc.remarks ?? '';
      isActive = doc.isActive;
      await _loadOrderDetail(jobworkOrderId);
      _disposeLines();
      lineDrafts = doc.lines.isEmpty
          ? <JobworkDispatchLineDraft>[JobworkDispatchLineDraft()]
          : doc.lines.map(JobworkDispatchLineDraft.fromModel).toList();
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
    warehouseId = warehouseOptions.isNotEmpty
        ? warehouseOptions.first.id
        : null;
    notifyListeners();
  }

  void onBranchChanged(int? value) {
    if (isLocked) {
      return;
    }
    branchId = value;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    warehouseId = warehouseOptions.isNotEmpty
        ? warehouseOptions.first.id
        : null;
    notifyListeners();
  }

  void onLocationChanged(int? value) {
    if (isLocked) {
      return;
    }
    locationId = value;
    warehouseId = warehouseOptions.isNotEmpty
        ? warehouseOptions.first.id
        : null;
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
    lineDrafts = List<JobworkDispatchLineDraft>.from(lineDrafts)
      ..add(JobworkDispatchLineDraft(warehouseId: warehouseId));
    notifyListeners();
  }

  void removeLine(int index) {
    if (!canEditLines || lineDrafts.length <= 1) {
      return;
    }
    final copy = List<JobworkDispatchLineDraft>.from(lineDrafts);
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

  void applyMaterialLink(int index, int? materialLineId) {
    if (!canEditLines) {
      return;
    }
    final line = lineDrafts[index];
    line.jobworkOrderMaterialId = materialLineId;
    if (materialLineId == null) {
      notifyListeners();
      return;
    }
    final mats = orderMaterialOptions;
    final m = mats.cast<JobworkOrderMaterialModel?>().firstWhere(
      (x) => x?.id == materialLineId,
      orElse: () => null,
    );
    if (m != null) {
      line.itemId = m.itemId;
      line.uomId = m.uomId;
      line.qtyController.text = m.plannedQty > 0
          ? m.plannedQty.toString()
          : '1';
      setLineItemId(index, m.itemId);
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
    if (jobworkOrderId == null) {
      return 'Jobwork order is required.';
    }
    if (supplierPartyId == null) {
      return 'Supplier is required.';
    }
    if (warehouseId == null) {
      return 'Warehouse is required.';
    }
    if (dispatchDateController.text.trim().isEmpty) {
      return 'Dispatch date is required.';
    }
    if (documentSeriesId == null && dispatchNoController.text.trim().isEmpty) {
      return 'Document series is required when dispatch number is empty.';
    }
    if (canEditLines) {
      for (final d in lineDrafts) {
        if (d.itemId == null ||
            d.uomId == null ||
            (double.tryParse(d.qtyController.text.trim()) ?? 0) <= 0) {
          return 'Each line needs item, UOM and quantity.';
        }
      }
    }
    return null;
  }

  JobworkDispatchModel _buildDocument() {
    final lines = lineDrafts
        .map((d) => d.toModel(headerWarehouseId: warehouseId))
        .toList();
    return JobworkDispatchModel(
      companyId: companyId,
      branchId: branchId,
      locationId: locationId,
      financialYearId: financialYearId,
      documentSeriesId: documentSeriesId,
      dispatchNo: dispatchNoController.text.trim(),
      dispatchDate: dispatchDateController.text.trim(),
      jobworkOrderId: jobworkOrderId,
      supplierPartyId: supplierPartyId,
      warehouseId: warehouseId,
      dcNo: nullIfEmpty(dcNoController.text),
      dcDate: nullIfEmpty(dcDateController.text),
      vehicleNo: nullIfEmpty(vehicleNoController.text),
      transporterPartyId: transporterPartyId,
      lrNo: nullIfEmpty(lrNoController.text),
      lrDate: nullIfEmpty(lrDateController.text),
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
        final response = await _service.createDispatch(doc);
        actionMessage = response.message;
        await load(selectId: response.data?.id);
      } else {
        final response = await _service.updateDispatch(selected!.id!, doc);
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

  Future<void> postDispatch() async {
    final id = selected?.id;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.postDispatch(id);
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> cancelDispatchDoc() async {
    final id = selected?.id;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.cancelDispatch(id);
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteDispatch() async {
    final id = selected?.id;
    if (id == null) {
      return;
    }
    try {
      await _service.deleteDispatch(id);
      actionMessage = 'Dispatch deleted.';
      await load();
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WorkingContextService.version.removeListener(_handleWorkingContextChanged);
    searchController.dispose();
    dispatchNoController.dispose();
    dispatchDateController.dispose();
    dcNoController.dispose();
    dcDateController.dispose();
    vehicleNoController.dispose();
    lrNoController.dispose();
    lrDateController.dispose();
    remarksController.dispose();
    _disposeLines();
    super.dispose();
  }
}
