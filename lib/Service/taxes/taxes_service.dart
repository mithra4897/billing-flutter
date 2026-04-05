import '../base/erp_module_service.dart';

class TaxesService extends ErpModuleService {
  TaxesService({super.apiClient});

  Future states({Map<String, dynamic>? filters}) =>
      index('/tax/states', filters: filters);
  Future statesAll({Map<String, dynamic>? filters}) =>
      list('/tax/states/all', filters: filters);
  Future state(int id) => show('/tax/states/$id');
  Future createState(Map<String, dynamic> body) => store('/tax/states', body);
  Future updateState(int id, Map<String, dynamic> body) =>
      update('/tax/states/$id', body);
  Future deleteState(int id) => destroy('/tax/states/$id');

  Future gstRegistrations({Map<String, dynamic>? filters}) =>
      index('/tax/gst-registrations', filters: filters);
  Future gstRegistrationsAll({Map<String, dynamic>? filters}) =>
      list('/tax/gst-registrations/all', filters: filters);
  Future gstRegistration(int id) => show('/tax/gst-registrations/$id');
  Future createGstRegistration(Map<String, dynamic> body) =>
      store('/tax/gst-registrations', body);
  Future updateGstRegistration(int id, Map<String, dynamic> body) =>
      update('/tax/gst-registrations/$id', body);
  Future deleteGstRegistration(int id) => destroy('/tax/gst-registrations/$id');

  Future placeOfSupplyRules({Map<String, dynamic>? filters}) =>
      index('/tax/place-of-supply-rules', filters: filters);
  Future placeOfSupplyRulesAll({Map<String, dynamic>? filters}) =>
      list('/tax/place-of-supply-rules/all', filters: filters);
  Future placeOfSupplyRule(int id) => show('/tax/place-of-supply-rules/$id');
  Future createPlaceOfSupplyRule(Map<String, dynamic> body) =>
      store('/tax/place-of-supply-rules', body);
  Future updatePlaceOfSupplyRule(int id, Map<String, dynamic> body) =>
      update('/tax/place-of-supply-rules/$id', body);
  Future deletePlaceOfSupplyRule(int id) =>
      destroy('/tax/place-of-supply-rules/$id');

  Future gstTaxRules({Map<String, dynamic>? filters}) =>
      index('/tax/gst-tax-rules', filters: filters);
  Future gstTaxRulesAll({Map<String, dynamic>? filters}) =>
      list('/tax/gst-tax-rules/all', filters: filters);
  Future gstTaxRule(int id) => show('/tax/gst-tax-rules/$id');
  Future createGstTaxRule(Map<String, dynamic> body) =>
      store('/tax/gst-tax-rules', body);
  Future updateGstTaxRule(int id, Map<String, dynamic> body) =>
      update('/tax/gst-tax-rules/$id', body);
  Future deleteGstTaxRule(int id) => destroy('/tax/gst-tax-rules/$id');

  Future documentTaxLines({Map<String, dynamic>? filters}) =>
      index('/tax/document-tax-lines', filters: filters);
  Future documentTaxLinesAll({Map<String, dynamic>? filters}) =>
      list('/tax/document-tax-lines/all', filters: filters);
  Future documentTaxLine(int id) => show('/tax/document-tax-lines/$id');
  Future createDocumentTaxLine(Map<String, dynamic> body) =>
      store('/tax/document-tax-lines', body);
  Future updateDocumentTaxLine(int id, Map<String, dynamic> body) =>
      update('/tax/document-tax-lines/$id', body);
  Future deleteDocumentTaxLine(int id) =>
      destroy('/tax/document-tax-lines/$id');
}
