import '../../screen.dart';

class ServiceVisitLogModel extends JsonModel {
  const ServiceVisitLogModel({
    super.id,
    this.serviceWorkOrderId,
    this.visitDate,
    this.visitType,
    this.checkInDatetime,
    this.checkOutDatetime,
    this.travelDistanceKm,
    this.travelExpense,
    this.visitNotes,
    this.customerSignatureName,
    this.customerConfirmationStatus,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });
  final int? serviceWorkOrderId;
  final String? visitDate;
  final String? visitType;
  final String? checkInDatetime;
  final String? checkOutDatetime;
  final double? travelDistanceKm;
  final double? travelExpense;
  final String? visitNotes;
  final String? customerSignatureName;
  final String? customerConfirmationStatus;
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;

  factory ServiceVisitLogModel.fromJson(Map<String, dynamic> json) {
    return ServiceVisitLogModel(
      id: JsonModel.nullableInt(json['id']),
      serviceWorkOrderId: JsonModel.nullableInt(json['service_work_order_id']),
      visitDate: json['visit_date']?.toString(),
      visitType: json['visit_type']?.toString(),
      checkInDatetime: json['check_in_datetime']?.toString(),
      checkOutDatetime: json['check_out_datetime']?.toString(),
      travelDistanceKm: JsonModel.nullableDouble(json['travel_distance_km']),
      travelExpense: JsonModel.nullableDouble(json['travel_expense']),
      visitNotes: json['visit_notes']?.toString(),
      customerSignatureName: json['customer_signature_name']?.toString(),
      customerConfirmationStatus: json['customer_confirmation_status']
          ?.toString(),
      createdBy: JsonModel.nullableInt(json['created_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }
  @override
  String toString() => 'Service Visit Log';


  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (serviceWorkOrderId != null) 'service_work_order_id': serviceWorkOrderId,
    if (visitDate != null) 'visit_date': visitDate,
    if (visitType != null) 'visit_type': visitType,
    if (checkInDatetime != null) 'check_in_datetime': checkInDatetime,
    if (checkOutDatetime != null) 'check_out_datetime': checkOutDatetime,
    if (travelDistanceKm != null) 'travel_distance_km': travelDistanceKm,
    if (travelExpense != null) 'travel_expense': travelExpense,
    if (visitNotes != null) 'visit_notes': visitNotes,
    if (customerSignatureName != null)
      'customer_signature_name': customerSignatureName,
    if (customerConfirmationStatus != null)
      'customer_confirmation_status': customerConfirmationStatus,
    if (createdBy != null) 'created_by': createdBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
