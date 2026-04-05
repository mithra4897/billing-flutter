import '../common/json_model.dart';

class ServiceTicketActivityModel implements JsonModel {
  const ServiceTicketActivityModel(this.data);

  final Map<String, dynamic> data;

  factory ServiceTicketActivityModel.fromJson(Map<String, dynamic> json) {
    return ServiceTicketActivityModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
