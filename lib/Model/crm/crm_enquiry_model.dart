import '../common/json_model.dart';

class CrmEnquiryModel implements JsonModel {
  const CrmEnquiryModel(this.data);

  final Map<String, dynamic> data;

  factory CrmEnquiryModel.fromJson(Map<String, dynamic> json) {
    return CrmEnquiryModel(json);
  }

  @override
  String toString() {
    final no = data['enquiry_no']?.toString().trim() ?? '';
    if (no.isNotEmpty) {
      return no;
    }

    final customer = data['customer_name']?.toString().trim() ?? '';
    if (customer.isNotEmpty) {
      return customer;
    }

    final lead = data['lead_name']?.toString().trim() ?? '';
    if (lead.isNotEmpty) {
      return lead;
    }

    final id = data['id']?.toString().trim() ?? '';
    if (id.isNotEmpty) {
      return 'Enquiry #$id';
    }

    return 'New Enquiry';
  }

  @override
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}
