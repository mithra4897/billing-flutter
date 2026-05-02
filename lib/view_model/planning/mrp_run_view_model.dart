import 'package:billing/screen.dart';

class MrpRunViewModel extends ChangeNotifier {
  final PlanningService _service = PlanningService();
  final MasterService _masterService = MasterService();

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
  MrpRunModel? selected;
  int? companyId;

  MrpRunViewModel() {
    searchController.addListener(notifyListeners);
  }

  List<MrpRunModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows.where((row) {
      final data = row.toJson();
      if (q.isEmpty) return true;
      return [
        stringValue(data, 'run_no'),
        stringValue(data, 'run_status'),
        stringValue(data, 'run_mode'),
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
        _service.mrpRuns(filters: const {'per_page': 200}),
        _masterService.companies(filters: const {'per_page': 200}),
      ]);
      rows = (responses[0] as PaginatedResponse<MrpRunModel>).data ??
          const <MrpRunModel>[];
      companies = ((responses[1] as PaginatedResponse<CompanyModel>).data ??
              const <CompanyModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);
      loading = false;
      if (selectId != null) {
        final existing = rows.cast<MrpRunModel?>().firstWhere(
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
    runNoController.clear();
    final today = DateTime.now().toIso8601String().split('T').first;
    runDateController.text = today;
    startDateController.text = today;
    endDateController.text = today;
    notesController.clear();
    notifyListeners();
  }

  Future<void> select(MrpRunModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) return;
    selected = row;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _service.mrpRun(id);
      final data = (response.data ?? row).toJson();
      companyId = intValue(data, 'company_id');
      runNoController.text = stringValue(data, 'run_no');
      runDateController.text = nullableStringValue(data, 'run_date') ?? '';
      startDateController.text = nullableStringValue(data, 'planning_start_date') ?? '';
      endDateController.text = nullableStringValue(data, 'planning_end_date') ?? '';
      notesController.text = stringValue(data, 'notes');
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

  String get status =>
      stringValue(selected?.toJson() ?? const <String, dynamic>{}, 'run_status', 'draft');

  String? _validate() {
    if (companyId == null) return 'Company is required.';
    if (runDateController.text.trim().isEmpty) return 'Run date is required.';
    if (startDateController.text.trim().isEmpty) return 'Planning start date is required.';
    if (endDateController.text.trim().isEmpty) return 'Planning end date is required.';
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
      'run_no': nullIfEmpty(runNoController.text),
      'run_date': runDateController.text.trim(),
      'planning_start_date': startDateController.text.trim(),
      'planning_end_date': endDateController.text.trim(),
      'notes': nullIfEmpty(notesController.text),
    };
    try {
      final response = selected == null
          ? await _service.createMrpRun(MrpRunModel(payload))
          : await _service.updateMrpRun(
              intValue(selected!.toJson(), 'id')!,
              MrpRunModel(payload),
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

  Future<void> process() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    try {
      final response = await _service.processMrpRun(id, const MrpRunModel(<String, dynamic>{}));
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> cancel() async {
    final id = intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');
    if (id == null) return;
    try {
      final response = await _service.cancelMrpRun(id, const MrpRunModel(<String, dynamic>{}));
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
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
      notifyListeners();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    runNoController.dispose();
    runDateController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    notesController.dispose();
    super.dispose();
  }
}
