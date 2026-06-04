import '../../../screen.dart';
import 'quality_module_refresh_controller.dart';

const Set<String> _resultActionInspectionStatuses = <String>{
  'completed',
  'approved',
  'rejected',
};

const List<AppDropdownItem<String>> kQcResultActionTypeItems =
    <AppDropdownItem<String>>[
      AppDropdownItem(value: 'accept_to_stock', label: 'Accept to stock'),
      AppDropdownItem(value: 'reject_to_supplier', label: 'Reject to supplier'),
      AppDropdownItem(value: 'reject_to_scrap', label: 'Reject to scrap'),
      AppDropdownItem(value: 'move_to_hold', label: 'Move to hold'),
      AppDropdownItem(value: 'move_to_quarantine', label: 'Move to quarantine'),
      AppDropdownItem(value: 'send_for_rework', label: 'Send for rework'),
      AppDropdownItem(value: 'manual_override', label: 'Manual override'),
    ];

class QcResultActionViewModel extends GetxController {
  QcResultActionViewModel() {
    searchController.addListener(update);
  }

  final QualityModuleRefreshController _refreshController =
      QualityModuleRefreshController.ensureRegistered();
  final QualityService _service = QualityService();
  final MasterService _masterService = MasterService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController actionQtyController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController referenceDocTypeController =
      TextEditingController();
  final TextEditingController referenceDocIdController =
      TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<QcResultActionModel> rows = const <QcResultActionModel>[];
  List<QcInspectionModel> inspections = const <QcInspectionModel>[];
  List<WarehouseModel> warehouses = const <WarehouseModel>[];

  QcResultActionModel? selected;

  int? qcInspectionId;
  String actionType = 'accept_to_stock';
  int? targetWarehouseId;

  String get actionStatus => selected?.actionStatus ?? 'pending';

  bool get canEdit => selected == null || actionStatus == 'pending';

  bool get canComplete => selected != null && actionStatus == 'pending';

  bool get canCancel =>
      selected != null &&
      actionStatus != 'completed' &&
      actionStatus != 'cancelled';

  bool get canDelete => selected != null && actionStatus == 'pending';

  List<QcInspectionModel> get inspectionOptions => inspections
      .where((i) {
        if (intValue(i.toJson(), 'id') == null) {
          return false;
        }
        final st = stringValue(i.toJson(), 'inspection_status');
        return _resultActionInspectionStatuses.contains(st);
      })
      .toList(growable: false);

