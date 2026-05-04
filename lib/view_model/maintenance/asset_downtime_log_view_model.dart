import 'package:billing/screen.dart';
import 'package:billing/view/hr/hr_workflow_dialogs.dart';
import 'package:billing/view/purchase/purchase_support.dart';

class AssetDowntimeLogViewModel extends ChangeNotifier {
  AssetDowntimeLogViewModel() {
    searchController.addListener(notifyListeners);
  }

  final MaintenanceService _maintenance = MaintenanceService();
  final AssetsService _assets = AssetsService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController downtimeReasonController = TextEditingController();
  final TextEditingController downtimeStartController = TextEditingController();
  final TextEditingController downtimeEndController = TextEditingController();
  final TextEditingController productionImpactController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<AssetDowntimeLogModel> rows = const <AssetDowntimeLogModel>[];
  List<AssetModel> assets = const <AssetModel>[];
  List<MaintenanceWorkOrderModel> workOrders = const <MaintenanceWorkOrderModel>[];

  AssetDowntimeLogModel? selected;

  int? assetId;
  int? maintenanceWorkOrderId;
  bool isPlanned = false;

  int? _sessionCompanyId;

  int? get selectedId =>
      intValue(selected?.toJson() ?? const <String, dynamic>{}, 'id');

  List<AssetDowntimeLogModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows.where((row) {
      if (q.isEmpty) {
        return true;
      }
      final data = row.toJson();
      return [
        stringValue(data, 'downtime_reason'),
        downtimeAssetLabel(data),
      ].join(' ').toLowerCase().contains(q);
    }).toList(growable: false);
  }

  String downtimeAssetLabel(Map<String, dynamic> data) {
    final nested = data['asset'];
    if (nested is Map<String, dynamic>) {
      final code = stringValue(nested, 'asset_code');
      final name = stringValue(nested, 'asset_name');
      if (code.isNotEmpty && name.isNotEmpty) {
        return '$code — $name';
      }
      return code.isNotEmpty ? code : name;
    }
    return '';
  }

  String listTitle(AssetDowntimeLogModel row) {
    final data = row.toJson();
    final label = downtimeAssetLabel(data);
    if (label.isNotEmpty) {
      return label;
    }
    final id = intValue(data, 'id');
    return id != null ? 'Downtime #$id' : 'Downtime';
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
        _maintenance.downtimeLogs(filters: filters),
        _assets.assets(filters: filters),
        _maintenance.workOrders(filters: filters),
      ]);

      rows =
          (responses[0] as PaginatedResponse<AssetDowntimeLogModel>).data ??
              const <AssetDowntimeLogModel>[];
      assets = ((responses[1] as PaginatedResponse<AssetModel>).data ??
              const <AssetModel>[])
          .where((a) => intValue(a.toJson(), 'id') != null)
          .toList(growable: false);
      workOrders =
          ((responses[2] as PaginatedResponse<MaintenanceWorkOrderModel>).data ??
                  const <MaintenanceWorkOrderModel>[])
              .where((w) => intValue(w.toJson(), 'id') != null)
              .toList(growable: false);

      loading = false;

      if (selectId != null) {
        AssetDowntimeLogModel? match;
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
        await select(
          AssetDowntimeLogModel(<String, dynamic>{'id': selectId}),
        );
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
    assetId = null;
    maintenanceWorkOrderId = null;
    downtimeReasonController.clear();
    downtimeStartController.text = _defaultDowntimeStart();
    downtimeEndController.clear();
    productionImpactController.clear();
    isPlanned = false;
    notifyListeners();
  }

  void setAssetId(int? value) {
    assetId = value;
    notifyListeners();
  }

  void setMaintenanceWorkOrderId(int? value) {
    maintenanceWorkOrderId = value;
    notifyListeners();
  }

  void setIsPlanned(bool value) {
    isPlanned = value;
    notifyListeners();
  }

  Future<void> select(AssetDowntimeLogModel row) async {
    final id = intValue(row.toJson(), 'id');
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _maintenance.downtimeLog(id);
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
    assetId = intValue(data, 'asset_id');
    maintenanceWorkOrderId = intValue(data, 'maintenance_work_order_id');
    downtimeReasonController.text = stringValue(data, 'downtime_reason');
    downtimeStartController.text =
        _formatDateTimeField(nullableStringValue(data, 'downtime_start'));
    downtimeEndController.text =
        _formatDateTimeField(nullableStringValue(data, 'downtime_end'));
    productionImpactController.text =
        stringValue(data, 'production_impact_notes');
    final planned = data['is_planned'];
    isPlanned = planned == true || planned == 1 || planned == '1';
  }

  static String _defaultDowntimeStart() {
    final s = DateTime.now().toIso8601String();
    final dot = s.indexOf('.');
    return dot > 0 ? s.substring(0, dot) : s;
  }

  String _formatDateTimeField(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return '';
    }
    return displayDateTime(raw.trim());
  }

  String? _validateForSave() {
    if (assetId == null) {
      return 'Asset is required.';
    }
    if (downtimeStartController.text.trim().isEmpty) {
      return 'Downtime start is required.';
    }
    return null;
  }

  Map<String, dynamic> _buildPayload() {
    return <String, dynamic>{
      'asset_id': assetId,
      'downtime_reason': nullIfEmpty(downtimeReasonController.text),
      'downtime_start': downtimeStartController.text.trim(),
      'downtime_end': ?nullIfEmpty(downtimeEndController.text.trim()),
      'production_impact_notes': nullIfEmpty(productionImpactController.text),
      'is_planned': isPlanned,
      'maintenance_work_order_id': ?maintenanceWorkOrderId,
    };
  }

  Future<void> save() async {
    final err = _validateForSave();
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
        final response = await _maintenance.createDowntimeLog(
          AssetDowntimeLogModel(_buildPayload()),
        );
        actionMessage = response.message;
        await load(selectId: intValue(response.data?.toJson() ?? {}, 'id'));
      } else {
        final id = selectedId;
        if (id == null) {
          formError = 'Missing downtime log id.';
          notifyListeners();
          return;
        }
        final response = await _maintenance.updateDowntimeLog(
          id,
          AssetDowntimeLogModel(_buildPayload()),
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

  Future<void> deleteLog() async {
    final id = selectedId;
    if (id == null) {
      return;
    }
    try {
      await _maintenance.deleteDowntimeLog(id);
      actionMessage = 'Downtime log deleted.';
      await load();
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  String assetPickerLabel(AssetModel a) {
    final d = a.toJson();
    final code = stringValue(d, 'asset_code');
    final name = stringValue(d, 'asset_name');
    if (code.isNotEmpty && name.isNotEmpty) {
      return '$code — $name';
    }
    return code.isNotEmpty ? code : name;
  }

  String workOrderLabel(MaintenanceWorkOrderModel w) {
    final d = w.toJson();
    final no = stringValue(d, 'work_order_no');
    if (no.isNotEmpty) {
      return no;
    }
    final id = intValue(d, 'id');
    return id != null ? 'WO #$id' : 'Work order';
  }

  @override
  void dispose() {
    searchController.dispose();
    downtimeReasonController.dispose();
    downtimeStartController.dispose();
    downtimeEndController.dispose();
    productionImpactController.dispose();
    super.dispose();
  }
}
