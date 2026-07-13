import '../../../screen.dart';

class MrpRunViewModel extends GetxController {
  static const List<AppDropdownItem<String>> runScopeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem<String>(value: 'all_items', label: 'All Items'),
        AppDropdownItem<String>(
          value: 'selected_warehouse',
          label: 'Warehouse Only',
        ),
      ];

  static const List<AppDropdownItem<String>> runModeItems =
      <AppDropdownItem<String>>[
        AppDropdownItem<String>(value: 'official', label: 'Official Run'),
        AppDropdownItem<String>(value: 'simulation', label: 'Simulation'),
      ];

  final PlanningService _service = PlanningService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController runNoController = TextEditingController();
  final TextEditingController runDateController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<MrpRunModel> rows = const <MrpRunModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];
  List<BranchModel> branches = const <BranchModel>[];
  List<BusinessLocationModel> locations = const <BusinessLocationModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];
  List<PlanningCalendarModel> calendars = const <PlanningCalendarModel>[];
  MrpRunModel? selected;
  int? companyId;
  int? branchId;
  int? locationId;
  int? warehouseId;
  int? planningCalendarId;
  String runScope = 'all_items';
  String runMode = 'official';

  MrpRunViewModel() {
    searchController.addListener(update);
    WorkingContextService.version.addListener(_handleWorkingContextChanged);
  }

  void _handleWorkingContextChanged() {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    load(selectId: id);
  }

  List<MrpRunModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows
        .where((row) {
          final data = row.toJson();
          if (q.isEmpty) return true;
          return [
            stringValue(data, 'run_no'),
            stringValue(data, 'run_status'),
            stringValue(data, 'run_mode'),
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  String? consumeActionMessage() {
    final value = actionMessage;
    actionMessage = null;
    return value;
  }

  List<BranchModel> get branchOptions => branchesForCompany(
    branches,
    companyId,
  ).where((branch) => branch.isActive).toList(growable: false);

  List<BusinessLocationModel> get locationOptions => locationsForBranch(
    locations,
    branchId,
  ).where((location) => location.isActive).toList(growable: false);

  List<WarehouseModel> get warehouseOptions => warehouses
      .where((warehouse) {
        if (!warehouse.isActive || warehouse.id == null) {
          return false;
        }
        if (companyId != null && warehouse.companyId != companyId) {
          return false;
        }
        if (branchId != null && warehouse.branchId != branchId) {
          return false;
        }
        if (locationId != null && warehouse.locationId != locationId) {
          return false;
        }
        return true;
      })
      .toList(growable: false);

  List<PlanningCalendarModel> get calendarOptions => calendars
      .where((calendar) {
        if (calendar.id == null) {
          return false;
        }
        if (companyId != null && calendar.companyId != companyId) {
          return false;
        }
        return calendar.isActive ?? true;
      })
      .toList(growable: false);

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    update();
    try {
      await MasterDataCache.to.ensureLoaded();
      final cache = MasterDataCache.to;
      final responses = await Future.wait<dynamic>([
        _service.mrpRuns(filters: const {'per_page': 200}),
        _service.calendars(filters: const {'per_page': 300}),
      ]);
      rows =
          (responses[0] as PaginatedResponse<MrpRunModel>).data ??
          const <MrpRunModel>[];
      companies = cache.activeCompanies;
      branches = cache.activeBranches;
      locations = cache.activeLocations;
      warehouses = cache.activeWarehouses;
      calendars =
          ((responses[1] as PaginatedResponse<PlanningCalendarModel>).data ??
                  const <PlanningCalendarModel>[])
              .where((x) => x.isActive ?? true)
              .toList(growable: false);
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
      loading = false;
      if (selectId != null) {
        final existing = rows.cast<MrpRunModel?>().firstWhere(
          (x) =>
              intValue(x?.toJson() ?? const <String, dynamic>{}, 'id') ==
              selectId,
          orElse: () => null,
        );
        if (existing != null) {
          await select(existing);
          return;
        }
        if (await restoreSelectionAfterReload<MrpRunModel>(
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
    final normalized = normalizedWorkingContextSelection(
      companies: companies,
      branches: branches,
      locations: locations,
      financialYears: const <FinancialYearModel>[],
      companyId: companyId,
      branchId: branchId,
      locationId: locationId,
      financialYearId: null,
    );
    companyId = normalized.companyId;
    branchId = normalized.branchId;
    locationId = normalized.locationId;
    warehouseId = null;
    planningCalendarId =
        calendarOptions
            .cast<PlanningCalendarModel?>()
            .firstWhere(
              (calendar) => calendar?.isDefault == true,
              orElse: () => null,
            )
            ?.id ??
        (calendarOptions.isNotEmpty ? calendarOptions.first.id : null);
    runScope = 'all_items';
    runMode = 'official';
    runNoController.clear();
    final today = displayTodayDate();
    runDateController.text = today;
    startDateController.text = today;
    endDateController.text = today;
    notesController.clear();
    update();
  }

  Future<void> select(MrpRunModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) return;
    selected = row;
    detailLoading = true;
    formError = null;
    update();
    try {
      final response = await _service.mrpRun(id);
      final data = (response.data ?? row).toJson();
      companyId = intValue(data, 'company_id');
      branchId = intValue(data, 'branch_id');
      locationId = intValue(data, 'location_id');
      warehouseId = intValue(data, 'warehouse_id');
      planningCalendarId = intValue(data, 'planning_calendar_id');
      runNoController.text = stringValue(data, 'run_no');
      runDateController.text = normalizeDateValue(
        nullableStringValue(data, 'run_date'),
      );
      startDateController.text = normalizeDateValue(
        nullableStringValue(data, 'planning_start_date'),
      );
      endDateController.text = normalizeDateValue(
        nullableStringValue(data, 'planning_end_date'),
      );
      runScope = _normalizeRunScope(stringValue(data, 'run_scope'));
      runMode = _normalizeRunMode(stringValue(data, 'run_mode'));
      notesController.text = stringValue(data, 'notes');
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      update();
    }
  }

  void onCompanyChanged(int? value) {
    companyId = value;
    final nextBranches = branchOptions;
    branchId = containsMasterId(nextBranches, branchId, (item) => item.id)
        ? branchId
        : (nextBranches.isNotEmpty ? nextBranches.first.id : null);
    final nextLocations = locationOptions;
    locationId = containsMasterId(nextLocations, locationId, (item) => item.id)
        ? locationId
        : (nextLocations.isNotEmpty ? nextLocations.first.id : null);
    if (!warehouseOptions.any((warehouse) => warehouse.id == warehouseId)) {
      warehouseId = null;
    }
    if (!calendarOptions.any((calendar) => calendar.id == planningCalendarId)) {
      planningCalendarId =
          calendarOptions
              .cast<PlanningCalendarModel?>()
              .firstWhere(
                (calendar) => calendar?.isDefault == true,
                orElse: () => null,
              )
              ?.id ??
          (calendarOptions.isNotEmpty ? calendarOptions.first.id : null);
    }
    update();
  }

  void onBranchChanged(int? value) {
    branchId = value;
    final nextLocations = locationOptions;
    locationId = containsMasterId(nextLocations, locationId, (item) => item.id)
        ? locationId
        : (nextLocations.isNotEmpty ? nextLocations.first.id : null);
    if (!warehouseOptions.any((warehouse) => warehouse.id == warehouseId)) {
      warehouseId = null;
    }
    update();
  }

  void onLocationChanged(int? value) {
    locationId = value;
    if (!warehouseOptions.any((warehouse) => warehouse.id == warehouseId)) {
      warehouseId = null;
    }
    update();
  }

  void onWarehouseChanged(int? value) {
    warehouseId = value;
    update();
  }

  void onPlanningCalendarChanged(int? value) {
    planningCalendarId = value;
    update();
  }

  void onRunScopeChanged(String? value) {
    runScope = _normalizeRunScope(value);
    if (runScope != 'selected_warehouse') {
      warehouseId = null;
    }
    update();
  }

  void onRunModeChanged(String? value) {
    runMode = _normalizeRunMode(value);
    update();
  }

  String get status => stringValue(
    selected?.toJson() ?? const <String, dynamic>{},
    'run_status',
    'draft',
  );

  String? _validate() {
    if (companyId == null) return 'Company is required.';
    if (runDateController.text.trim().isEmpty) return 'Run date is required.';
    if (startDateController.text.trim().isEmpty) {
      return 'Planning start date is required.';
    }
    if (endDateController.text.trim().isEmpty) {
      return 'Planning end date is required.';
    }
    return null;
  }

  Future<void> save() async {
    final err = _validate();
    if (err != null) {
      formError = err;
      update();
      return;
    }
    saving = true;
    formError = null;
    update();
    final payload = <String, dynamic>{
      'company_id': companyId,
      'branch_id': branchId,
      'location_id': locationId,
      'warehouse_id': runScope == 'selected_warehouse' ? warehouseId : null,
      'planning_calendar_id': planningCalendarId,
      'run_no': nullIfEmpty(runNoController.text),
      'run_date': runDateController.text.trim(),
      'planning_start_date': startDateController.text.trim(),
      'planning_end_date': endDateController.text.trim(),
      'run_scope': runScope,
      'run_mode': runMode,
      'notes': nullIfEmpty(notesController.text),
    };
    try {
      final response = selected == null
          ? await _service.createMrpRun(
              MrpRunModel.fromJson(normalizeDatePayload(payload)),
            )
          : await _service.updateMrpRun(
              intValue(selected!.toJson(), 'id')!,
              MrpRunModel.fromJson(normalizeDatePayload(payload)),
            );
      actionMessage = response.message;
      await load(
        selectId: intValue(
          response.data?.toJson() ?? const <String, dynamic>{},
          'id',
        ),
      );
    } catch (e) {
      formError = e.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> process() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    try {
      final response = await _service.processMrpRun(
        id,
        MrpRunModel.fromJson(<String, dynamic>{}),
      );
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  Future<void> cancel() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    try {
      final response = await _service.cancelMrpRun(
        id,
        MrpRunModel.fromJson(<String, dynamic>{}),
      );
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  Future<void> delete() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    try {
      await _service.deleteMrpRun(id);
      actionMessage = 'MRP run deleted successfully.';
      await load();
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  @override
  void onClose() {
    WorkingContextService.version.removeListener(_handleWorkingContextChanged);
    searchController.dispose();
    runNoController.dispose();
    runDateController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    notesController.dispose();
    super.onClose();
  }

  String _normalizeRunScope(String? value) {
    final normalized = (value ?? 'all_items').trim().toLowerCase();
    switch (normalized) {
      case 'all':
        return 'all_items';
      case 'warehouse':
        return 'selected_warehouse';
      default:
        return normalized.isEmpty ? 'all_items' : normalized;
    }
  }

  String _normalizeRunMode(String? value) {
    final normalized = (value ?? 'official').trim().toLowerCase();
    switch (normalized) {
      case 'full':
        return 'official';
      case 'regenerative':
        return 'simulation';
      default:
        return normalized.isEmpty ? 'official' : normalized;
    }
  }
}
