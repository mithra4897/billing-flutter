import '../common/json_model.dart';

class VoucherAllocationModel implements JsonModel {
  const VoucherAllocationModel(this.data);

  final Map<String, dynamic> data;

  factory VoucherAllocationModel.fromJson(Map<String, dynamic> json) {
    return VoucherAllocationModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
