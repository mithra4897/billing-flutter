import '../../../screen.dart';
import 'manufacturing_module_refresh_controller.dart';

class BomLineDraft {
  BomLineDraft({
    this.itemId,
    this.uomId,
    String? requiredQty,
    String? wastagePercent,
    String? lineType,
    String? remarks,
  }) : requiredQtyController = TextEditingController(text: requiredQty ?? ''),
       wastagePercentController = TextEditingController(
         text: wastagePercent ?? '',
       ),
       lineTypeController = TextEditingController(
         text: lineType ?? 'raw_material',
       ),
       remarksController = TextEditingController(text: remarks ?? '');

  factory BomLineDraft.fromJson(Map<String, dynamic> json) {
    return BomLineDraft(
      itemId: intValue(json, 'item_id'),
      uomId: intValue(json, 'uom_id'),
      requiredQty: stringValue(json, 'required_qty'),
      wastagePercent: stringValue(json, 'wastage_percent'),
      lineType: stringValue(json, 'line_type', 'raw_material'),
      remarks: stringValue(json, 'remarks'),
    );
  }

  int? itemId;
  int? uomId;
  final TextEditingController requiredQtyController;
  final TextEditingController wastagePercentController;
  final TextEditingController lineTypeController;
  final TextEditingController remarksController;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'item_id': itemId,
    'uom_id': uomId,
    'required_qty':
        Validators.parseFlexibleNumber(requiredQtyController.text) ?? 0,
    'wastage_percent':
        Validators.parseFlexibleNumber(wastagePercentController.text) ?? 0,
    'line_type': nullIfEmpty(lineTypeController.text) ?? 'raw_material',
    'remarks': nullIfEmpty(remarksController.text),
  };

  void dispose() {
    requiredQtyController.dispose();
    wastagePercentController.dispose();
    lineTypeController.dispose();
    remarksController.dispose();
  }
}

class BomOperationDraft {
  BomOperationDraft({
    String? operationName,
    String? workCenter,
    String? setupMinutes,
    String? runMinutes,
  }) : operationNameController = TextEditingController(
         text: operationName ?? '',
       ),
       workCenterController = TextEditingController(text: workCenter ?? ''),
       setupMinutesController = TextEditingController(text: setupMinutes ?? ''),
       runMinutesController = TextEditingController(text: runMinutes ?? '');

  factory BomOperationDraft.fromJson(Map<String, dynamic> json) {
    return BomOperationDraft(
      operationName: stringValue(json, 'operation_name'),
      workCenter: stringValue(json, 'work_center'),
      setupMinutes: stringValue(json, 'setup_time_minutes'),
      runMinutes: stringValue(json, 'run_time_minutes'),
    );
  }

  final TextEditingController operationNameController;
  final TextEditingController workCenterController;
  final TextEditingController setupMinutesController;
  final TextEditingController runMinutesController;

  bool get hasMeaningfulData =>
      operationNameController.text.trim().isNotEmpty ||
      workCenterController.text.trim().isNotEmpty ||
      setupMinutesController.text.trim().isNotEmpty ||
      runMinutesController.text.trim().isNotEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'operation_name': nullIfEmpty(operationNameController.text),
    'work_center': nullIfEmpty(workCenterController.text),
    'setup_time_minutes':
        Validators.parseFlexibleNumber(setupMinutesController.text) ?? 0,
    'run_time_minutes':
        Validators.parseFlexibleNumber(runMinutesController.text) ?? 0,
  };

  void dispose() {
    operationNameController.dispose();
    workCenterController.dispose();
    setupMinutesController.dispose();
    runMinutesController.dispose();
  }
}

class BomViewModel extends GetxController {
  BomViewModel() {
    searchController.addListener(_notifySafely);
    bomCodeController.addListener(_handleBomCodeChanged);
    WorkingContextService.version.addListener(_handleWorkingContextChanged);
  }

  void _handleWorkingContextChanged() {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    load(selectId: id);
  }