  List<QcResultActionModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows
        .where((row) {
          if (q.isEmpty) {
            return true;
          }
          return [
            row.actionType,
            row.actionStatus,
            row.inspectionNoLabel,
          ].join(' ').toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  String? consumeActionMessage() {
    final message = actionMessage;
    actionMessage = null;
    return message;
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    update();
    try {
      final responses = await Future.wait<dynamic>([
        _service.qcResultActions(
          filters: const {'per_page': 200, 'sort_by': 'id'},
        ),
        _service.qcInspections(filters: const {'per_page': 400}),
        _masterService.warehouses(filters: const {'per_page': 400}),
      ]);
      rows =
          (responses[0] as PaginatedResponse<QcResultActionModel>).data ??
          const <QcResultActionModel>[];
      inspections =
          (responses[1] as PaginatedResponse<QcInspectionModel>).data ??
          const <QcInspectionModel>[];
      warehouses =
          ((responses[2] as PaginatedResponse<WarehouseModel>).data ??
                  const <WarehouseModel>[])
              .where((x) => x.isActive)
              .toList(growable: false);

      loading = false;

      if (selectId != null) {
        QcResultActionModel? match;
        for (final r in rows) {
          if (r.id == selectId) {
            match = r;
            break;
          }
        }
        if (match != null) {
          await select(match);
          return;
        }
        if (await restoreSelectionAfterReload<QcResultActionModel>(
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
    qcInspectionId = inspectionOptions.isNotEmpty
        ? intValue(inspectionOptions.first.toJson(), 'id')
        : null;
    actionType = 'accept_to_stock';
    actionQtyController.clear();
    targetWarehouseId = null;
    remarksController.clear();
    referenceDocTypeController.clear();
    referenceDocIdController.clear();
    update();
  }

  Future<void> select(QcResultActionModel row) async {
    final id = row.id;
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    formError = null;
    update();
    try {
      final response = await _service.qcResultAction(id);
      final doc = response.data ?? row;
      qcInspectionId = doc.qcInspectionId;
      actionType = doc.actionType.isNotEmpty
          ? doc.actionType
          : 'accept_to_stock';
      actionQtyController.text = doc.actionQty > 0
          ? doc.actionQty.toString()
          : '';
      targetWarehouseId = doc.targetWarehouseId;
      remarksController.text = doc.remarks ?? '';
      referenceDocTypeController.text = doc.referenceDocumentType ?? '';
      referenceDocIdController.text = doc.referenceDocumentId?.toString() ?? '';
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      update();
    }
  }

  void setQcInspectionId(int? value) {
    if (!canEdit) {
      return;
    }
    qcInspectionId = value;
    update();
  }

  void setActionType(String value) {
    if (!canEdit) {
      return;
    }
    actionType = value;
    update();
  }

  void setTargetWarehouseId(int? value) {
    if (!canEdit) {
      return;
    }
    targetWarehouseId = value;
    update();
  }

  List<WarehouseModel> warehouseOptionsForInspection(int? inspectionId) {
    QcInspectionModel? ins;
    for (final x in inspections) {
      if (intValue(x.toJson(), 'id') == inspectionId) {
        ins = x;
        break;
      }
    }
    final cid = ins != null ? intValue(ins.toJson(), 'company_id') : null;
    return warehouses
        .where((w) {
          if (w.id == null) {
            return false;
          }
          return cid == null || w.companyId == cid;
        })
        .toList(growable: false);
  }

  String? _validate() {
    if (qcInspectionId == null) {
      return 'QC inspection is required.';
    }
    final qty = double.tryParse(actionQtyController.text.trim()) ?? 0;
    if (qty <= 0) {
      return 'Action quantity must be greater than zero.';
    }
    return null;
  }

  QcResultActionModel _buildDocument() {
    final qty = double.tryParse(actionQtyController.text.trim()) ?? 0;
    final refId = int.tryParse(referenceDocIdController.text.trim());
    return QcResultActionModel(
      qcInspectionId: qcInspectionId,
      actionType: actionType,
      actionQty: qty,
      targetWarehouseId: targetWarehouseId,
      referenceDocumentType: nullIfEmpty(referenceDocTypeController.text),
      referenceDocumentId: refId,
      remarks: nullIfEmpty(remarksController.text),
    );
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
    actionMessage = null;
    update();
    try {
      final doc = _buildDocument();
      if (selected == null) {
        final response = await _service.createQcResultAction(doc);
        actionMessage = response.message;
        _refreshController.notifyChanged(source: 'qc_result_action');
        await load(selectId: response.data?.id);
      } else {
        final response = await _service.updateQcResultAction(
          selected!.id!,
          doc,
        );
        actionMessage = response.message;
        _refreshController.notifyChanged(source: 'qc_result_action');
        await load(selectId: selected!.id);
      }
    } catch (e) {
      formError = e.toString();
      update();
    } finally {
      saving = false;
      update();
    }
  }

  Future<void> completeAction() async {
    final id = selected?.id;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.completeQcResultAction(id);
      actionMessage = response.message;
      _refreshController.notifyChanged(source: 'qc_result_action');
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  Future<void> cancelAction() async {
    final id = selected?.id;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.cancelQcResultAction(id);
      actionMessage = response.message;
      _refreshController.notifyChanged(source: 'qc_result_action');
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  Future<void> deleteAction() async {
    final id = selected?.id;
    if (id == null) {
      return;
    }
    try {
      await _service.deleteQcResultAction(id);
      actionMessage = 'Result action deleted.';
      _refreshController.notifyChanged(source: 'qc_result_action');
      await load();
    } catch (e) {
      formError = e.toString();
      update();
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    actionQtyController.dispose();
    remarksController.dispose();
    referenceDocTypeController.dispose();
    referenceDocIdController.dispose();
    super.onClose();
  }
}
