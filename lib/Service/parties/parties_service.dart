import '../../core/models/api_response.dart';
import '../../core/models/paginated_response.dart';
import '../../model/masters/party_address_model.dart';
import '../../model/masters/party_bank_account_model.dart';
import '../../model/masters/party_contact_model.dart';
import '../../model/masters/party_credit_limit_model.dart';
import '../../model/masters/party_gst_detail_model.dart';
import '../../model/masters/party_model.dart';
import '../../model/masters/party_payment_term_model.dart';
import '../../model/masters/party_type_model.dart';
import '../base/erp_module_service.dart';

class PartiesService extends ErpModuleService {
  PartiesService({super.apiClient});

  Future<PaginatedResponse<PartyTypeModel>> partyTypes({
    Map<String, dynamic>? filters,
  }) => paginated<PartyTypeModel>(
    '/masters/party-types',
    filters: filters,
    fromJson: PartyTypeModel.fromJson,
  );

  Future<ApiResponse<PartyTypeModel>> partyType(int id) =>
      object<PartyTypeModel>(
        '/masters/party-types/$id',
        fromJson: PartyTypeModel.fromJson,
      );

  Future<ApiResponse<PartyTypeModel>> createPartyType(PartyTypeModel body) =>
      createModel<PartyTypeModel>(
        '/masters/party-types',
        body,
        fromJson: PartyTypeModel.fromJson,
      );

  Future<ApiResponse<PartyTypeModel>> updatePartyType(
    int id,
    PartyTypeModel body,
  ) => updateModel<PartyTypeModel>(
    '/masters/party-types/$id',
    body,
    fromJson: PartyTypeModel.fromJson,
  );

  Future<ApiResponse<PartyTypeModel>> changePartyTypeStatus(
    int id,
    PartyTypeModel body,
  ) => patchModel<PartyTypeModel>(
    '/masters/party-types/$id/status',
    body,
    fromJson: PartyTypeModel.fromJson,
  );

  Future<PaginatedResponse<PartyModel>> parties({
    Map<String, dynamic>? filters,
  }) => paginated<PartyModel>(
    '/masters/parties',
    filters: filters,
    fromJson: PartyModel.fromJson,
  );

  Future<ApiResponse<PartyModel>> party(int id) =>
      object<PartyModel>('/masters/parties/$id', fromJson: PartyModel.fromJson);

  Future<ApiResponse<PartyModel>> createParty(PartyModel body) =>
      createModel<PartyModel>(
        '/masters/parties',
        body,
        fromJson: PartyModel.fromJson,
      );

  Future<ApiResponse<PartyModel>> updateParty(int id, PartyModel body) =>
      updateModel<PartyModel>(
        '/masters/parties/$id',
        body,
        fromJson: PartyModel.fromJson,
      );

  Future<ApiResponse<PartyModel>> togglePartyStatus(int id, PartyModel body) =>
      patchModel<PartyModel>(
        '/masters/parties/$id/toggle-status',
        body,
        fromJson: PartyModel.fromJson,
      );

  Future<PaginatedResponse<PartyAddressModel>> partyAddresses(
    int partyId, {
    Map<String, dynamic>? filters,
  }) => paginated<PartyAddressModel>(
    '/masters/parties/$partyId/addresses',
    filters: filters,
    fromJson: PartyAddressModel.fromJson,
  );

  Future<ApiResponse<PartyAddressModel>> partyAddress(int partyId, int id) =>
      object<PartyAddressModel>(
        '/masters/parties/$partyId/addresses/$id',
        fromJson: PartyAddressModel.fromJson,
      );

  Future<ApiResponse<PartyAddressModel>> createPartyAddress(
    int partyId,
    PartyAddressModel body,
  ) => createModel<PartyAddressModel>(
    '/masters/parties/$partyId/addresses',
    body,
    fromJson: PartyAddressModel.fromJson,
  );

  Future<ApiResponse<PartyAddressModel>> updatePartyAddress(
    int partyId,
    int id,
    PartyAddressModel body,
  ) => updateModel<PartyAddressModel>(
    '/masters/parties/$partyId/addresses/$id',
    body,
    fromJson: PartyAddressModel.fromJson,
  );

