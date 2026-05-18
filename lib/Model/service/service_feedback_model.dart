import '../../screen.dart';

class ServiceFeedbackModel implements JsonModel {
  const ServiceFeedbackModel({
    this.id,
    this.serviceTicketId,
    this.serviceWorkOrderId,
    this.feedbackDate,
    this.ratingOverall,
    this.ratingTechnician,
    this.ratingResolution,
    this.ratingTimeliness,
    this.customerFeedback,
    this.resolutionConfirmed,
    this.revisitRequired,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    Map<String, dynamic>? raw,
  }) : _raw = raw;

  final int? id;
  final int? serviceTicketId;
  final int? serviceWorkOrderId;
  final String? feedbackDate;
  final String? ratingOverall;
  final String? ratingTechnician;
  final String? ratingResolution;
  final String? ratingTimeliness;
  final String? customerFeedback;
  final bool? resolutionConfirmed;
  final bool? revisitRequired;
  final int? createdBy;
  final String? createdAt;
  final String? updatedAt;

  factory ServiceFeedbackModel.fromJson(Map<String, dynamic> json) {
    return ServiceFeedbackModel(
      id: ModelValue.nullableInt(json['id']),
      serviceTicketId: ModelValue.nullableInt(json['service_ticket_id']),
      serviceWorkOrderId: ModelValue.nullableInt(json['service_work_order_id']),
      feedbackDate: json['feedback_date']?.toString(),
      ratingOverall: json['rating_overall']?.toString(),
      ratingTechnician: json['rating_technician']?.toString(),
      ratingResolution: json['rating_resolution']?.toString(),
      ratingTimeliness: json['rating_timeliness']?.toString(),
      customerFeedback: json['customer_feedback']?.toString(),
      resolutionConfirmed: json['resolution_confirmed'] == null
          ? null
          : ModelValue.boolOf(json['resolution_confirmed']),
      revisitRequired: json['revisit_required'] == null
          ? null
          : ModelValue.boolOf(json['revisit_required']),
      createdBy: ModelValue.nullableInt(json['created_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (serviceTicketId != null) 'service_ticket_id': serviceTicketId,
    if (serviceWorkOrderId != null) 'service_work_order_id': serviceWorkOrderId,
    if (feedbackDate != null) 'feedback_date': feedbackDate,
    if (ratingOverall != null) 'rating_overall': ratingOverall,
    if (ratingTechnician != null) 'rating_technician': ratingTechnician,
    if (ratingResolution != null) 'rating_resolution': ratingResolution,
    if (ratingTimeliness != null) 'rating_timeliness': ratingTimeliness,
    if (customerFeedback != null) 'customer_feedback': customerFeedback,
    if (resolutionConfirmed != null)
      'resolution_confirmed': resolutionConfirmed,
    if (revisitRequired != null) 'revisit_required': revisitRequired,
    if (createdBy != null) 'created_by': createdBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };
}
