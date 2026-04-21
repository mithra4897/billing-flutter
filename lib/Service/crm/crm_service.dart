import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/crm/crm_enquiry_model.dart';
import '../../model/crm/crm_lead_model.dart';
import '../../model/crm/crm_opportunity_model.dart';
import '../../model/crm/crm_source_model.dart';
import '../../model/crm/crm_stage_model.dart';
import '../base/erp_module_service.dart';

class CrmService extends ErpModuleService {
  CrmService({super.apiClient});

  Future<PaginatedResponse<CrmSourceModel>> sources({
    Map<String, dynamic>? filters,
  }) => paginated<CrmSourceModel>(
    '/crm/sources',
    filters: filters,
    fromJson: CrmSourceModel.fromJson,
  );
  Future<ApiResponse<CrmSourceModel>> source(int id) => object<CrmSourceModel>(
    '/crm/sources/$id',
    fromJson: CrmSourceModel.fromJson,
  );
  Future<ApiResponse<CrmSourceModel>> createSource(CrmSourceModel body) =>
      createModel<CrmSourceModel>(
        '/crm/sources',
        body,
        fromJson: CrmSourceModel.fromJson,
      );
  Future<ApiResponse<CrmSourceModel>> updateSource(
    int id,
    CrmSourceModel body,
  ) => updateModel<CrmSourceModel>(
    '/crm/sources/$id',
    body,
    fromJson: CrmSourceModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteSource(int id) =>
      destroy('/crm/sources/$id');

  Future<PaginatedResponse<CrmStageModel>> stages({
    Map<String, dynamic>? filters,
  }) => paginated<CrmStageModel>(
    '/crm/stages',
    filters: filters,
    fromJson: CrmStageModel.fromJson,
  );
  Future<ApiResponse<CrmStageModel>> stage(int id) => object<CrmStageModel>(
    '/crm/stages/$id',
    fromJson: CrmStageModel.fromJson,
  );
  Future<ApiResponse<CrmStageModel>> createStage(CrmStageModel body) =>
      createModel<CrmStageModel>(
        '/crm/stages',
        body,
        fromJson: CrmStageModel.fromJson,
      );
  Future<ApiResponse<CrmStageModel>> updateStage(int id, CrmStageModel body) =>
      updateModel<CrmStageModel>(
        '/crm/stages/$id',
        body,
        fromJson: CrmStageModel.fromJson,
      );
  Future<ApiResponse<dynamic>> deleteStage(int id) =>
      destroy('/crm/stages/$id');

  Future<PaginatedResponse<CrmLeadModel>> leads({
    Map<String, dynamic>? filters,
  }) => paginated<CrmLeadModel>(
    '/crm/leads',
    filters: filters,
    fromJson: CrmLeadModel.fromJson,
  );
  Future<ApiResponse<CrmLeadModel>> lead(int id) =>
      object<CrmLeadModel>('/crm/leads/$id', fromJson: CrmLeadModel.fromJson);
  Future<ApiResponse<CrmLeadModel>> createLead(CrmLeadModel body) =>
      createModel<CrmLeadModel>(
        '/crm/leads',
        body,
        fromJson: CrmLeadModel.fromJson,
      );
  Future<ApiResponse<CrmLeadModel>> updateLead(int id, CrmLeadModel body) =>
      updateModel<CrmLeadModel>(
        '/crm/leads/$id',
        body,
        fromJson: CrmLeadModel.fromJson,
      );
  /// Backend returns `{ lead, enquiry? }`. Use [createEnquiry] to start a sales enquiry in one step.
  Future<ApiResponse<Map<String, dynamic>>> convertLead(
    int id, {
    bool createEnquiry = true,
  }) {
    return client.post<Map<String, dynamic>>(
      '/crm/leads/$id/convert',
      body: <String, dynamic>{'create_enquiry': createEnquiry},
      fromData: (dynamic json) {
        if (json is Map<String, dynamic>) {
          return json;
        }
        if (json is Map) {
          return Map<String, dynamic>.from(json);
        }
        return <String, dynamic>{};
      },
    );
  }
  Future<ApiResponse<dynamic>> deleteLead(int id) => destroy('/crm/leads/$id');

  Future<PaginatedResponse<CrmEnquiryModel>> enquiries({
    Map<String, dynamic>? filters,
  }) => paginated<CrmEnquiryModel>(
    '/crm/enquiries',
    filters: filters,
    fromJson: CrmEnquiryModel.fromJson,
  );
  Future<ApiResponse<CrmEnquiryModel>> enquiry(int id) =>
      object<CrmEnquiryModel>(
        '/crm/enquiries/$id',
        fromJson: CrmEnquiryModel.fromJson,
      );
  Future<ApiResponse<CrmEnquiryModel>> createEnquiry(CrmEnquiryModel body) =>
      createModel<CrmEnquiryModel>(
        '/crm/enquiries',
        body,
        fromJson: CrmEnquiryModel.fromJson,
      );
  Future<ApiResponse<CrmEnquiryModel>> updateEnquiry(
    int id,
    CrmEnquiryModel body,
  ) => updateModel<CrmEnquiryModel>(
    '/crm/enquiries/$id',
    body,
    fromJson: CrmEnquiryModel.fromJson,
  );
  /// Backend returns `{ enquiry, opportunity? }` when an opportunity is created from the enquiry.
  Future<ApiResponse<Map<String, dynamic>>> convertEnquiry(int id) {
    return client.post<Map<String, dynamic>>(
      '/crm/enquiries/$id/convert',
      body: <String, dynamic>{},
      fromData: (dynamic json) {
        if (json is Map<String, dynamic>) {
          return json;
        }
        if (json is Map) {
          return Map<String, dynamic>.from(json);
        }
        return <String, dynamic>{};
      },
    );
  }
  Future<ApiResponse<CrmEnquiryModel>> loseEnquiry(
    int id,
    CrmEnquiryModel body,
  ) => actionModel<CrmEnquiryModel>(
    '/crm/enquiries/$id/lose',
    body: body,
    fromJson: CrmEnquiryModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteEnquiry(int id) =>
      destroy('/crm/enquiries/$id');

  Future<PaginatedResponse<CrmOpportunityModel>> opportunities({
    Map<String, dynamic>? filters,
  }) => paginated<CrmOpportunityModel>(
    '/crm/opportunities',
    filters: filters,
    fromJson: CrmOpportunityModel.fromJson,
  );
  Future<ApiResponse<CrmOpportunityModel>> opportunity(int id) =>
      object<CrmOpportunityModel>(
        '/crm/opportunities/$id',
        fromJson: CrmOpportunityModel.fromJson,
      );
  Future<ApiResponse<CrmOpportunityModel>> createOpportunity(
    CrmOpportunityModel body,
  ) => createModel<CrmOpportunityModel>(
    '/crm/opportunities',
    body,
    fromJson: CrmOpportunityModel.fromJson,
  );
  Future<ApiResponse<CrmOpportunityModel>> updateOpportunity(
    int id,
    CrmOpportunityModel body,
  ) => updateModel<CrmOpportunityModel>(
    '/crm/opportunities/$id',
    body,
    fromJson: CrmOpportunityModel.fromJson,
  );
  Future<ApiResponse<CrmOpportunityModel>> winOpportunity(
    int id,
    CrmOpportunityModel body,
  ) => actionModel<CrmOpportunityModel>(
    '/crm/opportunities/$id/win',
    body: body,
    fromJson: CrmOpportunityModel.fromJson,
  );
  Future<ApiResponse<CrmOpportunityModel>> loseOpportunity(
    int id,
    CrmOpportunityModel body,
  ) => actionModel<CrmOpportunityModel>(
    '/crm/opportunities/$id/lose',
    body: body,
    fromJson: CrmOpportunityModel.fromJson,
  );
  Future<ApiResponse<dynamic>> deleteOpportunity(int id) =>
      destroy('/crm/opportunities/$id');
}
