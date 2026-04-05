import '../common/json_model.dart';

class SalesReceiptAllocationModel implements JsonModel {
  const SalesReceiptAllocationModel(this.data);

  final Map<String, dynamic> data;

  factory SalesReceiptAllocationModel.fromJson(Map<String, dynamic> json) {
    return SalesReceiptAllocationModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
