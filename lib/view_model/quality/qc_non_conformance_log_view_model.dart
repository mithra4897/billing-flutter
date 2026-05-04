import 'package:billing/screen.dart';

class QcNcLineOption {
  QcNcLineOption({
    required this.id,
    required this.lineNo,
    required this.checkpointName,
  });

  final int id;
  final int lineNo;
  final String checkpointName;

  String get label =>
      'Line $lineNo · ${checkpointName.isNotEmpty ? checkpointName : 'Checkpoint'}';
}

class QcNonConformanceLogViewModel extends ChangeNotifier {
  QcNonConformanceLogViewModel() {
    searchController.addListener(notifyListeners);
  }

  final QualityService _service = QualityService();

  final TextEditingController searchController = TextEditingController();
  final TextEditingController defectCodeController = TextEditingController();
  final TextEditingController defectNameController = TextEditingController();
  final TextEditingController severityController = TextEditingController();
  final TextEditingController defectQtyController = TextEditingController();
  final TextEditingController rootCauseController = TextEditingController();
  final TextEditingController correctiveActionController =
      TextEditingController();
  final TextEditingController preventiveActionController =
      TextEditingController();
  final TextEditingController assignedToController = TextEditingController();
  final TextEditingController dueDateController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();

  bool loading = true;
  bool detailLoading = false;
  bool saving = false;
  String? pageError;
  String? formError;
  String? actionMessage;

  List<QcNonConformanceLogModel> rows = const <QcNonConformanceLogModel>[];
  List<QcInspectionModel> inspections = const <QcInspectionModel>[];

  QcNonConformanceLogModel? selected;

  int? qcInspectionId;
  int? qcInspectionLineId;

  List<QcNcLineOption> inspectionLineOptions = const <QcNcLineOption>[];

  String get closureStatus => selected?.closureStatus ?? 'open';

  bool get canEdit =>
      selected == null ||
      (closureStatus != 'closed' && closureStatus != 'waived');

  bool get canClose =>
      selected != null &&
      closureStatus != 'closed' &&
      closureStatus != 'waived';

  bool get canWaive =>
      selected != null &&
      closureStatus != 'closed' &&
      closureStatus != 'waived';

  bool get canDelete => canEdit;

  List<QcNonConformanceLogModel> get filteredRows {
    final q = searchController.text.trim().toLowerCase();
    return rows.where((row) {
      if (q.isEmpty) {
        return true;
      }
      return [
        row.defectName,
        row.defectCode ?? '',
        row.severity ?? '',
        row.closureStatus,
        row.inspectionNoLabel,
      ].join(' ').toLowerCase().contains(q);
    }).toList(growable: false);
  }

  String? consumeActionMessage() {
    final message = actionMessage;
    actionMessage = null;
    return message;
  }

  Future<void> _loadInspectionLines(
    int? inspectionId, {
    bool clearSelectedLine = true,
  }) async {
    inspectionLineOptions = const <QcNcLineOption>[];
    if (clearSelectedLine) {
      qcInspectionLineId = null;
    }
    if (inspectionId == null) {
      notifyListeners();
      return;
    }
    try {
      final response = await _service.qcInspection(inspectionId);
      final data = response.data?.toJson() ?? const <String, dynamic>{};
      final ln = data['lines'];
      if (ln is List) {
        final opts = <QcNcLineOption>[];
        for (final raw in ln) {
          if (raw is! Map) {
            continue;
          }
          final e = Map<String, dynamic>.from(raw);
          final lid = int.tryParse(e['id']?.toString() ?? '') ?? 0;
          if (lid <= 0) {
            continue;
          }
          opts.add(
            QcNcLineOption(
              id: lid,
              lineNo: int.tryParse(e['line_no']?.toString() ?? '') ?? 0,
              checkpointName: e['checkpoint_name']?.toString() ?? '',
            ),
          );
        }
        inspectionLineOptions = opts;
      }
    } catch (_) {
      inspectionLineOptions = const <QcNcLineOption>[];
    }
    notifyListeners();
  }

  Future<void> load({int? selectId}) async {
    loading = true;
    pageError = null;
    notifyListeners();
    try {
      final responses = await Future.wait<dynamic>([
        _service.qcNonConformanceLogs(
          filters: const {'per_page': 200, 'sort_by': 'id'},
        ),
        _service.qcInspections(filters: const {'per_page': 400}),
      ]);
      rows =
          (responses[0] as PaginatedResponse<QcNonConformanceLogModel>).data ??
              const <QcNonConformanceLogModel>[];
      inspections =
          (responses[1] as PaginatedResponse<QcInspectionModel>).data ??
              const <QcInspectionModel>[];

      loading = false;

      if (selectId != null) {
        QcNonConformanceLogModel? match;
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
      }
      await resetDraft();
      notifyListeners();
    } catch (e) {
      pageError = e.toString();
      loading = false;
      notifyListeners();
    }
  }

