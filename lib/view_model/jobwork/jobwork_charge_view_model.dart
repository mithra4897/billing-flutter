import 'package:billing/screen.dart';
import 'package:billing/view/purchase/purchase_support.dart';

class JobworkChargeLineDraft {
  JobworkChargeLineDraft({
    this.itemId,
    this.outputItemId,
    String? serviceDescription,
    String? qty,
    String? rate,
    String? amount,
    String? remarks,
  }) : serviceDescriptionController = TextEditingController(
         text: serviceDescription ?? '',
       ),
       qtyController = TextEditingController(text: qty ?? '1'),
       rateController = TextEditingController(text: rate ?? '0'),
       amountController = TextEditingController(text: amount ?? '0'),
       remarksController = TextEditingController(text: remarks ?? '');

  factory JobworkChargeLineDraft.fromModel(JobworkChargeLineModel m) {
    return JobworkChargeLineDraft(
      itemId: m.itemId,
      outputItemId: m.outputItemId,
      serviceDescription: m.serviceDescription,
      qty: m.qty.toString(),
      rate: m.rate.toString(),
      amount: m.amount.toString(),
      remarks: m.remarks,
    );
  }

  int? itemId;
  int? outputItemId;

  final TextEditingController serviceDescriptionController;
  final TextEditingController qtyController;
  final TextEditingController rateController;
  final TextEditingController amountController;
  final TextEditingController remarksController;

  JobworkChargeLineModel toModel() {
    final q = double.tryParse(qtyController.text.trim()) ?? 0;
    final r = double.tryParse(rateController.text.trim()) ?? 0;
    var amt = double.tryParse(amountController.text.trim());
    if (amt == null || amt == 0) {
      amt = (q * r);
    }
    return JobworkChargeLineModel(
      serviceDescription: serviceDescriptionController.text.trim(),
      itemId: itemId,
      outputItemId: outputItemId,
      qty: q,
      rate: r,
      amount: amt,
      taxPercent: 0,
      cgstAmount: 0,
      sgstAmount: 0,
      igstAmount: 0,
      cessAmount: 0,
      lineTotal: amt,
      remarks: nullIfEmpty(remarksController.text),
    );
  }

  void dispose() {
    serviceDescriptionController.dispose();
    qtyController.dispose();
    rateController.dispose();
    amountController.dispose();
    remarksController.dispose();
  }
}

class JobworkChargeViewModel extends ChangeNotifier {
  JobworkChargeViewModel() {
    searchController.addListener(notifyListeners);
    WorkingContextService.version.addListener(_handleWorkingContextChanged);
  }

  final JobworkService _service = JobworkService();
  final MasterService _masterService = MasterService();
  final PartiesService _partiesService = PartiesService();
  final InventoryService _inventoryService = InventoryService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController chargeNoController = TextEditingController();
  final TextEditingController chargeDateController = TextEditingController();
  final TextEditingController purchaseInvoiceIdController =
      TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<JobworkChargeModel> rows = const <JobworkChargeModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<BranchModel> branches = const <BranchModel>[];
  List<BusinessLocationModel> locations = const <BusinessLocationModel>[];
  List<FinancialYearModel> financialYears = const <FinancialYearModel>[];
  List<DocumentSeriesModel> documentSeries = const <DocumentSeriesModel>[];
  List<PartyModel> parties = const <PartyModel>[];
  List<PartyTypeModel> partyTypes = const <PartyTypeModel>[];
  List<ItemModel> items = const <ItemModel>[];
  List<JobworkOrderModel> jobworkOrders = const <JobworkOrderModel>[];

  JobworkChargeModel? selected;
  JobworkOrderModel? selectedOrderDetail;

  int? companyId;
  int? branchId;
  int? locationId;
  int? financialYearId;
  int? documentSeriesId;
  int? jobworkOrderId;
  int? supplierPartyId;
  bool isActive = true;

  List<JobworkChargeLineDraft> lineDrafts = <JobworkChargeLineDraft>[];

  void _handleWorkingContextChanged() {
    load(selectId: selected?.id);
  }

  String get chargeStatus => selected?.chargeStatus ?? 'draft';

  bool get isLocked => chargeStatus == 'posted' || chargeStatus == 'cancelled';

  bool get canEditLines => chargeStatus == 'draft';

  bool get canPost => selected != null && chargeStatus == 'draft';

  bool get canCancelCharge => selected != null && chargeStatus == 'draft';

  bool get canDelete => selected != null && chargeStatus == 'draft';

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
      return okCompany && fyOk && dt == 'JOBWORK_CHARGE';
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

