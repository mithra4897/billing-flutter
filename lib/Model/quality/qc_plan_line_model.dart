import '../common/json_model.dart';

class QcPlanLineModel implements JsonModel {
  const QcPlanLineModel({
    this.id,
    this.qcPlanId,
    this.lineNo = 1,
    this.checkpointName = '',
    this.checkpointType = 'visual',
    this.specification,
    this.toleranceMin,
    this.toleranceMax,
    this.expectedText,
    this.unit,
    this.isCritical = false,
    this.isMandatory = true,
    this.sequenceNo = 1,
    this.remarks,
  });

  final int? id;
  final int? qcPlanId;
  final int lineNo;
  final String checkpointName;
  final String checkpointType;
  final String? specification;
  final double? toleranceMin;
  final double? toleranceMax;
  final String? expectedText;
  final String? unit;
  final bool isCritical;
  final bool isMandatory;
  final int sequenceNo;
  final String? remarks;

  factory QcPlanLineModel.fromJson(Map<String, dynamic> json) {
    return QcPlanLineModel(
      id: _i(json['id']),
      qcPlanId: _i(json['qc_plan_id']),
      lineNo: _i(json['line_no']) ?? 1,
      checkpointName: json['checkpoint_name']?.toString() ?? '',
      checkpointType: json['checkpoint_type']?.toString() ?? 'visual',
      specification: json['specification']?.toString(),
      toleranceMin: _d(json['tolerance_min']),
      toleranceMax: _d(json['tolerance_max']),
      expectedText: json['expected_text']?.toString(),
      unit: json['unit']?.toString(),
      isCritical: _b(json['is_critical']),
      isMandatory: json['is_mandatory'] == null ? true : _b(json['is_mandatory']),
      sequenceNo: _i(json['sequence_no']) ?? 1,
      remarks: json['remarks']?.toString(),
    );
  }

  Map<String, dynamic> toLinePayload() => <String, dynamic>{
    'checkpoint_name': checkpointName.trim(),
    'checkpoint_type': checkpointType,
    if (specification != null && specification!.trim().isNotEmpty)
      'specification': specification!.trim(),
    if (toleranceMin != null) 'tolerance_min': toleranceMin,
    if (toleranceMax != null) 'tolerance_max': toleranceMax,
    if (expectedText != null && expectedText!.trim().isNotEmpty)
      'expected_text': expectedText!.trim(),
    if (unit != null && unit!.trim().isNotEmpty) 'unit': unit!.trim(),
    'is_critical': isCritical ? 1 : 0,
    'is_mandatory': isMandatory ? 1 : 0,
    'sequence_no': sequenceNo,
    if (remarks != null && remarks!.trim().isNotEmpty)
      'remarks': remarks!.trim(),
  };

  @override
  Map<String, dynamic> toJson() => toLinePayload();

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

  static bool _b(dynamic v) {
    if (v == null) {
      return false;
    }
    if (v is bool) {
      return v;
    }
    final s = v.toString();
    return s == '1' || s.toLowerCase() == 'true';
  }
}
