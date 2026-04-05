import '../common/json_model.dart';

class VoucherTypeModel implements JsonModel {
  const VoucherTypeModel(this.data);

  final Map<String, dynamic> data;

  factory VoucherTypeModel.fromJson(Map<String, dynamic> json) {
    return VoucherTypeModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
