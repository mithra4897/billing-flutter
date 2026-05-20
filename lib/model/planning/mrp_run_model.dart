import '../../screen.dart';

class MrpRunModel extends JsonModel {
  const MrpRunModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.warehouseId,
    this.planningCalendarId,
    this.runNo,
    this.runDate,
    this.planningStartDate,
    this.planningEndDate,
    this.runScope,
    this.runMode,
    this.runStatus,
    this.totalItemsProcessed,
    this.totalShortageItems,
    this.totalRecommendations,
    this.notes,
    this.errorMessage,
    this.createdBy,
    this.completedBy,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });
  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? warehouseId;
  final int? planningCalendarId;
  final String? runNo;
  final String? runDate;
  final String? planningStartDate;
  final String? planningEndDate;
  final String? runScope;
  final String? runMode;
  final String? runStatus;
  final int? totalItemsProcessed;
  final int? totalShortageItems;
  final int? totalRecommendations;
  final String? notes;
  final String? errorMessage;
  final int? createdBy;
  final int? completedBy;
  final String? completedAt;
  final String? createdAt;
  final String? updatedAt;

  factory MrpRunModel.fromJson(Map<String, dynamic> json) {
    return MrpRunModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      branchId: JsonModel.nullableInt(json['branch_id']),
      locationId: JsonModel.nullableInt(json['location_id']),
      warehouseId: JsonModel.nullableInt(json['warehouse_id']),
      planningCalendarId: JsonModel.nullableInt(json['planning_calendar_id']),
      runNo: json['run_no']?.toString(),
      runDate: json['run_date']?.toString(),
      planningStartDate: json['planning_start_date']?.toString(),
      planningEndDate: json['planning_end_date']?.toString(),
      runScope: json['run_scope']?.toString(),
      runMode: json['run_mode']?.toString(),
      runStatus: json['run_status']?.toString(),
      totalItemsProcessed: JsonModel.nullableInt(
        json['total_items_processed'],
      ),
      totalShortageItems: JsonModel.nullableInt(json['total_shortage_items']),
      totalRecommendations: JsonModel.nullableInt(
        json['total_recommendations'],
      ),
      notes: json['notes']?.toString(),
      errorMessage: json['error_message']?.toString(),
      createdBy: JsonModel.nullableInt(json['created_by']),
      completedBy: JsonModel.nullableInt(json['completed_by']),
      completedAt: json['completed_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => JsonModel.combineValues([
    runNo,
    runDate,
    planningStartDate,
  ], defaultValue: 'MRP Run');


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (planningCalendarId != null) 'planning_calendar_id': planningCalendarId,
    if (runNo != null) 'run_no': runNo,
    if (runDate != null) 'run_date': runDate,
    if (planningStartDate != null) 'planning_start_date': planningStartDate,
    if (planningEndDate != null) 'planning_end_date': planningEndDate,
    if (runScope != null) 'run_scope': runScope,
    if (runMode != null) 'run_mode': runMode,
    if (runStatus != null) 'run_status': runStatus,
    if (totalItemsProcessed != null)
      'total_items_processed': totalItemsProcessed,
    if (totalShortageItems != null) 'total_shortage_items': totalShortageItems,
    if (totalRecommendations != null)
      'total_recommendations': totalRecommendations,
    if (notes != null) 'notes': notes,
    if (errorMessage != null) 'error_message': errorMessage,
    if (createdBy != null) 'created_by': createdBy,
    if (completedBy != null) 'completed_by': completedBy,
    if (completedAt != null) 'completed_at': completedAt,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
