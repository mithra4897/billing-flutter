import '../common/json_model.dart';

class CrmEnquiryModel implements JsonModel {
  const CrmEnquiryModel(this.data);

  final Map<String, dynamic> data;

  factory CrmEnquiryModel.fromJson(Map<String, dynamic> json) {
    return CrmEnquiryModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
