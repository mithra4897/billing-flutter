import '../common/json_model.dart';

class DocumentPostingLineModel implements JsonModel {
  const DocumentPostingLineModel(this.data);

  final Map<String, dynamic> data;

  factory DocumentPostingLineModel.fromJson(Map<String, dynamic> json) {
    return DocumentPostingLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
