import '../../screen.dart';

class TransporterModel extends JsonModel {
  const TransporterModel({
    super.id,
    this.name,
    this.transporterType,
    this.deliveryMode,
    this.isActive = true,
    this.remarks,
  });

  final String? name;
  final String? transporterType;
  final String? deliveryMode;
  final bool isActive;
  final String? remarks;

  String get deliveryModeLabel {
    switch (deliveryMode) {
      case 'direct_delivery':
        return 'Direct Delivery';
      case 'pickup':
        return 'Pickup';
      default:
        return deliveryMode ?? '';
    }
  }

  String get transporterTypeLabel {
    switch (transporterType) {
      case 'courier':
        return 'Courier';
      case 'third_party':
        return 'Third Party';
      case 'own_vehicle':
        return 'Own Vehicle';
      case 'customer_pickup':
        return 'Customer Pickup';
      case 'supplier_delivery':
        return 'Supplier Delivery';
      default:
        return transporterType ?? '';
    }
  }

  @override
  String toString() => name ?? 'Transporter';

  factory TransporterModel.fromJson(Map<String, dynamic> json) {
    return TransporterModel(
      id: JsonModel.nullableInt(json['id']),
      name: json['name']?.toString(),
      transporterType: json['transporter_type']?.toString(),
      deliveryMode: json['delivery_mode']?.toString(),
      isActive: json['is_active'] != false && json['is_active'] != 0,
      remarks: json['remarks']?.toString(),
    );
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    if (id != null) 'id': id,
    if (name != null) 'name': name,
    if (transporterType != null) 'transporter_type': transporterType,
    if (deliveryMode != null) 'delivery_mode': deliveryMode,
    if (remarks != null) 'remarks': remarks,
    'is_active': isActive,
  };
}
