import '../../screen.dart';

class QcInspectionLineModel extends JsonModel {
  const QcInspectionLineModel({
    super.id,
    this.qcInspectionId,
    this.qcPlanLineId,
    this.lineNo,
    this.checkpointName,
    this.checkpointType,
    this.expectedValue,
    this.actualValue,
    this.measuredValue,
    this.toleranceMin,
    this.toleranceMax,
    this.resultStatus,
    this.isCritical,
    this.isMandatory,
    this.remarks,
    this.createdAt,
    this.updatedAt,
  });
  final int? qcInspectionId;
  final int? qcPlanLineId;
  final int? lineNo;
  final String? checkpointName;
  final String? checkpointType;
  final String? expectedValue;
  final String? actualValue;
  final double? measuredValue;
  final double? toleranceMin;
  final double? toleranceMax;
  final String? resultStatus;
  final bool? isCritical;
  final bool? isMandatory;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;

  factory QcInspectionLineModel.fromJson(Map<String, dynamic> json) {
    return QcInspectionLineModel(
      id: JsonModel.nullableInt(json['id']),
      qcInspectionId: JsonModel.nullableInt(json['qc_inspection_id']),
      qcPlanLineId: JsonModel.nullableInt(json['qc_plan_line_id']),
      lineNo: JsonModel.nullableInt(json['line_no']),
      checkpointName: json['checkpoint_name']?.toString(),
      checkpointType: json['checkpoint_type']?.toString(),
      expectedValue: json['expected_value']?.toString(),
      actualValue: json['actual_value']?.toString(),
      measuredValue: JsonModel.nullableDouble(json['measured_value']),
      toleranceMin: JsonModel.nullableDouble(json['tolerance_min']),
      toleranceMax: JsonModel.nullableDouble(json['tolerance_max']),
      resultStatus: json['result_status']?.toString(),
      isCritical: json['is_critical'] == null
          ? null
          : JsonModel.boolOf(json['is_critical']),
      isMandatory: json['is_mandatory'] == null
          ? null
          : JsonModel.boolOf(json['is_mandatory']),
      remarks: json['remarks']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Qc Inspection Line';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (qcInspectionId != null) 'qc_inspection_id': qcInspectionId,
    if (qcPlanLineId != null) 'qc_plan_line_id': qcPlanLineId,
    if (lineNo != null) 'line_no': lineNo,
    if (checkpointName != null) 'checkpoint_name': checkpointName,
    if (checkpointType != null) 'checkpoint_type': checkpointType,
    if (expectedValue != null) 'expected_value': expectedValue,
    if (actualValue != null) 'actual_value': actualValue,
    if (measuredValue != null) 'measured_value': measuredValue,
    if (toleranceMin != null) 'tolerance_min': toleranceMin,
    if (toleranceMax != null) 'tolerance_max': toleranceMax,
    if (resultStatus != null) 'result_status': resultStatus,
    if (isCritical != null) 'is_critical': isCritical,
    if (isMandatory != null) 'is_mandatory': isMandatory,
    if (remarks != null) 'remarks': remarks,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
