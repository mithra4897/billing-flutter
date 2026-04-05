import '../common/json_model.dart';

class ServiceTicketModel implements JsonModel {
  const ServiceTicketModel(this.data);

  final Map<String, dynamic> data;

  factory ServiceTicketModel.fromJson(Map<String, dynamic> json) {
    return ServiceTicketModel(json);
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
