import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/crm/crm_enquiry_model.dart';
import '../../model/crm/crm_followup_model.dart';
import '../../model/crm/crm_lead_model.dart';
import '../../model/crm/crm_opportunity_model.dart';
import '../../model/crm/crm_source_model.dart';
import '../../model/crm/crm_stage_model.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/error/api_exception.dart';
import '../base/erp_module_service.dart';

class CrmService extends ErpModuleService {
  CrmService({super.apiClient});

  Future<PaginatedResponse<CrmSourceModel>> sources({
    Map<String, dynamic>? filters,
  }) => paginated<CrmSourceModel>(
    ApiEndpoints.crmSources,
    filters: filters,
    fromJson: CrmSourceModel.fromJson,
  );

  Future<ApiResponse<CrmSourceModel>> source(int id) => object<CrmSourceModel>(
    '${ApiEndpoints.crmSources}/$id',
    fromJson: CrmSourceModel.fromJson,
  );

  Future<ApiResponse<CrmSourceModel>> createSource(CrmSourceModel body) =>
      createModel<CrmSourceModel>(
        ApiEndpoints.crmSources,
        body,
        fromJson: CrmSourceModel.fromJson,
      );

  Future<ApiResponse<CrmSourceModel>> updateSource(
    int id,
    CrmSourceModel body,
  ) => updateModel<CrmSourceModel>(
    '${ApiEndpoints.crmSources}/$id',
    body,
    fromJson: CrmSourceModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deleteSource(int id) =>
      destroy('${ApiEndpoints.crmSources}/$id');

  Future<PaginatedResponse<CrmStageModel>> stages({
    Map<String, dynamic>? filters,
  }) => paginated<CrmStageModel>(
    ApiEndpoints.crmStages,
    filters: filters,
    fromJson: CrmStageModel.fromJson,
  );

  Future<ApiResponse<CrmStageModel>> stage(int id) => object<CrmStageModel>(
    '${ApiEndpoints.crmStages}/$id',
    fromJson: CrmStageModel.fromJson,
  );

  Future<ApiResponse<CrmStageModel>> createStage(CrmStageModel body) =>
      createModel<CrmStageModel>(
        ApiEndpoints.crmStages,
        body,
        fromJson: CrmStageModel.fromJson,
      );

  Future<ApiResponse<CrmStageModel>> updateStage(int id, CrmStageModel body) =>
      updateModel<CrmStageModel>(
        '${ApiEndpoints.crmStages}/$id',
        body,
        fromJson: CrmStageModel.fromJson,
      );

  Future<ApiResponse<dynamic>> deleteStage(int id) =>
      destroy('${ApiEndpoints.crmStages}/$id');

  Future<PaginatedResponse<CrmLeadModel>> leads({
    Map<String, dynamic>? filters,
  }) => paginated<CrmLeadModel>(
    ApiEndpoints.crmLeads,
    filters: filters,
    fromJson: CrmLeadModel.fromJson,
  );

  Future<ApiResponse<CrmLeadModel>> lead(int id) => object<CrmLeadModel>(
    '${ApiEndpoints.crmLeads}/$id',
    fromJson: CrmLeadModel.fromJson,
  );

  Future<ApiResponse<CrmLeadModel>> createLead(CrmLeadModel body) =>
      createModel<CrmLeadModel>(
        ApiEndpoints.crmLeads,
        body,
        fromJson: CrmLeadModel.fromJson,
      );

  Future<ApiResponse<CrmLeadModel>> updateLead(int id, CrmLeadModel body) =>
      updateModel<CrmLeadModel>(
        '${ApiEndpoints.crmLeads}/$id',
        body,
        fromJson: CrmLeadModel.fromJson,
      );

  /// Backend returns `{ lead, enquiry? }`. Use [createEnquiry] to start a sales enquiry in one step.
  Future<ApiResponse<Map<String, dynamic>>> convertLead(
    int id, {
    bool createEnquiry = true,
  }) {
    return client.post<Map<String, dynamic>>(
      '${ApiEndpoints.crmLeads}/$id/convert',
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

  Future<ApiResponse<dynamic>> deleteLead(int id) =>
      destroy('${ApiEndpoints.crmLeads}/$id');

  Future<PaginatedResponse<CrmEnquiryModel>> enquiries({
    Map<String, dynamic>? filters,
  }) => paginated<CrmEnquiryModel>(
    ApiEndpoints.crmEnquiries,
    filters: filters,
    fromJson: CrmEnquiryModel.fromJson,
  );

  Future<ApiResponse<CrmEnquiryModel>> enquiry(int id) =>
      object<CrmEnquiryModel>(
        '${ApiEndpoints.crmEnquiries}/$id',
        fromJson: CrmEnquiryModel.fromJson,
      );

  Future<ApiResponse<List<CrmFollowupModel>>> pendingFollowups() =>
      collection<CrmFollowupModel>(
        ApiEndpoints.crmPendingFollowups,
        fromJson: CrmFollowupModel.fromJson,
      );

  Future<ApiResponse<CrmEnquiryModel>> createEnquiry(CrmEnquiryModel body) =>
      createModel<CrmEnquiryModel>(
        ApiEndpoints.crmEnquiries,
        body,
        fromJson: CrmEnquiryModel.fromJson,
      );

  Future<ApiResponse<CrmEnquiryModel>> updateEnquiry(
    int id,
    CrmEnquiryModel body,
  ) => updateModel<CrmEnquiryModel>(
    '${ApiEndpoints.crmEnquiries}/$id',
    body,
    fromJson: CrmEnquiryModel.fromJson,
  );

  /// Backend returns `{ enquiry, opportunity? }` when an opportunity is created from the enquiry.
  Future<ApiResponse<Map<String, dynamic>>> convertEnquiry(int id) {
    return client.post<Map<String, dynamic>>(
      '${ApiEndpoints.crmEnquiries}/$id/convert',
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
    '${ApiEndpoints.crmEnquiries}/$id/lose',
    body: body,
    fromJson: CrmEnquiryModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deleteEnquiry(int id) =>
      destroy('${ApiEndpoints.crmEnquiries}/$id');

  Future<PaginatedResponse<CrmOpportunityModel>> opportunities({
    Map<String, dynamic>? filters,
  }) => paginated<CrmOpportunityModel>(
    ApiEndpoints.crmOpportunities,
    filters: filters,
    fromJson: CrmOpportunityModel.fromJson,
  );

  Future<ApiResponse<CrmOpportunityModel>> opportunity(int id) =>
      object<CrmOpportunityModel>(
        '${ApiEndpoints.crmOpportunities}/$id',
        fromJson: CrmOpportunityModel.fromJson,
      );

  Future<ApiResponse<CrmOpportunityModel>> createOpportunity(
    CrmOpportunityModel body,
  ) => createModel<CrmOpportunityModel>(
    ApiEndpoints.crmOpportunities,
    body,
    fromJson: CrmOpportunityModel.fromJson,
  );

  Future<ApiResponse<CrmOpportunityModel>> updateOpportunity(
    int id,
    CrmOpportunityModel body,
  ) => updateModel<CrmOpportunityModel>(
    '${ApiEndpoints.crmOpportunities}/$id',
    body,
    fromJson: CrmOpportunityModel.fromJson,
  );

  Future<ApiResponse<CrmOpportunityModel>> winOpportunity(
    int id,
    CrmOpportunityModel body,
  ) => actionModel<CrmOpportunityModel>(
    '${ApiEndpoints.crmOpportunities}/$id/win',
    body: body,
    fromJson: CrmOpportunityModel.fromJson,
  );

  Future<ApiResponse<CrmOpportunityModel>> loseOpportunity(
    int id,
    CrmOpportunityModel body,
  ) => actionModel<CrmOpportunityModel>(
    '${ApiEndpoints.crmOpportunities}/$id/lose',
    body: body,
    fromJson: CrmOpportunityModel.fromJson,
  );

  Future<ApiResponse<dynamic>> deleteOpportunity(int id) =>
      destroy('${ApiEndpoints.crmOpportunities}/$id');

  /// Resolves lead → enquiry → opportunity → quotations → orders → invoices → receipts.
  /// Uses CRM route when permitted; falls back to [ApiEndpoints.salesSalesChain] for sales-only users.
  Future<ApiResponse<Map<String, dynamic>>> salesChain({
    int? leadId,
    int? enquiryId,
    int? opportunityId,
    int? quotationId,
    int? orderId,
    int? invoiceId,
    int? receiptId,
  }) async {
    final query = <String, dynamic>{
      'lead_id': ?leadId,
      'enquiry_id': ?enquiryId,
      'opportunity_id': ?opportunityId,
      'quotation_id': ?quotationId,
      'order_id': ?orderId,
      'invoice_id': ?invoiceId,
      'receipt_id': ?receiptId,
    };

    Future<ApiResponse<Map<String, dynamic>>> fetch(String endpoint) {
      return client.get<Map<String, dynamic>>(
        endpoint,
        queryParameters: query,
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

    try {
      return await fetch(ApiEndpoints.crmSalesChain);
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        return fetch(ApiEndpoints.salesSalesChain);
      }
      rethrow;
    }
  }
}
