import '../common/json_model.dart';

class CrmEnquiryLineModel implements JsonModel {
  const CrmEnquiryLineModel(this.data);

  final Map<String, dynamic> data;

  factory CrmEnquiryLineModel.fromJson(Map<String, dynamic> json) {
    return CrmEnquiryLineModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
