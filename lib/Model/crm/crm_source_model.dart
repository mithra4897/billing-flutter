import '../common/json_model.dart';

class CrmSourceModel implements JsonModel {
  const CrmSourceModel(this.data);

  final Map<String, dynamic> data;

  factory CrmSourceModel.fromJson(Map<String, dynamic> json) {
    return CrmSourceModel(json);
  }

  @override
  String toString() {
    final name = data['source_name']?.toString().trim() ?? '';
    return name.isNotEmpty ? name : 'New Source';
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
