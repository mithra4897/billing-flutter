import 'package:billing/screen.dart';
import 'package:billing/view/hr/hr_workflow_dialogs.dart';

class MaintenancePlanViewModel extends ChangeNotifier {
  MaintenancePlanViewModel() {
    searchController.addListener(notifyListeners);
  }

  final MaintenanceService _service = MaintenanceService();
  final MasterService _masterService = MasterService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController planCodeController = TextEditingController();
  final TextEditingController planNameController = TextEditingController();
  final TextEditingController maintenanceTypeController =
      TextEditingController();
  final TextEditingController scheduleBasisController = TextEditingController();
  final TextEditingController frequencyValueController =
      TextEditingController();
  final TextEditingController checklistNotesController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<MaintenancePlanModel> rows = const <MaintenancePlanModel>[];
  List<CompanyModel> companies = const <CompanyModel>[];

  MaintenancePlanModel? selected;

  int? companyId;
  bool isAutoGenerateRequest = false;
  bool isActive = true;

  int? _sessionCompanyId;

  int? get selectedId =>
      intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');

  List<MaintenancePlanModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows.where((row) {
      if (q.isEmpty) {
        return true;
      }
      final data = row.toJson();
      return [
        stringValue(data, 'plan_code'),
        stringValue(data, 'plan_name'),
        stringValue(data, 'maintenance_type'),
        stringValue(data, 'schedule_basis'),
      ].join(' ').toLowerCase().contains(q);
    }).toList(growable: false);
  }

  String listTitle(MaintenancePlanModel row) {
    final data = row.toJson();
    final name = stringValue(data, 'plan_name');
    if (name.isNotEmpty) {
      return name;
    }
    final code = stringValue(data, 'plan_code');
    if (code.isNotEmpty) {
      return code;
    }
    final id = intValue(data, 'id');
    return id != null ? 'Plan #$id' : 'Plan';
  }

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
      final info = await hrSessionCompanyInfo();
      _sessionCompanyId = info.companyId;

      final filters = <String, dynamic>{'per_page': 200};
      if (_sessionCompanyId != null) {
        filters['company_id'] = _sessionCompanyId;
      }

      final responses = await Future.wait<dynamic>([
        _service.plans(filters: filters),
        _masterService.companies(filters: const {'per_page': 200}),
      ]);

      rows =
          (responses[0] as PaginatedResponse<MaintenancePlanModel>).data ??
              const <MaintenancePlanModel>[];

      companies = ((responses[1] as PaginatedResponse<CompanyModel>).data ??
              const <CompanyModel>[])
          .where((x) => x.isActive)
          .toList(growable: false);

      loading = false;

      if (selectId != null) {
        MaintenancePlanModel? match;
        for (final r in rows) {
          if (intValue(r.toJson(), 'id') == selectId) {
            match = r;
            break;
          }
        }
        if (match != null) {
          await select(match);
          return;
        }
        await select(MaintenancePlanModel(<String, dynamic>{'id': selectId}));
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
    selected = null;
    formError = null;
    companyId = _sessionCompanyId ??
        (companies.isNotEmpty ? companies.first.id : null);
    planCodeController.clear();
    planNameController.clear();
    maintenanceTypeController.clear();
    scheduleBasisController.clear();
    frequencyValueController.clear();
    checklistNotesController.clear();
    isAutoGenerateRequest = false;
    isActive = true;
    notifyListeners();
  }

  void setCompanyId(int? value) {
    companyId = value;
    notifyListeners();
  }

  void setIsAutoGenerateRequest(bool value) {
    isAutoGenerateRequest = value;
    notifyListeners();
  }

  void setIsActive(bool value) {
    isActive = value;
    notifyListeners();
  }

  Future<void> select(MaintenancePlanModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _service.plan(id);
      final doc = response.data ?? row;
      selected = doc;
      _applyDetail(doc.toJson());
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      notifyListeners();
    }
  }

  void _applyDetail(Map<String, dynamic> data) {
    companyId = intValue(data, 'company_id');
    planCodeController.text = stringValue(data, 'plan_code');
    planNameController.text = stringValue(data, 'plan_name');
    maintenanceTypeController.text = stringValue(data, 'maintenance_type');
    scheduleBasisController.text = stringValue(data, 'schedule_basis');
    frequencyValueController.text =
        data['frequency_value']?.toString() ?? '';
    checklistNotesController.text = stringValue(data, 'checklist_notes');
    final auto = data['is_auto_generate_request'];
    isAutoGenerateRequest = auto == true || auto == 1 || auto == '1';
    final active = data['is_active'];
    isActive = active != false && active != 0 && active != '0';
  }

  String? _validateSave() {
    if (companyId == null) {
      return 'Company is required.';
    }
    if (planCodeController.text.trim().isEmpty) {
      return 'Plan code is required.';
    }
    if (planNameController.text.trim().isEmpty) {
      return 'Plan name is required.';
    }
    return null;
  }

  Map<String, dynamic> _buildPayload() {
    final fq = int.tryParse(frequencyValueController.text.trim());
    return <String, dynamic>{
      'company_id': companyId,
      'plan_code': planCodeController.text.trim(),
      'plan_name': planNameController.text.trim(),
      'maintenance_type': nullIfEmpty(maintenanceTypeController.text),
      'schedule_basis': nullIfEmpty(scheduleBasisController.text),
      'frequency_value': ?fq,
      'checklist_notes': nullIfEmpty(checklistNotesController.text),
      'is_auto_generate_request': isAutoGenerateRequest,
      'is_active': isActive,
    };
  }

  Future<void> save() async {
    final err = _validateSave();
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
      if (selected == null) {
        final response = await _service.createPlan(
          MaintenancePlanModel(_buildPayload()),
        );
        actionMessage = response.message;
        await load(selectId: intValue(response.data?.toJson() ?? {}, 'id'));
      } else {
        final id = selectedId;
        if (id == null) {
          formError = 'Missing plan id.';
          notifyListeners();
          return;
        }
        final response = await _service.updatePlan(
          id,
          MaintenancePlanModel(_buildPayload()),
        );
        actionMessage = response.message;
        await load(selectId: id);
      }
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<void> deletePlan() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      await _service.deletePlan(id);
      actionMessage = 'Maintenance plan deleted.';
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
    maintenanceTypeController.dispose();
    scheduleBasisController.dispose();
    frequencyValueController.dispose();
    checklistNotesController.dispose();
    super.dispose();
  }
}