  List<JobworkChargeModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows
        .where((row) {
          if (q.isEmpty) {
            return true;
          }
          return [
            row.chargeNo,
            row.chargeStatus,
            row.supplierLabel,
            row.jobworkOrderNoLabel,
            row.totalAmount.toString(),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  String? consumeActionMessage() {
    final message = actionMessage;
    actionMessage = null;
    return message;
  }

  void _disposeLines() {
    for (final d in lineDrafts) {
      d.dispose();
    }
    lineDrafts = <JobworkChargeLineDraft>[];
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    notifyListeners();
    try {
      final responses = await Future.wait<dynamic>([
        _service.charges(
          filters: const {'per_page': 200, 'sort_by': 'charge_date'},
        ),
        _masterService.companies(filters: const {'per_page': 200}),
        _masterService.branches(filters: const {'per_page': 300}),
        _masterService.businessLocations(filters: const {'per_page': 300}),
        _masterService.financialYears(filters: const {'per_page': 100}),
        _masterService.documentSeries(filters: const {'per_page': 300}),
        _partiesService.parties(filters: const {'per_page': 500}),
        _partiesService.partyTypes(filters: const {'per_page': 100}),
        _inventoryService.items(filters: const {'per_page': 500}),
        _service.orders(filters: const {'per_page': 300}),
      ]);
      rows =
          (responses[0] as PaginatedResponse<JobworkChargeModel>).data ??
          const <JobworkChargeModel>[];
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
      items =
          ((responses[8] as PaginatedResponse<ItemModel>).data ??
                  const <ItemModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);
      jobworkOrders =
          (responses[9] as PaginatedResponse<JobworkOrderModel>).data ??
          const <JobworkOrderModel>[];

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
        final existing = rows.cast<JobworkChargeModel?>().firstWhere(
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
    chargeNoController.clear();
    chargeDateController.text = DateTime.now()
        .toIso8601String()
        .split('T')
        .first;
    purchaseInvoiceIdController.clear();
    remarksController.clear();
    isActive = true;
    lineDrafts = <JobworkChargeLineDraft>[JobworkChargeLineDraft()];
    notifyListeners();
  }

  Future<void> select(JobworkChargeModel row) async {
    final id = row.id;
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _service.charge(id);
      final doc = response.data ?? row;
      companyId = doc.companyId;
      branchId = doc.branchId;
      locationId = doc.locationId;
      financialYearId = doc.financialYearId;
      documentSeriesId = doc.documentSeriesId;
      jobworkOrderId = doc.jobworkOrderId;
      supplierPartyId = doc.supplierPartyId;
      chargeNoController.text = doc.chargeNo;
      chargeDateController.text = displayDate(
        doc.chargeDate.isNotEmpty ? doc.chargeDate : null,
      );
      purchaseInvoiceIdController.text =
          doc.purchaseInvoiceId?.toString() ?? '';
      remarksController.text = doc.remarks ?? '';
      isActive = doc.isActive;
      await _loadOrderDetail(jobworkOrderId);
      _disposeLines();
      lineDrafts = doc.lines.isEmpty
          ? <JobworkChargeLineDraft>[JobworkChargeLineDraft()]
          : doc.lines.map(JobworkChargeLineDraft.fromModel).toList();
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
    notifyListeners();
  }

  void onBranchChanged(int? value) {
    if (isLocked) {
      return;
    }
    branchId = value;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    notifyListeners();
  }

  void onLocationChanged(int? value) {
    if (isLocked) {
      return;
    }
    locationId = value;
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

  void setDocumentSeriesId(int? value) {
    if (isLocked) {
      return;
    }
    documentSeriesId = value;
    notifyListeners();
  }

  void addLine() {
    if (!canEditLines) {
      return;
    }
    lineDrafts = List<JobworkChargeLineDraft>.from(lineDrafts)
      ..add(JobworkChargeLineDraft());
    notifyListeners();
  }

  void removeLine(int index) {
    if (!canEditLines || lineDrafts.length <= 1) {
      return;
    }
    final copy = List<JobworkChargeLineDraft>.from(lineDrafts);
    copy[index].dispose();
    copy.removeAt(index);
    lineDrafts = copy;
    notifyListeners();
  }

  void setLineItemId(int index, int? value) {
    if (!canEditLines) {
      return;
    }
    lineDrafts[index].itemId = value;
    notifyListeners();
  }

  String? _validate() {
    if (companyId == null ||
        branchId == null ||
        locationId == null ||
        financialYearId == null) {
      return 'Company, branch, location and financial year are required.';
    }
    if (jobworkOrderId == null || supplierPartyId == null) {
      return 'Jobwork order and supplier are required.';
    }
    if (chargeDateController.text.trim().isEmpty) {
      return 'Charge date is required.';
    }
    if (documentSeriesId == null && chargeNoController.text.trim().isEmpty) {
      return 'Document series is required when charge number is empty.';
    }
    if (canEditLines) {
      for (final d in lineDrafts) {
        if (d.serviceDescriptionController.text.trim().isEmpty) {
          return 'Each line needs a service description.';
        }
        final q = double.tryParse(d.qtyController.text.trim()) ?? 0;
        if (q <= 0) {
          return 'Each line needs a positive quantity.';
        }
      }
    }
    return null;
  }

  JobworkChargeModel _buildDocument() {
    final lines = lineDrafts.map((d) => d.toModel()).toList();
    final pi = int.tryParse(purchaseInvoiceIdController.text.trim());
    return JobworkChargeModel(
      companyId: companyId,
      branchId: branchId,
      locationId: locationId,
      financialYearId: financialYearId,
      documentSeriesId: documentSeriesId,
      chargeNo: chargeNoController.text.trim(),
      chargeDate: chargeDateController.text.trim(),
      jobworkOrderId: jobworkOrderId,
      supplierPartyId: supplierPartyId,
      purchaseInvoiceId: pi,
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
        final response = await _service.createCharge(doc);
        actionMessage = response.message;
        await load(selectId: response.data?.id);
      } else {
        final response = await _service.updateCharge(selected!.id!, doc);
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

  Future<void> postChargeDoc() async {
    final id = selected?.id;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.postCharge(id);
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> cancelChargeDoc() async {
    final id = selected?.id;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.cancelCharge(id);
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteCharge() async {
    final id = selected?.id;
    if (id == null) {
      return;
    }
    try {
      await _service.deleteCharge(id);
      actionMessage = 'Charge deleted.';
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
    chargeNoController.dispose();
    chargeDateController.dispose();
    purchaseInvoiceIdController.dispose();
    remarksController.dispose();
    _disposeLines();
    super.dispose();
  }
}
