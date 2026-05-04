import 'package:billing/screen.dart';

class QcPlanLineDraft {
  QcPlanLineDraft({
    String? checkpointName,
    this.checkpointType = 'visual',
    String? specification,
    String? toleranceMin,
    String? toleranceMax,
    String? expectedText,
    String? unit,
    this.isCritical = false,
    this.isMandatory = true,
    String? sequenceNo,
    String? remarks,
  }) : checkpointNameController =
           TextEditingController(text: checkpointName ?? ''),
       specificationController =
           TextEditingController(text: specification ?? ''),
       toleranceMinController =
           TextEditingController(text: toleranceMin ?? ''),
       toleranceMaxController =
           TextEditingController(text: toleranceMax ?? ''),
       expectedTextController =
           TextEditingController(text: expectedText ?? ''),
       unitController = TextEditingController(text: unit ?? ''),
       sequenceNoController = TextEditingController(text: sequenceNo ?? '1'),
       remarksController = TextEditingController(text: remarks ?? '');

  factory QcPlanLineDraft.fromModel(QcPlanLineModel m) {
    return QcPlanLineDraft(
      checkpointName: m.checkpointName,
      checkpointType: m.checkpointType,
      specification: m.specification,
      toleranceMin: m.toleranceMin?.toString(),
      toleranceMax: m.toleranceMax?.toString(),
      expectedText: m.expectedText,
      unit: m.unit,
      isCritical: m.isCritical,
      isMandatory: m.isMandatory,
      sequenceNo: m.sequenceNo.toString(),
      remarks: m.remarks,
    );
  }

  final TextEditingController checkpointNameController;
  String checkpointType;
  final TextEditingController specificationController;
  final TextEditingController toleranceMinController;
  final TextEditingController toleranceMaxController;
  final TextEditingController expectedTextController;
  final TextEditingController unitController;
  bool isCritical;
  bool isMandatory;
  final TextEditingController sequenceNoController;
  final TextEditingController remarksController;

  QcPlanLineModel toModel() {
    final seq = int.tryParse(sequenceNoController.text.trim()) ?? 1;
    final tMin = double.tryParse(toleranceMinController.text.trim());
    final tMax = double.tryParse(toleranceMaxController.text.trim());
    return QcPlanLineModel(
      checkpointName: checkpointNameController.text.trim(),
      checkpointType: checkpointType,
      specification: nullIfEmpty(specificationController.text),
      toleranceMin: tMin,
      toleranceMax: tMax,
      expectedText: nullIfEmpty(expectedTextController.text),
      unit: nullIfEmpty(unitController.text),
      isCritical: isCritical,
      isMandatory: isMandatory,
      sequenceNo: seq,
      remarks: nullIfEmpty(remarksController.text),
    );
  }

  void dispose() {
    checkpointNameController.dispose();
    specificationController.dispose();
    toleranceMinController.dispose();
    toleranceMaxController.dispose();
    expectedTextController.dispose();
    unitController.dispose();
    sequenceNoController.dispose();
    remarksController.dispose();
  }
}

class QcPlanViewModel extends ChangeNotifier {
  QcPlanViewModel() {
    searchController.addListener(notifyListeners);
  }

  final QualityService _service = QualityService();
  final MasterService _masterService = MasterService();
  final InventoryService _inventoryService = InventoryService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController planCodeController = TextEditingController();
  final TextEditingController planNameController = TextEditingController();
  final TextEditingController minPassPercentController =
      TextEditingController();
  final TextEditingController effectiveFromController = TextEditingController();
  final TextEditingController effectiveToController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController samplingMethodController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<QcPlanModel> rows = const <QcPlanModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<BranchModel> branches = const <BranchModel>[];
  List<BusinessLocationModel> locations = const <BusinessLocationModel>[];
  List<ItemModel> items = const <ItemModel>[];
  List<ItemCategoryModel> itemCategories = const <ItemCategoryModel>[];

  QcPlanModel? selected;

  int? companyId;
  int? branchId;
  int? locationId;
  int? itemId;
  int? itemCategoryId;
  String qcScope = 'all';
  String acceptanceBasis = 'all_pass';
  bool isDefault = false;
  bool isActive = true;

  List<QcPlanLineDraft> lineDrafts = <QcPlanLineDraft>[];

  String get approvalStatus => selected?.approvalStatus ?? 'draft';

  bool get canEdit =>
      selected == null || approvalStatus == 'draft';

  bool get canApprove =>
      selected != null &&
      approvalStatus != 'approved' &&
      approvalStatus != 'obsolete';

  bool get canDeactivate =>
      selected != null &&
      approvalStatus != 'inactive' &&
      approvalStatus != 'obsolete';

  bool get canObsolete => selected != null && approvalStatus != 'obsolete';