  Future<ApiResponse<PartyAddressModel>> changePartyAddressStatus(
    int partyId,
    int id,
    PartyAddressModel body,
  ) => patchModel<PartyAddressModel>(
    '/masters/parties/$partyId/addresses/$id/status',
    body,
    fromJson: PartyAddressModel.fromJson,
  );

  Future<PaginatedResponse<PartyContactModel>> partyContacts(
    int partyId, {
    Map<String, dynamic>? filters,
  }) => paginated<PartyContactModel>(
    '/masters/parties/$partyId/contacts',
    filters: filters,
    fromJson: PartyContactModel.fromJson,
  );

  Future<ApiResponse<PartyContactModel>> partyContact(int partyId, int id) =>
      object<PartyContactModel>(
        '/masters/parties/$partyId/contacts/$id',
        fromJson: PartyContactModel.fromJson,
      );

  Future<ApiResponse<PartyContactModel>> createPartyContact(
    int partyId,
    PartyContactModel body,
  ) => createModel<PartyContactModel>(
    '/masters/parties/$partyId/contacts',
    body,
    fromJson: PartyContactModel.fromJson,
  );

  Future<ApiResponse<PartyContactModel>> updatePartyContact(
    int partyId,
    int id,
    PartyContactModel body,
  ) => updateModel<PartyContactModel>(
    '/masters/parties/$partyId/contacts/$id',
    body,
    fromJson: PartyContactModel.fromJson,
  );

  Future<ApiResponse<PartyContactModel>> changePartyContactStatus(
    int partyId,
    int id,
    PartyContactModel body,
  ) => patchModel<PartyContactModel>(
    '/masters/parties/$partyId/contacts/$id/status',
    body,
    fromJson: PartyContactModel.fromJson,
  );

  Future<PaginatedResponse<PartyGstDetailModel>> partyGstDetails(
    int partyId, {
    Map<String, dynamic>? filters,
  }) => paginated<PartyGstDetailModel>(
    '/masters/parties/$partyId/gst-details',
    filters: filters,
    fromJson: PartyGstDetailModel.fromJson,
  );

  Future<ApiResponse<PartyGstDetailModel>> partyGstDetail(
    int partyId,
    int id,
  ) => object<PartyGstDetailModel>(
    '/masters/parties/$partyId/gst-details/$id',
    fromJson: PartyGstDetailModel.fromJson,
  );

  Future<ApiResponse<PartyGstDetailModel>> createPartyGstDetail(
    int partyId,
    PartyGstDetailModel body,
  ) => createModel<PartyGstDetailModel>(
    '/masters/parties/$partyId/gst-details',
    body,
    fromJson: PartyGstDetailModel.fromJson,
  );

  Future<ApiResponse<PartyGstDetailModel>> updatePartyGstDetail(
    int partyId,
    int id,
    PartyGstDetailModel body,
  ) => updateModel<PartyGstDetailModel>(
    '/masters/parties/$partyId/gst-details/$id',
    body,
    fromJson: PartyGstDetailModel.fromJson,
  );

  Future<ApiResponse<PartyGstDetailModel>> changePartyGstDetailStatus(
    int partyId,
    int id,
    PartyGstDetailModel body,
  ) => patchModel<PartyGstDetailModel>(
    '/masters/parties/$partyId/gst-details/$id/status',
    body,
    fromJson: PartyGstDetailModel.fromJson,
  );

  Future<PaginatedResponse<PartyBankAccountModel>> partyBankAccounts(
    int partyId, {
    Map<String, dynamic>? filters,
  }) => paginated<PartyBankAccountModel>(
    '/masters/parties/$partyId/bank-accounts',
    filters: filters,
    fromJson: PartyBankAccountModel.fromJson,
  );

  Future<ApiResponse<PartyBankAccountModel>> partyBankAccount(
    int partyId,
    int id,
  ) => object<PartyBankAccountModel>(
    '/masters/parties/$partyId/bank-accounts/$id',
    fromJson: PartyBankAccountModel.fromJson,
  );

  Future<ApiResponse<PartyBankAccountModel>> createPartyBankAccount(
    int partyId,
    PartyBankAccountModel body,
  ) => createModel<PartyBankAccountModel>(
    '/masters/parties/$partyId/bank-accounts',
    body,
    fromJson: PartyBankAccountModel.fromJson,
  );

