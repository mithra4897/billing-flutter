import '../common/json_model.dart';

class QcResultActionModel implements JsonModel {
  const QcResultActionModel({
    this.id,
    this.qcInspectionId,
    this.actionType = '',
    this.actionQty = 0,
    this.targetWarehouseId,
    this.referenceDocumentType,
    this.referenceDocumentId,
    this.actionStatus = 'pending',
    this.actionBy,
    this.actionAt,
    this.remarks,
    this.createdAt,
    this.rawInspection,
  });

  final int? id;
  final int? qcInspectionId;
  final String actionType;
  final double actionQty;
  final int? targetWarehouseId;
  final String? referenceDocumentType;
  final int? referenceDocumentId;
  final String actionStatus;
  final int? actionBy;
  final String? actionAt;
  final String? remarks;
  final String? createdAt;
  final Map<String, dynamic>? rawInspection;

  factory QcResultActionModel.fromJson(Map<String, dynamic> json) {
    return QcResultActionModel(
      id: _i(json['id']),
      qcInspectionId: _i(json['qc_inspection_id']),
      actionType: json['action_type']?.toString() ?? '',
      actionQty: _d(json['action_qty']) ?? 0,
      targetWarehouseId: _i(json['target_warehouse_id']),
      referenceDocumentType: json['reference_document_type']?.toString(),
      referenceDocumentId: _i(json['reference_document_id']),
      actionStatus: json['action_status']?.toString() ?? 'pending',
      actionBy: _i(json['action_by']),
      actionAt: json['action_at']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
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
    'action_type': actionType,
    'action_qty': actionQty,
    if (targetWarehouseId != null) 'target_warehouse_id': targetWarehouseId,
    if (referenceDocumentType != null &&
        referenceDocumentType!.trim().isNotEmpty)
      'reference_document_type': referenceDocumentType!.trim(),
    if (referenceDocumentId != null)
      'reference_document_id': referenceDocumentId,
    if (remarks != null && remarks!.trim().isNotEmpty)
      'remarks': remarks!.trim(),
  };

  @override
  Map<String, dynamic> toJson() => toDocumentPayload();

  @override
  String toString() {
    final n = inspectionNoLabel;
    if (n.isNotEmpty) {
      return '$actionType · $n';
    }
    return actionType.isNotEmpty ? actionType : 'QC result action';
  }

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
}
