import '../../screen.dart';

class MaintenancePlanModel implements JsonModel {
  const MaintenancePlanModel({
    this.id,
    this.companyId,
    this.planCode,
    this.planName,
    this.maintenanceType,
    this.scheduleBasis,
    this.frequencyValue,
    this.checklistNotes,
    this.isAutoGenerateRequest,
    this.isActive,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    Map<String, dynamic>? raw,
  }) : _raw = raw;

  final int? id;
  final int? companyId;
  final String? planCode;
  final String? planName;
  final String? maintenanceType;
  final String? scheduleBasis;
  final String? frequencyValue;
  final String? checklistNotes;
  final bool? isAutoGenerateRequest;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory MaintenancePlanModel.fromJson(Map<String, dynamic> json) {
    return MaintenancePlanModel(
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      planCode: json['plan_code']?.toString(),
      planName: json['plan_name']?.toString(),
      maintenanceType: json['maintenance_type']?.toString(),
      scheduleBasis: json['schedule_basis']?.toString(),
      frequencyValue: json['frequency_value']?.toString(),
      checklistNotes: json['checklist_notes']?.toString(),
      isAutoGenerateRequest: json['is_auto_generate_request'] == null
          ? null
          : ModelValue.boolOf(json['is_auto_generate_request']),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      createdBy: ModelValue.nullableInt(json['created_by']),
      updatedBy: ModelValue.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (planCode != null) 'plan_code': planCode,
    if (planName != null) 'plan_name': planName,
    if (maintenanceType != null) 'maintenance_type': maintenanceType,
    if (scheduleBasis != null) 'schedule_basis': scheduleBasis,
    if (frequencyValue != null) 'frequency_value': frequencyValue,
    if (checklistNotes != null) 'checklist_notes': checklistNotes,
    if (isAutoGenerateRequest != null)
      'is_auto_generate_request': isAutoGenerateRequest,
    if (isActive != null) 'is_active': isActive,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
