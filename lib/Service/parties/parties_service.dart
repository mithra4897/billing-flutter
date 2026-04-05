import '../base/erp_module_service.dart';

class PartiesService extends ErpModuleService {
  PartiesService({super.apiClient});

  Future partyTypes({Map<String, dynamic>? filters}) =>
      index('/masters/party-types', filters: filters);
  Future partyType(int id) => show('/masters/party-types/$id');
  Future createPartyType(Map<String, dynamic> body) =>
      store('/masters/party-types', body);
  Future updatePartyType(int id, Map<String, dynamic> body) =>
      update('/masters/party-types/$id', body);
  Future changePartyTypeStatus(int id, Map<String, dynamic> body) =>
      patch('/masters/party-types/$id/status', body);

  Future parties({Map<String, dynamic>? filters}) =>
      index('/masters/parties', filters: filters);
  Future party(int id) => show('/masters/parties/$id');
  Future createParty(Map<String, dynamic> body) =>
      store('/masters/parties', body);
  Future updateParty(int id, Map<String, dynamic> body) =>
      update('/masters/parties/$id', body);
  Future togglePartyStatus(int id, Map<String, dynamic> body) =>
      patch('/masters/parties/$id/toggle-status', body);

  Future partyAddresses(int partyId, {Map<String, dynamic>? filters}) =>
      index('/masters/parties/$partyId/addresses', filters: filters);
  Future partyAddress(int partyId, int id) =>
      show('/masters/parties/$partyId/addresses/$id');
  Future createPartyAddress(int partyId, Map<String, dynamic> body) =>
      store('/masters/parties/$partyId/addresses', body);
  Future updatePartyAddress(int partyId, int id, Map<String, dynamic> body) =>
      update('/masters/parties/$partyId/addresses/$id', body);
  Future changePartyAddressStatus(
    int partyId,
    int id,
    Map<String, dynamic> body,
  ) => patch('/masters/parties/$partyId/addresses/$id/status', body);

  Future partyContacts(int partyId, {Map<String, dynamic>? filters}) =>
      index('/masters/parties/$partyId/contacts', filters: filters);
  Future partyContact(int partyId, int id) =>
      show('/masters/parties/$partyId/contacts/$id');
  Future createPartyContact(int partyId, Map<String, dynamic> body) =>
      store('/masters/parties/$partyId/contacts', body);
  Future updatePartyContact(int partyId, int id, Map<String, dynamic> body) =>
      update('/masters/parties/$partyId/contacts/$id', body);
  Future changePartyContactStatus(
    int partyId,
    int id,
    Map<String, dynamic> body,
  ) => patch('/masters/parties/$partyId/contacts/$id/status', body);

  Future partyGstDetails(int partyId, {Map<String, dynamic>? filters}) =>
      index('/masters/parties/$partyId/gst-details', filters: filters);
  Future partyGstDetail(int partyId, int id) =>
      show('/masters/parties/$partyId/gst-details/$id');
  Future createPartyGstDetail(int partyId, Map<String, dynamic> body) =>
      store('/masters/parties/$partyId/gst-details', body);
  Future updatePartyGstDetail(int partyId, int id, Map<String, dynamic> body) =>
      update('/masters/parties/$partyId/gst-details/$id', body);
  Future changePartyGstDetailStatus(
    int partyId,
    int id,
    Map<String, dynamic> body,
  ) => patch('/masters/parties/$partyId/gst-details/$id/status', body);

  Future partyBankAccounts(int partyId, {Map<String, dynamic>? filters}) =>
      index('/masters/parties/$partyId/bank-accounts', filters: filters);
  Future partyBankAccount(int partyId, int id) =>
      show('/masters/parties/$partyId/bank-accounts/$id');
  Future createPartyBankAccount(int partyId, Map<String, dynamic> body) =>
      store('/masters/parties/$partyId/bank-accounts', body);
  Future updatePartyBankAccount(
    int partyId,
    int id,
    Map<String, dynamic> body,
  ) => update('/masters/parties/$partyId/bank-accounts/$id', body);
  Future changePartyBankAccountStatus(
    int partyId,
    int id,
    Map<String, dynamic> body,
  ) => patch('/masters/parties/$partyId/bank-accounts/$id/status', body);

  Future partyCreditLimits(int partyId, {Map<String, dynamic>? filters}) =>
      index('/masters/parties/$partyId/credit-limits', filters: filters);
  Future partyCreditLimit(int partyId, int id) =>
      show('/masters/parties/$partyId/credit-limits/$id');
  Future createPartyCreditLimit(int partyId, Map<String, dynamic> body) =>
      store('/masters/parties/$partyId/credit-limits', body);
  Future updatePartyCreditLimit(
    int partyId,
    int id,
    Map<String, dynamic> body,
  ) => update('/masters/parties/$partyId/credit-limits/$id', body);
  Future changePartyCreditLimitStatus(
    int partyId,
    int id,
    Map<String, dynamic> body,
  ) => patch('/masters/parties/$partyId/credit-limits/$id/status', body);

  Future partyPaymentTerms(int partyId, {Map<String, dynamic>? filters}) =>
      index('/masters/parties/$partyId/payment-terms', filters: filters);
  Future partyPaymentTerm(int partyId, int id) =>
      show('/masters/parties/$partyId/payment-terms/$id');
  Future createPartyPaymentTerm(int partyId, Map<String, dynamic> body) =>
      store('/masters/parties/$partyId/payment-terms', body);
  Future updatePartyPaymentTerm(
    int partyId,
    int id,
    Map<String, dynamic> body,
  ) => update('/masters/parties/$partyId/payment-terms/$id', body);
  Future changePartyPaymentTermStatus(
    int partyId,
    int id,
    Map<String, dynamic> body,
  ) => patch('/masters/parties/$partyId/payment-terms/$id/status', body);
}
