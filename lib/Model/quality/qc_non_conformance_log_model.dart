import '../common/json_model.dart';

class QcNonConformanceLogModel implements JsonModel {
  const QcNonConformanceLogModel({
    this.id,
    this.qcInspectionId,
    this.qcInspectionLineId,
    this.defectCode,
    this.defectName = '',
    this.severity,
    this.defectQty = 0,
    this.rootCause,
    this.correctiveAction,
    this.preventiveAction,
    this.assignedTo,
    this.dueDate,
    this.closureStatus = 'open',
    this.closedBy,
    this.closedAt,
    this.remarks,
    this.rawInspection,
  });

  final int? id;
  final int? qcInspectionId;
  final int? qcInspectionLineId;
  final String? defectCode;
  final String defectName;
  final String? severity;
  final double defectQty;
  final String? rootCause;
  final String? correctiveAction;
  final String? preventiveAction;
  final int? assignedTo;
  final String? dueDate;
  final String closureStatus;
  final int? closedBy;
  final String? closedAt;
  final String? remarks;
  final Map<String, dynamic>? rawInspection;

  factory QcNonConformanceLogModel.fromJson(Map<String, dynamic> json) {
    return QcNonConformanceLogModel(
      id: _i(json['id']),
      qcInspectionId: _i(json['qc_inspection_id']),
      qcInspectionLineId: _i(json['qc_inspection_line_id']),
      defectCode: json['defect_code']?.toString(),
      defectName: json['defect_name']?.toString() ?? '',
      severity: json['severity']?.toString(),
      defectQty: _d(json['defect_qty']) ?? 0,
      rootCause: json['root_cause']?.toString(),
      correctiveAction: json['corrective_action']?.toString(),
      preventiveAction: json['preventive_action']?.toString(),
      assignedTo: _i(json['assigned_to']),
      dueDate: _date(json['due_date']),
      closureStatus: json['closure_status']?.toString() ?? 'open',
      closedBy: _i(json['closed_by']),
      closedAt: json['closed_at']?.toString(),
      remarks: json['remarks']?.toString(),
      rawInspection: json['inspection'] is Map
          ? Map<String, dynamic>.from(json['inspection'] as Map)
          : null,
    );
  }

  int? get inspectionCompanyId => _i(rawInspection?['company_id']);

  String get inspectionNoLabel {
    final m = rawInspection;
    if (m == null) {
      return '';
    }
    return m['inspection_no']?.toString().trim() ?? '';
  }

  Map<String, dynamic> toDocumentPayload() => <String, dynamic>{
    'qc_inspection_id': qcInspectionId,
    if (qcInspectionLineId != null)
      'qc_inspection_line_id': qcInspectionLineId,
    if (defectCode != null && defectCode!.trim().isNotEmpty)
      'defect_code': defectCode!.trim(),
    'defect_name': defectName.trim(),
    if (severity != null && severity!.trim().isNotEmpty)
      'severity': severity!.trim(),
    'defect_qty': defectQty,
    if (rootCause != null && rootCause!.trim().isNotEmpty)
      'root_cause': rootCause!.trim(),
    if (correctiveAction != null && correctiveAction!.trim().isNotEmpty)
      'corrective_action': correctiveAction!.trim(),
    if (preventiveAction != null && preventiveAction!.trim().isNotEmpty)
      'preventive_action': preventiveAction!.trim(),
    if (assignedTo != null) 'assigned_to': assignedTo,
    if (dueDate != null && dueDate!.trim().isNotEmpty)
      'due_date': dueDate!.trim(),
    if (closureStatus.isNotEmpty) 'closure_status': closureStatus,
    if (remarks != null && remarks!.trim().isNotEmpty)
      'remarks': remarks!.trim(),
  };

  @override
  Map<String, dynamic> toJson() => toDocumentPayload();

  @override
  String toString() =>
      defectName.trim().isNotEmpty ? defectName.trim() : 'Non-conformance';

  static int? _i(dynamic v) {
    if (v == null) {
      return null;
    }
    if (v is int) {
      return v;
    }
    return int.tryParse(v.toString());
  }

  static double? _d(dynamic v) {
    if (v == null) {
      return null;
    }
    if (v is num) {
      return v.toDouble();
    }
    return double.tryParse(v.toString());
  }

  static String? _date(dynamic v) {
    if (v == null) {
      return null;
    }
    return v.toString().trim().split('T').first.split(' ').first;
  }
}
