import '../../screen.dart';

class BomOperationModel implements JsonModel {
  const BomOperationModel(this.data);

  final Map<String, dynamic> data;

  factory BomOperationModel.fromJson(Map<String, dynamic> json) {
    return BomOperationModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