  final ManufacturingModuleRefreshController _refreshController =
      ManufacturingModuleRefreshController.ensureRegistered();
  final ManufacturingService _service = ManufacturingService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController bomCodeController = TextEditingController();
  final TextEditingController bomNameController = TextEditingController();
  final TextEditingController versionNoController = TextEditingController();
  final TextEditingController batchSizeController = TextEditingController();
  final TextEditingController standardOutputQtyController =
      TextEditingController();
  final TextEditingController scrapPercentController = TextEditingController();
  final TextEditingController yieldPercentController = TextEditingController();
  final TextEditingController effectiveFromController = TextEditingController();
  final TextEditingController effectiveToController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<BomModel> rows = const <BomModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<BranchModel> branches = const <BranchModel>[];
  List<BusinessLocationModel> locations = const <BusinessLocationModel>[];
  List<ItemModel> items = const <ItemModel>[];
  List<UomModel> uoms = const <UomModel>[];
  List<UomConversionModel> uomConversions = const <UomConversionModel>[];

  BomModel? selected;
  int? companyId;
  int? branchId;
  int? locationId;
  int? outputItemId;
  int? outputUomId;
  bool isDefault = false;
  bool isActive = true;

  List<BomLineDraft> lines = <BomLineDraft>[];
  List<BomOperationDraft> operations = <BomOperationDraft>[];
  bool _suppressBomCodeListener = false;
  bool _bomCodeManuallyEdited = false;
  bool _isDisposed = false;

  bool get isApproved =>
      stringValue(selected?.toJson() ?? const {}, 'approval_status') ==
      'approved';
  bool get canEdit => !isApproved;

  List<BranchModel> get branchOptions =>
      branchesForCompany(branches, companyId);
  List<BusinessLocationModel> get locationOptions =>
      locationsForBranch(locations, branchId);
  List<ItemModel> get outputItemOptions {
    final cid = companyId;
    return items
        .where(
          (item) =>
              item.isManufacturable &&
              (cid == null || item.companyId == null || item.companyId == cid),
        )
        .toList(growable: false);
  }