  bool get canDelete => selected != null && approvalStatus != 'approved';

  bool get canEditLines => canEdit;

  List<BranchModel> get branchOptions => branchesForCompany(branches, companyId);
  List<BusinessLocationModel> get locationOptions =>
      locationsForBranch(locations, branchId);

  List<ItemModel> get itemOptions => items.where((i) {
    if (i.id == null) {
      return false;
    }
    return companyId == null || i.companyId == companyId;
  }).toList(growable: false);

  List<ItemCategoryModel> get categoryOptions =>
      itemCategories.where((c) {
        if (c.id == null) {
          return false;
        }
        if (companyId == null) {
          return true;
        }
        final raw = c.raw;
        final cid = raw != null
            ? int.tryParse(raw['company_id']?.toString() ?? '')
            : null;
        return cid == null || cid == companyId;
      }).toList(growable: false);

  List<QcPlanModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows.where((row) {
      if (q.isEmpty) {
        return true;
      }
      return [
        row.planCode,
        row.planName,
        row.approvalStatus,
        row.qcScope,
        row.itemLabel,
        row.categoryLabel,
      ].join(' ').toLowerCase().contains(q);
    }).toList(growable: false);
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
    lineDrafts = <QcPlanLineDraft>[];
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    notifyListeners();
    try {
      final responses = await Future.wait<dynamic>([
        _service.qcPlans(filters: const {'per_page': 200}),
        _masterService.companies(filters: const {'per_page': 200}),
        _masterService.branches(filters: const {'per_page': 300}),
        _masterService.businessLocations(filters: const {'per_page': 300}),
        _inventoryService.items(filters: const {'per_page': 800}),
        _inventoryService.itemCategories(filters: const {'per_page': 500}),
      ]);
      rows =
          (responses[0] as PaginatedResponse<QcPlanModel>).data ??
              const <QcPlanModel>[];
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
      items = ((responses[4] as PaginatedResponse<ItemModel>).data ??
              const <ItemModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      itemCategories =
          ((responses[5] as PaginatedResponse<ItemCategoryModel>).data ??
                  const <ItemCategoryModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);

      loading = false;

      if (selectId != null) {
        final existing = rows.cast<QcPlanModel?>().firstWhere(
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

  void resetDraft() {
    selected = null;
    formError = null;
    _disposeLines();
    companyId ??= companies.isNotEmpty ? companies.first.id : null;
    branchId = branchOptions.isNotEmpty ? branchOptions.first.id : null;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    planCodeController.clear();
    planNameController.clear();
    itemId = null;
    itemCategoryId = null;
    qcScope = 'all';
    samplingMethodController.clear();
    acceptanceBasis = 'all_pass';
    minPassPercentController.clear();
    effectiveFromController.clear();
    effectiveToController.clear();
    notesController.clear();
    isDefault = false;
    isActive = true;
    lineDrafts = <QcPlanLineDraft>[QcPlanLineDraft()];
    notifyListeners();
  }

  Future<void> select(QcPlanModel row) async {
    final id = row.id;
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _service.qcPlan(id);
      final doc = response.data ?? row;
      companyId = doc.companyId;
      branchId = doc.branchId;
      locationId = doc.locationId;
      planCodeController.text = doc.planCode;
      planNameController.text = doc.planName;
      itemId = doc.itemId;
      itemCategoryId = doc.itemCategoryId;
      qcScope = doc.qcScope;
      samplingMethodController.text = doc.samplingMethod ?? '';
      acceptanceBasis = doc.acceptanceBasis;
      minPassPercentController.text = doc.minPassPercent != null
          ? doc.minPassPercent.toString()
          : '';
      effectiveFromController.text = doc.effectiveFrom ?? '';
      effectiveToController.text = doc.effectiveTo ?? '';
      notesController.text = doc.notes ?? '';
      isDefault = doc.isDefault;
      isActive = doc.isActive;
      _disposeLines();
      lineDrafts = doc.lines.isEmpty
          ? <QcPlanLineDraft>[QcPlanLineDraft()]
          : doc.lines.map(QcPlanLineDraft.fromModel).toList();
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      notifyListeners();
    }
  }

  void onCompanyChanged(int? value) {
    if (!canEdit) {
      return;
    }
    companyId = value;
    branchId = branchOptions.isNotEmpty ? branchOptions.first.id : null;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    itemId = null;
    itemCategoryId = null;
    notifyListeners();
  }

  void onBranchChanged(int? value) {
    if (!canEdit) {
      return;
    }
    branchId = value;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    notifyListeners();
  }

  void onLocationChanged(int? value) {
    if (!canEdit) {
      return;
    }
    locationId = value;
    notifyListeners();
  }

  void setItemId(int? value) {
    if (!canEdit) {
      return;
    }
    itemId = value;
    notifyListeners();
  }

  void setItemCategoryId(int? value) {
    if (!canEdit) {
      return;
    }
    itemCategoryId = value;
    notifyListeners();
  }

  void setQcScope(String value) {
    if (!canEdit) {
      return;
    }
    qcScope = value;
    notifyListeners();
  }

  void setAcceptanceBasis(String value) {
    if (!canEdit) {
      return;
    }
    acceptanceBasis = value;
    notifyListeners();
  }

  void setIsDefault(bool value) {
    if (!canEdit) {
      return;
    }
    isDefault = value;
    notifyListeners();
  }

  void setIsActive(bool value) {
    if (!canEdit) {
      return;
    }
    isActive = value;
    notifyListeners();
  }

  void setCheckpointType(int index, String value) {
    if (!canEditLines) {
      return;
    }
    lineDrafts[index].checkpointType = value;
    notifyListeners();
  }

  void setLineCritical(int index, bool value) {
    if (!canEditLines) {
      return;
    }
    lineDrafts[index].isCritical = value;
    notifyListeners();
  }

  void setLineMandatory(int index, bool value) {
    if (!canEditLines) {
      return;
    }
    lineDrafts[index].isMandatory = value;
    notifyListeners();
  }

  void addLine() {
    if (!canEditLines) {
      return;
    }
    lineDrafts = List<QcPlanLineDraft>.from(lineDrafts)
      ..add(QcPlanLineDraft());
    notifyListeners();
  }

  void removeLine(int index) {
    if (!canEditLines || lineDrafts.length <= 1) {
      return;
    }
    final copy = List<QcPlanLineDraft>.from(lineDrafts);
    copy[index].dispose();
    copy.removeAt(index);
    lineDrafts = copy;
    notifyListeners();
  }

  String? _validate() {
    if (companyId == null) {
      return 'Company is required.';
    }
    if (planCodeController.text.trim().isEmpty ||
        planNameController.text.trim().isEmpty) {
      return 'Plan code and plan name are required.';
    }
    if (qcScope.trim().isEmpty) {
      return 'QC scope is required.';
    }
    if (acceptanceBasis == 'min_pass_percent') {
      final p = double.tryParse(minPassPercentController.text.trim()) ?? 0;
      if (p <= 0 || p > 100) {
        return 'Minimum pass percent must be between 1 and 100.';
      }
    }
    if (canEditLines) {
      for (final d in lineDrafts) {
        if (d.checkpointNameController.text.trim().isEmpty) {
          return 'Each checkpoint needs a name.';
        }
        final tMin = double.tryParse(d.toleranceMinController.text.trim());
        final tMax = double.tryParse(d.toleranceMaxController.text.trim());
        if (tMin != null &&
            tMax != null &&
            tMin > tMax) {
          return 'Tolerance min cannot exceed tolerance max.';
        }
      }
    }
    return null;
  }

  QcPlanModel _buildDocument() {
    final lines = lineDrafts.map((d) => d.toModel()).toList();
    final mp = acceptanceBasis == 'min_pass_percent'
        ? double.tryParse(minPassPercentController.text.trim())
        : null;
    return QcPlanModel(
      companyId: companyId,
      branchId: branchId,
      locationId: locationId,
      planCode: planCodeController.text.trim(),
      planName: planNameController.text.trim(),
      itemId: itemId,
      itemCategoryId: itemCategoryId,
      qcScope: qcScope,
      samplingMethod: nullIfEmpty(samplingMethodController.text),
      acceptanceBasis: acceptanceBasis,
      minPassPercent: mp,
      approvalStatus: approvalStatus,
      effectiveFrom: nullIfEmpty(effectiveFromController.text),
      effectiveTo: nullIfEmpty(effectiveToController.text),
      notes: nullIfEmpty(notesController.text),
      isDefault: isDefault,
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
        final response = await _service.createQcPlan(doc);
        actionMessage = response.message;
        await load(selectId: response.data?.id);
      } else {
        final response = await _service.updateQcPlan(selected!.id!, doc);
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

  Future<void> approvePlan() async {
    final id = selected?.id;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.approveQcPlan(id);
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> deactivatePlan() async {
    final id = selected?.id;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.deactivateQcPlan(id);
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> obsoletePlan() async {
    final id = selected?.id;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.obsoleteQcPlan(id);
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> deletePlan() async {
    final id = selected?.id;
    if (id == null) {
      return;
    }
    try {
      await _service.deleteQcPlan(id);
      actionMessage = 'QC plan deleted.';
      await load();
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    planCodeController.dispose();
    planNameController.dispose();
    minPassPercentController.dispose();
    effectiveFromController.dispose();
    effectiveToController.dispose();
    notesController.dispose();
    samplingMethodController.dispose();
    _disposeLines();
    super.dispose();
  }
}
