import '../../screen.dart';

class PlanningCalendarModel implements JsonModel {
  const PlanningCalendarModel({
    this.id,
    this.companyId,
    this.calendarCode,
    this.calendarName,
    this.planningFrequency,
    this.weekStartDay,
    this.isDefault,
    this.isActive,
    this.remarks,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int? companyId;
  final String? calendarCode;
  final String? calendarName;
  final String? planningFrequency;
  final String? weekStartDay;
  final bool? isDefault;
  final bool? isActive;
  final String? remarks;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory PlanningCalendarModel.fromJson(Map<String, dynamic> json) {
    return PlanningCalendarModel(
      id: ModelValue.nullableInt(json['id']),
      companyId: ModelValue.nullableInt(json['company_id']),
      calendarCode: json['calendar_code']?.toString(),
      calendarName: json['calendar_name']?.toString(),
      planningFrequency: json['planning_frequency']?.toString(),
      weekStartDay: json['week_start_day']?.toString(),
      isDefault: json['is_default'] == null
          ? null
          : ModelValue.boolOf(json['is_default']),
      isActive: json['is_active'] == null
          ? null
          : ModelValue.boolOf(json['is_active']),
      remarks: json['remarks']?.toString(),
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
    if (calendarCode != null) 'calendar_code': calendarCode,
    if (calendarName != null) 'calendar_name': calendarName,
    if (planningFrequency != null) 'planning_frequency': planningFrequency,
    if (weekStartDay != null) 'week_start_day': weekStartDay,
    if (isDefault != null) 'is_default': isDefault,
    if (isActive != null) 'is_active': isActive,
    if (remarks != null) 'remarks': remarks,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
