import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/common/erp_record_model.dart';
import '../base/erp_module_service.dart';

class PartiesService extends ErpModuleService {
  PartiesService({super.apiClient});

  Future<PaginatedResponse<ErpRecordModel>> partyTypes({
    Map<String, dynamic>? filters,
  }) => index('/masters/party-types', filters: filters);
  Future<ApiResponse<ErpRecordModel>> partyType(int id) =>
      show('/masters/party-types/$id');
  Future<ApiResponse<ErpRecordModel>> createPartyType(ErpRecordModel body) =>
      store('/masters/party-types', body);
  Future<ApiResponse<ErpRecordModel>> updatePartyType(
    int id,
    ErpRecordModel body,
  ) => update('/masters/party-types/$id', body);
  Future<ApiResponse<ErpRecordModel>> changePartyTypeStatus(
    int id,
    ErpRecordModel body,
  ) => patch('/masters/party-types/$id/status', body);

  Future<PaginatedResponse<ErpRecordModel>> parties({
    Map<String, dynamic>? filters,
  }) => index('/masters/parties', filters: filters);
  Future<ApiResponse<ErpRecordModel>> party(int id) =>
      show('/masters/parties/$id');
  Future<ApiResponse<ErpRecordModel>> createParty(ErpRecordModel body) =>
      store('/masters/parties', body);
  Future<ApiResponse<ErpRecordModel>> updateParty(
    int id,
    ErpRecordModel body,
  ) => update('/masters/parties/$id', body);
  Future<ApiResponse<ErpRecordModel>> togglePartyStatus(
    int id,
    ErpRecordModel body,
  ) => patch('/masters/parties/$id/toggle-status', body);

  Future<PaginatedResponse<ErpRecordModel>> partyAddresses(
    int partyId, {
    Map<String, dynamic>? filters,
  }) => index('/masters/parties/$partyId/addresses', filters: filters);
  Future<ApiResponse<ErpRecordModel>> partyAddress(int partyId, int id) =>
      show('/masters/parties/$partyId/addresses/$id');
  Future<ApiResponse<ErpRecordModel>> createPartyAddress(
    int partyId,
    ErpRecordModel body,
  ) => store('/masters/parties/$partyId/addresses', body);
  Future<ApiResponse<ErpRecordModel>> updatePartyAddress(
    int partyId,
    int id,
    ErpRecordModel body,
  ) => update('/masters/parties/$partyId/addresses/$id', body);
  Future<ApiResponse<ErpRecordModel>> changePartyAddressStatus(
    int partyId,
    int id,
    ErpRecordModel body,
  ) => patch('/masters/parties/$partyId/addresses/$id/status', body);

  Future<PaginatedResponse<ErpRecordModel>> partyContacts(
    int partyId, {
    Map<String, dynamic>? filters,
  }) => index('/masters/parties/$partyId/contacts', filters: filters);
  Future<ApiResponse<ErpRecordModel>> partyContact(int partyId, int id) =>
      show('/masters/parties/$partyId/contacts/$id');
  Future<ApiResponse<ErpRecordModel>> createPartyContact(
    int partyId,
    ErpRecordModel body,
  ) => store('/masters/parties/$partyId/contacts', body);
  Future<ApiResponse<ErpRecordModel>> updatePartyContact(
    int partyId,
    int id,
    ErpRecordModel body,
  ) => update('/masters/parties/$partyId/contacts/$id', body);
  Future<ApiResponse<ErpRecordModel>> changePartyContactStatus(
    int partyId,
    int id,
    ErpRecordModel body,
  ) => patch('/masters/parties/$partyId/contacts/$id/status', body);