  Future<ApiResponse<PartyBankAccountModel>> updatePartyBankAccount(
    int partyId,
    int id,
    PartyBankAccountModel body,
  ) => updateModel<PartyBankAccountModel>(
    '/masters/parties/$partyId/bank-accounts/$id',
    body,
    fromJson: PartyBankAccountModel.fromJson,
  );

  Future<ApiResponse<PartyBankAccountModel>> changePartyBankAccountStatus(
    int partyId,
    int id,
    PartyBankAccountModel body,
  ) => patchModel<PartyBankAccountModel>(
    '/masters/parties/$partyId/bank-accounts/$id/status',
    body,
    fromJson: PartyBankAccountModel.fromJson,
  );

  Future<PaginatedResponse<PartyCreditLimitModel>> partyCreditLimits(
    int partyId, {
    Map<String, dynamic>? filters,
  }) => paginated<PartyCreditLimitModel>(
    '/masters/parties/$partyId/credit-limits',
    filters: filters,
    fromJson: PartyCreditLimitModel.fromJson,
  );

  Future<ApiResponse<PartyCreditLimitModel>> partyCreditLimit(
    int partyId,
    int id,
  ) => object<PartyCreditLimitModel>(
    '/masters/parties/$partyId/credit-limits/$id',
    fromJson: PartyCreditLimitModel.fromJson,
  );

  Future<ApiResponse<PartyCreditLimitModel>> createPartyCreditLimit(
    int partyId,
    PartyCreditLimitModel body,
  ) => createModel<PartyCreditLimitModel>(
    '/masters/parties/$partyId/credit-limits',
    body,
    fromJson: PartyCreditLimitModel.fromJson,
  );

  Future<ApiResponse<PartyCreditLimitModel>> updatePartyCreditLimit(
    int partyId,
    int id,
    PartyCreditLimitModel body,
  ) => updateModel<PartyCreditLimitModel>(
    '/masters/parties/$partyId/credit-limits/$id',
    body,
    fromJson: PartyCreditLimitModel.fromJson,
  );

  Future<ApiResponse<PartyCreditLimitModel>> changePartyCreditLimitStatus(
    int partyId,
    int id,
    PartyCreditLimitModel body,
  ) => patchModel<PartyCreditLimitModel>(
    '/masters/parties/$partyId/credit-limits/$id/status',
    body,
    fromJson: PartyCreditLimitModel.fromJson,
  );

  Future<PaginatedResponse<PartyPaymentTermModel>> partyPaymentTerms(
    int partyId, {
    Map<String, dynamic>? filters,
  }) => paginated<PartyPaymentTermModel>(
    '/masters/parties/$partyId/payment-terms',
    filters: filters,
    fromJson: PartyPaymentTermModel.fromJson,
  );

  Future<ApiResponse<PartyPaymentTermModel>> partyPaymentTerm(
    int partyId,
    int id,
  ) => object<PartyPaymentTermModel>(
    '/masters/parties/$partyId/payment-terms/$id',
    fromJson: PartyPaymentTermModel.fromJson,
  );

  Future<ApiResponse<PartyPaymentTermModel>> createPartyPaymentTerm(
    int partyId,
    PartyPaymentTermModel body,
  ) => createModel<PartyPaymentTermModel>(
    '/masters/parties/$partyId/payment-terms',
    body,
    fromJson: PartyPaymentTermModel.fromJson,
  );

  Future<ApiResponse<PartyPaymentTermModel>> updatePartyPaymentTerm(
    int partyId,
    int id,
    PartyPaymentTermModel body,
  ) => updateModel<PartyPaymentTermModel>(
    '/masters/parties/$partyId/payment-terms/$id',
    body,
    fromJson: PartyPaymentTermModel.fromJson,
  );

  Future<ApiResponse<PartyPaymentTermModel>> changePartyPaymentTermStatus(
    int partyId,
    int id,
    PartyPaymentTermModel body,
  ) => patchModel<PartyPaymentTermModel>(
    '/masters/parties/$partyId/payment-terms/$id/status',
    body,
    fromJson: PartyPaymentTermModel.fromJson,
  );
}