  List<BomModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows
        .where((row) {
          final data = row.toJson();
          if (q.isEmpty) return true;
          return [
            stringValue(data, 'bom_code'),
            stringValue(data, 'bom_name'),
            stringValue(data, 'approval_status'),
            stringValue(data, 'version_no'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  String? consumeActionMessage() {
    final message = actionMessage;
    actionMessage = null;
    return message;
  }

  void _notifySafely() {
    if (_isDisposed) {
      return;
    }
    update();
  }

  void _handleBomCodeChanged() {
    if (_suppressBomCodeListener) {
      return;
    }
    _bomCodeManuallyEdited = true;
  }

  void _setBomCode(String value, {bool autoGenerated = false}) {
    _suppressBomCodeListener = true;
    bomCodeController.text = value;
    _suppressBomCodeListener = false;
    _bomCodeManuallyEdited = !autoGenerated;
  }

  String _generateBomCode({int? companyFilterId}) {
    final company = companyFilterId ?? companyId;
    final pattern = RegExp(r'^BOM/(\d+)$');
    var nextNumber = 1;

    for (final bom in rows) {
      final data = bom.toJson();
      if (company != null && intValue(data, 'company_id') != company) {
        continue;
      }

      final code = stringValue(data, 'bom_code').trim().toUpperCase();
      final match = pattern.firstMatch(code);
      if (match == null) {
        continue;
      }

      final value = int.tryParse(match.group(1) ?? '');
      if (value != null && value >= nextNumber) {
        nextNumber = value + 1;
      }
    }

    return 'BOM/${nextNumber.toString().padLeft(5, '0')}';
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    _notifySafely();
    try {
      await MasterDataCache.to.ensureLoaded();
      final cache = MasterDataCache.to;
      final responses = await Future.wait<dynamic>([
        _service.boms(filters: const {'per_page': 200, 'sort_by': 'bom_name'}),
      ]);
      rows =
          (responses[0] as PaginatedResponse<BomModel>).data ??
          const <BomModel>[];
      companies = cache.activeCompanies;
      branches = cache.activeBranches;
      locations = cache.activeLocations;
      items = cache.activeItems;
      uoms = cache.activeUoms;
      uomConversions = cache.activeUomConversions;
      loading = false;

      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: companies,
            branches: branches,
            locations: locations,
            financialYears: const <FinancialYearModel>[],
          );
      companyId = contextSelection.companyId;
      branchId = contextSelection.branchId;
      locationId = contextSelection.locationId;

      if (selectId != null) {
        final existing = rows.cast<BomModel?>().firstWhere(
          (x) =>
              intValue(x?.toJson() ?? const <String, dynamic>{}, 'id') ==
              selectId,
          orElse: () => null,
        );
        if (existing != null) {
          await select(existing);
          return;
        }
        if (await restoreSelectionAfterReload<BomModel>(
          selectId: selectId,
          rows: rows,
          selected: selected,
          onSelect: select,
          replaceRows: (nextRows) => rows = nextRows,
          notify: _notifySafely,
        )) {
          return;
        }
      }
      resetDraft();
      _notifySafely();
    } catch (e) {
      pageError = e.toString();
      loading = false;
      _notifySafely();
    }
  }

  void resetDraft() {
    for (final line in lines) {
      line.dispose();
    }
    for (final op in operations) {
      op.dispose();
    }
    selected = null;
    formError = null;
    final contextSelection = normalizedWorkingContextSelection(
      companies: companies,
      branches: branches,
      locations: locations,
      financialYears: const <FinancialYearModel>[],
      companyId: companyId,
      branchId: branchId,
      locationId: locationId,
      financialYearId: null,
    );
    companyId = contextSelection.companyId;
    branchId = contextSelection.branchId;
    locationId = contextSelection.locationId;
    outputItemId = null;
    outputUomId = null;
    _setBomCode(_generateBomCode(), autoGenerated: true);
    bomNameController.clear();
    versionNoController.text = '1.0';
    batchSizeController.text = '1';
    standardOutputQtyController.text = '1';
    scrapPercentController.text = '0';
    yieldPercentController.text = '100';
    effectiveFromController.text = displayTodayDate();
    effectiveToController.clear();
    notesController.clear();
    isDefault = false;
    isActive = true;
    lines = <BomLineDraft>[BomLineDraft()];
    operations = <BomOperationDraft>[BomOperationDraft()];
    _notifySafely();
  }

  Future<void> select(BomModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) return;
    selected = row;
    detailLoading = true;
    formError = null;
    _notifySafely();
    try {
      final response = await _service.bom(id);
      final data = (response.data ?? row).toJson();
      for (final line in lines) {
        line.dispose();
      }
      for (final op in operations) {
        op.dispose();
      }

      companyId = intValue(data, 'company_id');
      branchId = intValue(data, 'branch_id');
      locationId = intValue(data, 'location_id');
      outputItemId = intValue(data, 'output_item_id');
      outputUomId = intValue(data, 'output_uom_id');
      _setBomCode(stringValue(data, 'bom_code'));
      bomNameController.text = stringValue(data, 'bom_name');
      versionNoController.text = stringValue(data, 'version_no');
      batchSizeController.text = stringValue(data, 'batch_size', '1');
      standardOutputQtyController.text = stringValue(
        data,
        'standard_output_qty',
        '1',
      );
      scrapPercentController.text = stringValue(data, 'scrap_percent', '0');
      yieldPercentController.text = stringValue(data, 'yield_percent', '100');
      effectiveFromController.text = displayDate(
        nullableStringValue(data, 'effective_from'),
      );
      effectiveToController.text = displayDate(
        nullableStringValue(data, 'effective_to'),
      );
      notesController.text = stringValue(data, 'notes');
      isDefault = boolValue(data, 'is_default', fallback: false);
      isActive = boolValue(data, 'is_active', fallback: true);

      final rawLines = (data['lines'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      lines = rawLines.isEmpty
          ? <BomLineDraft>[BomLineDraft()]
          : rawLines.map(BomLineDraft.fromJson).toList(growable: true);

      final rawOperations =
          (data['operations'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .toList(growable: false);
      operations = rawOperations.isEmpty
          ? <BomOperationDraft>[BomOperationDraft()]
          : rawOperations
                .map(BomOperationDraft.fromJson)
                .toList(growable: true);
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      _notifySafely();
    }
  }

  void onCompanyChanged(int? value) {
    if (!canEdit) return;
    companyId = value;
    branchId = branchOptions.isNotEmpty ? branchOptions.first.id : null;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    if (selected == null && !_bomCodeManuallyEdited) {
      _setBomCode(
        _generateBomCode(companyFilterId: value),
        autoGenerated: true,
      );
    }
    _notifySafely();
  }

  void onBranchChanged(int? value) {
    if (!canEdit) return;
    branchId = value;
    locationId = locationOptions.isNotEmpty ? locationOptions.first.id : null;
    _notifySafely();
  }

  void onLocationChanged(int? value) {
    if (!canEdit) return;
    locationId = value;
    _notifySafely();
  }

  void setOutputItemId(int? value) {
    if (!canEdit) return;
    outputItemId = value;
    final item = items.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == value,
      orElse: () => null,
    );
    outputUomId = defaultUomIdForItem(
      item,
      uoms,
      uomConversions,
      current: outputUomId,
    );
    _notifySafely();
  }

  void setOutputUomId(int? value) {
    if (!canEdit) return;
    outputUomId = value;
    _notifySafely();
  }

  void addLine() {
    if (!canEdit) return;
    lines = List<BomLineDraft>.from(lines)..add(BomLineDraft());
    _notifySafely();
  }

  void setLineItemId(int index, int? value) {
    if (!canEdit || index < 0 || index >= lines.length) return;
    lines[index].itemId = value;
    final item = items.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == value,
      orElse: () => null,
    );
    lines[index].uomId = defaultUomIdForItem(
      item,
      uoms,
      uomConversions,
      current: lines[index].uomId,
    );
    _notifySafely();
  }

  void setLineUomId(int index, int? value) {
    if (!canEdit || index < 0 || index >= lines.length) return;
    lines[index].uomId = value;
    _notifySafely();
  }

  List<UomModel> uomOptionsForItem(int? itemId) {
    if (itemId == null) return const <UomModel>[];
    final item = items.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == itemId,
      orElse: () => null,
    );
    return allowedUomsForItem(item, uoms, uomConversions);
  }

  void removeLine(int index) {
    if (!canEdit || index < 0 || index >= lines.length) return;
    final next = List<BomLineDraft>.from(lines);
    final removed = next.removeAt(index);
    lines = next.isEmpty ? <BomLineDraft>[BomLineDraft()] : next;
    _notifySafely();
    disposeDraftEntriesNextFrame<BomLineDraft>([
      removed,
    ], (entry) => entry.dispose());
  }

  void addOperation() {
    if (!canEdit) return;
    operations = List<BomOperationDraft>.from(operations)
      ..add(BomOperationDraft());
    _notifySafely();
  }

  void removeOperation(int index) {
    if (!canEdit || index < 0 || index >= operations.length) return;
    final next = List<BomOperationDraft>.from(operations);
    final removed = next.removeAt(index);
    operations = next.isEmpty ? <BomOperationDraft>[BomOperationDraft()] : next;
    _notifySafely();
    disposeDraftEntriesNextFrame<BomOperationDraft>([
      removed,
    ], (entry) => entry.dispose());
  }

  String? validateForm() {
    if (companyId == null || branchId == null || locationId == null) {
      return 'Company, branch and location are required.';
    }
    if (nullIfEmpty(bomCodeController.text) == null) {
      return 'BOM code is required.';
    }
    final outputItem = items.cast<ItemModel?>().firstWhere(
      (entry) => entry?.id == outputItemId,
      orElse: () => null,
    );
    if (outputItemId != null && outputItem?.isManufacturable != true) {
      return 'Output item must be marked as manufacturable.';
    }
    if (outputItemId == null || outputUomId == null) {
      return 'Output item and output UOM are required.';
    }
    final versionNo = nullIfEmpty(versionNoController.text)?.trim();
    if (versionNo != null) {
      final selectedId = intValue(selected?.toJson() ?? const {}, 'id');
      final duplicate = rows.any((bom) {
        final data = bom.toJson();
        return intValue(data, 'company_id') == companyId &&
            intValue(data, 'output_item_id') == outputItemId &&
            stringValue(data, 'version_no').trim() == versionNo &&
            intValue(data, 'id') != selectedId;
      });
      if (duplicate) {
        return 'BOM version already exists for this output item in the selected company.';
      }
    }
    if (lines.isEmpty) {
      return 'At least one BOM line is required.';
    }
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.itemId == null || line.uomId == null) {
        return 'Line ${i + 1}: item and UOM are required.';
      }
    }
    return null;
  }

  Future<void> save() async {
    final error = validateForm();
    if (error != null) {
      formError = error;
      _notifySafely();
      return;
    }
    saving = true;
    formError = null;
    actionMessage = null;
    _notifySafely();
    final payload = <String, dynamic>{
      'company_id': companyId,
      'branch_id': branchId,
      'location_id': locationId,
      'bom_code': nullIfEmpty(bomCodeController.text),
      'bom_name': nullIfEmpty(bomNameController.text),
      'output_item_id': outputItemId,
      'output_uom_id': outputUomId,
      'version_no': nullIfEmpty(versionNoController.text),
      'batch_size':
          Validators.parseFlexibleNumber(batchSizeController.text) ?? 0,
      'standard_output_qty':
          Validators.parseFlexibleNumber(standardOutputQtyController.text) ?? 0,
      'scrap_percent':
          Validators.parseFlexibleNumber(scrapPercentController.text) ?? 0,
      'yield_percent':
          Validators.parseFlexibleNumber(yieldPercentController.text) ?? 0,
      'effective_from': nullIfEmpty(effectiveFromController.text),
      'effective_to': nullIfEmpty(effectiveToController.text),
      'notes': nullIfEmpty(notesController.text),
      'is_default': isDefault ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'lines': lines.map((line) => line.toJson()).toList(growable: false),
      'operations': operations
          .where((op) => op.hasMeaningfulData)
          .map((op) => op.toJson())
          .toList(growable: false),
    };
    try {
      final response = selected == null
          ? await _service.createBom(
              BomModel.fromJson(normalizeDatePayload(payload)),
            )
          : await _service.updateBom(
              intValue(selected!.toJson(), 'id')!,
              BomModel.fromJson(normalizeDatePayload(payload)),
            );
      actionMessage = response.message;
      await load(
        selectId: intValue(
          response.data?.toJson() ?? const <String, dynamic>{},
          'id',
        ),
      );
      _refreshController.notifyChanged(source: 'bom');
    } catch (e) {
      formError = e.toString();
      _notifySafely();
    } finally {
      saving = false;
      _notifySafely();
    }
  }

  Future<void> approve() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    try {
      final response = await _service.approveBom(
        id,
        BomModel.fromJson(<String, dynamic>{}),
      );
      actionMessage = response.message;
      await load(selectId: id);
      _refreshController.notifyChanged(source: 'bom');
    } catch (e) {
      formError = e.toString();
      _notifySafely();
    }
  }

  Future<void> delete() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    try {
      final response = await _service.deleteBom(id);
      actionMessage = response.message;
      await load();
      _refreshController.notifyChanged(source: 'bom');
    } catch (e) {
      formError = e.toString();
      _notifySafely();
    }
  }

  @override
  void onClose() {
    WorkingContextService.version.removeListener(_handleWorkingContextChanged);
    _isDisposed = true;
    searchController.removeListener(_notifySafely);
    searchController.dispose();
    bomCodeController.removeListener(_handleBomCodeChanged);
    bomCodeController.dispose();
    bomNameController.dispose();
    versionNoController.dispose();
    batchSizeController.dispose();
    standardOutputQtyController.dispose();
    scrapPercentController.dispose();
    yieldPercentController.dispose();
    effectiveFromController.dispose();
    effectiveToController.dispose();
    notesController.dispose();
    for (final line in lines) {
      line.dispose();
    }
    for (final op in operations) {
      op.dispose();
    }
    super.onClose();
  }
}
