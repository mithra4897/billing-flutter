import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/masters/state_model.dart';
import '../../model/tax/document_tax_line_model.dart';
import '../../model/tax/gst_place_of_supply_rule_model.dart';
import '../../model/tax/gst_registration_model.dart';
import '../../model/tax/gst_tax_rule_model.dart';
import '../base/erp_module_service.dart';

class TaxesService extends ErpModuleService {
  TaxesService({super.apiClient});

  Future<PaginatedResponse<StateModel>> states({
    Map<String, dynamic>? filters,
  }) =>
      paginated('/tax/states', filters: filters, fromJson: StateModel.fromJson);

  Future<ApiResponse<List<StateModel>>> statesAll({
    Map<String, dynamic>? filters,
  }) => collection(
    '/tax/states/all',
    filters: filters,
    fromJson: StateModel.fromJson,
  );

  Future<ApiResponse<StateModel>> state(int id) =>
      object('/tax/states/$id', fromJson: StateModel.fromJson);

  Future<ApiResponse<StateModel>> createState(StateModel body) =>
      createModel('/tax/states', body, fromJson: StateModel.fromJson);

  Future<ApiResponse<StateModel>> updateState(int id, StateModel body) =>
      updateModel('/tax/states/$id', body, fromJson: StateModel.fromJson);

  Future<ApiResponse<dynamic>> deleteState(int id) =>
      destroy('/tax/states/$id');

  Future<PaginatedResponse<GstRegistrationModel>> gstRegistrations({
    Map<String, dynamic>? filters,
  }) => paginated(
    '/tax/gst-registrations',
    filters: filters,
    fromJson: GstRegistrationModel.fromJson,
  );

  Future<ApiResponse<List<GstRegistrationModel>>> gstRegistrationsAll({
    Map<String, dynamic>? filters,
  }) => collection(
    '/tax/gst-registrations/all',
    filters: filters,
    fromJson: GstRegistrationModel.fromJson,
  );

  Future<ApiResponse<GstRegistrationModel>> gstRegistration(int id) => object(
    '/tax/gst-registrations/$id',
    fromJson: GstRegistrationModel.fromJson,
  );

  Future<ApiResponse<GstRegistrationModel>> createGstRegistration(
    GstRegistrationModel body,
  ) => createModel(
    '/tax/gst-registrations',
    body,
    fromJson: GstRegistrationModel.fromJson,
  );

  Future<ApiResponse<GstRegistrationModel>> updateGstRegistration(
    int id,
    GstRegistrationModel body,
  ) => updateModel(
    '/tax/gst-registrations/$id',
    body,
    fromJson: GstRegistrationModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deleteGstRegistration(int id) =>
      destroy('/tax/gst-registrations/$id');

  Future<PaginatedResponse<GstPlaceOfSupplyRuleModel>> placeOfSupplyRules({
    Map<String, dynamic>? filters,
  }) => paginated(
    '/tax/place-of-supply-rules',
    filters: filters,
    fromJson: GstPlaceOfSupplyRuleModel.fromJson,
  );

  Future<ApiResponse<List<GstPlaceOfSupplyRuleModel>>> placeOfSupplyRulesAll({
    Map<String, dynamic>? filters,
  }) => collection(
    '/tax/place-of-supply-rules/all',
    filters: filters,
    fromJson: GstPlaceOfSupplyRuleModel.fromJson,
  );

  Future<ApiResponse<GstPlaceOfSupplyRuleModel>> placeOfSupplyRule(int id) =>
      object(
        '/tax/place-of-supply-rules/$id',
        fromJson: GstPlaceOfSupplyRuleModel.fromJson,
      );

  Future<ApiResponse<GstPlaceOfSupplyRuleModel>> createPlaceOfSupplyRule(
    GstPlaceOfSupplyRuleModel body,
  ) => createModel(
    '/tax/place-of-supply-rules',
    body,
    fromJson: GstPlaceOfSupplyRuleModel.fromJson,
  );

  Future<ApiResponse<GstPlaceOfSupplyRuleModel>> updatePlaceOfSupplyRule(
    int id,
    GstPlaceOfSupplyRuleModel body,
  ) => updateModel(
    '/tax/place-of-supply-rules/$id',
    body,
    fromJson: GstPlaceOfSupplyRuleModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deletePlaceOfSupplyRule(int id) =>
      destroy('/tax/place-of-supply-rules/$id');

  Future<PaginatedResponse<GstTaxRuleModel>> gstTaxRules({
    Map<String, dynamic>? filters,
  }) => paginated(
    '/tax/gst-tax-rules',
    filters: filters,
    fromJson: GstTaxRuleModel.fromJson,
  );

  Future<ApiResponse<List<GstTaxRuleModel>>> gstTaxRulesAll({
    Map<String, dynamic>? filters,
  }) => collection(
    '/tax/gst-tax-rules/all',
    filters: filters,
    fromJson: GstTaxRuleModel.fromJson,
  );

  Future<ApiResponse<GstTaxRuleModel>> gstTaxRule(int id) =>
      object('/tax/gst-tax-rules/$id', fromJson: GstTaxRuleModel.fromJson);

  Future<ApiResponse<GstTaxRuleModel>> createGstTaxRule(GstTaxRuleModel body) =>
      createModel(
        '/tax/gst-tax-rules',
        body,
        fromJson: GstTaxRuleModel.fromJson,
      );

  Future<ApiResponse<GstTaxRuleModel>> updateGstTaxRule(
    int id,
    GstTaxRuleModel body,
  ) => updateModel(
    '/tax/gst-tax-rules/$id',
    body,
    fromJson: GstTaxRuleModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deleteGstTaxRule(int id) =>
      destroy('/tax/gst-tax-rules/$id');

  Future<PaginatedResponse<DocumentTaxLineModel>> documentTaxLines({
    Map<String, dynamic>? filters,
  }) => paginated(
    '/tax/document-tax-lines',
    filters: filters,
    fromJson: DocumentTaxLineModel.fromJson,
  );

  Future<ApiResponse<List<DocumentTaxLineModel>>> documentTaxLinesAll({
    Map<String, dynamic>? filters,
  }) => collection(
    '/tax/document-tax-lines/all',
    filters: filters,
    fromJson: DocumentTaxLineModel.fromJson,
  );

  Future<ApiResponse<DocumentTaxLineModel>> documentTaxLine(int id) => object(
    '/tax/document-tax-lines/$id',
    fromJson: DocumentTaxLineModel.fromJson,
  );

  Future<ApiResponse<DocumentTaxLineModel>> createDocumentTaxLine(
    DocumentTaxLineModel body,
  ) => createModel(
    '/tax/document-tax-lines',
    body,
    fromJson: DocumentTaxLineModel.fromJson,
  );

  Future<ApiResponse<DocumentTaxLineModel>> updateDocumentTaxLine(
    int id,
    DocumentTaxLineModel body,
  ) => updateModel(
    '/tax/document-tax-lines/$id',
    body,
    fromJson: DocumentTaxLineModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deleteDocumentTaxLine(int id) =>
      destroy('/tax/document-tax-lines/$id');
}
