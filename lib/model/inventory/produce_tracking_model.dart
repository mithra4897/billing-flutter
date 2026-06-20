import '../../screen.dart';

class ProduceTrackingModel extends JsonModel {
  const ProduceTrackingModel({
    super.id,
    this.companyId,
    this.branchId,
    this.locationId,
    this.financialYearId,
    this.documentSeriesId,
    this.trackingNo,
    this.trackingDate,
    this.referenceFlow,
    this.salesDeliveryId,
    this.purchaseOrderId,
    this.sourceWarehouseId,
    this.destinationType,
    this.destinationPartyId,
    this.destinationWarehouseId,
    this.destinationLocation,
    this.destinationAddress,
    this.assignedToName,
    this.referenceDocumentLabel,
    this.transporterPartyId,
    this.transporterId,
    this.transporterName,
    this.transporterDeliveryMode,
    this.vehicleNo,
    this.driverName,
    this.driverPhone,
    this.lrNo,
    this.lrDate,
    this.trackingStatus,
    this.currentLocation,
    this.currentLatitude,
    this.currentLongitude,
    this.lastLocationUpdateAt,
    this.remarks,
    this.postedBy,
    this.postedAt,
    this.isActive,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  final int? companyId;
  final int? branchId;
  final int? locationId;
  final int? financialYearId;
  final int? documentSeriesId;
  final String? trackingNo;
  final String? trackingDate;
  final String? referenceFlow;
  final int? salesDeliveryId;
  final int? purchaseOrderId;
  final int? sourceWarehouseId;
  final String? destinationType;
  final int? destinationPartyId;
  final int? destinationWarehouseId;
  final String? destinationLocation;
  final String? destinationAddress;
  final String? assignedToName;
  final String? referenceDocumentLabel;
  final int? transporterPartyId;
  final int? transporterId;
  final String? transporterName;
  final String? transporterDeliveryMode;
  final String? vehicleNo;
  final String? driverName;
  final String? driverPhone;
  final String? lrNo;
  final String? lrDate;
  final String? trackingStatus;
  final String? currentLocation;
  final double? currentLatitude;
  final double? currentLongitude;
  final String? lastLocationUpdateAt;
  final String? remarks;
  final int? postedBy;
  final String? postedAt;
  final bool? isActive;
  final int? createdBy;
  final int? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  factory ProduceTrackingModel.fromJson(Map<String, dynamic> json) {
    return ProduceTrackingModel(
      id: JsonModel.nullableInt(json['id']),
      companyId: JsonModel.nullableInt(json['company_id']),
      branchId: JsonModel.nullableInt(json['branch_id']),
      locationId: JsonModel.nullableInt(json['location_id']),
      financialYearId: JsonModel.nullableInt(json['financial_year_id']),
      documentSeriesId: JsonModel.nullableInt(json['document_series_id']),
      trackingNo: json['tracking_no']?.toString(),
      trackingDate: json['tracking_date']?.toString(),
      referenceFlow: json['reference_flow']?.toString(),
      salesDeliveryId: JsonModel.nullableInt(json['sales_delivery_id']),
      purchaseOrderId: JsonModel.nullableInt(json['purchase_order_id']),
      sourceWarehouseId: JsonModel.nullableInt(json['source_warehouse_id']),
      destinationType: json['destination_type']?.toString(),
      destinationPartyId: JsonModel.nullableInt(json['destination_party_id']),
      destinationWarehouseId: JsonModel.nullableInt(
        json['destination_warehouse_id'],
      ),
      destinationLocation: json['destination_location']?.toString(),
      destinationAddress: json['destination_address']?.toString(),
      assignedToName:
          (json['destination_party'] as Map<String, dynamic>?)?['party_name']
              ?.toString(),
      referenceDocumentLabel: _referenceDocumentLabel(json),
      transporterPartyId: JsonModel.nullableInt(json['transporter_party_id']),
      transporterId: JsonModel.nullableInt(json['transporter_id']),
      transporterName:
          (json['transporter_master'] as Map<String, dynamic>?)?['name']
              ?.toString(),
      transporterDeliveryMode:
          (json['transporter_master'] as Map<String, dynamic>?)?['delivery_mode']
              ?.toString(),
      vehicleNo: json['vehicle_no']?.toString(),
      driverName: json['driver_name']?.toString(),
      driverPhone: json['driver_phone']?.toString(),
      lrNo: json['lr_no']?.toString(),
      lrDate: json['lr_date']?.toString(),
      trackingStatus: json['tracking_status']?.toString(),
      currentLocation: json['current_location']?.toString(),
      currentLatitude: JsonModel.nullableDouble(json['current_latitude']),
      currentLongitude: JsonModel.nullableDouble(json['current_longitude']),
      lastLocationUpdateAt: json['last_location_update_at']?.toString(),
      remarks: json['remarks']?.toString(),
      postedBy: JsonModel.nullableInt(json['posted_by']),
      postedAt: json['posted_at']?.toString(),
      isActive: json['is_active'] == null
          ? null
          : JsonModel.boolOf(json['is_active']),
      createdBy: JsonModel.nullableInt(json['created_by']),
      updatedBy: JsonModel.nullableInt(json['updated_by']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  @override
  String toString() => JsonModel.combineValues(
    [trackingNo, trackingDate, trackingStatus],
    defaultValue: 'Produce Tracking',
  );

  @override
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (companyId != null) 'company_id': companyId,
    if (branchId != null) 'branch_id': branchId,
    if (locationId != null) 'location_id': locationId,
    if (financialYearId != null) 'financial_year_id': financialYearId,
    if (documentSeriesId != null) 'document_series_id': documentSeriesId,
    if (trackingNo != null) 'tracking_no': trackingNo,
    if (trackingDate != null) 'tracking_date': trackingDate,
    if (referenceFlow != null) 'reference_flow': referenceFlow,
    if (salesDeliveryId != null) 'sales_delivery_id': salesDeliveryId,
    if (purchaseOrderId != null) 'purchase_order_id': purchaseOrderId,
    if (sourceWarehouseId != null) 'source_warehouse_id': sourceWarehouseId,
    if (destinationType != null) 'destination_type': destinationType,
    if (destinationPartyId != null) 'destination_party_id': destinationPartyId,
    if (destinationWarehouseId != null)
      'destination_warehouse_id': destinationWarehouseId,
    if (destinationLocation != null) 'destination_location': destinationLocation,
    if (destinationAddress != null) 'destination_address': destinationAddress,
    if (assignedToName != null) 'assigned_to_name': assignedToName,
    if (referenceDocumentLabel != null)
      'reference_document_label': referenceDocumentLabel,
    if (transporterPartyId != null) 'transporter_party_id': transporterPartyId,
    if (transporterId != null) 'transporter_id': transporterId,
    if (transporterName != null) 'transporter_name': transporterName,
    if (transporterDeliveryMode != null)
      'transporter_delivery_mode': transporterDeliveryMode,
    if (vehicleNo != null) 'vehicle_no': vehicleNo,
    if (driverName != null) 'driver_name': driverName,
    if (driverPhone != null) 'driver_phone': driverPhone,
    if (lrNo != null) 'lr_no': lrNo,
    if (lrDate != null) 'lr_date': lrDate,
    if (trackingStatus != null) 'tracking_status': trackingStatus,
    if (currentLocation != null) 'current_location': currentLocation,
    if (currentLatitude != null) 'current_latitude': currentLatitude,
    if (currentLongitude != null) 'current_longitude': currentLongitude,
    if (lastLocationUpdateAt != null)
      'last_location_update_at': lastLocationUpdateAt,
    if (remarks != null) 'remarks': remarks,
    if (postedBy != null) 'posted_by': postedBy,
    if (postedAt != null) 'posted_at': postedAt,
    if (isActive != null) 'is_active': isActive,
    if (createdBy != null) 'created_by': createdBy,
    if (updatedBy != null) 'updated_by': updatedBy,
    if (createdAt != null) 'created_at': createdAt,
    if (updatedAt != null) 'updated_at': updatedAt,
  };

  static String? _referenceDocumentLabel(Map<String, dynamic> json) {
    final salesDelivery = json['sales_delivery'] as Map<String, dynamic>?;
    if (salesDelivery != null) {
      final no = salesDelivery['delivery_no']?.toString();
      if (no != null && no.trim().isNotEmpty) {
        return no;
      }
    }

    final purchaseOrder = json['purchase_order'] as Map<String, dynamic>?;
    if (purchaseOrder != null) {
      final no = purchaseOrder['order_no']?.toString();
      if (no != null && no.trim().isNotEmpty) {
        return no;
      }
    }

    return null;
  }
}