  Future<void> resetDraft() async {
    selected = null;
    formError = null;
    qcInspectionId = inspections.isNotEmpty
        ? intValue(inspections.first.toJson(), 'id')
        : null;
    qcInspectionLineId = null;
    inspectionLineOptions = const <QcNcLineOption>[];
    defectCodeController.clear();
    defectNameController.clear();
    severityController.clear();
    defectQtyController.text = '1';
    rootCauseController.clear();
    correctiveActionController.clear();
    preventiveActionController.clear();
    assignedToController.clear();
    dueDateController.clear();
    remarksController.clear();
    await _loadInspectionLines(qcInspectionId);
  }

  Future<void> select(QcNonConformanceLogModel row) async {
    final id = row.id;
    if (id == null) {
      return;
    }
    selected = row;
    detailLoading = true;
    formError = null;
    notifyListeners();
    try {
      final response = await _service.qcNonConformanceLog(id);
      final doc = response.data ?? row;
      qcInspectionId = doc.qcInspectionId;
      qcInspectionLineId = doc.qcInspectionLineId;
      defectCodeController.text = doc.defectCode ?? '';
      defectNameController.text = doc.defectName;
      severityController.text = doc.severity ?? '';
      defectQtyController.text = doc.defectQty > 0
          ? doc.defectQty.toString()
          : '1';
      rootCauseController.text = doc.rootCause ?? '';
      correctiveActionController.text = doc.correctiveAction ?? '';
      preventiveActionController.text = doc.preventiveAction ?? '';
      assignedToController.text = doc.assignedTo?.toString() ?? '';
      dueDateController.text = doc.dueDate ?? '';
      remarksController.text = doc.remarks ?? '';
      await _loadInspectionLines(qcInspectionId, clearSelectedLine: false);
      if (qcInspectionLineId != null) {
        final exists =
            inspectionLineOptions.any((o) => o.id == qcInspectionLineId);
        if (!exists) {
          qcInspectionLineId = null;
        }
      }
    } catch (e) {
      formError = e.toString();
    } finally {
      detailLoading = false;
      notifyListeners();
    }
  }

  Future<void> setQcInspectionId(int? value) async {
    if (!canEdit) {
      return;
    }
    qcInspectionId = value;
    qcInspectionLineId = null;
    await _loadInspectionLines(value);
  }

  void setQcInspectionLineId(int? value) {
    if (!canEdit) {
      return;
    }
    qcInspectionLineId = value;
    notifyListeners();
  }

  String? _validate() {
    if (qcInspectionId == null) {
      return 'QC inspection is required.';
    }
    if (defectNameController.text.trim().isEmpty) {
      return 'Defect name is required.';
    }
    final dq = double.tryParse(defectQtyController.text.trim()) ?? 0;
    if (dq <= 0) {
      return 'Defect quantity must be greater than zero.';
    }
    return null;
  }

  QcNonConformanceLogModel _buildDocument() {
    final dq = double.tryParse(defectQtyController.text.trim()) ?? 0;
    final assigned = int.tryParse(assignedToController.text.trim());
    return QcNonConformanceLogModel(
      qcInspectionId: qcInspectionId,
      qcInspectionLineId: qcInspectionLineId,
      defectCode: nullIfEmpty(defectCodeController.text),
      defectName: defectNameController.text.trim(),
      severity: nullIfEmpty(severityController.text),
      defectQty: dq,
      rootCause: nullIfEmpty(rootCauseController.text),
      correctiveAction: nullIfEmpty(correctiveActionController.text),
      preventiveAction: nullIfEmpty(preventiveActionController.text),
      assignedTo: assigned,
      dueDate: nullIfEmpty(dueDateController.text),
      closureStatus: closureStatus,
      remarks: nullIfEmpty(remarksController.text),
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
        final response = await _service.createQcNonConformanceLog(doc);
        actionMessage = response.message;
        await load(selectId: response.data?.id);
      } else {
        final response =
            await _service.updateQcNonConformanceLog(selected!.id!, doc);
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

  Future<void> closeLog() async {
    final id = selected?.id;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.closeQcNonConformanceLog(id);
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> waiveLog() async {
    final id = selected?.id;
    if (id == null) {
      return;
    }
    try {
      final response = await _service.waiveQcNonConformanceLog(id);
      actionMessage = response.message;
      await load(selectId: id);
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteLog() async {
    final id = selected?.id;
    if (id == null) {
      return;
    }
    try {
      await _service.deleteQcNonConformanceLog(id);
      actionMessage = 'Log deleted.';
      await load();
    } catch (e) {
      formError = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    defectCodeController.dispose();
    defectNameController.dispose();
    severityController.dispose();
    defectQtyController.dispose();
    rootCauseController.dispose();
    correctiveActionController.dispose();
    preventiveActionController.dispose();
    assignedToController.dispose();
    dueDateController.dispose();
    remarksController.dispose();
    super.dispose();
  }
}