  Future<PaginatedResponse<ErpRecordModel>> partyGstDetails(
    int partyId, {
    Map<String, dynamic>? filters,
  }) => index('/masters/parties/$partyId/gst-details', filters: filters);
  Future<ApiResponse<ErpRecordModel>> partyGstDetail(int partyId, int id) =>
      show('/masters/parties/$partyId/gst-details/$id');
  Future<ApiResponse<ErpRecordModel>> createPartyGstDetail(
    int partyId,
    ErpRecordModel body,
  ) => store('/masters/parties/$partyId/gst-details', body);
  Future<ApiResponse<ErpRecordModel>> updatePartyGstDetail(
    int partyId,
    int id,
    ErpRecordModel body,
  ) => update('/masters/parties/$partyId/gst-details/$id', body);
  Future<ApiResponse<ErpRecordModel>> changePartyGstDetailStatus(
    int partyId,
    int id,
    ErpRecordModel body,
  ) => patch('/masters/parties/$partyId/gst-details/$id/status', body);

  Future<PaginatedResponse<ErpRecordModel>> partyBankAccounts(
    int partyId, {
    Map<String, dynamic>? filters,
  }) => index('/masters/parties/$partyId/bank-accounts', filters: filters);
  Future<ApiResponse<ErpRecordModel>> partyBankAccount(int partyId, int id) =>
      show('/masters/parties/$partyId/bank-accounts/$id');
  Future<ApiResponse<ErpRecordModel>> createPartyBankAccount(
    int partyId,
    ErpRecordModel body,
  ) => store('/masters/parties/$partyId/bank-accounts', body);
  Future<ApiResponse<ErpRecordModel>> updatePartyBankAccount(
    int partyId,
    int id,
    ErpRecordModel body,
  ) => update('/masters/parties/$partyId/bank-accounts/$id', body);
  Future<ApiResponse<ErpRecordModel>> changePartyBankAccountStatus(
    int partyId,
    int id,
    ErpRecordModel body,
  ) => patch('/masters/parties/$partyId/bank-accounts/$id/status', body);

  Future<PaginatedResponse<ErpRecordModel>> partyCreditLimits(
    int partyId, {
    Map<String, dynamic>? filters,
  }) => index('/masters/parties/$partyId/credit-limits', filters: filters);
  Future<ApiResponse<ErpRecordModel>> partyCreditLimit(int partyId, int id) =>
      show('/masters/parties/$partyId/credit-limits/$id');
  Future<ApiResponse<ErpRecordModel>> createPartyCreditLimit(
    int partyId,
    ErpRecordModel body,
  ) => store('/masters/parties/$partyId/credit-limits', body);
  Future<ApiResponse<ErpRecordModel>> updatePartyCreditLimit(
    int partyId,
    int id,
    ErpRecordModel body,
  ) => update('/masters/parties/$partyId/credit-limits/$id', body);
  Future<ApiResponse<ErpRecordModel>> changePartyCreditLimitStatus(
    int partyId,
    int id,
    ErpRecordModel body,
  ) => patch('/masters/parties/$partyId/credit-limits/$id/status', body);

  Future<PaginatedResponse<ErpRecordModel>> partyPaymentTerms(
    int partyId, {
    Map<String, dynamic>? filters,
  }) => index('/masters/parties/$partyId/payment-terms', filters: filters);
  Future<ApiResponse<ErpRecordModel>> partyPaymentTerm(int partyId, int id) =>
      show('/masters/parties/$partyId/payment-terms/$id');
  Future<ApiResponse<ErpRecordModel>> createPartyPaymentTerm(
    int partyId,
    ErpRecordModel body,
  ) => store('/masters/parties/$partyId/payment-terms', body);
  Future<ApiResponse<ErpRecordModel>> updatePartyPaymentTerm(
    int partyId,
    int id,
    ErpRecordModel body,
  ) => update('/masters/parties/$partyId/payment-terms/$id', body);
  Future<ApiResponse<ErpRecordModel>> changePartyPaymentTermStatus(
    int partyId,
    int id,
    ErpRecordModel body,
  ) => patch('/masters/parties/$partyId/payment-terms/$id/status', body);
}
