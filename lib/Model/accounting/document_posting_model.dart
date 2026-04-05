import '../common/json_model.dart';

class DocumentPostingModel implements JsonModel {
  const DocumentPostingModel(this.data);

  final Map<String, dynamic> data;

  factory DocumentPostingModel.fromJson(Map<String, dynamic> json) {
    return DocumentPostingModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
