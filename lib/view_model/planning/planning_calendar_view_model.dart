import 'package:billing/screen.dart';

class PlanningCalendarViewModel extends ChangeNotifier {
  final PlanningService _service = PlanningService();
  final MasterService _masterService = MasterService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController frequencyController = TextEditingController();
  final TextEditingController weekStartDayController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<PlanningCalendarModel> rows = const <PlanningCalendarModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];

  PlanningCalendarModel? selected;
  int? companyId;
  bool isActive = true;
  bool isDefault = false;

  PlanningCalendarViewModel() {
    searchController.addListener(notifyListeners);
    WorkingContextService.version.addListener(_handleWorkingContextChanged);
  }

  void _handleWorkingContextChanged() {
    final id =
        intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    load(selectId: id);
  }

  List<PlanningCalendarModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows.where((row) {
      final data = row.toJson();
      if (q.isEmpty) return true;
      return [
        stringValue(data, 'calendar_code'),
        stringValue(data, 'calendar_name'),
      ].join(' ').toLowerCase().contains(q);
    }).toList(growable: false);
  }

  String? consumeActionMessage() {
    final value = actionMessage;
    actionMessage = null;
    return value;
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    notifyListeners();
    try {
      final responses = await Future.wait<dynamic>([
        _service.calendars(filters: const {'per_page': 200}),
        _masterService.companies(filters: const {'per_page': 200}),
      ]);
      rows = (responses[0] as PaginatedResponse<PlanningCalendarModel>).data ??
          const <PlanningCalendarModel>[];
      companies = ((responses[1] as PaginatedResponse<CompanyModel>).data ??
              const <CompanyModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      final contextSelection = await WorkingContextService.instance
          .resolveSelection(
            companies: companies,
            branches: const <BranchModel>[],
            locations: const <BusinessLocationModel>[],
            financialYears: const <FinancialYearModel>[],
          );
      companyId = contextSelection.companyId;
      loading = false;
      if (selectId != null) {
        final existing = rows.cast<PlanningCalendarModel?>().firstWhere(
          (x) => intValue(x?.toJson() ?? const <String, dynamic>{}, 'id') == selectId,
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
    companyId ??= companies.isNotEmpty ? companies.first.id : null;
    codeController.clear();
    nameController.clear();
    frequencyController.text = 'weekly';
    weekStartDayController.text = 'monday';
    remarksController.clear();
    isActive = true;
    isDefault = false;
    notifyListeners();
  }

  Future<void> select(PlanningCalendarModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) return;
    selected = row;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _service.calendar(id);
      final data = (response.data ?? row).toJson();
      companyId = intValue(data, 'company_id');
      codeController.text = stringValue(data, 'calendar_code');
      nameController.text = stringValue(data, 'calendar_name');
      frequencyController.text = stringValue(data, 'planning_frequency', 'weekly');
      weekStartDayController.text = stringValue(data, 'week_start_day', 'monday');
      remarksController.text = stringValue(data, 'remarks');
      isActive = boolValue(data, 'is_active', fallback: true);
      isDefault = boolValue(data, 'is_default');
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      notifyListeners();
    }
  }

  void onCompanyChanged(int? value) {
    companyId = value;
    notifyListeners();
  }

  void setIsDefault(bool value) {
    isDefault = value;
    notifyListeners();
  }

  void setIsActive(bool value) {
    isActive = value;
    notifyListeners();
  }

  String? _validate() {
    if (companyId == null) return 'Company is required.';
    if (codeController.text.trim().isEmpty) return 'Calendar code is required.';
    if (nameController.text.trim().isEmpty) return 'Calendar name is required.';
    return null;
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
    notifyListeners();
    final payload = <String, dynamic>{
      'company_id': companyId,
      'calendar_code': codeController.text.trim(),
      'calendar_name': nameController.text.trim(),
      'planning_frequency': nullIfEmpty(frequencyController.text),
      'week_start_day': nullIfEmpty(weekStartDayController.text),
      'is_default': isDefault ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'remarks': nullIfEmpty(remarksController.text),
    };
    try {
      final response = selected == null
          ? await _service.createCalendar(PlanningCalendarModel(payload))
          : await _service.updateCalendar(
              intValue(selected!.toJson(), 'id')!,
              PlanningCalendarModel(payload),
            );
      actionMessage = response.message;
      await load(
        selectId: intValue(response.data?.toJson() ?? const <String, dynamic>{}, 'id'),
      );
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> delete() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    try {
      await _service.deleteCalendar(id);
      actionMessage = 'Planning calendar deleted successfully.';
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
    codeController.dispose();
    nameController.dispose();
    frequencyController.dispose();
    weekStartDayController.dispose();
    remarksController.dispose();
    super.dispose();
  }
}
