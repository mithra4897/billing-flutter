import '../base/erp_module_service.dart';

class CrmService extends ErpModuleService {
  CrmService({super.apiClient});

  Future sources({Map<String, dynamic>? filters}) =>
      index('/crm/sources', filters: filters);
  Future source(int id) => show('/crm/sources/$id');
  Future createSource(Map<String, dynamic> body) => store('/crm/sources', body);
  Future updateSource(int id, Map<String, dynamic> body) =>
      update('/crm/sources/$id', body);
  Future deleteSource(int id) => destroy('/crm/sources/$id');

  Future stages({Map<String, dynamic>? filters}) =>
      index('/crm/stages', filters: filters);
  Future stage(int id) => show('/crm/stages/$id');
  Future createStage(Map<String, dynamic> body) => store('/crm/stages', body);
  Future updateStage(int id, Map<String, dynamic> body) =>
      update('/crm/stages/$id', body);
  Future deleteStage(int id) => destroy('/crm/stages/$id');

  Future leads({Map<String, dynamic>? filters}) =>
      index('/crm/leads', filters: filters);
  Future lead(int id) => show('/crm/leads/$id');
  Future createLead(Map<String, dynamic> body) => store('/crm/leads', body);
  Future updateLead(int id, Map<String, dynamic> body) =>
      update('/crm/leads/$id', body);
  Future convertLead(int id, Map<String, dynamic> body) =>
      action('/crm/leads/$id/convert', body: body);
  Future deleteLead(int id) => destroy('/crm/leads/$id');

  Future enquiries({Map<String, dynamic>? filters}) =>
      index('/crm/enquiries', filters: filters);
  Future enquiry(int id) => show('/crm/enquiries/$id');
  Future createEnquiry(Map<String, dynamic> body) =>
      store('/crm/enquiries', body);
  Future updateEnquiry(int id, Map<String, dynamic> body) =>
      update('/crm/enquiries/$id', body);
  Future convertEnquiry(int id, Map<String, dynamic> body) =>
      action('/crm/enquiries/$id/convert', body: body);
  Future loseEnquiry(int id, Map<String, dynamic> body) =>
      action('/crm/enquiries/$id/lose', body: body);
  Future deleteEnquiry(int id) => destroy('/crm/enquiries/$id');

  Future opportunities({Map<String, dynamic>? filters}) =>
      index('/crm/opportunities', filters: filters);
  Future opportunity(int id) => show('/crm/opportunities/$id');
  Future createOpportunity(Map<String, dynamic> body) =>
      store('/crm/opportunities', body);
  Future updateOpportunity(int id, Map<String, dynamic> body) =>
      update('/crm/opportunities/$id', body);
  Future winOpportunity(int id, Map<String, dynamic> body) =>
      action('/crm/opportunities/$id/win', body: body);
  Future loseOpportunity(int id, Map<String, dynamic> body) =>
      action('/crm/opportunities/$id/lose', body: body);
  Future deleteOpportunity(int id) => destroy('/crm/opportunities/$id');
}
